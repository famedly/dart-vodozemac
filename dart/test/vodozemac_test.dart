import 'dart:io';

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

void main() {
  loadVodozemac(
      libraryPath: Platform.environment['librarypath'] ??
          '../rust/target/debug/libvodozemac_bindings_dart.dylib');

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
}
