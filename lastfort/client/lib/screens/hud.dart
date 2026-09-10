import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;
import 'package:lastfort_core/lastfort_core.dart';

import '../app/theme.dart';
import '../game/match_client.dart';

/// Shared HUD chrome: translucent dark panels readable over any terrain.
class HudPanel extends StatelessWidget {
  const HudPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: LfTokens.s3,
      vertical: LfTokens.s2,
    ),
    this.accent,
    this.radius = LfTokens.rMd,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? accent;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xCC0B0F17),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (accent ?? Colors.white).withValues(
          alpha: accent == null ? 0.12 : 0.55,
        ),
      ),
    ),
    child: Padding(padding: padding, child: child),
  );
}

const hudText = Color(0xFFF3F5F8);
const hudMuted = Color(0xFF9AA5B8);

TextStyle hudLabel(BuildContext context, {Color color = hudMuted}) => context
    .text
    .labelSmall!
    .copyWith(color: color, letterSpacing: 1.6, fontWeight: FontWeight.w700);

/// Procedural icons for item types; colours follow the rarity token.
class ItemIconPainter extends CustomPainter {
  ItemIconPainter(this.item);
  final Item item;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final col = Color(item.rarity.argb);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final dark = Paint()..color = col;
    switch (item.type) {
      case ItemType.weapon:
        final kind = item.weapon!;
        final len = switch (kind) {
          WeaponKind.pistol => 0.55,
          WeaponKind.smg => 0.7,
          WeaponKind.rifle => 0.9,
          WeaponKind.shotgun => 0.85,
          WeaponKind.sniper => 1.0,
        };
        final thick = kind == WeaponKind.shotgun ? 0.16 : 0.11;
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * (0.5 - len / 2), h * 0.42, w * len, h * thick),
          const Radius.circular(2),
        );
        canvas.drawRRect(body, paint);
        canvas.drawRect(
          Rect.fromLTWH(
            w * (0.5 - len / 2) + w * len * 0.35,
            h * 0.42 + h * thick,
            w * 0.1,
            h * 0.25,
          ),
          paint,
        );
        if (kind == WeaponKind.sniper) {
          canvas.drawRect(
            Rect.fromLTWH(w * 0.45, h * 0.32, w * 0.25, h * 0.08),
            paint,
          );
        }
        if (kind == WeaponKind.rifle || kind == WeaponKind.smg) {
          canvas.drawRect(
            Rect.fromLTWH(
              w * (0.5 - len / 2),
              h * 0.42 + h * thick,
              w * 0.12,
              h * 0.16,
            ),
            paint,
          );
        }
      case ItemType.consumable:
        final k = item.consumable!;
        if (k == ConsumableKind.bandage || k == ConsumableKind.medkit) {
          final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.25, w * 0.6, h * 0.5),
            const Radius.circular(3),
          );
          canvas.drawRRect(r, paint);
          final cross = Paint()..color = LfTokens.health;
          canvas.drawRect(
            Rect.fromLTWH(w * 0.45, h * 0.32, w * 0.1, h * 0.36),
            cross,
          );
          canvas.drawRect(
            Rect.fromLTWH(w * 0.32, h * 0.45, w * 0.36, h * 0.1),
            cross,
          );
        } else {
          final bottle = Path()
            ..moveTo(w * 0.42, h * 0.15)
            ..lineTo(w * 0.58, h * 0.15)
            ..lineTo(w * 0.58, h * 0.3)
            ..lineTo(w * 0.68, h * 0.4)
            ..lineTo(w * 0.68, h * 0.85)
            ..lineTo(w * 0.32, h * 0.85)
            ..lineTo(w * 0.32, h * 0.4)
            ..lineTo(w * 0.42, h * 0.3)
            ..close();
          canvas.drawPath(
            bottle,
            Paint()
              ..color = LfTokens.shield.withValues(
                alpha: k == ConsumableKind.bigShield ? 1 : 0.7,
              ),
          );
          canvas.drawRect(
            Rect.fromLTWH(w * 0.36, h * 0.5, w * 0.28, h * 0.25),
            paint..color = Colors.white.withValues(alpha: 0.5),
          );
        }
      case ItemType.ammo:
        for (var i = 0; i < 3; i++) {
          final x = w * (0.3 + i * 0.2);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x - w * 0.06, h * 0.3, w * 0.12, h * 0.45),
              const Radius.circular(2),
            ),
            paint,
          );
          canvas.drawCircle(
            Offset(x, h * 0.3),
            w * 0.06,
            dark..color = LfTokens.warning,
          );
        }
      case ItemType.material:
        final m = item.material!;
        final c = switch (m) {
          Material.wood => LfTokens.wood,
          Material.stone => LfTokens.stone,
          Material.metal => LfTokens.metal,
        };
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.6, h * 0.4),
            const Radius.circular(3),
          ),
          Paint()..color = c,
        );
    }
  }

  @override
  bool shouldRepaint(covariant ItemIconPainter old) => old.item != item;
}

// ------------------------------------------------------------ minimap/compass

class Minimap extends StatelessWidget {
  const Minimap({super.key, required this.client, required this.size});
  final MatchClient client;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Minimap',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xD90B0F17),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(painter: _MinimapPainter(client)),
      ),
    ),
  );
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.client);
  final MatchClient client;

  @override
  void paint(Canvas canvas, Size size) {
    final sim = client.sim;
    final rules = sim.rules;
    final s = size.width / rules.mapSize;
    final world = sim.world;
    final n = world.n;
    final step = math.max(1, n ~/ 40);
    final cell = size.width / (n / step);
    final p = Paint();
    for (var gy = 0; gy < n; gy += step) {
      for (var gx = 0; gx < n; gx += step) {
        final t = world.terrainAt(gx, gy);
        if (t == Terrain.water) continue;
        p.color = switch (t) {
          Terrain.sand => const Color(0xFF8E8460),
          Terrain.grass => const Color(0xFF4A7A3E),
          Terrain.meadow => const Color(0xFF5E8F45),
          Terrain.dirt => const Color(0xFF6E5B41),
          Terrain.road => const Color(0xFF55595F),
          Terrain.rock => const Color(0xFF6B7078),
          Terrain.water => Colors.transparent,
        };
        canvas.drawRect(
          Rect.fromLTWH(
            gx / step * cell,
            gy / step * cell,
            cell + 0.5,
            cell + 0.5,
          ),
          p,
        );
      }
    }
    // Storm: outside area shaded, ring drawn.
    final storm = sim.storm;
    final full = Path()..addRect(Offset.zero & size);
    final safe = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(storm.cx * s, storm.cy * s),
          radius: storm.radius * s,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, safe),
      Paint()..color = LfTokens.storm.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(storm.cx * s, storm.cy * s),
      storm.radius * s,
      Paint()
        ..color = LfTokens.storm
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    if (storm.targetRadius < storm.radius - 1) {
      canvas.drawCircle(
        Offset(storm.targetX * s, storm.targetY * s),
        storm.targetRadius * s,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    // Bus path.
    if (sim.phase == MatchPhase.bus) {
      canvas.drawLine(
        Offset(sim.busX0 * s, sim.busY0 * s),
        Offset(sim.busX1 * s, sim.busY1 * s),
        Paint()
          ..color = LfTokens.teal.withValues(alpha: 0.6)
          ..strokeWidth = 1.5,
      );
      final b = sim.busPosition();
      canvas.drawCircle(
        Offset(b.x * s, b.y * s),
        3.5,
        Paint()..color = LfTokens.teal,
      );
    }
    // Teammates and self.
    final me = client.me;
    for (final pl in sim.players.values) {
      if (me == null || pl.team != me.team || pl.eliminated) continue;
      final self = pl.id == me.id;
      final o = Offset(pl.x * s, pl.y * s);
      canvas.drawCircle(
        o,
        self ? 4 : 3,
        Paint()..color = self ? Colors.white : LfTokens.teal,
      );
      if (self) {
        final dir = Offset(math.cos(pl.aim), math.sin(pl.aim));
        canvas.drawLine(
          o,
          o + dir * 8,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter old) => true;
}
