import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:nitro_core/nitro_core.dart';

import '../theme/tokens.dart';
import 'kart_art.dart';
import 'session.dart';
import 'track_art.dart';

/// A short-lived visual effect in world space.
class _Particle {
  _Particle(this.pos, this.vel, this.life, this.color, this.size) : maxLife = life;
  V2 pos;
  V2 vel;
  double life;
  final double maxLife;
  final Color color;
  final double size;
}

class _FloatText {
  _FloatText(this.pos, this.text, this.color) : life = 1.1;
  final V2 pos;
  final String text;
  final Color color;
  double life;
}

/// Flame game that renders a [RaceSession]: cached track art, karts,
/// projectiles, particles, and a chase camera. Input and HUD live in Flutter.
class RaceGame extends FlameGame {
  RaceGame({required this.session, required this.chaseCamera, required this.reduceMotion, this.onEvent}) : art = TrackArt(session.sim.track);

  RaceSession session;
  bool chaseCamera;
  bool reduceMotion;
  void Function(SimEvent e)? onEvent;

  TrackArt art;
  double _camHeading = 0;
  V2 _camPos = V2.zero;
  double _camZoom = 1;
  double _time = 0;
  double _shake = 0;
  final List<_Particle> _particles = [];
  final List<_FloatText> _texts = [];
  final _rng = math.Random(7);
  final double _pausedAlpha = 0;
  bool _first = true;

  Track get track => session.sim.track;

  @override
  Color backgroundColor() => Color(track.def.theme.ground);

  @override
  Future<void> onLoad() async {
    final me = session.local ?? session.sim.racers.first;
    _camPos = me.pos;
    _camHeading = me.heading;
  }

  void swapSession(RaceSession next) {
    session = next;
    art.dispose();
    art = TrackArt(track);
    _particles.clear();
    _texts.clear();
    _first = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    session.advance(dt);
    for (final e in session.frameEvents) {
      _handleEvent(e);
      onEvent?.call(e);
    }
    session.frameEvents.clear();
    _updateParticles(dt);
    _updateCamera(dt);
    _shake = math.max(0, _shake - dt * 3);
  }

  void _updateCamera(double dt) {
    final me = session.local ?? session.sim.racers.first;
    final pose = session.poseOf(me);
    // Look a bit ahead of the kart at speed.
    final ahead = V2.fromAngle(pose.heading, 18 + me.speed.abs() * 0.18);
    final target = pose.pos + ahead;
    final k = _first ? 1.0 : 1 - math.pow(0.001, dt * 2.2).toDouble();
    _camPos = V2(lerpD(_camPos.x, target.x, k), lerpD(_camPos.y, target.y, k));
    if (chaseCamera) {
      final wantHeading = me.isSpinning ? _camHeading : pose.heading;
      final hk = _first ? 1.0 : 1 - math.pow(0.001, dt * 1.6).toDouble();
      _camHeading += wrapAngle(wantHeading - _camHeading) * hk;
    } else {
      _camHeading = -math.pi / 2;
    }
    final base = math.min(size.x, size.y) / 210;
    final wantZoom = base * (me.boostTicks > 0 ? 0.93 : 1.0);
    _camZoom = _first ? wantZoom : lerpD(_camZoom, wantZoom, 1 - math.pow(0.001, dt).toDouble());
    _first = false;
  }

  void _handleEvent(SimEvent e) {
    final r = e.slot >= 0 ? session.sim.racerBySlot(e.slot) : null;
    final isMe = e.slot == session.localSlot;
    switch (e.type) {
      case 'miniTurbo':
      case 'pad':
      case 'rocketStart':
      case 'trickLand':
      case 'slipstream':
        if (r != null) _burst(r.pos, r.heading + math.pi, e.type == 'pad' ? NtColors.nitro : NtColors.sky, 14);
        if (isMe && e.type == 'miniTurbo') {
          _texts.add(_FloatText(r!.pos, ['Mini-turbo!', 'Super turbo!', 'Ultra turbo!'][e.value.clamp(1, 3) - 1], NtColors.sunny));
        }
        if (isMe && e.type == 'slipstream') _texts.add(_FloatText(r!.pos, 'Slipstream!', NtColors.mint));
        if (isMe && e.type == 'trickLand') _texts.add(_FloatText(r!.pos, 'Trick!', NtColors.grape));
        if (isMe && e.type == 'rocketStart') _texts.add(_FloatText(r!.pos, 'Rocket start!', NtColors.nitro));
      case 'hit':
      case 'knockout':
        if (r != null) _burst(r.pos, 0, NtColors.sunny, 18, spread: math.pi * 2);
        if (isMe) _shake = 1;
      case 'wall':
      case 'bump':
        if (isMe) _shake = math.max(_shake, 0.35);
        if (r != null) _burst(r.pos, r.heading + math.pi, const Color(0xFFDDDDDD), 5, spread: math.pi);
      case 'shieldPop':
        if (r != null) _burst(r.pos, 0, NtColors.sky, 20, spread: math.pi * 2);
      case 'lap':
        if (isMe && r != null && e.value < session.info.laps) {
          _texts.add(_FloatText(r.pos, e.value == session.info.laps - 1 ? 'Final lap!' : 'Lap ${e.value + 1}', NtColors.sunny));
        }
      case 'pickup':
        if (r != null) _burst(r.pos, 0, NtColors.bubblegum, 8, spread: math.pi * 2);
      case 'score':
        if (r != null) _texts.add(_FloatText(r.pos, '+${e.value}', NtColors.lime));
      case 'stall':
        if (isMe) _shake = 0.5;
    }
  }

  void _burst(V2 at, double dir, Color color, int n, {double spread = 0.9}) {
    if (reduceMotion) n = (n / 3).ceil();
    for (var i = 0; i < n; i++) {
      final a = dir + (_rng.nextDouble() - 0.5) * spread;
      final sp = 40 + _rng.nextDouble() * 90;
      final life = 0.35 + _rng.nextDouble() * 0.4;
      _particles.add(_Particle(at, V2.fromAngle(a, sp), life, color, 1.5 + _rng.nextDouble() * 2.5));
    }
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.life -= dt;
      p.pos = p.pos + p.vel * dt;
      p.vel = p.vel * math.pow(0.02, dt).toDouble();
    }
    _particles.removeWhere((p) => p.life <= 0);
    for (final t in _texts) {
      t.life -= dt;
    }
    _texts.removeWhere((t) => t.life <= 0);

    // Continuous drift / boost trails.
    if (!reduceMotion) {
      for (final r in session.sim.racers) {
        if (r.isDrifting && r.speed > 20 && _rng.nextDouble() < 0.6) {
          final c = switch (r.driftTierPreview) {
            0 => const Color(0xFF9EE7FF),
            1 => NtColors.sky,
            2 => NtColors.nitro,
            _ => NtColors.grape,
          };
          final back = r.pos - V2.fromAngle(r.heading, 9);
          _particles.add(_Particle(back, V2.fromAngle(r.heading + math.pi + (_rng.nextDouble() - 0.5), 25), 0.25, c, 1.6));
        }
        if (r.boostTicks > 0 && _rng.nextDouble() < 0.7) {
          final back = r.pos - V2.fromAngle(r.heading, 11);
          _particles.add(
            _Particle(
              back,
              V2.fromAngle(r.heading + math.pi + (_rng.nextDouble() - 0.5) * 0.4, 60),
              0.3,
              _rng.nextBool() ? NtColors.sunny : NtColors.nitro,
              2.2,
            ),
          );
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sim = session.sim;
    final w = size.x;
    final h = size.y;
    // The world picture is finite; paint the horizon in the track's ground colour first.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Color.alphaBlend(TrackArt.beyondTint, TrackArt.c(art.theme.ground)));
    canvas.save();
    // Camera: kart sits ~62% down the screen in chase mode.
    final anchorY = chaseCamera ? h * 0.62 : h * 0.5;
    var shakeX = 0.0, shakeY = 0.0;
    if (_shake > 0 && !reduceMotion) {
      shakeX = (_rng.nextDouble() - 0.5) * 10 * _shake;
      shakeY = (_rng.nextDouble() - 0.5) * 10 * _shake;
    }
    canvas.translate(w / 2 + shakeX, anchorY + shakeY);
    canvas.scale(_camZoom);
    canvas.rotate(-_camHeading - math.pi / 2);
    canvas.translate(-_camPos.x, -_camPos.y);

    canvas.drawPicture(art.picture);

    // Dropped hazards.
    for (final d in sim.dropped) {
      canvas.drawOval(Rect.fromCenter(center: Offset(d.pos.x, d.pos.y), width: 22, height: 16), Paint()..color = const Color(0xCC2B2440));
      canvas.drawOval(Rect.fromCenter(center: Offset(d.pos.x - 3, d.pos.y - 3), width: 8, height: 4), Paint()..color = const Color(0x66FFFFFF));
    }

    // Item boxes.
    for (var i = 0; i < track.itemBoxes.length; i++) {
      final b = track.itemBoxes[i];
      canvas.save();
      canvas.translate(b.pos.x, b.pos.y);
      KartArt.drawItemBox(canvas, _time + i * 0.7, alive: sim.itemBoxRespawn[i] == 0);
      canvas.restore();
    }

    // Moving hazards (rollers).
    for (final m in sim.movingHazards) {
      canvas.save();
      canvas.translate(m.pos.x, m.pos.y);
      canvas.rotate(_time * 4);
      canvas.drawCircle(const Offset(1.5, 2.5), 9, Paint()..color = const Color(0x44000000));
      canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFF6E7D95));
      canvas.drawCircle(
        Offset.zero,
        9,
        Paint()
          ..color = KartArt.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (var k = 0; k < 4; k++) {
        final a = k * math.pi / 2;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(a) * 8, math.sin(a) * 8),
          Paint()
            ..color = KartArt.ink
            ..strokeWidth = 1.6,
        );
      }
      canvas.restore();
    }

    // Ghost.
    final ghost = session.ghostPose;
    if (ghost != null) {
      canvas.save();
      canvas.translate(ghost.pos.x, ghost.pos.y);
      canvas.rotate(ghost.heading);
      KartArt.drawKart(canvas, body: const Color(0xFFB9C4D6), kart: karts.first, ghost: true, time: _time);
      canvas.restore();
    }

    // Karts, drawn so the local racer is on top.
    final order = [...sim.racers]..sort((a, b) => a.slot == session.localSlot ? 1 : (b.slot == session.localSlot ? -1 : 0));
    for (final r in order) {
      if (r.respawnTicks > 0 && (r.respawnTicks ~/ 4).isEven) continue;
      final pose = session.poseOf(r);
      final kart = karts.firstWhere((k) => k.id == r.kartId, orElse: () => karts.first);
      canvas.save();
      canvas.translate(pose.pos.x, pose.pos.y);
      final spin = r.isSpinning ? _time * 14 : 0.0;
      final airborne = r.isAirborne;
      final hop = r.hopTicks > 0 ? 4.0 : (airborne ? 8.0 + 6 * math.sin(math.min(1, r.airTicks / 20) * math.pi) : 0.0);
      canvas.rotate(pose.heading + spin + (airborne && r.trickDone ? math.sin(r.airTicks * 0.5) * 0.4 : 0));
      KartArt.drawKart(
        canvas,
        body: NtColors.forCharacter(r.characterId),
        kart: kart,
        steer: r.driftDir != 0 ? r.driftDir * 0.8 : 0,
        hop: hop,
        drifting: r.isDrifting && !airborne,
        driftTier: r.driftTierPreview,
        boosting: r.boostTicks > 0,
        shield: r.hasShield,
        spinning: r.isSpinning,
        time: _time,
        scale: airborne ? 1.12 : 1,
      );
      canvas.restore();

      // Name tag for other racers.
      if (r.slot != session.localSlot) {
        canvas.save();
        canvas.translate(pose.pos.x, pose.pos.y);
        canvas.rotate(_camHeading + math.pi / 2);
        final tp = TextPainter(
          text: TextSpan(
            text: r.name,
            style: TextStyle(
              fontFamily: NtType.displayFont,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFFFFF),
              shadows: const [Shadow(color: Color(0x99000000), blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final bg = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -19), width: tp.width + 8, height: tp.height + 3), const Radius.circular(6));
        canvas.drawRRect(bg, Paint()..color = NtColors.forCharacter(r.characterId).withValues(alpha: 0.85));
        tp.paint(canvas, Offset(-tp.width / 2, -19 - tp.height / 2));
        canvas.restore();
      }
    }

    // Projectiles.
    for (final p in sim.projectiles) {
      canvas.save();
      canvas.translate(p.pos.x, p.pos.y);
      if (p.kind == ItemKind.rocket) {
        canvas.rotate(p.heading);
        canvas.drawCircle(const Offset(-8, 0), 3 + math.sin(_time * 50).abs() * 2, Paint()..color = NtColors.sunny.withValues(alpha: 0.9));
        KartArt.drawItem(canvas, ItemKind.rocket, 16);
      } else {
        canvas.rotate(_time * 6);
        KartArt.drawItem(canvas, ItemKind.orb, 14);
      }
      canvas.restore();
    }

    // Particles.
    for (final p in _particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), p.size * (0.5 + a * 0.5), Paint()..color = p.color.withValues(alpha: a));
    }

    // Floating text.
    for (final t in _texts) {
      canvas.save();
      final rise = (1.1 - t.life) * 26;
      canvas.translate(t.pos.x, t.pos.y);
      canvas.rotate(_camHeading + math.pi / 2);
      canvas.translate(0, -28 - rise);
      final a = (t.life / 0.4).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: TextStyle(
            fontFamily: NtType.displayFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: t.color.withValues(alpha: a),
            shadows: [Shadow(color: const Color(0xFF000000).withValues(alpha: 0.6 * a), blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.restore();

    final viewport = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      viewport,
      Paint()..shader = const RadialGradient(radius: 0.85, colors: [Color(0x00071927), Color(0x44071927)], stops: [0.5, 1]).createShader(viewport),
    );

    // Vignette + speed lines when boosting.
    final me = session.local;
    if (me != null && me.boostTicks > 0 && !reduceMotion) {
      final p = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25)
        ..strokeWidth = 2;
      for (var i = 0; i < 14; i++) {
        final a = i / 14 * math.pi * 2 + _time * 3;
        final r0 = math.max(w, h) * 0.42;
        final r1 = r0 + 40 + (math.sin(_time * 30 + i) + 1) * 30;
        canvas.drawLine(Offset(w / 2 + math.cos(a) * r0, anchorY + math.sin(a) * r0), Offset(w / 2 + math.cos(a) * r1, anchorY + math.sin(a) * r1), p);
      }
    }
    if (_pausedAlpha > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF000000).withValues(alpha: 0.4 * _pausedAlpha));
    }
  }

  /// World -> screen, used by the HUD to anchor overlays if needed.
  Offset worldToScreen(V2 p) {
    final anchorY = chaseCamera ? size.y * 0.62 : size.y * 0.5;
    final d = p - _camPos;
    final a = -_camHeading - math.pi / 2;
    final x = d.x * math.cos(a) - d.y * math.sin(a);
    final y = d.x * math.sin(a) + d.y * math.cos(a);
    return Offset(size.x / 2 + x * _camZoom, anchorY + y * _camZoom);
  }

  @override
  void onRemove() {
    art.dispose();
    super.onRemove();
  }
}
