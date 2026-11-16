import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final root = args[0];

  var testPassed = false;
  var testCompleted = false;

  // Create static file handler
  final staticHandler = createStaticHandler(
    root,
    defaultDocument: 'index.html',
    contentTypeResolver: MimeTypeResolver()
      ..addExtension('js', 'text/javascript')
      ..addExtension('wasm', 'application/wasm')
      ..addExtension('json', 'application/json'),
  );

  // Create WebSocket handler for test communication
  final wsHandler = webSocketHandler((WebSocketChannel channel, _) async {
    await for (final message in channel.stream) {
      try {
        final data = jsonDecode(message);
        if (data is Map) {
          if (data.containsKey('__result__')) {
            testPassed = data['__result__'] == true;
            testCompleted = true;
          } else if (data.containsKey('error')) {
            print('Test error: ${data['error']}');
            testPassed = false;
            testCompleted = true;
          } else {
            print(data);
          }
        }
      } catch (err, st) {
        print('Error processing message: $err\nStacktrace:\n$st');
        testPassed = false;
        testCompleted = true;
      }
    }
  });

  final handler = const Pipeline()
      .addHandler(Cascade().add(wsHandler).add(staticHandler).handler);

  // Start server
  final ip = InternetAddress.anyIPv4;
  final server = await serve(handler, ip, port);
  print('Server listening on http://localhost:${server.port}');

  // Launch browser and run tests
  final browser = await puppeteer.launch(
    headless: true,
    timeout: const Duration(minutes: 5),
    args: ['--no-sandbox'],
  );

  try {
    final page = await browser.newPage();

    // Listen for console messages
    page.onConsole.listen((msg) {
      print('[Browser Console] ${msg.text}');
    });

    // Listen for page errors
    page.onError.listen((error) {
      print('[Browser Error] ${error.message}');
      testPassed = false;
      testCompleted = true;
    });

    await page.goto('http://localhost:${server.port}');

    // Wait for test completion or timeout
    while (!testCompleted) {
      await Future.delayed(const Duration(seconds: 1));
    }
  } catch (e, st) {
    print('Error during test execution: $e\nStacktrace:\n$st');
    testPassed = false;
  } finally {
    await browser.close();
    await server.close();
  }

  // Exit with appropriate code
  exit(testPassed ? 0 : 1);
}
