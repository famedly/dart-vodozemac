import 'bridge_generated.web.dart';
export 'bridge_generated.web.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

const root = 'pkg/vodozemac-bindings-dart';

VodozemacBindingsDartImpl initializeExternalLibrary(void _) =>
    VodozemacBindingsDartImpl.wasm(
      WasmModule.initialize(kind: const Modules.noModules(root: root)),
    );
