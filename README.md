# Dart Vodozemac bindings

This library provides bindings to Olm and Megolm libraries from Dart. Currently only vodozemac is implemented as a
backend. Both web and native are supported. You need to provide the path to the built rust library yourself.

### Installation

Add vodozemac to your project:

```sh
flutter pub add vodozemac
```

Now you need to compile and add the shared library. You can use the install script for this. This requires `git` and `cargo` to be available in your PATH. [Install Rust](https://www.rust-lang.org/tools/install).

```sh
dart run vodozemac:install
```

This will try to compile and install them for all platforms which are enabled in your Flutter project. This might fail as not all platforms can be installed from any OS. To only install the desired platforms, you can specify them as parameters:

```sh
dart run vodozemac:install android ios macos linux web
```

For iOS and macOS you also have to add the library to Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode (or `macos/Runner.xcworkspace`).
2. In the project navigator, right-click the Runner group and choose "Add Files to 'Runner'...".
3. Select libyour_library.a (located in `ios/Runner/`).

To build for iOS simulators (not possible together with platform `ios`):

```sh
dart run vodozemac:install iosSimulators
```

> Windows is not supported yet.

It is recommended to add the built files to `.gitignore`. Please make sure to rebuild this command every time you update the package.

#### Install on Windows

For Windows you need to compile it by hand and add the dll file to the release build directory `build/windows/x64/runner/Release/`.

```sh
git clone https://github.com/famedly/dart-vodozemac.git
cd dart-vodozemac/rust
rustup target add x86_64-pc-windows-gnu
cargo build --release --target x86_64-pc-windows-gnu
```

This will result in a dll file at: `target/x86_64-pc-windows-gnu/release/`

### Contribution guide

1. Make necessary changes in `rust/src/bindings.rs`
2. Then run `flutter_rust_bridge_codegen generate` to generate the rust bindings
3. Now use those code generated in `dart/lib/generated/` to write/modify documented wrapper code in `dart/lib/api.dart`
4. Then, cd into `dart` directory and run `dart run import_sorter:main` to sort imports
5. Run tests locally and then open a PR

### Running tests
```
# To test it locally for your platform (MacOS/Linux/Windows)
./scripts/run_io_tests.sh

# To test it for dart web
./scripts/run_web_tests.sh
```