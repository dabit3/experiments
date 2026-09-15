import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors, RadialGradient;
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../net/client.dart';
import '../theme/tokens.dart';
import 'particles.dart';
import 'sprites.dart';

/// Flame game that renders the authoritative [GameState] held by [GameClient].
///
/// All art is drawn procedurally with vectors so the four clients render the
/// exact same scene at any DPI. Positions are interpolated between the last
/// two snapshots; one-shot events become particles/floating text.
class KitchenGame extends FlameGame {
  KitchenGame(this.client, {required this.isDark});

  final GameClient client;
  bool isDark;

  final Particles particles = Particles();
  double t = 0;

  /// Local prediction: chef id -> predicted held item shown until the server
  /// confirms (lag compensation for pickup/drop).
  String? predictedChef;
  Item? predictedHeld;
  bool predictedEmpty = false;
  double predictionTtl = 0;

  double cell = 48;
  Offset origin = Offset.zero;

  /// Static backdrop (brick frame, floor tiles, pit water) rasterised once per
  /// layout/theme so each frame draws it as a single texture instead of
  /// ~1.5k primitives.
  Image? _backdrop;
  String _backdropKey = '';

  @override
  void onRemove() {
    _backdrop?.dispose();
    _backdrop = null;
    super.onRemove();
  }

  Image _backdropFor(GameState g, Size size, double dpr) {
    final key = '${g.level.id}|$cell|${origin.dx},${origin.dy}|${size.width}x${size.height}|$dpr|$isDark';
    final cached = _backdrop;
    if (cached != null && key == _backdropKey) return cached;
    cached?.dispose();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    final arena = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(arena, const Radius.circular(22)),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF376D66), Color(0xFF102F35)],
          radius: 0.8,
        ).createShader(arena),
    );
    final dot = Paint()..color = const Color(0x184FAF9D);
    for (var y = 12.0; y < size.height; y += 22) {
      for (var x = 12.0; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1.3, dot);
      }
    }
    final sp = Sprites(canvas, cell, 0, isDark: isDark);
    sp.frame(Rect.fromLTWH(origin.dx, origin.dy, cell * g.width, cell * g.height));
    for (var y = 0; y < g.height; y++) {
      for (var x = 0; x < g.width; x++) {
        final r = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);
        if (g.baseTile(x, y)!.type == TileType.pit) {
          sp.pitBase(r);
        } else {
          sp.floor(r, x, y);
        }
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync((size.width * dpr).ceil(), (size.height * dpr).ceil());
    picture.dispose();
    _backdrop = image;
    _backdropKey = key;
    return image;
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  void predictInteract() {
    final g = client.game;
    final me = client.me;
    if (g == null || me == null) return;
    final tx = me.tileX + me.facing.dx;
    final ty = me.tileY + me.facing.dy;
    final tile = g.tileAt(tx, ty);
    if (tile == null) return;
    predictedChef = me.id;
    predictionTtl = 0.25;
    if (me.held == null) {
      final it = tile.item;
      if (it is PlateStack) {
        predictedHeld = Plate();
        predictedEmpty = false;
      } else if (tile.type == TileType.crate) {
        predictedHeld = IngredientItem(tile.crate!);
        predictedEmpty = false;
      } else if (it != null && it is! Extinguisher || it is Extinguisher) {
        predictedHeld = it;
        predictedEmpty = false;
      } else {
        predictedChef = null;
      }
    } else if (tile.type.holdsItems && tile.item == null) {
      predictedHeld = null;
      predictedEmpty = true;
    } else {
      predictedChef = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    particles.update(dt);
    if (predictionTtl > 0) {
      predictionTtl -= dt;
      if (predictionTtl <= 0) predictedChef = null;
    }
    final g = client.game;
    if (g == null) return;
    // Server confirmation clears the prediction early.
    if (predictedChef != null) {
      final c = g.chefById(predictedChef!);
      if (c != null && ((predictedEmpty && c.held == null) || (!predictedEmpty && c.held != null))) {
        predictedChef = null;
      }
    }
    for (final e in client.pendingEvents) {
      _spawnFx(e, g);
    }
    client.pendingEvents.clear();
  }

  void _spawnFx(GameEvent e, GameState g) {
    Offset at(int? x, int? y) => Offset((x ?? 0) + 0.5, (y ?? 0) + 0.5);
    switch (e.kind) {
      case 'served':
        particles.burst(at(e.x, e.y), PPColor.butter, count: 18, speed: 3.2);
        particles.text(at(e.x, e.y) - const Offset(0, 0.6), '+${e.value ?? 0}', PPColor.butter, scale: 1.3);
        final tip = (e.value ?? 0) - Scoring.basePoints;
        if (tip > 0) particles.text(at(e.x, e.y) - const Offset(0, 1.15), 'TIP +$tip', PPColor.basil, scale: 0.85);
        if (g.combo > 1) {
          particles.text(at(e.x, e.y) - const Offset(0, 1.6), 'COMBO x${g.combo}', PPColor.plum, scale: 0.85);
        }
      case 'wrong':
        particles.text(at(e.x, e.y) - const Offset(0, 0.6), 'WRONG DISH', PPColor.paprika);
      case 'burnt':
        particles.smoke(at(e.x, e.y), count: 14);
        particles.text(at(e.x, e.y) - const Offset(0, 0.8), 'BURNT!', PPColor.paprika);
      case 'fire':
        for (final (x, y, tile) in g.allTiles()) {
          if (tile.onFire) particles.burst(at(x, y), PPColor.paprika, count: 6, speed: 1.6);
        }
      case 'extinguished':
        particles.smoke(at(e.x, e.y), count: 10, color: PPColor.steel);
      case 'chopped':
        particles.burst(at(e.x, e.y), PPColor.basil, count: 6, speed: 1.4, size: 0.06);
      case 'cooked':
        particles.text(at(e.x, e.y) - const Offset(0, 0.7), 'READY', PPColor.basil, scale: 0.9);
      case 'washed':
        particles.burst(at(e.x, e.y), PPColor.water, count: 8, speed: 1.4, size: 0.06);
      case 'dash':
        final c = g.chefById(e.chef ?? '');
        if (c != null) particles.puff(Offset(c.x, c.y + 0.3));
      case 'plated':
        particles.burst(at(e.x, e.y), Colors.white, count: 5, speed: 1.0, size: 0.05);
      case 'trash':
        final c = g.chefById(e.chef ?? '');
        if (c != null) particles.puff(Offset(c.x + c.facing.dx, c.y + c.facing.dy), color: PPColor.mute);
    }
  }

  void _layout(Size size, GameState g) {
    // Leave room for the wall band (0.22 cell) and hanging progress bubbles.
    const wallX = 1.0, wallY = 1.2;
    cell = math.min(size.width / (g.width + wallX), size.height / (g.height + wallY)).floorToDouble();
    final w = cell * g.width;
    final h = cell * g.height;
    origin = Offset((size.width - w) / 2, (size.height - h) / 2 + cell * 0.1);
  }

  Offset _px(double x, double y) => Offset(origin.dx + x * cell, origin.dy + y * cell);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final g = client.game;
    if (g == null) return;
    final viewport = size.toSize();
    _layout(viewport, g);
    final sp = Sprites(canvas, cell, t, isDark: isDark);

    // Pass 1: brick frame, floors and pit water from the cached backdrop, then
    // the animated pit ripples on top.
    final dpr = PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;
    final backdrop = _backdropFor(g, viewport, dpr);
    canvas.drawImageRect(
      backdrop,
      Rect.fromLTWH(0, 0, backdrop.width.toDouble(), backdrop.height.toDouble()),
      Rect.fromLTWH(0, 0, viewport.width, viewport.height),
      Paint()..filterQuality = FilterQuality.low,
    );
    for (var y = 0; y < g.height; y++) {
      for (var x = 0; x < g.width; x++) {
        if (g.baseTile(x, y)!.type != TileType.pit) continue;
        sp.pitRipple(Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell), x, y);
      }
    }
    // Pass 2: mover platforms (continuous offsets).
    for (var i = 0; i < g.level.movers.length; i++) {
      final m = g.level.movers[i];
      final off = g.moverOffsets[i];
      final mx = m.x + (m.axis == 'x' ? off : 0);
      final my = m.y + (m.axis == 'y' ? off : 0);
      for (var yy = 0; yy < m.height; yy++) {
        for (var xx = 0; xx < m.width; xx++) {
          final tile = g.moverTiles[i][yy * m.width + xx];
          final r = Rect.fromLTWH(origin.dx + (mx + xx) * cell, origin.dy + (my + yy) * cell, cell, cell);
          sp.platform(r, first: xx == 0, last: xx == m.width - 1, top: yy == 0, bottom: yy == m.height - 1);
          if (tile.type != TileType.platform) sp.station(r, tile);
        }
      }
    }
    // Pass 3: base stations, sorted by row so fronts overlap correctly.
    for (var y = 0; y < g.height; y++) {
      for (var x = 0; x < g.width; x++) {
        final tile = g.baseTile(x, y)!;
        if (tile.type == TileType.floor || tile.type == TileType.pit) continue;
        final r = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);
        sp.station(r, tile);
      }
    }
    // Pass 4: items on tiles, progress and fire (base + movers).
    for (var y = 0; y < g.height; y++) {
      for (var x = 0; x < g.width; x++) {
        final tile = g.baseTile(x, y)!;
        final r = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell, cell);
        sp.tileContents(r, tile);
      }
    }
    for (var i = 0; i < g.level.movers.length; i++) {
      final m = g.level.movers[i];
      final off = g.moverOffsets[i];
      final mx = m.x + (m.axis == 'x' ? off : 0);
      final my = m.y + (m.axis == 'y' ? off : 0);
      for (var yy = 0; yy < m.height; yy++) {
        for (var xx = 0; xx < m.width; xx++) {
          final tile = g.moverTiles[i][yy * m.width + xx];
          final r = Rect.fromLTWH(origin.dx + (mx + xx) * cell, origin.dy + (my + yy) * cell, cell, cell);
          sp.tileContents(r, tile);
        }
      }
    }

    // Pass 5: chefs, sorted by y for overlap.
    final a = client.interpolation;
    final chefs = [...g.chefs]..sort((p, q) => p.y.compareTo(q.y));
    for (final c in chefs) {
      final prev = client.prevPos[c.id] ?? (c.x, c.y);
      var x = prev.$1 + (c.x - prev.$1) * a;
      var y = prev.$2 + (c.y - prev.$2) * a;
      // Never lerp across a teleport (respawn/platform snap).
      if ((c.x - prev.$1).abs() > 1.5 || (c.y - prev.$2).abs() > 1.5) {
        x = c.x;
        y = c.y;
      }
      var held = c.held;
      if (predictedChef == c.id) held = predictedEmpty ? null : predictedHeld;
      sp.chef(_px(x, y), c, held: held, isMe: c.id == client.playerId, moving: prev.$1 != c.x || prev.$2 != c.y);
    }

    // Pass 6: particles + floating text.
    particles.render(canvas, cell, origin);

    // Fire glow overlay.
    var anyFire = false;
    for (final (_, _, tile) in g.allTiles()) {
      if (tile.onFire) {
        anyFire = true;
        break;
      }
    }
    if (anyFire) {
      final pulse = 0.08 + 0.05 * math.sin(t * 6);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = PPColor.paprika.withValues(alpha: pulse));
    }
  }
}
