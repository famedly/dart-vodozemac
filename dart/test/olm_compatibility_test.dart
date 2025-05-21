import 'dart:convert';
import 'dart:typed_data';

import 'package:olm/olm.dart' as olm;
import 'package:test/test.dart';

import 'package:vodozemac/vodozemac.dart' as vodozemac;

void main() {
  group('Compatibility', () {
    late olm.Account olmAccount;
    late vodozemac.Account vodozemacAccount;

    setUpAll(() async {
      await vodozemac.loadVodozemac(
        wasmPath:
            './pkg/', // this is relative to the output file (compiled to js in `web/`)
        libraryPath:
            '../rust/target/debug/', // this is relative to the whole dart project
      );
      await olm.init();

      olmAccount = olm.Account();
      olmAccount.create();
      final olmAccountPickle = olmAccount.pickle('key');

      vodozemacAccount = await vodozemac.Account.fromOlmPickleEncrypted(
        pickle: olmAccountPickle,
        pickleKey: Uint8List.fromList('key'.codeUnits),
      );
    });
    test('Export import identity keys', () async {
      final olmKeys = jsonDecode(olmAccount.identity_keys());
      final vodozemacKeys = {
        'curve25519': vodozemacAccount.curve25519Key().toBase64(),
        'ed25519': vodozemacAccount.ed25519Key().toBase64(),
      };
      expect(olmKeys, vodozemacKeys);
    });
    test('Export import Olm Session', () async {
      final other = olm.Account();
      other.create();
      other.generate_one_time_keys(1);
      final otk = jsonDecode(other.one_time_keys())['curve25519'].values.single;
      other.mark_keys_as_published();

      final olmSession = olm.Session();
      olmSession.create_outbound(
        olmAccount,
        jsonDecode(other.identity_keys())['ed25519'],
        otk,
      );

      final pickle = olmSession.pickle('key');

      final vodozemacSession = await vodozemac.Session.fromOlmPickleEncrypted(
        pickle: pickle,
        pickleKey: Uint8List.fromList('key'.codeUnits),
      );

      expect(olmSession.session_id(), vodozemacSession.sessionId());

      other.free();
      olmSession.free();
    });
    test('Export import Outbound Group Session', () async {
      final other = olm.Account();
      other.create();

      final olmSession = olm.OutboundGroupSession();
      olmSession.create();

      final pickle = olmSession.pickle('key');

      final vodozemacSession =
          await vodozemac.GroupSession.fromOlmPickleEncrypted(
        pickle: pickle,
        pickleKey: Uint8List.fromList('key'.codeUnits),
      );

      expect(olmSession.session_id(), vodozemacSession.sessionId());

      other.free();
      olmSession.free();
    });
    test('Export import Group Session', () async {
      final other = olm.Account();
      other.create();

      final olmSession = olm.OutboundGroupSession();
      final inboundOlmSession = olm.InboundGroupSession();
      olmSession.create();
      inboundOlmSession.create(olmSession.session_key());

      final pickle = olmSession.pickle('key');
      final inboundPickle = inboundOlmSession.pickle('key');

      final vodozemacSession =
          await vodozemac.GroupSession.fromOlmPickleEncrypted(
        pickle: pickle,
        pickleKey: Uint8List.fromList('key'.codeUnits),
      );

      final vodozemacInboundSession =
          await vodozemac.InboundGroupSession.fromOlmPickleEncrypted(
        pickle: inboundPickle,
        pickleKey: Uint8List.fromList('key'.codeUnits),
      );

      expect(olmSession.session_id(), vodozemacSession.sessionId());
      expect(
        inboundOlmSession.session_id(),
        vodozemacInboundSession.sessionId(),
      );

      other.free();
      olmSession.free();
    });

    tearDownAll(() {
      olmAccount.free();
    });
  });
}
