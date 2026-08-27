## 0.8.0
- build: update flutter_rust_bridge to 2.13.0 (includes web worker WASM initialization fix)
- build: require Dart 3.10+ (in preparation for the native assets integration backend)

## 0.7.0
- chore: version bump to get back on sync with flutter_vodozemac

## 0.6.0
- build: update FRB to 2.12.0
- build: update vodozemac to 0.10.0 and remove default version workaround
- chore: session config is now configurable for inbound group session as well

## 0.5.0
- fix: Use the specced olm session config v1 by default (Christian Kußowski)

## 0.4.0

- feat: add ios ffi bindings for decryption in notification extension

## 0.3.0

- feat: Add CryptoUtils to forward algorithms for SSSS and file encryption
- build: Update flutter_rust_bridge to 2.11.1

## 0.2.0

- feat: write bindings for remove_one_time_key in Account
- feat: add disposed getter for Sas

## 0.1.0

- Initial version.
