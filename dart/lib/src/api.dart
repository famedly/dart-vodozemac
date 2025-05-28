import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'generated/bindings.dart' as vodozemac;
import 'generated/frb_generated.dart' as vodozemac show RustLib;

/// Initialize by loading the vodozemac library. You can provide the [wasmPath]
/// and [libraryPath] to specify the location of the wasm and native library
/// respectively.
///
/// This is required before using any of the cryptographic functions in this library.
Future<void> init(
        {required String wasmPath, required String libraryPath}) async =>
    vodozemac.RustLib.init(
        externalLibrary: await loadExternalLibrary(ExternalLibraryLoaderConfig(
            stem: 'vodozemac_bindings_dart',
            ioDirectory: libraryPath,
            webPrefix: wasmPath)));

/// If the vodozemac library has been loaded and initialized.
bool isInitialized() => vodozemac.RustLib.instance.initialized;

/// Represents a Curve25519 public key used for encryption in Matrix.
///
/// Used in various parts of Matrix E2EE, including Olm and Megolm protocols.
final class Curve25519PublicKey {
  final vodozemac.VodozemacCurve25519PublicKey _key;

  Curve25519PublicKey._(this._key);

  /// Creates a Curve25519 public key from a base64 encoded string.
  factory Curve25519PublicKey.fromBase64(String key) => Curve25519PublicKey._(
      vodozemac.VodozemacCurve25519PublicKey.fromBase64(base64Key: key));

  /// Creates a Curve25519 public key from raw bytes.
  factory Curve25519PublicKey.fromBytes(Uint8List key) =>
      Curve25519PublicKey._(vodozemac.VodozemacCurve25519PublicKey.fromSlice(
          bytes: vodozemac.U8Array32(key)));

  /// Returns the key as a base64 encoded string.
  String toBase64() => _key.toBase64();

  /// Returns the key as raw bytes.
  Uint8List toBytes() => Uint8List.fromList(_key.asBytes());
}

/// Represents an Ed25519 signature used for verification in Matrix.
///
/// Used to verify the authenticity of messages and keys.
final class Ed25519Signature {
  final vodozemac.VodozemacEd25519Signature _key;

  Ed25519Signature._(this._key);

  /// Creates an Ed25519 signature from a base64 encoded string.
  factory Ed25519Signature.fromBase64(String key) => Ed25519Signature._(
      vodozemac.VodozemacEd25519Signature.fromBase64(signature: key));

  /// Creates an Ed25519 signature from raw bytes.
  factory Ed25519Signature.fromBytes(Uint8List key) =>
      Ed25519Signature._(vodozemac.VodozemacEd25519Signature.fromSlice(
          bytes: vodozemac.U8Array64(key)));

  /// Returns the signature as a base64 encoded string.
  String toBase64() => _key.toBase64();

  /// Returns the signature as raw bytes.
  Uint8List toBytes() => Uint8List.fromList(_key.toBytes());
}

/// Represents an Ed25519 public key used for verification in Matrix.
///
/// Used to verify signatures created with the corresponding private key.
final class Ed25519PublicKey {
  final vodozemac.VodozemacEd25519PublicKey _key;

  Ed25519PublicKey._(this._key);

  /// Creates an Ed25519 public key from a base64 encoded string.
  factory Ed25519PublicKey.fromBase64(String key) => Ed25519PublicKey._(
      vodozemac.VodozemacEd25519PublicKey.fromBase64(base64Key: key));

  /// Creates an Ed25519 public key from raw bytes.
  factory Ed25519PublicKey.fromBytes(Uint8List key) =>
      Ed25519PublicKey._(vodozemac.VodozemacEd25519PublicKey.fromSlice(
          bytes: vodozemac.U8Array32(key)));

  /// Returns the key as a base64 encoded string.
  String toBase64() => _key.toBase64();

  /// Returns the key as raw bytes.
  Uint8List toBytes() => Uint8List.fromList(_key.asBytes());

  /// Verify an Ed25519 signature against a message.
  ///
  /// Throws an exception if the signature is invalid.
  void verify({required String message, required Ed25519Signature signature}) =>
      _key.verify(message: message, signature: signature._key);
}

/// Represents a Megolm group session for encrypting messages in Matrix rooms.
///
/// Used to encrypt messages sent to Matrix rooms with Megolm encryption.
/// Reference: https://spec.matrix.org/latest/client-server-api/#messaging-algorithms
final class GroupSession {
  final vodozemac.VodozemacGroupSession _session;

  GroupSession._(this._session);

  /// Creates a new outbound group session with default configuration.
  GroupSession()
      : _session = vodozemac.VodozemacGroupSession(
          config: vodozemac.VodozemacMegolmSessionConfig.def(),
        );

  /// The unique identifier for this session.
  String get sessionId => _session.sessionId();

  /// The session key that can be shared with others to allow them to decrypt
  /// messages by creating an inbound group session.
  String get sessionKey => _session.sessionKey();

  /// The current message index of the session.
  int get messageIndex => _session.messageIndex();

  /// Encrypt a message using this session.
  ///
  /// Returns the encrypted message as a base64 encoded string.
  String encrypt(String plaintext) => _session.encrypt(plaintext: plaintext);

  /// Convert this outbound session to an inbound session.
  ///
  /// This allows the session owner to decrypt their own messages.
  InboundGroupSession toInbound() =>
      InboundGroupSession._(_session.toInbound());

  /// Serialize the session with encryption for storage.
  ///
  /// The pickle can be restored with [fromPickleEncrypted].
  String toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  /// Deserialize a session from an encrypted pickle.
  static GroupSession fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      GroupSession._(vodozemac.VodozemacGroupSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  /// Deserialize a session from an encrypted pickle in the legacy libolm format.
  static GroupSession fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      GroupSession._(vodozemac.VodozemacGroupSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

/// Represents a Megolm inbound group session for decrypting messages in Matrix rooms.
///
/// Used to decrypt messages received in Matrix rooms encrypted with Megolm.
/// Reference: https://spec.matrix.org/latest/client-server-api/#messaging-algorithms
final class InboundGroupSession {
  final vodozemac.VodozemacInboundGroupSession _session;

  InboundGroupSession._(this._session);

  /// Creates a new inbound group session from a session key.
  InboundGroupSession(String sessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession(
            sessionKey: sessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  /// Creates a new inbound group session from an exported session key using the
  /// [exportAt] method.
  ///
  /// This allows importing a session that was exported at a specific message index.
  InboundGroupSession.import(String exportedSessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession.import_(
            exportedSessionKey: exportedSessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  /// The unique identifier for this session.
  String get sessionId => _session.sessionId();

  /// The earliest message index that this session can decrypt.
  int get firstKnownIndex => _session.firstKnownIndex();

  /// Decrypt a message using this session.
  ///
  /// Returns the decrypted plaintext and the message index.
  ({String plaintext, int messageIndex}) decrypt(String encrypted) {
    final result = _session.decrypt(encrypted: encrypted);
    return (plaintext: result.field0, messageIndex: result.field1);
  }

  /// Export the session at a specific message index.
  ///
  /// This allows sharing the ability to decrypt messages from the specified index onwards.
  /// Returns null if the message index is invalid.
  String? exportAt(int messageIndex) => _session.exportAt(index: messageIndex);

  /// Export the session at the first known message index.
  ///
  /// This allows sharing the ability to decrypt all messages this session can decrypt.
  String exportAtFirstKnownIndex() => _session.exportAtFirstKnownIndex();

  /// Serialize the session with encryption for storage.
  ///
  /// The pickle can be restored with [fromPickleEncrypted].
  String toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  /// Deserialize a session from an encrypted pickle.
  static InboundGroupSession fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      InboundGroupSession._(
          vodozemac.VodozemacInboundGroupSession.fromPickleEncrypted(
              pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  /// Deserialize a session from an encrypted pickle in the legacy libolm format.
  static InboundGroupSession fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      InboundGroupSession._(
          vodozemac.VodozemacInboundGroupSession.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));
}

/// Represents an Olm session for end-to-end encrypted communication between two devices.
///
/// Used for direct encrypted communication between two devices in Matrix.
/// Reference: https://spec.matrix.org/latest/client-server-api/#messaging-algorithms
final class Session {
  final vodozemac.VodozemacSession _session;

  Session._(this._session);

  /// The unique identifier for this session.
  String get sessionId => _session.sessionId();

  /// Have we ever received and decrypted a message from the other side?
  ///
  /// Used to decide if outgoing messages should be sent as normal or pre-key
  /// messages.
  bool get hasReceivedMessage => _session.hasReceivedMessage();

  /// Encrypt a message using this session.
  ///
  /// Returns the message type and ciphertext. The message type is used to determine
  /// how to decrypt the message (either 0 for pre-key messages or 1 for normal messages).
  ({int messageType, String ciphertext}) encrypt(String plaintext) {
    final encrypted = _session.encrypt(plaintext: plaintext);
    return (
      messageType: encrypted.messageType().toInt(),
      ciphertext: encrypted.message(),
    );
  }

  /// Decrypt a message using this session.
  ///
  /// The message type determines how to decrypt the message (either 0 for pre-key
  /// messages or 1 for normal messages).
  String decrypt({required int messageType, required String ciphertext}) =>
      _session.decrypt(
          message: vodozemac.VodozemacOlmMessage.fromParts(
              messageType: BigInt.from(messageType), ciphertext: ciphertext));

  /// Serialize the session with encryption for storage.
  ///
  /// The pickle can be restored with [fromPickleEncrypted].
  String toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  /// Deserialize a session from an encrypted pickle.
  static Session fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Session._(vodozemac.VodozemacSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  /// Deserialize a session from an encrypted pickle in the legacy libolm format.
  static Session fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Session._(vodozemac.VodozemacSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

/// Represents a Matrix account for end-to-end encryption.
///
/// Used to manage keys and create sessions for E2EE in Matrix.
/// Reference: https://spec.matrix.org/latest/client-server-api/#key-distribution
final class Account {
  final vodozemac.VodozemacAccount _account;

  Account._(this._account);

  /// Creates a new account with a new identity key pair.
  factory Account() => Account._(vodozemac.VodozemacAccount());

  /// The maximum number of one-time keys that can be stored.
  int get maxNumberOfOneTimeKeys => _account.maxNumberOfOneTimeKeys().toInt();

  /// The Ed25519 identity key used for signing.
  Ed25519PublicKey get ed25519Key => Ed25519PublicKey._(_account.ed25519Key());

  /// The Curve25519 identity key used for encryption.
  Curve25519PublicKey get curve25519Key =>
      Curve25519PublicKey._(_account.curve25519Key());

  /// Get both identity keys (Ed25519 and Curve25519).
  ({Ed25519PublicKey ed25519, Curve25519PublicKey curve25519})
      get identityKeys {
    final keys = _account.identityKeys();
    return (
      ed25519: Ed25519PublicKey._(keys.ed25519),
      curve25519: Curve25519PublicKey._(keys.curve25519)
    );
  }

  /// The current one-time keys available for creating sessions.
  ///
  /// These are used for creating new Olm sessions.
  Map<String, Curve25519PublicKey> get oneTimeKeys =>
      Map<String, Curve25519PublicKey>.fromEntries(_account
          .oneTimeKeys()
          .map((e) => MapEntry(e.keyid, Curve25519PublicKey._(e.key))));

  /// The current fallback key.
  ///
  /// This is used when no one-time keys are available.
  Map<String, Curve25519PublicKey> get fallbackKey =>
      Map<String, Curve25519PublicKey>.fromEntries(_account
          .fallbackKey()
          .map((e) => MapEntry(e.keyid, Curve25519PublicKey._(e.key))));

  /// Generate a new fallback key.
  ///
  /// The fallback key is used when no one-time keys are available.
  void generateFallbackKey() => _account.generateFallbackKey();

  /// Forget the current fallback key.
  ///
  /// Returns true if a fallback key was forgotten.
  bool forgetFallbackKey() => _account.forgetFallbackKey();

  /// Generate new one-time keys.
  ///
  /// These are used for creating new Olm sessions.
  void generateOneTimeKeys(int count) =>
      _account.generateOneTimeKeys(count: BigInt.from(count));

  /// Mark keys as published to the server.
  ///
  /// This should be called after successfully uploading keys to the server.
  void markKeysAsPublished() => _account.markKeysAsPublished();

  /// Sign a message with the account's Ed25519 key.
  Ed25519Signature sign(String message) =>
      Ed25519Signature._(_account.sign(message: message));

  /// Create an outbound Olm session with another device.
  ///
  /// Uses the recipient's identity key and one-time key to establish a secure channel.
  Session createOutboundSession({
    required Curve25519PublicKey identityKey,
    required Curve25519PublicKey oneTimeKey,
  }) =>
      Session._(_account.createOutboundSession(
          config: vodozemac.VodozemacOlmSessionConfig.def(),
          identityKey: identityKey._key,
          oneTimeKey: oneTimeKey._key));

  /// Create an inbound Olm session from a received pre-key message.
  ///
  /// Used to establish a secure channel when receiving a pre-key message.
  ({Session session, String plaintext}) createInboundSession({
    required Curve25519PublicKey theirIdentityKey,
    required String preKeyMessageBase64,
  }) {
    final inb = _account.createInboundSession(
        theirIdentityKey: theirIdentityKey._key,
        preKeyMessageBase64: preKeyMessageBase64);

    return (session: Session._(inb.session), plaintext: inb.plaintext);
  }

  /// Serialize the account with encryption for storage.
  ///
  /// The pickle can be restored with [fromPickleEncrypted].
  String toPickleEncrypted(Uint8List pickleKey) =>
      _account.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  /// Deserialize an account from an encrypted pickle.
  static Account fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Account._(vodozemac.VodozemacAccount.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  /// Deserialize an account from an encrypted pickle in the legacy libolm format.
  static Account fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Account._(vodozemac.VodozemacAccount.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

/// Represents a Short Authentication String (SAS) verification process.
///
/// Used for interactive device verification in Matrix.
/// Reference: https://spec.matrix.org/latest/client-server-api/#short-authentication-string-sas-verification
final class Sas {
  final vodozemac.VodozemacSas _sas;
  final String _publicKey;
  bool _disposed = false;

  Sas._(this._sas) : _publicKey = _sas.publicKey();

  /// Creates a new SAS verification process.
  factory Sas() => Sas._(vodozemac.VodozemacSas());

  /// The public key for this SAS verification.
  ///
  /// This should be sent to the other party.
  String get publicKey => _publicKey;

  /// Establish a shared secret using the other party's public key.
  ///
  /// Once called, this Sas object is disposed and cannot be used again.
  /// Create a new Sas object for a new verification process.
  EstablishedSas establishSasSecret(String otherPublicKey) {
    if (_disposed) {
      throw Exception('Sas has been disposed');
    }
    _disposed = true;
    return EstablishedSas._(
        _sas.establishSasSecret(otherPublicKey: otherPublicKey));
  }
}

/// Represents an established Short Authentication String (SAS) shared secret.
///
/// Used for generating verification codes and MACs in the SAS verification process.
/// Reference: https://spec.matrix.org/latest/client-server-api/#short-authentication-string-sas-verification
final class EstablishedSas {
  final vodozemac.VodozemacEstablishedSas _sas;

  EstablishedSas._(this._sas);

  /// Generate bytes from the shared secret.
  ///
  /// Used for generating emoji or decimal representations for verification.
  Uint8List generateBytes(String info, int length) =>
      _sas.generateBytes(info: info, length: length);

  /// Calculate a MAC for verification.
  ///
  /// To be used with `hkdf-hmac-sha256.v2` which is the current recommended method.
  /// Reference: https://spec.matrix.org/latest/client-server-api/#mac-calculation
  String calculateMac(String input, String info) =>
      _sas.calculateMac(input: input, info: info);

  /// Calculate a MAC using the deprecated method.
  ///
  /// To be used with `hkdf-hmac-sha256` which is deprecated due to a bug in
  /// its original implementation in libolm.
  /// Reference: https://spec.matrix.org/latest/client-server-api/#mac-calculation
  String calculateMacDeprecated(String input, String info) =>
      _sas.calculateMacDeprecated(input: input, info: info);

  /// Verify a MAC received from the other party.
  ///
  /// Throws an exception if the MAC is invalid.
  void verifyMac(String input, String info, String mac) =>
      _sas.verifyMac(input: input, info: info, mac: mac);
}

/// Represents an encrypted message using public key cryptography.
///
/// Used in Matrix's key backup and cross-signing features.
final class PkMessage {
  final vodozemac.VodozemacPkMessage _message;

  PkMessage._(this._message);

  PkMessage(
      Uint8List ciphertext, Uint8List mac, Curve25519PublicKey ephemeralKey)
      : _message = vodozemac.VodozemacPkMessage(
          ciphertext: ciphertext,
          mac: mac,
          ephemeralKey: ephemeralKey._key,
        );

  /// Create a new PkMessage from a Base64-encoded triplet of ciphertext, MAC, and ephemeral key.
  factory PkMessage.fromBase64({
    required String ciphertext,
    required String mac,
    required String ephemeralKey,
  }) =>
      PkMessage._(vodozemac.VodozemacPkMessage.fromBase64(
          ciphertext: ciphertext, mac: mac, ephemeralKey: ephemeralKey));

  /// Encode the PkMessage as a Base64-encoded triplet of ciphertext, MAC, and ephemeral key.
  (String ciphertext, String mac, String ephemeralKey) toBase64() =>
      _message.toBase64();

  /// The encrypted ciphertext.
  Uint8List get ciphertext => _message.ciphertext;

  /// The MAC for message authentication.
  Uint8List get mac => _message.mac;

  /// The ephemeral key used for encryption.
  Curve25519PublicKey get ephemeralKey =>
      Curve25519PublicKey._(_message.ephemeralKey);
}

/// Used for encrypting messages with public key cryptography.
///
/// Used in Matrix's key backup and cross-signing features.
/// Reference: https://spec.matrix.org/latest/client-server-api/#cross-signing
final class PkEncryption {
  final vodozemac.VodozemacPkEncryption _encryption;

  PkEncryption._(this._encryption);

  /// Create a new PkEncryption using a public key.
  factory PkEncryption.fromPublicKey(Curve25519PublicKey key) => PkEncryption._(
      vodozemac.VodozemacPkEncryption.fromKey(publicKey: key._key));

  /// Encrypt a message using the public key.
  PkMessage encrypt(String message) =>
      PkMessage._(_encryption.encrypt(message: message));
}

/// Used for decrypting messages encrypted with public key cryptography.
///
/// Used in Matrix's key backup and cross-signing features.
/// Reference: https://spec.matrix.org/latest/client-server-api/#cross-signing
final class PkDecryption {
  final vodozemac.VodozemacPkDecryption _decryption;

  PkDecryption._(this._decryption);

  /// Create a new PkDecryption with a new key pair.
  factory PkDecryption() => PkDecryption._(vodozemac.VodozemacPkDecryption());

  /// Create a new PkDecryption with an existing secret key.
  factory PkDecryption.fromSecretKey(Curve25519PublicKey key) =>
      PkDecryption._(vodozemac.VodozemacPkDecryption.fromKey(
          secretKey: vodozemac.U8Array32(key.toBytes())));

  /// The public key corresponding to the private key.
  String get publicKey => _decryption.publicKey();

  /// The private key used for decryption.
  Uint8List get privateKey => _decryption.privateKey();

  /// Decrypt a message using the private key.
  String decrypt(PkMessage message) =>
      _decryption.decrypt(message: message._message);

  /// Deserialize from a libolm pickle.
  static PkDecryption fromLibolmPickle({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      PkDecryption._(vodozemac.VodozemacPkDecryption.fromLibolmPickle(
          pickle: pickle, pickleKey: pickleKey));

  /// Serialize to a libolm pickle.
  String toLibolmPickle(Uint8List pickleKey) =>
      _decryption.toLibolmPickle(pickleKey: vodozemac.U8Array32(pickleKey));
}

/// Used for signing messages with a public key.
///
/// Used in Matrix's cross-signing feature.
/// Reference: https://spec.matrix.org/latest/client-server-api/#cross-signing
final class PkSigning {
  final vodozemac.PkSigning _signing;

  PkSigning._(this._signing);

  /// Create a new PkSigning with a new key pair.
  factory PkSigning() => PkSigning._(vodozemac.PkSigning());

  /// Create a new PkSigning with an existing secret key.
  factory PkSigning.fromSecretKey(String key) =>
      PkSigning._(vodozemac.PkSigning.fromSecretKey(key: key));

  /// The secret key used for signing.
  String get secretKey => _signing.secretKey();

  /// The public key that can verify signatures created by this object.
  Ed25519PublicKey get publicKey => Ed25519PublicKey._(_signing.publicKey());

  /// Sign a message using the secret key.
  Ed25519Signature sign(String message) =>
      Ed25519Signature._(_signing.sign(message: message));
}
