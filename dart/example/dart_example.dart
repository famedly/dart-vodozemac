import 'package:vodozemac_bindings_dart/vodozemac_bindings_dart.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert' show utf8;

void main() async {
  final dylib = DynamicLibrary.open(
      '../rust/target/debug/libvodozemac_bindings_dart.dylib');
  final api = VodozemacBindingsDartImpl(dylib);
  final account = await VodozemacAccount.newVodozemacAccount(bridge: api);
  print(await account.maxNumberOfOneTimeKeys());
  await account.generateFallbackKey();
  await account.generateOneTimeKeys(count: 20);

  final curvelen = (await (await account.fallbackKey()).first.key.toBase64()).length;
  print("curvelen $curvelen");

  print(await (await account.ed25519Key()).toBase64());

  String message = "Some str";
  final signature = await account.sign(message: message);
  print("Signed '$message', signature '${await signature.toBase64()}");

  try {
    await (await account.ed25519Key()).verify(
        message: message,
        signature: signature);
    print("Signature verified");
  } catch (e) {
    print("Signature not verified");
  }

  try {
    await (await account.ed25519Key()).verify(
        message: "abc", signature: signature);
    print("2nd Signature verified");
  } catch (e) {
    print("2nd Signature not verified, $e");
  }


  try {
	  final session = await VodozemacGroupSession.newVodozemacGroupSession(bridge: api, config: await VodozemacMegolmSessionConfig.version2(bridge: api));
	  final inbound = await session.toInbound();

	  final encrypted = await session.encrypt(plaintext: 'This is a test');
	  print("Encrypted: $encrypted");
	  print("Index: ${await session.messageIndex()}");

	  final decrypted = await inbound.decrypt(encrypted: encrypted);
	  print("Decrypted: $decrypted");

	  try {
	  final inbound2 = await session.toInbound();
	  final decrypted2 = await inbound2.decrypt(encrypted: encrypted);
	  print("Decryption succeeded, when it should not!");
	  } catch(e) {
		  print("Decryption failed successfully after exporting the inbound session later");
	  }
  } catch (e) {
    print("Encryption test failed, $e");
  }
  
}
