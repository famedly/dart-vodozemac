import 'dart:convert';

import 'package:vodozemac/vodozemac.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Expected the directory containing the native library');
  }

  await init(
    libraryPath: arguments.single,
    stem: 'flutter_vodozemac',
  );

  final session = GroupSession();
  final encrypted = session.encrypt('Megolm v1 artifact verification');
  final wireVersion = base64.decode(base64.normalize(encrypted)).first;

  if (session.sessionConfigVersion != 1 || wireVersion != 3) {
    throw StateError(
      'Expected Megolm config v1 / wire version 3, got '
      'config v${session.sessionConfigVersion} / wire version $wireVersion',
    );
  }

  print('Verified Megolm config v1 / wire version 3.');
}
