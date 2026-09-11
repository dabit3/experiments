/// Deterministic Lehmer/Park–Miller generator.
///
/// Every intermediate value stays below 2^53 so results are identical on the
/// Dart VM and when compiled to JavaScript.
class SeededRng {
  SeededRng(int seed) : _state = (seed % 2147483646).abs() + 1;

  int _state;

  int get state => _state;

  /// Returns a value in `[0, 2147483646)`.
  int nextInt32() {
    _state = (_state * 48271) % 2147483647;
    return _state - 1;
  }

  /// Returns a value in `[0, max)`.
  int nextInt(int max) => max <= 0 ? 0 : nextInt32() % max;

  /// Returns a value in `[0, 1)`.
  double nextDouble() => nextInt32() / 2147483646;

  /// Returns a value in `[min, max)`.
  double nextRange(double min, double max) => min + nextDouble() * (max - min);

  T pick<T>(List<T> items) => items[nextInt(items.length)];
}
