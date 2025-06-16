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

Vodozemac needs Rust to be installed locally. [Install Rust](https://www.rust-lang.org/tools/install)

Add the package to your Dart/Flutter project:

```sh
flutter pub add vodozemac
```

You need to build vodozemac first, either the wasm or the native library. For flutter you can use the `flutter_vodozemac` package:

```sh
flutter pub add flutter_vodozemac
```

Then you can initialize vodozemac for native platforms like this:

```dart
import 'package:flutter_vodozemac/flutter_vodozemac.cart' as vod;

await vod.init();
```

### Build for web

For web you need to build the package by yourself. You can use the script below to do so:

```sh
git clone https://github.com/famedly/dart-vodozemac.git .vodozemac
cd .vodozemac
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(readlink -f rust) --release
cd ..
mv .vodozemac/dart/web/pkg ./web/
rm -rf .vodozemac
```

## Usage

You can find some basic examples in the examples folder and more extensive tests in the tests directory. But the gist of
it is this:

```dart
// load the library, possibly provide the path to the wasm or native library
init();

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

You can run the tests using `dart test`, but you might need to adapt the library path.
 -> You can run `cargo build` in `../rust` directory to get the `.dylib` file to load
