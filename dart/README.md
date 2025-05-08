# Generic Olm Bindings

## Features

Currently supported functionality:

- Olm Account creation, one time and fallback key creation, etc.
- Ed25519 and Curve25519 encryption and signing
- Olm encryption and decryption
- Megolm encryption and decryption
- Export to the vodozemac pickle format (encrypted)
- Import from the vodozemac pickle format and the libolm pickle format

Unfinished:

- SAS Api
- libolm pickle export
- libolm backend

## Getting started

You need to build vodozemac first, either the wasm or the native library.

## Usage

You can find some basic examples in the examples folder and more extensive tests in the tests directory. But the gist of
it is this:

```dart
// load the library, possibly provide the path to the wasm or native library
loadVodozemac();

// Create an olm account. Alternatively import it.
final account = await Account.create();

// create some one time keys up to a library specific maximum.
print(account.maxNumberOfOneTimeKeys());
await account.generateFallbackKey();
await account.generateOneTimeKeys(20);


// You can sign messages and keys.
String message = "Some str";
final signature = await account.sign(message);
print("Signed '$message', signature '${signature.toBase64()}");

// And verify the signature
try {
  await account.ed25519Key().verify(message: message, signature: signature);
  print("Signature verified");
} catch (e) {
  print("Signature not verified");
}


// You can also create group sessions
final session = await GroupSession.create();
final inbound = session.toInbound();

// and encrypt with them
final encrypted = await session.encrypt('This is a test');
print("Encrypted: $encrypted");
print("Index: ${session.messageIndex()}");

// Or decrypt
final decrypted = await inbound.decrypt(encrypted);
print("Decrypted: $decrypted");

// Olm session usage not pictured.
```

## Additional information

Currently you have the choice of the generic interface or the vodozemac interface. In the future a libolm interface
might be added to ease migration.

You can run the tests using `dart test`, but you might need to adapt the library path.
 -> You can run `cargo build` in `../rust` directory to get the `.dylib` file to load

You can also run the tests for web using `dart run flutter_rust_bridge:serve --crate ../rust --run-tests -d example/run_tests_web.dart --root .`
