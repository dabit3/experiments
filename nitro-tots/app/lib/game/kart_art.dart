import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:nitro_core/nitro_core.dart';

import 'art_assets.dart';

import '../theme/tokens.dart';

/// Vector kart + item iconography shared by the race view, minimap, garage
/// previews and the lobby.
abstract final class KartArt {
  static const ink = Color(0xFF2B2440);

  /// Draws a kart centred at the origin facing +x. World units (~20 long).
  static void drawKart(
    Canvas canvas, {
    required Color body,
    required Kart kart,
    double steer = 0,
    double hop = 0,
    int driftTier = 0,
    bool drifting = false,
    bool boosting = false,
    bool shield = false,
    bool spinning = false,
    bool ghost = false,
    double time = 0,
    double scale = 1,
  }) {
    canvas.save();
    canvas.scale(scale);
    final len = 16.0 + 1.4 * kart.weight;
    final wid = 9.5 + 0.8 * kart.weight;
    final alpha = ghost ? 0.45 : 1.0;

    // Shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-1, 2 + hop * 0.4), width: len + 4, height: wid + 4),
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.22 * alpha),
    );
    canvas.translate(0, -hop);

    // Boost flame.
    if (boosting) {
      final flick = 1 + 0.2 * math.sin(time * 40);
      final flame = Path()
        ..moveTo(-len / 2, -4)
        ..lineTo(-len / 2 - 12 * flick, 0)
        ..lineTo(-len / 2, 4)
        ..close();
      canvas.drawPath(flame, Paint()..color = const Color(0xFFFF8A3D).withValues(alpha: alpha));
      final inner = Path()
        ..moveTo(-len / 2, -2)
        ..lineTo(-len / 2 - 7 * flick, 0)
        ..lineTo(-len / 2, 2)
        ..close();
      canvas.drawPath(inner, Paint()..color = const Color(0xFFFFE27A).withValues(alpha: alpha));
    }

    if (!ArtAssets.draw(
      canvas,
      'kart-${kart.id}.png',
      Rect.fromCenter(center: Offset.zero, width: len + 10, height: (len + 10) * 0.75),
      opacity: alpha,
    )) {
      // Wheels.
      final wheel = Paint()..color = ink.withValues(alpha: alpha);
      final hub = Paint()..color = const Color(0xFFB8D8E3).withValues(alpha: alpha);
      for (final (x, y, front) in [
        (len * 0.30, -wid / 2 - 1.5, true),
        (len * 0.30, wid / 2 + 1.5, true),
        (-len * 0.32, -wid / 2 - 1.5, false),
        (-len * 0.32, wid / 2 + 1.5, false),
      ]) {
        canvas.save();
        canvas.translate(x, y);
        if (front) canvas.rotate(steer * 0.45);
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-3.2, -2, 6.4, 4), const Radius.circular(1.6));
        canvas.drawRRect(r, wheel);
        for (var line = -2; line <= 2; line++) {
          canvas.drawLine(
            Offset(line.toDouble(), -1.7),
            Offset(line.toDouble(), 1.7),
            Paint()
              ..color = const Color(0xFF394656).withValues(alpha: alpha)
              ..strokeWidth = 0.4,
          );
        }
        canvas.drawRect(const Rect.fromLTWH(-1.2, -0.8, 2.4, 1.6), hub);
        canvas.restore();
      }

      // Body.
      final bodyRect = RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset.zero, width: len, height: wid),
        topRight: Radius.circular(wid * 0.5),
        bottomRight: Radius.circular(wid * 0.5),
        topLeft: const Radius.circular(3),
        bottomLeft: const Radius.circular(3),
      );
      canvas.drawRRect(bodyRect, Paint()..color = ink.withValues(alpha: alpha));
      canvas.drawRRect(
        bodyRect.deflate(1.1),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(-2, -wid / 2),
            Offset(2, wid / 2),
            [
              Color.lerp(body, const Color(0xFFFFFFFF), 0.5)!.withValues(alpha: alpha),
              body.withValues(alpha: alpha),
              Color.lerp(body, ink, 0.5)!.withValues(alpha: alpha),
            ],
            [0, 0.4, 1],
          ),
      );
      final spoiler = RRect.fromRectAndRadius(Rect.fromLTWH(-len / 2 - 1, -wid / 2 - 1, 3, wid + 2), const Radius.circular(0.7));
      canvas.drawRRect(spoiler.shift(const Offset(1, 1)), Paint()..color = ink.withValues(alpha: alpha));
      canvas.drawRRect(spoiler, Paint()..color = body.withValues(alpha: alpha));
      canvas.drawLine(
        Offset(-len / 2, -wid / 2),
        Offset(-len / 2, wid / 2),
        Paint()
          ..color = const Color(0xFFECF3EE).withValues(alpha: alpha)
          ..strokeWidth = 0.6,
      );
      for (final side in [-1.0, 1.0]) {
        final pipe = Rect.fromLTWH(-len / 2 - 2, side * (wid * 0.33) - 1, 6, 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(pipe, const Radius.circular(0.7)),
          Paint()
            ..shader = ui.Gradient.linear(pipe.topLeft, pipe.bottomLeft, [
              const Color(0xFFE1EDF3).withValues(alpha: alpha),
              const Color(0xFF506273).withValues(alpha: alpha),
            ]),
        );
        canvas.drawCircle(Offset(-len / 2 - 1.7, side * (wid * 0.33)), 0.6, wheel);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(len / 2 - 2, side * wid * 0.27), width: 2, height: 1.3),
          Paint()..color = const Color(0xFF91FFFF).withValues(alpha: alpha),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(2, -1.2, len / 2 - 4, 2.4), const Radius.circular(0.5)),
        Paint()..color = const Color(0xFFFFF5D9).withValues(alpha: alpha),
      );
      if (kart.id == 'pinewood') {
        for (var y = -2; y <= 2; y++) {
          canvas.drawLine(
            Offset(3, y * 1.6),
            Offset(len / 2 - 2, y * 1.6),
            Paint()
              ..color = const Color(0x6696683A)
              ..strokeWidth = 0.4,
          );
        }
      }
      // Highlight stripe.
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-len / 2 + 3, -wid / 2 + 2.2, len - 8, 2.2), const Radius.circular(1)),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * alpha),
      );
      // Nose / bumper accent.
      canvas.drawCircle(Offset(len / 2 - 3, 0), 1.8, Paint()..color = const Color(0xFFFFE27A).withValues(alpha: alpha));
    }

    // Driver helmet.
    canvas.drawCircle(const Offset(-1.4, 0.7), 4.8, Paint()..color = ink.withValues(alpha: alpha));
    canvas.drawCircle(
      const Offset(-2, -0.5),
      4.6,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(-3.4, -2),
          7,
          [
            Color.lerp(body, const Color(0xFFFFFFFF), 0.65)!.withValues(alpha: alpha),
            body.withValues(alpha: alpha),
            Color.lerp(body, ink, 0.65)!.withValues(alpha: alpha),
          ],
          [0, 0.5, 1],
        ),
    );
    canvas.drawLine(
      const Offset(-5.7, -0.5),
      const Offset(-1.8, -0.5),
      Paint()
        ..color = const Color(0xFFFFF0D6).withValues(alpha: alpha)
        ..strokeWidth = 1.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-1.4, -3.7, 3.3, 6.4), const Radius.circular(1.3)),
      Paint()..color = const Color(0xFFB9D9DA).withValues(alpha: alpha),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-1, -3.3, 2.6, 5.6), const Radius.circular(1)),
      Paint()
        ..shader = ui.Gradient.linear(const Offset(-1, -3), const Offset(2, 3), [
          const Color(0xFF66C8D6).withValues(alpha: alpha),
          const Color(0xFF12364C).withValues(alpha: alpha),
        ]),
    );
    canvas.drawLine(
      const Offset(-0.6, -2.7),
      const Offset(-0.6, 0.4),
      Paint()
        ..color = const Color(0xAAFFFFFF).withValues(alpha: alpha * 0.7)
        ..strokeWidth = 0.55,
    );

    // Drift sparks.
    if (drifting) {
      final sparkColor = switch (driftTier) {
        0 => const Color(0xFF9EE7FF),
        1 => const Color(0xFF3DB7FF),
        2 => const Color(0xFFFF9A3D),
        _ => const Color(0xFFC77DFF),
      };
      final p = Paint()..color = sparkColor.withValues(alpha: alpha);
      for (var i = 0; i < 3; i++) {
        final jitter = math.sin(time * 60 + i * 2.1) * 2;
        canvas.drawCircle(Offset(-len * 0.4 - i * 3.0 + jitter, -wid / 2 - 3 - i), 1.6 + (driftTier >= 1 ? 0.6 : 0), p);
        canvas.drawCircle(Offset(-len * 0.4 - i * 3.0 - jitter, wid / 2 + 3 + i), 1.6 + (driftTier >= 1 ? 0.6 : 0), p);
      }
    }

    // Shield bubble.
    if (shield) {
      final pulse = 0.5 + 0.5 * math.sin(time * 6);
      canvas.drawCircle(Offset.zero, len * 0.72, Paint()..color = NtColors.sky.withValues(alpha: 0.22 + 0.1 * pulse));
      canvas.drawCircle(
        Offset.zero,
        len * 0.72,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Spin stars.
    if (spinning) {
      final p = Paint()..color = NtColors.sunny;
      for (var i = 0; i < 3; i++) {
        final a = time * 8 + i * 2.09;
        canvas.drawCircle(Offset(math.cos(a) * 12, math.sin(a) * 12 - 4), 1.8, p);
      }
    }
    canvas.restore();
  }

  /// Item icon centred at the origin within a [size]-diameter circle.
  static void drawItem(Canvas canvas, ItemKind kind, double size, {int charges = 1}) {
    final r = size / 2;
    final color = itemColor(kind);
    final ink = KartArt.ink;
    final paint = Paint()..color = color;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case ItemKind.turbo:
      case ItemKind.tripleTurbo:
        final n = kind == ItemKind.tripleTurbo ? 3 : 1;
        for (var i = 0; i < n; i++) {
          final dx = (i - (n - 1) / 2) * r * 0.55;
          final path = Path()
            ..moveTo(dx - r * 0.25, -r * 0.45)
            ..lineTo(dx + r * 0.32, -r * 0.05)
            ..lineTo(dx - r * 0.02, -r * 0.05)
            ..lineTo(dx + r * 0.25, r * 0.5)
            ..lineTo(dx - r * 0.32, r * 0.02)
            ..lineTo(dx + r * 0.02, r * 0.02)
            ..close();
          canvas.drawPath(path, paint);
          canvas.drawPath(path, stroke);
        }
      case ItemKind.rocket:
        final body = Path()
          ..moveTo(r * 0.55, 0)
          ..lineTo(r * 0.1, -r * 0.35)
          ..lineTo(-r * 0.45, -r * 0.35)
          ..lineTo(-r * 0.45, r * 0.35)
          ..lineTo(r * 0.1, r * 0.35)
          ..close();
        canvas.drawPath(body, paint);
        canvas.drawPath(body, stroke);
        final fin = Path()
          ..moveTo(-r * 0.45, -r * 0.35)
          ..lineTo(-r * 0.7, -r * 0.6)
          ..lineTo(-r * 0.7, r * 0.6)
          ..lineTo(-r * 0.45, r * 0.35);
        canvas.drawPath(fin, Paint()..color = NtColors.nitroDeep);
        canvas.drawPath(fin, stroke);
        canvas.drawCircle(Offset(r * 0.05, 0), r * 0.14, Paint()..color = const Color(0xFF9BE7FF));
      case ItemKind.orb:
        canvas.drawCircle(Offset.zero, r * 0.55, paint);
        canvas.drawCircle(Offset.zero, r * 0.55, stroke);
        canvas.drawCircle(Offset(-r * 0.2, -r * 0.2), r * 0.16, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8));
        canvas.drawCircle(Offset.zero, r * 0.3, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25));
      case ItemKind.slick:
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.3, height: r * 0.9), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.3, height: r * 0.9), stroke);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(-r * 0.2, -r * 0.15), width: r * 0.45, height: r * 0.22),
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35),
        );
      case ItemKind.shield:
        final path = Path()
          ..moveTo(0, -r * 0.6)
          ..lineTo(r * 0.55, -r * 0.35)
          ..lineTo(r * 0.45, r * 0.2)
          ..lineTo(0, r * 0.62)
          ..lineTo(-r * 0.45, r * 0.2)
          ..lineTo(-r * 0.55, -r * 0.35)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, stroke);
        canvas.drawLine(Offset(0, -r * 0.35), Offset(0, r * 0.35), stroke..strokeWidth = size * 0.05);
      case ItemKind.zap:
        final path = Path()
          ..moveTo(r * 0.15, -r * 0.65)
          ..lineTo(-r * 0.35, r * 0.05)
          ..lineTo(r * 0.0, r * 0.05)
          ..lineTo(-r * 0.15, r * 0.65)
          ..lineTo(r * 0.35, -r * 0.1)
          ..lineTo(r * 0.0, -r * 0.1)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, stroke);
      case ItemKind.comet:
        canvas.drawCircle(Offset(r * 0.15, 0), r * 0.4, paint);
        canvas.drawCircle(Offset(r * 0.15, 0), r * 0.4, stroke);
        final tail = Path()
          ..moveTo(-r * 0.05, -r * 0.3)
          ..lineTo(-r * 0.75, -r * 0.15)
          ..lineTo(-r * 0.5, 0)
          ..lineTo(-r * 0.75, r * 0.15)
          ..lineTo(-r * 0.05, r * 0.3)
          ..close();
        canvas.drawPath(tail, Paint()..color = NtColors.sunny);
        canvas.drawPath(tail, stroke);
    }
    if (charges > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '×$charges',
          style: TextStyle(fontFamily: NtType.displayFont, fontSize: size * 0.3, fontWeight: FontWeight.w700, color: const Color(0xFFFFFFFF)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r * 0.35, r * 0.3));
    }
  }

  static Color itemColor(ItemKind kind) => switch (kind) {
    ItemKind.turbo || ItemKind.tripleTurbo => NtColors.sunny,
    ItemKind.rocket => NtColors.nitro,
    ItemKind.orb => NtColors.lime,
    ItemKind.slick => const Color(0xFF433B5F),
    ItemKind.shield => NtColors.sky,
    ItemKind.zap => NtColors.grape,
    ItemKind.comet => NtColors.bubblegum,
  };

  /// Item box: a spinning translucent cube seen from above.
  static void drawItemBox(Canvas canvas, double time, {bool alive = true, double scale = 1}) {
    canvas.save();
    canvas.scale(scale);
    if (!alive) {
      canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0x33FFFFFF));
      canvas.restore();
      return;
    }
    canvas.rotate(time * 1.6);
    final rect = Rect.fromCenter(center: Offset.zero, width: 12, height: 12);
    final shader = ui.Gradient.sweep(
      Offset.zero,
      [NtColors.bubblegum, NtColors.sunny, NtColors.mint, NtColors.sky, NtColors.grape, NtColors.bubblegum],
      const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..shader = shader
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.rotate(-time * 1.6);
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(fontFamily: NtType.displayFont, fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  /// Small face badge for a character (used in HUD, lobby, results).
  static void drawFace(Canvas canvas, Color color, double size, {bool bot = false}) {
    final r = size / 2;
    canvas.drawCircle(Offset.zero, r, Paint()..color = ink);
    canvas.drawCircle(Offset.zero, r - size * 0.07, Paint()..color = HSLColor.fromColor(color).withLightness(0.8).toColor());
    // Visor.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -r * 0.05), width: r * 1.15, height: r * 0.62), Radius.circular(r * 0.3)),
      Paint()..color = bot ? const Color(0xFF5B5478) : const Color(0xFF3A6EA5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-r * 0.2, -r * 0.15), width: r * 0.4, height: r * 0.18), Radius.circular(r * 0.1)),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6),
    );
    // Helmet stripe in the character colour.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r - size * 0.14),
      -math.pi * 0.85,
      math.pi * 0.7,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.12,
    );
  }
}
