import 'package:vodozemac/vodozemac.dart';

void main() async {
  await loadVodozemac(
      wasmPath: '../web/pkg/', libraryPath: '../../../rust/target/debug/');

  final account = await Account.create();
  print(account.maxNumberOfOneTimeKeys());
  await account.generateFallbackKey();
  await account.generateOneTimeKeys(20);

  final curvelen = account.fallbackKey().entries.first.value.toBase64().length;
  print("curvelen $curvelen");

  print(account.ed25519Key().toBase64());

  String message = "Some str";
  final signature = await account.sign(message);
  print("Signed '$message', signature '${signature.toBase64()}");

  try {
    await account.ed25519Key().verify(message: message, signature: signature);
    print("Signature verified");
  } catch (e) {
    print("Signature not verified");
  }

  try {
    await account.ed25519Key().verify(message: "abc", signature: signature);
    print("2nd Signature verified");
  } catch (e) {
    print("2nd Signature not verified, $e");
  }

  try {
    final session = await GroupSession.create();
    final inbound = session.toInbound();

    final encrypted = await session.encrypt('This is a test');
    print("Encrypted: $encrypted");
    print("Index: ${session.messageIndex()}");

    final decrypted = await inbound.decrypt(encrypted);
    print("Decrypted: $decrypted");

    try {
      final inbound2 = session.toInbound();
      await inbound2.decrypt(encrypted);
      print("Decryption succeeded, when it should not!");
    } catch (e) {
      print(
          "Decryption failed successfully after exporting the inbound session later");
    }
  } catch (e) {
    print("Encryption test failed, $e");
  }
}
