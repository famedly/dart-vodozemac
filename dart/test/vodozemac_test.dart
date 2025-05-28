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
  await init(
    wasmPath:
        './pkg/', // this is relative to the output file (compiled to js in `web/`)
    libraryPath:
        '../rust/target/debug/', // this is relative to the whole dart project
  );

  test('vodozemac is loaded', () {
    check(isInitialized()).isTrue();
  });

  group('Account', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('can be created', () async {
      check(Account()).isNotNull();
    });

    test('has sane max OTKs', () async {
      final account = Account();

      check(account.maxNumberOfOneTimeKeys).isGreaterOrEqual(50);
    });

    test('can generate OTKs', () async {
      final account = Account();

      expect(() => account.generateOneTimeKeys(20), returnsNormally);

      check(account.oneTimeKeys)
        ..length.equals(20)
        ..entries.every((subject) {
          subject.has((val) => val.key, 'keyid').length.equals(11);
          subject.has((val) => val.value, 'key').isValid();
        });
    });

    test('can generate fallback key', () async {
      final account = Account();

      expect(() => account.generateFallbackKey(), returnsNormally);

      check(account.fallbackKey)
        ..length.equals(1)
        ..entries.every((subject) {
          subject.has((val) => val.key, 'keyid').length.equals(11);
          subject.has((val) => val.value, 'key').isValid();
        });
    });

    test('can publish fallback key', () async {
      final account = Account();

      expect(() => account.generateFallbackKey(), returnsNormally);

      check(account.fallbackKey).length.equals(1);

      check(account.markKeysAsPublished).returnsNormally();

      // forgetting returns false, because it was unused.
      check(account.forgetFallbackKey()).isFalse();

      check(account.fallbackKey).length.equals(0);

      expect(() => account.generateFallbackKey(), returnsNormally);
      check(account.forgetFallbackKey()).isTrue();
    });

    test('sending olm messages works properly', () async {
      final account = Account();
      final account2 = Account();

      expect(() => account.generateOneTimeKeys(1), returnsNormally);

      final onetimeKey = account.oneTimeKeys.values.first;

      check(account.markKeysAsPublished).returnsNormally();

      final outboundSession = account2.createOutboundSession(
          identityKey: account.curve25519Key, oneTimeKey: onetimeKey);
      check(outboundSession.hasReceivedMessage).isFalse();

      final encrypted = outboundSession.encrypt('Test');
      final inbound = account.createInboundSession(
          theirIdentityKey: account2.curve25519Key,
          preKeyMessageBase64: encrypted.ciphertext);

      check(inbound.plaintext).equals('Test');
      check(inbound.session.hasReceivedMessage).isTrue();

      final encrypted2 = inbound.session.encrypt('Test2');

      check(outboundSession.hasReceivedMessage).isFalse();
      check(outboundSession.decrypt(
              messageType: encrypted2.messageType,
              ciphertext: encrypted2.ciphertext))
          .equals('Test2');
      check(outboundSession.hasReceivedMessage).isTrue();
    });

    test('sending olm messages works properly with fallback key', () async {
      final account = Account();
      final account2 = Account();

      expect(() => account.generateFallbackKey(), returnsNormally);

      final onetimeKey = account.fallbackKey.values.first;

      check(account.markKeysAsPublished).returnsNormally();

      final outboundSession = account2.createOutboundSession(
          identityKey: account.curve25519Key, oneTimeKey: onetimeKey);
      check(outboundSession.hasReceivedMessage).isFalse();

      final encrypted = outboundSession.encrypt('Test');
      final inbound = account.createInboundSession(
          theirIdentityKey: account2.curve25519Key,
          preKeyMessageBase64: encrypted.ciphertext);

      check(inbound.plaintext).equals('Test');
      check(inbound.session.hasReceivedMessage).isTrue();

      final encrypted2 = inbound.session.encrypt('Test2');

      check(outboundSession.hasReceivedMessage).isFalse();
      check(outboundSession.decrypt(
              messageType: encrypted2.messageType,
              ciphertext: encrypted2.ciphertext))
          .equals('Test2');
      check(outboundSession.hasReceivedMessage).isTrue();
    });

    test('can sign messages', () async {
      final account = Account();

      final signature = account.sign('Abc');

      final signKey = account.ed25519Key;
      expect(() => signKey.verify(message: 'Abc', signature: signature),
          returnsNormally);
      expect(() => signKey.verify(message: 'Abcd', signature: signature),
          throwsA(anything));
    });

    test('messageType indicates whether message is pre-key or normal',
        () async {
      final alice = Account();
      final bob = Account();

      alice.generateOneTimeKeys(1);
      final oneTimeKey = alice.oneTimeKeys.values.first;

      final bobSession = bob.createOutboundSession(
          identityKey: alice.curve25519Key, oneTimeKey: oneTimeKey);

      // First message should be a pre-key message (type 0)
      final firstMsg = bobSession.encrypt('First message');
      check(firstMsg.messageType).equals(0);

      // Create Alice's session from Bob's pre-key message
      final aliceSession = alice
          .createInboundSession(
              theirIdentityKey: bob.curve25519Key,
              preKeyMessageBase64: firstMsg.ciphertext)
          .session;

      // Alice sends a message back to Bob
      final aliceMsg = aliceSession.encrypt('Alice response');

      // This should be a normal message (type 1)
      check(aliceMsg.messageType).equals(1);

      // Bob can decrypt it
      check(bobSession.decrypt(
              messageType: aliceMsg.messageType,
              ciphertext: aliceMsg.ciphertext))
          .equals('Alice response');

      // Now Bob has received a message, so future messages from Bob should be normal
      final bobSecondMsg = bobSession.encrypt('Bob second message');
      check(bobSecondMsg.messageType).equals(1);
    });
  });

  group('Megolm session can', () {
    test('be created', () async {
      check(GroupSession()).isNotNull();
    });

    test('inbound can be created from a session key and also from an object',
        () async {
      final groupSession = GroupSession();
      final inbound = InboundGroupSession(groupSession.sessionKey);
      final inboundFromObj = groupSession.toInbound();
      check(inbound).isNotNull();
      check(inboundFromObj).isNotNull();
      check(inbound.sessionId).equals(inboundFromObj.sessionId);
    });

    test('encrypt and decrypt', () async {
      final groupSession = GroupSession();
      final inbound = InboundGroupSession(groupSession.sessionKey);

      final encrypted = groupSession.encrypt('Test');

      check(encrypted).not((subject) => subject.contains('Test'));
      check(inbound.decrypt(encrypted))
          .has((res) => res.plaintext, 'plaintext')
          .equals('Test');

      // ensure that a later exported session does not decrypt the message
      final inboundAfter = InboundGroupSession(groupSession.sessionKey);
      expect(() => inboundAfter.decrypt(encrypted), throwsA(anything));
    });

    test('be imported and exported', () async {
      final groupSession = GroupSession();
      final inbound = InboundGroupSession(groupSession.sessionKey);
      final reimportedInbound =
          InboundGroupSession.import(inbound.exportAtFirstKnownIndex());
      final laterInbound = InboundGroupSession.import(inbound.exportAt(1)!);

      final encrypted = groupSession.encrypt('Test');
      final encrypted2 = groupSession.encrypt('Test');

      check(encrypted).not((subject) => subject.equals(encrypted2));

      check(encrypted).not((subject) => subject.contains('Test'));
      check(reimportedInbound.decrypt(encrypted))
          .has((res) => res.plaintext, 'plaintext')
          .equals('Test');

      // ensure that a later exported session does not decrypt the message
      expect(() => laterInbound.decrypt(encrypted), throwsA(anything));

      // check if second index decryptes
      check(reimportedInbound.decrypt(encrypted2))
          .has((res) => res.plaintext, 'plaintext')
          .equals('Test');

      check(laterInbound.decrypt(encrypted2))
          .has((res) => res.plaintext, 'plaintext')
          .equals('Test');
    });

    test('handle multiple exports at different indices', () async {
      final groupSession = GroupSession();
      final inbound = InboundGroupSession(groupSession.sessionKey);

      // Send multiple messages
      final encrypted1 = groupSession.encrypt('Message 1');
      final encrypted2 = groupSession.encrypt('Message 2');
      final encrypted3 = groupSession.encrypt('Message 3');

      // Export at each index
      final export0 = inbound.exportAtFirstKnownIndex();
      final export1 = inbound.exportAt(1)!;
      final export2 = inbound.exportAt(2)!;

      // Import at different indices
      final importedAt0 = InboundGroupSession.import(export0);
      final importedAt1 = InboundGroupSession.import(export1);
      final importedAt2 = InboundGroupSession.import(export2);

      // Verify imports at index 0 can decrypt all messages
      check(importedAt0.decrypt(encrypted1).plaintext).equals('Message 1');
      check(importedAt0.decrypt(encrypted2).plaintext).equals('Message 2');
      check(importedAt0.decrypt(encrypted3).plaintext).equals('Message 3');

      // Verify imports at index 1 can decrypt messages 2 and 3 but not 1
      expect(() => importedAt1.decrypt(encrypted1), throwsA(anything));
      check(importedAt1.decrypt(encrypted2).plaintext).equals('Message 2');
      check(importedAt1.decrypt(encrypted3).plaintext).equals('Message 3');

      // Verify imports at index 2 can decrypt only message 3
      expect(() => importedAt2.decrypt(encrypted1), throwsA(anything));
      expect(() => importedAt2.decrypt(encrypted2), throwsA(anything));
      check(importedAt2.decrypt(encrypted3).plaintext).equals('Message 3');
    });
  });

  group('Sas', () {
    test('can establish shared secret', () async {
      final alice = Sas();
      final bob = Sas();

      check(alice.publicKey).isNotEmpty();
      check(bob.publicKey).isNotEmpty();

      final aliceEstablished = alice.establishSasSecret(bob.publicKey);
      final bobEstablished = bob.establishSasSecret(alice.publicKey);

      // Both should generate the same bytes for the same info string
      final aliceBytes = aliceEstablished.generateBytes("SAS", 6);
      final bobBytes = bobEstablished.generateBytes("SAS", 6);

      check(aliceBytes).deepEquals(bobBytes);
    });

    test('can calculate and verify MACs', () async {
      final alice = Sas();
      final bob = Sas();

      final aliceEstablished = alice.establishSasSecret(bob.publicKey);
      final bobEstablished = bob.establishSasSecret(alice.publicKey);

      final message = "test message";
      final info = "MAC info";

      final aliceMac = aliceEstablished.calculateMac(message, info);
      final bobMac = bobEstablished.calculateMac(message, info);

      // Both should calculate the same MAC
      check(aliceMac).equals(bobMac);

      // Verification should succeed
      expect(() => aliceEstablished.verifyMac(message, info, bobMac),
          returnsNormally);
      expect(() => bobEstablished.verifyMac(message, info, aliceMac),
          returnsNormally);

      // Verification should fail with wrong message
      expect(() => aliceEstablished.verifyMac("wrong message", info, bobMac),
          throwsA(anything));
      // Verification should fail with wrong info
      expect(() => aliceEstablished.verifyMac(message, "wrong info", bobMac),
          throwsA(anything));
    });

    test('can calculate deprecated MAC format', () async {
      final alice = Sas();
      final bob = Sas();

      final aliceEstablished = alice.establishSasSecret(bob.publicKey);
      final bobEstablished = bob.establishSasSecret(alice.publicKey);

      final message = "test message";
      final info = "MAC info";

      final aliceMac = aliceEstablished.calculateMacDeprecated(message, info);
      final bobMac = bobEstablished.calculateMacDeprecated(message, info);

      // Both should calculate the same MAC in deprecated format
      check(aliceMac).equals(bobMac);
    });

    test('emoji generation', () async {
      final alice = Sas();
      final bob = Sas();

      final aliceEstablished = alice.establishSasSecret(bob.publicKey);
      final bobEstablished = bob.establishSasSecret(alice.publicKey);

      // Generate bytes for emoji representation (should be 6 bytes)
      final bytes = aliceEstablished.generateBytes("EMOJI", 6);
      check(bytes.length).equals(6);

      // In a real application, these bytes would be converted to emoji indices
      // Here we'll just verify both sides get the same bytes
      final bobBytes = bobEstablished.generateBytes("EMOJI", 6);
      check(bytes).deepEquals(bobBytes);
    });

    test('handle errors properly', () async {
      final alice = Sas();

      // Should throw when establishing with invalid base64
      expect(() => alice.establishSasSecret("invalid base64!!!"),
          throwsA(anything));

      // Create valid established SAS
      final bob = Sas();

      // Should throw now that alice has been disposed
      expect(() => alice.establishSasSecret(bob.publicKey), throwsA(anything));

      // Create a new Sas object for alice again
      final aliceNew = Sas();
      final aliceEstablished = aliceNew.establishSasSecret(bob.publicKey);

      // Should throw when verifying with invalid MAC
      expect(
          () => aliceEstablished.verifyMac("message", "info", "invalid mac!!!"),
          throwsA(anything));
    });

    test('generates consistent decimal representation', () async {
      final alice = Sas();
      final bob = Sas();

      final aliceEstablished = alice.establishSasSecret(bob.publicKey);
      final bobEstablished = bob.establishSasSecret(alice.publicKey);

      // Generate bytes for decimal representation
      // In Matrix, this uses 5 bytes to create 3 pairs of digits (0-99)
      // refer: https://spec.matrix.org/latest/client-server-api/#sas-method-decimal
      final aliceBytes = aliceEstablished.generateBytes("DECIMAL", 5);
      final bobBytes = bobEstablished.generateBytes("DECIMAL", 5);

      check(aliceBytes).deepEquals(bobBytes);

      // Simulate converting to decimal pairs as would be done in a real app
      List<int> bytesToDecimals(Uint8List bytes) {
        final result = <int>[];

        // Use first 5 bytes to generate 3 pairs of decimal digits (0-99)
        for (int i = 0; i < 3; i++) {
          final decimal = (bytes[i] << 8) | bytes[i + 2];
          result.add(decimal % 100);
        }

        return result;
      }

      final aliceDecimals = bytesToDecimals(aliceBytes);
      final bobDecimals = bytesToDecimals(bobBytes);

      // Both sides should generate the same decimal digits
      check(aliceDecimals).deepEquals(bobDecimals);
    });
  });

  group('PkEncryption and PkDecryption', () {
    test('encryption roundtrip works', () async {
      final decryptor = PkDecryption();
      final publicKey = decryptor.publicKey;
      final encryptor =
          PkEncryption.fromPublicKey(Curve25519PublicKey.fromBase64(publicKey));

      final message = "It's a secret to everybody";
      final encrypted = encryptor.encrypt(message);

      check(encrypted.ciphertext).isNotEmpty();
      check(encrypted.mac).isNotEmpty();
      check(encrypted.ephemeralKey).isValid();

      final decrypted = decryptor.decrypt(encrypted);
      check(decrypted).equals(message);
    });

    test('can create from secret key', () async {
      final decryptor = PkDecryption();
      final privateKeyBytes = decryptor.privateKey;
      final publicKey = decryptor.publicKey;

      // Create new decryptor from secret key
      final restoredDecryptor = PkDecryption.fromSecretKey(
          Curve25519PublicKey.fromBytes(privateKeyBytes));

      // Public keys should match
      check(restoredDecryptor.publicKey).equals(publicKey);

      // Test encryption/decryption with restored key
      final encryptor =
          PkEncryption.fromPublicKey(Curve25519PublicKey.fromBase64(publicKey));
      final message = "Test message";
      final encrypted = encryptor.encrypt(message);
      final decrypted = restoredDecryptor.decrypt(encrypted);
      check(decrypted).equals(message);
    });

    test('can pickle and unpickle', () async {
      final decryptor = PkDecryption();
      final publicKey = decryptor.publicKey;
      final pickleKey = Uint8List.fromList(List.generate(32, (i) => i));

      // Create encrypted pickle
      final pickle = decryptor.toLibolmPickle(pickleKey);

      // Restore from pickle
      final restoredDecryptor =
          PkDecryption.fromLibolmPickle(pickle: pickle, pickleKey: pickleKey);

      // Public keys should match
      check(restoredDecryptor.publicKey).equals(publicKey);

      // Test encryption/decryption with restored key
      final encryptor =
          PkEncryption.fromPublicKey(Curve25519PublicKey.fromBase64(publicKey));
      final message = "Test message";
      final encrypted = encryptor.encrypt(message);
      final decrypted = restoredDecryptor.decrypt(encrypted);
      check(decrypted).equals(message);
    });

    test('different keys produce different ciphertexts', () async {
      final decryptor1 = PkDecryption();
      final decryptor2 = PkDecryption();
      final encryptor1 = PkEncryption.fromPublicKey(
          Curve25519PublicKey.fromBase64(decryptor1.publicKey));
      final encryptor2 = PkEncryption.fromPublicKey(
          Curve25519PublicKey.fromBase64(decryptor2.publicKey));

      final message = "Test message";
      final encrypted1 = encryptor1.encrypt(message);
      final encrypted2 = encryptor2.encrypt(message);

      // Ciphertexts should be different
      check(encrypted1.ciphertext)
          .not((subject) => subject.equals(encrypted2.ciphertext));

      // But both should decrypt correctly with their respective keys
      final decrypted1 = decryptor1.decrypt(encrypted1);
      final decrypted2 = decryptor2.decrypt(encrypted2);
      check(decrypted1).equals(message);
      check(decrypted2).equals(message);

      // Cross-decryption should fail
      expect(() => decryptor2.decrypt(encrypted1), throwsA(anything));
      expect(() => decryptor1.decrypt(encrypted2), throwsA(anything));
    });

    test('can handle empty and large messages', () async {
      final decryptor = PkDecryption();
      final encryptor = PkEncryption.fromPublicKey(
          Curve25519PublicKey.fromBase64(decryptor.publicKey));

      // Test empty message
      final emptyEncrypted = encryptor.encrypt("");
      final emptyDecrypted = decryptor.decrypt(emptyEncrypted);
      check(emptyDecrypted).equals("");

      // Test large message
      final largeMessage = "A" * 10000;
      final largeEncrypted = encryptor.encrypt(largeMessage);
      final largeDecrypted = decryptor.decrypt(largeEncrypted);
      check(largeDecrypted).equals(largeMessage);
    });

    test('PkMessage supports direct construction and Base64 conversion',
        () async {
      // Create a PkMessage directly
      final ciphertext = Uint8List.fromList([1, 2, 3]);
      final mac = Uint8List.fromList([4, 5, 6]);
      final decryptor = PkDecryption();
      final ephemeralKey = Curve25519PublicKey.fromBase64(decryptor.publicKey);

      final message = PkMessage(ciphertext, mac, ephemeralKey);

      // Convert to Base64
      final base64Data = message.toBase64();

      // Convert back from Base64
      final recreated = PkMessage.fromBase64(
        ciphertext: base64Data.$1,
        mac: base64Data.$2,
        ephemeralKey: base64Data.$3,
      );

      // Verify values match
      check(recreated.ciphertext).deepEquals(ciphertext);
      check(recreated.mac).deepEquals(mac);
      check(recreated.ephemeralKey.toBase64()).equals(ephemeralKey.toBase64());
    });
  });

  group('PkSigning', () {
    test('can sign and verify messages', () async {
      final signing = PkSigning();
      final message = "Hello, world!";
      final signature = signing.sign(message);
      check(signature.toBase64()).isNotEmpty();
      expect(
          () =>
              signing.publicKey.verify(message: message, signature: signature),
          returnsNormally);
    });

    test('fails to verify modified messages', () async {
      final signing = PkSigning();
      final message = "Hello, world!";
      final signature = signing.sign(message);

      // Should fail for different message
      expect(
          () => signing.publicKey.verify(
              message: "Hello, World!", // Capital W
              signature: signature),
          throwsA(anything));

      // Should fail for truncated message
      expect(
          () => signing.publicKey.verify(
              message: "Hello, world", // removed !
              signature: signature),
          throwsA(anything));
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
      expect(
          () => signing1.publicKey
              .verify(message: message, signature: signature1),
          returnsNormally);
      expect(
          () => signing2.publicKey
              .verify(message: message, signature: signature2),
          returnsNormally);

      // Cross-verification should fail
      expect(
          () => signing1.publicKey
              .verify(message: message, signature: signature2),
          throwsA(anything));
      expect(
          () => signing2.publicKey
              .verify(message: message, signature: signature1),
          throwsA(anything));
    });

    test('can create from seed', () async {
      final seed = Uint8List.fromList(List.generate(32, (i) => i));
      final signing1 =
          PkSigning.fromSecretKey(Utils.encodeBase64Unpadded(seed));
      final signing2 =
          PkSigning.fromSecretKey(Utils.encodeBase64Unpadded(seed));

      // Same seed should produce same key pair
      check(signing1.publicKey.toBase64())
          .equals(signing2.publicKey.toBase64());

      // Signatures from both instances should be verifiable by either public key
      final message = "Test message";
      final signature1 = signing1.sign(message);
      final signature2 = signing2.sign(message);

      expect(
          () => signing1.publicKey
              .verify(message: message, signature: signature2),
          returnsNormally);
      expect(
          () => signing2.publicKey
              .verify(message: message, signature: signature1),
          returnsNormally);
    });

    test('handles empty and special messages', () async {
      final signing = PkSigning();

      // Empty message
      final emptySignature = signing.sign("");
      expect(
          () =>
              signing.publicKey.verify(message: "", signature: emptySignature),
          returnsNormally);

      // Message with special characters
      final specialMessage = "!@#\$%^&*()_+\n\t\r";
      final specialSignature = signing.sign(specialMessage);
      expect(
          () => signing.publicKey
              .verify(message: specialMessage, signature: specialSignature),
          returnsNormally);

      // Long message
      final longMessage = "a" * 1000;
      final longSignature = signing.sign(longMessage);
      expect(
          () => signing.publicKey
              .verify(message: longMessage, signature: longSignature),
          returnsNormally);
    });
  });

  group('Curve25519 and Ed25519 keys', () {
    test('can convert Curve25519 keys between formats', () async {
      final account = Account();
      final originalKey = account.curve25519Key;

      // Convert to base64 and back
      final base64 = originalKey.toBase64();
      final fromBase64 = Curve25519PublicKey.fromBase64(base64);
      check(fromBase64.toBase64()).equals(base64);

      // Convert to bytes and back
      final bytes = originalKey.toBytes();
      check(bytes.length).equals(32);
      final fromBytes = Curve25519PublicKey.fromBytes(bytes);
      check(fromBytes.toBase64()).equals(base64);
    });

    test('can convert Ed25519 keys between formats', () async {
      final account = Account();
      final originalKey = account.ed25519Key;

      // Convert to base64 and back
      final base64 = originalKey.toBase64();
      final fromBase64 = Ed25519PublicKey.fromBase64(base64);
      check(fromBase64.toBase64()).equals(base64);

      // Convert to bytes and back
      final bytes = originalKey.toBytes();
      check(bytes.length).equals(32);
      final fromBytes = Ed25519PublicKey.fromBytes(bytes);
      check(fromBytes.toBase64()).equals(base64);
    });

    test('can convert Ed25519 signatures between formats', () async {
      final account = Account();
      final signature = account.sign('Test message');

      // Convert to base64 and back
      final base64 = signature.toBase64();
      final fromBase64 = Ed25519Signature.fromBase64(base64);
      check(fromBase64.toBase64()).equals(base64);

      // Convert to bytes and back
      final bytes = signature.toBytes();
      check(bytes.length).equals(64);
      final fromBytes = Ed25519Signature.fromBytes(bytes);
      check(fromBytes.toBase64()).equals(base64);

      // Verify both converted signatures
      expect(
          () => account.ed25519Key
              .verify(message: 'Test message', signature: fromBase64),
          returnsNormally);

      expect(
          () => account.ed25519Key
              .verify(message: 'Test message', signature: fromBytes),
          returnsNormally);
    });
  });
}
