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
class RaceHud extends StatelessWidget {
  const RaceHud({super.key, required this.session, required this.art, required this.compact, this.rttMs, this.bottomInset = 0});

  final RaceSession session;
  final TrackArt art;
  final bool compact;
  final int? rttMs;

  /// Height reserved at the bottom for on-screen touch controls so the speedo
  /// and minimap sit above them instead of underneath.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final sim = session.sim;
    final me = session.local;
    final info = session.info;
    final isBattle = info.mode == GameMode.battle;
    final pad = compact ? 10.0 : 16.0;
    final top = <Widget>[];

    if (me != null) {
      top.add(_PositionBadge(place: me.position, total: sim.racers.length, compact: compact, battle: isBattle, score: me.score));
    }

    final lapOrTimer = isBattle
        ? _Pill(
            label: 'TIME',
            value: _mmss(sim.battleTicksLeft),
            color: sim.battleTicksLeft < 10 * ticksPerSecond ? NtColors.nitro : NtColors.sky,
            compact: compact,
          )
        : _Pill(
            label: info.timeTrial ? 'LAP' : 'LAP',
            value: '${math.min(info.laps, (me?.lap ?? 0) + 1)}/${info.laps}',
            color: (me?.lap ?? 0) >= info.laps - 1 ? NtColors.nitro : NtColors.sky,
            compact: compact,
          );

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Stack(
          children: [
            // Top-left: position + lap.
            Positioned(
              left: 0,
              top: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...top,
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      lapOrTimer,
                      const SizedBox(height: 6),
                      if (!isBattle)
                        _Pill(
                          label: 'TIME',
                          value: formatTicks(me != null && me.finished ? me.raceTicks : math.max(0, sim.tick - countdownTicks)),
                          color: NtColors.grape,
                          compact: true,
                        ),
                      if (info.online && rttMs != null) ...[
                        const SizedBox(height: 6),
                        _Pill(label: 'PING', value: '${rttMs}ms', color: rttMs! > 150 ? NtColors.nitro : NtColors.mint, compact: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Top-right: item slot.
            Positioned(
              right: 0,
              top: 0,
              child: _ItemSlot(racer: me, compact: compact),
            ),
            // Bottom-right: minimap.
            Positioned(
              right: 0,
              bottom: bottomInset + (compact ? 0 : 4),
              child: Minimap(session: session, art: art, size: compact ? 96 : 150),
            ),
            // Bottom-left: speed + boost gauge.
            if (me != null)
              Positioned(
                left: 0,
                bottom: bottomInset,
                child: _Speedo(racer: me, compact: compact),
              ),
            // Centre: countdown / wrong way / finish.
            Positioned.fill(
              child: Center(
                child: _CentreText(session: session, compact: compact),
              ),
            ),
            // Battle: balloons.
            if (isBattle && me != null)
              Positioned(
                left: 0,
                right: 0,
                top: compact ? 60 : 84,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(Icons.circle, size: compact ? 12 : 16, color: i < me.balloons ? NtColors.bubblegum : Colors.white.withValues(alpha: 0.3)),
                        ),
                    ],
                  ),
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

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.place, required this.total, required this.compact, required this.battle, required this.score});
  final int place;
  final int total;
  final bool compact;
  final bool battle;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = placeColor(place);
    final size = compact ? 64.0 : 88.0;
    final value = battle ? '$score' : '$place';
    final suffix = battle ? 'PTS' : ordinal(place).substring(value.length);
    return Semantics(
      label: battle ? '$score points' : '${ordinal(place)} of $total',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NtColors.inkDark.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(NtRadius.lg),
          border: Border.all(color: color, width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16)],
        ),
        child: Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: NtType.hud(Colors.white, size: compact ? 34 : 46),
                ),
                TextSpan(
                  text: suffix,
                  style: NtType.hud(color, size: compact ? 14 : 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color, required this.compact});
  final String label;
  final String value;
  final Color color;
  final bool compact;

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
          Text(label, style: NtType.caption(color)),
          const SizedBox(width: 8),
          Text(value, style: NtType.hud(Colors.white, size: compact ? 16 : 20)),
        ],
      ),
    );
  }
}

class _ItemSlot extends StatelessWidget {
  const _ItemSlot({required this.racer, required this.compact});
  final Racer? racer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 64.0 : 88.0;
    final r = racer;
    final rolling = r != null && r.rouletteTicks > 0;
    final item = r?.item;
    ItemKind? shown = item;
    if (rolling) {
      shown = ItemKind.values[(r.rouletteTicks ~/ 3) % ItemKind.values.length];
    }
    final label = shown == null ? 'No item' : (rolling ? 'Rolling item' : '${shown.label}${(r?.itemCharges ?? 1) > 1 ? ' x${r!.itemCharges}' : ''}');
    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: NtMotion.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NtColors.inkDark.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(NtRadius.lg),
          border: Border.all(color: shown != null && !rolling ? KartArt.itemColor(shown) : Colors.white.withValues(alpha: 0.2), width: 3),
          boxShadow: shown != null && !rolling ? [BoxShadow(color: KartArt.itemColor(shown).withValues(alpha: 0.45), blurRadius: 16)] : null,
        ),
        child: shown == null
            ? Center(
                child: Icon(Icons.help_outline_rounded, color: Colors.white.withValues(alpha: 0.18), size: size * 0.4),
              )
            : Opacity(
                opacity: rolling ? 0.6 : 1,
                child: CustomPaint(painter: _ItemPainter(shown, rolling ? 1 : (r?.itemCharges ?? 1)), size: Size.square(size)),
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

class _Speedo extends StatelessWidget {
  const _Speedo({required this.racer, required this.compact});
  final Racer racer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final frac = (racer.speed.abs() / (racer.maxSpeed * 1.4)).clamp(0.0, 1.0);
    final drift = racer.isDrifting ? (racer.driftCharge / 110).clamp(0.0, 1.0) : 0.0;
    final tier = racer.driftTierPreview;
    final w = compact ? 110.0 : 150.0;
    return Semantics(
      label: 'Speed ${(racer.speed.abs() * 1.6).round()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (racer.isDrifting || racer.boostTicks > 0)
            Padding(
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
            decoration: BoxDecoration(color: NtColors.inkDark.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(NtRadius.md)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: compact ? 44 : 60,
                  height: compact ? 22 : 30,
                  child: CustomPaint(painter: _GaugePainter(frac, racer.boostTicks > 0)),
                ),
                const SizedBox(width: 8),
                Text('${(racer.speed.abs() * 1.6).round()}', style: NtType.hud(Colors.white, size: compact ? 18 : 24)),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('KPH', style: NtType.caption(Colors.white.withValues(alpha: 0.6))),
                ),
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
    if (sim.phase == RacePhase.countdown) {
      final left = countdownTicks - sim.tick;
      final n = (left / ticksPerSecond).ceil().clamp(1, 4);
      if (n <= 3) {
        text = '$n';
        color = [NtColors.nitro, NtColors.sunny, NtColors.lime][3 - n];
        final within = (left % ticksPerSecond) / ticksPerSecond;
        scale = 0.85 + 0.35 * within;
      } else {
        text = 'GET READY';
        color = Colors.white;
      }
    } else if (sim.tick - countdownTicks < ticksPerSecond && sim.phase == RacePhase.racing) {
      text = 'GO!';
      color = NtColors.lime;
      scale = 1 + (sim.tick - countdownTicks) / ticksPerSecond * 0.6;
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
    return Transform.scale(
      scale: scale,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: NtType.hud(color, size: compact ? 56 : 84).copyWith(
          letterSpacing: 2,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
            Shadow(color: color.withValues(alpha: 0.6), blurRadius: 30),
          ],
        ),
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
