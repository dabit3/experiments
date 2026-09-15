import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter/painting.dart' as painting;
import 'package:lastfort_core/lastfort_core.dart';

import 'controls.dart';
import 'match_client.dart';

/// Top-down 2.5D renderer + fixed-step input loop for a [MatchClient].
///
/// All art is procedural (paths, gradients, shadows) so the four platforms
/// draw the identical scene from the identical replica state.
class LastfortGame extends FlameGame {
  LastfortGame({
    required this.client,
    required this.controls,
    required this.onInput,
    this.reducedMotion = false,
    this.compact = false,
  });

  final MatchClient client;
  final Controls controls;
  final void Function(Map<String, Object?> msg) onInput;
  final bool reducedMotion;
  final bool compact;

  double camX = 500, camY = 500;
  double scale = 10;
  double _tickAcc = 0;
  double time = 0;
  bool _camInit = false;

  final Map<int, ui.Picture> _chunks = {};
  static const _chunkTiles = 25;

  World get lfWorld => client.sim.world;
  Rules get rules => client.rules;

  // --------------------------------------------------------------- helpers

  ({double x, double y}) screenToWorld(Offset s) => (
    x: (s.dx - size.x / 2) / scale + camX,
    y: (s.dy - size.y / 2) / scale + camY,
  );

  Offset worldToScreen(double wx, double wy) => Offset(
    (wx - camX) * scale + size.x / 2,
    (wy - camY) * scale + size.y / 2,
  );

  @override
  Color backgroundColor() => const Color(0xFF0E2A40);

  double get _visibleUnits {
    final base = compact ? 46.0 : 60.0;
    final target = client.viewTarget;
    final alt = target == null || target.state != PlayerState.dropping
        ? 0.0
        : target.altitude;
    return base * (1 + alt * 0.9);
  }

  // ---------------------------------------------------------------- update

  @override
  void update(double dt) {
    super.update(dt);
    final d = dt.clamp(0.0, 0.1);
    time += d;
    client.advance(d);

    final me = client.me;
    if (me != null) controls.currentMaterial = me.buildMaterial;

    // Camera.
    final target = client.viewTarget;
    double tx = camX, ty = camY;
    if (client.sim.phase == MatchPhase.bus &&
        (target == null || target.state == PlayerState.inBus)) {
      final bp = _busPosition();
      tx = bp.x;
      ty = bp.y;
    } else if (target != null) {
      final v = client.viewOf(target);
      tx = v.x;
      ty = v.y;
      if (controls.usesPointer && target.id == client.localId && target.alive) {
        // Lead the camera a little toward the aim.
        tx += math.cos(target.aim) * 2.5;
        ty += math.sin(target.aim) * 2.5;
      }
    }
    if (!_camInit) {
      camX = tx;
      camY = ty;
      _camInit = true;
    } else {
      final k = 1 - math.exp(-d * 9);
      camX += (tx - camX) * k;
      camY += (ty - camY) * k;
    }
    final targetScale = math.min(size.x, size.y) / _visibleUnits;
    scale += (targetScale - scale) * (1 - math.exp(-d * 5));

    // Aim.
    if (me != null) {
      final p = controls.pointer;
      controls.updateAim(
        px: me.x,
        py: me.y,
        pointerWorld: p == null ? null : screenToWorld(p),
      );
    }

    // Fixed-step input.
    _tickAcc += d;
    final step = client.sim.dt;
    while (_tickAcc >= step) {
      _tickAcc -= step;
      _sendTick();
    }
  }

  void _sendTick() {
    final mv = controls.move;
    final msg = client.buildInput(
      moveX: mv.x,
      moveY: mv.y,
      aim: controls.aim,
      fire: controls.fire,
      sprint: controls.sprint,
      actions: controls.drainActions(),
    );
    if (msg != null) onInput(msg);
  }

  ({double x, double y}) _busPosition() {
    final s = client.sim;
    final t = s.replicatedBusProgress;
    return (
      x: s.busX0 + (s.busX1 - s.busX0) * t,
      y: s.busY0 + (s.busY1 - s.busY0) * t,
    );
  }

  // ---------------------------------------------------------------- render

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sim = client.sim;
    final shake = reducedMotion ? 0.0 : client.shake;
    final shx = shake > 0 ? math.sin(time * 71) * shake * 6 : 0.0;
    final shy = shake > 0 ? math.cos(time * 67) * shake * 6 : 0.0;

    canvas.save();
    canvas.translate(size.x / 2 + shx, size.y / 2 + shy);
    canvas.scale(scale);
    canvas.translate(-camX, -camY);

    final halfW = size.x / 2 / scale + 4;
    final halfH = size.y / 2 / scale + 4;
    final view = Rect.fromLTRB(
      camX - halfW,
      camY - halfH,
      camX + halfW,
      camY + halfH,
    );

    _drawTerrain(canvas, view);
    _drawGroundStructures(canvas, view);
    _drawChests(canvas, view);
    _drawLoot(canvas, view);
    _drawNodeShadows(canvas, view);
    _drawPlayers(canvas, view, shadowsOnly: true);
    _drawWalls(canvas, view);
    _drawNodes(canvas, view);
    _drawPlayers(canvas, view, shadowsOnly: false);
    _drawBuildPreview(canvas);
    _drawVfx(canvas);
    _drawStorm(canvas, view);
    if (sim.phase == MatchPhase.bus) _drawBus(canvas);
    canvas.restore();

    _drawLabels(canvas, view);
    _drawReticle(canvas);
    _drawScreenFlashes(canvas);
  }

  // ----------------------------------------------------------------- terrain

  static const _terrainColors = <Terrain, Color>{
    Terrain.water: Color(0xFF117FA3),
    Terrain.sand: Color(0xFFF0D595),
    Terrain.grass: Color(0xFF81B957),
    Terrain.meadow: Color(0xFFACCD67),
    Terrain.dirt: Color(0xFFC0A474),
    Terrain.road: Color(0xFF566D79),
    Terrain.rock: Color(0xFF8AABAF),
  };

  int _hash(int x, int y) {
    var h = x * 374761393 + y * 668265263 + lfWorld.seed * 31;
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  ui.Picture _chunk(int cx, int cy) {
    final key = cy * 1000 + cx;
    final cached = _chunks[key];
    if (cached != null) return cached;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final ts = rules.tileSize;
    final paint = Paint();
    for (var gy = cy * _chunkTiles; gy < (cy + 1) * _chunkTiles; gy++) {
      for (var gx = cx * _chunkTiles; gx < (cx + 1) * _chunkTiles; gx++) {
        if (!lfWorld.inBounds(gx, gy)) continue;
        final t = lfWorld.terrainAt(gx, gy);
        final base = _terrainColors[t]!;
        paint.color = base;
        c.drawRect(
          Rect.fromLTWH(gx * ts, gy * ts, ts + 0.02, ts + 0.02),
          paint,
        );
        if (t == Terrain.water) {
          // Shoreline foam where water touches land.
          var land = false;
          for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            if (lfWorld.inBounds(gx + d.$1, gy + d.$2) &&
                lfWorld.isLand(gx + d.$1, gy + d.$2)) {
              land = true;
              break;
            }
          }
          if (land) {
            paint.color = const Color(0xFF62DBCF).withValues(alpha: 0.6);
            c.drawRect(
              Rect.fromLTWH(gx * ts, gy * ts, ts + 0.02, ts + 0.02),
              paint,
            );
            c.drawArc(
              Rect.fromLTWH(gx * ts + 0.3, gy * ts + 0.3, ts - 0.6, ts - 0.6),
              0.2,
              1.6,
              false,
              Paint()
                ..color = const Color(0xFFBFF5DA)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.12,
            );
          }
        } else if (t == Terrain.grass || t == Terrain.meadow) {
          final h = _hash(gx * 7, gy * 3);
          final ox = gx * ts + 0.5 + (h % 17) / 17 * (ts - 1);
          final oy = gy * ts + 0.5 + ((h >> 5) % 13) / 13 * (ts - 1);
          c.drawOval(
            Rect.fromCenter(
              center: Offset(ox, oy),
              width: ts * 0.65,
              height: ts * 0.38,
            ),
            Paint()..color = _shade(base, h.isEven ? 0.018 : -0.018),
          );
          if (h % 3 == 0) {
            final tuft = Path()
              ..moveTo(ox - 0.3, oy)
              ..lineTo(ox - 0.4, oy - 0.5)
              ..lineTo(ox, oy - 0.15)
              ..lineTo(ox + 0.12, oy - 0.65)
              ..lineTo(ox + 0.27, oy)
              ..close();
            c.drawPath(tuft, Paint()..color = _shade(base, -0.09));
          }
          if (h % 19 == 0) {
            for (var f = 0; f < 3; f++) {
              c.drawCircle(
                Offset(ox + f * 0.3, oy + (f % 2) * 0.25),
                0.10,
                Paint()
                  ..color = h.isEven
                      ? const Color(0xFFFFF0A6)
                      : const Color(0xFFDAD1FA),
              );
            }
          }
        } else if (t == Terrain.road) {
          final h = _hash(gx * 11, gy * 5);
          if (h % 3 == 0) {
            paint.color = _shade(base, 0.08);
            c.drawRect(
              Rect.fromLTWH(gx * ts + 0.4, gy * ts + 0.4, ts - 0.8, ts - 0.8),
              paint,
            );
          }
        }
        if (t != Terrain.road) {
          for (final d in const [(1, 1), (1, -1), (-1, 1), (-1, -1)]) {
            final horizontal = lfWorld.terrainAt(gx + d.$1, gy);
            final vertical = lfWorld.terrainAt(gx, gy + d.$2);
            if (horizontal == t ||
                horizontal != vertical ||
                horizontal == Terrain.road)
              continue;
            final cornerX = (gx + (d.$1 > 0 ? 1 : 0)) * ts;
            final cornerY = (gy + (d.$2 > 0 ? 1 : 0)) * ts;
            final radius = ts * 0.45;
            final corner = Path()
              ..moveTo(cornerX, cornerY)
              ..lineTo(cornerX - d.$1 * radius, cornerY)
              ..quadraticBezierTo(
                cornerX,
                cornerY,
                cornerX,
                cornerY - d.$2 * radius,
              )
              ..close();
            c.drawPath(corner, Paint()..color = _terrainColors[horizontal]!);
          }
        }
      }
    }
    final pic = rec.endRecording();
    _chunks[key] = pic;
    return pic;
  }

  Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  void _drawTerrain(Canvas c, Rect view) {
    final chunkSize = _chunkTiles * rules.tileSize;
    final maxChunk = (lfWorld.n / _chunkTiles).ceil();
    final x0 = (view.left / chunkSize).floor().clamp(0, maxChunk - 1);
    final x1 = (view.right / chunkSize).floor().clamp(0, maxChunk - 1);
    final y0 = (view.top / chunkSize).floor().clamp(0, maxChunk - 1);
    final y1 = (view.bottom / chunkSize).floor().clamp(0, maxChunk - 1);
    for (var cy = y0; cy <= y1; cy++) {
      for (var cx = x0; cx <= x1; cx++) {
        c.drawPicture(_chunk(cx, cy));
      }
    }
    // Water ripples (animated, subtle) around the island.
    if (!reducedMotion) {
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35;
      final cxp = lfWorld.centerX, cyp = lfWorld.centerY;
      for (var i = 0; i < 3; i++) {
        final r =
            rules.islandRadius + 8 + i * 10 + math.sin(time * 0.8 + i) * 2;
        c.drawCircle(Offset(cxp, cyp), r, p);
      }
    }
  }

  // --------------------------------------------------------------- structures

  Iterable<Structure> _visibleStructures(Rect view) sync* {
    final gx0 = lfWorld.toTile(view.left).clamp(0, lfWorld.n - 1);
    final gx1 = lfWorld.toTile(view.right).clamp(0, lfWorld.n - 1);
    final gy0 = lfWorld.toTile(view.top).clamp(0, lfWorld.n - 1);
    final gy1 = lfWorld.toTile(view.bottom).clamp(0, lfWorld.n - 1);
    final structs = client.sim.structures;
    for (var gy = gy0; gy <= gy1; gy++) {
      for (var gx = gx0; gx <= gx1; gx++) {
        final s = structs[lfWorld.tileKey(gx, gy)];
        if (s != null && s.hp > 0 && !client.hiddenStructureIds.contains(s.id))
          yield s;
      }
    }
  }

  static const _matColors = <Material, Color>{
    Material.wood: Color(0xFFB3773B),
    Material.stone: Color(0xFF8E939B),
    Material.metal: Color(0xFF5F7FA6),
  };

  Color _structColor(Structure s) {
    final base = s.team == -1
        ? const Color(0xFFCDD5CD)
        : _matColors[s.material]!;
    final build = s.maxHp == 0 ? 1.0 : (s.hp / s.maxHp).clamp(0.0, 1.0);
    return Color.lerp(base.withValues(alpha: 0.45), base, build)!;
  }

  void _drawGroundStructures(Canvas c, Rect view) {
    final ts = rules.tileSize;
    final paint = Paint();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.12
      ..color = Colors.black.withValues(alpha: 0.25);
    for (final s in _visibleStructures(view)) {
      if (s.piece == Piece.wall) continue;
      final r = Rect.fromLTWH(s.gx * ts, s.gy * ts, ts, ts);
      final col = _structColor(s);
      switch (s.piece) {
        case Piece.floor:
          paint.color = col;
          c.drawRect(r.deflate(0.05), paint);
          c.drawRect(r.deflate(0.05), line);
          // Plank seams.
          for (var i = 1; i < 3; i++) {
            c.drawLine(
              Offset(r.left, r.top + ts * i / 3),
              Offset(r.right, r.top + ts * i / 3),
              line,
            );
          }
        case Piece.ramp:
          final shader = ui.Gradient.linear(
            _rampFrom(r, s.direction),
            _rampTo(r, s.direction),
            [_shade(col, -0.18), _shade(col, 0.12)],
          );
          paint.shader = shader;
          c.drawRect(r.deflate(0.05), paint);
          paint.shader = null;
          c.drawRect(r.deflate(0.05), line);
          _drawArrow(
            c,
            r.center,
            s.direction,
            ts * 0.28,
            line..strokeWidth = 0.22,
          );
          line.strokeWidth = 0.12;
        case Piece.roof:
          paint.color = _shade(col, -0.05);
          final path = Path()
            ..moveTo(r.left, r.bottom)
            ..lineTo(r.center.dx, r.top)
            ..lineTo(r.right, r.bottom)
            ..close();
          c.drawRect(r.deflate(0.05), paint);
          paint.color = _shade(col, 0.15);
          c.drawPath(path, paint);
          c.drawRect(r.deflate(0.05), line);
        case Piece.wall:
          break;
      }
      if (s.team != -1 && s.hp < s.maxHp) _drawStructHp(c, r, s);
    }
  }

  Offset _rampFrom(Rect r, int dir) => switch (dir) {
    0 => r.centerLeft,
    1 => r.topCenter,
    2 => r.centerRight,
    _ => r.bottomCenter,
  };
  Offset _rampTo(Rect r, int dir) => switch (dir) {
    0 => r.centerRight,
    1 => r.bottomCenter,
    2 => r.centerLeft,
    _ => r.topCenter,
  };

  void _drawArrow(Canvas c, Offset center, int dir, double len, Paint p) {
    final a = dir * math.pi / 2;
    final tip = center + Offset(math.cos(a), math.sin(a)) * len;
    final tail = center - Offset(math.cos(a), math.sin(a)) * len;
    c.drawLine(tail, tip, p);
    final l = tip + Offset(math.cos(a + 2.5), math.sin(a + 2.5)) * len * 0.6;
    final r = tip + Offset(math.cos(a - 2.5), math.sin(a - 2.5)) * len * 0.6;
    c.drawLine(tip, l, p);
    c.drawLine(tip, r, p);
  }

  void _drawStructHp(Canvas c, Rect r, Structure s) {
    final frac = (s.hp / s.maxHp).clamp(0.0, 1.0);
    final bar = Rect.fromLTWH(r.left + 0.4, r.top + 0.25, r.width - 0.8, 0.35);
    c.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(0.15)),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left, bar.top, bar.width * frac, bar.height),
        const Radius.circular(0.15),
      ),
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFF4D5E),
          const Color(0xFF52D273),
          frac,
        )!,
    );
  }

  void _drawWalls(Canvas c, Rect view) {
    final ts = rules.tileSize;
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.14
      ..color = Colors.black.withValues(alpha: 0.35);
    for (final s in _visibleStructures(view)) {
      if (s.piece != Piece.wall) continue;
      final r = Rect.fromLTWH(s.gx * ts, s.gy * ts, ts, ts);
      final col = _structColor(s);
      // Drop shadow to the lower-right for height.
      c.drawRRect(
        RRect.fromRectAndRadius(
          r.shift(const Offset(0.35, 0.45)).deflate(0.1),
          const Radius.circular(0.3),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.28),
      );
      final body = RRect.fromRectAndRadius(
        r.deflate(0.1),
        const Radius.circular(0.3),
      );
      fill.shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [
        _shade(col, 0.06),
        _shade(col, -0.14),
      ]);
      c.drawRRect(body, fill);
      fill.shader = null;
      // Top face highlight.
      fill.color = _shade(col, 0.14);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left + 0.1,
            r.top + 0.1,
            r.width - 0.2,
            r.height * 0.64,
          ),
          const Radius.circular(0.3),
        ),
        fill,
      );
      c.drawRRect(body, edge);
      if (s.team == -1) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              r.left + ts * 0.2,
              r.bottom - ts * 0.25,
              ts * 0.6,
              ts * 0.12,
            ),
            const Radius.circular(0.08),
          ),
          Paint()..color = const Color(0xFF225573),
        );
        c.drawLine(
          Offset(r.left + ts * 0.2, r.bottom - ts * 0.24),
          Offset(r.right - ts * 0.2, r.bottom - ts * 0.24),
          Paint()
            ..color = const Color(0xFF83E5DB)
            ..strokeWidth = 0.08,
        );
      }
      switch (s.edit) {
        case PieceEdit.door:
          fill.color = _shade(col, -0.32);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: r.center,
                width: ts * 0.42,
                height: ts * 0.7,
              ),
              const Radius.circular(0.2),
            ),
            fill,
          );
        case PieceEdit.window:
          fill.color = const Color(0xFF9FD8F5).withValues(alpha: 0.85);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: r.center,
                width: ts * 0.5,
                height: ts * 0.34,
              ),
              const Radius.circular(0.15),
            ),
            fill,
          );
        case PieceEdit.none:
          if (s.team == -1) {
            // Brick seams for prebuilt buildings.
            edge.strokeWidth = 0.08;
            c.drawLine(
              Offset(r.left + 0.3, r.center.dy),
              Offset(r.right - 0.3, r.center.dy),
              edge,
            );
            edge.strokeWidth = 0.14;
          }
      }
      if (s.team != -1 && s.hp < s.maxHp) _drawStructHp(c, r, s);
    }
  }

  // ---------------------------------------------------------------- objects

  void _drawChests(Canvas c, Rect view) {
    for (final ch in lfWorld.chests) {
      if (!view.contains(Offset(ch.x, ch.y))) continue;
      final r = Rect.fromCenter(
        center: Offset(ch.x, ch.y),
        width: 1.9,
        height: 1.4,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          r.shift(const Offset(0.15, 0.25)),
          const Radius.circular(0.3),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );
      final base = ch.opened
          ? const Color(0xFF7A5A3A)
          : const Color(0xFFC98A2E);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(0.3)),
        Paint()..color = base,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.42),
          const Radius.circular(0.3),
        ),
        Paint()..color = _shade(base, ch.opened ? -0.1 : 0.14),
      );
      c.drawRect(
        Rect.fromCenter(center: r.center, width: 0.5, height: r.height),
        Paint()
          ..color = ch.opened
              ? const Color(0xFF5A4028)
              : const Color(0xFFFFD98A),
      );
      if (!ch.opened && !reducedMotion) {
        final glow = 0.25 + 0.15 * math.sin(time * 3 + ch.id);
        c.drawCircle(
          Offset(ch.x, ch.y),
          1.8,
          Paint()
            ..color = const Color(0xFFFFC857).withValues(alpha: glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
        );
      }
    }
  }

  void _drawLoot(Canvas c, Rect view) {
    for (final d in client.sim.drops.values) {
      if (!view.contains(Offset(d.x, d.y))) continue;
      final col = Color(d.item.rarity.argb);
      final bob = reducedMotion ? 0.0 : math.sin(time * 4 + d.id) * 0.12;
      final center = Offset(d.x, d.y + bob);
      c.drawCircle(
        Offset(d.x, d.y + 0.35),
        0.55,
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );
      c.drawCircle(
        center,
        1.1,
        Paint()
          ..color = col.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
      );
      final p = Paint()..color = col;
      switch (d.item.type) {
        case ItemType.weapon:
          c.save();
          c.translate(center.dx, center.dy);
          c.rotate(-0.6);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 1.6, height: 0.45),
              const Radius.circular(0.15),
            ),
            p,
          );
          c.drawRect(Rect.fromLTWH(-0.2, 0.1, 0.4, 0.5), p);
          c.restore();
        case ItemType.consumable:
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: 0.8, height: 1.1),
              const Radius.circular(0.25),
            ),
            p,
          );
          c.drawRect(
            Rect.fromCenter(
              center: center.translate(0, -0.55),
              width: 0.45,
              height: 0.2,
            ),
            Paint()..color = Colors.white70,
          );
        case ItemType.ammo:
          for (var i = -1; i <= 1; i++) {
            c.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: center.translate(i * 0.32, 0),
                  width: 0.24,
                  height: 0.8,
                ),
                const Radius.circular(0.1),
              ),
              p,
            );
          }
        case ItemType.material:
          final path = Path()
            ..moveTo(center.dx, center.dy - 0.6)
            ..lineTo(center.dx + 0.6, center.dy)
            ..lineTo(center.dx, center.dy + 0.6)
            ..lineTo(center.dx - 0.6, center.dy)
            ..close();
          c.drawPath(
            path,
            Paint()..color = _matColors[d.item.material ?? Material.wood]!,
          );
      }
    }
  }

  Iterable<ResourceNode> _visibleNodes(Rect view) sync* {
    final gx0 = lfWorld.toTile(view.left).clamp(0, lfWorld.n - 1);
    final gx1 = lfWorld.toTile(view.right).clamp(0, lfWorld.n - 1);
    final gy0 = lfWorld.toTile(view.top).clamp(0, lfWorld.n - 1);
    final gy1 = lfWorld.toTile(view.bottom).clamp(0, lfWorld.n - 1);
    for (var gy = gy0; gy <= gy1; gy++) {
      for (var gx = gx0; gx <= gx1; gx++) {
        final list = lfWorld.nodesByTile[lfWorld.tileKey(gx, gy)];
        if (list == null) continue;
        for (final n in list) {
          if (n.alive) yield n;
        }
      }
    }
  }

  void _drawNodeShadows(Canvas c, Rect view) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.28);
    for (final n in _visibleNodes(view)) {
      final r = n.kind.radius;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(n.x + r * 0.35, n.y + r * 0.45),
          width: r * 2.1,
          height: r * 1.5,
        ),
        p,
      );
    }
  }

  void _drawNodes(Canvas c, Rect view) {
    final paint = Paint();
    for (final n in _visibleNodes(view)) {
      final frac = (n.hp / n.kind.hp).clamp(0.0, 1.0);
      final r = n.kind.radius * (0.7 + 0.3 * frac);
      final center = Offset(n.x, n.y);
      switch (n.kind) {
        case ResourceKind.tree:
          final sway = reducedMotion ? 0.0 : math.sin(time * 1.3 + n.id) * 0.08;
          paint.color = const Color(0xFF816040);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: center.translate(0, r * 0.1),
                width: r * 0.4,
                height: r * 1.3,
              ),
              const Radius.circular(0.2),
            ),
            paint,
          );
          final canopy = center.translate(sway, -r * 0.4);
          final g = [
            const Color(0xFF579C45),
            const Color(0xFF3C9266),
            const Color(0xFF92B749),
          ][n.variant % 3];
          c.drawCircle(
            canopy.translate(0.1, r * 0.18),
            r,
            Paint()..color = _shade(g, -0.15),
          );
          for (var crown = 0; crown < 4; crown++) {
            final a = crown * 2.4 + n.variant;
            final pos = canopy + Offset(math.cos(a), math.sin(a)) * r * 0.35;
            c.drawCircle(
              pos,
              r * 0.7,
              Paint()
                ..shader = ui.Gradient.radial(
                  pos.translate(-r * 0.2, -r * 0.25),
                  r,
                  [_shade(g, 0.18), g, _shade(g, -0.10)],
                  [0, 0.6, 1],
                ),
            );
            c.drawArc(
              Rect.fromCircle(center: pos, radius: r * 0.52),
              3.6,
              1.1,
              false,
              Paint()
                ..color = _shade(g, 0.25).withValues(alpha: 0.6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.06,
            );
          }
        case ResourceKind.rock:
          final g = const Color(0xFF8A9199);
          final path = Path();
          for (var i = 0; i < 7; i++) {
            final a = i / 7 * math.pi * 2 + n.variant;
            final rr = r * (0.75 + ((_hash(n.id, i) % 100) / 100) * 0.35);
            final pt = center + Offset(math.cos(a), math.sin(a)) * rr;
            if (i == 0) {
              path.moveTo(pt.dx, pt.dy);
            } else {
              path.lineTo(pt.dx, pt.dy);
            }
          }
          path.close();
          paint.shader = ui.Gradient.linear(
            center.translate(-r, -r),
            center.translate(r, r),
            [const Color(0xFFCCDDE0), g, const Color(0xFF527380)],
            [0, 0.5, 1],
          );
          c.drawPath(path, paint);
          paint.shader = null;
          c.drawPath(
            path,
            Paint()
              ..color = const Color(0xFF476570)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.08,
          );
          c.drawLine(
            center.translate(-r * 0.45, -r * 0.5),
            center.translate(r * 0.4, -r * 0.3),
            Paint()
              ..color = const Color(0xFFEBF2D9)
              ..strokeWidth = 0.1,
          );
        case ResourceKind.car:
          final col = [
            const Color(0xFFC94C4C),
            const Color(0xFF4C7FC9),
            const Color(0xFFD9A441),
          ][n.variant % 3];
          c.save();
          c.translate(center.dx, center.dy);
          c.rotate(n.variant * 0.8);
          paint.color = col;
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: r * 2.4,
                height: r * 1.3,
              ),
              const Radius.circular(0.4),
            ),
            paint,
          );
          paint.color = const Color(0xFF223344);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: const Offset(0.2, 0),
                width: r * 1.2,
                height: r * 1.0,
              ),
              const Radius.circular(0.3),
            ),
            paint,
          );
          c.restore();
      }
      if (frac < 1) {
        final bar = Rect.fromCenter(
          center: center.translate(0, -r - 0.6),
          width: 2.2,
          height: 0.3,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(bar, const Radius.circular(0.15)),
          Paint()..color = Colors.black45,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bar.left, bar.top, bar.width * frac, bar.height),
            const Radius.circular(0.15),
          ),
          Paint()..color = _matColors[n.kind.material]!,
        );
      }
    }
  }

  // ---------------------------------------------------------------- players

  void _drawPlayers(Canvas c, Rect view, {required bool shadowsOnly}) {
    final sim = client.sim;
    final me = client.me;
    for (final p in sim.players.values) {
      if (p.state == PlayerState.inBus || p.eliminated) continue;
      if (!client.isVisible(p)) continue;
      final v = client.viewOf(p);
      if (!view.inflate(4).contains(Offset(v.x, v.y))) continue;
      final alt = p.state == PlayerState.dropping ? p.altitude : 0.0;
      if (shadowsOnly) {
        final sh = 0.9 - alt * 0.5;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(v.x + alt * 2.5, v.y + 0.35 + alt * 3.5),
            width: sh * 2,
            height: sh * 1.3,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.32 - alt * 0.2),
        );
        continue;
      }
      _drawPlayer(
        c,
        p,
        v.x,
        v.y - alt * 3.0,
        v.aim,
        alt,
        isLocal: p.id == client.localId,
        isMate: me != null && p.team == me.team,
      );
    }
  }

  void _drawPlayer(
    Canvas c,
    Player p,
    double x,
    double y,
    double aim,
    double alt, {
    required bool isLocal,
    required bool isMate,
  }) {
    final outfit = cosmeticById(p.loadout.outfit);
    final primary = Color(outfit.primary);
    final secondary = Color(outfit.secondary);
    final accent = Color(outfit.accent);
    final r = 0.85 * (1 + alt * 0.35);
    c.save();
    c.translate(x, y);

    // Team ring / local ring.
    if (isLocal || isMate) {
      c.drawCircle(
        Offset.zero,
        r + 0.35,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.18
          ..color = (isLocal ? Colors.white : const Color(0xFF2FD3C6))
              .withValues(alpha: 0.9),
      );
    }
    if (p.inStorm && !reducedMotion) {
      c.drawCircle(
        Offset.zero,
        r + 0.7,
        Paint()
          ..color = const Color(0xFF7B5CFF)
              .withValues(alpha: 0.25 + 0.15 * math.sin(time * 8))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
      );
    }

    // Glider when dropping.
    if (alt > 0.02) {
      final glider = cosmeticById(p.loadout.glider);
      final gw = 3.2 * (1 + alt * 0.3);
      final path = Path()
        ..moveTo(-gw / 2, -0.4)
        ..quadraticBezierTo(0, -2.6, gw / 2, -0.4)
        ..quadraticBezierTo(0, -1.0, -gw / 2, -0.4)
        ..close();
      c.drawPath(path, Paint()..color = Color(glider.primary));
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.12
          ..color = Color(glider.accent),
      );
      c.drawLine(
        const Offset(-0.5, -0.5),
        Offset(-gw / 2 + 0.3, -0.5),
        Paint()
          ..color = Colors.white54
          ..strokeWidth = 0.08,
      );
      c.drawLine(
        const Offset(0.5, -0.5),
        Offset(gw / 2 - 0.3, -0.5),
        Paint()
          ..color = Colors.white54
          ..strokeWidth = 0.08,
      );
    }

    // Held tool toward aim.
    if (p.alive) {
      c.save();
      c.rotate(aim);
      final swing = p.fireHeld && !p.buildMode
          ? math.sin(time * 18) * 0.25
          : 0.0;
      c.rotate(swing);
      final item = p.selectedSlot > 0 && p.selectedSlot < p.inventory.length
          ? p.inventory[p.selectedSlot]
          : null;
      if (p.buildMode) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r * 0.4, -0.22, 1.2, 0.44),
            const Radius.circular(0.1),
          ),
          Paint()..color = _matColors[p.buildMaterial]!,
        );
      } else if (item != null && item.isWeapon) {
        final wr = Color(item.rarity.argb);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r * 0.5, -0.2, 1.7, 0.4),
            const Radius.circular(0.12),
          ),
          Paint()..color = const Color(0xFF2B2F36),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r * 0.5 + 0.9, -0.14, 0.8, 0.28),
            const Radius.circular(0.1),
          ),
          Paint()..color = wr,
        );
      } else {
        final pick = cosmeticById(p.loadout.pickaxe);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r * 0.3, -0.12, 1.6, 0.24),
            const Radius.circular(0.1),
          ),
          Paint()..color = Color(pick.secondary),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r * 0.3 + 1.2, -0.5, 0.45, 1.0),
            const Radius.circular(0.12),
          ),
          Paint()..color = Color(pick.primary),
        );
      }
      c.restore();
    }

    c.save();
    c.rotate(aim);
    for (final side in [-1.0, 1.0]) {
      final shoulder = Rect.fromCenter(
        center: Offset(-r * 0.12, side * r * 0.68),
        width: r * 0.9,
        height: r * 0.65,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(shoulder, Radius.circular(r * 0.25)),
        Paint()
          ..shader = ui.Gradient.linear(
            shoulder.topLeft,
            shoulder.bottomRight,
            [_shade(primary, 0.20), primary, _shade(primary, -0.22)],
            [0, 0.5, 1],
          ),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-r * 0.3, 0),
          width: r * 1.15,
          height: r * 1.3,
        ),
        Radius.circular(r * 0.3),
      ),
      Paint()..color = secondary,
    );
    final helmet = Rect.fromCenter(
      center: Offset(r * 0.12, 0),
      width: r * 1.38,
      height: r * 1.25,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(helmet, Radius.circular(r * 0.48)),
      Paint()
        ..shader = ui.Gradient.linear(
          helmet.topLeft,
          helmet.bottomRight,
          [_shade(primary, 0.25), primary, _shade(primary, -0.16)],
          [0, 0.5, 1],
        ),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r * 0.45, -r * 0.43, r * 0.33, r * 0.86),
        Radius.circular(r * 0.14),
      ),
      Paint()..color = const Color(0xFF132A46),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r * 0.56, -r * 0.32, r * 0.12, r * 0.64),
        Radius.circular(r * 0.05),
      ),
      Paint()..color = accent,
    );
    c.drawLine(
      Offset(-r * 0.38, -r * 0.27),
      Offset(r * 0.18, -r * 0.38),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..strokeWidth = 0.08,
    );
    c.restore();

    // Emote sparkle.
    if (p.emoteRemaining > 0 && !reducedMotion) {
      for (var i = 0; i < 5; i++) {
        final a = time * 3 + i * 1.26;
        final pt = Offset(math.cos(a), math.sin(a)) * (r + 0.9);
        c.drawCircle(pt, 0.16, Paint()..color = accent);
      }
    }

    // Status bar above teammates (local player has the HUD).
    if (isMate && !isLocal && p.alive) {
      final w = 2.6;
      final top = -r - 1.0;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w / 2, top, w, 0.32),
          const Radius.circular(0.1),
        ),
        Paint()..color = Colors.black54,
      );
      final hp = p.health / p.maxHealth;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w / 2, top, w * hp, 0.32),
          const Radius.circular(0.1),
        ),
        Paint()..color = const Color(0xFF52D273),
      );
      if (p.shield > 0) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-w / 2, top - 0.36, w * (p.shield / 100), 0.26),
            const Radius.circular(0.1),
          ),
          Paint()..color = const Color(0xFF4DA3FF),
        );
      }
    }
    c.restore();
  }

  // ---------------------------------------------------------- build preview

  void _drawBuildPreview(Canvas c) {
    final me = client.me;
    if (me == null || !me.alive || !me.buildMode) return;
    final sim = client.sim;
    final t = sim.targetTile(me, null, null);
    final ok =
        sim.canPlaceAt(me, t.gx, t.gy) &&
        me.materials[me.buildMaterial.index] >= rules.pieceCost;
    final ts = rules.tileSize;
    final r = Rect.fromLTWH(t.gx * ts, t.gy * ts, ts, ts).deflate(0.15);
    final col = ok ? const Color(0xFF2FD3C6) : const Color(0xFFFF4D5E);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(0.3)),
      Paint()..color = col.withValues(alpha: 0.22),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(0.3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.18
        ..color = col.withValues(alpha: 0.95),
    );
    final label = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.14;
    switch (me.buildPiece) {
      case Piece.wall:
        c.drawRect(r.deflate(0.9), label);
      case Piece.floor:
        c.drawLine(
          r.topLeft + const Offset(0.8, 1.4),
          r.topRight + const Offset(-0.8, 1.4),
          label,
        );
        c.drawLine(
          r.bottomLeft + const Offset(0.8, -1.4),
          r.bottomRight + const Offset(-0.8, -1.4),
          label,
        );
      case Piece.ramp:
        final dir = ((me.aim + math.pi / 4) / (math.pi / 2)).floor() % 4;
        _drawArrow(c, r.center, (dir + 4) % 4, ts * 0.3, label);
      case Piece.roof:
        c.drawPath(
          Path()
            ..moveTo(r.left + 0.7, r.bottom - 0.9)
            ..lineTo(r.center.dx, r.top + 0.7)
            ..lineTo(r.right - 0.7, r.bottom - 0.9),
          label,
        );
    }
  }

  // -------------------------------------------------------------------- vfx

  void _drawVfx(Canvas c) {
    for (final v in client.vfx) {
      final t = v.t;
      switch (v.kind) {
        case 'tracer':
          final p = Paint()
            ..color = Color(v.color == 0 ? 0xFFFFE8A3 : v.color)
                .withValues(alpha: (1 - t) * 0.9)
            ..strokeWidth = 0.22
            ..strokeCap = StrokeCap.round;
          final a = Offset(v.x, v.y);
          final b = Offset(v.x2, v.y2);
          c.drawLine(
            Offset.lerp(a, b, t * 0.7)!,
            Offset.lerp(a, b, math.min(1, t + 0.3))!,
            p,
          );
        case 'impact':
          c.drawCircle(
            Offset(v.x, v.y),
            0.4 + t * 1.4,
            Paint()
              ..color = Color(v.color == 0 ? 0xFFFFFFFF : v.color)
                  .withValues(alpha: (1 - t) * 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.18,
          );
        case 'harvest':
          final col = Color(v.color == 0 ? 0xFFFFFFFF : v.color);
          for (var i = 0; i < 4; i++) {
            final a = i * 1.57 + v.x * 0.1 + t * 2;
            final d = 0.4 + t * 1.6;
            c.drawCircle(
              Offset(v.x + math.cos(a) * d, v.y + math.sin(a) * d - t * 1.5),
              0.22 * (1 - t),
              Paint()..color = col.withValues(alpha: 1 - t),
            );
          }
          _worldText(
            c,
            '+${v.value}',
            Offset(v.x, v.y - 1.2 - t * 2.2),
            col.withValues(alpha: 1 - t),
          );
        case 'damage':
          final col = Color(v.color == 0 ? 0xFFFFFFFF : v.color);
          _worldText(
            c,
            '${v.value}',
            Offset(v.x + 0.6, v.y - 1.4 - t * 2.4),
            col.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
            bold: true,
          );
        case 'elim':
          c.drawCircle(
            Offset(v.x, v.y),
            1 + t * 4,
            Paint()
              ..color = Color(v.color).withValues(alpha: (1 - t) * 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.3 * (1 - t) + 0.05,
          );
        case 'build':
          c.drawRect(
            Rect.fromCenter(
              center: Offset(v.x, v.y),
              width: rules.tileSize * (1 + t * 0.3),
              height: rules.tileSize * (1 + t * 0.3),
            ),
            Paint()
              ..color = Color(v.color).withValues(alpha: (1 - t) * 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.2,
          );
        default:
          break;
      }
    }
  }

  // ------------------------------------------------------------------ storm

  void _drawStorm(Canvas c, Rect view) {
    final storm = client.sim.storm;
    final big = view.inflate(200);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(big)
      ..addOval(
        Rect.fromCircle(
          center: Offset(storm.cx, storm.cy),
          radius: storm.radius,
        ),
      );
    final pulse = reducedMotion ? 0.0 : math.sin(time * 2) * 0.04;
    c.drawPath(
      path,
      Paint()..color = const Color(0xFF3B2A7A).withValues(alpha: 0.58 + pulse),
    );
    // Glowing edge.
    c.drawCircle(
      Offset(storm.cx, storm.cy),
      storm.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFB08CFF).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    c.drawCircle(
      Offset(storm.cx, storm.cy),
      storm.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = const Color(0xFFD7C6FF).withValues(alpha: 0.9),
    );
    // Next circle.
    if (storm.targetRadius < storm.radius - 0.5) {
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3
        ..color = Colors.white.withValues(alpha: 0.75);
      final circ = 2 * math.pi * storm.targetRadius;
      final segs = math.max(24, (circ / 6).round());
      for (var i = 0; i < segs; i += 2) {
        final a0 = i / segs * math.pi * 2;
        final a1 = (i + 1) / segs * math.pi * 2;
        c.drawArc(
          Rect.fromCircle(
            center: Offset(storm.targetX, storm.targetY),
            radius: storm.targetRadius,
          ),
          a0,
          a1 - a0,
          false,
          dash,
        );
      }
    }
  }

  // -------------------------------------------------------------------- bus

  void _drawBus(Canvas c) {
    final sim = client.sim;
    final bp = _busPosition();
    final ang = math.atan2(sim.busY1 - sim.busY0, sim.busX1 - sim.busX0);
    // Path line.
    c.drawLine(
      Offset(sim.busX0, sim.busY0),
      Offset(sim.busX1, sim.busY1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 0.4,
    );
    // Shadow far below.
    c.drawOval(
      Rect.fromCenter(center: Offset(bp.x + 6, bp.y + 9), width: 9, height: 5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    c.save();
    c.translate(bp.x, bp.y);
    c.rotate(ang);
    final bob = reducedMotion ? 0.0 : math.sin(time * 2) * 0.3;
    c.translate(0, bob);
    // Balloon.
    c.drawCircle(
      const Offset(0, -6.5),
      4.2,
      Paint()..color = const Color(0xFFFF7A2F),
    );
    c.drawCircle(
      const Offset(-1.2, -7.6),
      1.4,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    c.drawLine(
      const Offset(-2.5, -3.2),
      const Offset(-3, 0),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 0.15,
    );
    c.drawLine(
      const Offset(2.5, -3.2),
      const Offset(3, 0),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 0.15,
    );
    // Cabin.
    final cabin = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 3.4),
      const Radius.circular(0.8),
    );
    c.drawRRect(cabin, Paint()..color = const Color(0xFF2FD3C6));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -0.4), width: 7, height: 1.2),
        const Radius.circular(0.3),
      ),
      Paint()..color = const Color(0xFF0E2A40),
    );
    c.drawRRect(
      cabin,
      Paint()
        ..color = Colors.black45
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.15,
    );
    c.restore();
  }

  // ------------------------------------------------------------ screen space

  void _drawLabels(Canvas c, Rect view) {
    final me = client.me;
    // POI names.
    for (final poi in lfWorld.pois) {
      if (!view.contains(Offset(poi.x, poi.y))) continue;
      _text(
        c,
        poi.name.toUpperCase(),
        worldToScreen(poi.x, poi.y - poi.radius * 0.6),
        size: compact ? 12 : 14,
        color: Colors.white.withValues(alpha: 0.75),
        letterSpacing: 2,
        weight: FontWeight.w700,
      );
    }
    // Player names.
    for (final p in client.sim.players.values) {
      if (p.id == client.localId ||
          p.state == PlayerState.inBus ||
          p.eliminated)
        continue;
      if (!client.isVisible(p)) continue;
      final mate = me != null && p.team == me.team;
      final v = client.viewOf(p);
      if (!view.contains(Offset(v.x, v.y))) continue;
      final alt = p.state == PlayerState.dropping ? p.altitude : 0.0;
      final s = worldToScreen(v.x, v.y - alt * 3.0 - (mate ? 2.4 : 1.6));
      _text(
        c,
        p.name,
        s,
        size: compact ? 11 : 12,
        color: mate
            ? const Color(0xFF9FF3EC)
            : Colors.white.withValues(alpha: 0.9),
        weight: FontWeight.w600,
        shadow: true,
      );
    }
    // Spectating banner target name is drawn by the HUD.
  }

  void _drawReticle(Canvas c) {
    final me = client.me;
    if (me == null || !me.alive || !controls.usesPointer) return;
    final p = controls.pointer;
    if (p == null) return;
    final col = me.buildMode ? const Color(0xFF2FD3C6) : Colors.white;
    final paint = Paint()
      ..color = col.withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final gap = me.fireHeld ? 9.0 : 6.0;
    for (final d in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      c.drawLine(p + d * gap, p + d * (gap + 6), paint);
    }
    c.drawCircle(p, 1.5, Paint()..color = col);
  }

  void _drawScreenFlashes(Canvas c) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    c.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          rect.longestSide * 0.65,
          [Colors.transparent, const Color(0x33112845)],
          [0.5, 1],
        ),
    );
    if (client.damageFlash > 0) {
      c.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(rect.center, rect.longestSide * 0.75, [
            Colors.transparent,
            const Color(0xFFFF4D5E)
                .withValues(alpha: 0.45 * client.damageFlash),
          ]),
      );
    }
    final me = client.me;
    if (me != null && me.inStorm) {
      final pulse = reducedMotion ? 0.3 : 0.25 + 0.1 * math.sin(time * 6);
      c.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(rect.center, rect.longestSide * 0.8, [
            Colors.transparent,
            const Color(0xFF7B5CFF).withValues(alpha: pulse),
          ]),
      );
    }
    if (client.hitFlash > 0) {
      c.drawCircle(
        rect.center,
        6 + (1 - client.hitFlash) * 10,
        Paint()
          ..color = Colors.white.withValues(alpha: client.hitFlash * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Text drawn while the world transform is active: scaled so it keeps a
  /// constant on-screen size.
  void _worldText(
    Canvas c,
    String s,
    Offset at,
    Color color, {
    bool bold = false,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(1 / scale);
    _text(
      c,
      s,
      Offset.zero,
      size: bold ? 16 : 13,
      color: color,
      weight: bold ? FontWeight.w800 : FontWeight.w700,
    );
    c.restore();
  }

  void _text(
    Canvas c,
    String s,
    Offset at, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0,
    bool shadow = true,
  }) {
    final tp = painting.TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          color: color,
          shadows: shadow
              ? const [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }
}
