# Flutter Vodozemac

This package contains bindings to build Vodozemac in Flutter applications. Please refer to [vodozemac](https://pub.dev/packages/vodozemac) for documentation.

Read this guide on [decrypting ciphertext in iOS directly with C-compatible ffi bindings, for displaying encrypted messages in push notifications](./ios/README_NOTIFICATION_DECRYPT.md).

## iOS/macOS setup: Swift Package Manager or CocoaPods

This plugin supports both. No plugin-specific setup is needed for either —
Flutter picks the integration per app based on
`flutter config --enable-swift-package-manager` (SPM is the default on recent
Flutter versions). The difference is **where the Rust library gets built**:

### Swift Package Manager (prebuilt binary)

SwiftPM cannot run cargo during the build (build tool plugins are sandboxed),
so your app uses a **prebuilt** `flutter_vodozemac.xcframework` that we build
and commit to this repo (under `ios/flutter_vodozemac/` and
`macos/flutter_vodozemac/`, referenced as a local-path `binaryTarget` in the
`Package.swift` there).

- No Rust toolchain needed on your machine; nothing is compiled during your
  build, which makes clean/CI builds noticeably faster.
- You are running a binary built by the maintainers. It is always committed
  in the same change as the Rust source it was built from
  (`scripts/build_xcframework.sh`), so it can be audited or reproduced. If
  you prefer to compile from source, use CocoaPods.

### CocoaPods (built from source)

The Rust library is compiled from source **during your app's build** via a
[cargokit](./cargokit) script phase (see the podspecs in `ios/` and `macos/`).

- Requires a Rust toolchain (cargokit bootstraps rustup and the needed
  targets automatically on first build).
- First/clean builds take longer since cargo compiles the crate and its
  dependencies; incremental builds are fast once cargo has cached.

Either way the resulting app contains the same library; unused architectures
are stripped by Xcode when embedding.

### Using the FFI from an app extension (notification decrypt) with SPM

If your app follows the
[notification decryption guide](./ios/README_NOTIFICATION_DECRYPT.md), the
CocoaPods setup declares `pod 'flutter_vodozemac'` for the extension target.
Keeping that pod line while building with SPM makes the build fail with
`Multiple commands produce .../Runner.app/Frameworks/flutter_vodozemac.framework`
(the pod and the SPM binary target both embed the framework). To migrate the
extension to SPM:

1. Remove the `pod 'flutter_vodozemac', :path => ...` line from the extension
   target in your Podfile (then `pod install`).
2. In Xcode, add the `flutter-vodozemac` package product to the extension
   target under *General → Frameworks and Libraries*. The plugin's package is
   already in the workspace via `FlutterGeneratedPluginSwiftPackage`.
3. Replace the bridging-header import with `import flutter_vodozemac` in
   Swift. The framework ships `vodozemac_ios_ffi_bindings.h` and a module map,
   so `ios_decrypt_event` & co. are directly callable — a bridging header (and
   the pod's header search paths) are no longer needed.

If you'd rather not migrate the extension yet, opt the whole app out of SPM in
its `pubspec.yaml` and everything keeps working exactly as before:

```yaml
flutter:
  disable-swift-package-manager: true
```

### Updating the prebuilt XCFramework (maintainers)

Whenever `flutter/rust` changes, rebuild it and commit the result together
with that change:

```sh
./scripts/build_xcframework.sh   # from the repo root
```

This overwrites `flutter_vodozemac.xcframework` in both `ios/flutter_vodozemac/`
and `macos/flutter_vodozemac/`. No separate release step is needed — publishing
the flutter package to pub.dev ships whatever XCFramework is committed at that
point.

## Testing the plugin locally

```sh
cd flutter
flutter create example
cd example
flutter pub add flutter_vodozemac --path ..
flutter run
```

To try both iOS/macOS integration paths, toggle
`flutter config --enable-swift-package-manager` /
`--no-enable-swift-package-manager` between runs: SwiftPM uses the committed
XCFramework, CocoaPods compiles the Rust crate from source via cargokit.
