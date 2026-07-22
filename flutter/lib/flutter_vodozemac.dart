// ignore_for_file: unused-files, unused-code - nothing in package imports the public entry point only consumers do

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

Future<void> init({String wasmPath = './pkg/'}) => vod.init(
      wasmPath: wasmPath,
      libraryPath: './',
      stem: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
          ? 'flutter_vodozemac'
          : 'vodozemac_bindings_dart',
    );
