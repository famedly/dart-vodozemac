import 'package:vodozemac_bindings_dart/vodozemac_bindings_dart.dart';
import 'package:test/test.dart';
import 'package:checks/checks.dart';
import 'package:checks/context.dart';

extension PublicCurveChecks on Subject<VodozemacCurve25519PublicKey> {
  Future<void> isValid() async {
    await context.expectAsync(() => ['meets this expectation'], (actual) async {
      if ((await actual.toBase64()).length == 43) return null;
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
  final api = initializeExternalLibrary(
      '../rust/target/debug/libvodozemac_bindings_dart.dylib');

  group('Account', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('can be created', () async {
      await check(VodozemacAccount.newVodozemacAccount(bridge: api))
          .completes();
    });

    test('has sane max OTKs', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);

      await check(account.maxNumberOfOneTimeKeys())
          .completes(it()..isGreaterOrEqual(50));
    });

    test('can generate OTKs', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);

      await check(account.generateOneTimeKeys(count: 20)).completes();

      await check(account.oneTimeKeys()).completes(it()
        ..length.equals(20)
        ..everyAsync(it()
          ..has((val) => val.keyid, 'keyid').length.equals(11)
          ..has((val) => val.key, 'key').isValid()));
    });

    test('can generate fallback key', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);

      await check(account.generateFallbackKey()).completes();

      await check(account.fallbackKey()).completes(it()
        ..length.equals(1)
        ..everyAsync(it()
          ..has((val) => val.keyid, 'keyid').length.equals(11)
          ..has((val) => val.key, 'key').isValid()));
    });

    test('can publish fallback key', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);

      await check(account.generateFallbackKey()).completes();

      await check(account.fallbackKey()).completes(it()..length.equals(1));

      await check(account.markKeysAsPublished()).completes();

      // forgetting returns false, because it was unused.
      await check(account.forgetFallbackKey()).completes(it()..isFalse());

      await check(account.fallbackKey()).completes(it()..length.equals(0));

      await check(account.generateFallbackKey()).completes();
      await check(account.forgetFallbackKey()).completes(it()..isTrue());
    });

    test('sending olm messages works properly', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);
      final account2 = await VodozemacAccount.newVodozemacAccount(bridge: api);

      await check(account.generateOneTimeKeys(count: 1)).completes();

      final onetimeKey = (await account.oneTimeKeys()).first;

      await check(account.markKeysAsPublished()).completes();

      final outboundSession = await account2.createOutboundSession(
          config: await VodozemacOlmSessionConfig.def(bridge: api),
          identityKey: await account.curve25519Key(),
          oneTimeKey: onetimeKey.key);
      check(outboundSession.hasReceivedMessage()).completes(it()..isFalse());

      final encrypted = await outboundSession.encrypt(plaintext: 'Test');
      final inbound = await account.createInboundSession(
          theirIdentityKey: await account2.curve25519Key(),
          preKeyMessageBase64: await encrypted.message());

      check(inbound.plaintext).equals('Test');
      await check(inbound.session.hasReceivedMessage())
          .completes(it()..isTrue());

      final encrypted2 = await inbound.session.encrypt(plaintext: 'Test2');

      await check(outboundSession.hasReceivedMessage())
          .completes(it()..isFalse());
      await check(outboundSession.decrypt(message: encrypted2))
          .completes(it()..equals('Test2'));
      await check(outboundSession.hasReceivedMessage())
          .completes(it()..isTrue());
    });

    test('sending olm messages works properly with fallback key', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);
      final account2 = await VodozemacAccount.newVodozemacAccount(bridge: api);

      await check(account.generateFallbackKey()).completes();

      final onetimeKey = (await account.fallbackKey()).first;

      await check(account.markKeysAsPublished()).completes();

      final outboundSession = await account2.createOutboundSession(
          config: await VodozemacOlmSessionConfig.def(bridge: api),
          identityKey: await account.curve25519Key(),
          oneTimeKey: onetimeKey.key);
      check(outboundSession.hasReceivedMessage()).completes(it()..isFalse());

      final encrypted = await outboundSession.encrypt(plaintext: 'Test');
      final inbound = await account.createInboundSession(
          theirIdentityKey: await account2.curve25519Key(),
          preKeyMessageBase64: await encrypted.message());

      check(inbound.plaintext).equals('Test');
      await check(inbound.session.hasReceivedMessage())
          .completes(it()..isTrue());

      final encrypted2 = await inbound.session.encrypt(plaintext: 'Test2');

      await check(outboundSession.hasReceivedMessage())
          .completes(it()..isFalse());
      await check(outboundSession.decrypt(message: encrypted2))
          .completes(it()..equals('Test2'));
      await check(outboundSession.hasReceivedMessage())
          .completes(it()..isTrue());
    });

    test('can sign messages', () async {
      final account = await VodozemacAccount.newVodozemacAccount(bridge: api);

      final signature = await account.sign(message: 'Abc');

      final signKey = await account.ed25519Key();
      await check(signKey.verify(message: 'Abc', signature: signature))
          .completes();
      await check(signKey.verify(message: 'Abcd', signature: signature))
          .throws();
    });
  });

  group('Megolm session can', () {
    test('be created', () async {
      await check(VodozemacGroupSession.newVodozemacGroupSession(
        bridge: api,
        config: await VodozemacMegolmSessionConfig.def(bridge: api),
      )).completes();
    });

    test('encrypt and decrypt', () async {
      final groupSession = await VodozemacGroupSession.newVodozemacGroupSession(
        bridge: api,
        config: await VodozemacMegolmSessionConfig.def(bridge: api),
      );
      final inbound = await groupSession.toInbound();

      final encrypted = await groupSession.encrypt(plaintext: 'Test');

      check(encrypted).not(it()..contains('Test'));
      await check(inbound.decrypt(encrypted: encrypted))
          .completes(it()..equals('Test'));

      // ensure that a later exported session does not decrypt the message
      final inboundAfter = await groupSession.toInbound();
      await check(inboundAfter.decrypt(encrypted: encrypted)).throws();
    });

    test('be imported and exported', () async {
      final groupSession = await VodozemacGroupSession.newVodozemacGroupSession(
        bridge: api,
        config: await VodozemacMegolmSessionConfig.def(bridge: api),
      );
      final inbound = await groupSession.toInbound();
      final reimportedInbound = await inbound.exportAtFirstKnownIndex().then(
          (exported) async => VodozemacInboundGroupSession.import(
              bridge: api,
              sessionKey: exported,
              config: await VodozemacMegolmSessionConfig.def(bridge: api)));
      final laterInbound = await inbound.exportAt(index: 1).then(
          (exported) async => VodozemacInboundGroupSession.import(
              bridge: api,
              sessionKey: exported!,
              config: await VodozemacMegolmSessionConfig.def(bridge: api)));

      final encrypted = await groupSession.encrypt(plaintext: 'Test');
      final encrypted2 = await groupSession.encrypt(plaintext: 'Test');

      check(encrypted).not(it()..equals(encrypted2));

      check(encrypted).not(it()..contains('Test'));
      await check(reimportedInbound.decrypt(encrypted: encrypted))
          .completes(it()..equals('Test'));

      // ensure that a later exported session does not decrypt the message
      await check(laterInbound.decrypt(encrypted: encrypted)).throws();

      // check if second index decryptes
      await check(reimportedInbound.decrypt(encrypted: encrypted2))
          .completes(it()..equals('Test'));
      await check(laterInbound.decrypt(encrypted: encrypted2))
          .completes(it()..equals('Test'));
    });
  });
}
