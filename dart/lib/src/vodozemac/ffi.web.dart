import 'generated/bridge_generated.web.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

VodozemacBindingsDartImpl initializeExternalLibrary(String root) =>
    VodozemacBindingsDartImpl.wasm(
      WasmModule.initialize(kind: Modules.noModules(root: root)),
    );

VodozemacBindingsDartImpl? api;
