import 'package:flutter/material.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../../theme/tokens.dart';

/// Original vector piece set ("Court" set). Every glyph is authored in a
/// 100x100 box and scaled to the square, so all four platforms rasterise
/// the identical geometry.
class PieceGlyph extends StatelessWidget {
  const PieceGlyph(
    this.piece, {
    super.key,
    required this.size,
    this.shadow = false,
    this.opacity = 1,
  });

  final Piece piece;
  final double size;
  final bool shadow;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GcColors>()!;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: PiecePainter(piece, colors, shadow: shadow, opacity: opacity),
      ),
    );
  }
}

class PiecePainter extends CustomPainter {
  const PiecePainter(
    this.piece,
    this.colors, {
    this.shadow = false,
    this.opacity = 1,
  });

  final Piece piece;
  final GcColors colors;
  final bool shadow;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    if (opacity < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    }
    canvas.scale(scale);
    final white = piece.isWhite;
    final fill = white ? colors.pieceWhite : colors.pieceBlack;
    final ink = white ? colors.pieceWhiteInk : colors.pieceBlackInk;
    final detail = white
        ? colors.pieceWhiteInk
        : colors.pieceWhite.withValues(alpha: 0.55);

    final body = _bodyPath(piece.type);
    if (shadow) {
      canvas.drawPath(
        body.shift(const Offset(0, 6)),
        Paint()
          ..color = colors.shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    } else {
      canvas.drawPath(
        body.shift(const Offset(0, 1.5)),
        Paint()
          ..color = colors.shadow.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
    }
    canvas.drawPath(body, Paint()..color = fill);
    canvas.drawPath(
      body,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );
    _details(canvas, piece.type, detail, ink, white);
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  static final Map<PieceType, Path> _cache = {};

  Path _bodyPath(PieceType type) => _cache.putIfAbsent(type, () {
    final u = _Union();
    switch (type) {
      case PieceType.pawn:
        u.addOval(Rect.fromCircle(center: const Offset(50, 29), radius: 11.5));
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(36, 41, 64, 48),
            const Radius.circular(3),
          ),
        );
        u.add(
          Path()
            ..moveTo(41.5, 47)
            ..cubicTo(41, 58, 36, 66, 30, 77)
            ..lineTo(70, 77)
            ..cubicTo(64, 66, 59, 58, 58.5, 47)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(25, 76, 75, 88),
            const Radius.circular(4),
          ),
        );
      case PieceType.rook:
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(22, 77, 78, 88),
            const Radius.circular(4),
          ),
        );
        u.add(
          Path()
            ..moveTo(31, 42)
            ..lineTo(69, 42)
            ..lineTo(66, 77)
            ..lineTo(34, 77)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(27, 33, 73, 43),
            const Radius.circular(2),
          ),
        );
        u.addRect(const Rect.fromLTRB(27, 18, 38, 34));
        u.addRect(const Rect.fromLTRB(44.5, 18, 55.5, 34));
        u.addRect(const Rect.fromLTRB(62, 18, 73, 34));
      case PieceType.knight:
        u.add(
          Path()
            ..moveTo(27, 77)
            ..lineTo(73, 77)
            ..lineTo(72, 62)
            ..cubicTo(74, 46, 70, 30, 58, 22)
            ..lineTo(56, 10)
            ..lineTo(49, 19)
            ..lineTo(43, 9)
            ..lineTo(40, 20)
            ..cubicTo(30, 24, 22, 34, 19, 46)
            ..lineTo(16, 52)
            ..cubicTo(16, 56, 20, 58, 25, 57)
            ..lineTo(31, 54)
            ..cubicTo(37, 58, 42, 64, 40, 70)
            ..cubicTo(38, 74, 32, 76, 27, 77)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(22, 77, 78, 88),
            const Radius.circular(4),
          ),
        );
      case PieceType.bishop:
        u.addOval(Rect.fromCircle(center: const Offset(50, 14), radius: 5.5));
        u.add(
          Path()
            ..moveTo(50, 19)
            ..cubicTo(73, 33, 73, 56, 50, 63)
            ..cubicTo(27, 56, 27, 33, 50, 19)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(35, 61, 65, 69),
            const Radius.circular(3),
          ),
        );
        u.add(
          Path()
            ..moveTo(40, 69)
            ..lineTo(60, 69)
            ..lineTo(66, 77)
            ..lineTo(34, 77)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(24, 77, 76, 88),
            const Radius.circular(4),
          ),
        );
      case PieceType.queen:
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(22, 77, 78, 88),
            const Radius.circular(4),
          ),
        );
        u.add(
          Path()
            ..moveTo(32, 77)
            ..lineTo(68, 77)
            ..lineTo(64, 57)
            ..lineTo(36, 57)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(33, 53, 67, 60),
            const Radius.circular(3),
          ),
        );
        u.add(
          Path()
            ..moveTo(35, 55)
            ..lineTo(23, 28)
            ..lineTo(33.5, 43)
            ..lineTo(37, 17)
            ..lineTo(44.5, 40)
            ..lineTo(50, 13)
            ..lineTo(55.5, 40)
            ..lineTo(63, 17)
            ..lineTo(66.5, 43)
            ..lineTo(77, 28)
            ..lineTo(65, 55)
            ..close(),
        );
        for (final c in const [
          Offset(23, 26),
          Offset(37, 15),
          Offset(50, 11),
          Offset(63, 15),
          Offset(77, 26),
        ]) {
          u.addOval(Rect.fromCircle(center: c, radius: 3.6));
        }
      case PieceType.king:
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(22, 77, 78, 88),
            const Radius.circular(4),
          ),
        );
        u.add(
          Path()
            ..moveTo(32, 77)
            ..lineTo(68, 77)
            ..lineTo(64, 57)
            ..lineTo(36, 57)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(33, 53, 67, 60),
            const Radius.circular(3),
          ),
        );
        u.add(
          Path()
            ..moveTo(36, 55)
            ..cubicTo(24, 44, 28, 28, 42, 30)
            ..lineTo(58, 30)
            ..cubicTo(72, 28, 76, 44, 64, 55)
            ..close(),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(47, 8, 53, 31),
            const Radius.circular(1.5),
          ),
        );
        u.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTRB(41, 14, 59, 20),
            const Radius.circular(1.5),
          ),
        );
    }
    return u.path;
  });

  void _details(
    Canvas canvas,
    PieceType type,
    Color detail,
    Color ink,
    bool white,
  ) {
    final line = Paint()
      ..color = detail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    switch (type) {
      case PieceType.pawn:
        canvas.drawLine(const Offset(32, 76), const Offset(68, 76), line);
      case PieceType.rook:
        canvas.drawLine(const Offset(30, 43), const Offset(70, 43), line);
        canvas.drawLine(const Offset(34, 76), const Offset(66, 76), line);
        canvas.drawLine(
          const Offset(38, 50),
          const Offset(62, 50),
          line..strokeWidth = 1.4,
        );
      case PieceType.knight:
        canvas.drawCircle(const Offset(37, 32), 2.6, Paint()..color = ink);
        canvas.drawCircle(const Offset(23, 49), 1.6, Paint()..color = ink);
        canvas.drawLine(
          const Offset(46, 30),
          const Offset(64, 46),
          line..strokeWidth = 1.8,
        );
        canvas.drawLine(
          const Offset(30, 76),
          const Offset(70, 76),
          line..strokeWidth = 2,
        );
      case PieceType.bishop:
        final slit = Paint()
          ..color = white ? ink : detail
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(53, 28), const Offset(61, 44), slit);
        canvas.drawLine(const Offset(36, 68), const Offset(64, 68), line);
        canvas.drawLine(const Offset(30, 76), const Offset(70, 76), line);
      case PieceType.queen:
        canvas.drawLine(const Offset(36, 59), const Offset(64, 59), line);
        canvas.drawLine(const Offset(30, 76), const Offset(70, 76), line);
      case PieceType.king:
        canvas.drawLine(const Offset(36, 59), const Offset(64, 59), line);
        canvas.drawLine(const Offset(30, 76), const Offset(70, 76), line);
        canvas.drawLine(
          const Offset(50, 36),
          const Offset(50, 52),
          line..strokeWidth = 1.8,
        );
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece ||
      old.colors != colors ||
      old.shadow != shadow ||
      old.opacity != opacity;
}

/// Accumulates sub-shapes with a geometric union so overlapping parts never
/// cancel each other out regardless of winding direction.
class _Union {
  Path path = Path();

  void add(Path part) {
    path = Path.combine(PathOperation.union, path, part);
  }

  void addOval(Rect rect) => add(Path()..addOval(rect));
  void addRect(Rect rect) => add(Path()..addRect(rect));
  void addRRect(RRect rrect) => add(Path()..addRRect(rrect));
}
