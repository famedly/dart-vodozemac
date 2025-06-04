import 'dart:io';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  print(args);

  final platforms = args.isNotEmpty
      ? args.map((platform) => SupportedPlatforms.fromName(platform)).toList()
      : SupportedPlatforms.defaultPlatforms;

  const commands = {'cargo', 'git'};
  for (final command in commands) {
    if (await commandExists(command) == false) {
      print('[Vodozemac] ❌ Missing command $command in PATH');
      return;
    }
  }

  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    print(
        '[Vodozemac] ❌ Current working directory is not a Flutter/Dart project.');
  }

  final vodozemacDir = Directory(
    path.join(Directory.current.path, '.vodozemac'),
  );
  if (await vodozemacDir.exists()) await vodozemacDir.delete(recursive: true);
  await sh('git', [
    'clone',
    'https://github.com/famedly/dart-vodozemac.git',
    '.vodozemac',
  ]);
  print('[Vodozemac] ✅ Downloaded vodozemac rust bindings');

  for (final platform in platforms) {
    final buildDir = Directory('./${platform.name}');
    if (!buildDir.existsSync()) continue;

    print('[Vodozemac] ✅ Found build directory for ${platform.name}');

    await sh(
      'rustup',
      ['target', 'add', ...platform.targets],
      workingDirectory: path.join(vodozemacDir.path, 'rust'),
    );
    print('[Vodozemac] ✅ Activated target(s) ${platform.targets}');

    switch (platform) {
      case SupportedPlatforms.android:
        await sh(
          'cargo',
          ['install', 'cargo-ndk'],
          workingDirectory: path.join(vodozemacDir.path, 'rust'),
        );
        print('[Vodozemac] ✅ Installed cargo-ndk');
        await sh(
          'cargo',
          [
            'ndk',
            for (final target in platform.targets) ...[
              '-t',
              target,
            ],
            '-o',
            '../../android/app/src/main/jniLibs',
            'build',
          ],
          workingDirectory: path.join(vodozemacDir.path, 'rust'),
        );
        print('[Vodozemac] ✅ Built jniLibs');
        break;
      case SupportedPlatforms.macos:
      case SupportedPlatforms.macosX86:
        final macosFrameworksDir =
            Directory(path.join(Directory.current.path, 'macos', 'Frameworks'));
        await macosFrameworksDir.create();
        for (final target in platform.targets) {
          await sh(
            'cargo',
            ['build', '--target', target, '--release'],
            workingDirectory: path.join(vodozemacDir.path, 'rust'),
          );
          await File(
            path.join(vodozemacDir.path, 'rust', 'target', target, 'release',
                'libvodozemac_bindings_dart.dylib'),
          ).copy(path.join(
            macosFrameworksDir.path,
            'libvodozemac_bindings_dart.dylib',
          ));
          print('[Vodozemac] ✅ Built for $target');
        }
        break;
      case SupportedPlatforms.ios:
      case SupportedPlatforms.iosSimulators:
        for (final target in platform.targets) {
          await sh(
            'cargo',
            ['build', '--target', target, '--release'],
            workingDirectory: path.join(vodozemacDir.path, 'rust'),
          );
          print('[Vodozemac] ✅ Built for $target');
        }

        await sh(
          'lipo',
          [
            '-create',
            ...platform.targets.map((target) =>
                'target/$target/release/libvodozemac_bindings_dart.a'),
            '-output',
            '../../ios/Runner/libvodozemac_bindings_dart.a',
          ],
          workingDirectory: path.join(vodozemacDir.path, 'rust'),
        );
        print(
            '[Vodozemac] ✅ Created static library for iOS. Please refer to the documentation to add them to Xcode!');
        break;
      case SupportedPlatforms.web:
        for (final target in platform.targets) {
          await sh(
            'flutter_rust_bridge_codegen',
            [
              'build-web',
              '--dart-root',
              path.join(vodozemacDir.path, 'dart'),
              '--rust-root',
              path.join(vodozemacDir.path, 'rust'),
              '--release',
            ],
            workingDirectory: vodozemacDir.path,
          );
          print('[Vodozemac] ✅ Built for $target');
        }

        const files = {
          'vodozemac_bindings_dart.js',
          'vodozemac_bindings_dart_bg.wasm',
          'package.json',
        };
        final webPkgDir =
            await Directory(path.join(Directory.current.path, 'web', 'pkg'))
                .create();
        for (final file in files) {
          File(
            path.join(
              vodozemacDir.path,
              'dart',
              'web',
              'pkg',
              file,
            ),
          ).copy(path.join(webPkgDir.path, file));
        }
      case SupportedPlatforms.linux:
        final libDir =
            Directory(path.join(Directory.current.path, 'linux', 'lib'));
        await libDir.create();
        for (final target in platform.targets) {
          await sh(
            'cargo',
            ['build', '--target', target, '--release'],
            workingDirectory: path.join(vodozemacDir.path, 'rust'),
          );
          await File(path.join(
            vodozemacDir.path,
            'rust',
            target,
            'release',
            'libvodozemac_bindings_dart.so',
          )).copy(libDir.path);
          print('[Vodozemac] ✅ Built for $target');
        }
    }
  }

  //await vodozemacDir.delete(recursive: true);
}

enum SupportedPlatforms {
  android({
    'armv7-linux-androideabi',
    'aarch64-linux-android',
    'i686-linux-android',
    'x86_64-linux-android',
  }),
  ios({'aarch64-apple-ios', 'x86_64-apple-ios'}),
  iosSimulators({'aarch64-apple-ios-sim'}),
  web({'wasm32-unknown-unknown'}),
  macos({'aarch64-apple-darwin'}),
  macosX86({'x86_64-apple-darwin'}),
  linux({'x86_64-unknown-linux-gnu', 'aarch64-unknown-linux-gnu'});

  const SupportedPlatforms(this.targets);
  static const Set<SupportedPlatforms> defaultPlatforms = {
    android,
    ios,
    web,
    macos,
    linux,
  };
  factory SupportedPlatforms.fromName(String name) =>
      values.singleWhere((platform) => platform.name == name);

  final Set<String> targets;
}

Future<void> sh(
  String cmd,
  List<String> args, {
  String? workingDirectory,
}) async {
  final result = await Process.run(
    cmd,
    args,
    workingDirectory: workingDirectory,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw Exception(
        '[Vodozemac] ❌ Command failed with exit code ${result.exitCode}');
  }
}

Future<bool> commandExists(String command) async {
  final isWindows = Platform.isWindows;
  final result = await Process.run(
    isWindows ? 'where' : 'which',
    [command],
  );
  return result.exitCode == 0;
}
