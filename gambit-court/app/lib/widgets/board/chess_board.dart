import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../../state/app_controller.dart';
import '../../theme/tokens.dart';
import 'piece_glyph.dart';

/// Interactive board: tap-tap and drag-and-drop input, hover feedback for
/// pointer devices, last-move / legal-move / check / premove highlights, and
/// slide animations driven by [BoardTransition].
class ChessBoard extends StatefulWidget {
  const ChessBoard({
    super.key,
    required this.position,
    required this.orientation,
    required this.size,
    this.lastMove,
    this.selected,
    this.premove,
    this.transition,
    this.movableColor,
    this.onTap,
    this.onDrop,
    this.showCoordinates = true,
    this.dimmed = false,
  });

  final Position position;
  final PieceColor orientation;
  final double size;
  final Move? lastMove;
  final int? selected;
  final Move? premove;
  final BoardTransition? transition;

  /// Colour whose pieces may be picked up; null makes the board read-only.
  final PieceColor? movableColor;
  final void Function(int square)? onTap;

  /// Return true when the drop was accepted (a move or premove was issued)
  /// so the board skips the slide animation for the echo from the server.
  final bool Function(int from, int to)? onDrop;
  final bool showCoordinates;
  final bool dimmed;

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: GcMotion.piece,
  );
  Position? _animFrom;
  Move? _animMove;
  int _animSeq = -1;
  Move? _lastDrop;

  int? _dragFrom;
  Offset? _dragPointer;
  int? _hover;
  Piece? _dragPiece;
  int? _tapCandidate;
  Offset? _downAt;

  double get _square => widget.size / 8;

  @override
  void initState() {
    super.initState();
    _slide.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animFrom = null;
          _animMove = null;
        });
      }
    });
    _syncTransition();
  }

  @override
  void didUpdateWidget(covariant ChessBoard old) {
    super.didUpdateWidget(old);
    if (old.transition?.seq != widget.transition?.seq) _syncTransition();
    if (widget.movableColor == null && _dragFrom != null) {
      _dragFrom = null;
      _dragPointer = null;
      _dragPiece = null;
    }
  }

  void _syncTransition() {
    final t = widget.transition;
    if (t == null || t.seq == _animSeq) return;
    _animSeq = t.seq;
    final move = t.move;
    if (move == null) {
      _animFrom = null;
      _animMove = null;
      return;
    }
    final drop = _lastDrop;
    if (drop != null && drop.from == move.from && drop.to == move.to) {
      // The user dragged this piece into place already; do not replay.
      _lastDrop = null;
      return;
    }
    _animFrom = Position.fromFen(t.fromFen);
    _animMove = move;
    _slide
      ..stop()
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ geometry

  Offset _originOf(int square) {
    final file = Square.fileOf(square);
    final rank = Square.rankOf(square);
    final x = widget.orientation == PieceColor.white ? file : 7 - file;
    final y = widget.orientation == PieceColor.white ? 7 - rank : rank;
    return Offset(x * _square, y * _square);
  }

  int? _squareAt(Offset local) {
    final x = (local.dx / _square).floor();
    final y = (local.dy / _square).floor();
    if (x < 0 || x > 7 || y < 0 || y > 7) return null;
    final file = widget.orientation == PieceColor.white ? x : 7 - x;
    final rank = widget.orientation == PieceColor.white ? 7 - y : y;
    return Square.of(file, rank);
  }

  // -------------------------------------------------------------- input

  bool _canPick(int square) {
    final piece = widget.position.pieceAt(square);
    return piece != null &&
        widget.movableColor != null &&
        piece.color == widget.movableColor;
  }

  void _onPanStart(DragStartDetails d) {
    final square = _squareAt(d.localPosition);
    _downAt = d.localPosition;
    _dragPointer = d.localPosition;
    if (square == null) return;
    if (!_canPick(square)) {
      _tapCandidate = square;
      return;
    }
    setState(() {
      _dragFrom = square;
      _dragPiece = widget.position.pieceAt(square);
      _hover = square;
    });
    widget.onTap?.call(square);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _dragPointer = d.localPosition;
    if (_dragFrom == null) return;
    setState(() => _hover = _squareAt(d.localPosition));
  }

  void _onPanEnd(DragEndDetails d) {
    final from = _dragFrom;
    final pointer = _dragPointer;
    final tap = _tapCandidate;
    final down = _downAt;
    _tapCandidate = null;
    _downAt = null;
    if (from == null) {
      if (tap != null &&
          pointer != null &&
          down != null &&
          (pointer - down).distance < _square * 0.5) {
        widget.onTap?.call(tap);
      }
      return;
    }
    setState(() {
      _dragFrom = null;
      _dragPointer = null;
      _dragPiece = null;
    });
    final to = pointer == null ? null : _squareAt(pointer);
    if (to == null || to == from) return;
    final accepted = widget.onDrop?.call(from, to) ?? false;
    if (accepted) _lastDrop = Move(from, to);
  }

  void _onPanCancel() {
    _tapCandidate = null;
    _downAt = null;
    if (_dragFrom == null) return;
    setState(() {
      _dragFrom = null;
      _dragPointer = null;
      _dragPiece = null;
    });
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GcColors>()!;
    final pos = widget.position;
    final selected = widget.selected;
    final legal = <int, bool>{};
    if (selected != null && widget.movableColor != null) {
      final own = pos.pieceAt(selected)?.color == widget.movableColor;
      if (own && pos.turn == widget.movableColor) {
        for (final m in pos.legalMovesFrom(selected)) {
          legal[m.to] = pos.isCapture(m);
        }
      }
    }
    final checkSquare = pos.isInCheck ? pos.kingSquare(pos.turn) : null;

    return SizedBox.square(
      dimension: widget.size,
      child: MouseRegion(
        cursor: _cursorFor(),
        onHover: (e) {
          final sq = _squareAt(e.localPosition);
          if (sq != _hover) setState(() => _hover = sq);
        },
        onExit: (_) => setState(() => _hover = null),
        child: RawGestureDetector(
          gestures: {
            _ImmediatePanRecognizer:
                GestureRecognizerFactoryWithHandlers<_ImmediatePanRecognizer>(
                  _ImmediatePanRecognizer.new,
                  (r) => r
                    ..onStart = _onPanStart
                    ..onUpdate = _onPanUpdate
                    ..onEnd = _onPanEnd
                    ..onCancel = _onPanCancel,
                ),
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _SquaresPainter(
                        colors: colors,
                        orientation: widget.orientation,
                        lastMove: widget.lastMove,
                        selected: selected,
                        legal: legal,
                        premove: widget.premove,
                        checkSquare: checkSquare,
                        hover: _dragFrom != null ? _hover : null,
                        showCoordinates: widget.showCoordinates,
                        squareSize: _square,
                      ),
                    ),
                  ),
                ),
                ..._pieces(pos),
                if (_dragPiece != null && _dragPointer != null)
                  Positioned(
                    left: _dragPointer!.dx - _square * 0.6,
                    top: _dragPointer!.dy - _square * 0.72,
                    child: IgnorePointer(
                      child: PieceGlyph(
                        _dragPiece!,
                        size: _square * 1.2,
                        shadow: true,
                      ),
                    ),
                  ),
                if (widget.dimmed)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.bg.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MouseCursor _cursorFor() {
    if (_dragFrom != null) return SystemMouseCursors.grabbing;
    final h = _hover;
    if (h != null && _canPick(h)) return SystemMouseCursors.grab;
    return SystemMouseCursors.basic;
  }

  List<Widget> _pieces(Position pos) {
    final widgets = <Widget>[];
    final pieceSize = _square * 0.86;
    final inset = (_square - pieceSize) / 2;
    final animMove = _animMove;
    final animFrom = _animFrom;
    final animating =
        animMove != null && animFrom != null && _slide.isAnimating;

    int? rookFrom;
    int? rookTo;
    int? captured;
    if (animating) {
      final mover = animFrom.pieceAt(animMove.from);
      if (mover?.type == PieceType.king &&
          (Square.fileOf(animMove.to) - Square.fileOf(animMove.from)).abs() ==
              2) {
        final rank = Square.rankOf(animMove.from);
        final kingSide = Square.fileOf(animMove.to) == 6;
        rookFrom = Square.of(kingSide ? 7 : 0, rank);
        rookTo = Square.of(kingSide ? 5 : 3, rank);
      }
      if (animFrom.pieceAt(animMove.to) != null) {
        captured = animMove.to;
      } else if (mover?.type == PieceType.pawn &&
          Square.fileOf(animMove.from) != Square.fileOf(animMove.to)) {
        captured = Square.of(
          Square.fileOf(animMove.to),
          Square.rankOf(animMove.from),
        );
      }
    }

    for (var sq = 0; sq < 64; sq++) {
      final piece = pos.pieceAt(sq);
      if (piece == null) continue;
      if (_dragFrom == sq) continue;
      final origin = _originOf(sq) + Offset(inset, inset);
      final glyph = PieceGlyph(piece, size: pieceSize);
      int? slideFrom;
      if (animating) {
        if (sq == animMove.to) {
          slideFrom = animMove.from;
        } else if (rookTo != null && sq == rookTo) {
          slideFrom = rookFrom;
        }
      }
      if (slideFrom != null) {
        widgets.add(
          Positioned(
            key: ValueKey('p$sq'),
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: _Slide(
                animation: _slide,
                from: _originOf(slideFrom) + Offset(inset, inset),
                to: origin,
                child: glyph,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Positioned(
            key: ValueKey('p$sq'),
            left: origin.dx,
            top: origin.dy,
            child: IgnorePointer(child: glyph),
          ),
        );
      }
    }
    if (animating && captured != null) {
      final victim = animFrom.pieceAt(captured);
      if (victim != null) {
        final origin = _originOf(captured);
        widgets.insert(
          0,
          Positioned(
            key: const ValueKey('captured'),
            left: origin.dx + inset,
            top: origin.dy + inset,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: ReverseAnimation(
                  CurvedAnimation(
                    parent: _slide,
                    curve: const Interval(0.3, 1),
                  ),
                ),
                child: PieceGlyph(victim, size: pieceSize),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

/// Slides [child] between two board offsets; the caller positions it at
/// (0,0) and the translation does the rest.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.animation,
    required this.from,
    required this.to,
    required this.child,
  });

  final Animation<double> animation;
  final Offset from;
  final Offset to;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: GcMotion.enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final offset = Offset.lerp(from, to, curved.value)!;
        final lift = math.sin(curved.value * math.pi);
        return Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: 1 + 0.08 * lift,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}

/// A pan recognizer that wins the arena immediately so a drag can start
/// without the default touch slop delay (pieces should stick to the finger).
class _ImmediatePanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'immediate pan';
}

class _SquaresPainter extends CustomPainter {
  _SquaresPainter({
    required this.colors,
    required this.orientation,
    required this.lastMove,
    required this.selected,
    required this.legal,
    required this.premove,
    required this.checkSquare,
    required this.hover,
    required this.showCoordinates,
    required this.squareSize,
  });

  final GcColors colors;
  final PieceColor orientation;
  final Move? lastMove;
  final int? selected;
  final Map<int, bool> legal;
  final Move? premove;
  final int? checkSquare;
  final int? hover;
  final bool showCoordinates;
  final double squareSize;

  Rect _rect(int square) {
    final file = Square.fileOf(square);
    final rank = Square.rankOf(square);
    final x = orientation == PieceColor.white ? file : 7 - file;
    final y = orientation == PieceColor.white ? 7 - rank : rank;
    return Rect.fromLTWH(
      x * squareSize,
      y * squareSize,
      squareSize,
      squareSize,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = colors.boardLight;
    final dark = Paint()..color = colors.boardDark;
    for (var sq = 0; sq < 64; sq++) {
      canvas.drawRect(_rect(sq), Square.isDark(sq) ? dark : light);
    }

    final last = lastMove;
    if (last != null) {
      final p = Paint()..color = colors.lastMove;
      canvas.drawRect(_rect(last.from), p);
      canvas.drawRect(_rect(last.to), p);
    }
    final pre = premove;
    if (pre != null) {
      final p = Paint()..color = colors.premove;
      canvas.drawRect(_rect(pre.from), p);
      canvas.drawRect(_rect(pre.to), p);
    }
    final sel = selected;
    if (sel != null) {
      canvas.drawRect(_rect(sel), Paint()..color = colors.selected);
    }
    final check = checkSquare;
    if (check != null) {
      final r = _rect(check);
      canvas.drawRect(
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [colors.checkGlow, colors.checkGlow.withValues(alpha: 0)],
            stops: const [0.25, 1],
          ).createShader(r.inflate(squareSize * 0.1)),
      );
    }
    for (final entry in legal.entries) {
      final r = _rect(entry.key);
      if (entry.value) {
        canvas.drawCircle(
          r.center,
          squareSize * 0.46,
          Paint()
            ..color = colors.legalDot
            ..style = PaintingStyle.stroke
            ..strokeWidth = squareSize * 0.085,
        );
      } else {
        canvas.drawCircle(
          r.center,
          squareSize * 0.16,
          Paint()..color = colors.legalDot,
        );
      }
    }
    final h = hover;
    if (h != null) {
      canvas.drawRect(
        _rect(h).deflate(squareSize * 0.04),
        Paint()
          ..color = colors.text.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = squareSize * 0.06,
      );
    }

    if (showCoordinates) {
      final fontSize = (squareSize * 0.2).clamp(8.0, 13.0);
      for (var i = 0; i < 8; i++) {
        // Files along the bottom row, ranks along the left column.
        final fileIndex = orientation == PieceColor.white ? i : 7 - i;
        final rankIndex = orientation == PieceColor.white ? 7 - i : i;
        final bottomSquare = Square.of(
          fileIndex,
          orientation == PieceColor.white ? 0 : 7,
        );
        final leftSquare = Square.of(
          orientation == PieceColor.white ? 0 : 7,
          rankIndex,
        );
        _label(
          canvas,
          'abcdefgh'[fileIndex],
          Offset(
            (i + 1) * squareSize - fontSize * 0.75,
            size.height - fontSize * 1.25,
          ),
          Square.isDark(bottomSquare) ? colors.boardLight : colors.boardDark,
          fontSize,
        );
        _label(
          canvas,
          '${rankIndex + 1}',
          Offset(squareSize * 0.08, i * squareSize + squareSize * 0.06),
          Square.isDark(leftSquare) ? colors.boardLight : colors.boardDark,
          fontSize,
        );
      }
    }
  }

  void _label(Canvas canvas, String text, Offset at, Color color, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: GcFonts.mono,
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_SquaresPainter old) =>
      old.colors != colors ||
      old.orientation != orientation ||
      old.lastMove != lastMove ||
      old.selected != selected ||
      old.premove != premove ||
      old.checkSquare != checkSquare ||
      old.hover != hover ||
      old.showCoordinates != showCoordinates ||
      old.squareSize != squareSize ||
      !_sameLegal(old.legal, legal);

  static bool _sameLegal(Map<int, bool> a, Map<int, bool> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
