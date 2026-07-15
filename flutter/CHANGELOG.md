## 0.6.0
- feat: Support Swift Package Manager on iOS and macOS via a prebuilt
  XCFramework binary target. CocoaPods keeps building the Rust library from
  source via cargokit and is unaffected. (Emre Yurtseven)
- fix: Android builds with Gradle 9, which removed the Project.exec API the
  vendored cargokit relied on. (Emre Yurtseven)
- fix: Compile the Android plugin against SDK 36; the AndroidX libraries
  pulled in by current Flutter embeddings require 34 or later. (Emre Yurtseven)

## 0.5.0
- fix: Use the specced olm session config v1 by default (Christian Kußowski)

## 0.4.1

Fix broken release of 0.4.1 which doesn't actually include the changes of 0.4.0.

## 0.4.0

Update to Vodozemac 0.4.0 with:
- feat: add ios ffi bindings for decryption in notification extension

## 0.3.0

Update to Vodozemac 0.3.0 with:
- feat: Add CryptoUtils to forward algorithms for SSSS and file encryption
- build: Update flutter_rust_bridge to 2.11.1

## 0.2.2

- fix: Pass thorugh wasmPath for init()

## 0.2.1

- fix: Wrong plugin name in cmakeslists for Linux and Windows

## 0.2.0

- Update to Vodozemac 0.2.0

## 0.1.0

- Initial release.
