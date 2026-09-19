//! C-compatible FFI bindings for iOS
//! These functions can be called directly from Swift without flutter_rust_bridge

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::{
    panic::{catch_unwind, AssertUnwindSafe},
    slice,
    sync::atomic::{compiler_fence, Ordering},
};
use vodozemac::{
    base64_decode,
    pk_encryption::{Message as PkMessage, PkDecryption},
    Curve25519PublicKey, Curve25519SecretKey,
};
use vodozemac::megolm::{InboundGroupSession, InboundGroupSessionPickle, MegolmMessage};

const BACKUP_PRIVATE_KEY_LENGTH: usize = 32;
const MAX_BACKUP_EPHEMERAL_KEY_BASE64_LENGTH: usize = 44;
const MAX_BACKUP_MAC_BASE64_LENGTH: usize = 128;
const MAX_BACKUP_CIPHERTEXT_BASE64_LENGTH: usize = 64 * 1024;
const MAX_BACKUP_PLAINTEXT_LENGTH: usize = 64 * 1024;

/// A caller-owned backup key copied into Rust for one decryption call.
///
/// The wrapper never serializes or persists this value. Its local copy is
/// wiped using volatile writes when the call returns; the caller remains
/// responsible for clearing its input buffer after the FFI call.
struct BackupPrivateKey([u8; BACKUP_PRIVATE_KEY_LENGTH]);

impl Drop for BackupPrivateKey {
    fn drop(&mut self) {
        for byte in &mut self.0 {
            // A normal assignment can be optimized out after the final use.
            unsafe { std::ptr::write_volatile(byte, 0) };
        }
        compiler_fence(Ordering::SeqCst);
    }
}

/// A byte buffer returned by the bounded backup decrypt entry point.
///
/// There is deliberately no error string: callers receive only success or a
/// generic failure and must keep their existing generic-notification fallback.
#[repr(C)]
pub struct IOSBackupDecryptResult {
    pub plaintext: *mut u8,
    pub plaintext_len: usize,
    pub success: u8,
}

impl IOSBackupDecryptResult {
    const fn failed() -> Self {
        Self {
            plaintext: std::ptr::null_mut(),
            plaintext_len: 0,
            success: 0,
        }
    }
}

/// Decrypt one `m.megolm_backup.v1.curve25519-aes-sha2` session payload.
///
/// The private key is exactly 32 raw bytes. The other three inputs are bounded
/// base64 byte slices from the Matrix backup payload. This function only calls
/// the pinned vodozemac PK-decryption primitive; it has no account store, file,
/// network, logging, or notification-rendering access.
///
/// Invalid input, cryptographic failure, oversized payload, and an unwinding
/// panic return a generic failed result with no error text. Allocator OOM and
/// abort-mode panics terminate the process and cannot produce an ABI result.
/// On success, the caller owns `plaintext` and must call
/// `ios_backup_decrypt_result_free` after parsing it.
#[no_mangle]
pub extern "C" fn ios_decrypt_backup_v1(
    private_key: *const u8,
    private_key_len: usize,
    ephemeral_key_base64: *const u8,
    ephemeral_key_base64_len: usize,
    mac_base64: *const u8,
    mac_base64_len: usize,
    ciphertext_base64: *const u8,
    ciphertext_base64_len: usize,
) -> IOSBackupDecryptResult {
    let result = catch_unwind(AssertUnwindSafe(|| {
        decrypt_backup_v1(
            private_key,
            private_key_len,
            ephemeral_key_base64,
            ephemeral_key_base64_len,
            mac_base64,
            mac_base64_len,
            ciphertext_base64,
            ciphertext_base64_len,
        )
    }));

    let Ok(Ok(mut plaintext)) = result else {
        return IOSBackupDecryptResult::failed();
    };
    if plaintext.is_empty() || plaintext.len() > MAX_BACKUP_PLAINTEXT_LENGTH {
        wipe_bytes(&mut plaintext);
        return IOSBackupDecryptResult::failed();
    }

    let plaintext_len = plaintext.len();
    let plaintext = Box::into_raw(plaintext.into_boxed_slice()) as *mut u8;
    IOSBackupDecryptResult {
        plaintext,
        plaintext_len,
        success: 1,
    }
}

/// Wipe and release a successful `ios_decrypt_backup_v1` result.
///
/// # Safety
/// `result` must be the unmodified successful result from
/// `ios_decrypt_backup_v1`, and may be freed exactly once.
#[no_mangle]
pub unsafe extern "C" fn ios_backup_decrypt_result_free(result: IOSBackupDecryptResult) {
    if result.success == 0 || result.plaintext.is_null() || result.plaintext_len == 0 {
        return;
    }
    let plaintext = unsafe { slice::from_raw_parts_mut(result.plaintext, result.plaintext_len) };
    wipe_bytes(plaintext);
    drop(unsafe { Box::from_raw(plaintext) });
}

fn decrypt_backup_v1(
    private_key: *const u8,
    private_key_len: usize,
    ephemeral_key_base64: *const u8,
    ephemeral_key_base64_len: usize,
    mac_base64: *const u8,
    mac_base64_len: usize,
    ciphertext_base64: *const u8,
    ciphertext_base64_len: usize,
) -> Result<Vec<u8>, ()> {
    if private_key.is_null() || private_key_len != BACKUP_PRIVATE_KEY_LENGTH {
        return Err(());
    }
    let ephemeral_key = bounded_utf8(
        ephemeral_key_base64,
        ephemeral_key_base64_len,
        MAX_BACKUP_EPHEMERAL_KEY_BASE64_LENGTH,
    )?;
    let mac = bounded_utf8(mac_base64, mac_base64_len, MAX_BACKUP_MAC_BASE64_LENGTH)?;
    let ciphertext = bounded_utf8(
        ciphertext_base64,
        ciphertext_base64_len,
        MAX_BACKUP_CIPHERTEXT_BASE64_LENGTH,
    )?;

    let mut private_key_bytes = [0u8; BACKUP_PRIVATE_KEY_LENGTH];
    private_key_bytes.copy_from_slice(unsafe {
        slice::from_raw_parts(private_key, BACKUP_PRIVATE_KEY_LENGTH)
    });
    let private_key = BackupPrivateKey(private_key_bytes);
    let message = PkMessage {
        ciphertext: base64_decode(ciphertext).map_err(|_| ())?,
        mac: base64_decode(mac).map_err(|_| ())?,
        ephemeral_key: Curve25519PublicKey::from_base64(ephemeral_key).map_err(|_| ())?,
    };
    let decryption = PkDecryption::from_key(Curve25519SecretKey::from_slice(&private_key.0));
    decryption.decrypt(&message).map_err(|_| ())
}

fn bounded_utf8<'a>(input: *const u8, input_len: usize, maximum_len: usize) -> Result<&'a str, ()> {
    if input.is_null() || input_len == 0 || input_len > maximum_len {
        return Err(());
    }
    let input = unsafe { slice::from_raw_parts(input, input_len) };
    std::str::from_utf8(input).map_err(|_| ())
}

fn wipe_bytes(bytes: &mut [u8]) {
    for byte in bytes {
        unsafe { std::ptr::write_volatile(byte, 0) };
    }
    compiler_fence(Ordering::SeqCst);
}

/// Result structure for iOS FFI decryption operations
#[repr(C)]
pub struct IOSDecryptResult {
    /// Decrypted plaintext (JSON string), or NULL on error
    pub plaintext: *mut c_char,
    /// Error message if operation failed, or NULL on success
    pub error: *mut c_char,
}

/// Decrypt an encrypted message using a pickled session
/// 
/// # Arguments
/// * `pickled_session` - Encrypted pickled session (from vodozemac)
/// * `pickle_key` - Pointer to 32-byte pickle key array
/// * `ciphertext` - Base64 encoded encrypted message
///
/// # Returns
/// An IOSDecryptResult containing:
/// - plaintext: The decrypted message (JSON string)
/// - error: Error message if decryption failed
/// 
/// Caller must free all non-NULL fields using `ios_free_result`
#[no_mangle]
pub extern "C" fn ios_decrypt_event(
    pickled_session: *const c_char,
    pickle_key: *const [u8; 32],
    ciphertext: *const c_char,
) -> IOSDecryptResult {
    // Initialize result with nulls
    let mut result = IOSDecryptResult {
        plaintext: std::ptr::null_mut(),
        error: std::ptr::null_mut(),
    };

    // Safety check for null pointers
    if pickled_session.is_null() || pickle_key.is_null() || ciphertext.is_null() {
        result.error = create_c_string("Invalid input: null pointer provided");
        return result;
    }

    // Convert C strings to Rust strings
    let pickled_session_str = match unsafe { CStr::from_ptr(pickled_session).to_str() } {
        Ok(s) => s,
        Err(e) => {
            result.error = create_c_string(&format!("Invalid pickled_session string: {}", e));
            return result;
        }
    };

    let ciphertext_str = match unsafe { CStr::from_ptr(ciphertext).to_str() } {
        Ok(s) => s,
        Err(e) => {
            result.error = create_c_string(&format!("Invalid ciphertext string: {}", e));
            return result;
        }
    };

    // Attempt decryption
    match decrypt_event_internal(pickled_session_str, unsafe { *pickle_key }, ciphertext_str) {
        Ok(plaintext) => {
            result.plaintext = create_c_string(&plaintext);
        }
        Err(e) => {
            result.error = create_c_string(&format!("Decryption failed: {}", e));
        }
    }

    result
}

/// Free a string allocated by this library
/// 
/// # Safety
/// Must only be called with strings returned by iOS FFI functions
#[no_mangle]
pub extern "C" fn ios_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

/// Free an IOSDecryptResult structure
/// 
/// # Safety
/// Must only be called with results returned by ios_decrypt_event
#[no_mangle]
pub extern "C" fn ios_free_result(result: IOSDecryptResult) {
    ios_free_string(result.plaintext);
    ios_free_string(result.error);
}

/// Helper to create a C string, returns null on error
fn create_c_string(s: &str) -> *mut c_char {
    match CString::new(s) {
        Ok(c_str) => c_str.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Internal decryption logic
fn decrypt_event_internal(
    pickled_session: &str,
    pickle_key: [u8; 32],
    ciphertext: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    // Unpickle the session from vodozemac's encrypted pickle format
    let pickle = InboundGroupSessionPickle::from_encrypted(pickled_session, &pickle_key)?;
    let mut session = InboundGroupSession::from(pickle);

    // Parse the ciphertext
    let message = MegolmMessage::from_base64(ciphertext)?;

    // Decrypt the message
    let decrypted = session.decrypt(&message)?;

    // Convert plaintext bytes to UTF-8 string
    let plaintext = String::from_utf8(decrypted.plaintext)?;

    Ok(plaintext)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;
    use vodozemac::{
        base64_encode,
        pk_encryption::{PkDecryption, PkEncryption},
        Curve25519SecretKey,
    };
    use vodozemac::megolm::GroupSession;

    #[test]
    fn decrypts_one_bounded_backup_payload_and_releases_the_return() {
        let private_key = [7u8; BACKUP_PRIVATE_KEY_LENGTH];
        let decryptor = PkDecryption::from_key(Curve25519SecretKey::from_slice(&private_key));
        let message = PkEncryption::from_key(decryptor.public_key())
            .encrypt(br#"{\"session_key\":\"not logged\"}"#)
            .expect("test message encryption succeeds");
        let ephemeral_key = message.ephemeral_key.to_base64();
        let mac = base64_encode(&message.mac);
        let ciphertext = base64_encode(&message.ciphertext);

        let result = ios_decrypt_backup_v1(
            private_key.as_ptr(),
            private_key.len(),
            ephemeral_key.as_ptr(),
            ephemeral_key.len(),
            mac.as_ptr(),
            mac.len(),
            ciphertext.as_ptr(),
            ciphertext.len(),
        );

        assert_eq!(result.success, 1);
        assert!(!result.plaintext.is_null());
        let plaintext = unsafe { slice::from_raw_parts(result.plaintext, result.plaintext_len) };
        assert_eq!(plaintext, br#"{\"session_key\":\"not logged\"}"#);
        unsafe { ios_backup_decrypt_result_free(result) };
    }

    #[test]
    fn backup_decrypt_returns_only_generic_failure_for_invalid_or_oversized_input() {
        let private_key = [7u8; BACKUP_PRIVATE_KEY_LENGTH];
        let oversized_ciphertext = vec![b'A'; MAX_BACKUP_CIPHERTEXT_BASE64_LENGTH + 1];
        let result = ios_decrypt_backup_v1(
            private_key.as_ptr(),
            private_key.len(),
            b"invalid".as_ptr(),
            b"invalid".len(),
            b"invalid".as_ptr(),
            b"invalid".len(),
            oversized_ciphertext.as_ptr(),
            oversized_ciphertext.len(),
        );

        assert_eq!(result.success, 0);
        assert!(result.plaintext.is_null());
        assert_eq!(result.plaintext_len, 0);
    }

    #[test]
    fn test_decrypt_matrix_event_with_pickle() {
        // Create a group session and encrypt a message
        let mut outbound_session = GroupSession::new(vodozemac::megolm::SessionConfig::version_1());
        let session_key = outbound_session.session_key();
        let plaintext = "Hello, iOS Notification Extension!";
        let ciphertext = outbound_session.encrypt(plaintext);

        // Create inbound session and pickle it using vodozemac native format
        let inbound_session = InboundGroupSession::new(
            &session_key,
            vodozemac::megolm::SessionConfig::version_1(),
        );
        let pickle_key: [u8; 32] = *b"01234567890123456789012345678901";
        let pickled = inbound_session.pickle().encrypt(&pickle_key);

        // Convert to C strings
        let pickled_c = CString::new(pickled.clone()).unwrap();
        let ciphertext_c = CString::new(ciphertext.to_base64()).unwrap();

        // Call the C function
        let result = ios_decrypt_event(
            pickled_c.as_ptr(),
            &pickle_key,
            ciphertext_c.as_ptr(),
        );

        // Check for success
        if !result.error.is_null() {
            let error_msg = unsafe { CStr::from_ptr(result.error).to_str().unwrap() };
            panic!("Decryption failed: {}", error_msg);
        }
        assert!(!result.plaintext.is_null(), "Expected plaintext");

        // Convert result back to Rust string
        let result_plaintext = unsafe { CStr::from_ptr(result.plaintext).to_str().unwrap() };
        assert_eq!(result_plaintext, plaintext);

        // Clean up
        ios_free_result(result);
    }

    #[test]
    fn test_decrypt_with_invalid_pickle() {
        let pickle_key: [u8; 32] = *b"0123456789012345678901234567890!";
        let invalid_pickle = CString::new("invalid_base64_pickle").unwrap();
        let ciphertext = CString::new("some_ciphertext").unwrap();

        let result = ios_decrypt_event(
            invalid_pickle.as_ptr(),
            &pickle_key,
            ciphertext.as_ptr(),
        );

        // Should have error
        assert!(!result.error.is_null());
        assert!(result.plaintext.is_null());

        ios_free_result(result);
    }
}
