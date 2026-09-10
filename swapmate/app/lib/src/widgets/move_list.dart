import 'package:flutter/material.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../theme/tokens.dart';
import 'common.dart';

/// Two-column move list, one column per board, in BPGN order.
class MoveList extends StatefulWidget {
  const MoveList({
    super.key,
    required this.moves,
    this.dense = false,
    this.header = true,
  });

  final List<MatchMove> moves;
  final bool dense;
  final bool header;

  @override
  State<MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<MoveList> {
  final _a = ScrollController();
  final _b = ScrollController();

  @override
  void didUpdateWidget(MoveList old) {
    super.didUpdateWidget(old);
    if (old.moves.length != widget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in [_a, _b]) {
          if (c.hasClients) {
            c.animateTo(
              c.position.maxScrollExtent,
              duration: Motion.base,
              curve: Motion.curve,
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = widget.moves.where((m) => m.board == BoardId.a).toList();
    final b = widget.moves.where((m) => m.board == BoardId.b).toList();
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (widget.header)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.md,
                Space.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.list_alt_outlined, size: 16, color: c.textMuted),
                  const SizedBox(width: Space.sm),
                  Text('Moves', style: context.type.titleSmall),
                  const Spacer(),
                  Text(
                    '${widget.moves.length}',
                    key: const Key('move-count'),
                    style: context.type.labelSmall,
                  ),
                ],
              ),
            ),
          if (widget.header) Divider(color: c.outline),
          Expanded(
            child: widget.moves.isEmpty
                ? Center(
                    child: Text(
                      'No moves yet',
                      style: context.type.bodySmall?.copyWith(
                        color: c.textFaint,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _Column(
                          title: 'Board A',
                          moves: a,
                          controller: _a,
                          dense: widget.dense,
                        ),
                      ),
                      VerticalDivider(color: c.outline, width: 1),
                      Expanded(
                        child: _Column(
                          title: 'Board B',
                          moves: b,
                          controller: _b,
                          dense: widget.dense,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.moves,
    required this.controller,
    required this.dense,
  });
  final String title;
  final List<MatchMove> moves;
  final ScrollController controller;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = <List<MatchMove?>>[];
    for (final m in moves) {
      if (m.color == PieceColor.white) {
        rows.add([m, null]);
      } else if (rows.isNotEmpty &&
          rows.last[1] == null &&
          rows.last[0]!.number == m.number) {
        rows.last[1] = m;
      } else {
        rows.add([null, m]);
      }
    }
    final style = (dense ? context.type.bodySmall : context.type.bodyMedium)
        ?.copyWith(color: c.text);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.md,
            Space.xs,
          ),
          child: Row(
            children: [
              Text(title.toUpperCase(), style: context.type.labelSmall),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              final n = (r[0] ?? r[1])!.number;
              final last = i == rows.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: Space.xs,
                ),
                decoration: BoxDecoration(
                  color: last ? c.surfaceSunken : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        '$n.',
                        style: style?.copyWith(color: c.textFaint),
                      ),
                    ),
                    Expanded(child: Text(r[0]?.san ?? '…', style: style)),
                    Expanded(child: Text(r[1]?.san ?? '', style: style)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
