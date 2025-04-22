import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:test/test.dart';

import 'package:vodozemac/vodozemac.dart';

extension PublicCurveChecks on Subject<Curve25519PublicKey> {
  void isValid() {
    context.expect(() => ['meets this expectation'], (actual) {
      if ((actual.toBase64()).length == 43) return null;
      return Rejection(which: ['does not meet this expectation']);
    });
  }
}

extension AsyncIterableChecks<T> on Subject<Iterable<T>> {
  /// Expects there are no elements in the iterable which fail to satisfy
  /// [elementCondition].
  ///
  /// Empty iterables will pass always pass this expectation.
  Future<void> everyAsync(Condition<T> elementCondition) async {
    await context.expectAsync(() {
      final conditionDescription = describe(elementCondition);
      assert(conditionDescription.isNotEmpty);
      return [
        'only has values that:',
        ...conditionDescription,
      ];
    }, (actual) async {
      final iterator = actual.iterator;
      for (var i = 0; iterator.moveNext(); i++) {
        final element = iterator.current;
        final failure = await softCheckAsync(element, elementCondition);
        if (failure == null) continue;
        final which = failure.rejection.which;
        return Rejection(which: [
          'has an element at index $i that:',
          ...indent(failure.detail.actual.skip(1)),
          ...indent(prefixFirst('Actual: ', failure.rejection.actual),
              failure.detail.depth + 1),
          if (which != null && which.isNotEmpty)
            ...indent(prefixFirst('Which: ', which), failure.detail.depth + 1),
        ]);
      }
      return null;
    });
  }
}

extension Uint8ListChecks on Subject<Uint8List> {
  void isNotEmpty() {
    context.expect(() => ['is not empty'], (actual) {
      if (actual.isNotEmpty) return null;
      return Rejection(which: ['is empty']);
    });
  }
}

class Utils {
  static Uint8List base64decodeUnpadded(String s) {
    final needEquals = (4 - (s.length % 4)) % 4;
    return base64.decode(s + ('=' * needEquals));
  }

  static String encodeBase64Unpadded(List<int> s) {
    return base64Encode(s).replaceAll(RegExp(r'=+$', multiLine: true), '');
  }
}

void main() async {
  await loadVodozemac(
    wasmPath:
        './pkg/', // this is relative to the output file (compiled to js in `web/`)
    libraryPath:
        '../rust/target/debug/', // this is relative to the whole dart project
  );

  test('vodozemac is loaded', () {
    check(isVodozemacLoaded).returnsNormally();
  });

  group('Account', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('can be created', () async {
      await check(Account.create()).completes();
    });

    test('has sane max OTKs', () async {
      final account = await Account.create();

      check(account.maxNumberOfOneTimeKeys()).isGreaterOrEqual(50);
    });

    test('can generate OTKs', () async {
      final account = await Account.create();

      await check(account.generateOneTimeKeys(20)).completes();

      check(account.oneTimeKeys())
        ..length.equals(20)
        ..entries.every((subject) {
          subject.has((val) => val.key, 'keyid').length.equals(11);
          subject.has((val) => val.value, 'key').isValid();
        });
    });

    test('can generate fallback key', () async {
      final account = await Account.create();

      await check(account.generateFallbackKey()).completes();

      check(account.fallbackKey())
        ..length.equals(1)
        ..entries.every((subject) {
          subject.has((val) => val.key, 'keyid').length.equals(11);
          subject.has((val) => val.value, 'key').isValid();
        });
    });

    test('can publish fallback key', () async {
      final account = await Account.create();

      await check(account.generateFallbackKey()).completes();

      check(account.fallbackKey()).length.equals(1);

      check(account.markKeysAsPublished).returnsNormally();

      // forgetting returns false, because it was unused.
      check(account.forgetFallbackKey()).isFalse();

      check(account.fallbackKey()).length.equals(0);

      await check(account.generateFallbackKey()).completes();
      check(account.forgetFallbackKey()).isTrue();
    });

    test('sending olm messages works properly', () async {
      final account = await Account.create();
      final account2 = await Account.create();

      await check(account.generateOneTimeKeys(1)).completes();

      final onetimeKey = (account.oneTimeKeys()).values.first;

      check(account.markKeysAsPublished).returnsNormally();

      final outboundSession = await account2.createOutboundSession(
          identityKey: account.curve25519Key(), oneTimeKey: onetimeKey);
      check(outboundSession.hasReceivedMessage()).isFalse();

      final encrypted = await outboundSession.encrypt('Test');
      final inbound = await account.createInboundSession(
          theirIdentityKey: account2.curve25519Key(),
          preKeyMessageBase64: encrypted.ciphertext);

      check(inbound.plaintext).equals('Test');
      check(inbound.session.hasReceivedMessage()).isTrue();

      final encrypted2 = await inbound.session.encrypt('Test2');

      check(outboundSession.hasReceivedMessage()).isFalse();
      await check(outboundSession.decrypt(
              messageType: encrypted2.messageType,
              ciphertext: encrypted2.ciphertext))
          .completes((subject) => subject.equals('Test2'));
      check(outboundSession.hasReceivedMessage()).isTrue();
    });

    test('sending olm messages works properly with fallback key', () async {
      final account = await Account.create();
      final account2 = await Account.create();

      await check(account.generateFallbackKey()).completes();

      final onetimeKey = account.fallbackKey().values.first;

      check(account.markKeysAsPublished).returnsNormally();

      final outboundSession = await account2.createOutboundSession(
          identityKey: account.curve25519Key(), oneTimeKey: onetimeKey);
      check(outboundSession.hasReceivedMessage()).isFalse();

      final encrypted = await outboundSession.encrypt('Test');
      final inbound = await account.createInboundSession(
          theirIdentityKey: account2.curve25519Key(),
          preKeyMessageBase64: encrypted.ciphertext);

      check(inbound.plaintext).equals('Test');
      check(inbound.session.hasReceivedMessage()).isTrue();

      final encrypted2 = await inbound.session.encrypt('Test2');

      check(outboundSession.hasReceivedMessage()).isFalse();
      await check(outboundSession.decrypt(
              messageType: encrypted2.messageType,
              ciphertext: encrypted2.ciphertext))
          .completes((subject) => subject.equals('Test2'));
      check(outboundSession.hasReceivedMessage()).isTrue();
    });

    test('can sign messages', () async {
      final account = await Account.create();

      final signature = await account.sign('Abc');

      final signKey = account.ed25519Key();
      await check(signKey.verify(message: 'Abc', signature: signature))
          .completes();
      await check(signKey.verify(message: 'Abcd', signature: signature))
          .throws();
    });
  });

  group('Megolm session can', () {
    test('be created', () async {
      await check(GroupSession.create()).completes();
    });

    test('encrypt and decrypt', () async {
      final groupSession = await GroupSession.create();
      final inbound = groupSession.toInbound();

      final encrypted = await groupSession.encrypt('Test');

      check(encrypted).not((subject) => subject.contains('Test'));
      await check(inbound.decrypt(encrypted)).completes((subject) =>
          subject.has((res) => res.plaintext, 'plaintext').equals('Test'));

      // ensure that a later exported session does not decrypt the message
      final inboundAfter = groupSession.toInbound();
      await check(inboundAfter.decrypt(encrypted)).throws();
    });

    test('be imported and exported', () async {
      final groupSession = await GroupSession.create();
      final inbound = groupSession.toInbound();
      final reimportedInbound =
          InboundGroupSession.import(inbound.exportAtFirstKnownIndex());
      final laterInbound = InboundGroupSession.import(inbound.exportAt(1)!);

      final encrypted = await groupSession.encrypt('Test');
      final encrypted2 = await groupSession.encrypt('Test');

      check(encrypted).not((subject) => subject.equals(encrypted2));

      check(encrypted).not((subject) => subject.contains('Test'));
      await check(reimportedInbound.decrypt(encrypted)).completes((subject) =>
          subject.has((res) => res.plaintext, 'plaintext').equals('Test'));

      // ensure that a later exported session does not decrypt the message
      await check(laterInbound.decrypt(encrypted)).throws();

      // check if second index decryptes
      await check(reimportedInbound.decrypt(encrypted2)).completes((subject) =>
          subject.has((res) => res.plaintext, 'plaintext').equals('Test'));

      await check(laterInbound.decrypt(encrypted2)).completes((subject) =>
          subject.has((res) => res.plaintext, 'plaintext').equals('Test'));
    });
  });

  group('PkEncryption and PkDecryption', () {
    test('encryption roundtrip works', () async {
      final decryptor = PkDecryption();
      final publicKey = decryptor.publicKey();
      final encryptor =
          PkEncryption.fromPublicKey(Curve25519PublicKey.fromBase64(publicKey));

      final message = "It's a secret to everybody";
      final encrypted = await encryptor.encrypt(message);

      check(encrypted.ciphertext()).isNotEmpty();
      check(encrypted.mac()).isNotEmpty();
      check(encrypted.ephemeralKey()).isValid();

      final decrypted = await decryptor.decrypt(encrypted);
      check(decrypted).equals(message);
    });

    test('can create from secret key', () async {
      final decryptor = PkDecryption();
      final privateKeyBytes = await decryptor.privateKey();
      final publicKey = decryptor.publicKey();

      // Create new decryptor from secret key
      final restoredDecryptor = PkDecryption.fromSecretKey(
          Curve25519PublicKey.fromBytes(privateKeyBytes));

      // Public keys should match
      check(restoredDecryptor.publicKey()).equals(publicKey);

      // Test encryption/decryption with restored key
      final encryptor =
          PkEncryption.fromPublicKey(Curve25519PublicKey.fromBase64(publicKey));
      final message = "Test message";
      final encrypted = await encryptor.encrypt(message);
      final decrypted = await restoredDecryptor.decrypt(encrypted);
      check(decrypted).equals(message);
    });

    test('can pickle and unpickle', () async {
      final decryptor = PkDecryption();
      final publicKey = decryptor.publicKey();
      final pickleKey = Uint8List.fromList(List.generate(32, (i) => i));

      // Create encrypted pickle
      final pickle = await decryptor.toLibolmPickle(pickleKey);

      // Restore from pickle
      final restoredDecryptor = await PkDecryption.fromLibolmPickle(
          pickle: pickle, pickleKey: pickleKey);

      // Public keys should match
      check(restoredDecryptor.publicKey()).equals(publicKey);

      // Test encryption/decryption with restored key
      final encryptor =
          PkEncryption.fromPublicKey(Curve25519PublicKey.fromBase64(publicKey));
      final message = "Test message";
      final encrypted = await encryptor.encrypt(message);
      final decrypted = await restoredDecryptor.decrypt(encrypted);
      check(decrypted).equals(message);
    });

    test('different keys produce different ciphertexts', () async {
      final decryptor1 = PkDecryption();
      final decryptor2 = PkDecryption();
      final encryptor1 = PkEncryption.fromPublicKey(
          Curve25519PublicKey.fromBase64(decryptor1.publicKey()));
      final encryptor2 = PkEncryption.fromPublicKey(
          Curve25519PublicKey.fromBase64(decryptor2.publicKey()));

      final message = "Test message";
      final encrypted1 = await encryptor1.encrypt(message);
      final encrypted2 = await encryptor2.encrypt(message);

      // Ciphertexts should be different
      check(encrypted1.ciphertext())
          .not((subject) => subject.equals(encrypted2.ciphertext()));

      // But both should decrypt correctly with their respective keys
      final decrypted1 = await decryptor1.decrypt(encrypted1);
      final decrypted2 = await decryptor2.decrypt(encrypted2);
      check(decrypted1).equals(message);
      check(decrypted2).equals(message);

      // Cross-decryption should fail
      await check(decryptor2.decrypt(encrypted1)).throws();
      await check(decryptor1.decrypt(encrypted2)).throws();
    });
  });

  group('PkSigning', () {
    test('can sign and verify messages', () async {
      final signing = PkSigning();
      final message = "Hello, world!";
      final signature = signing.sign(message);
      check(signature.toBase64()).isNotEmpty();
      check(signing.publicKey().verify(message: message, signature: signature))
          .completes();
    });

    test('fails to verify modified messages', () async {
      final signing = PkSigning();
      final message = "Hello, world!";
      final signature = signing.sign(message);

      // Should fail for different message
      await check(signing.publicKey().verify(
              message: "Hello, World!", // Capital W
              signature: signature))
          .throws();

      // Should fail for truncated message
      await check(signing.publicKey().verify(
              message: "Hello, world", // removed !
              signature: signature))
          .throws();
    });

    test('different keys produce different signatures', () async {
      final signing1 = PkSigning();
      final signing2 = PkSigning();
      final message = "Hello, world!";

      final signature1 = signing1.sign(message);
      final signature2 = signing2.sign(message);

      // Signatures should be different
      check(signature1.toBase64())
          .not((subject) => subject.equals(signature2.toBase64()));

      // Each signature should verify with its own key
      await check(signing1
              .publicKey()
              .verify(message: message, signature: signature1))
          .completes();
      await check(signing2
              .publicKey()
              .verify(message: message, signature: signature2))
          .completes();

      // Cross-verification should fail
      await check(signing1
              .publicKey()
              .verify(message: message, signature: signature2))
          .throws();
      await check(signing2
              .publicKey()
              .verify(message: message, signature: signature1))
          .throws();
    });

    test('can create from seed', () async {
      final seed = Uint8List.fromList(List.generate(32, (i) => i));
      final signing1 =
          PkSigning.fromSecretKey(Utils.encodeBase64Unpadded(seed));
      final signing2 =
          PkSigning.fromSecretKey(Utils.encodeBase64Unpadded(seed));

      // Same seed should produce same key pair
      check(signing1.publicKey().toBase64())
          .equals(signing2.publicKey().toBase64());

      // Signatures from both instances should be verifiable by either public key
      final message = "Test message";
      final signature1 = signing1.sign(message);
      final signature2 = signing2.sign(message);

      await check(signing1
              .publicKey()
              .verify(message: message, signature: signature2))
          .completes();
      await check(signing2
              .publicKey()
              .verify(message: message, signature: signature1))
          .completes();
    });

    test('handles empty and special messages', () async {
      final signing = PkSigning();

      // Empty message
      final emptySignature = signing.sign("");
      await check(signing
              .publicKey()
              .verify(message: "", signature: emptySignature))
          .completes();

      // Message with special characters
      final specialMessage = "!@#\$%^&*()_+\n\t\r";
      final specialSignature = signing.sign(specialMessage);
      await check(signing
              .publicKey()
              .verify(message: specialMessage, signature: specialSignature))
          .completes();

      // Long message
      final longMessage = "a" * 1000;
      final longSignature = signing.sign(longMessage);
      await check(signing
              .publicKey()
              .verify(message: longMessage, signature: longSignature))
          .completes();
    });
  });
}
