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
so your app uses a **prebuilt** `flutter_vodozemac.xcframework`. Our release
workflow builds it on a GitHub macOS runner and attaches it to the
[GitHub release](https://github.com/famedly/dart-vodozemac/releases) of that
version; the `Package.swift` files under `ios/flutter_vodozemac/` and
`macos/flutter_vodozemac/` in the published package point at that asset by URL
and checksum, and Xcode downloads it when it resolves packages. iOS ships it as
a framework; macOS ships a plain `libflutter_vodozemac.dylib`.

- No Rust toolchain needed on your machine; nothing is compiled during your
  build, which makes clean/CI builds noticeably faster.
- You are running a binary built by our CI from the tagged source
  (`.github/workflows/build_assets.yml`), so it can be audited or reproduced.
  If you prefer to compile from source, use CocoaPods.
- Not using the pub.dev release? The `Package.swift` files in git point at a
  local, gitignored XCFramework instead. For a git dependency, use CocoaPods.
  For a path dependency on a local checkout, run
  `./scripts/build_xcframework.sh` there (needs macOS, Xcode and Rust), and
  again after every change under `rust/`, or use CocoaPods.

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
(the pod and the SPM binary target both embed the framework).

#### Migration guide

If your extension predates this plugin's SPM support, you have three things to
remove and one to add.

**1. Podfile** — drop the pod line from the extension target, then run
`pod install`:

```diff
   target 'YourExtensionTarget' do
     inherit! :search_paths
-    pod 'flutter_vodozemac', :path => '.symlinks/plugins/flutter_vodozemac/ios'
   end
```

**2. Bridging header** — remove the vodozemac import. If that was the only
line, delete the header file entirely:

```diff
-// Import the vodozemac C header
-#import "vodozemac_ios_ffi_bindings.h"
```

**3. Xcode build settings** — for the extension target, clear
_Build Settings → Swift Compiler - General → Objective-C Bridging Header_
(a path pointing at a deleted file fails the build).

**4. Swift code** — the bridging header's symbols are now provided by a normal
import instead:

```diff
+import flutter_vodozemac
```

`ios_decrypt_event` & co. are directly callable after that — the framework
ships `vodozemac_ios_ffi_bindings.h` and a module map, so no other code
changes are needed.

If you'd rather not migrate the extension yet, opt the whole app out of SPM in
its `pubspec.yaml` and everything keeps working exactly as before:

```yaml
flutter:
  disable-swift-package-manager: true
```

### Releasing the prebuilt XCFramework (maintainers)

Nothing to do by hand. Pushing a `v*` tag runs `.github/workflows/publish.yml`,
which builds the XCFrameworks (and the other native and web assets), attaches
them to the GitHub release, rewrites both `Package.swift` files to the release
asset's URL and checksum and then publishes to pub.dev. Pull requests that
touch `rust/` build them too, including an example app with SwiftPM.

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
`--no-enable-swift-package-manager` between runs: SwiftPM uses the
XCFramework that `./scripts/build_xcframework.sh` builds into `ios/` and
`macos/` (run it first), CocoaPods compiles the Rust crate from source via
cargokit.

## Cargokit patch:

Removed the `compileSdkVersion` variable and all occurences in `dart-vodozemac/flutter/cargokit/gradle/plugin.gradle` as it's unneeded. The old way was breaking as `Android 37` is now called `Android 37.0` in the SDK.
