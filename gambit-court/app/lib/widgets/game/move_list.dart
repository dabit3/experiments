import 'package:flutter/material.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../ui.dart';

/// Algebraic move list. Vertical (two columns per move number) on wide
/// layouts, a horizontal ribbon on phones. Tapping a move browses history.
class MoveList extends StatefulWidget {
  const MoveList({
    super.key,
    required this.moves,
    required this.viewPly,
    required this.onSelectPly,
    this.horizontal = false,
    this.result,
  });

  final List<PlayedMove> moves;

  /// Ply currently displayed (moves.length when live).
  final int viewPly;
  final void Function(int ply) onSelectPly;
  final bool horizontal;
  final GameResult? result;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final _controller = ScrollController();
  int _lastCount = -1;
  int _lastView = -1;

  @override
  void didUpdateWidget(covariant MoveList old) {
    super.didUpdateWidget(old);
    if (widget.moves.length != _lastCount || widget.viewPly != _lastView) {
      _lastCount = widget.moves.length;
      _lastView = widget.viewPly;
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  void _follow() {
    if (!_controller.hasClients) return;
    final live = widget.viewPly >= widget.moves.length;
    if (!live && !widget.horizontal) {
      final row = (widget.viewPly - 1) ~/ 2;
      final target = (row * 30.0 - 60).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      );
      _controller.animateTo(
        target,
        duration: GcMotion.fast,
        curve: GcMotion.enter,
      );
      return;
    }
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: GcMotion.medium,
      curve: GcMotion.enter,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    if (widget.moves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GcSpace.lg),
          child: Text(
            widget.horizontal ? 'No moves yet' : 'Moves will appear here.',
            style: GcType.body(c.textFaint, size: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (widget.horizontal) return _ribbon(context);
    return _table(context);
  }

  Widget _ribbon(BuildContext context) {
    final c = context.gc;
    return ListView.builder(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: GcSpace.md),
      itemCount: widget.moves.length,
      itemBuilder: (context, i) {
        final number = i.isEven ? '${i ~/ 2 + 1}.' : null;
        return Row(
          children: [
            if (number != null)
              Padding(
                padding: const EdgeInsets.only(left: 6, right: 2),
                child: Text(number, style: GcType.mono(c.textFaint, size: 12)),
              ),
            _MoveCell(
              san: widget.moves[i].san,
              selected: widget.viewPly == i + 1,
              onTap: () => widget.onSelectPly(i + 1),
              dense: true,
            ),
          ],
        );
      },
    );
  }

  Widget _table(BuildContext context) {
    final c = context.gc;
    final rows = (widget.moves.length + 1) ~/ 2;
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: GcSpace.xs),
      itemCount: rows + (widget.result != null ? 1 : 0),
      itemExtent: 30,
      itemBuilder: (context, row) {
        if (row == rows) {
          return Center(
            child: Text(
              '${widget.result!.score}  ·  ${widget.result!.headline} ${widget.result!.reasonLabel}',
              style: GcType.mono(c.textMuted, size: 12),
            ),
          );
        }
        final whiteIndex = row * 2;
        final blackIndex = whiteIndex + 1;
        return Container(
          color: row.isOdd ? c.text.withValues(alpha: 0.025) : null,
          padding: const EdgeInsets.symmetric(horizontal: GcSpace.md),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '${row + 1}.',
                  style: GcType.mono(c.textFaint, size: 12),
                ),
              ),
              Expanded(
                child: _MoveCell(
                  san: widget.moves[whiteIndex].san,
                  selected: widget.viewPly == whiteIndex + 1,
                  onTap: () => widget.onSelectPly(whiteIndex + 1),
                ),
              ),
              Expanded(
                child: blackIndex < widget.moves.length
                    ? _MoveCell(
                        san: widget.moves[blackIndex].san,
                        selected: widget.viewPly == blackIndex + 1,
                        onTap: () => widget.onSelectPly(blackIndex + 1),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoveCell extends StatelessWidget {
  const _MoveCell({
    required this.san,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });
  final String san;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: c.text.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: GcMotion.micro,
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 6 : 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: selected ? c.brassSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected
                    ? c.brass.withValues(alpha: 0.6)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              san,
              style: GcType.mono(
                selected ? c.text : c.textMuted,
                size: 13,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// First / previous / next / last controls for browsing history.
class HistoryControls extends StatelessWidget {
  const HistoryControls({
    super.key,
    required this.viewPly,
    required this.total,
    required this.onSelect,
  });

  final int viewPly;
  final int total;
  final void Function(int ply) onSelect;

  @override
  Widget build(BuildContext context) {
    final atStart = viewPly <= 0;
    final atEnd = viewPly >= total;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GcIconButton(
          icon: Icons.first_page_rounded,
          tooltip: 'First move',
          onPressed: atStart ? null : () => onSelect(0),
          size: 34,
        ),
        GcIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous move (←)',
          onPressed: atStart ? null : () => onSelect(viewPly - 1),
          size: 34,
        ),
        GcIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next move (→)',
          onPressed: atEnd ? null : () => onSelect(viewPly + 1),
          size: 34,
        ),
        GcIconButton(
          icon: Icons.last_page_rounded,
          tooltip: 'Live position',
          onPressed: atEnd ? null : () => onSelect(total),
          size: 34,
        ),
      ],
    );
  }
}
