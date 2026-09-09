import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../theme/tokens.dart';

/// Ingredient colours (original palette).
Color ingredientColor(Ingredient i) => switch (i) {
  Ingredient.tomato => const Color(0xFFE94F37),
  Ingredient.onion => const Color(0xFFE9D8F2),
  Ingredient.mushroom => const Color(0xFFC79A6A),
  Ingredient.lettuce => const Color(0xFF6CC551),
};

Color ingredientAccent(Ingredient i) => switch (i) {
  Ingredient.tomato => const Color(0xFF3FAF6E),
  Ingredient.onion => const Color(0xFFB08ACF),
  Ingredient.mushroom => const Color(0xFFF2E3D0),
  Ingredient.lettuce => const Color(0xFFB5E88E),
};

Color dishColor(Dish d) => switch (d) {
  Dish.tomatoSoup => const Color(0xFFE94F37),
  Dish.onionSoup => const Color(0xFFE6C98A),
  Dish.mushroomSoup => const Color(0xFFB98A5E),
  Dish.gardenSalad => const Color(0xFF6CC551),
};

/// Stateless vector painter for one frame. `cell` is the tile size in px.
class Sprites {
  Sprites(this.c, this.cell, this.t, {required this.isDark});

  final Canvas c;
  final double cell;
  final double t;
  final bool isDark;

  final Paint _p = Paint();
  Paint _fill(Color color) => _p
    ..style = PaintingStyle.fill
    ..color = color
    ..strokeWidth = 0
    ..shader = null
    ..maskFilter = null;

  RRect _rr(Rect r, double rad) => RRect.fromRectAndRadius(r, Radius.circular(rad));

  // ------------------------------------------------------------------ floors

  void floor(Rect r, int x, int y) {
    final even = (x + y) % 2 == 0;
    final a = isDark ? const Color(0xFF4D4A5A) : PPColor.floorA;
    final b = isDark ? const Color(0xFF45424F) : PPColor.floorB;
    c.drawRect(r, _fill(even ? a : b));
  }

  void pit(Rect r, int x, int y) {
    final base = isDark ? const Color(0xFF14202B) : const Color(0xFF2B6E9E);
    c.drawRect(r, _fill(base));
    // Gentle water ripple.
    final wave = math.sin(t * 1.6 + x * 0.9 + y * 1.7);
    final ry = r.top + r.height * (0.5 + 0.18 * wave);
    final path = Path()..moveTo(r.left, ry);
    for (var i = 1; i <= 4; i++) {
      final px = r.left + r.width * i / 4;
      path.lineTo(px, ry + math.sin(t * 2 + px * 0.08) * cell * 0.04);
    }
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = const Color(0xFFFFFFFF).withValues(alpha: isDark ? 0.10 : 0.22),
    );
  }

  void platform(Rect r, {required bool first, required bool last, required bool top, required bool bottom}) {
    final wood = isDark ? const Color(0xFF6B4A2E) : PPColor.wood;
    final wood2 = isDark ? const Color(0xFF7D5738) : const Color(0xFF9E6A3E);
    c.drawRect(r, _fill(wood));
    for (var i = 0; i < 3; i++) {
      final plank = Rect.fromLTWH(
        r.left + cell * 0.04,
        r.top + r.height * (i / 3) + cell * 0.05,
        r.width - cell * 0.08,
        r.height / 3 - cell * 0.08,
      );
      c.drawRRect(_rr(plank, cell * 0.06), _fill(wood2));
    }
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.08
      ..color = const Color(0xFF3F2A18);
    if (first) c.drawLine(r.topLeft, r.bottomLeft, edge);
    if (last) c.drawLine(r.topRight, r.bottomRight, edge);
    if (top) c.drawLine(r.topLeft, r.topRight, edge);
    if (bottom) c.drawLine(r.bottomLeft, r.bottomRight, edge);
  }

  // ---------------------------------------------------------------- stations

  void _counterBase(Rect r, {Color? top, Color? side}) {
    final topC = top ?? (isDark ? const Color(0xFF8E7A5C) : PPColor.counterTop);
    final sideC = side ?? (isDark ? const Color(0xFF5A4A34) : PPColor.counterSide);
    final body = r.deflate(cell * 0.03);
    // Front face (3D edge).
    c.drawRRect(
      _rr(Rect.fromLTRB(body.left, body.top + cell * 0.18, body.right, body.bottom), cell * 0.12),
      _fill(sideC),
    );
    // Top.
    c.drawRRect(
      _rr(Rect.fromLTRB(body.left, body.top, body.right, body.bottom - cell * 0.16), cell * 0.12),
      _fill(topC),
    );
    // Highlight.
    c.drawRRect(
      _rr(
        Rect.fromLTRB(
          body.left + cell * 0.08,
          body.top + cell * 0.06,
          body.right - cell * 0.08,
          body.top + cell * 0.14,
        ),
        cell * 0.05,
      ),
      _fill(const Color(0xFFFFFFFF).withValues(alpha: 0.25)),
    );
  }

  void station(Rect r, Tile tile) {
    switch (tile.type) {
      case TileType.wall:
        c.drawRRect(
          _rr(r.deflate(cell * 0.02), cell * 0.08),
          _fill(isDark ? const Color(0xFF2C2A36) : const Color(0xFF8B7A63)),
        );
      case TileType.counter:
        _counterBase(r);
      case TileType.crate:
        _counterBase(
          r,
          top: isDark ? const Color(0xFF7A5A3C) : const Color(0xFFC2905E),
          side: isDark ? const Color(0xFF4F3A26) : const Color(0xFF8C5A34),
        );
        final inner = Rect.fromLTRB(
          r.left + cell * 0.16,
          r.top + cell * 0.14,
          r.right - cell * 0.16,
          r.bottom - cell * 0.32,
        );
        c.drawRRect(_rr(inner, cell * 0.08), _fill(const Color(0xFF3F2A18).withValues(alpha: 0.55)));
        // Ingredient heap.
        final ing = tile.crate!;
        for (var i = 0; i < 3; i++) {
          final cx = inner.left + inner.width * (0.25 + 0.25 * i);
          final cy = inner.center.dy + (i == 1 ? -cell * 0.06 : cell * 0.02);
          ingredient(Offset(cx, cy), ing, chopped: false, scale: 0.55);
        }
      case TileType.board:
        _counterBase(r);
        final board = Rect.fromLTRB(
          r.left + cell * 0.14,
          r.top + cell * 0.12,
          r.right - cell * 0.14,
          r.bottom - cell * 0.34,
        );
        c.drawRRect(_rr(board, cell * 0.06), _fill(isDark ? const Color(0xFFB9925F) : const Color(0xFFE2B77E)));
        c.drawRRect(
          _rr(board.deflate(cell * 0.03), cell * 0.05),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.02
            ..color = const Color(0xFF7A5230).withValues(alpha: 0.5),
        );
        // Knife.
        final k = Offset(r.right - cell * 0.22, r.top + cell * 0.22);
        c.drawRRect(
          _rr(Rect.fromCenter(center: k, width: cell * 0.1, height: cell * 0.34), cell * 0.03),
          _fill(PPColor.steel),
        );
        c.drawRRect(
          _rr(
            Rect.fromCenter(center: k + Offset(0, cell * 0.22), width: cell * 0.09, height: cell * 0.12),
            cell * 0.02,
          ),
          _fill(PPColor.ink),
        );
      case TileType.stove:
        _counterBase(
          r,
          top: isDark ? const Color(0xFF6D6F78) : PPColor.steel,
          side: isDark ? const Color(0xFF474952) : PPColor.steelDark,
        );
        final ring = Offset(r.center.dx, r.top + cell * 0.36);
        c.drawCircle(ring, cell * 0.3, _fill(const Color(0xFF2B2B33)));
        final hot = tile.item is Pot && (tile.item as Pot).contents.isNotEmpty && !(tile.item as Pot).burnt;
        c.drawCircle(
          ring,
          cell * 0.22,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.05
            ..color = hot
                ? Color.lerp(const Color(0xFFE8563F), const Color(0xFFFFB347), 0.5 + 0.5 * math.sin(t * 8))!
                : const Color(0xFF4A4A55),
        );
      case TileType.sink:
        _counterBase(
          r,
          top: isDark ? const Color(0xFF6D6F78) : PPColor.steel,
          side: isDark ? const Color(0xFF474952) : PPColor.steelDark,
        );
        final basin = Rect.fromLTRB(
          r.left + cell * 0.14,
          r.top + cell * 0.12,
          r.right - cell * 0.14,
          r.bottom - cell * 0.36,
        );
        c.drawRRect(_rr(basin, cell * 0.1), _fill(const Color(0xFF3E4650)));
        c.drawRRect(_rr(basin.deflate(cell * 0.05), cell * 0.08), _fill(PPColor.water.withValues(alpha: 0.85)));
        // Tap.
        c.drawRRect(
          _rr(Rect.fromLTWH(r.center.dx - cell * 0.04, r.top + cell * 0.02, cell * 0.08, cell * 0.16), cell * 0.03),
          _fill(PPColor.steelDark),
        );
      case TileType.rack:
        _counterBase(r);
      case TileType.plateReturn:
        _counterBase(
          r,
          top: isDark ? const Color(0xFF6D6F78) : PPColor.steel,
          side: isDark ? const Color(0xFF474952) : PPColor.steelDark,
        );
        final slot = Rect.fromLTRB(
          r.left + cell * 0.18,
          r.top + cell * 0.16,
          r.right - cell * 0.18,
          r.top + cell * 0.36,
        );
        c.drawRRect(_rr(slot, cell * 0.05), _fill(const Color(0xFF2B2B33)));
      case TileType.pass:
        _counterBase(
          r,
          top: isDark ? const Color(0xFF3F7FE8) : const Color(0xFF5B95F0),
          side: isDark ? const Color(0xFF2A56A3) : const Color(0xFF2F63C4),
        );
        // Bell.
        final b = Offset(r.center.dx, r.top + cell * 0.34);
        final bob = math.sin(t * 3) * cell * 0.01;
        c.drawCircle(b + Offset(0, bob), cell * 0.17, _fill(PPColor.butter));
        c.drawRect(
          Rect.fromCenter(center: b + Offset(0, cell * 0.17 + bob), width: cell * 0.4, height: cell * 0.06),
          _fill(PPColor.butter),
        );
        c.drawCircle(b + Offset(0, -cell * 0.17 + bob), cell * 0.04, _fill(PPColor.ink));
      case TileType.trash:
        _counterBase(r);
        final bin = Rect.fromLTRB(
          r.left + cell * 0.22,
          r.top + cell * 0.08,
          r.right - cell * 0.22,
          r.bottom - cell * 0.3,
        );
        c.drawRRect(_rr(bin, cell * 0.06), _fill(const Color(0xFF4B5563)));
        c.drawRRect(
          _rr(
            Rect.fromLTWH(bin.left - cell * 0.04, bin.top - cell * 0.02, bin.width + cell * 0.08, cell * 0.1),
            cell * 0.03,
          ),
          _fill(const Color(0xFF6B7280)),
        );
      case TileType.conveyor:
        final belt = r.deflate(cell * 0.02);
        c.drawRRect(_rr(belt, cell * 0.08), _fill(const Color(0xFF3B3B45)));
        c.drawRRect(_rr(belt.deflate(cell * 0.09), cell * 0.06), _fill(const Color(0xFF55555F)));
        // Animated chevrons.
        final d = tile.conveyorDir!;
        final phase = (t * 1.2) % 1;
        final chev = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06
          ..strokeCap = StrokeCap.round
          ..color = PPColor.butter.withValues(alpha: 0.8);
        for (var i = 0; i < 3; i++) {
          final f = ((i / 3) + phase) % 1;
          final along = -0.3 + f * 0.6;
          final cx = r.center.dx + d.dx * along * cell;
          final cy = r.center.dy + d.dy * along * cell;
          final path = Path();
          final s = cell * 0.13;
          if (d.dx != 0) {
            path
              ..moveTo(cx - d.dx * s, cy - s)
              ..lineTo(cx, cy)
              ..lineTo(cx - d.dx * s, cy + s);
          } else {
            path
              ..moveTo(cx - s, cy - d.dy * s)
              ..lineTo(cx, cy)
              ..lineTo(cx + s, cy - d.dy * s);
          }
          c.drawPath(path, chev);
        }
      case TileType.floor || TileType.pit || TileType.platform:
        break;
    }
  }

  /// Items, fire and progress bars on top of a tile.
  void tileContents(Rect r, Tile tile) {
    final it = tile.item;
    final top = Offset(r.center.dx, r.top + cell * 0.36);
    if (it != null) {
      if (tile.type == TileType.conveyor) {
        final d = tile.conveyorDir!;
        final off = (tile.conveyor - 0.5) * cell;
        item(Offset(r.center.dx + d.dx * off, r.center.dy + d.dy * off), it, scale: 0.9);
      } else {
        item(top, it, scale: tile.type == TileType.stove || tile.type == TileType.board ? 1 : 0.92);
      }
    }
    if (tile.progress > 0 && (tile.type == TileType.board || tile.type == TileType.sink)) {
      progressBar(Offset(r.center.dx, r.bottom - cell * 0.2), tile.progress, PPColor.basil);
    }
    if (it is Pot && it.contents.isNotEmpty && !it.burnt) {
      if (it.cook < 1) {
        progressBar(Offset(r.center.dx, r.bottom - cell * 0.2), it.cook, PPColor.butter);
      } else {
        final warn = it.burn > 0.5 && (t * 6).floor().isEven;
        progressBar(
          Offset(r.center.dx, r.bottom - cell * 0.2),
          it.burn,
          warn ? PPColor.paprikaDark : PPColor.paprika,
          track: PPColor.basil,
        );
      }
    }
    if (tile.onFire) fire(Offset(r.center.dx, r.center.dy), tile.fire);
  }

  void progressBar(Offset center, double f, Color color, {Color? track}) {
    final w = cell * 0.66;
    final h = cell * 0.12;
    final r = Rect.fromCenter(center: center, width: w, height: h);
    c.drawRRect(_rr(r.inflate(cell * 0.02), h), _fill(const Color(0xAA000000)));
    c.drawRRect(_rr(r, h), _fill(track ?? const Color(0xFF3A3846)));
    c.drawRRect(_rr(Rect.fromLTWH(r.left, r.top, w * f.clamp(0, 1), h), h), _fill(color));
  }

  void fire(Offset at, double intensity) {
    for (var i = 0; i < 3; i++) {
      final ph = t * 9 + i * 2.1;
      final fx = at.dx + math.sin(ph) * cell * 0.1 + (i - 1) * cell * 0.16;
      final fy = at.dy - cell * 0.05 - (math.sin(ph * 0.7) * 0.5 + 0.5) * cell * 0.12;
      final h = cell * (0.28 + 0.1 * math.sin(ph * 1.3)) * (0.7 + 0.3 * intensity);
      final flame = Path()
        ..moveTo(fx - cell * 0.12, fy + cell * 0.1)
        ..quadraticBezierTo(fx - cell * 0.14, fy - h * 0.4, fx, fy - h)
        ..quadraticBezierTo(fx + cell * 0.14, fy - h * 0.4, fx + cell * 0.12, fy + cell * 0.1)
        ..close();
      c.drawPath(flame, _fill(const Color(0xFFFF7A1A)));
      final inner = Path()
        ..moveTo(fx - cell * 0.06, fy + cell * 0.08)
        ..quadraticBezierTo(fx - cell * 0.07, fy - h * 0.25, fx, fy - h * 0.55)
        ..quadraticBezierTo(fx + cell * 0.07, fy - h * 0.25, fx + cell * 0.06, fy + cell * 0.08)
        ..close();
      c.drawPath(inner, _fill(PPColor.butter));
    }
  }

  // ------------------------------------------------------------------- items

  void item(Offset at, Item it, {double scale = 1}) {
    switch (it) {
      case IngredientItem():
        ingredient(at, it.ingredient, chopped: it.chopped, scale: scale);
      case Pot():
        pot(at, it, scale: scale);
      case Plate():
        plate(at, it, scale: scale);
      case PlateStack():
        plateStack(at, it, scale: scale);
      case Extinguisher():
        extinguisher(at, scale: scale);
    }
  }

  void ingredient(Offset at, Ingredient ing, {required bool chopped, double scale = 1}) {
    final s = cell * 0.3 * scale;
    final col = ingredientColor(ing);
    final acc = ingredientAccent(ing);
    c.drawCircle(at + Offset(0, s * 0.35), s * 0.9, _fill(const Color(0x33000000)));
    if (chopped) {
      // Three slices fanned out.
      for (var i = -1; i <= 1; i++) {
        final o = at + Offset(i * s * 0.55, i.abs() * s * 0.12);
        c.drawOval(Rect.fromCenter(center: o, width: s * 0.9, height: s * 0.7), _fill(col));
        c.drawOval(Rect.fromCenter(center: o, width: s * 0.5, height: s * 0.38), _fill(acc.withValues(alpha: 0.85)));
      }
      return;
    }
    switch (ing) {
      case Ingredient.tomato:
        c.drawCircle(at, s, _fill(col));
        c.drawCircle(at + Offset(-s * 0.3, -s * 0.3), s * 0.28, _fill(const Color(0x55FFFFFF)));
        final leaf = Path()
          ..moveTo(at.dx, at.dy - s * 0.9)
          ..quadraticBezierTo(at.dx + s * 0.5, at.dy - s * 1.3, at.dx + s * 0.55, at.dy - s * 0.85)
          ..quadraticBezierTo(at.dx + s * 0.2, at.dy - s * 0.9, at.dx, at.dy - s * 0.65)
          ..close();
        c.drawPath(leaf, _fill(acc));
      case Ingredient.onion:
        c.drawOval(Rect.fromCenter(center: at, width: s * 1.9, height: s * 2), _fill(col));
        c.drawOval(Rect.fromCenter(center: at, width: s * 1.1, height: s * 1.3), _fill(acc.withValues(alpha: 0.35)));
        c.drawRRect(
          _rr(Rect.fromCenter(center: at + Offset(0, -s), width: s * 0.28, height: s * 0.5), s * 0.1),
          _fill(acc),
        );
      case Ingredient.mushroom:
        c.drawRRect(
          _rr(Rect.fromCenter(center: at + Offset(0, s * 0.45), width: s * 0.8, height: s * 1.0), s * 0.2),
          _fill(acc),
        );
        c.drawOval(Rect.fromCenter(center: at + Offset(0, -s * 0.2), width: s * 2, height: s * 1.3), _fill(col));
        c.drawCircle(at + Offset(-s * 0.4, -s * 0.3), s * 0.2, _fill(acc.withValues(alpha: 0.8)));
        c.drawCircle(at + Offset(s * 0.35, -s * 0.15), s * 0.15, _fill(acc.withValues(alpha: 0.8)));
      case Ingredient.lettuce:
        for (var i = 0; i < 5; i++) {
          final a = i * math.pi * 2 / 5;
          c.drawCircle(at + Offset(math.cos(a), math.sin(a)) * s * 0.55, s * 0.62, _fill(col));
        }
        c.drawCircle(at, s * 0.7, _fill(acc));
    }
  }

  void pot(Offset at, Pot p, {double scale = 1}) {
    final s = cell * 0.36 * scale;
    c.drawOval(
      Rect.fromCenter(center: at + Offset(0, s * 0.5), width: s * 2.3, height: s * 0.9),
      _fill(const Color(0x44000000)),
    );
    final body = Rect.fromCenter(center: at + Offset(0, s * 0.15), width: s * 2.1, height: s * 1.5);
    c.drawRRect(_rr(body, s * 0.35), _fill(const Color(0xFF3E4650)));
    // Handles.
    c.drawRRect(
      _rr(Rect.fromCenter(center: at + Offset(-s * 1.2, s * 0.05), width: s * 0.5, height: s * 0.25), s * 0.1),
      _fill(const Color(0xFF6B7280)),
    );
    c.drawRRect(
      _rr(Rect.fromCenter(center: at + Offset(s * 1.2, s * 0.05), width: s * 0.5, height: s * 0.25), s * 0.1),
      _fill(const Color(0xFF6B7280)),
    );
    // Contents.
    final rim = Rect.fromCenter(center: at + Offset(0, -s * 0.5), width: s * 2.0, height: s * 0.9);
    Color liquid;
    if (p.burnt) {
      liquid = const Color(0xFF2A211B);
    } else if (p.contents.isEmpty) {
      liquid = const Color(0xFF5B6470);
    } else {
      final d = Dish.match(p.contents, cooked: true);
      final base = d != null ? dishColor(d) : ingredientColor(p.contents.first);
      liquid = Color.lerp(base.withValues(alpha: 0.9), base, p.cook.clamp(0, 1))!;
    }
    c.drawOval(rim, _fill(const Color(0xFF6B7280)));
    c.drawOval(rim.deflate(s * 0.14), _fill(liquid));
    if (!p.burnt && p.contents.isNotEmpty && p.cook < 1) {
      for (var i = 0; i < p.contents.length; i++) {
        final a = t * 1.5 + i * 2.1;
        final o = rim.center + Offset(math.cos(a) * s * 0.45, math.sin(a) * s * 0.18);
        ingredient(o, p.contents[i], chopped: true, scale: 0.35);
      }
    }
    if (p.cook >= 1 && !p.burnt) {
      // Steam.
      for (var i = 0; i < 2; i++) {
        final ph = (t * 0.8 + i * 0.5) % 1;
        c.drawCircle(
          rim.center + Offset((i - 0.5) * s * 0.6, -s * (0.4 + ph * 1.4)),
          s * 0.22 * (1 - ph) + s * 0.05,
          _fill(const Color(0xFFFFFFFF).withValues(alpha: 0.55 * (1 - ph))),
        );
      }
    }
    if (p.burnt) {
      for (var i = 0; i < 2; i++) {
        final ph = (t * 0.6 + i * 0.5) % 1;
        c.drawCircle(
          rim.center + Offset((i - 0.5) * s * 0.7, -s * (0.4 + ph * 1.6)),
          s * 0.3 * (1 - ph) + s * 0.1,
          _fill(const Color(0xFF3A3846).withValues(alpha: 0.7 * (1 - ph))),
        );
      }
    }
  }

  void plate(Offset at, Plate p, {double scale = 1}) {
    final s = cell * 0.36 * scale;
    c.drawOval(
      Rect.fromCenter(center: at + Offset(0, s * 0.35), width: s * 2.3, height: s * 1.0),
      _fill(const Color(0x33000000)),
    );
    c.drawOval(Rect.fromCenter(center: at, width: s * 2.2, height: s * 1.1), _fill(const Color(0xFFFFFFFF)));
    c.drawOval(Rect.fromCenter(center: at, width: s * 1.6, height: s * 0.75), _fill(const Color(0xFFE6E2DA)));
    if (p.contents.isEmpty) return;
    final d = p.dish;
    if (d != null && d.cooked) {
      c.drawOval(Rect.fromCenter(center: at, width: s * 1.5, height: s * 0.7), _fill(dishColor(d)));
      c.drawOval(
        Rect.fromCenter(center: at + Offset(-s * 0.3, -s * 0.1), width: s * 0.5, height: s * 0.2),
        _fill(const Color(0x66FFFFFF)),
      );
    } else {
      for (var i = 0; i < p.contents.length; i++) {
        final o = at + Offset((i - (p.contents.length - 1) / 2) * s * 0.55, -s * 0.15);
        ingredient(o, p.contents[i], chopped: true, scale: 0.4);
      }
    }
  }

  void plateStack(Offset at, PlateStack st, {double scale = 1}) {
    final s = cell * 0.36 * scale;
    final n = st.count.clamp(0, 5);
    for (var i = 0; i < n; i++) {
      final o = at + Offset(0, -i * s * 0.22);
      c.drawOval(
        Rect.fromCenter(center: o, width: s * 2.1, height: s * 1.0),
        _fill(st.dirty ? const Color(0xFFB8A98F) : const Color(0xFFFFFFFF)),
      );
      c.drawOval(
        Rect.fromCenter(center: o, width: s * 1.5, height: s * 0.68),
        _fill(st.dirty ? const Color(0xFF8E7B5F) : const Color(0xFFE6E2DA)),
      );
      if (st.dirty) {
        c.drawCircle(o + Offset(s * 0.3, -s * 0.05), s * 0.15, _fill(const Color(0xFF6B4F2E)));
        c.drawCircle(o + Offset(-s * 0.35, s * 0.1), s * 0.1, _fill(const Color(0xFF6B4F2E)));
      }
    }
    if (st.count > 0) {
      _label(at + Offset(s * 0.9, -s * 0.9), '${st.count}', const Color(0xFFFFFFFF), bg: PPColor.ink);
    }
  }

  void extinguisher(Offset at, {double scale = 1}) {
    final s = cell * 0.36 * scale;
    c.drawRRect(_rr(Rect.fromCenter(center: at, width: s * 0.9, height: s * 1.9), s * 0.3), _fill(PPColor.paprika));
    c.drawRRect(
      _rr(Rect.fromCenter(center: at + Offset(0, -s * 0.95), width: s * 0.45, height: s * 0.35), s * 0.1),
      _fill(PPColor.ink),
    );
    c.drawRRect(
      _rr(Rect.fromCenter(center: at + Offset(s * 0.5, -s * 0.6), width: s * 0.7, height: s * 0.2), s * 0.1),
      _fill(PPColor.ink),
    );
    c.drawRRect(
      _rr(Rect.fromCenter(center: at, width: s * 0.5, height: s * 0.6), s * 0.08),
      _fill(const Color(0xFFFFFFFF).withValues(alpha: 0.85)),
    );
  }

  // ------------------------------------------------------------------- chefs

  void chef(Offset at, Chef ch, {Item? held, required bool isMe, required bool moving}) {
    final col = PPColor.chefs[ch.slot % 4];
    final s = cell * 0.36;
    final bob = moving ? math.sin(t * 16) * s * 0.08 : 0.0;
    final body = at + Offset(0, -s * 0.3 + bob);

    // Shadow.
    c.drawOval(
      Rect.fromCenter(center: at + Offset(0, s * 0.85), width: s * 1.9, height: s * 0.7),
      _fill(const Color(0x44000000)),
    );
    if (ch.dash > 0) {
      c.drawCircle(body, s * 1.35, _fill(col.withValues(alpha: 0.25)));
    }
    if (isMe) {
      c.drawCircle(
        at + Offset(0, s * 0.85),
        s * 1.15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.05
          ..color = col.withValues(alpha: 0.9),
      );
    }
    // Apron + body.
    c.drawRRect(
      _rr(Rect.fromCenter(center: body + Offset(0, s * 0.35), width: s * 1.6, height: s * 1.5), s * 0.5),
      _fill(col),
    );
    c.drawRRect(
      _rr(Rect.fromCenter(center: body + Offset(0, s * 0.55), width: s * 1.0, height: s * 1.0), s * 0.3),
      _fill(const Color(0xFFFFFFFF).withValues(alpha: 0.92)),
    );
    // Head.
    final skin = ch.bot ? const Color(0xFFCFD4DA) : const Color(0xFFF6C9A0);
    c.drawCircle(body + Offset(0, -s * 0.5), s * 0.72, _fill(skin));
    // Face direction.
    final fd = Offset(ch.facing.dx * 1.0, ch.facing.dy * 1.0);
    if (ch.facing != Dir.up) {
      final eyeY = body.dy - s * 0.55 + fd.dy * s * 0.15;
      final ex = body.dx + fd.dx * s * 0.25;
      c.drawCircle(Offset(ex - s * 0.22, eyeY), s * 0.09, _fill(PPColor.ink));
      c.drawCircle(Offset(ex + s * 0.22, eyeY), s * 0.09, _fill(PPColor.ink));
      if (ch.bot) {
        c.drawRect(
          Rect.fromCenter(center: Offset(ex, eyeY + s * 0.28), width: s * 0.36, height: s * 0.07),
          _fill(PPColor.ink),
        );
      } else {
        c.drawArc(
          Rect.fromCenter(center: Offset(ex, eyeY + s * 0.18), width: s * 0.36, height: s * 0.24),
          0.2,
          math.pi - 0.4,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.07
            ..color = PPColor.ink,
        );
      }
    }
    // Hat.
    final hatTop = body + Offset(0, -s * 1.25);
    c.drawRRect(
      _rr(Rect.fromCenter(center: body + Offset(0, -s * 1.05), width: s * 1.3, height: s * 0.4), s * 0.1),
      _fill(const Color(0xFFFFFFFF)),
    );
    c.drawOval(Rect.fromCenter(center: hatTop, width: s * 1.45, height: s * 0.9), _fill(const Color(0xFFFFFFFF)));
    c.drawOval(
      Rect.fromCenter(center: hatTop + Offset(0, s * 0.05), width: s * 1.45, height: s * 0.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.06
        ..color = col.withValues(alpha: 0.6),
    );
    if (ch.bot) {
      // Antenna marks a server bot.
      c.drawLine(
        hatTop + Offset(0, -s * 0.4),
        hatTop + Offset(0, -s * 0.85),
        Paint()
          ..strokeWidth = s * 0.08
          ..color = PPColor.steelDark,
      );
      c.drawCircle(hatTop + Offset(0, -s * 0.9), s * 0.12, _fill(col));
    }
    // Held item floats in front.
    if (held != null) {
      final hp = body + Offset(fd.dx * s * 0.9, s * 0.6 + fd.dy * s * 0.5);
      item(hp, held, scale: 0.72);
    }
    // Working sparkle.
    if (ch.working) {
      final a = t * 12;
      final o = body + Offset(fd.dx * s * 1.4, fd.dy * s * 1.2 + s * 0.4);
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * s * 0.3, s * 0.1, _fill(PPColor.butter));
      c.drawCircle(o - Offset(math.cos(a), math.sin(a)) * s * 0.3, s * 0.08, _fill(const Color(0xFFFFFFFF)));
    }
    // Name tag.
    _label(
      at + Offset(0, s * 1.45),
      ch.name,
      const Color(0xFFFFFFFF),
      bg: col.withValues(alpha: ch.connected ? 0.95 : 0.45),
      scale: 0.9,
    );
    if (!ch.connected) {
      _label(
        at + Offset(0, -s * 2.6),
        'offline',
        const Color(0xFFFFFFFF),
        bg: PPColor.ink.withValues(alpha: 0.8),
        scale: 0.8,
      );
    }
    // Emote bubble.
    if (ch.emote != null && ch.emote! >= 0 && ch.emote! < kEmotes.length) {
      _bubble(body + Offset(s * 1.1, -s * 2.2), kEmotes[ch.emote!], col);
    }
  }

  void _label(Offset center, String text, Color color, {required Color bg, double scale = 1}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: PPType.caption(color).copyWith(fontSize: cell * 0.19 * scale, letterSpacing: 0.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromCenter(center: center, width: tp.width + cell * 0.18, height: tp.height + cell * 0.08);
    c.drawRRect(_rr(r, r.height / 2), _fill(bg));
    tp.paint(c, Offset(r.left + cell * 0.09, r.top + cell * 0.04));
  }

  void _bubble(Offset at, String text, Color accent) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: PPType.h3(PPColor.ink).copyWith(fontSize: cell * 0.24),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pop = 1 + 0.06 * math.sin(t * 10);
    final r = Rect.fromCenter(
      center: at,
      width: (tp.width + cell * 0.3) * pop,
      height: (tp.height + cell * 0.18) * pop,
    );
    c.drawRRect(_rr(r.shift(Offset(0, cell * 0.04)), cell * 0.18), _fill(const Color(0x44000000)));
    c.drawRRect(_rr(r, cell * 0.18), _fill(const Color(0xFFFFFFFF)));
    final tail = Path()
      ..moveTo(r.left + cell * 0.2, r.bottom - 1)
      ..lineTo(r.left + cell * 0.05, r.bottom + cell * 0.16)
      ..lineTo(r.left + cell * 0.4, r.bottom - 1)
      ..close();
    c.drawPath(tail, _fill(const Color(0xFFFFFFFF)));
    c.drawRRect(
      _rr(r, cell * 0.18),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.04
        ..color = accent,
    );
    tp.paint(c, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }
}
