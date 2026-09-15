import 'rng.dart';

/// 32-bit FNV-1a, incremental. Used for world/chat state fingerprints that
/// every client and the server must agree on.
class Fnv32 {
  int _h = 0x811c9dc5;

  void addByte(int b) {
    _h ^= b & 0xff;
    _h = mul32(_h, 0x01000193);
  }

  void addInt(int v) {
    addByte(v);
    addByte(v >>> 8);
    addByte(v >>> 16);
    addByte(v >>> 24);
  }

  void addString(String s) {
    for (final c in s.codeUnits) {
      addInt(c);
    }
    addByte(0xff);
  }

  int get value => _h;

  String get hex => _h.toRadixString(16).padLeft(8, '0');
}
