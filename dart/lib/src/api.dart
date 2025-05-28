import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'generated/bindings.dart' as vodozemac;
import 'generated/frb_generated.dart' as vodozemac show RustLib;

/// Initialize by loading the vodozemac library. You can provide the [wasmPath]
/// and [libraryPath] to specify the location of the wasm and native library
/// respectively.
Future<void> init(
        {required String wasmPath, required String libraryPath}) async =>
    vodozemac.RustLib.init(
        externalLibrary: await loadExternalLibrary(ExternalLibraryLoaderConfig(
            stem: 'vodozemac_bindings_dart',
            ioDirectory: libraryPath,
            webPrefix: wasmPath)));

/// If the vodozemac library has been loaded and initialized.
bool isInitialized() => vodozemac.RustLib.instance.initialized;

final class Curve25519PublicKey {
  final vodozemac.VodozemacCurve25519PublicKey _key;

  Curve25519PublicKey._(this._key);

  factory Curve25519PublicKey.fromBase64(String key) => Curve25519PublicKey._(
      vodozemac.VodozemacCurve25519PublicKey.fromBase64(base64Key: key));

  factory Curve25519PublicKey.fromBytes(Uint8List key) =>
      Curve25519PublicKey._(vodozemac.VodozemacCurve25519PublicKey.fromSlice(
          bytes: vodozemac.U8Array32(key)));

  String toBase64() => _key.toBase64();
  Uint8List toBytes() => Uint8List.fromList(_key.asBytes());
}

final class Ed25519Signature {
  final vodozemac.VodozemacEd25519Signature _key;

  Ed25519Signature._(this._key);

  factory Ed25519Signature.fromBase64(String key) => Ed25519Signature._(
      vodozemac.VodozemacEd25519Signature.fromBase64(signature: key));

  factory Ed25519Signature.fromBytes(Uint8List key) =>
      Ed25519Signature._(vodozemac.VodozemacEd25519Signature.fromSlice(
          bytes: vodozemac.U8Array64(key)));

  String toBase64() => _key.toBase64();
  Uint8List toBytes() => Uint8List.fromList(_key.toBytes());
}

final class Ed25519PublicKey {
  final vodozemac.VodozemacEd25519PublicKey _key;

  Ed25519PublicKey._(this._key);

  factory Ed25519PublicKey.fromBase64(String key) => Ed25519PublicKey._(
      vodozemac.VodozemacEd25519PublicKey.fromBase64(base64Key: key));

  factory Ed25519PublicKey.fromBytes(Uint8List key) =>
      Ed25519PublicKey._(vodozemac.VodozemacEd25519PublicKey.fromSlice(
          bytes: vodozemac.U8Array32(key)));

  String toBase64() => _key.toBase64();
  Uint8List toBytes() => Uint8List.fromList(_key.asBytes());

  /// Verify an Ed25519 signature.
  void verify({required String message, required Ed25519Signature signature}) =>
      _key.verify(message: message, signature: signature._key);
}

final class GroupSession {
  final vodozemac.VodozemacGroupSession _session;

  GroupSession._(this._session);

  GroupSession()
      : _session = vodozemac.VodozemacGroupSession(
          config: vodozemac.VodozemacMegolmSessionConfig.def(),
        );

  String get sessionId => _session.sessionId();
  String get sessionKey => _session.sessionKey();
  int get messageIndex => _session.messageIndex();

  /// Encrypt a message.
  String encrypt(String plaintext) => _session.encrypt(plaintext: plaintext);

  /// Convert to an inbound group session.
  InboundGroupSession toInbound() =>
      InboundGroupSession._(_session.toInbound());

  String toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static GroupSession fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      GroupSession._(vodozemac.VodozemacGroupSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static GroupSession fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      GroupSession._(vodozemac.VodozemacGroupSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

final class InboundGroupSession {
  final vodozemac.VodozemacInboundGroupSession _session;

  InboundGroupSession._(this._session);

  InboundGroupSession(String sessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession(
            sessionKey: sessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  InboundGroupSession.import(String exportedSessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession.import_(
            exportedSessionKey: exportedSessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  String get sessionId => _session.sessionId();
  int get firstKnownIndex => _session.firstKnownIndex();

  /// Decrypt a message.
  ({String plaintext, int messageIndex}) decrypt(String encrypted) {
    final result = _session.decrypt(encrypted: encrypted);
    return (plaintext: result.field0, messageIndex: result.field1);
  }

  /// Export a session at a specific message index. Returns `exportedSessionKey`
  /// which can be used to import the session again.
  String? exportAt(int messageIndex) => _session.exportAt(index: messageIndex);

  /// Export a session at the first known message index. Returns `exportedSessionKey`
  /// which can be used to import the session again.
  String exportAtFirstKnownIndex() => _session.exportAtFirstKnownIndex();

  String toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static InboundGroupSession fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      InboundGroupSession._(
          vodozemac.VodozemacInboundGroupSession.fromPickleEncrypted(
              pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static InboundGroupSession fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      InboundGroupSession._(
          vodozemac.VodozemacInboundGroupSession.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));
}

final class Session {
  final vodozemac.VodozemacSession _session;

  Session._(this._session);

  String get sessionId => _session.sessionId();
  bool get hasReceivedMessage => _session.hasReceivedMessage();

  /// Encrypt a message.
  ({int messageType, String ciphertext}) encrypt(String plaintext) {
    final encrypted = _session.encrypt(plaintext: plaintext);
    return (
      messageType: encrypted.messageType().toInt(),
      ciphertext: encrypted.message(),
    );
  }

  /// Decrypt a message.
  String decrypt({required int messageType, required String ciphertext}) =>
      _session.decrypt(
          message: vodozemac.VodozemacOlmMessage.fromParts(
              messageType: BigInt.from(messageType), ciphertext: ciphertext));

  String toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Session fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Session._(vodozemac.VodozemacSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Session fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Session._(vodozemac.VodozemacSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

final class Account {
  final vodozemac.VodozemacAccount _account;

  Account._(this._account);
  factory Account() => Account._(vodozemac.VodozemacAccount());

  int get maxNumberOfOneTimeKeys => _account.maxNumberOfOneTimeKeys().toInt();

  Ed25519PublicKey get ed25519Key => Ed25519PublicKey._(_account.ed25519Key());

  Curve25519PublicKey get curve25519Key =>
      Curve25519PublicKey._(_account.curve25519Key());

  ({Ed25519PublicKey ed25519, Curve25519PublicKey curve25519})
      get identityKeys {
    final keys = _account.identityKeys();
    return (
      ed25519: Ed25519PublicKey._(keys.ed25519),
      curve25519: Curve25519PublicKey._(keys.curve25519)
    );
  }

  Map<String, Curve25519PublicKey> get oneTimeKeys =>
      Map<String, Curve25519PublicKey>.fromEntries(_account
          .oneTimeKeys()
          .map((e) => MapEntry(e.keyid, Curve25519PublicKey._(e.key))));

  Map<String, Curve25519PublicKey> get fallbackKey =>
      Map<String, Curve25519PublicKey>.fromEntries(_account
          .fallbackKey()
          .map((e) => MapEntry(e.keyid, Curve25519PublicKey._(e.key))));

  /// Generate a fallback key.
  void generateFallbackKey() => _account.generateFallbackKey();

  /// Forget the fallback key.
  bool forgetFallbackKey() => _account.forgetFallbackKey();

  /// Generate one-time keys.
  void generateOneTimeKeys(int count) =>
      _account.generateOneTimeKeys(count: BigInt.from(count));

  /// Mark keys as published.
  void markKeysAsPublished() => _account.markKeysAsPublished();

  /// Sign a message.
  Ed25519Signature sign(String message) =>
      Ed25519Signature._(_account.sign(message: message));

  /// Create an outbound session.
  Session createOutboundSession({
    required Curve25519PublicKey identityKey,
    required Curve25519PublicKey oneTimeKey,
  }) =>
      Session._(_account.createOutboundSession(
          config: vodozemac.VodozemacOlmSessionConfig.def(),
          identityKey: identityKey._key,
          oneTimeKey: oneTimeKey._key));

  /// Create an inbound session.
  ({Session session, String plaintext}) createInboundSession({
    required Curve25519PublicKey theirIdentityKey,
    required String preKeyMessageBase64,
  }) {
    final inb = _account.createInboundSession(
        theirIdentityKey: theirIdentityKey._key,
        preKeyMessageBase64: preKeyMessageBase64);

    return (session: Session._(inb.session), plaintext: inb.plaintext);
  }

  String toPickleEncrypted(Uint8List pickleKey) =>
      _account.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Account fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Account._(vodozemac.VodozemacAccount.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Account fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      Account._(vodozemac.VodozemacAccount.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

final class Sas {
  final vodozemac.VodozemacSas _sas;
  final String _publicKey;
  bool _disposed = false;

  Sas._(this._sas) : _publicKey = _sas.publicKey();
  factory Sas() => Sas._(vodozemac.VodozemacSas());

  String get publicKey => _publicKey;

  /// Once the `establishSasSecret` method is called, the Sas object is disposed
  /// and cannot be used again to establish a new SAS secret.
  /// Create a new Sas object instead.
  EstablishedSas establishSasSecret(String otherPublicKey) {
    if (_disposed) {
      throw Exception('Sas has been disposed');
    }
    _disposed = true;
    return EstablishedSas._(
        _sas.establishSasSecret(otherPublicKey: otherPublicKey));
  }
}

final class EstablishedSas {
  final vodozemac.VodozemacEstablishedSas _sas;

  EstablishedSas._(this._sas);

  /// Generate SAS secret bytes.
  Uint8List generateBytes(String info, int length) =>
      _sas.generateBytes(info: info, length: length);

  /// Calculate a MAC.
  /// To be used with `hkdf-hmac-sha256.v2` which is the current recommended method
  String calculateMac(String input, String info) =>
      _sas.calculateMac(input: input, info: info);

  /// Calculate a MAC.
  /// To be used with `hkdf-hmac-sha256` which is deprecated now due to a bug in
  /// it's original implementation in libolm.
  /// Refer to info section in https://spec.matrix.org/latest/client-server-api/#mac-calculation
  String calculateMacDeprecated(String input, String info) =>
      _sas.calculateMacDeprecated(input: input, info: info);

  /// Verify a MAC.
  void verifyMac(String input, String info, String mac) =>
      _sas.verifyMac(input: input, info: info, mac: mac);
}

final class PkMessage {
  final vodozemac.VodozemacPkMessage _message;

  PkMessage._(this._message);

  Uint8List get ciphertext => _message.ciphertext;
  Uint8List get mac => _message.mac;
  Curve25519PublicKey get ephemeralKey =>
      Curve25519PublicKey._(_message.ephemeralKey);
}

final class PkEncryption {
  final vodozemac.VodozemacPkEncryption _encryption;

  PkEncryption._(this._encryption);

  factory PkEncryption.fromPublicKey(Curve25519PublicKey key) => PkEncryption._(
      vodozemac.VodozemacPkEncryption.fromKey(publicKey: key._key));

  /// Encrypt a message.
  PkMessage encrypt(String message) =>
      PkMessage._(_encryption.encrypt(message: message));
}

final class PkDecryption {
  final vodozemac.VodozemacPkDecryption _decryption;

  PkDecryption._(this._decryption);
  factory PkDecryption() => PkDecryption._(vodozemac.VodozemacPkDecryption());

  factory PkDecryption.fromSecretKey(Curve25519PublicKey key) =>
      PkDecryption._(vodozemac.VodozemacPkDecryption.fromKey(
          secretKey: vodozemac.U8Array32(key.toBytes())));

  String get publicKey => _decryption.publicKey();

  Uint8List get privateKey => _decryption.privateKey();

  /// Decrypt a message.
  String decrypt(PkMessage message) =>
      _decryption.decrypt(message: message._message);

  static PkDecryption fromLibolmPickle({
    required String pickle,
    required Uint8List pickleKey,
  }) =>
      PkDecryption._(vodozemac.VodozemacPkDecryption.fromLibolmPickle(
          pickle: pickle, pickleKey: pickleKey));

  String toLibolmPickle(Uint8List pickleKey) =>
      _decryption.toLibolmPickle(pickleKey: vodozemac.U8Array32(pickleKey));
}

final class PkSigning {
  final vodozemac.PkSigning _signing;

  PkSigning._(this._signing);
  factory PkSigning() => PkSigning._(vodozemac.PkSigning());

  factory PkSigning.fromSecretKey(String key) =>
      PkSigning._(vodozemac.PkSigning.fromSecretKey(key: key));

  String get secretKey => _signing.secretKey();

  Ed25519PublicKey get publicKey => Ed25519PublicKey._(_signing.publicKey());

  /// Sign a message.
  Ed25519Signature sign(String message) =>
      Ed25519Signature._(_signing.sign(message: message));
}
