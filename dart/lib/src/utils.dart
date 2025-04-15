import 'dart:convert';
import 'dart:typed_data';

class Utils {
  static Uint8List base64decodeUnpadded(String s) {
    final needEquals = (4 - (s.length % 4)) % 4;
    return base64.decode(s + ('=' * needEquals));
  }
}
