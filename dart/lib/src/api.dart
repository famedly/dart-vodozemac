import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:vodozemac/src/utils.dart';

import 'generated/frb_generated.dart' as vodozemac show RustLib;
import 'generated/bindings.dart' as vodozemac;

/// Load the vodozemac backend. Only one backend can be loaded. You can provide the [wasmPath] and [libraryPath] to
/// specify the location of the wasm and native library respectively.
Future<void> loadVodozemac({
  String wasmPath = 'pkg/vodozemac-bindings-dart',
  String libraryPath = '../rust/target/debug/libvodozemac_bindings_dart.dylib',
}) =>
    vodozemac.RustLib.init(
        externalLibrary: ExternalLibrary.open(
            bool.fromEnvironment('dart.library.html')
                ? wasmPath
                : libraryPath));

void isVodozemacLoaded() {
  if (!vodozemac.RustLib.instance.initialized) {
    throw Exception('Vodozemac library not loaded!');
  }
}

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
  Future<void> verify(
          {required String message, required Ed25519Signature signature}) =>
      _key.verify(message: message, signature: signature._key);
}

final class GroupSession {
  final vodozemac.VodozemacGroupSession _session;

  GroupSession._(this._session);

  static Future<GroupSession> create() async =>
      GroupSession._(vodozemac.VodozemacGroupSession(
        config: vodozemac.VodozemacMegolmSessionConfig.def(),
      ));

  String sessionId() => _session.sessionId();

  int messageIndex() => _session.messageIndex();

  Future<String> encrypt(String plaintext) =>
      _session.encrypt(plaintext: plaintext);

  Future<String> sessionKey() => _session.sessionKey();

  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<GroupSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      GroupSession._(await vodozemac.VodozemacGroupSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<GroupSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      GroupSession._(
          await vodozemac.VodozemacGroupSession.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));

  InboundGroupSession toInbound() =>
      InboundGroupSession._(_session.toInbound());
}

final class InboundGroupSession {
  final vodozemac.VodozemacInboundGroupSession _session;

  InboundGroupSession._(this._session);

  InboundGroupSession(String sessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession(
            sessionKey: sessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  InboundGroupSession.import(String sessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession.import_(
            sessionKey: sessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  String sessionId() => _session.sessionId();
  int firstKnownIndex() => _session.firstKnownIndex();

  Future<({String plaintext, int messageIndex})> decrypt(
      String encrypted) async {
    final result = await _session.decrypt(encrypted: encrypted);
    return (plaintext: result.field0, messageIndex: result.field1);
  }

  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<InboundGroupSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      InboundGroupSession._(
          await vodozemac.VodozemacInboundGroupSession.fromPickleEncrypted(
              pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<InboundGroupSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      InboundGroupSession._(
          await vodozemac.VodozemacInboundGroupSession.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));

  String? exportAt(int messageIndex) => _session.exportAt(index: messageIndex);
  String exportAtFirstKnownIndex() => _session.exportAtFirstKnownIndex();
}

final class Session {
  final vodozemac.VodozemacSession _session;

  Session._(this._session);

  String sessionId() => _session.sessionId();
  bool hasReceivedMessage() => _session.hasReceivedMessage();

  Future<({int messageType, String ciphertext})> encrypt(
      String plaintext) async {
    final encrypted = await _session.encrypt(plaintext: plaintext);
    return (
      messageType: encrypted.messageType().toInt(),
      ciphertext: encrypted.message(),
    );
  }

  Future<String> decrypt(
          {required int messageType, required String ciphertext}) =>
      _session.decrypt(
          message: vodozemac.VodozemacOlmMessage.fromParts(
              messageType: BigInt.from(messageType),
              ciphertext: Utils.base64decodeUnpadded(ciphertext)));

  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<Session> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      Session._(await vodozemac.VodozemacSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<Session> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      Session._(await vodozemac.VodozemacSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}

final class Account {
  final vodozemac.VodozemacAccount _account;

  Account._(this._account);

  static Future<Account> create() async =>
      Account._(vodozemac.VodozemacAccount());

  int maxNumberOfOneTimeKeys() => _account.maxNumberOfOneTimeKeys().toInt();

  Future<void> generateFallbackKey() => _account.generateFallbackKey();

  bool forgetFallbackKey() => _account.forgetFallbackKey();

  Future<void> generateOneTimeKeys(int count) =>
      _account.generateOneTimeKeys(count: BigInt.from(count));

  void markKeysAsPublished() => _account.markKeysAsPublished();

  Ed25519PublicKey ed25519Key() => Ed25519PublicKey._(_account.ed25519Key());

  Curve25519PublicKey curve25519Key() =>
      Curve25519PublicKey._(_account.curve25519Key());

  ({Ed25519PublicKey ed25519, Curve25519PublicKey curve25519}) identityKeys() {
    final keys = _account.identityKeys();
    return (
      ed25519: Ed25519PublicKey._(keys.ed25519),
      curve25519: Curve25519PublicKey._(keys.curve25519)
    );
  }

  Map<String, Curve25519PublicKey> oneTimeKeys() =>
      Map<String, Curve25519PublicKey>.fromEntries(_account
          .oneTimeKeys()
          .map((e) => MapEntry(e.keyid, Curve25519PublicKey._(e.key))));

  Map<String, Curve25519PublicKey> fallbackKey() =>
      Map<String, Curve25519PublicKey>.fromEntries(_account
          .fallbackKey()
          .map((e) => MapEntry(e.keyid, Curve25519PublicKey._(e.key))));

  Future<Ed25519Signature> sign(String message) async =>
      Ed25519Signature._(await _account.sign(message: message));

  Future<Session> createOutboundSession({
    required covariant Curve25519PublicKey identityKey,
    required covariant Curve25519PublicKey oneTimeKey,
  }) async =>
      Session._(await _account.createOutboundSession(
          config: vodozemac.VodozemacOlmSessionConfig.def(),
          identityKey: identityKey._key,
          oneTimeKey: oneTimeKey._key));

  Future<({Session session, String plaintext})> createInboundSession({
    required covariant Curve25519PublicKey theirIdentityKey,
    required String preKeyMessageBase64,
  }) async {
    final inb = await _account.createInboundSession(
        theirIdentityKey: theirIdentityKey._key,
        preKeyMessageBase64: preKeyMessageBase64);

    return (session: Session._(inb.session), plaintext: inb.plaintext);
  }

  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _account.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<Account> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      Account._(await vodozemac.VodozemacAccount.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<Account> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      Account._(await vodozemac.VodozemacAccount.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey));
}
