import 'dart:math' as math;

import 'rng.dart';

/// Seeded gradient-free value noise with smooth interpolation. Deterministic
/// across VMs because it only uses integer hashing plus double math on values
/// that are exactly representable.
class ValueNoise {
  ValueNoise(this.seed);

  final int seed;

  double _lattice(int x, int y, int z) => (hash3(x + seed, y - seed * 3, z + seed * 7) & 0xffff) / 65535.0;

  static double _fade(double t) => t * t * (3 - 2 * t);

  double noise2(double x, double y) => noise3(x, y, 0);

  double noise3(double x, double y, double z) {
    final x0 = x.floor(), y0 = y.floor(), z0 = z.floor();
    final fx = _fade(x - x0), fy = _fade(y - y0), fz = _fade(z - z0);
    double lerp(double a, double b, double t) => a + (b - a) * t;
    final c000 = _lattice(x0, y0, z0), c100 = _lattice(x0 + 1, y0, z0);
    final c010 = _lattice(x0, y0 + 1, z0), c110 = _lattice(x0 + 1, y0 + 1, z0);
    final c001 = _lattice(x0, y0, z0 + 1), c101 = _lattice(x0 + 1, y0, z0 + 1);
    final c011 = _lattice(x0, y0 + 1, z0 + 1);
    final c111 = _lattice(x0 + 1, y0 + 1, z0 + 1);
    final x00 = lerp(c000, c100, fx), x10 = lerp(c010, c110, fx);
    final x01 = lerp(c001, c101, fx), x11 = lerp(c011, c111, fx);
    final y0v = lerp(x00, x10, fy), y1v = lerp(x01, x11, fy);
    return lerp(y0v, y1v, fz);
  }

  /// Fractal Brownian motion in [0, 1].
  double fbm2(double x, double y, int octaves, {double persistence = 0.5}) {
    var amp = 1.0, freq = 1.0, sum = 0.0, norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += noise2(x * freq, y * freq) * amp;
      norm += amp;
      amp *= persistence;
      freq *= 2;
    }
    return sum / norm;
  }

  double fbm3(double x, double y, double z, int octaves) {
    var amp = 1.0, freq = 1.0, sum = 0.0, norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += noise3(x * freq, y * freq, z * freq) * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2;
    }
    return sum / norm;
  }
}

double clamp01(double v) => math.max(0, math.min(1, v));
