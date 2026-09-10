import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;
import 'package:lastfort_core/lastfort_core.dart';

import '../app/theme.dart';
import '../app/widgets.dart';
import '../game/controls.dart';
import '../game/match_client.dart';
import 'hub_screen.dart';
import 'hud.dart';

/// Battle-royale HUD blocks laid out the way players expect from the genre:
/// compass across the top, minimap + storm + counters top-right, feed on the
/// left, squad + vitals bottom-left, materials + hotbar bottom-right.
///
/// Panels are borderless translucent slabs with a slight forward lean; digits
/// are heavy and tabular so values do not jitter as they change.

const _slab = Color(0xB80B0F17);
const _slabStrong = Color(0xD90B0F17);

TextStyle hudDigits(
  double size, {
  Color color = hudText,
  FontWeight weight = FontWeight.w700,
}) => TextStyle(
  fontFamily: 'Rajdhani',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
  shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
);

TextStyle hudCaps(
  double size, {
  Color color = hudMuted,
  FontWeight weight = FontWeight.w700,
}) => TextStyle(
  fontFamily: 'Rajdhani',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1,
  letterSpacing: 1.4,
  shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
);

/// Slab with parallelogram ends (the "lean" used by every HUD block).
class HudSlab extends StatelessWidget {
  const HudSlab({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.strong = false,
    this.accent,
    this.lean = 0.18,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool strong;
  final Color? accent;
  final double lean;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SlabPainter(
      color: strong ? _slabStrong : _slab,
      accent: accent,
      lean: lean,
    ),
    child: Padding(padding: padding, child: child),
  );
}

class _SlabPainter extends CustomPainter {
  _SlabPainter({required this.color, required this.accent, required this.lean});
  final Color color;
  final Color? accent;
  final double lean;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height * lean;
    final path = Path()
      ..moveTo(k, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - k, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    final a = accent;
    if (a != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = a
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SlabPainter old) =>
      old.color != color || old.accent != accent || old.lean != lean;
}

// ------------------------------------------------------------ top-right

/// Minimap with the storm timer and the alive/eliminations counters stacked
/// beneath it, all right-aligned to the minimap's edge.
class TopRightCluster extends StatelessWidget {
  const TopRightCluster({
    super.key,
    required this.client,
    required this.compact,
  });
  final MatchClient client;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mapSize = compact ? 112.0 : 168.0;
    final sim = client.sim;
    final storm = sim.storm;
    final me = client.viewTarget;
    final inStorm = me != null && me.alive && !storm.contains(me.x, me.y);
    final phase = sim.phase;
    final String label;
    final String value;
    Color accent = hudText;
    if (phase == MatchPhase.bus) {
      label = 'BUS LEAVES IN';
      value = _fmt(client.busSecondsLeft);
      accent = LfTokens.teal;
    } else if (storm.finished && !storm.shrinking) {
      label = 'FINAL CIRCLE';
      value = '${storm.damagePerSecond.toStringAsFixed(0)}/s';
      accent = LfTokens.storm;
    } else {
      label = storm.shrinking ? 'STORM SHRINKING' : 'STORM SHRINKS IN';
      value = _fmt(storm.remaining);
      if (storm.shrinking) accent = LfTokens.storm;
    }
    final total = storm.shrinking ? storm.current.shrink : storm.current.wait;
    final frac = total <= 0
        ? 0.0
        : (1 - storm.remaining / total).clamp(0.0, 1.0);
    final kills = client.me?.stats.kills ?? 0;
    final digits = compact ? 18.0 : 22.0;

    return SizedBox(
      width: mapSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Minimap(client: client, size: mapSize),
          const SizedBox(height: 4),
          Semantics(
            label: '$label $value',
            child: HudSlab(
              accent: inStorm ? LfTokens.storm : null,
              padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        inStorm
                            ? Icons.warning_amber_rounded
                            : Icons.cyclone_rounded,
                        size: compact ? 14 : 16,
                        color: inStorm ? LfTokens.storm : accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          inStorm ? 'IN THE STORM' : label,
                          style: hudCaps(
                            compact ? 9 : 10,
                            color: inStorm ? LfTokens.storm : hudMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(value, style: hudDigits(digits, color: accent)),
                    ],
                  ),
                  if (phase != MatchPhase.bus) ...[
                    const SizedBox(height: 5),
                    LfBar(
                      value: frac,
                      color: accent == hudText ? LfTokens.stormDeep : accent,
                      height: 3,
                      radius: 1,
                      background: Colors.white.withValues(alpha: 0.14),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _CounterSlab(
                  icon: Icons.people_alt_rounded,
                  value: client.playersLeft,
                  semantics: 'players left',
                  size: digits,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _CounterSlab(
                  icon: Icons.gps_fixed_rounded,
                  value: kills,
                  semantics: 'eliminations',
                  size: digits,
                  color: kills > 0 ? LfTokens.ember : hudText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double s) {
    final t = s.ceil();
    return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
  }
}

class _CounterSlab extends StatelessWidget {
  const _CounterSlab({
    required this.icon,
    required this.value,
    required this.semantics,
    required this.size,
    this.color = hudText,
  });
  final IconData icon;
  final int value;
  final String semantics;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $semantics',
    child: HudSlab(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: size * 0.7, color: hudMuted),
          const SizedBox(width: 6),
          Text('$value', style: hudDigits(size, color: color)),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------ vitals

/// Shield over health, numbers in a dark block on the left, bars running
/// right — the layout every BR player reads at a glance.
class VitalsPanel extends StatelessWidget {
  const VitalsPanel({super.key, required this.client, required this.compact});
  final MatchClient client;
  final bool compact;

  static double widthFor(bool compact) => compact ? 200 : 300;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    if (p == null) return const SizedBox.shrink();
    final rules = client.rules;
    final w = widthFor(compact);
    final busy = p.alive && (p.useRemaining > 0 || p.reloadRemaining > 0);
    return SizedBox(
      width: w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
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
                    style: hudCaps(10, color: LfTokens.warning),
                  ),
                ],
              ),
            ),
          _VitalBar(
            label: 'Shield',
            color: LfTokens.shield,
            value: p.shield,
            max: rules.maxShield,
            height: compact ? 8 : 10,
            digits: compact ? 15 : 17,
            faint: p.shield == 0,
          ),
          const SizedBox(height: 3),
          _VitalBar(
            label: 'Health',
            color: p.health <= rules.maxHealth * 0.3
                ? LfTokens.danger
                : LfTokens.health,
            value: p.health,
            max: rules.maxHealth,
            height: compact ? 14 : 18,
            digits: compact ? 20 : 24,
          ),
        ],
      ),
    );
  }
}

class _VitalBar extends StatelessWidget {
  const _VitalBar({
    required this.label,
    required this.color,
    required this.value,
    required this.max,
    required this.height,
    required this.digits,
    this.faint = false,
  });
  final String label;
  final Color color;
  final int value;
  final int max;
  final double height;
  final double digits;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final block = digits * 2.3;
    return Semantics(
      label: '$label $value of $max',
      child: Opacity(
        opacity: faint ? 0.55 : 1,
        child: HudSlab(
          padding: EdgeInsets.zero,
          lean: 0.35,
          child: SizedBox(
            height: height + 8,
            child: Row(
              children: [
                SizedBox(
                  width: block,
                  child: Center(
                    child: Text(
                      '$value',
                      style: hudDigits(digits, color: faint ? hudMuted : color),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: max == 0 ? 0 : value / max),
                      duration: LfTokens.base,
                      curve: LfTokens.ease,
                      builder: (context, v, _) => LfBar(
                        value: v,
                        color: color,
                        height: height,
                        radius: 1,
                        background: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ squad

/// Teammates stacked directly above the player's own bars.
class SquadPanel extends StatelessWidget {
  const SquadPanel({super.key, required this.client, required this.compact});
  final MatchClient client;
  final bool compact;

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
    final w = VitalsPanel.widthFor(compact) * (compact ? 0.9 : 0.78);
    return SizedBox(
      width: w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in mates)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Semantics(
                label:
                    '${m.name}: ${m.eliminated ? 'eliminated' : '${m.health} health, ${m.shield} shield'}',
                child: HudSlab(
                  padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                  lean: 0.22,
                  child: Row(
                    children: [
                      Opacity(
                        opacity: m.eliminated ? 0.35 : 1,
                        child: OutfitAvatar(
                          cosmeticById(m.loadout.outfit),
                          size: compact ? 22 : 28,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.name.toUpperCase(),
                                    style: hudCaps(
                                      compact ? 10 : 12,
                                      color: m.eliminated ? hudMuted : hudText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  PlatformBadge.describe(m.platform).$2,
                                  size: 11,
                                  color: hudMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (m.eliminated)
                              Text(
                                'ELIMINATED',
                                style: hudCaps(9, color: LfTokens.danger),
                              )
                            else ...[
                              LfBar(
                                value: m.shield / client.rules.maxShield,
                                color: LfTokens.shield,
                                height: 3,
                                radius: 1,
                                background: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              LfBar(
                                value: m.health / client.rules.maxHealth,
                                color: LfTokens.health,
                                height: 4,
                                radius: 1,
                                background: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ hotbar

/// Tool slot plus five item slots; the selected slot lifts and gets a white
/// frame, rarity tints the slot, ammo/count sits bottom-right.
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

  static double widthFor(bool compact) => compact ? 296 : 396;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    if (p == null) return const SizedBox.shrink();
    final selected = p.buildMode ? -1 : p.selectedSlot;
    final size = compact ? 42.0 : 56.0;
    final sel = p.inventory[p.selectedSlot];
    final reserve = sel != null && sel.isWeapon
        ? (p.ammo[sel.weapon!.def.ammo] ?? 0)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sel != null && !p.buildMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  sel.label.toUpperCase(),
                  style: hudCaps(
                    compact ? 11 : 13,
                    color: LfTokens.rarity(sel.rarity),
                  ),
                ),
                const SizedBox(width: 10),
                if (reserve != null) ...[
                  Text('${sel.loaded}', style: hudDigits(compact ? 20 : 26)),
                  Text(
                    ' / $reserve',
                    style: hudDigits(compact ? 13 : 15, color: hudMuted),
                  ),
                ] else
                  Text('×${sel.count}', style: hudDigits(compact ? 18 : 22)),
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ToolSlot(
              size: size,
              selected: p.buildMode,
              hint: 'Q',
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
              if (i < p.inventory.length - 1) const SizedBox(width: 3),
            ],
          ],
        ),
      ],
    );
  }
}

class _ToolSlot extends StatelessWidget {
  const _ToolSlot({
    required this.size,
    required this.selected,
    required this.hint,
    required this.onTap,
  });
  final double size;
  final bool selected;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Build tool',
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: LfTokens.fast,
        width: size * 0.82,
        height: size,
        transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: selected ? LfTokens.teal.withValues(alpha: 0.3) : _slab,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.handyman_rounded,
                color: selected ? Colors.white : hudMuted,
                size: size * 0.42,
              ),
            ),
            Positioned(
              top: 2,
              left: 4,
              child: Text(hint, style: hudCaps(9, color: hudMuted)),
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
        ? const Color(0xFF2A3346)
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
          transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
          decoration: BoxDecoration(
            gradient: it == null
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [rar, Color.lerp(rar, Colors.black, 0.45)!],
                  ),
            color: it == null ? _slab : null,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0),
              width: 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (it != null)
                Center(
                  child: CustomPaint(
                    size: Size.square(size * 0.58),
                    painter: ItemIconPainter(it),
                  ),
                ),
              Positioned(
                top: 2,
                left: 4,
                child: Text(
                  hint,
                  style: hudCaps(
                    9,
                    color: it == null ? hudMuted : Colors.white70,
                  ),
                ),
              ),
              if (it != null)
                Positioned(
                  bottom: 2,
                  right: 4,
                  child: Text(
                    ammo != null ? '$ammo' : '${it.count}',
                    style: hudDigits(size * 0.24, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ materials

/// Wood / stone / metal totals (and the piece picker while building), stacked
/// above the hotbar and right-aligned with it.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (p.buildMode) ...[
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
                if (piece != Piece.roof) const SizedBox(width: 3),
              ],
            ],
          ),
          const SizedBox(height: 4),
        ],
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
              if (m != Material.metal) const SizedBox(width: 3),
            ],
          ],
        ),
      ],
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
    final c = LfTokens.material(material);
    return Semantics(
      button: true,
      selected: selected,
      label: '${material.name} $amount',
      child: GestureDetector(
        onTap: onTap,
        child: HudSlab(
          accent: selected ? c : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size.square(compact ? 12 : 14),
                painter: _MaterialGlyph(material),
              ),
              const SizedBox(width: 6),
              Text(
                '$amount',
                style: hudDigits(compact ? 14 : 17, color: hudText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialGlyph extends CustomPainter {
  _MaterialGlyph(this.material);
  final Material material;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = LfTokens.material(material);
    final paint = Paint()..color = c;
    switch (material) {
      case Material.wood:
        for (var i = 0; i < 3; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(0, h * (0.05 + i * 0.33), w, h * 0.26),
              const Radius.circular(1),
            ),
            paint,
          );
        }
      case Material.stone:
        final rows = [
          [0.0, 0.55],
          [0.3, 0.7],
          [0.0, 0.55],
        ];
        for (var r = 0; r < rows.length; r++) {
          var x = rows[r][0] == 0.0 ? 0.0 : -w * 0.3;
          while (x < w) {
            final bw = w * 0.55;
            canvas.drawRect(
              Rect.fromLTWH(
                math.max(0, x),
                h * (0.05 + r * 0.33),
                math.min(bw - (x < 0 ? -x : 0), w - math.max(0, x)),
                h * 0.26,
              ),
              paint,
            );
            x += bw + w * 0.08;
          }
        }
      case Material.metal:
        final bar = Path()
          ..moveTo(w * 0.1, h * 0.25)
          ..lineTo(w * 0.9, h * 0.25)
          ..lineTo(w, h * 0.5)
          ..lineTo(w * 0.9, h * 0.75)
          ..lineTo(w * 0.1, h * 0.75)
          ..lineTo(0, h * 0.5)
          ..close();
        canvas.drawPath(bar, paint);
        canvas.drawLine(
          Offset(w * 0.15, h * 0.4),
          Offset(w * 0.85, h * 0.4),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..strokeWidth = 1,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MaterialGlyph old) => old.material != material;
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
            color: selected ? LfTokens.teal.withValues(alpha: 0.3) : _slab,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0),
              width: 2,
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
                child: Text(hint, style: hudCaps(8, color: hudMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ feed

/// Elimination / pickup feed: left side, newest on top, entries fade out.
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: AnimatedOpacity(
              duration: LfTokens.base,
              opacity: (1 - ((now - e.createdAt - 5) / 2)).clamp(0.0, 1.0),
              child: HudSlab(
                accent: e.highlight ? Color(e.accent) : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 220 : 320),
                  child: Text(
                    e.text,
                    style: hudCaps(
                      compact ? 11 : 13,
                      color: e.highlight ? Color(e.accent) : hudText,
                      weight: FontWeight.w600,
                    ).copyWith(letterSpacing: 0.4),
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

// ------------------------------------------------------------ compass

/// Borderless compass strip across the top: cardinals, 15° ticks, storm
/// bearing marker and the numeric heading under the centre pip.
class CompassStrip extends StatelessWidget {
  const CompassStrip({super.key, required this.client, required this.width});
  final MatchClient client;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = client.viewTarget;
    final aim = p?.aim ?? 0;
    return Semantics(
      label: 'Compass heading ${headingDegrees(aim).round()} degrees',
      child: SizedBox(
        width: width,
        height: 34,
        child: CustomPaint(painter: _CompassPainter(aim, client)),
      ),
    );
  }

  static double headingDegrees(double aim) =>
      ((aim * 180 / math.pi) + 90 + 360) % 360;
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.aim, this.client);
  final double aim;
  final MatchClient client;

  @override
  void paint(Canvas canvas, Size size) {
    final heading = CompassStrip.headingDegrees(aim);
    final span = 90.0;
    final pxPerDeg = size.width / span;
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
    // Fade the strip toward both ends.
    final fade = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.15, 0.85, 1],
      ).createShader(Offset.zero & size);
    canvas.saveLayer(Offset.zero & size, Paint());
    const shadow = [Shadow(color: Color(0xCC000000), blurRadius: 4)];
    final baseline = size.height - 8;
    final start = (heading - span / 2).floor();
    for (var d = start - (start % 5); d <= heading + span / 2; d += 5) {
      final deg = ((d % 360) + 360) % 360;
      final x = size.width / 2 + (d - heading) * pxPerDeg;
      final major = deg % 45 == 0;
      final mid = deg % 15 == 0;
      canvas.drawLine(
        Offset(x, baseline),
        Offset(x, baseline - (major ? 8 : (mid ? 5 : 3))),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.9 : 0.45)
          ..strokeWidth = major ? 1.5 : 1,
      );
      final label = labels[deg];
      if (label != null) {
        tp.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: label == 'N' ? LfTokens.ember : hudText,
            fontFamily: 'Rajdhani',
            shadows: shadow,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));
      } else if (deg % 15 == 0) {
        tp.text = TextSpan(
          text: '$deg',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: hudMuted,
            fontFamily: 'Rajdhani',
            shadows: shadow,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 4));
      }
    }
    // Storm centre bearing marker.
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
      if (rel.abs() <= span / 2) {
        final x = size.width / 2 + rel * pxPerDeg;
        final tri = Path()
          ..moveTo(x, baseline + 2)
          ..lineTo(x - 4, baseline + 8)
          ..lineTo(x + 4, baseline + 8)
          ..close();
        canvas.drawPath(tri, Paint()..color = LfTokens.storm);
      }
    }
    canvas.drawRect(Offset.zero & size, fade..blendMode = BlendMode.dstIn);
    canvas.restore();
    // Centre pip.
    final cx = size.width / 2;
    final pip = Path()
      ..moveTo(cx, baseline - 12)
      ..lineTo(cx - 4, baseline - 18)
      ..lineTo(cx + 4, baseline - 18)
      ..close();
    canvas.drawPath(pip, Paint()..color = LfTokens.ember);
    canvas.drawLine(
      Offset(cx, baseline - 11),
      Offset(cx, baseline),
      Paint()
        ..color = LfTokens.ember
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => true;
}
