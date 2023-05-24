import 'dart:convert';
import 'dart:html';

import 'package:js/js.dart';
import 'package:test_core/src/direct_run.dart';
import 'package:test_core/src/runner/reporter/expanded.dart';
import 'package:test_core/src/util/print_sink.dart';

import '../test/generic_test.dart' as generic_test;
import '../test/vodozemac_test.dart' as vodozemac_test;

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
  );
  final result_vodozemac = await directRunTests(
    () => vodozemac_test.main(),
    reporterFactory: (engine) => ExpandedReporter.watch(
      engine,
      PrintSink(),
      color: true,
      printPlatform: false,
      printPath: false,
    ),
  );
  _close(result && result_vodozemac);
}

void _close(bool result) {
  final socket = WebSocket(Uri.base.replace(scheme: 'ws').toString());
  socket.onOpen.first.then((_) {
    socket.send(jsonEncode({'__result__': result}));
    close();
  });
}
