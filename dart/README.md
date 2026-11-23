# Generic Olm Bindings

## Features

Currently supported functionality:

- Olm Account creation, one time and fallback key creation, etc.
- Ed25519 and Curve25519 encryption and signing
- Olm encryption and decryption
- Megolm encryption and decryption
- Export to the vodozemac pickle format (encrypted)
- Import from the vodozemac pickle format and the libolm pickle format
- SAS verification
- Public key cryptography (Pk algorithms)

## Getting started

Vodozemac needs Rust to be installed locally, unless you use the prebuilt libraries below. [Install Rust](https://www.rust-lang.org/tools/install)

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
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;

await vod.init();
```

### Prebuilt libraries

[Releases](https://github.com/famedly/dart-vodozemac/releases) ship prebuilt
libraries, so you don't need Rust to use them:

| Asset | For |
|---|---|
| `vodozemac-web.zip` | Web: unzip into `web/pkg/` |
| `libvodozemac_bindings_dart-linux-x64.so`, `-linux-arm64.so` | Dart on Linux (glibc 2.35+), e.g. servers and tests |
| `libvodozemac_bindings_dart-macos.dylib` | Dart on macOS (arm64 and x86_64) |
| `flutter_vodozemac-{ios,macos}.xcframework.zip` | Used by `flutter_vodozemac` with Swift Package Manager |

`SHA256SUMS` lists their checksums. Use the release whose tag matches your
`vodozemac` version, since the Dart bindings and the library must match:

```sh
version=$(yq ".packages.vodozemac.version" < pubspec.lock)
curl -fsSLO "https://github.com/famedly/dart-vodozemac/releases/download/v${version}/vodozemac-web.zip"
rm -rf web/pkg && unzip -q vodozemac-web.zip -d web/pkg && rm vodozemac-web.zip
```

Rename a native library to `libvodozemac_bindings_dart.so` (or `.dylib`) and
pass its directory, with a trailing `/` (e.g. `libs/`), as `libraryPath` to
`init`. To build them yourself instead,
see `.github/workflows/build_assets.yml`.

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

The olm compatibility tests additionally need libolm. On Linux install
`libolm3`; on macOS install it with `brew install libolm` and place a
(gitignored) symlink where `dlopen` can find it:

```sh
ln -s /opt/homebrew/lib/libolm.3.dylib dart/libolm.3.dylib   # from the repo root
```
