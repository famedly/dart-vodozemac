// ignore_for_file: unused-files, unused-code - nothing in package imports the public entry point only consumers do

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

/// The directory [init] loads the native library from when no `libraryPath`
/// is given.
String defaultLibraryPath() {
  if (kIsWeb || !Platform.isMacOS) return './';
  final parts = Platform.resolvedExecutable.split('/');
  final bundle = parts.lastIndexWhere((part) => part.endsWith('.app'));
  if (bundle == -1) return './';
  return Uri.directory(
    '${parts.sublist(0, bundle + 1).join('/')}/Contents/Frameworks',
  ).toString();
}

Future<void> init({String wasmPath = './pkg/', String? libraryPath}) =>
    vod.init(
      wasmPath: wasmPath,
      libraryPath: libraryPath ?? defaultLibraryPath(),
      stem: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
          ? 'flutter_vodozemac'
          : 'vodozemac_bindings_dart',
    );
