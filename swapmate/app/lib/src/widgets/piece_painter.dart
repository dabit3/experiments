import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../theme/tokens.dart';

/// Draws Swapmate's original vector piece set. Pieces are designed in a
/// 100x100 unit box and scaled to the target rect so they look identical at
/// every size and on every platform.
class PiecePainter extends CustomPainter {
  PiecePainter({
    required this.piece,
    required this.colors,
    this.opacity = 1,
    this.shadow = true,
  });

  final Piece piece;
  final SwapColors colors;
  final double opacity;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    final isWhite = piece.color == PieceColor.white;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? [
                Colors.white.withValues(alpha: opacity),
                colors.pieceWhite.withValues(alpha: opacity),
                const Color(0xFFDFCDA4).withValues(alpha: opacity),
              ]
            : [
                const Color(0xFF557887).withValues(alpha: opacity),
                colors.pieceBlack.withValues(alpha: opacity),
                const Color(0xFF132931).withValues(alpha: opacity),
              ],
        stops: const [0, 0.5, 1],
      ).createShader(const Rect.fromLTWH(20, 8, 60, 86))
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = (isWhite ? colors.pieceWhiteOutline : colors.pieceBlackOutline)
          .withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final detail = Paint()
      ..color = (isWhite ? colors.pieceWhiteOutline : colors.pieceBlackOutline)
          .withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final body = _path(piece.type);
    if (shadow) {
      canvas.drawOval(
        const Rect.fromLTWH(18, 87, 64, 10),
        Paint()
          ..color = const Color(0xFF102E2D).withValues(alpha: opacity * 0.22),
      );
      canvas.drawPath(
        body.shift(const Offset(0, 4)),
        Paint()
          ..color = colors.shadow.withValues(alpha: 0.35 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
    canvas.drawPath(
      body.shift(const Offset(0, 3)),
      Paint()..color = colors.pieceWhiteOutline.withValues(alpha: opacity),
    );
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
      body.shift(const Offset(1.8, 2.2)),
      Paint()
        ..color = Colors.white.withValues(
          alpha: opacity * (isWhite ? 0.85 : 0.3),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
    _details(canvas, piece.type, detail, fill, stroke);
    canvas.drawLine(
      const Offset(30, 86),
      const Offset(70, 86),
      Paint()
        ..color = (isWhite ? const Color(0xFFC2AE7D) : const Color(0xFF719992))
            .withValues(alpha: opacity)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  static Path _base(Path p, {double w = 30, double y = 86}) {
    p.moveTo(50 - w, y);
    p.quadraticBezierTo(50 - w, y - 8, 50 - w + 6, y - 8);
    p.lineTo(50 + w - 6, y - 8);
    p.quadraticBezierTo(50 + w, y - 8, 50 + w, y);
    p.quadraticBezierTo(50 + w, y + 8, 50 + w - 6, y + 8);
    p.lineTo(50 - w + 6, y + 8);
    p.quadraticBezierTo(50 - w, y + 8, 50 - w, y);
    p.close();
    return p;
  }

  static Path _path(PieceType t) {
    final p = Path();
    switch (t) {
      case PieceType.pawn:
        _base(p, w: 24, y: 86);
        // neck + body
        p.moveTo(34, 78);
        p.quadraticBezierTo(38, 58, 44, 50);
        p.lineTo(56, 50);
        p.quadraticBezierTo(62, 58, 66, 78);
        p.close();
        // collar
        p.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(38, 45, 24, 7),
            const Radius.circular(3.5),
          ),
        );
        // head
        p.addOval(Rect.fromCircle(center: const Offset(50, 32), radius: 13));
      case PieceType.rook:
        _base(p, w: 28, y: 86);
        p.moveTo(31, 78);
        p.lineTo(34, 40);
        p.lineTo(66, 40);
        p.lineTo(69, 78);
        p.close();
        // crenellated top
        p.moveTo(29, 40);
        p.lineTo(29, 18);
        p.lineTo(39, 18);
        p.lineTo(39, 26);
        p.lineTo(45, 26);
        p.lineTo(45, 18);
        p.lineTo(55, 18);
        p.lineTo(55, 26);
        p.lineTo(61, 26);
        p.lineTo(61, 18);
        p.lineTo(71, 18);
        p.lineTo(71, 40);
        p.close();
      case PieceType.knight:
        _base(p, w: 28, y: 86);
        p.moveTo(30, 78);
        p.cubicTo(30, 60, 38, 52, 44, 44); // back of neck
        p.cubicTo(36, 46, 30, 44, 30, 38); // throat curve
        p.cubicTo(30, 34, 34, 34, 37, 33); // jaw
        p.lineTo(41, 28); // muzzle bottom
        p.cubicTo(43, 24, 50, 20, 52, 15); // nose up
        p.lineTo(56, 22); // ear front
        p.lineTo(62, 14); // ear tip
        p.cubicTo(66, 22, 70, 30, 70, 44); // back of head
        p.cubicTo(70, 58, 70, 66, 70, 78);
        p.close();
      case PieceType.bishop:
        _base(p, w: 26, y: 86);
        p.moveTo(34, 78);
        p.quadraticBezierTo(38, 62, 40, 56);
        p.lineTo(60, 56);
        p.quadraticBezierTo(62, 62, 66, 78);
        p.close();
        // mitre
        p.moveTo(50, 22);
        p.cubicTo(64, 30, 66, 44, 60, 56);
        p.lineTo(40, 56);
        p.cubicTo(34, 44, 36, 30, 50, 22);
        p.close();
        p.addOval(Rect.fromCircle(center: const Offset(50, 16), radius: 5));
      case PieceType.queen:
        _base(p, w: 29, y: 86);
        p.moveTo(31, 78);
        p.quadraticBezierTo(36, 60, 38, 48);
        p.lineTo(62, 48);
        p.quadraticBezierTo(64, 60, 69, 78);
        p.close();
        // crown
        p.moveTo(34, 48);
        p.lineTo(26, 24);
        p.lineTo(38, 38);
        p.lineTo(42, 18);
        p.lineTo(50, 36);
        p.lineTo(58, 18);
        p.lineTo(62, 38);
        p.lineTo(74, 24);
        p.lineTo(66, 48);
        p.close();
        for (final c in const [
          Offset(26, 22),
          Offset(42, 15),
          Offset(58, 15),
          Offset(74, 22),
        ]) {
          p.addOval(Rect.fromCircle(center: c, radius: 3.6));
        }
      case PieceType.king:
        _base(p, w: 29, y: 86);
        p.moveTo(31, 78);
        p.quadraticBezierTo(36, 60, 38, 48);
        p.lineTo(62, 48);
        p.quadraticBezierTo(64, 60, 69, 78);
        p.close();
        // crown body
        p.moveTo(34, 48);
        p.cubicTo(28, 40, 30, 30, 40, 30);
        p.lineTo(60, 30);
        p.cubicTo(70, 30, 72, 40, 66, 48);
        p.close();
        // cross
        p.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(47, 8, 6, 22),
            const Radius.circular(2),
          ),
        );
        p.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(41, 14, 18, 6),
            const Radius.circular(2),
          ),
        );
    }
    return p;
  }

  static void _details(
    Canvas c,
    PieceType t,
    Paint detail,
    Paint fill,
    Paint stroke,
  ) {
    switch (t) {
      case PieceType.knight:
        // eye + mane
        c.drawCircle(const Offset(58, 30), 2.2, Paint()..color = detail.color);
        c.drawLine(const Offset(62, 46), const Offset(60, 66), detail);
      case PieceType.bishop:
        c.drawLine(const Offset(50, 30), const Offset(50, 48), detail);
        c.drawLine(const Offset(40, 56), const Offset(60, 56), detail);
      case PieceType.rook:
        c.drawLine(const Offset(34, 40), const Offset(66, 40), detail);
      case PieceType.queen:
        c.drawLine(const Offset(38, 48), const Offset(62, 48), detail);
        c.drawLine(const Offset(36, 56), const Offset(64, 56), detail);
      case PieceType.king:
        c.drawLine(const Offset(38, 48), const Offset(62, 48), detail);
        c.drawLine(const Offset(36, 56), const Offset(64, 56), detail);
      case PieceType.pawn:
        break;
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece ||
      old.colors != colors ||
      old.opacity != opacity ||
      old.shadow != shadow;
}

/// A piece rendered at a given size.
class PieceGlyph extends StatelessWidget {
  const PieceGlyph(
    this.piece, {
    super.key,
    this.size = 40,
    this.opacity = 1,
    this.shadow = true,
  });

  final Piece piece;
  final double size;
  final double opacity;
  final bool shadow;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(size),
      painter: PiecePainter(
        piece: piece,
        colors: context.colors,
        opacity: opacity,
        shadow: shadow,
      ),
    ),
  );
}

/// Swapmate's mark: two overlapping rounded squares with a swap arrow.
class SwapmateMark extends StatelessWidget {
  const SwapmateMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _MarkPainter(context.colors),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.colors);
  final SwapColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.scale(s);
    final r = const Radius.circular(18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, 6, 58, 58), r),
      Paint()..color = colors.teamOne,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(36, 36, 58, 58), r),
      Paint()..color = colors.teamTwo,
    );
    final arrow = Paint()
      ..color = colors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final p = Path()
      ..moveTo(28, 62)
      ..arcTo(
        const Rect.fromLTWH(28, 28, 44, 44),
        math.pi * 0.75,
        -math.pi * 1.1,
        false,
      );
    canvas.drawPath(p, arrow);
    canvas.drawPath(
      Path()
        ..moveTo(58, 24)
        ..lineTo(70, 30)
        ..lineTo(62, 40),
      arrow,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.colors != colors;
}
