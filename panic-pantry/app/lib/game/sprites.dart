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
    final grout = isDark ? const Color(0xFF3A3846) : PPColor.grout;
    c.drawRect(r, _fill(grout));
    // Four glazed tiles per cell with thin grout lines.
    final g = cell * 0.025;
    final half = cell / 2;
    for (var i = 0; i < 2; i++) {
      for (var j = 0; j < 2; j++) {
        final tile = Rect.fromLTWH(r.left + i * half + g, r.top + j * half + g, half - g * 2, half - g * 2);
        c.drawRRect(_rr(tile, cell * 0.03), _fill(even == ((i + j) % 2 == 0) ? a : b));
      }
    }
  }

  void pitBase(Rect r) {
    final base = isDark ? const Color(0xFF14202B) : const Color(0xFF2B6E9E);
    c.drawRect(r, _fill(base));
  }

  /// Gentle animated water ripple over [pitBase].
  void pitRipple(Rect r, int x, int y) {
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

  /// Depth of a counter's front face, as a fraction of a cell.
  static const double lip = 0.3;

  /// Chunky counter module: rounded top slab with a visible front face and a
  /// darker foot so the kitchen reads as blocks seen from a raised camera.
  void _counterBase(Rect r, {Color? top, Color? side, Color? edge, bool drawer = true}) {
    final topC = top ?? (isDark ? const Color(0xFF8E7A5C) : PPColor.counterTop);
    final sideC = side ?? (isDark ? const Color(0xFF5A4A34) : PPColor.counterSide);
    final edgeC = edge ?? (isDark ? const Color(0xFF6E5B42) : PPColor.counterEdge);
    final body = r.deflate(cell * 0.015);
    // Ground shadow.
    c.drawRRect(
      _rr(
        Rect.fromLTRB(
          body.left + cell * 0.04,
          body.bottom - cell * 0.08,
          body.right + cell * 0.03,
          body.bottom + cell * 0.05,
        ),
        cell * 0.1,
      ),
      _fill(const Color(0x30000000)),
    );
    // Front face.
    c.drawRRect(
      _rr(Rect.fromLTRB(body.left, body.top + cell * (1 - lip) - cell * 0.1, body.right, body.bottom), cell * 0.1),
      _fill(sideC),
    );
    // Foot line.
    c.drawRect(
      Rect.fromLTRB(
        body.left + cell * 0.04,
        body.bottom - cell * 0.06,
        body.right - cell * 0.04,
        body.bottom - cell * 0.02,
      ),
      _fill(isDark ? const Color(0xFF3A2E1F) : PPColor.counterFoot),
    );
    if (drawer) {
      // Drawer handle on the front face.
      c.drawRRect(
        _rr(
          Rect.fromCenter(
            center: Offset(body.center.dx, body.bottom - cell * 0.15),
            width: cell * 0.26,
            height: cell * 0.05,
          ),
          cell * 0.03,
        ),
        _fill(const Color(0x55000000)),
      );
    }
    // Top slab with a lighter rim.
    final slab = Rect.fromLTRB(body.left, body.top, body.right, body.bottom - cell * lip);
    c.drawRRect(_rr(slab, cell * 0.1), _fill(edgeC));
    c.drawRRect(_rr(slab.deflate(cell * 0.045), cell * 0.07), _fill(topC));
  }

  /// Steel-topped module (stove, sink, pass, return chute) with a red or grey body.
  void _applianceBase(Rect r, {required Color body, required Color bodyDark, Color? top}) {
    _counterBase(
      r,
      top: top ?? (isDark ? const Color(0xFF6D6F78) : PPColor.steel),
      edge: top != null
          ? Color.lerp(top, const Color(0xFF000000), 0.2)
          : (isDark ? const Color(0xFF474952) : PPColor.steelDark),
      side: body,
      drawer: false,
    );
    c.drawRect(
      Rect.fromLTRB(r.left + cell * 0.06, r.bottom - cell * 0.075, r.right - cell * 0.06, r.bottom - cell * 0.035),
      _fill(bodyDark),
    );
  }

  void station(Rect r, Tile tile) {
    switch (tile.type) {
      case TileType.wall:
        _brick(r);
      case TileType.counter:
        _counterBase(r);
      case TileType.crate:
        _counterBase(
          r,
          top: isDark ? const Color(0xFF7A5A3C) : const Color(0xFFC79463),
          edge: isDark ? const Color(0xFF5A4028) : const Color(0xFFA5733F),
          side: isDark ? const Color(0xFF4F3A26) : PPColor.wood,
          drawer: false,
        );
        // Wooden crate: slat lines on the front, picture label on top.
        final slat = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.025
          ..color = const Color(0x55000000);
        for (var i = 1; i <= 2; i++) {
          final y = r.bottom - cell * lip + cell * (lip - 0.06) * i / 3;
          c.drawLine(Offset(r.left + cell * 0.08, y), Offset(r.right - cell * 0.08, y), slat);
        }
        final label = Rect.fromLTRB(
          r.left + cell * 0.17,
          r.top + cell * 0.1,
          r.right - cell * 0.17,
          r.bottom - cell * lip - cell * 0.09,
        );
        c.drawRRect(_rr(label, cell * 0.06), _fill(const Color(0xFFFFF6E3)));
        c.drawRRect(
          _rr(label, cell * 0.06),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.03
            ..color = const Color(0xFF7A5230).withValues(alpha: 0.6),
        );
        ingredient(label.center + Offset(0, cell * 0.03), tile.crate!, chopped: false, scale: 0.72);
      case TileType.board:
        _counterBase(r);
        final board = Rect.fromLTRB(
          r.left + cell * 0.12,
          r.top + cell * 0.1,
          r.right - cell * 0.12,
          r.bottom - cell * lip - cell * 0.07,
        );
        c.drawRRect(_rr(board.shift(Offset(0, cell * 0.03)), cell * 0.06), _fill(const Color(0x33000000)));
        c.drawRRect(_rr(board, cell * 0.06), _fill(isDark ? const Color(0xFFB9925F) : const Color(0xFFE6BE84)));
        c.drawRRect(
          _rr(board.deflate(cell * 0.04), cell * 0.05),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.02
            ..color = const Color(0xFF7A5230).withValues(alpha: 0.45),
        );
        // Knife resting diagonally on the board.
        c.save();
        c.translate(r.right - cell * 0.26, r.top + cell * 0.2);
        c.rotate(0.6);
        c.drawRRect(
          _rr(Rect.fromCenter(center: Offset.zero, width: cell * 0.1, height: cell * 0.36), cell * 0.04),
          _fill(PPColor.steel),
        );
        c.drawRRect(
          _rr(Rect.fromCenter(center: Offset(0, cell * 0.24), width: cell * 0.09, height: cell * 0.14), cell * 0.02),
          _fill(PPColor.ink),
        );
        c.restore();
      case TileType.stove:
        _applianceBase(
          r,
          body: isDark ? const Color(0xFF8A3A2E) : PPColor.stove,
          bodyDark: isDark ? const Color(0xFF5E2620) : PPColor.stoveDark,
          top: isDark ? const Color(0xFFB04A3B) : const Color(0xFFE2584A),
        );
        // Black burner plate with a glowing ring while cooking.
        final ring = Offset(r.center.dx, r.top + cell * 0.36);
        c.drawCircle(ring, cell * 0.32, _fill(const Color(0xFF23222B)));
        final hot = tile.item is Pot && (tile.item as Pot).contents.isNotEmpty && !(tile.item as Pot).burnt;
        c.drawCircle(
          ring,
          cell * 0.23,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.05
            ..color = hot
                ? Color.lerp(const Color(0xFFE8563F), const Color(0xFFFFB347), 0.5 + 0.5 * math.sin(t * 8))!
                : const Color(0xFF4A4A55),
        );
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + math.pi / 4;
          c.drawCircle(
            ring + Offset(math.cos(a), math.sin(a)) * cell * 0.13,
            cell * 0.025,
            _fill(const Color(0xFF6A6A75)),
          );
        }
        // Dials on the front.
        for (final dx in [-0.16, 0.16]) {
          c.drawCircle(
            Offset(r.center.dx + cell * dx, r.bottom - cell * 0.16),
            cell * 0.045,
            _fill(const Color(0xFF23222B)),
          );
        }
      case TileType.sink:
        _applianceBase(
          r,
          body: isDark ? const Color(0xFF474952) : PPColor.steelDark,
          bodyDark: isDark ? const Color(0xFF2E3037) : const Color(0xFF5E6A74),
        );
        final basin = Rect.fromLTRB(
          r.left + cell * 0.13,
          r.top + cell * 0.14,
          r.right - cell * 0.13,
          r.bottom - cell * lip - cell * 0.07,
        );
        c.drawRRect(_rr(basin, cell * 0.1), _fill(const Color(0xFF3E4650)));
        c.drawRRect(_rr(basin.deflate(cell * 0.05), cell * 0.08), _fill(PPColor.water.withValues(alpha: 0.85)));
        c.drawOval(
          Rect.fromCenter(
            center: basin.center + Offset(-cell * 0.08, -cell * 0.04),
            width: cell * 0.2,
            height: cell * 0.07,
          ),
          _fill(const Color(0x66FFFFFF)),
        );
        // Tap.
        c.drawRRect(
          _rr(Rect.fromLTWH(r.center.dx - cell * 0.04, r.top + cell * 0.01, cell * 0.08, cell * 0.17), cell * 0.03),
          _fill(PPColor.steelDark),
        );
        c.drawRRect(
          _rr(Rect.fromLTWH(r.center.dx - cell * 0.04, r.top + cell * 0.01, cell * 0.2, cell * 0.06), cell * 0.03),
          _fill(PPColor.steelDark),
        );
      case TileType.rack:
        _counterBase(r);
      case TileType.plateReturn:
        _applianceBase(
          r,
          body: isDark ? const Color(0xFF474952) : PPColor.steelDark,
          bodyDark: isDark ? const Color(0xFF2E3037) : const Color(0xFF5E6A74),
        );
        // Dark chute lit green: dirty plates come back through here.
        final slot = Rect.fromLTRB(
          r.left + cell * 0.16,
          r.top + cell * 0.1,
          r.right - cell * 0.16,
          r.bottom - cell * lip - cell * 0.07,
        );
        c.drawRRect(_rr(slot, cell * 0.06), _fill(const Color(0xFF23222B)));
        final glow = 0.55 + 0.25 * math.sin(t * 2.5);
        c.drawRRect(_rr(slot.deflate(cell * 0.06), cell * 0.04), _fill(PPColor.basil.withValues(alpha: glow)));
        c.drawRRect(
          _rr(slot.deflate(cell * 0.06), cell * 0.04),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.025
            ..color = const Color(0xFFB7F5CC).withValues(alpha: glow),
        );
      case TileType.pass:
        _applianceBase(
          r,
          body: isDark ? const Color(0xFF474952) : PPColor.steelDark,
          bodyDark: isDark ? const Color(0xFF2E3037) : const Color(0xFF5E6A74),
          top: isDark ? const Color(0xFF7A828C) : const Color(0xFFCFD6DC),
        );
        // Serving hatch: dark mat with two white chevrons pointing out.
        final mat = Rect.fromLTRB(
          r.left + cell * 0.12,
          r.top + cell * 0.09,
          r.right - cell * 0.12,
          r.bottom - cell * lip - cell * 0.06,
        );
        c.drawRRect(_rr(mat, cell * 0.06), _fill(const Color(0xFF3A3F47)));
        final chev = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.75 + 0.25 * math.sin(t * 3));
        for (var i = 0; i < 2; i++) {
          final cy = mat.center.dy + cell * (0.12 - i * 0.17);
          final w = cell * 0.17;
          final path = Path()
            ..moveTo(mat.center.dx - w, cy + cell * 0.08)
            ..lineTo(mat.center.dx, cy - cell * 0.04)
            ..lineTo(mat.center.dx + w, cy + cell * 0.08);
          c.drawPath(path, chev);
        }
      case TileType.trash:
        _counterBase(r);
        final bin = Rect.fromLTRB(
          r.left + cell * 0.2,
          r.top + cell * 0.06,
          r.right - cell * 0.2,
          r.bottom - cell * lip - cell * 0.04,
        );
        c.drawRRect(_rr(bin, cell * 0.06), _fill(const Color(0xFF3F4752)));
        c.drawRRect(_rr(bin.deflate(cell * 0.06), cell * 0.04), _fill(const Color(0xFF23222B)));
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

  /// Low brick wall framing the whole kitchen, with a soft ground shadow.
  void frame(Rect board) {
    final wall = board.inflate(cell * 0.22);
    final mortar = isDark ? const Color(0xFF2C2A36) : PPColor.brickDark;
    final brick = isDark ? const Color(0xFF3B3847) : PPColor.brick;
    c.drawRRect(
      _rr(wall.inflate(cell * 0.04).shift(Offset(0, cell * 0.16)), cell * 0.3),
      _fill(const Color(0x00000000).withValues(alpha: isDark ? 0.5 : 0.22)),
    );
    c.drawRRect(_rr(wall, cell * 0.26), _fill(mortar));
    // Brick courses along the wall band, clipped to the band itself.
    c.save();
    c.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(_rr(wall, cell * 0.26))
        ..addRRect(_rr(board, cell * 0.08)),
    );
    final bw = cell * 0.5;
    final bh = cell * 0.22;
    var row = 0;
    for (var y = wall.top; y < wall.bottom; y += bh, row++) {
      final off = row.isOdd ? bw / 2 : 0.0;
      for (var x = wall.left - bw + off; x < wall.right; x += bw) {
        c.drawRRect(
          _rr(Rect.fromLTWH(x + cell * 0.02, y + cell * 0.02, bw - cell * 0.04, bh - cell * 0.04), cell * 0.03),
          _fill(brick),
        );
      }
    }
    c.restore();
    c.drawRRect(
      _rr(wall, cell * 0.26),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.04
        ..color = const Color(0x33FFFFFF),
    );
  }

  /// Brick wall block: mortar background, staggered bricks, a lighter cap.
  void _brick(Rect r) {
    final mortar = isDark ? const Color(0xFF2C2A36) : PPColor.brickDark;
    final brick = isDark ? const Color(0xFF3B3847) : PPColor.brick;
    c.drawRRect(_rr(r.deflate(cell * 0.01), cell * 0.06), _fill(mortar));
    final rows = 3;
    final bh = r.height / rows;
    for (var i = 0; i < rows; i++) {
      final y = r.top + bh * i;
      final offset = i.isOdd ? r.width / 4 : 0.0;
      for (var j = -1; j < 2; j++) {
        final x = r.left + offset + j * (r.width / 2);
        final b = Rect.fromLTWH(x + cell * 0.03, y + cell * 0.03, r.width / 2 - cell * 0.06, bh - cell * 0.06);
        final clipped = b.intersect(r.deflate(cell * 0.03));
        if (clipped.width > 0 && clipped.height > 0) c.drawRRect(_rr(clipped, cell * 0.03), _fill(brick));
      }
    }
    c.drawRect(
      Rect.fromLTWH(r.left + cell * 0.02, r.top + cell * 0.02, r.width - cell * 0.04, cell * 0.05),
      _fill(const Color(0x33FFFFFF)),
    );
  }

  /// Items, fire and progress bubbles on top of a tile.
  void tileContents(Rect r, Tile tile) {
    final it = tile.item;
    final top = Offset(r.center.dx, r.top + cell * 0.34);
    if (it != null) {
      if (tile.type == TileType.conveyor) {
        final d = tile.conveyorDir!;
        final off = (tile.conveyor - 0.5) * cell;
        item(Offset(r.center.dx + d.dx * off, r.center.dy + d.dy * off), it, scale: 0.9);
      } else {
        item(top, it, scale: tile.type == TileType.stove || tile.type == TileType.board ? 1 : 0.92);
      }
    }
    final bubbleAt = Offset(r.center.dx, r.top - cell * 0.2);
    if (tile.progress > 0 && (tile.type == TileType.board || tile.type == TileType.sink)) {
      progressBubble(bubbleAt, tile.progress, tile.type == TileType.sink ? PPColor.water : PPColor.basil);
    }
    if (it is Pot && it.contents.isNotEmpty && !it.burnt) {
      if (it.cook < 1) {
        progressBubble(bubbleAt, it.cook, PPColor.basil);
      } else {
        // Cooked: the bubble turns into a flashing warning as it heads for burnt.
        warningBubble(bubbleAt, it.burn);
      }
    }
    if (tile.onFire) fire(Offset(r.center.dx, r.center.dy), tile.fire);
  }

  /// White speech bubble hanging over a station with a chunky progress bar.
  void progressBubble(Offset center, double f, Color color) {
    final w = cell * 0.78;
    final h = cell * 0.3;
    final box = Rect.fromCenter(center: center, width: w, height: h);
    _bubbleBox(box);
    final bar = Rect.fromLTWH(box.left + cell * 0.07, box.center.dy - cell * 0.06, w - cell * 0.14, cell * 0.12);
    c.drawRRect(_rr(bar, cell * 0.06), _fill(const Color(0xFFD8D3C8)));
    c.drawRRect(
      _rr(Rect.fromLTWH(bar.left, bar.top, bar.width * f.clamp(0, 1), bar.height), cell * 0.06),
      _fill(color),
    );
  }

  /// Cooked-and-waiting indicator: a check that turns into a flashing flame.
  void warningBubble(Offset center, double burn) {
    final danger = burn > 0.5;
    final flash = danger && (t * (burn > 0.8 ? 10 : 5)).floor().isEven;
    final s = cell * 0.17;
    final box = Rect.fromCenter(center: center, width: cell * 0.46, height: cell * 0.4);
    _bubbleBox(box, fill: flash ? PPColor.paprika : const Color(0xFFFFFFFF));
    if (!danger) {
      final tick = Path()
        ..moveTo(center.dx - s * 0.6, center.dy)
        ..lineTo(center.dx - s * 0.15, center.dy + s * 0.45)
        ..lineTo(center.dx + s * 0.65, center.dy - s * 0.5);
      c.drawPath(
        tick,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = PPColor.basil,
      );
      return;
    }
    final col = flash ? const Color(0xFFFFFFFF) : PPColor.paprika;
    final flame = Path()
      ..moveTo(center.dx - s * 0.6, center.dy + s * 0.55)
      ..quadraticBezierTo(center.dx - s * 0.85, center.dy - s * 0.2, center.dx - s * 0.1, center.dy - s * 0.85)
      ..quadraticBezierTo(center.dx + s * 0.05, center.dy - s * 0.3, center.dx + s * 0.35, center.dy - s * 0.55)
      ..quadraticBezierTo(center.dx + s * 0.9, center.dy, center.dx + s * 0.6, center.dy + s * 0.55)
      ..close();
    c.drawPath(flame, _fill(col));
    c.drawCircle(center + Offset(0, s * 0.3), s * 0.28, _fill(flash ? PPColor.paprika : PPColor.butter));
  }

  void _bubbleBox(Rect box, {Color fill = const Color(0xFFFFFFFF)}) {
    final rad = cell * 0.1;
    c.drawRRect(_rr(box.shift(Offset(0, cell * 0.03)), rad), _fill(const Color(0x3A000000)));
    c.drawRRect(_rr(box, rad), _fill(fill));
    final tail = Path()
      ..moveTo(box.center.dx - cell * 0.07, box.bottom - 1)
      ..lineTo(box.center.dx, box.bottom + cell * 0.09)
      ..lineTo(box.center.dx + cell * 0.07, box.bottom - 1)
      ..close();
    c.drawPath(tail, _fill(fill));
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
    const steel = Color(0xFF8FA3B8);
    const steelD = Color(0xFF5C7084);
    const steelL = Color(0xFFC3D2E0);
    c.drawOval(
      Rect.fromCenter(center: at + Offset(0, s * 0.55), width: s * 2.4, height: s * 0.9),
      _fill(const Color(0x44000000)),
    );
    final body = Rect.fromCenter(center: at + Offset(0, s * 0.15), width: s * 2.1, height: s * 1.55);
    c.drawRRect(_rr(body, s * 0.35), _fill(steel));
    c.drawRRect(
      _rr(Rect.fromLTRB(body.left, body.top + s * 0.9, body.right, body.bottom), s * 0.35),
      _fill(steelD.withValues(alpha: 0.5)),
    );
    // Handles.
    for (final dx in [-1.25, 1.25]) {
      c.drawRRect(
        _rr(Rect.fromCenter(center: at + Offset(s * dx, -s * 0.15), width: s * 0.55, height: s * 0.28), s * 0.14),
        _fill(steelD),
      );
    }
    // Rolled rim + contents.
    final rim = Rect.fromCenter(center: at + Offset(0, -s * 0.5), width: s * 2.15, height: s * 0.95);
    Color liquid;
    if (p.burnt) {
      liquid = const Color(0xFF2A211B);
    } else if (p.contents.isEmpty) {
      liquid = steelD;
    } else {
      final d = Dish.match(p.contents, cooked: true);
      final base = d != null ? dishColor(d) : ingredientColor(p.contents.first);
      liquid = Color.lerp(base.withValues(alpha: 0.9), base, p.cook.clamp(0, 1))!;
    }
    c.drawOval(rim, _fill(steelL));
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
    final dark = Color.lerp(col, const Color(0xFF000000), 0.25)!;
    final s = cell * 0.4;
    final bob = moving ? math.sin(t * 16) * s * 0.08 : 0.0;
    final body = at + Offset(0, -s * 0.35 + bob);
    final fd = Offset(ch.facing.dx * 1.0, ch.facing.dy * 1.0);
    final side = fd.dx; // -1 left, 1 right, 0 facing up/down

    // Shadow + local-player ring.
    c.drawOval(
      Rect.fromCenter(center: at + Offset(0, s * 0.85), width: s * 1.9, height: s * 0.7),
      _fill(const Color(0x44000000)),
    );
    if (ch.dash > 0) {
      c.drawCircle(body, s * 1.4, _fill(col.withValues(alpha: 0.25)));
    }
    if (isMe) {
      c.drawOval(
        Rect.fromCenter(center: at + Offset(0, s * 0.85), width: s * 2.3, height: s * 0.95),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.055
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.95),
      );
    }
    // Feet.
    final step = moving ? math.sin(t * 16) * s * 0.18 : 0.0;
    for (final dx in [-0.42, 0.42]) {
      c.drawOval(
        Rect.fromCenter(
          center: body + Offset(dx * s, s * 1.05 + (dx < 0 ? step : -step) * 0.3),
          width: s * 0.5,
          height: s * 0.3,
        ),
        _fill(PPColor.ink),
      );
    }
    // Round body in the chef's colour, white double-breasted front.
    final torso = Rect.fromCenter(center: body + Offset(0, s * 0.45), width: s * 1.75, height: s * 1.45);
    c.drawRRect(_rr(torso, s * 0.6), _fill(col));
    c.drawRRect(
      _rr(Rect.fromLTRB(torso.left, torso.top + s * 0.9, torso.right, torso.bottom), s * 0.55),
      _fill(dark.withValues(alpha: 0.35)),
    );
    if (fd.dy >= 0) {
      final front = Rect.fromCenter(center: body + Offset(side * s * 0.15, s * 0.5), width: s * 0.95, height: s * 1.1);
      c.drawRRect(_rr(front, s * 0.3), _fill(const Color(0xFFFFFFFF)));
      for (final dy in [0.25, 0.55, 0.85]) {
        c.drawCircle(front.topCenter + Offset(0, front.height * dy), s * 0.06, _fill(dark));
      }
    } else {
      // Back view: apron strings.
      c.drawRRect(
        _rr(Rect.fromCenter(center: body + Offset(0, s * 0.35), width: s * 0.9, height: s * 0.12), s * 0.06),
        _fill(const Color(0xFFFFFFFF)),
      );
    }
    // Arms (mitts) swing toward the facing side.
    for (final dx in [-1.0, 1.0]) {
      final ax = body.dx + dx * s * 0.95 + fd.dx * s * 0.15;
      final ay = body.dy + s * 0.5 + fd.dy * s * 0.1;
      c.drawCircle(Offset(ax, ay), s * 0.26, _fill(col));
      c.drawCircle(
        Offset(ax, ay + s * 0.12),
        s * 0.18,
        _fill(ch.bot ? const Color(0xFFCFD4DA) : const Color(0xFFF6C9A0)),
      );
    }
    // Big round head.
    final skin = ch.bot ? const Color(0xFFCFD4DA) : const Color(0xFFF6C9A0);
    final head = body + Offset(side * s * 0.05, -s * 0.55);
    c.drawCircle(head, s * 0.82, _fill(skin));
    if (ch.facing != Dir.up) {
      final eyeY = head.dy + s * 0.05 + fd.dy * s * 0.12;
      final ex = head.dx + fd.dx * s * 0.3;
      final gap = fd.dx == 0 ? 0.26 : 0.2;
      c.drawOval(
        Rect.fromCenter(center: Offset(ex - s * gap, eyeY), width: s * 0.2, height: s * 0.26),
        _fill(PPColor.ink),
      );
      c.drawOval(
        Rect.fromCenter(center: Offset(ex + s * gap, eyeY), width: s * 0.2, height: s * 0.26),
        _fill(PPColor.ink),
      );
      c.drawCircle(Offset(ex - s * gap - s * 0.04, eyeY - s * 0.06), s * 0.05, _fill(const Color(0xFFFFFFFF)));
      c.drawCircle(Offset(ex + s * gap - s * 0.04, eyeY - s * 0.06), s * 0.05, _fill(const Color(0xFFFFFFFF)));
      // Cheeks.
      c.drawCircle(Offset(ex - s * 0.42, eyeY + s * 0.22), s * 0.1, _fill(const Color(0x33E8563F)));
      c.drawCircle(Offset(ex + s * 0.42, eyeY + s * 0.22), s * 0.1, _fill(const Color(0x33E8563F)));
      if (ch.bot) {
        c.drawRRect(
          _rr(Rect.fromCenter(center: Offset(ex, eyeY + s * 0.36), width: s * 0.4, height: s * 0.09), s * 0.04),
          _fill(PPColor.ink),
        );
      } else {
        c.drawArc(
          Rect.fromCenter(center: Offset(ex, eyeY + s * 0.22), width: s * 0.42, height: s * 0.3),
          0.25,
          math.pi - 0.5,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.08
            ..strokeCap = StrokeCap.round
            ..color = PPColor.ink,
        );
      }
    } else {
      // Hair tuft at the back of the head.
      c.drawOval(
        Rect.fromCenter(center: head + Offset(0, s * 0.35), width: s * 1.2, height: s * 0.6),
        _fill(dark.withValues(alpha: 0.55)),
      );
    }
    // Tall puffy toque: band + three lobes.
    final white = const Color(0xFFFFFFFF);
    final shade = const Color(0xFFE4E2EA);
    final bandC = head + Offset(0, -s * 0.62);
    c.drawRRect(_rr(Rect.fromCenter(center: bandC, width: s * 1.5, height: s * 0.42), s * 0.14), _fill(white));
    c.drawRRect(
      _rr(Rect.fromCenter(center: bandC + Offset(0, s * 0.12), width: s * 1.5, height: s * 0.16), s * 0.08),
      _fill(col.withValues(alpha: 0.7)),
    );
    final puff = bandC + Offset(0, -s * 0.55);
    c.drawCircle(puff + Offset(-s * 0.5, s * 0.1), s * 0.5, _fill(shade));
    c.drawCircle(puff + Offset(s * 0.5, s * 0.1), s * 0.5, _fill(shade));
    c.drawCircle(puff + Offset(0, -s * 0.15), s * 0.62, _fill(white));
    c.drawCircle(puff + Offset(-s * 0.45, s * 0.02), s * 0.4, _fill(white));
    c.drawCircle(puff + Offset(s * 0.45, s * 0.02), s * 0.4, _fill(white));
    if (ch.bot) {
      // Antenna marks a server bot.
      c.drawLine(
        puff + Offset(0, -s * 0.7),
        puff + Offset(0, -s * 1.15),
        Paint()
          ..strokeWidth = s * 0.08
          ..color = PPColor.steelDark,
      );
      c.drawCircle(puff + Offset(0, -s * 1.2), s * 0.13, _fill(col));
    }
    // Held item floats in front of the mitts.
    if (held != null) {
      final hp = body + Offset(fd.dx * s * 1.05, s * 0.7 + fd.dy * s * 0.55);
      item(hp, held, scale: 0.8);
    }
    // Working sparkle.
    if (ch.working) {
      final a = t * 12;
      final o = body + Offset(fd.dx * s * 1.5, fd.dy * s * 1.3 + s * 0.4);
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * s * 0.3, s * 0.1, _fill(PPColor.butter));
      c.drawCircle(o - Offset(math.cos(a), math.sin(a)) * s * 0.3, s * 0.08, _fill(const Color(0xFFFFFFFF)));
    }
    // Name tag.
    _label(
      at + Offset(0, s * 1.5),
      ch.name,
      const Color(0xFFFFFFFF),
      bg: col.withValues(alpha: ch.connected ? 0.95 : 0.45),
      scale: 0.9,
    );
    if (!ch.connected) {
      _label(
        at + Offset(0, -s * 3.0),
        'offline',
        const Color(0xFFFFFFFF),
        bg: PPColor.ink.withValues(alpha: 0.8),
        scale: 0.8,
      );
    }
    // Emote bubble.
    if (ch.emote != null && ch.emote! >= 0 && ch.emote! < kEmotes.length) {
      _bubble(body + Offset(s * 1.2, -s * 2.5), kEmotes[ch.emote!], col);
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
