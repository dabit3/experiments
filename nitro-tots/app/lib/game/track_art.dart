import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:nitro_core/nitro_core.dart';

import 'art_assets.dart';

/// Builds a cached vector picture of everything on a track that never moves.
class TrackArt {
  TrackArt(this.track) {
    _build();
  }

  final Track track;
  late final ui.Picture picture;
  late final Rect bounds;
  late final Path roadPath;

  TrackTheme get theme => track.def.theme;

  static Color c(int argb) => Color(argb);

  /// Dim applied to ground outside the drivable band.
  static const beyondTint = Color(0x1A000000);

  void _build() {
    final margin = track.def.grassMargin + 900;
    bounds = Rect.fromLTRB(track.boundsMin.x - margin, track.boundsMin.y - margin, track.boundsMax.x + margin, track.boundsMax.y + margin);
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec, bounds);

    _ground(canvas);
    if (track.isArena) {
      _arena(canvas);
    } else {
      _boundary(canvas);
      _shortcuts(canvas);
      _road(canvas);
      _startLine(canvas);
    }
    _scenery(canvas);
    _boostPads(canvas);
    _jumps(canvas);
    _staticHazards(canvas);
    picture = rec.endRecording();
  }

  void _ground(Canvas canvas) {
    final name = switch (track.id) {
      'sprinkle' => 'sand',
      'mossy' => 'moss',
      'frostbite' => 'ice',
      _ => 'asphalt',
    };
    final texture = ArtAssets.images['ground-$name.jpg'];
    if (texture != null) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = ui.ImageShader(
            texture,
            ui.TileMode.mirror,
            ui.TileMode.mirror,
            Matrix4.diagonal3Values(0.25, 0.25, 1).storage,
            filterQuality: FilterQuality.medium,
          ),
      );
      canvas.drawRect(bounds, Paint()..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [const Color(0x08FFF6CB), const Color(0x22061927)]));
      return;
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [Color.lerp(c(theme.ground), const Color(0xFFF5F6CE), 0.12)!, c(theme.groundAlt)]),
    );
    final alt = Paint()..color = c(theme.groundAlt);
    const cell = 96.0;
    final x0 = (bounds.left / cell).floor();
    final x1 = (bounds.right / cell).ceil();
    final y0 = (bounds.top / cell).floor();
    final y1 = (bounds.bottom / cell).ceil();
    for (var i = x0; i < x1; i++) {
      for (var j = y0; j < y1; j++) {
        canvas.drawOval(Rect.fromLTWH(i * cell, j * cell, cell * 0.8, cell * 0.65), alt..color = c(theme.groundAlt).withValues(alpha: 0.25));
      }
    }
    // Scatter decor blobs (deterministic per track) for a lived-in look.
    final rng = Rng(track.id.codeUnits.fold(7, (a, b) => (a * 31 + b) & 0x7fffffff));
    final blob = Paint()..color = c(theme.groundAlt).withValues(alpha: 0.9);
    final blob2 = Paint()..color = c(theme.accent).withValues(alpha: 0.22);
    for (var i = 0; i < 800; i++) {
      final p = Offset(bounds.left + rng.nextDouble() * bounds.width, bounds.top + rng.nextDouble() * bounds.height);
      final near = track.nearestIndex(V2(p.dx, p.dy));
      final s = track.samples[near];
      final d = s.pos.distanceTo(V2(p.dx, p.dy));
      if (d < s.width / 2 + 40) continue;
      if (track.def.shortcuts.any((sc) => pointInPolygon(V2(p.dx, p.dy), sc.polygon))) continue;
      final r = 6 + rng.nextDouble() * 16;
      canvas.drawCircle(p, r, rng.nextInt(3) == 0 ? blob2 : blob);
    }
  }

  void _scenery(Canvas canvas) {
    final rng = Rng(9182);
    for (var i = 0; i < track.samples.length; i += 9) {
      final sample = track.samples[i];
      for (final side in [-1.0, 1.0]) {
        final radius = 12 + rng.nextDouble() * 14;
        final distance = sample.width / 2 + track.def.grassMargin + radius + 10 + rng.nextDouble() * 35;
        final pos = sample.pos + sample.normal * (distance * side);
        final nearest = track.samples[track.nearestIndex(pos)];
        if (nearest.pos.distanceTo(pos) < nearest.width / 2 + track.def.grassMargin + radius) continue;
        if (track.def.shortcuts.any((sc) => pointInPolygon(pos, sc.polygon))) continue;
        canvas.save();
        canvas.translate(pos.x, pos.y);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(radius * 0.45, radius * 0.6), width: radius * 2.4, height: radius * 1.6),
          Paint()..color = const Color(0x33071827),
        );
        final prop = i % 72 == 0
            ? 'grandstand'
            : i % 99 == 0
            ? 'pit'
            : switch (track.id) {
                'sprinkle' => 'candy',
                'mossy' => 'forest',
                'frostbite' => 'ice',
                _ => 'tower',
              };
        final sprite = ArtAssets.draw(canvas, 'prop-$prop.png', Rect.fromCenter(center: Offset.zero, width: radius * 2.8, height: radius * 2.8));
        if (!sprite) {
          switch (track.id) {
            case 'tincity':
            case 'bowl':
              _building(canvas, radius, i.isEven);
            case 'frostbite':
              _crystal(canvas, radius);
            default:
              _tree(canvas, radius, track.id == 'sprinkle', i ~/ 9 + (side < 0 ? 1 : 0));
          }
        }
        canvas.restore();
      }
    }
    if (track.isArena) return;
    for (var i = 0; i < track.samples.length; i += 24) {
      final s = track.samples[i];
      final pos = s.pos + s.normal * (s.width / 2 + track.def.grassMargin + 4);
      canvas.save();
      canvas.translate(pos.x, pos.y);
      canvas.rotate(s.tangent.angle);
      final sign = RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -5, 36, 10), const Radius.circular(2));
      canvas.drawRRect(sign.shift(const Offset(2, 3)), Paint()..color = const Color(0x55000000));
      canvas.drawRRect(sign, Paint()..color = const Color(0xFF102B3B));
      for (var k = -1; k <= 1; k++) {
        final x = k * 9.0;
        canvas.drawPath(
          Path()
            ..moveTo(x - 3, -3)
            ..lineTo(x + 1, 0)
            ..lineTo(x - 3, 3),
          Paint()
            ..color = c(theme.curbA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      canvas.restore();
    }
  }

  void _tree(Canvas canvas, double r, bool candy, int index) {
    final color = candy
        ? [const Color(0xFFFF9466), const Color(0xFFEC6795), const Color(0xFFC66DB2)][index % 3]
        : [const Color(0xFF247866), const Color(0xFF399660), const Color(0xFF5FAA69)][index % 3];
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-3, -2, 6, r * 0.8), const Radius.circular(2)), Paint()..color = const Color(0xFF8A6850));
    for (final (x, y, scale) in [(0.0, 0.0, 1.0), (-0.4, -0.15, 0.7), (0.25, -0.45, 0.75)]) {
      final center = Offset(x * r, y * r);
      canvas.drawCircle(
        center,
        r * scale,
        Paint()
          ..shader = ui.Gradient.radial(
            center.translate(-r * 0.3, -r * 0.3),
            r * 1.5,
            [Color.lerp(color, const Color(0xFFFFF4B0), 0.25)!, color, Color.lerp(color, const Color(0xFF072F3C), 0.45)!],
            [0, 0.55, 1],
          ),
      );
    }
    if (candy) {
      for (var k = 0; k < 9; k++) {
        final a = k * 2.4;
        final p = Offset(math.cos(a) * r * 0.65, math.sin(a) * r * 0.65);
        canvas.drawLine(
          p,
          p.translate(2, -2),
          Paint()
            ..color = const Color(0xFFFDF1CA)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    } else {
      canvas.drawCircle(Offset(r + 3, 3), 4, Paint()..color = const Color(0xFF53CFC1));
      canvas.drawCircle(Offset(r + 2, 2), 1, Paint()..color = const Color(0xFFEEFFD8));
    }
  }

  void _crystal(Canvas canvas, double r) {
    final p = Path()
      ..moveTo(-r * 0.6, r * 0.6)
      ..lineTo(-r * 0.3, -r)
      ..lineTo(r * 0.3, -r * 1.4)
      ..lineTo(r * 0.7, r * 0.4)
      ..lineTo(0, r)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..shader = ui.Gradient.linear(Offset(-r, -r), Offset(r, r), [const Color(0xFFEEFFFF), const Color(0xFF4DC6E2), const Color(0xFF657FD1)], [0, 0.5, 1]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-r * 0.3, -r)
        ..lineTo(0, r)
        ..lineTo(r * 0.3, -r * 1.4),
      Paint()
        ..color = const Color(0xAAFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(0, r), width: r * 1.8, height: r * 0.35), Paint()..color = const Color(0xFFDDF9FF));
  }

  void _building(Canvas canvas, double r, bool pink) {
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.translate(4, 7), const Radius.circular(5)), Paint()..color = const Color(0xFF101A3F));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [const Color(0xFF53628C), const Color(0xFF243557)]),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFF172544));
    final neon = pink ? const Color(0xFFFF76CC) : const Color(0xFF58E8FF);
    canvas.drawLine(
      rect.bottomLeft.translate(3, -1),
      rect.bottomRight.translate(-3, -1),
      Paint()
        ..color = neon
        ..strokeWidth = 2,
    );
    for (var y = -r + 7; y < r - 4; y += 6) {
      for (var x = -r * 0.85 + 6; x < r * 0.85 - 4; x += 6) {
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 2.5), Paint()..color = neon.withValues(alpha: 0.75));
      }
    }
  }

  void _shortcuts(Canvas canvas) {
    final fill = Paint()..color = c(theme.shortcut);
    final edge = Paint()
      ..color = c(theme.shortcut).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round;
    for (final sc in track.def.shortcuts) {
      final path = Path()..moveTo(sc.polygon.first.x, sc.polygon.first.y);
      for (final p in sc.polygon.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      path.close();
      canvas.drawPath(path, edge);
      canvas.drawPath(path, fill);
      // Dotted tyre marks to hint it's driveable.
      final dots = Paint()..color = const Color(0x22000000);
      final cx = sc.polygon.fold(0.0, (a, p) => a + p.x) / sc.polygon.length;
      final cy = sc.polygon.fold(0.0, (a, p) => a + p.y) / sc.polygon.length;
      for (var i = -2; i <= 2; i++) {
        canvas.drawCircle(Offset(cx + i * 9.0, cy), 2.2, dots);
      }
    }
  }

  /// Fence at the edge of the drivable off-road band, with the world beyond
  /// it dimmed so players can read where the invisible wall is.
  void _boundary(Canvas canvas) {
    final margin = track.def.grassMargin;
    final outer = <Offset>[];
    final inner = <Offset>[];
    for (final s in track.samples) {
      final n = s.normal;
      final d = s.width / 2 + margin;
      outer.add(Offset(s.pos.x + n.x * d, s.pos.y + n.y * d));
      inner.add(Offset(s.pos.x - n.x * d, s.pos.y - n.y * d));
    }
    // Even-odd fills instead of Path.combine: identical output on every renderer.
    final band = Path()
      ..fillType = PathFillType.evenOdd
      ..addPolygon(outer, true)
      ..addPolygon(inner, true);
    final beyond = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addPolygon(outer, true)
      ..addPolygon(inner, true);
    canvas.drawPath(beyond, Paint()..color = beyondTint);
    canvas.drawPath(
      band,
      Paint()
        ..color = c(theme.roadEdge).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    final post = Paint()..color = c(theme.curbA);
    final postRim = Paint()..color = c(theme.roadEdge);
    for (var i = 0; i < track.samples.length; i += 5) {
      for (final ring in [outer, inner]) {
        canvas.drawCircle(ring[i], 3.6, postRim);
        canvas.drawCircle(ring[i], 2.2, post);
      }
    }
  }

  void _road(Canvas canvas) {
    final left = <Offset>[];
    final right = <Offset>[];
    for (final s in track.samples) {
      final n = s.normal;
      left.add(Offset(s.pos.x + n.x * s.width / 2, s.pos.y + n.y * s.width / 2));
      right.add(Offset(s.pos.x - n.x * s.width / 2, s.pos.y - n.y * s.width / 2));
    }
    roadPath = Path()..addPolygon(left, true);
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addPolygon(left, true)
      ..addPolygon(right, true);

    canvas.drawPath(
      ring.shift(const Offset(3, 5)),
      Paint()
        ..color = const Color(0x33071927)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      ring,
      Paint()
        ..color = c(theme.roadEdge)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      ring,
      Paint()..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [Color.lerp(c(theme.road), const Color(0xFF263B50), 0.28)!, c(theme.road)]),
    );
    final asphalt = ArtAssets.images['ground-asphalt.jpg'];
    if (asphalt != null) {
      canvas.drawPath(
        ring,
        Paint()
          ..shader = ui.ImageShader(
            asphalt,
            ui.TileMode.mirror,
            ui.TileMode.mirror,
            Matrix4.diagonal3Values(0.16, 0.16, 1).storage,
            filterQuality: FilterQuality.medium,
          )
          ..color = const Color(0x77FFFFFF)
          ..blendMode = BlendMode.softLight,
      );
    }
    canvas.save();
    canvas.clipPath(ring);
    final grain = Rng(781);
    final texture = Paint()..color = const Color(0x10FFFFFF);
    for (var i = 0; i < track.samples.length; i += 2) {
      final s = track.samples[i];
      for (var n = 0; n < 4; n++) {
        final p = s.pos + s.normal * ((grain.nextDouble() - 0.5) * s.width);
        canvas.drawCircle(Offset(p.x, p.y), 0.35 + grain.nextDouble() * 0.5, texture);
      }
    }
    canvas.restore();

    // Curb stripes along both edges.
    final a = Paint()..color = c(theme.curbA);
    final b = Paint()..color = c(theme.curbB);
    for (var i = 0; i < track.samples.length; i++) {
      final s = track.samples[i];
      final s2 = track.samples[(i + 1) % track.samples.length];
      final n = s.normal;
      final paint = (i ~/ 3).isEven ? a : b;
      for (final side in [1.0, -1.0]) {
        final o1 = Offset(s.pos.x + n.x * side * (s.width / 2 - 1), s.pos.y + n.y * side * (s.width / 2 - 1));
        final o2 = Offset(s2.pos.x + s2.normal.x * side * (s2.width / 2 - 1), s2.pos.y + s2.normal.y * side * (s2.width / 2 - 1));
        canvas.drawLine(
          o1,
          o2,
          paint
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.butt,
        );
      }
    }
    final lane = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = 0.7;
    for (var i = 0; i < track.samples.length; i++) {
      final s = track.samples[i];
      final next = track.samples[(i + 1) % track.samples.length];
      for (final side in [-1.0, 1.0]) {
        final p = s.pos + s.normal * ((s.width / 2 - 5) * side);
        final q = next.pos + next.normal * ((next.width / 2 - 5) * side);
        canvas.drawLine(Offset(p.x, p.y), Offset(q.x, q.y), lane);
      }
    }

    // Centre dashes.
    final dash = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < track.samples.length; i += 4) {
      final s = track.samples[i];
      final s2 = track.samples[(i + 2) % track.samples.length];
      canvas.drawLine(Offset(s.pos.x, s.pos.y), Offset(s2.pos.x, s2.pos.y), dash);
    }
  }

  void _arena(Canvas canvas) {
    final cps = track.def.controlPoints;
    final cx = cps.fold(0.0, (a, p) => a + p.x) / cps.length;
    final cy = cps.fold(0.0, (a, p) => a + p.y) / cps.length;
    final centre = Offset(cx, cy);
    final mid = cps.first.distanceTo(V2(cx, cy));
    final w = track.samples.first.width;
    final outer = mid + w / 2;
    final inner = mid - w / 2;
    canvas.drawCircle(centre, outer + 10, Paint()..color = c(theme.roadEdge));
    canvas.drawCircle(centre, outer, Paint()..color = c(theme.road));
    final a = Paint()..color = c(theme.curbA);
    final b = Paint()..color = c(theme.curbB);
    for (var i = 0; i < 72; i++) {
      final t0 = i / 72 * math.pi * 2;
      final t1 = (i + 1) / 72 * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: outer - 3),
        t0,
        t1 - t0,
        false,
        (i.isEven ? a : b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }
    // Ring markings.
    for (final rr in [mid - w * 0.22, mid, mid + w * 0.22]) {
      canvas.drawCircle(
        centre,
        rr,
        Paint()
          ..color = const Color(0x1AFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    // Central fountain (the wall in the middle).
    canvas.drawCircle(centre, inner + 8, Paint()..color = c(theme.roadEdge));
    canvas.drawCircle(centre, inner, Paint()..color = c(theme.accent).withValues(alpha: 0.9));
    canvas.drawCircle(centre, inner * 0.55, Paint()..color = const Color(0xFF9BE7FF));
    canvas.drawCircle(centre.translate(-inner * 0.2, -inner * 0.2), inner * 0.18, Paint()..color = const Color(0xCCFFFFFF));
    roadPath = Path()..addOval(Rect.fromCircle(center: centre, radius: outer));
  }

  void _startLine(Canvas canvas) {
    final s = track.samples[0];
    final n = s.normal;
    final t = s.tangent;
    final half = s.width / 2;
    const cells = 8;
    final cellW = s.width / cells;
    const depth = 10.0;
    for (var i = 0; i < cells; i++) {
      for (var j = 0; j < 2; j++) {
        final lat = -half + cellW * i;
        final lon = -depth / 2 + j * depth / 2;
        final p = Offset(s.pos.x + n.x * lat + t.x * lon, s.pos.y + n.y * lat + t.y * lon);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(t.angle);
        canvas.drawRect(Rect.fromLTWH(0, 0, depth / 2, cellW), Paint()..color = ((i + j).isEven ? const Color(0xFFFFFFFF) : const Color(0xFF2B2440)));
        canvas.restore();
      }
    }
  }

  void _boostPads(Canvas canvas) {
    for (final p in track.boostPads) {
      canvas.save();
      canvas.translate(p.pos.x, p.pos.y);
      canvas.rotate(p.angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: p.length, height: p.width);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(4)), Paint()..color = const Color(0xFF182F43));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [const Color(0xFFFFCD4B), const Color(0xFFFF643D)]),
      );
      // Chevrons.
      final ch = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var i = -1; i <= 1; i++) {
        final x = i * 7.0;
        canvas.drawLine(Offset(x - 3, -4), Offset(x + 1, 0), ch);
        canvas.drawLine(Offset(x + 1, 0), Offset(x - 3, 4), ch);
      }
      canvas.restore();
    }
  }

  void _jumps(Canvas canvas) {
    for (final j in track.jumps) {
      canvas.save();
      canvas.translate(j.pos.x, j.pos.y);
      canvas.rotate(j.angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: j.length, height: j.width);
      final shader = ui.Gradient.linear(Offset(-j.length / 2, 0), Offset(j.length / 2, 0), [const Color(0xFF6D5DFC), const Color(0xFFB9A9FF)]);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..shader = shader);
      final stripe = Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = 2;
      for (var x = -j.length / 2 + 4; x < j.length / 2; x += 6) {
        canvas.drawLine(Offset(x, -j.width / 2 + 2), Offset(x, j.width / 2 - 2), stripe);
      }
      canvas.drawRect(Rect.fromLTWH(j.length / 2 - 3, -j.width / 2, 3, j.width), Paint()..color = const Color(0xFF3F2FB8));
      canvas.restore();
    }
  }

  void _staticHazards(Canvas canvas) {
    for (final h in track.hazards) {
      switch (h.kind) {
        case HazardKind.oilSlick:
          canvas.drawOval(Rect.fromCenter(center: Offset(h.pos.x, h.pos.y), width: 24, height: 18), Paint()..color = const Color(0xCC2B2440));
          canvas.drawOval(Rect.fromCenter(center: Offset(h.pos.x - 3, h.pos.y - 3), width: 9, height: 5), Paint()..color = const Color(0x55FFFFFF));
        case HazardKind.pillar:
          canvas.drawCircle(Offset(h.pos.x + 2, h.pos.y + 3), 9, Paint()..color = const Color(0x44000000));
          canvas.drawCircle(Offset(h.pos.x, h.pos.y), 9, Paint()..color = c(theme.accent));
          canvas.drawCircle(
            Offset(h.pos.x, h.pos.y),
            9,
            Paint()
              ..color = const Color(0xFF2B2440)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          canvas.drawCircle(Offset(h.pos.x - 2.5, h.pos.y - 2.5), 2.6, Paint()..color = const Color(0x99FFFFFF));
        case HazardKind.roller:
          // Rail the roller slides along.
          final dir = V2.fromAngle(h.angle).perp();
          final a = Offset(h.pos.x - dir.x * h.range, h.pos.y - dir.y * h.range);
          final b = Offset(h.pos.x + dir.x * h.range, h.pos.y + dir.y * h.range);
          canvas.drawLine(
            a,
            b,
            Paint()
              ..color = const Color(0x552B2440)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
      }
    }
  }

  void dispose() => picture.dispose();
}

/// Small overhead outline of a track for selection cards and lobbies.
class TrackThumbPainter extends CustomPainter {
  TrackThumbPainter(this.track);
  final Track track;

  static final Map<String, Path> _paths = {};

  Path get _path => _paths.putIfAbsent(track.def.id, () {
    if (track.isArena) {
      final cps = track.def.controlPoints;
      final cx = cps.fold(0.0, (a, p) => a + p.x) / cps.length;
      final cy = cps.fold(0.0, (a, p) => a + p.y) / cps.length;
      final r = cps.fold(0.0, (a, p) => math.max(a, math.sqrt((p.x - cx) * (p.x - cx) + (p.y - cy) * (p.y - cy))));
      return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    }
    final path = Path();
    for (final (i, s) in track.samples.indexed) {
      i == 0 ? path.moveTo(s.pos.x, s.pos.y) : path.lineTo(s.pos.x, s.pos.y);
    }
    return path..close();
  });

  @override
  void paint(Canvas canvas, Size size) {
    final b = Rect.fromLTRB(track.boundsMin.x, track.boundsMin.y, track.boundsMax.x, track.boundsMax.y);
    final scale = math.min(size.width / b.width, size.height / b.height);
    canvas.translate((size.width - b.width * scale) / 2, (size.height - b.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-b.left, -b.top);
    final theme = track.def.theme;
    final w = track.isArena ? 10.0 : track.samples.first.width;
    for (final sc in track.def.shortcuts) {
      final p = Path();
      for (final (i, pt) in sc.polygon.indexed) {
        i == 0 ? p.moveTo(pt.x, pt.y) : p.lineTo(pt.x, pt.y);
      }
      canvas.drawPath(p..close(), Paint()..color = Color(theme.shortcut));
    }
    canvas.drawPath(
      _path,
      Paint()
        ..color = Color(theme.roadEdge)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w + 10
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      _path,
      Paint()
        ..color = Color(theme.road)
        ..style = track.isArena ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeJoin = StrokeJoin.round,
    );
    if (!track.isArena) {
      final s = track.samples.first;
      canvas.save();
      canvas.translate(s.pos.x, s.pos.y);
      canvas.rotate(s.tangent.angle);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: s.width + 4), Paint()..color = const Color(0xFFFFFFFF));
      canvas.restore();
    }
    for (final pad in track.boostPads) {
      canvas.drawCircle(Offset(pad.pos.x, pad.pos.y), 6, Paint()..color = Color(theme.accent));
    }
  }

  @override
  bool shouldRepaint(TrackThumbPainter old) => old.track != track;
}
