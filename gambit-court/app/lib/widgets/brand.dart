import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Original Gambit Court mark: a 2x2 checker tile with a brass corner,
/// plus the Fraunces wordmark.
class GcMark extends StatelessWidget {
  const GcMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(c.brass, c.text, c.bg),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.brass, this.ink, this.bg);
  final Color brass;
  final Color ink;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.28),
    );
    canvas.save();
    canvas.clipRRect(r);
    final half = size.width / 2;
    final paintInk = Paint()..color = ink;
    final paintBg = Paint()..color = bg;
    canvas.drawRect(Rect.fromLTWH(0, 0, half, half), paintInk);
    canvas.drawRect(Rect.fromLTWH(half, half, half, half), paintInk);
    canvas.drawRect(Rect.fromLTWH(half, 0, half, half), paintBg);
    canvas.drawRect(Rect.fromLTWH(0, half, half, half), paintBg);
    canvas.drawRect(Rect.fromLTWH(half, 0, half, half), Paint()..color = brass);
    canvas.drawCircle(
      Offset(half * 0.5, half * 1.5),
      size.width * 0.13,
      Paint()..color = brass,
    );
    canvas.restore();
    canvas.drawRRect(
      r,
      Paint()
        ..color = ink.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.brass != brass || old.ink != ink || old.bg != bg;
}

class GcWordmark extends StatelessWidget {
  const GcWordmark({super.key, this.size = 22, this.showMark = true});
  final double size;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) ...[
          GcMark(size: size * 1.25),
          SizedBox(width: size * 0.5),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Gambit ',
                style: GcType.title(c.text, size: size),
              ),
              TextSpan(
                text: 'Court',
                style: GcType.displayItalic(
                  c.brass,
                  size: size,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
