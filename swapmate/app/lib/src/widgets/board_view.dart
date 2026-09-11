import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../theme/tokens.dart';
import 'piece_painter.dart';

/// Payload dragged from a reserve tray onto the board.
class ReserveDrag {
  const ReserveDrag(this.piece, this.board);
  final Piece piece;
  final BoardId board;
}

/// Interactive chess board.
///
/// Rendering is retained-mode Flutter: squares and highlights are one
/// `CustomPaint`, pieces are keyed `AnimatedPositioned` widgets so moves slide
/// smoothly, and input goes through a single gesture layer that supports
/// tap-tap, drag-and-drop and reserve drops.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.position,
    required this.orientation,
    required this.boardId,
    this.lastMove,
    this.premove,
    this.selected,
    this.targets = const {},
    this.inCheck = false,
    this.interactive = false,
    this.showCoordinates = true,
    this.onSquareTap,
    this.onDragMove,
    this.onReserveDrop,
    this.dropTargets = const {},
    this.dimmed = false,
  });

  final Position position;
  final PieceColor orientation;
  final BoardId boardId;
  final Move? lastMove;
  final Move? premove;
  final int? selected;
  final Set<int> targets;
  final bool inCheck;
  final bool interactive;
  final bool showCoordinates;
  final void Function(int square)? onSquareTap;
  final void Function(int from, int to)? onDragMove;
  final void Function(PieceType type, int to)? onReserveDrop;

  /// Squares highlighted while a reserve piece is being dragged.
  final Set<int> dropTargets;
  final bool dimmed;

  /// Converts a square to its rect within a board of [size].
  static Rect squareRect(int square, double size, PieceColor orientation) {
    final cell = size / 8;
    final f = Square.fileOf(square);
    final r = Square.rankOf(square);
    final x = orientation == PieceColor.white ? f : 7 - f;
    final y = orientation == PieceColor.white ? 7 - r : r;
    return Rect.fromLTWH(x * cell, y * cell, cell, cell);
  }

  static int? squareAt(Offset local, double size, PieceColor orientation) {
    if (local.dx < 0 || local.dy < 0 || local.dx >= size || local.dy >= size) {
      return null;
    }
    final cell = size / 8;
    final x = (local.dx / cell).floor();
    final y = (local.dy / cell).floor();
    final f = orientation == PieceColor.white ? x : 7 - x;
    final r = orientation == PieceColor.white ? 7 - y : y;
    return Square.of(f, r);
  }

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  /// Stable ids so the same widget animates from one square to another.
  final Map<int, int> _ids = {};
  int _nextId = 1;
  Position? _lastPosition;

  int? _dragFrom;
  Offset? _dragPos;
  int? _hoverSquare;

  @override
  void initState() {
    super.initState();
    _assignIds(null);
  }

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position) _assignIds(old.position);
  }

  void _assignIds(Position? previous) {
    final pos = widget.position;
    final next = <int, int>{};
    final lm = widget.lastMove;
    final prev = _lastPosition ?? previous;
    if (prev != null && lm != null) {
      // Carry ids through the last move so the mover slides.
      final moved = <int>{};
      if (!lm.isDrop && _ids.containsKey(lm.from!)) {
        final piece = pos.at(lm.to);
        if (piece != null) {
          next[lm.to] = _ids[lm.from!]!;
          moved.add(lm.to);
        }
        // Castling: rook slides too.
        final df = Square.fileOf(lm.to) - Square.fileOf(lm.from!);
        final mover = prev.at(lm.from!);
        if (mover?.type == PieceType.king && df.abs() == 2) {
          final rank = Square.rankOf(lm.from!);
          final rookFrom = Square.of(df > 0 ? 7 : 0, rank);
          final rookTo = Square.of(df > 0 ? 5 : 3, rank);
          if (_ids.containsKey(rookFrom)) {
            next[rookTo] = _ids[rookFrom]!;
            moved.add(rookTo);
          }
        }
      }
      for (var s = 0; s < 64; s++) {
        if (pos.at(s) == null || moved.contains(s)) continue;
        final old = _ids[s];
        final oldPiece = prev.at(s);
        if (old != null && oldPiece == pos.at(s)) {
          next[s] = old;
        } else {
          next[s] = _nextId++;
        }
      }
    } else {
      for (var s = 0; s < 64; s++) {
        if (pos.at(s) != null) next[s] = _ids[s] ?? _nextId++;
      }
    }
    _ids
      ..clear()
      ..addAll(next);
    _lastPosition = pos;
  }

  bool _canPick(int sq) {
    if (!widget.interactive) return false;
    final p = widget.position.at(sq);
    return p != null && p.color == widget.position.turn;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final cell = size / 8;
        return DragTarget<ReserveDrag>(
          onWillAcceptWithDetails: (d) =>
              widget.interactive && d.data.board == widget.boardId,
          onMove: (d) {
            final box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(
              d.offset + Offset(cell / 2, cell / 2),
            );
            final sq = BoardView.squareAt(local, size, widget.orientation);
            if (sq != _hoverSquare) setState(() => _hoverSquare = sq);
          },
          onLeave: (_) => setState(() => _hoverSquare = null),
          onAcceptWithDetails: (d) {
            final box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(
              d.offset + Offset(cell / 2, cell / 2),
            );
            final sq = BoardView.squareAt(local, size, widget.orientation);
            setState(() => _hoverSquare = null);
            if (sq != null) widget.onReserveDrop?.call(d.data.piece.type, sq);
          },
          builder: (context, candidates, rejected) {
            final dragging = candidates.isNotEmpty;
            return SizedBox(
              width: size,
              height: size,
              child: Semantics(
                label: 'Board ${widget.boardId.id.toUpperCase()}',
                child: MouseRegion(
                  cursor: widget.interactive
                      ? SystemMouseCursors.click
                      : MouseCursor.defer,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final sq = BoardView.squareAt(
                        d.localPosition,
                        size,
                        widget.orientation,
                      );
                      if (sq != null) widget.onSquareTap?.call(sq);
                    },
                    onPanStart: (d) {
                      final sq = BoardView.squareAt(
                        d.localPosition,
                        size,
                        widget.orientation,
                      );
                      if (sq != null && _canPick(sq)) {
                        HapticFeedback.selectionClick();
                        widget.onSquareTap?.call(sq);
                        setState(() {
                          _dragFrom = sq;
                          _dragPos = d.localPosition;
                        });
                      }
                    },
                    onPanUpdate: (d) {
                      if (_dragFrom == null) return;
                      setState(() {
                        _dragPos = d.localPosition;
                        _hoverSquare = BoardView.squareAt(
                          d.localPosition,
                          size,
                          widget.orientation,
                        );
                      });
                    },
                    onPanEnd: (d) {
                      final from = _dragFrom;
                      final pos = _dragPos;
                      setState(() {
                        _dragFrom = null;
                        _dragPos = null;
                        _hoverSquare = null;
                      });
                      if (from == null || pos == null) return;
                      final to = BoardView.squareAt(
                        pos,
                        size,
                        widget.orientation,
                      );
                      if (to != null && to != from) {
                        widget.onDragMove?.call(from, to);
                      }
                    },
                    onPanCancel: () => setState(() {
                      _dragFrom = null;
                      _dragPos = null;
                      _hoverSquare = null;
                    }),
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
                                premove: widget.premove,
                                selected: widget.selected,
                                targets: widget.targets,
                                checkSquare: widget.inCheck
                                    ? widget.position.kingSquare(
                                        widget.position.turn,
                                      )
                                    : null,
                                hover: _hoverSquare,
                                dropTargets: dragging
                                    ? widget.dropTargets
                                    : const {},
                                showCoordinates: widget.showCoordinates,
                                position: widget.position,
                              ),
                            ),
                          ),
                        ),
                        for (final e in _ids.entries)
                          _AnimatedPiece(
                            key: ValueKey(e.value),
                            rect: BoardView.squareRect(
                              e.key,
                              size,
                              widget.orientation,
                            ),
                            piece: widget.position.at(e.key)!,
                            hidden: _dragFrom == e.key,
                            dimmed: widget.dimmed,
                          ),
                        if (_dragFrom != null &&
                            _dragPos != null &&
                            widget.position.at(_dragFrom!) != null)
                          Positioned(
                            left: _dragPos!.dx - cell * 0.6,
                            top: _dragPos!.dy - cell * 0.75,
                            child: IgnorePointer(
                              child: PieceGlyph(
                                widget.position.at(_dragFrom!)!,
                                size: cell * 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedPiece extends StatelessWidget {
  const _AnimatedPiece({
    super.key,
    required this.rect,
    required this.piece,
    required this.hidden,
    required this.dimmed,
  });

  final Rect rect;
  final Piece piece;
  final bool hidden;
  final bool dimmed;

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
    duration: Motion.base,
    curve: Motion.curve,
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: IgnorePointer(
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: hidden ? 0 : (dimmed ? 0.55 : 1),
        child: Padding(
          padding: EdgeInsets.all(rect.width * 0.06),
          child: PieceGlyph(piece, size: rect.width * 0.88),
        ),
      ),
    ),
  );
}

class _SquaresPainter extends CustomPainter {
  _SquaresPainter({
    required this.colors,
    required this.orientation,
    required this.lastMove,
    required this.premove,
    required this.selected,
    required this.targets,
    required this.checkSquare,
    required this.hover,
    required this.dropTargets,
    required this.showCoordinates,
    required this.position,
  });

  final SwapColors colors;
  final PieceColor orientation;
  final Move? lastMove;
  final Move? premove;
  final int? selected;
  final Set<int> targets;
  final int? checkSquare;
  final int? hover;
  final Set<int> dropTargets;
  final bool showCoordinates;
  final Position position;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cell = s / 8;
    final light = Paint()..color = colors.boardLight;
    final dark = Paint()..color = colors.boardDark;
    for (var sq = 0; sq < 64; sq++) {
      final r = BoardView.squareRect(sq, s, orientation);
      canvas.drawRect(r, Square.isLight(sq) ? light : dark);
      canvas.drawLine(
        r.topLeft + const Offset(0, 0.5),
        r.topRight + const Offset(0, 0.5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..strokeWidth = 1,
      );
    }
    void fill(int sq, Color c) => canvas.drawRect(
      BoardView.squareRect(sq, s, orientation),
      Paint()..color = c,
    );

    if (lastMove != null) {
      if (!lastMove!.isDrop) fill(lastMove!.from!, colors.highlightMove);
      fill(lastMove!.to, colors.highlightMove);
    }
    if (premove != null) {
      if (!premove!.isDrop) fill(premove!.from!, colors.highlightPremove);
      fill(premove!.to, colors.highlightPremove);
    }
    if (checkSquare != null) {
      final r = BoardView.squareRect(checkSquare!, s, orientation);
      canvas.drawCircle(
        r.center,
        cell * 0.62,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  colors.highlightCheck,
                  colors.highlightCheck.withValues(alpha: 0),
                ],
                stops: const [0.35, 1],
              ).createShader(
                Rect.fromCircle(center: r.center, radius: cell * 0.62),
              ),
      );
    }
    if (selected != null) {
      fill(selected!, colors.highlightSelect);
      canvas.drawRect(
        BoardView.squareRect(selected!, s, orientation).deflate(2),
        Paint()
          ..color = colors.onAccent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    for (final t in dropTargets) {
      final r = BoardView.squareRect(t, s, orientation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.deflate(cell * 0.3),
          Radius.circular(cell * 0.1),
        ),
        Paint()..color = colors.highlightPremove,
      );
    }
    for (final t in targets) {
      final r = BoardView.squareRect(t, s, orientation);
      final occupied = position.at(t) != null;
      if (occupied) {
        canvas.drawCircle(
          r.center,
          cell * 0.46,
          Paint()
            ..color = colors.highlightTarget
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.09,
        );
      } else {
        canvas.drawCircle(
          r.center,
          cell * 0.17,
          Paint()..color = colors.highlightTarget,
        );
      }
    }
    if (hover != null) {
      final r = BoardView.squareRect(hover!, s, orientation);
      canvas.drawRect(
        r.deflate(1.5),
        Paint()
          ..color = colors.text.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (showCoordinates && cell >= 22) {
      final style = TextStyle(
        fontFamily: 'Inter',
        fontSize: (cell * 0.22).clamp(8, 12),
        fontWeight: FontWeight.w600,
      );
      for (var i = 0; i < 8; i++) {
        final file = orientation == PieceColor.white ? i : 7 - i;
        final rank = orientation == PieceColor.white ? 7 - i : i;
        final fileSq = Square.of(file, orientation == PieceColor.white ? 0 : 7);
        final rankSq = Square.of(orientation == PieceColor.white ? 0 : 7, rank);
        final fileColor = Square.isLight(fileSq)
            ? colors.boardDark
            : colors.boardLight;
        final rankColor = Square.isLight(rankSq)
            ? colors.boardDark
            : colors.boardLight;
        final fp = TextPainter(
          text: TextSpan(
            text: 'abcdefgh'[file],
            style: style.copyWith(color: fileColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        fp.paint(
          canvas,
          Offset(
            (i + 1) * cell - fp.width - cell * 0.08,
            s - fp.height - cell * 0.03,
          ),
        );
        final rp = TextPainter(
          text: TextSpan(
            text: '${rank + 1}',
            style: style.copyWith(color: rankColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        rp.paint(canvas, Offset(cell * 0.08, i * cell + cell * 0.04));
      }
    }
  }

  @override
  bool shouldRepaint(_SquaresPainter old) =>
      old.colors != colors ||
      old.orientation != orientation ||
      old.lastMove != lastMove ||
      old.premove != premove ||
      old.selected != selected ||
      old.targets != targets ||
      old.checkSquare != checkSquare ||
      old.hover != hover ||
      old.dropTargets != dropTargets ||
      old.showCoordinates != showCoordinates ||
      old.position != position;
}
