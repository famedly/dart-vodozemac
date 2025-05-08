# Dart Vodozemac bindings

This library provides bindings to Olm and Megolm libraries from Dart. Currently only vodozemac is implemented as a
backend. Both web and native are supported. You need to provide the path to the built rust library yourself.

### Contribution guide

1. Make necessary changes in `rust/src/bindings.rs`
2. Then `cd` into `dart/` directory and run `flutter_rust_bridge_codegen generate` to generate the rust bindings
3. Now use those code generated in `dart/lib/generated/` to write/modify documented wrapper code in `dart/lib/api.dart`