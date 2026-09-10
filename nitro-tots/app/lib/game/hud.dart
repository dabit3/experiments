import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';

import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';
import 'kart_art.dart';
import 'session.dart';
import 'track_art.dart';

/// Heads-up display drawn over the game canvas. Rebuilds every frame via a
/// ticker owned by the race screen; keeps its widgets cheap.
///
/// Layout follows the classic kart-racer arrangement: item slot top-left,
/// lap counter and clock top-right, large position numeral bottom-left,
/// minimap bottom-right, countdown and status text centred.
class RaceHud extends StatelessWidget {
  const RaceHud({super.key, required this.session, required this.art, required this.compact, this.rttMs, this.bottomInset = 0});

  final RaceSession session;
  final TrackArt art;
  final bool compact;
  final int? rttMs;

  /// Height reserved at the bottom for on-screen touch controls so the
  /// position badge and minimap sit above them instead of underneath.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final sim = session.sim;
    final me = session.local;
    final info = session.info;
    final isBattle = info.mode == GameMode.battle;
    final pad = compact ? 10.0 : 16.0;

    final lapOrTimer = isBattle
        ? _Pill(
            icon: Icons.timer_rounded,
            label: 'TIME',
            value: _mmss(sim.battleTicksLeft),
            color: sim.battleTicksLeft < 10 * ticksPerSecond ? NtColors.nitro : NtColors.sky,
            compact: compact,
          )
        : _Pill(
            icon: Icons.flag_rounded,
            label: 'LAP',
            value: '${math.min(info.laps, (me?.lap ?? 0) + 1)}/${info.laps}',
            color: (me?.lap ?? 0) >= info.laps - 1 ? NtColors.nitro : NtColors.sunny,
            compact: compact,
          );

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Stack(
          children: [
            // Top-left: item slot.
            Positioned(
              left: 0,
              top: 0,
              child: _ItemSlot(racer: me, compact: compact),
            ),
            // Top-right: lap counter, clock, ping.
            Positioned(
              right: 0,
              top: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  lapOrTimer,
                  if (!isBattle) ...[
                    const SizedBox(height: 6),
                    _Clock(
                      ticks: me != null && me.finished ? me.raceTicks : math.max(0, sim.tick - countdownTicks),
                      compact: compact,
                      splits: me?.lapTicks ?? const [],
                    ),
                  ],
                  if (info.online && rttMs != null) ...[
                    const SizedBox(height: 6),
                    _Pill(label: 'PING', value: '${rttMs}ms', color: rttMs! > 150 ? NtColors.nitro : NtColors.mint, compact: true),
                  ],
                ],
              ),
            ),
            // Bottom-left: big position numeral + speed.
            if (me != null)
              Positioned(
                left: 0,
                bottom: bottomInset,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PositionBadge(place: me.position, total: sim.racers.length, compact: compact, battle: isBattle, score: me.score, balloons: me.balloons),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _Speedo(racer: me, compact: compact),
                    ),
                  ],
                ),
              ),
            // Bottom-right: minimap.
            Positioned(
              right: 0,
              bottom: bottomInset + (compact ? 0 : 4),
              child: Minimap(session: session, art: art, size: compact ? 96 : 150),
            ),
            // Centre: countdown / wrong way / finish.
            Positioned.fill(
              child: Center(
                child: _CentreText(session: session, compact: compact),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _mmss(int ticks) {
    final s = (ticks / ticksPerSecond).ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

/// Large outlined place numeral with a small ordinal suffix, coloured by
/// place. In battle mode it shows the score and remaining balloons instead.
class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.place, required this.total, required this.compact, required this.battle, required this.score, required this.balloons});
  final int place;
  final int total;
  final bool compact;
  final bool battle;
  final int score;
  final int balloons;

  @override
  Widget build(BuildContext context) {
    final color = battle ? NtColors.bubblegum : placeColor(place);
    final value = battle ? '$score' : '$place';
    final suffix = battle ? 'PTS' : ordinal(place).substring(value.length);
    final big = compact ? 64.0 : 96.0;
    final small = compact ? 18.0 : 26.0;
    return Semantics(
      label: battle ? '$score points, $balloons balloons' : '${ordinal(place)} of $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (battle)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.circle, size: compact ? 12 : 16, color: i < balloons ? NtColors.bubblegum : Colors.white.withValues(alpha: 0.3)),
                    ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedText(value, size: big, fill: color, stroke: NtColors.inkDark, strokeWidth: compact ? 5 : 7),
              Padding(
                padding: EdgeInsets.only(top: compact ? 6 : 10, left: 2),
                child: OutlinedText(suffix, size: small, fill: Colors.white, stroke: NtColors.inkDark, strokeWidth: compact ? 3 : 4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Display text with a solid outline, the HUD's signature lettering.
class OutlinedText extends StatelessWidget {
  const OutlinedText(this.text, {super.key, required this.size, required this.fill, required this.stroke, required this.strokeWidth, this.letterSpacing = 0});
  final String text;
  final double size;
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: NtType.displayFont, fontSize: size, height: 1, fontWeight: FontWeight.w700, letterSpacing: letterSpacing);
    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))],
          ),
        ),
        Text(text, style: base.copyWith(color: fill)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color, required this.compact, this.icon});
  final String label;
  final String value;
  final Color color;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: NtColors.inkDark.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(NtRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: compact ? 16 : 20, color: color), const SizedBox(width: 6)],
          Text(label, style: NtType.caption(color)),
          const SizedBox(width: 8),
          Text(value, style: NtType.hud(Colors.white, size: compact ? 18 : 24)),
        ],
      ),
    );
  }
}

/// Race clock with the completed lap splits listed underneath.
class _Clock extends StatelessWidget {
  const _Clock({required this.ticks, required this.compact, required this.splits});
  final int ticks;
  final bool compact;
  final List<int> splits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: NtColors.inkDark.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(NtRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatTicks(ticks),
            style: NtType.hud(Colors.white, size: compact ? 18 : 24).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (!compact)
            for (final (i, t) in splits.indexed) Text('L${i + 1}  ${formatTicks(t)}', style: NtType.mono(Colors.white.withValues(alpha: 0.6), size: 11)),
        ],
      ),
    );
  }
}

/// Item slot: rounded frame that shows the held item, or a vertical roulette
/// of items scrolling past while one is being decided.
class _ItemSlot extends StatelessWidget {
  const _ItemSlot({required this.racer, required this.compact});
  final Racer? racer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 72.0 : 100.0;
    final r = racer;
    final rolling = r != null && r.rouletteTicks > 0;
    final item = r?.item;
    final kinds = ItemKind.values;
    final idx = rolling ? (r.rouletteTicks ~/ 3) % kinds.length : 0;
    final frac = rolling ? (r.rouletteTicks % 3) / 3 : 0.0;
    final label = item == null && !rolling ? 'No item' : (rolling ? 'Rolling item' : '${item!.label}${(r?.itemCharges ?? 1) > 1 ? ' x${r!.itemCharges}' : ''}');
    final accent = item != null && !rolling ? KartArt.itemColor(item) : Colors.white.withValues(alpha: 0.2);
    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: NtMotion.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NtColors.inkDark.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: accent, width: 4),
          boxShadow: item != null && !rolling ? NtElevation.glow(accent) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28 - 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: EdgeInsets.all(size * 0.1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                ),
              ),
              if (rolling)
                for (var k = -1; k <= 1; k++)
                  Transform.translate(
                    offset: Offset(0, (k + frac) * size * 0.62),
                    child: Opacity(
                      opacity: k == 0 ? 0.9 : 0.35,
                      child: CustomPaint(painter: _ItemPainter(kinds[(idx + k) % kinds.length], 1), size: Size.square(size * 0.62)),
                    ),
                  )
              else if (item != null)
                CustomPaint(painter: _ItemPainter(item, r?.itemCharges ?? 1), size: Size.square(size * 0.8))
              else
                Icon(Icons.help_outline_rounded, color: Colors.white.withValues(alpha: 0.18), size: size * 0.4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemPainter extends CustomPainter {
  _ItemPainter(this.kind, this.charges);
  final ItemKind kind;
  final int charges;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    KartArt.drawItem(canvas, kind, size.width * 0.78, charges: charges);
  }

  @override
  bool shouldRepaint(_ItemPainter old) => old.kind != kind || old.charges != charges;
}

/// Compact speed readout with the drift-charge / boost bar above it.
class _Speedo extends StatelessWidget {
  const _Speedo({required this.racer, required this.compact});
  final Racer racer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final frac = (racer.speed.abs() / (racer.maxSpeed * 1.4)).clamp(0.0, 1.0);
    final drift = racer.isDrifting ? (racer.driftCharge / 110).clamp(0.0, 1.0) : 0.0;
    final tier = racer.driftTierPreview;
    final w = compact ? 92.0 : 120.0;
    return Semantics(
      label: 'Speed ${(racer.speed.abs() * 1.6).round()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: NtMotion.fast,
            opacity: racer.isDrifting || racer.boostTicks > 0 ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: w,
                height: 8,
                decoration: BoxDecoration(color: NtColors.inkDark.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: racer.boostTicks > 0 ? 1 : drift,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: racer.boostTicks > 0 ? NtColors.sunny : [const Color(0xFF9EE7FF), NtColors.sky, NtColors.nitro, NtColors.grape][tier],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
            decoration: BoxDecoration(color: NtColors.inkDark.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(NtRadius.pill)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: compact ? 34 : 44,
                  height: compact ? 17 : 22,
                  child: CustomPaint(painter: _GaugePainter(frac, racer.boostTicks > 0)),
                ),
                const SizedBox(width: 6),
                Text('${(racer.speed.abs() * 1.6).round()}', style: NtType.hud(Colors.white, size: compact ? 15 : 18)),
                const SizedBox(width: 3),
                Text('km/h', style: NtType.caption(Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.frac, this.boost);
  final double frac;
  final bool boost;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r - 3);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * frac,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: math.pi,
          endAngle: math.pi * 2,
          colors: boost ? [NtColors.sunny, NtColors.nitro] : [NtColors.mint, NtColors.sky, NtColors.nitro],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.frac != frac || old.boost != boost;
}

/// Countdown lights + centred status text (GO!, FINISH!, WRONG WAY...).
class _CentreText extends StatelessWidget {
  const _CentreText({required this.session, required this.compact});
  final RaceSession session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sim = session.sim;
    final me = session.local;
    String? text;
    Color color = Colors.white;
    double scale = 1;
    int lit = -1; // -1 hidden, 0..3 lamps lit, 4 = all green
    if (sim.phase == RacePhase.countdown) {
      final left = countdownTicks - sim.tick;
      final n = (left / ticksPerSecond).ceil().clamp(1, 4);
      if (n <= 3) {
        text = '$n';
        color = [NtColors.nitro, NtColors.sunny, NtColors.lime][3 - n];
        final within = (left % ticksPerSecond) / ticksPerSecond;
        scale = 0.85 + 0.35 * within;
        lit = 4 - n;
      } else {
        text = 'GET READY';
        color = Colors.white;
        lit = 0;
      }
    } else if (sim.tick - countdownTicks < ticksPerSecond && sim.phase == RacePhase.racing) {
      text = 'GO!';
      color = NtColors.lime;
      scale = 1 + (sim.tick - countdownTicks) / ticksPerSecond * 0.6;
      lit = 4;
    } else if (me != null && me.finished) {
      text = me.finishTick > 0 && sim.mode == GameMode.race ? 'FINISH!' : null;
      color = NtColors.sunny;
    } else if (me != null && me.wrongWayTicks > 20) {
      text = 'WRONG WAY';
      color = NtColors.nitro;
    } else if (me != null && me.respawnTicks > 0) {
      text = 'RESPAWNING';
      color = NtColors.sky;
    }
    if (text == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lit >= 0) ...[_StartLights(lit: lit, compact: compact), SizedBox(height: compact ? 12 : 20)],
        Transform.scale(
          scale: scale,
          child: OutlinedText(text, size: compact ? 56 : 84, fill: color, stroke: NtColors.inkDark, strokeWidth: compact ? 6 : 9, letterSpacing: 2),
        ),
      ],
    );
  }
}

/// Three-lamp start signal: lamps turn red one by one, then all green on GO.
class _StartLights extends StatelessWidget {
  const _StartLights({required this.lit, required this.compact});
  final int lit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final d = compact ? 22.0 : 32.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: d * 0.5, vertical: d * 0.35),
      decoration: BoxDecoration(
        color: NtColors.inkDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(NtRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: d * 0.22),
              child: AnimatedContainer(
                duration: NtMotion.fast,
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lit >= 4
                      ? NtColors.lime
                      : i < lit
                      ? NtColors.nitro
                      : Colors.white.withValues(alpha: 0.12),
                  boxShadow: lit >= 4 || i < lit ? NtElevation.glow(lit >= 4 ? NtColors.lime : NtColors.nitro) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Track outline with racer dots; local racer highlighted.
class Minimap extends StatelessWidget {
  const Minimap({super.key, required this.session, required this.art, required this.size});
  final RaceSession session;
  final TrackArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Minimap',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NtColors.inkDark.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(NtRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: CustomPaint(painter: _MinimapPainter(session, art)),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.session, this.art);
  final RaceSession session;
  final TrackArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final t = art.track;
    final b = Rect.fromLTRB(t.boundsMin.x - 30, t.boundsMin.y - 30, t.boundsMax.x + 30, t.boundsMax.y + 30);
    final scale = math.min(size.width / b.width, size.height / b.height);
    canvas.translate((size.width - b.width * scale) / 2, (size.height - b.height * scale) / 2);
    canvas.scale(scale);
    canvas.translate(-b.left, -b.top);
    canvas.drawPath(
      art.roadPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34 * (art.track.isArena ? 0.5 : 1)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (!art.track.isArena) {
      canvas.drawPath(
        art.roadPath,
        Paint()
          ..color = NtColors.inkDark.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      final s = art.track.samples.first;
      canvas.save();
      canvas.translate(s.pos.x, s.pos.y);
      canvas.rotate(s.tangent.angle);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: s.width + 8), Paint()..color = NtColors.sunny);
      canvas.restore();
    } else {
      canvas.drawPath(art.roadPath, Paint()..color = NtColors.inkDark.withValues(alpha: 0.6));
    }
    final dotR = 3.6 / scale;
    for (final r in session.sim.racers) {
      if (r.slot == session.localSlot) continue;
      final p = session.poseOf(r).pos;
      canvas.drawCircle(Offset(p.x, p.y), dotR, Paint()..color = NtColors.inkDark);
      canvas.drawCircle(Offset(p.x, p.y), dotR * 0.75, Paint()..color = NtColors.forCharacter(r.characterId));
    }
    final me = session.local;
    if (me != null) {
      final p = session.poseOf(me);
      canvas.save();
      canvas.translate(p.pos.x, p.pos.y);
      canvas.drawCircle(Offset.zero, dotR * 1.7, Paint()..color = Colors.white.withValues(alpha: 0.35));
      canvas.rotate(p.heading);
      final tri = Path()
        ..moveTo(dotR * 1.9, 0)
        ..lineTo(-dotR * 1.3, dotR * 1.2)
        ..lineTo(-dotR * 1.3, -dotR * 1.2)
        ..close();
      canvas.drawPath(tri, Paint()..color = Colors.white);
      canvas.drawPath(
        tri,
        Paint()
          ..color = NtColors.forCharacter(me.characterId)
          ..style = PaintingStyle.stroke
          ..strokeWidth = dotR * 0.5,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
