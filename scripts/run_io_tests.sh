#!/bin/bash

# build the rust crate
RUST_DIR="rust"
cd "$RUST_DIR"
cargo fetch
cargo build
cd ../

# Run the Vodozemac test suite
DART_DIR="dart"
cd "$DART_DIR"
dart pub get
dart test .