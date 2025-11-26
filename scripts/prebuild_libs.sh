#!/usr/bin/env bash

dart ../flutter/cargokit/build_tool/bin/build_tool.dart precompile-binaries \
  --repository QuickBirdEng/dart-vodozemac \
  --manifest-dir ../rust \
  --target aarch64-apple-ios,aarch64-apple-ios-sim,x86_64-apple-ios \
  --target aarch64-linux-android,i686-linux-android,x86_64-linux-android,armv7-linux-androideabi \
  --android-sdk-location "$HOME/Library/Android/sdk" \
  --android-ndk-version "26.1.10909125" \
  --android-min-sdk-version 21 \
  --verbose