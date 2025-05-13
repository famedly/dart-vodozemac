#!/usr/bin/env bash

# ----------- CONFIGURATION -----------
RUST_DIR="rust"
DART_DIR="dart"
PORT=8080

# ----------- UTILITIES -----------
echo_info() {
  echo -e "\033[1;32m[INFO]\033[0m $1"
}

echo_error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# ----------- COMPILE RUST TO WASM -----------
echo_info "Building rust crate to WASM..."
flutter_rust_bridge_codegen build-web --dart-root $DART_DIR --rust-root $(readlink -f $RUST_DIR) --release

# ----------- COMPILE DART TO JS -----------
echo_info "Compiling Dart entrypoint to JavaScript..."
cd "$DART_DIR" # we do this because dart compile fails with a relative path for some reason
dart pub get

DART_INPUT="test/vodozemac_test_web.dart"
JS_OUTPUT="web"
mkdir -p "$JS_OUTPUT"
dart compile js "$DART_INPUT" \
  -o "$JS_OUTPUT/$(basename $DART_INPUT).js" \
  -O2 \
  --enable-diagnostic-colors

# ----------- RUN TESTS -----------
echo_info "Running web tests..."

cleanup() {
  rm -rf "$JS_OUTPUT/pkg"
  rm "$JS_OUTPUT/$(basename $DART_INPUT)"*
}
trap cleanup EXIT

export PORT=$PORT
DART_TEST_HELPER="./test/web_test_helper/main.dart"
if ! dart run "$DART_TEST_HELPER" "$(readlink -f $JS_OUTPUT)"; then
  echo_error "Tests failed"
  exit 1
fi

echo_info "Tests completed successfully" 