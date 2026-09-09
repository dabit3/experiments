import 'dart:math' as math;

/// Immutable 2D vector used throughout the simulation.
class V2 {
  const V2(this.x, this.y);

  static const zero = V2(0, 0);

  final double x;
  final double y;

  V2 operator +(V2 o) => V2(x + o.x, y + o.y);
  V2 operator -(V2 o) => V2(x - o.x, y - o.y);
  V2 operator *(double s) => V2(x * s, y * s);
  V2 operator -() => V2(-x, -y);

  double get length => math.sqrt(x * x + y * y);
  double get length2 => x * x + y * y;
  double get angle => math.atan2(y, x);

  double dot(V2 o) => x * o.x + y * o.y;
  double cross(V2 o) => x * o.y - y * o.x;
  double distanceTo(V2 o) => (this - o).length;

  V2 normalized() {
    final l = length;
    return l < 1e-9 ? zero : V2(x / l, y / l);
  }

  /// Perpendicular vector rotated 90° counter-clockwise.
  V2 perp() => V2(-y, x);

  V2 lerp(V2 o, double t) => V2(x + (o.x - x) * t, y + (o.y - y) * t);

  static V2 fromAngle(double a, [double len = 1]) =>
      V2(math.cos(a) * len, math.sin(a) * len);

  Map<String, num> toJson() => {'x': _r(x), 'y': _r(y)};
  static V2 fromJson(Map<String, dynamic> j) =>
      V2((j['x'] as num).toDouble(), (j['y'] as num).toDouble());

  @override
  String toString() => 'V2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Rounds to two decimals so wire payloads stay compact.
double _r(double v) => (v * 100).roundToDouble() / 100;
double round2(double v) => _r(v);

/// Wraps an angle to (-pi, pi].
double wrapAngle(double a) {
  var r = a % (2 * math.pi);
  if (r > math.pi) r -= 2 * math.pi;
  if (r <= -math.pi) r += 2 * math.pi;
  return r;
}

/// Moves [a] toward [b] by at most [maxDelta] radians, along the shortest arc.
double turnToward(double a, double b, double maxDelta) {
  final d = wrapAngle(b - a);
  if (d.abs() <= maxDelta) return b;
  return a + (d > 0 ? maxDelta : -maxDelta);
}

double clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

double lerpD(double a, double b, double t) => a + (b - a) * t;

/// Returns true when [p] lies inside the polygon [poly] (even-odd rule).
bool pointInPolygon(V2 p, List<V2> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i];
    final b = poly[j];
    if ((a.y > p.y) != (b.y > p.y) &&
        p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

/// Catmull-Rom interpolation between p1 and p2 with neighbors p0/p3.
V2 catmullRom(V2 p0, V2 p1, V2 p2, V2 p3, double t) {
  final t2 = t * t;
  final t3 = t2 * t;
  return V2(
    0.5 *
        ((2 * p1.x) +
            (-p0.x + p2.x) * t +
            (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
            (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
    0.5 *
        ((2 * p1.y) +
            (-p0.y + p2.y) * t +
            (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
            (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
  );
}

/// Deterministic Park–Miller PRNG. Uses only values below 2^53 so it produces
/// identical sequences on the Dart VM and on the web.
class Rng {
  Rng(int seed) : _state = (seed % 2147483646) + 1;

  int _state;

  int get state => _state;

  int nextInt(int max) {
    _state = (_state * 48271) % 2147483647;
    return _state % max;
  }

  double nextDouble() {
    _state = (_state * 48271) % 2147483647;
    return (_state - 1) / 2147483646;
  }

  /// Picks an index according to integer [weights].
  int weighted(List<int> weights) {
    var total = 0;
    for (final w in weights) {
      total += w;
    }
    var roll = nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return i;
    }
    return weights.length - 1;
  }
}
