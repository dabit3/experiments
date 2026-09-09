/// Exact 32-bit multiplication that also works on the web, where ints are
/// IEEE doubles and a full 32x32 product would lose precision.
int mul32(int a, int b) {
  final aLo = a & 0xffff, aHi = (a >>> 16) & 0xffff;
  final bLo = b & 0xffff, bHi = (b >>> 16) & 0xffff;
  final cross = (aHi * bLo + aLo * bHi) & 0xffff;
  return (aLo * bLo + (cross << 16)) & 0xffffffff;
}

/// Deterministic 32-bit xorshift generator. Identical sequences on every
/// platform (including dart2js) because all arithmetic stays within 32 bits.
class Rng {
  Rng(int seed) : _s = (seed & 0xffffffff) == 0 ? 0x9e3779b9 : seed & 0xffffffff;

  int _s;

  int nextInt(int max) {
    if (max <= 0) return 0;
    return _next() % max;
  }

  double nextDouble() => _next() / 4294967296.0;

  bool chance(double p) => nextDouble() < p;

  int _next() {
    var x = _s;
    x ^= (x << 13) & 0xffffffff;
    x ^= x >>> 17;
    x ^= (x << 5) & 0xffffffff;
    _s = x & 0xffffffff;
    return _s;
  }
}

/// Maps any small signed integer onto [0, 2^32) identically on VM and web.
int u32(int v) => v % 4294967296;

/// Integer hash mixing used for per-column decisions (tree placement, decor).
int hash3(int a, int b, int c) {
  var h = (mul32(u32(a), 374761393) + mul32(u32(b), 668265263) + mul32(u32(c), 2147483647)) % 4294967296;
  h = mul32(h ^ (h >>> 13), 1274126177);
  return (h ^ (h >>> 16)) & 0xffffffff;
}
