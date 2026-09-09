import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../theme/tokens.dart';

class _P {
  _P(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.life,
    this.color,
    this.size, {
    this.gravity = 6,
    this.drag = 0.9,
    this.grow = 0,
  }) : maxLife = life;
  double x, y, vx, vy, life;
  final double maxLife;
  final Color color;
  double size;
  final double gravity;
  final double drag;
  final double grow;
  double get alpha => (life / maxLife).clamp(0, 1);
}

class _T {
  _T(this.x, this.y, this.text, this.color, this.scale) : life = 1.1;
  final double x;
  double y;
  final String text;
  final Color color;
  final double scale;
  double life;
}

/// Tiny world-space particle system (units = cells). Purely cosmetic and
/// therefore not part of the deterministic core.
class Particles {
  final List<_P> _ps = [];
  final List<_T> _ts = [];
  final math.Random _rng = math.Random(7);

  void burst(Offset at, Color c, {int count = 10, double speed = 2, double size = 0.09}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final v = speed * (0.4 + _rng.nextDouble());
      _ps.add(
        _P(
          at.dx,
          at.dy,
          math.cos(a) * v,
          math.sin(a) * v - speed * 0.6,
          0.55 + _rng.nextDouble() * 0.35,
          c,
          size * (0.6 + _rng.nextDouble()),
        ),
      );
    }
  }

  void smoke(Offset at, {int count = 10, Color color = const Color(0xFF5A5560)}) {
    for (var i = 0; i < count; i++) {
      _ps.add(
        _P(
          at.dx + (_rng.nextDouble() - 0.5) * 0.5,
          at.dy,
          (_rng.nextDouble() - 0.5) * 0.6,
          -0.8 - _rng.nextDouble() * 0.8,
          1.0 + _rng.nextDouble() * 0.6,
          color,
          0.12,
          gravity: -0.4,
          drag: 0.98,
          grow: 0.18,
        ),
      );
    }
  }

  void puff(Offset at, {Color color = const Color(0xFFFFFFFF)}) {
    for (var i = 0; i < 5; i++) {
      _ps.add(
        _P(
          at.dx,
          at.dy,
          (_rng.nextDouble() - 0.5) * 1.2,
          -0.3 - _rng.nextDouble() * 0.4,
          0.35,
          color,
          0.1,
          gravity: 0,
          drag: 0.9,
          grow: 0.25,
        ),
      );
    }
  }

  void text(Offset at, String s, Color c, {double scale = 1}) {
    if (s.isEmpty) return;
    _ts.add(_T(at.dx, at.dy, s, c, scale));
  }

  void update(double dt) {
    for (final p in _ps) {
      p.life -= dt;
      p.vy += p.gravity * dt;
      p.vx *= math.pow(p.drag, dt * 60).toDouble();
      p.vy *= math.pow(p.drag, dt * 60).toDouble();
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.size += p.grow * dt;
    }
    _ps.removeWhere((p) => p.life <= 0);
    for (final t in _ts) {
      t.life -= dt;
      t.y -= dt * 0.7;
    }
    _ts.removeWhere((t) => t.life <= 0);
  }

  void render(Canvas canvas, double cell, Offset origin) {
    final paint = Paint();
    for (final p in _ps) {
      paint.color = p.color.withValues(alpha: p.alpha * 0.95);
      canvas.drawCircle(Offset(origin.dx + p.x * cell, origin.dy + p.y * cell), p.size * cell, paint);
    }
    for (final t in _ts) {
      final a = (t.life / 1.1).clamp(0.0, 1.0);
      final pop = 1 + 0.25 * math.sin(math.min(1, (1.1 - t.life) * 6) * math.pi);
      final style = PPType.numeric(t.color.withValues(alpha: a), size: cell * 0.36 * t.scale * pop);
      final tp = TextPainter(
        text: TextSpan(
          text: t.text,
          style: style.copyWith(
            shadows: [Shadow(color: const Color(0xAA000000), blurRadius: 4, offset: const Offset(0, 1.5))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(origin.dx + t.x * cell - tp.width / 2, origin.dy + t.y * cell - tp.height / 2));
    }
  }
}
