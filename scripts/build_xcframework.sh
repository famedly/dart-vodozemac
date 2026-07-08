#!/usr/bin/env bash
# Builds flutter_vodozemac.xcframework from the Rust crate in flutter/rust and
# writes it directly into flutter/ios/flutter_vodozemac and
# flutter/macos/flutter_vodozemac, where it is committed to the repo and
# referenced by a local-path SwiftPM binaryTarget (see the Package.swift files
# there). CocoaPods consumers are unaffected: they still build from source via
# cargokit.
#
# The framework/binary is named flutter_vodozemac because flutter_rust_bridge's
# darwin loader opens "flutter_vodozemac.framework/flutter_vodozemac" (see
# flutter/lib/flutter_vodozemac.dart).
#
# Run this after any change to flutter/rust and commit the result alongside
# the change.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE_DIR="$REPO_ROOT/flutter/rust"
OUT_DIR="$REPO_ROOT/build/xcframework"
DEST_IOS="$REPO_ROOT/flutter/ios/flutter_vodozemac/flutter_vodozemac.xcframework"
DEST_MACOS="$REPO_ROOT/flutter/macos/flutter_vodozemac/flutter_vodozemac.xcframework"
LIB_NAME="libvodozemac_bindings_dart.dylib"
FRAMEWORK_NAME="flutter_vodozemac"
# Shipped inside the frameworks (Headers/ + module map) so app extensions can
# `import flutter_vodozemac` and call the notification-decrypt C FFI without a
# bridging header; see flutter/README.md.
FFI_HEADER="$REPO_ROOT/flutter/ios/Classes/vodozemac_ios_ffi_bindings.h"
# Keep in sync with the platforms in the Package.swift manifests.
IOS_MIN_VERSION="13.0"
MACOS_MIN_VERSION="10.15"

IOS_TARGETS=(aarch64-apple-ios)
IOS_SIM_TARGETS=(aarch64-apple-ios-sim x86_64-apple-ios)
MACOS_TARGETS=(aarch64-apple-darwin x86_64-apple-darwin)
ALL_TARGETS=("${IOS_TARGETS[@]}" "${IOS_SIM_TARGETS[@]}" "${MACOS_TARGETS[@]}")

echo "==> Installing Rust targets"
rustup target add "${ALL_TARGETS[@]}"

echo "==> Building crate for ${ALL_TARGETS[*]}"
for target in "${ALL_TARGETS[@]}"; do
  # IPHONEOS_DEPLOYMENT_TARGET/MACOSX_DEPLOYMENT_TARGET pin the dylib's
  # minimum OS so it matches the framework Info.plist.
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN_VERSION" \
  MACOSX_DEPLOYMENT_TARGET="$MACOS_MIN_VERSION" \
    cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target "$target"
done

TARGET_OUT="$(cargo metadata --manifest-path "$CRATE_DIR/Cargo.toml" --format-version 1 --no-deps \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])')"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/lipo"

lipo_or_copy() { # <output> <input...>
  local output="$1"; shift
  if [ "$#" -eq 1 ]; then
    cp "$1" "$output"
  else
    lipo -create "$@" -output "$output"
  fi
}

dylibs_for() { # <target...>
  for t in "$@"; do echo "$TARGET_OUT/$t/release/$LIB_NAME"; done
}

ios_plist() { # <path>
  cat >"$1" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$FRAMEWORK_NAME</string>
  <key>CFBundleIdentifier</key><string>com.famedly.flutter-vodozemac</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$FRAMEWORK_NAME</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>$IOS_MIN_VERSION</string>
</dict>
</plist>
EOF
}

write_module_files() { # <dir that will contain Headers/ and Modules/>
  mkdir -p "$1/Headers" "$1/Modules"
  cp "$FFI_HEADER" "$1/Headers/"
  cat >"$1/Modules/module.modulemap" <<EOF
framework module $FRAMEWORK_NAME {
    header "$(basename "$FFI_HEADER")"
    export *
}
EOF
}

make_ios_framework() { # <slice-dir> <fat-binary>
  local fw="$1/$FRAMEWORK_NAME.framework"
  mkdir -p "$fw"
  cp "$2" "$fw/$FRAMEWORK_NAME"
  install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$fw/$FRAMEWORK_NAME"
  ios_plist "$fw/Info.plist"
  write_module_files "$fw"
}

make_macos_framework() { # <slice-dir> <fat-binary>
  local fw="$1/$FRAMEWORK_NAME.framework"
  mkdir -p "$fw/Versions/A/Resources"
  cp "$2" "$fw/Versions/A/$FRAMEWORK_NAME"
  install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/Versions/A/$FRAMEWORK_NAME" "$fw/Versions/A/$FRAMEWORK_NAME"
  cat >"$fw/Versions/A/Resources/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$FRAMEWORK_NAME</string>
  <key>CFBundleIdentifier</key><string>com.famedly.flutter-vodozemac</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$FRAMEWORK_NAME</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>$MACOS_MIN_VERSION</string>
</dict>
</plist>
EOF
  write_module_files "$fw/Versions/A"
  ln -s A "$fw/Versions/Current"
  ln -s "Versions/Current/$FRAMEWORK_NAME" "$fw/$FRAMEWORK_NAME"
  ln -s Versions/Current/Resources "$fw/Resources"
  ln -s Versions/Current/Headers "$fw/Headers"
  ln -s Versions/Current/Modules "$fw/Modules"
}

echo "==> Creating fat binaries"
lipo_or_copy "$OUT_DIR/lipo/ios-device" $(dylibs_for "${IOS_TARGETS[@]}")
lipo_or_copy "$OUT_DIR/lipo/ios-simulator" $(dylibs_for "${IOS_SIM_TARGETS[@]}")
lipo_or_copy "$OUT_DIR/lipo/macos" $(dylibs_for "${MACOS_TARGETS[@]}")

echo "==> Assembling frameworks"
mkdir -p "$OUT_DIR/slices/ios-device" "$OUT_DIR/slices/ios-simulator" "$OUT_DIR/slices/macos"
make_ios_framework "$OUT_DIR/slices/ios-device" "$OUT_DIR/lipo/ios-device"
make_ios_framework "$OUT_DIR/slices/ios-simulator" "$OUT_DIR/lipo/ios-simulator"
make_macos_framework "$OUT_DIR/slices/macos" "$OUT_DIR/lipo/macos"

echo "==> Creating XCFrameworks"
# Two separate XCFrameworks, each with only the slices its platform needs,
# rather than one fat one duplicated into both plugin folders.
rm -rf "$OUT_DIR/ios.xcframework" "$OUT_DIR/macos.xcframework"
xcodebuild -create-xcframework \
  -framework "$OUT_DIR/slices/ios-device/$FRAMEWORK_NAME.framework" \
  -framework "$OUT_DIR/slices/ios-simulator/$FRAMEWORK_NAME.framework" \
  -output "$OUT_DIR/ios.xcframework"
xcodebuild -create-xcframework \
  -framework "$OUT_DIR/slices/macos/$FRAMEWORK_NAME.framework" \
  -output "$OUT_DIR/macos.xcframework"

echo "==> Installing into flutter/ios and flutter/macos"
rm -rf "$DEST_IOS" "$DEST_MACOS"
ditto "$OUT_DIR/ios.xcframework" "$DEST_IOS"
ditto "$OUT_DIR/macos.xcframework" "$DEST_MACOS"

echo
echo "Updated:"
echo "  $DEST_IOS"
echo "  $DEST_MACOS"
echo "Commit these together with your flutter/rust change."
