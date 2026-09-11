import 'package:flutter/material.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../game/sprites.dart';
import '../theme/tokens.dart';

/// Miniature static rendering of a level layout for level select cards.
class LevelPreview extends StatelessWidget {
  const LevelPreview({super.key, required this.level, this.isDark = false});
  final LevelDef level;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: level.width / level.height,
      child: CustomPaint(painter: _Painter(level, isDark)),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.level, this.isDark) : state = GameState(level, playerCount: 4);
  final LevelDef level;
  final bool isDark;
  final GameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / level.width;
    final sp = Sprites(canvas, cell, 0, isDark: isDark);
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final tile = state.baseTile(x, y)!;
        final r = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        if (tile.type == TileType.pit) {
          sp.pitBase(r);
          sp.pitRipple(r, x, y);
        } else {
          sp.floor(r, x, y);
        }
      }
    }
    for (var i = 0; i < level.movers.length; i++) {
      final m = level.movers[i];
      for (var yy = 0; yy < m.height; yy++) {
        for (var xx = 0; xx < m.width; xx++) {
          final tile = state.moverTiles[i][yy * m.width + xx];
          final r = Rect.fromLTWH((m.x + xx) * cell, (m.y + yy) * cell, cell, cell);
          sp.platform(r, first: xx == 0, last: xx == m.width - 1, top: yy == 0, bottom: yy == m.height - 1);
          if (tile.type != TileType.platform) sp.station(r, tile);
          sp.tileContents(r, tile);
        }
      }
    }
    for (var y = 0; y < level.height; y++) {
      for (var x = 0; x < level.width; x++) {
        final tile = state.baseTile(x, y)!;
        if (tile.type == TileType.floor || tile.type == TileType.pit) continue;
        final r = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        sp.station(r, tile);
        sp.tileContents(r, tile);
      }
    }
    for (final e in state.spawns.entries) {
      final c = Offset(e.value.$1 * cell, e.value.$2 * cell);
      canvas.drawCircle(c, cell * 0.28, Paint()..color = PPColor.chefs[e.key % 4]);
      canvas.drawCircle(
        c,
        cell * 0.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => old.level != level || old.isDark != isDark;
}
