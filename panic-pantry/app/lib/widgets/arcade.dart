import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class ArcadeBackdrop extends StatelessWidget {
  const ArcadeBackdrop({super.key, this.celebrate = false});
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ArcadePainter(dark: s.isDark, celebrate: celebrate, padding: MediaQuery.paddingOf(context)),
          ),
        ),
      ),
    );
  }
}

class _ArcadePainter extends CustomPainter {
  const _ArcadePainter({required this.dark, required this.celebrate, required this.padding});
  final bool dark;
  final bool celebrate;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size surface) {
    final size = Size(math.max(0, surface.width - padding.horizontal), math.max(0, surface.height - padding.vertical));
    canvas.save();
    canvas.translate(padding.left, padding.top);
    final bounds = Offset.zero & size;
    canvas.drawRect(
      Rect.fromLTWH(-padding.left, -padding.top, surface.width, surface.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.6, -0.7),
          radius: 1.4,
          colors: dark ? const [Color(0xFF275854), Color(0xFF0D252D)] : const [Color(0xFFFFF7E7), Color(0xFFE2D2B4)],
        ).createShader(bounds),
    );
    final dots = Paint()..color = (dark ? Colors.white : PPColor.ink).withValues(alpha: 0.055);
    for (var y = 14.0; y < size.height; y += 24) {
      for (var x = 14.0; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 1.1, dots);
      }
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = (dark ? PPColor.butter : PPColor.basil).withValues(alpha: 0.10);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.1), 100 + i * 32, line);
    }
    final checker = Paint()..color = PPColor.basil.withValues(alpha: dark ? 0.14 : 0.08);
    const tile = 26.0;
    for (var x = 0; x < size.width / tile; x++) {
      for (var y = 0; y < 2; y++) {
        if ((x + y).isEven) {
          canvas.drawRect(Rect.fromLTWH(x * tile, size.height - (y + 1) * tile, tile, tile), checker);
        }
      }
    }
    if (celebrate) {
      const colors = [PPColor.paprika, PPColor.butter, PPColor.basil, PPColor.blueberry];
      for (var i = 0; i < 55; i++) {
        final x = ((i * 137) % 997) / 997 * size.width;
        final y = ((i * 79) % 587) / 587 * size.height;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(i * math.pi / 7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -5, 6, 10), const Radius.circular(2)),
          Paint()..color = colors[i % colors.length].withValues(alpha: 0.55),
        );
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArcadePainter old) => old.dark != dark || old.celebrate != celebrate || old.padding != padding;
}

class ArcadeHeading extends StatelessWidget {
  const ArcadeHeading({super.key, required this.eyebrow, required this.title, this.subtitle});
  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: PPType.caption(s.isDark ? PPColor.butter : PPColor.basil).copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 6),
        Text(title, style: PPType.display(s.text).copyWith(fontSize: 34)),
        if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: PPType.body(s.text2))],
      ],
    );
  }
}
