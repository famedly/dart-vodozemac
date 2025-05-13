import 'dart:convert';
import 'dart:html';
import 'dart:js_interop';

import 'package:test_core/src/direct_run.dart';
import 'package:test_core/src/runner/reporter/expanded.dart';
import 'package:test_core/src/util/print_sink.dart';

import 'vodozemac_test.dart' as generic_test;

@JS()
external void close();

void main() async {
  final result = await directRunTests(
    () => generic_test.main(),
    reporterFactory: (engine) => ExpandedReporter.watch(
      engine,
      PrintSink(),
      color: true,
      printPlatform: false,
      printPath: false,
    ),
  ).catchError((e) => false);
  _close(result);
}

void _close(bool result) {
  final socket = WebSocket(Uri.base.replace(scheme: 'ws').toString());
  socket.onOpen.first.then((_) {
    socket.send(jsonEncode({'__result__': result}));
    close();
  });
}
