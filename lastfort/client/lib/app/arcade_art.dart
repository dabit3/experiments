import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lastfort_core/lastfort_core.dart' hide Material;

import 'theme.dart';

class ScoutPainter extends CustomPainter {
  const ScoutPainter(this.outfit);
  final Cosmetic outfit;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final primary = Color(outfit.primary);
    final secondary = Color(outfit.secondary);
    final accent = Color(outfit.accent);
    const ink = Color(0xFF10213B);
    void armor(Rect r, Color color, double radius) {
      final shape = RRect.fromRectAndRadius(r, Radius.circular(radius));
      canvas.drawRRect(shape.shift(const Offset(0, 2)), Paint()..color = ink);
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = ui.Gradient.linear(
            r.topLeft,
            r.bottomRight,
            [
              Color.lerp(color, Colors.white, 0.4)!,
              color,
              Color.lerp(color, ink, 0.45)!,
            ],
            [0, 0.45, 1],
          ),
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        r.topLeft + Offset(radius, 1.3),
        r.topRight + Offset(-radius, 1.3),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 0.7,
      );
    }

    canvas.drawOval(
      const Rect.fromLTWH(15, 89, 72, 8),
      Paint()..color = ink.withValues(alpha: 0.22),
    );
    armor(const Rect.fromLTWH(58, 43, 18, 30), secondary, 5);
    armor(const Rect.fromLTWH(34, 70, 13, 20), secondary, 4);
    armor(const Rect.fromLTWH(53, 70, 13, 20), secondary, 4);
    armor(const Rect.fromLTWH(27, 83, 21, 10), primary, 4);
    armor(const Rect.fromLTWH(52, 83, 23, 10), primary, 4);
    armor(const Rect.fromLTWH(31, 70, 16, 9), primary, 3);
    armor(const Rect.fromLTWH(53, 70, 16, 9), primary, 3);
    armor(const Rect.fromLTWH(27, 43, 47, 31), primary, 9);
    armor(const Rect.fromLTWH(34, 48, 33, 19), secondary, 5);
    armor(const Rect.fromLTWH(17, 47, 17, 16), primary, 6);
    armor(const Rect.fromLTWH(68, 46, 17, 16), primary, 6);
    armor(const Rect.fromLTWH(18, 60, 13, 15), secondary, 5);
    armor(const Rect.fromLTWH(73, 59, 13, 15), secondary, 5);
    armor(const Rect.fromLTWH(16, 69, 16, 10), primary, 4);
    armor(const Rect.fromLTWH(73, 68, 16, 10), primary, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 69, 43, 5),
        const Radius.circular(2),
      ),
      Paint()..color = ink,
    );
    armor(const Rect.fromLTWH(44, 67, 12, 8), accent, 2);
    final badge = Path()
      ..moveTo(50, 50)
      ..lineTo(57, 56)
      ..lineTo(50, 63)
      ..lineTo(43, 56)
      ..close();
    canvas.drawPath(badge, Paint()..color = accent);
    canvas.drawPath(
      Path()
        ..moveTo(48, 53)
        ..lineTo(48, 59)
        ..lineTo(54, 56)
        ..close(),
      Paint()..color = ink,
    );
    armor(const Rect.fromLTWH(28, 18, 46, 29), primary, 12);
    armor(const Rect.fromLTWH(22, 29, 9, 13), secondary, 3);
    armor(const Rect.fromLTWH(72, 29, 9, 13), secondary, 3);
    armor(const Rect.fromLTWH(31, 27, 41, 15), ink, 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 30, 29, 8),
        const Radius.circular(4),
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(36, 30),
          const Offset(65, 38),
          [Colors.white, accent, Color.lerp(accent, LfTokens.teal, 0.5)!],
          [0, 0.5, 1],
        ),
    );
    canvas.drawLine(
      const Offset(50, 31),
      const Offset(47, 37),
      Paint()
        ..color = ink
        ..strokeWidth = 2.5,
    );
    armor(const Rect.fromLTWH(44, 17, 13, 7), accent, 2);
    canvas.drawCircle(const Offset(77, 33), 2, Paint()..color = accent);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScoutPainter old) => old.outfit != outfit;
}

class ArcadeAtmosphere extends StatefulWidget {
  const ArcadeAtmosphere({
    super.key,
    this.celebrate = false,
    this.reduced = false,
  });
  final bool celebrate;
  final bool reduced;

  @override
  State<ArcadeAtmosphere> createState() => _ArcadeAtmosphereState();
}

class _ArcadeAtmosphereState extends State<ArcadeAtmosphere>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant ArcadeAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.reduced || MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => CustomPaint(
          painter: _AtmospherePainter(_clock.value, widget.celebrate),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter(this.t, this.celebrate);
  final double t;
  final bool celebrate;

  @override
  void paint(Canvas canvas, Size size) {
    final count = celebrate ? 54 : 24;
    for (var i = 0; i < count; i++) {
      final x =
          ((i * 0.618034 + math.sin(t * math.pi * 2 + i) * 0.025) % 1) *
          size.width;
      final y = ((i * 0.371 + (celebrate ? t : -t) + 1) % 1) * size.height;
      final color = [LfTokens.warning, LfTokens.teal, Colors.white][i % 3];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i + t * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: celebrate ? 5 : 2,
            height: celebrate ? 10 : 2,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = color.withValues(alpha: celebrate ? 0.65 : 0.35),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.t != t || old.celebrate != celebrate;
}

class VictoryCrest extends StatelessWidget {
  const VictoryCrest({super.key, required this.accent, required this.won});
  final Color accent;
  final bool won;

  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    height: 96,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [
          Color.lerp(accent, Colors.white, 0.5)!,
          accent,
          Color.lerp(accent, Colors.black, 0.4)!,
        ],
      ),
      border: Border.all(color: Colors.white70, width: 3),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.35),
          blurRadius: 48,
          spreadRadius: 10,
        ),
      ],
    ),
    child: Icon(
      won ? Icons.emoji_events_rounded : Icons.shield_rounded,
      size: 54,
      color: const Color(0xFF10213B),
    ),
  );
}
