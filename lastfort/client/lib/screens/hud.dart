import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;
import 'package:lastfort_core/lastfort_core.dart';

import '../app/theme.dart';
import '../app/widgets.dart';
import '../game/controls.dart';
import '../game/match_client.dart';
import 'hub_screen.dart';

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

// ------------------------------------------------------------- storm/timer

class StormPanel extends StatelessWidget {
  const StormPanel({super.key, required this.client, required this.compact});
  final MatchClient client;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sim = client.sim;
    final storm = sim.storm;
    final me = client.viewTarget;
    final inStorm = me != null && me.alive && !storm.contains(me.x, me.y);
    final phase = sim.phase;
    String label;
    String value;
    Color accent;
    if (phase == MatchPhase.bus) {
      label = 'BUS LEAVES IN';
      value = _fmt(client.busSecondsLeft);
      accent = LfTokens.teal;
    } else if (storm.finished && !storm.shrinking) {
      label = 'FINAL CIRCLE';
      value = '${storm.damagePerSecond.toStringAsFixed(0)}/s';
      accent = LfTokens.storm;
    } else {
      label = storm.shrinking ? 'STORM CLOSING' : 'STORM MOVES IN';
      value = _fmt(storm.remaining);
      accent = storm.shrinking ? LfTokens.storm : hudMuted;
    }
    final total = storm.shrinking ? storm.current.shrink : storm.current.wait;
    final frac = total <= 0
        ? 0.0
        : (1 - storm.remaining / total).clamp(0.0, 1.0);
    return HudPanel(
      accent: inStorm ? LfTokens.storm : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                inStorm ? Icons.warning_amber_rounded : Icons.cyclone_rounded,
                size: 14,
                color: inStorm ? LfTokens.storm : accent,
              ),
              const SizedBox(width: 6),
              Text(
                inStorm ? 'IN THE STORM' : label,
                style: hudLabel(
                  context,
                  color: inStorm ? LfTokens.storm : hudMuted,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style:
                    (compact
                            ? context.text.headlineSmall
                            : context.text.headlineMedium)
                        ?.copyWith(
                          color: hudText,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          height: 1.1,
                        ),
              ),
              const SizedBox(width: LfTokens.s2),
              Text(
                'PHASE ${storm.phase + 1}/${sim.rules.stormPhases.length}',
                style: hudLabel(context),
              ),
            ],
          ),
          if (phase != MatchPhase.bus) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: compact ? 120 : 160,
              child: LfBar(
                value: frac,
                color: accent,
                height: 4,
                background: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double s) {
    final t = s.ceil();
    return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
  }
}

class PlayersLeftPanel extends StatelessWidget {
  const PlayersLeftPanel({super.key, required this.client});
  final MatchClient client;

  @override
  Widget build(BuildContext context) {
    final me = client.me;
    final kills = me?.stats.kills ?? 0;
    return HudPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Counter(
            icon: Icons.people_alt_rounded,
            value: client.playersLeft,
            label: 'LEFT',
            color: hudText,
          ),
          const SizedBox(width: LfTokens.s3),
          Container(
            width: 1,
            height: 26,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(width: LfTokens.s3),
          _Counter(
            icon: Icons.gps_fixed_rounded,
            value: kills,
            label: 'ELIMS',
            color: LfTokens.ember,
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
      const SizedBox(width: 6),
      Text(
        '$value',
        style: context.text.titleLarge?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: hudLabel(context)),
    ],
  );
}

// ------------------------------------------------------------ vitals

class VitalsPanel extends StatelessWidget {
  const VitalsPanel({super.key, required this.client, required this.compact});
  final MatchClient client;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    if (p == null) return const SizedBox.shrink();
    final w = compact ? 180.0 : 260.0;
    final rules = client.rules;
    return HudPanel(
      padding: const EdgeInsets.all(LfTokens.s3),
      child: SizedBox(
        width: w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _VitalRow(
              icon: Icons.shield_rounded,
              color: LfTokens.shield,
              value: p.shield,
              max: rules.maxShield,
              compact: compact,
            ),
            const SizedBox(height: 6),
            _VitalRow(
              icon: Icons.favorite_rounded,
              color: LfTokens.health,
              value: p.health,
              max: rules.maxHealth,
              compact: compact,
            ),
            if (p.alive && (p.useRemaining > 0 || p.reloadRemaining > 0)) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LfTokens.warning,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.reloadRemaining > 0
                        ? 'RELOADING ${p.reloadRemaining.toStringAsFixed(1)}s'
                        : 'USING ${p.useRemaining.toStringAsFixed(1)}s',
                    style: hudLabel(context, color: LfTokens.warning),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VitalRow extends StatelessWidget {
  const _VitalRow({
    required this.icon,
    required this.color,
    required this.value,
    required this.max,
    required this.compact,
  });
  final IconData icon;
  final Color color;
  final int value;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${icon == Icons.favorite_rounded ? 'Health' : 'Shield'} $value of $max',
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value / max),
              duration: LfTokens.base,
              curve: LfTokens.ease,
              builder: (context, v, _) => LfBar(
                value: v,
                color: color,
                height: compact ? 10 : 14,
                segments: 4,
                background: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: context.text.titleMedium?.copyWith(
                color: hudText,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ hotbar

class HotbarPanel extends StatelessWidget {
  const HotbarPanel({
    super.key,
    required this.client,
    required this.controls,
    required this.compact,
  });
  final MatchClient client;
  final Controls controls;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    if (p == null) return const SizedBox.shrink();
    final selected = p.buildMode ? -1 : p.selectedSlot;
    final size = compact ? 40.0 : 52.0;
    final sel = p.inventory[p.selectedSlot];
    final ammoLabel = sel != null && sel.isWeapon
        ? '${sel.loaded} / ${p.ammo[sel.weapon!.def.ammo] ?? 0}'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact && sel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: HudPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: LfTokens.s3,
                vertical: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sel.label.toUpperCase(),
                    style: hudLabel(
                      context,
                      color: LfTokens.rarity(sel.rarity),
                    ),
                  ),
                  if (ammoLabel != null) ...[
                    const SizedBox(width: LfTokens.s3),
                    Text(
                      ammoLabel,
                      style: context.text.titleMedium?.copyWith(
                        color: hudText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: LfTokens.s3),
                    Text(
                      '×${sel.count}',
                      style: context.text.titleMedium?.copyWith(color: hudText),
                    ),
                  ],
                ],
              ),
            ),
          ),
        HudPanel(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolSlot(
                size: size,
                selected: p.buildMode,
                icon: Icons.handyman_rounded,
                color: LfTokens.wood,
                hint: 'Q',
                label: 'Build tool',
                onTap: () => controls.toggleBuild(),
              ),
              const SizedBox(width: 6),
              for (var i = 0; i < p.inventory.length; i++) ...[
                _ItemSlot(
                  size: size,
                  item: p.inventory[i],
                  selected: selected == i,
                  hint: '${i + 1}',
                  ammo: p.inventory[i]?.isWeapon == true
                      ? p.inventory[i]!.loaded
                      : null,
                  onTap: () => controls.selectSlot(i),
                ),
                if (i < p.inventory.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolSlot extends StatelessWidget {
  const _ToolSlot({
    required this.size,
    required this.selected,
    required this.icon,
    required this.color,
    required this.hint,
    required this.label,
    required this.onTap,
  });
  final double size;
  final bool selected;
  final IconData icon;
  final Color color;
  final String hint;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: LfTokens.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: selected ? color : hudMuted,
                size: size * 0.45,
              ),
            ),
            Positioned(
              top: 2,
              left: 4,
              child: Text(
                hint,
                style: TextStyle(
                  fontSize: 9,
                  color: hudMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({
    required this.size,
    required this.item,
    required this.selected,
    required this.hint,
    required this.onTap,
    this.ammo,
  });
  final double size;
  final Item? item;
  final bool selected;
  final String hint;
  final VoidCallback onTap;
  final int? ammo;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final rar = it == null
        ? Colors.white.withValues(alpha: 0.15)
        : LfTokens.rarity(it.rarity);
    return Semantics(
      button: true,
      selected: selected,
      label: it == null ? 'Empty slot $hint' : '${it.label} slot $hint',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LfTokens.fast,
          width: size,
          height: size,
          transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
          decoration: BoxDecoration(
            gradient: it == null
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      rar.withValues(alpha: 0.45),
                      rar.withValues(alpha: 0.12),
                    ],
                  ),
            color: it == null ? Colors.white.withValues(alpha: 0.04) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : rar.withValues(alpha: it == null ? 1 : 0.8),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: rar.withValues(alpha: 0.5), blurRadius: 12)]
                : null,
          ),
          child: Stack(
            children: [
              if (it != null)
                Center(
                  child: CustomPaint(
                    size: Size.square(size * 0.55),
                    painter: ItemIconPainter(it),
                  ),
                ),
              Positioned(
                top: 2,
                left: 4,
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 9,
                    color: hudMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (it != null)
                Positioned(
                  bottom: 2,
                  right: 4,
                  child: Text(
                    ammo != null ? '$ammo' : '${it.count}',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      color: hudText,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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

// ------------------------------------------------------------ materials/build

class MaterialsPanel extends StatelessWidget {
  const MaterialsPanel({
    super.key,
    required this.client,
    required this.controls,
    required this.compact,
  });
  final MatchClient client;
  final Controls controls;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    if (p == null) return const SizedBox.shrink();
    return HudPanel(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in Material.values) ...[
                _MatChip(
                  material: m,
                  amount: p.materials[m.index],
                  selected: p.buildMode && p.buildMaterial == m,
                  compact: compact,
                  onTap: () => controls.setMaterial(m),
                ),
                if (m != Material.metal) const SizedBox(width: 4),
              ],
            ],
          ),
          if (p.buildMode) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final piece in Piece.values) ...[
                  _PieceChip(
                    piece: piece,
                    selected: p.buildPiece == piece,
                    hint: const ['Z', 'X', 'C', 'V'][piece.index],
                    compact: compact,
                    onTap: () => controls.selectPiece(piece),
                  ),
                  if (piece != Piece.roof) const SizedBox(width: 4),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MatChip extends StatelessWidget {
  const _MatChip({
    required this.material,
    required this.amount,
    required this.selected,
    required this.compact,
    required this.onTap,
  });
  final Material material;
  final int amount;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = switch (material) {
      Material.wood => LfTokens.wood,
      Material.stone => LfTokens.stone,
      Material.metal => LfTokens.metal,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${material.name} $amount',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LfTokens.fast,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: selected
                ? c.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? c : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$amount',
                style: context.text.titleSmall?.copyWith(
                  color: hudText,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceChip extends StatelessWidget {
  const _PieceChip({
    required this.piece,
    required this.selected,
    required this.hint,
    required this.compact,
    required this.onTap,
  });
  final Piece piece;
  final bool selected;
  final String hint;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (piece) {
      Piece.wall => Icons.crop_portrait_rounded,
      Piece.floor => Icons.crop_landscape_rounded,
      Piece.ramp => Icons.signal_cellular_4_bar_rounded,
      Piece.roof => Icons.change_history_rounded,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: piece.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LfTokens.fast,
          width: compact ? 40 : 48,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: selected
                ? LfTokens.ember.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? LfTokens.ember
                  : Colors.white.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? hudText : hudMuted,
                ),
              ),
              Positioned(
                top: 1,
                left: 3,
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 8,
                    color: hudMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ squad

class SquadPanel extends StatelessWidget {
  const SquadPanel({super.key, required this.client});
  final MatchClient client;

  @override
  Widget build(BuildContext context) {
    final me = client.me;
    if (me == null) return const SizedBox.shrink();
    final mates =
        client.sim.players.values
            .where((p) => p.team == me.team && p.id != me.id)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (mates.isEmpty) return const SizedBox.shrink();
    return HudPanel(
      padding: const EdgeInsets.all(LfTokens.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text('SQUAD', style: hudLabel(context)),
          ),
          for (final m in mates)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Semantics(
                label:
                    '${m.name}: ${m.eliminated ? 'eliminated' : '${m.health} health, ${m.shield} shield'}',
                child: Row(
                  children: [
                    Opacity(
                      opacity: m.eliminated ? 0.4 : 1,
                      child: OutfitAvatar(
                        cosmeticById(m.loadout.outfit),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 96,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: context.text.labelLarge?.copyWith(
                                    color: m.eliminated ? hudMuted : hudText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PlatformBadge(m.platform, compact: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (m.eliminated)
                            Text(
                              'ELIMINATED',
                              style: hudLabel(context, color: LfTokens.danger),
                            )
                          else ...[
                            LfBar(
                              value: m.shield / client.rules.maxShield,
                              color: LfTokens.shield,
                              height: 3,
                              background: Colors.white.withValues(alpha: 0.1),
                            ),
                            const SizedBox(height: 2),
                            LfBar(
                              value: m.health / client.rules.maxHealth,
                              color: LfTokens.health,
                              height: 3,
                              background: Colors.white.withValues(alpha: 0.1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ feed

class FeedPanel extends StatelessWidget {
  const FeedPanel({super.key, required this.client, required this.compact});
  final MatchClient client;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final now = client.serverTimeSeconds;
    final entries = client.feed
        .where((e) => now - e.createdAt < 7)
        .take(compact ? 3 : 5)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AnimatedOpacity(
              duration: LfTokens.base,
              opacity: (1 - ((now - e.createdAt - 5) / 2)).clamp(0.0, 1.0),
              child: HudPanel(
                accent: e.highlight ? Color(e.accent) : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: LfTokens.s3,
                  vertical: 5,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 220 : 320),
                  child: Text(
                    e.text,
                    style: context.text.labelLarge?.copyWith(
                      color: e.highlight ? Color(e.accent) : hudText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
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
      borderRadius: BorderRadius.circular(LfTokens.rMd),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xCC0B0F17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(LfTokens.rMd),
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

class CompassStrip extends StatelessWidget {
  const CompassStrip({super.key, required this.client, required this.width});
  final MatchClient client;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    final aim = p?.aim ?? 0;
    return Semantics(
      label: 'Compass heading ${_heading(aim)}',
      child: HudPanel(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: SizedBox(
          width: width,
          height: 22,
          child: CustomPaint(painter: _CompassPainter(aim, client)),
        ),
      ),
    );
  }

  static String _heading(double aim) {
    final deg = ((aim * 180 / math.pi) + 90 + 360) % 360;
    return '${deg.round()} degrees';
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.aim, this.client);
  final double aim;
  final MatchClient client;

  @override
  void paint(Canvas canvas, Size size) {
    final heading = ((aim * 180 / math.pi) + 90 + 360) % 360;
    final pxPerDeg = size.width / 120;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    const labels = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };
    for (var d = -60; d <= 60; d += 15) {
      final deg = ((heading + d) % 360 + 360) % 360;
      final x = size.width / 2 + d * pxPerDeg;
      final major = deg % 45 == 0;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - (major ? 7 : 4)),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.7 : 0.35)
          ..strokeWidth = 1,
      );
      final label = labels[deg.round()];
      if (label != null) {
        tp.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: label == 'N' ? LfTokens.ember : hudText,
            fontFamily: 'Rajdhani',
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));
      }
    }
    // Storm center bearing.
    final me = client.viewTarget;
    if (me != null) {
      final st = client.sim.storm;
      final bearing =
          (math.atan2(st.cy - me.y, st.cx - me.x) * 180 / math.pi + 90 + 360) %
          360;
      var rel = bearing - heading;
      while (rel > 180) {
        rel -= 360;
      }
      while (rel < -180) {
        rel += 360;
      }
      if (rel.abs() <= 60) {
        final x = size.width / 2 + rel * pxPerDeg;
        canvas.drawCircle(
          Offset(x, size.height - 3),
          3,
          Paint()..color = LfTokens.storm,
        );
      }
    }
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = LfTokens.ember
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => true;
}
