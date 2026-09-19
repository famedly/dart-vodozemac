#ifndef VODOZEMAC_IOS_FFI_BINDINGS_H
#define VODOZEMAC_IOS_FFI_BINDINGS_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Result structure for iOS FFI decryption operations.
 * Contains the decrypted plaintext and error information.
 */
typedef struct {
    /** Decrypted plaintext (JSON string), or NULL on error */
    char* plaintext;
    /** Error message if operation failed, or NULL on success */
    char* error;
} IOSDecryptResult;

/**
 * Result from decrypting one m.megolm_backup.v1.curve25519-aes-sha2 payload.
 * `plaintext` is NULL and `success` is zero for every failure class. No error
 * details cross the boundary.
 */
typedef struct {
    uint8_t* plaintext;
    size_t plaintext_len;
    uint8_t success;
} IOSBackupDecryptResult;

/**
 * Decrypt one Matrix v1 key-backup payload with a raw 32-byte backup private
 * key. The ephemeral key, MAC, and ciphertext are bounded base64 byte slices.
 * The function performs no persistence, network, logging, or rendering.
 *
 * The caller owns and clears private_key after this call. On success it must
 * call ios_backup_decrypt_result_free exactly once after parsing plaintext.
 */
IOSBackupDecryptResult ios_decrypt_backup_v1(
    const uint8_t* private_key,
    size_t private_key_len,
    const uint8_t* ephemeral_key_base64,
    size_t ephemeral_key_base64_len,
    const uint8_t* mac_base64,
    size_t mac_base64_len,
    const uint8_t* ciphertext_base64,
    size_t ciphertext_base64_len
);

/** Wipe and release a successful ios_decrypt_backup_v1 result exactly once. */
void ios_backup_decrypt_result_free(IOSBackupDecryptResult result);

/**
 * Decrypt an encrypted message using a pickled session.
 * 
 * This function is designed for use in iOS Notification Extensions where you need
 * to decrypt messages without the main app running.
 * 
 * @param pickled_session Encrypted pickled session (vodozemac format)
 * @param pickle_key Pointer to 32-byte array containing the pickle key
 * @param ciphertext Base64 encoded encrypted message
 * 
 * @return IOSDecryptResult containing:
 *         - plaintext: The decrypted message (JSON string)
 *         - error: Error message if operation failed
 * 
 * @note Caller must free all non-NULL fields using ios_free_result()
 * 
 * @example
 * ```swift
 * let pickleKey: [UInt8] = ... // Your 32-byte pickle key
 * let pickledSession = "..." // Pickled session from storage
 * let ciphertext = "..." // Base64 encrypted message
 * 
 * let result = ios_decrypt_event(
 *     pickledSession,
 *     pickleKey,
 *     ciphertext
 * )
 * 
 * if result.error == nil {
 *     let plaintext = String(cString: result.plaintext!)
 *     print("Decrypted: \(plaintext)")
 * } else {
 *     let error = String(cString: result.error!)
 *     print("Operation failed: \(error)")
 * }
 * 
 * ios_free_result(result)
 * ```
 */
IOSDecryptResult ios_decrypt_event(
    const char* pickled_session,
    const uint8_t pickle_key[32],
    const char* ciphertext
);

/**
 * Free a string allocated by this library.
 * 
 * @param s String to free (can be NULL)
 */
void ios_free_string(char* s);

/**
 * Free an IOSDecryptResult structure and all its fields.
 * 
 * @param result Result structure to free
 */
void ios_free_result(IOSDecryptResult result);

#ifdef __cplusplus
}
#endif

#endif /* VODOZEMAC_IOS_FFI_BINDINGS_H */
