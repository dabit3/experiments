/// Source of wall-clock time for the server.
///
/// Production uses [RealClock]. Tests use [FixedClock], which starts at a fixed
/// epoch and only advances when the simulation ticks, so timestamps and match
/// timers are reproducible.
abstract class Clock {
  int nowMs();

  /// Called once per server tick; only [FixedClock] cares.
  void tick(int ms) {}
}

class RealClock implements Clock {
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;

  @override
  void tick(int ms) {}
}

class FixedClock implements Clock {
  FixedClock([this._now = 1757000000000]);

  int _now;

  @override
  int nowMs() => _now;

  @override
  void tick(int ms) => _now += ms;
}
