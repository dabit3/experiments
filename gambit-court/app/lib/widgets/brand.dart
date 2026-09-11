import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class GcMark extends StatelessWidget {
  const GcMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GcArcade.sunshine,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: const [
          BoxShadow(color: Color(0xFF9A701B), offset: Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final crown = Path()
      ..moveTo(9, 24)
      ..lineTo(30, 43)
      ..lineTo(50, 13)
      ..lineTo(70, 43)
      ..lineTo(91, 24)
      ..lineTo(80, 72)
      ..lineTo(20, 72)
      ..close();
    final paint = Paint()..color = GcArcade.midnight;
    canvas.drawPath(crown, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 80, 60, 8),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
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
          GcMark(size: size * 1.8),
          SizedBox(width: size * 0.6),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GAMBIT', style: GcType.display(c.text, size: size)),
            Text('C O U R T', style: GcType.label(c.brass, size: size * 0.56)),
          ],
        ),
      ],
    );
  }
}
