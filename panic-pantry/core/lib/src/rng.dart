/// Small deterministic PRNG (xorshift32) so server, bots and tests produce the
/// same sequence on every Dart platform (VM, dart2js, wasm).
class Rng {
  Rng(int seed) : _state = (seed & 0xffffffff) == 0 ? 0x9e3779b9 : seed & 0xffffffff;

  int _state;

  int get state => _state;

  int nextInt(int max) {
    var x = _state;
    x ^= (x << 13) & 0xffffffff;
    x ^= x >> 17;
    x ^= (x << 5) & 0xffffffff;
    _state = x & 0xffffffff;
    return _state % max;
  }

  double nextDouble() => nextInt(1 << 24) / (1 << 24);
}
