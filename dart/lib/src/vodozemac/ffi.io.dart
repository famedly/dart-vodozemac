import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

import 'generated/bridge_generated.dart';

VodozemacBindingsDartImpl initializeExternalLibrary(String path) =>
    VodozemacBindingsDartImpl(
      loadLibForDart(path),
    );

VodozemacBindingsDartImpl? api;
