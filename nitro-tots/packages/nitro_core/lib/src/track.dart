import 'dart:math' as math;

import 'math.dart';

enum Surface { road, offroad, shortcut, wall }

enum HazardKind { oilSlick, pillar, roller }

class TrackTheme {
  const TrackTheme({
    required this.ground,
    required this.groundAlt,
    required this.road,
    required this.roadEdge,
    required this.curbA,
    required this.curbB,
    required this.shortcut,
    required this.accent,
    required this.sky,
  });

  final int ground;
  final int groundAlt;
  final int road;
  final int roadEdge;
  final int curbA;
  final int curbB;
  final int shortcut;
  final int accent;
  final int sky;
}

/// Feature positions below are expressed in control-point space: `t = 2.5`
/// means halfway between control points 2 and 3. Offsets are lateral world
/// units (negative = left of the travel direction).

class ItemBoxDef {
  const ItemBoxDef(this.t, this.offsets);
  final double t;
  final List<double> offsets;
}

class BoostPadDef {
  const BoostPadDef(this.t, this.offset, {this.length = 26, this.width = 14});
  final double t;
  final double offset;
  final double length;
  final double width;
}

class HazardDef {
  const HazardDef(this.kind, this.t, this.offset, {this.range = 0});
  final HazardKind kind;
  final double t;
  final double offset;

  /// Lateral travel for [HazardKind.roller].
  final double range;
}

class JumpDef {
  const JumpDef(this.t, {this.length = 24, this.offset = 0, this.width = 0});
  final double t;
  final double length;
  final double offset;

  /// 0 = full road width.
  final double width;
}

class ShortcutDef {
  const ShortcutDef(this.name, this.polygon, {required this.entryT, required this.exitT});
  final String name;
  final List<V2> polygon;
  final double entryT;
  final double exitT;
}

class TrackDef {
  const TrackDef({
    required this.id,
    required this.name,
    required this.location,
    required this.controlPoints,
    required this.widths,
    required this.theme,
    this.itemBoxes = const [],
    this.boostPads = const [],
    this.hazards = const [],
    this.jumps = const [],
    this.shortcuts = const [],
    this.isArena = false,
    this.grassMargin = 34,
    this.description = '',
  });

  final String id;
  final String name;
  final String location;
  final String description;
  final List<V2> controlPoints;

  /// Road width at each control point (interpolated between them).
  final List<double> widths;
  final TrackTheme theme;
  final List<ItemBoxDef> itemBoxes;
  final List<BoostPadDef> boostPads;
  final List<HazardDef> hazards;
  final List<JumpDef> jumps;
  final List<ShortcutDef> shortcuts;
  final bool isArena;
  final double grassMargin;
}

class TrackSample {
  const TrackSample(this.pos, this.tangent, this.width, this.s);
  final V2 pos;
  final V2 tangent;
  final double width;

  /// Distance along the lap from the start line.
  final double s;

  V2 get normal => tangent.perp();
}

class PlacedBoostPad {
  const PlacedBoostPad(this.pos, this.angle, this.length, this.width);
  final V2 pos;
  final double angle;
  final double length;
  final double width;

  bool contains(V2 p) {
    final d = p - pos;
    final fwd = V2.fromAngle(angle);
    final lon = d.dot(fwd);
    final lat = d.cross(fwd);
    return lon.abs() <= length / 2 && lat.abs() <= width / 2;
  }
}

class PlacedJump {
  const PlacedJump(this.pos, this.angle, this.length, this.width);
  final V2 pos;
  final double angle;
  final double length;
  final double width;

  bool contains(V2 p) {
    final d = p - pos;
    final fwd = V2.fromAngle(angle);
    return d.dot(fwd).abs() <= length / 2 && d.cross(fwd).abs() <= width / 2;
  }
}

class PlacedHazard {
  const PlacedHazard(this.kind, this.pos, this.angle, this.range);
  final HazardKind kind;
  final V2 pos;
  final double angle;
  final double range;
}

class PlacedItemBox {
  const PlacedItemBox(this.index, this.pos);
  final int index;
  final V2 pos;
}

/// Sampled geometry derived from a [TrackDef].
class Track {
  Track(this.def) {
    _build();
  }

  static const sampleCount = 512;
  static const checkpointCount = 6;

  final TrackDef def;
  late final List<TrackSample> samples;
  late final double length;
  late final List<PlacedBoostPad> boostPads;
  late final List<PlacedJump> jumps;
  late final List<PlacedHazard> hazards;
  late final List<PlacedItemBox> itemBoxes;
  late final List<V2> startGrid;
  late final double startHeading;
  late final V2 boundsMin;
  late final V2 boundsMax;
  late final double Function(double) _tOf;

  /// Converts a control-point-space position into a lap fraction (0..1).
  double tOfControlPoint(double cp) => _tOf(cp);

  String get id => def.id;
  String get name => def.name;
  bool get isArena => def.isArena;

  void _build() {
    final cps = def.controlPoints;
    final n = cps.length;
    // Densely sample the closed Catmull-Rom loop, then re-sample by arc length.
    final dense = <V2>[];
    final denseWidth = <double>[];
    const perSeg = 24;
    for (var i = 0; i < n; i++) {
      final p0 = cps[(i - 1 + n) % n];
      final p1 = cps[i];
      final p2 = cps[(i + 1) % n];
      final p3 = cps[(i + 2) % n];
      final w1 = def.widths[i % def.widths.length];
      final w2 = def.widths[(i + 1) % def.widths.length];
      for (var k = 0; k < perSeg; k++) {
        final t = k / perSeg;
        dense.add(catmullRom(p0, p1, p2, p3, t));
        denseWidth.add(lerpD(w1, w2, t));
      }
    }
    final cum = <double>[0];
    for (var i = 1; i <= dense.length; i++) {
      cum.add(cum[i - 1] + dense[i % dense.length].distanceTo(dense[i - 1]));
    }
    length = cum.last;
    // Converts a control-point-space position (e.g. 2.5 = halfway between
    // control points 2 and 3) into a lap fraction.
    double tOf(double cp) {
      final di = ((cp % n) * perSeg);
      final i0 = di.floor() % dense.length;
      final f = di - di.floor();
      final s = lerpD(cum[i0], cum[i0 + 1], f);
      return (s / length) % 1.0;
    }

    _tOf = tOf;
    final out = <TrackSample>[];
    var j = 0;
    for (var i = 0; i < sampleCount; i++) {
      final target = length * i / sampleCount;
      while (j < dense.length - 1 && cum[j + 1] < target) {
        j++;
      }
      final segLen = cum[j + 1] - cum[j];
      final f = segLen <= 0 ? 0.0 : (target - cum[j]) / segLen;
      final a = dense[j];
      final b = dense[(j + 1) % dense.length];
      final pos = a.lerp(b, f);
      final width = lerpD(denseWidth[j], denseWidth[(j + 1) % dense.length], f);
      out.add(TrackSample(pos, (b - a).normalized(), width, target));
    }
    // Smooth tangents with neighbours for a stable normal.
    samples = List.generate(sampleCount, (i) {
      final prev = out[(i - 1 + sampleCount) % sampleCount].pos;
      final next = out[(i + 1) % sampleCount].pos;
      return TrackSample(out[i].pos, (next - prev).normalized(), out[i].width, out[i].s);
    });

    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final s in samples) {
      final r = s.width / 2 + def.grassMargin + 40;
      minX = math.min(minX, s.pos.x - r);
      minY = math.min(minY, s.pos.y - r);
      maxX = math.max(maxX, s.pos.x + r);
      maxY = math.max(maxY, s.pos.y + r);
    }
    for (final sc in def.shortcuts) {
      for (final p in sc.polygon) {
        minX = math.min(minX, p.x - 40);
        minY = math.min(minY, p.y - 40);
        maxX = math.max(maxX, p.x + 40);
        maxY = math.max(maxY, p.y + 40);
      }
    }
    boundsMin = V2(minX, minY);
    boundsMax = V2(maxX, maxY);

    boostPads = [for (final b in def.boostPads) PlacedBoostPad(pointAt(tOf(b.t), b.offset), sampleAt(tOf(b.t)).tangent.angle, b.length, b.width)];
    jumps = [
      for (final j in def.jumps)
        PlacedJump(pointAt(tOf(j.t), j.offset), sampleAt(tOf(j.t)).tangent.angle, j.length, j.width == 0 ? sampleAt(tOf(j.t)).width : j.width),
    ];
    hazards = [for (final h in def.hazards) PlacedHazard(h.kind, pointAt(tOf(h.t), h.offset), sampleAt(tOf(h.t)).tangent.angle, h.range)];
    var idx = 0;
    itemBoxes = [
      for (final row in def.itemBoxes)
        for (final o in row.offsets) PlacedItemBox(idx++, pointAt(tOf(row.t), o)),
    ];

    final start = samples[0];
    startHeading = start.tangent.angle;
    startGrid = List.generate(8, (i) {
      final row = i ~/ 2;
      final col = i % 2;
      final back = 16.0 + row * 16.0;
      final side = (col == 0 ? -1.0 : 1.0) * start.width * 0.22;
      final s = sampleAtDistance(-back);
      return s.pos + s.normal * side;
    });
  }

  TrackSample sampleAt(double t) {
    final i = ((t % 1.0) * sampleCount).floor() % sampleCount;
    return samples[i];
  }

  TrackSample sampleAtDistance(double s) {
    final t = ((s % length) + length) % length / length;
    return sampleAt(t);
  }

  V2 pointAt(double t, double offset) {
    final s = sampleAt(t);
    return s.pos + s.normal * offset;
  }

  /// Index of the nearest centerline sample. [hint] restricts the search to a
  /// window around a previous result for speed; the full loop is scanned when
  /// the hint is null or the window result looks unreliable.
  int nearestIndex(V2 p, [int? hint]) {
    if (hint != null) {
      var best = hint;
      var bestD = samples[hint].pos.distanceTo(p);
      for (var k = -40; k <= 40; k++) {
        final i = (hint + k + sampleCount) % sampleCount;
        final d = samples[i].pos.distanceTo(p);
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
      if (bestD < samples[best].width + def.grassMargin + 60) return best;
    }
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < sampleCount; i++) {
      final d = samples[i].pos.distanceTo(p);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Signed lateral offset of [p] from sample [i] (negative = left).
  double lateral(V2 p, int i) {
    final s = samples[i];
    return s.tangent.cross(p - s.pos);
  }

  Surface surfaceAt(V2 p, int nearest) {
    for (final sc in def.shortcuts) {
      if (pointInPolygon(p, sc.polygon)) return Surface.shortcut;
    }
    final s = samples[nearest];
    final d = lateral(p, nearest).abs();
    if (isArena) {
      return d <= s.width / 2 ? Surface.road : Surface.wall;
    }
    if (d <= s.width / 2) return Surface.road;
    if (d <= s.width / 2 + def.grassMargin) return Surface.offroad;
    return Surface.wall;
  }

  /// Progress (0..1 of a lap) for the sample index.
  double progressOf(int i) => i / sampleCount;

  int checkpointOf(int i) => (i * checkpointCount) ~/ sampleCount;
}
