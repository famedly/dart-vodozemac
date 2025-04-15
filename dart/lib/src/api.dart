import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'dart:convert';

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

class Utils {
  static Uint8List base64decodeUnpadded(String s) {
    final needEquals = (4 - (s.length % 4)) % 4;
    return base64.decode(s + ('=' * needEquals));
  }
}

abstract base class Curve25519PublicKey {
  factory Curve25519PublicKey.fromBase64(String key) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacCurve25519PublicKey.fromBase64(key);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  factory Curve25519PublicKey.fromBytes(Uint8List key) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacCurve25519PublicKey.fromBytes(key);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  String toBase64();
  Uint8List toBytes();
}

final class VodozemacCurve25519PublicKey implements Curve25519PublicKey {
  final vodozemac.VodozemacCurve25519PublicKey _key;

  VodozemacCurve25519PublicKey._(this._key);

  VodozemacCurve25519PublicKey.fromBase64(String key)
      : _key =
            vodozemac.VodozemacCurve25519PublicKey.fromBase64(base64Key: key);
  VodozemacCurve25519PublicKey.fromBytes(Uint8List key)
      : _key = vodozemac.VodozemacCurve25519PublicKey.fromSlice(
            bytes: vodozemac.U8Array32(key));

  @override
  String toBase64() => _key.toBase64();
  @override
  Uint8List toBytes() => Uint8List.fromList(_key.asBytes());
}

abstract base class Ed25519Signature {
  factory Ed25519Signature.fromBase64(String key) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacEd25519Signature.fromBase64(key);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  factory Ed25519Signature.fromBytes(Uint8List key) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacEd25519Signature.fromBytes(key);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  String toBase64();
  Uint8List toBytes();
}

final class VodozemacEd25519Signature implements Ed25519Signature {
  final vodozemac.VodozemacEd25519Signature _key;

  VodozemacEd25519Signature._(this._key);
  VodozemacEd25519Signature.fromBase64(String key)
      : _key = vodozemac.VodozemacEd25519Signature.fromBase64(signature: key);
  VodozemacEd25519Signature.fromBytes(Uint8List key)
      : _key = vodozemac.VodozemacEd25519Signature.fromSlice(
            bytes: vodozemac.U8Array64(key));

  @override
  String toBase64() => _key.toBase64();
  @override
  Uint8List toBytes() => Uint8List.fromList(_key.toBytes());
}

abstract base class Ed25519PublicKey {
  factory Ed25519PublicKey.fromBase64(String key) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacEd25519PublicKey.fromBase64(key);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  factory Ed25519PublicKey.fromBytes(Uint8List key) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacEd25519PublicKey.fromBytes(key);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  String toBase64();
  Uint8List toBytes();

  Future<void> verify(
      {required String message, required Ed25519Signature signature});
}

final class VodozemacEd25519PublicKey implements Ed25519PublicKey {
  final vodozemac.VodozemacEd25519PublicKey _key;

  VodozemacEd25519PublicKey._(this._key);

  VodozemacEd25519PublicKey.fromBase64(String key)
      : _key = vodozemac.VodozemacEd25519PublicKey.fromBase64(base64Key: key);
  VodozemacEd25519PublicKey.fromBytes(Uint8List key)
      : _key = vodozemac.VodozemacEd25519PublicKey.fromSlice(
            bytes: vodozemac.U8Array32(key));

  @override
  String toBase64() => _key.toBase64();
  @override
  Uint8List toBytes() => Uint8List.fromList(_key.asBytes());
  @override
  Future<void> verify(
          {required String message,
          required covariant VodozemacEd25519Signature signature}) =>
      _key.verify(message: message, signature: signature._key);
}

abstract base class GroupSession {
  static Future<GroupSession> create() {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacGroupSession.create();
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  String sessionId();
  int messageIndex();

  Future<String> encrypt(String plaintext);

  Future<String> sessionKey();

  Future<String> toPickleEncrypted(Uint8List pickleKey);
  static Future<GroupSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacGroupSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  static Future<GroupSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacGroupSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  InboundGroupSession toInbound();
}

final class VodozemacGroupSession implements GroupSession {
  final vodozemac.VodozemacGroupSession _session;

  VodozemacGroupSession._(this._session);

  static Future<VodozemacGroupSession> create() async =>
      VodozemacGroupSession._(vodozemac.VodozemacGroupSession(
        config: vodozemac.VodozemacMegolmSessionConfig.def(),
      ));

  @override
  String sessionId() => _session.sessionId();

  @override
  int messageIndex() => _session.messageIndex();

  @override
  Future<String> encrypt(String plaintext) =>
      _session.encrypt(plaintext: plaintext);

  @override
  Future<String> sessionKey() => _session.sessionKey();

  @override
  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<VodozemacGroupSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacGroupSession._(
          await vodozemac.VodozemacGroupSession.fromPickleEncrypted(
        pickle: pickle,
        pickleKey: vodozemac.U8Array32(pickleKey),
      ));

  static Future<VodozemacGroupSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacGroupSession._(
          await vodozemac.VodozemacGroupSession.fromOlmPickleEncrypted(
        pickle: pickle,
        pickleKey: pickleKey,
      ));

  @override
  VodozemacInboundGroupSession toInbound() =>
      VodozemacInboundGroupSession._(_session.toInbound());
}

abstract base class InboundGroupSession {
  factory InboundGroupSession(String sessionKey) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacInboundGroupSession(sessionKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  factory InboundGroupSession.import(String sessionKey) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacInboundGroupSession.import(sessionKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  String sessionId();
  int firstKnownIndex();

  Future<({String plaintext, int messageIndex})> decrypt(String encrypted);

  Future<String> toPickleEncrypted(Uint8List pickleKey);
  static Future<GroupSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacGroupSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  static Future<GroupSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacGroupSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  String? exportAt(int messageIndex);
  String exportAtFirstKnownIndex();
}

final class VodozemacInboundGroupSession implements InboundGroupSession {
  final vodozemac.VodozemacInboundGroupSession _session;

  VodozemacInboundGroupSession._(this._session);

  VodozemacInboundGroupSession(String sessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession(
            sessionKey: sessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  VodozemacInboundGroupSession.import(String sessionKey)
      : _session = vodozemac.VodozemacInboundGroupSession.import_(
            sessionKey: sessionKey,
            config: vodozemac.VodozemacMegolmSessionConfig.def());

  @override
  String sessionId() => _session.sessionId();
  @override
  int firstKnownIndex() => _session.firstKnownIndex();

  @override
  Future<({String plaintext, int messageIndex})> decrypt(
      String encrypted) async {
    final result = await _session.decrypt(encrypted: encrypted);
    return (plaintext: result.field0, messageIndex: result.field1);
  }

  @override
  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<VodozemacInboundGroupSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacInboundGroupSession._(
          await vodozemac.VodozemacInboundGroupSession.fromPickleEncrypted(
              pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<VodozemacInboundGroupSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacInboundGroupSession._(
          await vodozemac.VodozemacInboundGroupSession.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));

  @override
  String? exportAt(int messageIndex) => _session.exportAt(index: messageIndex);
  @override
  String exportAtFirstKnownIndex() => _session.exportAtFirstKnownIndex();
}

abstract base class Session {
  String sessionId();
  bool hasReceivedMessage();

  Future<({int messageType, String ciphertext})> encrypt(String plaintext);
  Future<String> decrypt(
      {required int messageType, required String ciphertext});

  Future<String> toPickleEncrypted(Uint8List pickleKey);
  static Future<Session> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  static Future<Session> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacSession.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  // static int versionFromString({required String ciphertext}) {
  //   if (vodozemac.RustLib.instance.initialized) {
  //     return vodozemac.VodozemacOlmMessage.versionFromString(
  //         ciphertext: ciphertext);
  //   }

  //   throw UnimplementedError('No implemented backend loaded');
  // }
}

final class VodozemacSession implements Session {
  final vodozemac.VodozemacSession _session;

  VodozemacSession._(this._session);

  @override
  String sessionId() => _session.sessionId();
  @override
  bool hasReceivedMessage() => _session.hasReceivedMessage();

  @override
  Future<({int messageType, String ciphertext})> encrypt(
      String plaintext) async {
    final encrypted = await _session.encrypt(plaintext: plaintext);
    return (
      messageType: encrypted.messageType().toInt(),
      ciphertext: encrypted.message(),
    );
  }

  @override
  Future<String> decrypt(
          {required int messageType, required String ciphertext}) =>
      _session.decrypt(
          message: vodozemac.VodozemacOlmMessage.fromParts(
              messageType: BigInt.from(messageType),
              ciphertext: Utils.base64decodeUnpadded(ciphertext)));

  @override
  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _session.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<VodozemacSession> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacSession._(await vodozemac.VodozemacSession.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<VodozemacSession> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacSession._(
          await vodozemac.VodozemacSession.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));
}

abstract base class Account {
  static Future<Account> create() async {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacAccount.create();
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  int maxNumberOfOneTimeKeys();

  Future<void> generateFallbackKey();

  bool forgetFallbackKey();

  Future<void> generateOneTimeKeys(int count);

  void markKeysAsPublished();

  Ed25519PublicKey ed25519Key();

  Curve25519PublicKey curve25519Key();

  ({Ed25519PublicKey ed25519, Curve25519PublicKey curve25519}) identityKeys();

  Map<String, Curve25519PublicKey> oneTimeKeys();

  Map<String, Curve25519PublicKey> fallbackKey();

  Future<Ed25519Signature> sign(String message);

  Future<Session> createOutboundSession({
    required Curve25519PublicKey identityKey,
    required Curve25519PublicKey oneTimeKey,
  });

  Future<({Session session, String plaintext})> createInboundSession({
    required Curve25519PublicKey theirIdentityKey,
    required String preKeyMessageBase64,
  });

  Future<String> toPickleEncrypted(Uint8List pickleKey);

  static Future<Account> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacAccount.fromPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }

  static Future<Account> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) {
    if (vodozemac.RustLib.instance.initialized) {
      return VodozemacAccount.fromOlmPickleEncrypted(
          pickle: pickle, pickleKey: pickleKey);
    }

    throw UnimplementedError('No implemented backend loaded');
  }
}

final class VodozemacAccount implements Account {
  final vodozemac.VodozemacAccount _account;

  VodozemacAccount._(this._account);

  static Future<VodozemacAccount> create() async =>
      VodozemacAccount._(vodozemac.VodozemacAccount());

  @override
  int maxNumberOfOneTimeKeys() => _account.maxNumberOfOneTimeKeys().toInt();

  @override
  Future<void> generateFallbackKey() => _account.generateFallbackKey();

  @override
  bool forgetFallbackKey() => _account.forgetFallbackKey();

  @override
  Future<void> generateOneTimeKeys(int count) =>
      _account.generateOneTimeKeys(count: BigInt.from(count));

  @override
  void markKeysAsPublished() => _account.markKeysAsPublished();

  @override
  VodozemacEd25519PublicKey ed25519Key() =>
      VodozemacEd25519PublicKey._(_account.ed25519Key());

  @override
  VodozemacCurve25519PublicKey curve25519Key() =>
      VodozemacCurve25519PublicKey._(_account.curve25519Key());

  @override
  ({VodozemacEd25519PublicKey ed25519, VodozemacCurve25519PublicKey curve25519})
      identityKeys() {
    final keys = _account.identityKeys();
    return (
      ed25519: VodozemacEd25519PublicKey._(keys.ed25519),
      curve25519: VodozemacCurve25519PublicKey._(keys.curve25519)
    );
  }

  @override
  Map<String, VodozemacCurve25519PublicKey> oneTimeKeys() =>
      Map<String, VodozemacCurve25519PublicKey>.fromEntries(_account
          .oneTimeKeys()
          .map(
              (e) => MapEntry(e.keyid, VodozemacCurve25519PublicKey._(e.key))));

  @override
  Map<String, VodozemacCurve25519PublicKey> fallbackKey() =>
      Map<String, VodozemacCurve25519PublicKey>.fromEntries(_account
          .fallbackKey()
          .map(
              (e) => MapEntry(e.keyid, VodozemacCurve25519PublicKey._(e.key))));

  @override
  Future<VodozemacEd25519Signature> sign(String message) async =>
      VodozemacEd25519Signature._(await _account.sign(message: message));

  @override
  Future<VodozemacSession> createOutboundSession({
    required covariant VodozemacCurve25519PublicKey identityKey,
    required covariant VodozemacCurve25519PublicKey oneTimeKey,
  }) async =>
      VodozemacSession._(await _account.createOutboundSession(
          config: vodozemac.VodozemacOlmSessionConfig.def(),
          identityKey: identityKey._key,
          oneTimeKey: oneTimeKey._key));

  @override
  Future<({VodozemacSession session, String plaintext})> createInboundSession({
    required covariant VodozemacCurve25519PublicKey theirIdentityKey,
    required String preKeyMessageBase64,
  }) async {
    final inb = await _account.createInboundSession(
        theirIdentityKey: theirIdentityKey._key,
        preKeyMessageBase64: preKeyMessageBase64);

    return (session: VodozemacSession._(inb.session), plaintext: inb.plaintext);
  }

  @override
  Future<String> toPickleEncrypted(Uint8List pickleKey) =>
      _account.pickleEncrypted(pickleKey: vodozemac.U8Array32(pickleKey));

  static Future<VodozemacAccount> fromPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacAccount._(await vodozemac.VodozemacAccount.fromPickleEncrypted(
          pickle: pickle, pickleKey: vodozemac.U8Array32(pickleKey)));

  static Future<VodozemacAccount> fromOlmPickleEncrypted({
    required String pickle,
    required Uint8List pickleKey,
  }) async =>
      VodozemacAccount._(
          await vodozemac.VodozemacAccount.fromOlmPickleEncrypted(
              pickle: pickle, pickleKey: pickleKey));
}
