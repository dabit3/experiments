/// Deterministic 32-bit xorshift RNG shared by server, bots, map generation
/// and client-side prediction so that a seed always yields the same match.
class Rng {
  Rng(int seed)
      : _s = (seed & 0xFFFFFFFF) == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int _s;

  int get state => _s;

  /// Next 32-bit unsigned integer.
  int nextInt32() {
    var x = _s;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _s = x & 0xFFFFFFFF;
    return _s;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextInt32() / 4294967296.0;

  /// Uniform integer in [0, max).
  int nextInt(int max) => max <= 0 ? 0 : nextInt32() % max;

  /// Uniform double in [min, max).
  double range(double min, double max) => min + (max - min) * nextDouble();

  bool chance(double p) => nextDouble() < p;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// Picks an index using the provided relative weights.
  int weighted(List<double> weights) {
    var total = 0.0;
    for (final w in weights) {
      total += w;
    }
    var r = nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      r -= weights[i];
      if (r < 0) return i;
    }
    return weights.length - 1;
  }

  /// Derives an independent child stream, used so that unrelated systems do
  /// not perturb each other's sequences.
  Rng fork(int salt) => Rng((_s ^ (salt * 0x45D9F3B)) & 0xFFFFFFFF);
}

/// 32-bit wrapping multiply that is exact on every Dart platform. On the web
/// ints are doubles, so a plain product of two 32-bit values loses low bits
/// once it exceeds 2^53.
int mul32(int a, int b) {
  final aLo = a & 0xFFFF;
  final aHi = (a >> 16) & 0xFFFF;
  final bLo = b & 0xFFFF;
  final bHi = (b >> 16) & 0xFFFF;
  final hi = (aHi * bLo + aLo * bHi) & 0xFFFF;
  return (aLo * bLo + hi * 0x10000) & 0xFFFFFFFF;
}

/// Stable string hash (FNV-1a, 32-bit) used to derive seeds from room codes.
int stableHash(String input) {
  var h = 0x811C9DC5;
  for (final c in input.codeUnits) {
    h = mul32(h ^ c, 0x01000193);
  }
  return h;
}
