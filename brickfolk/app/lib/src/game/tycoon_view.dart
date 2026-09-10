import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Brick Tycoon: a 6x6 plot, a brick palette and upgrades. Pure widgets —
/// the state is small and changes at most once a second.
class TycoonView extends StatefulWidget {
  const TycoonView({super.key});

  @override
  State<TycoonView> createState() => _TycoonViewState();
}

class _TycoonViewState extends State<TycoonView> {
  String _selected = brickTypes.first.id;
  bool _removeMode = false;
  int? _flashCell;

  TycoonPlot? _plotOf(GameFrame? f, String? id) {
    final plots = f?.json['plots'] as Map?;
    final raw = plots?[id];
    return raw is Map ? TycoonPlot.fromJson(raw.cast()) : null;
  }

  void _tapCell(int cell, TycoonPlot plot) {
    final client = AppScope.read(context).client;
    final haptics = AppScope.read(context).hapticsEnabled;
    if (plot.cells[cell] != null) {
      if (_removeMode) {
        client.sendInput(TycoonAction.remove(cell).toJson());
        if (haptics) HapticFeedback.lightImpact();
      }
      return;
    }
    if (_removeMode) return;
    final type = brickTypeById[_selected]!;
    if (plot.cash < type.cost) {
      if (haptics) HapticFeedback.vibrate();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Need ${type.cost - plot.cash} more cash for a ${type.name}.',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      return;
    }
    client.sendInput(TycoonAction.place(cell, _selected).toJson());
    if (haptics) HapticFeedback.selectionClick();
    setState(() => _flashCell = cell);
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final frame = client.frame;
    final plot = _plotOf(frame, client.myId) ?? TycoonPlot();
    final earned = ((frame?.json['earned'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    );
    final members = {
      for (final m in client.room?.members ?? const <RoomMember>[])
        m.player.id: m.player,
    };
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
    final pad = MediaQuery.paddingOf(context);

    final board = _PlotBoard(
      plot: plot,
      selected: _removeMode ? null : _selected,
      removeMode: _removeMode,
      flashCell: _flashCell,
      onTap: (c) => _tapCell(c, plot),
    );

    final palette = _Palette(
      plot: plot,
      selected: _selected,
      removeMode: _removeMode,
      onSelect: (id) => setState(() {
        _selected = id;
        _removeMode = false;
      }),
      onToggleRemove: () => setState(() => _removeMode = !_removeMode),
      onUpgrade: (id) => client.sendInput(TycoonAction.upgrade(id).toJson()),
    );

    final rivals = _Rivals(earned: earned, members: members, myId: client.myId);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF1A1410), const Color(0xFF2A1C12)]
              : [const Color(0xFFFFE9D6), const Color(0xFFFFD2AE)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: wide
            ? Padding(
                padding: EdgeInsets.fromLTRB(
                  Space.lg,
                  72 + pad.top,
                  Space.lg,
                  Space.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: AspectRatio(aspectRatio: 1, child: board),
                      ),
                    ),
                    const SizedBox(width: Space.lg),
                    SizedBox(
                      width: 320,
                      child: ListView(
                        children: [
                          _CashCard(
                            plot: plot,
                            earned: earned[client.myId] ?? 0,
                          ),
                          const SizedBox(height: Space.md),
                          palette,
                          const SizedBox(height: Space.md),
                          rivals,
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  Space.md,
                  72 + pad.top,
                  Space.md,
                  Space.md,
                ),
                children: [
                  _CashCard(plot: plot, earned: earned[client.myId] ?? 0),
                  const SizedBox(height: Space.md),
                  AspectRatio(aspectRatio: 1, child: board),
                  const SizedBox(height: Space.md),
                  palette,
                  const SizedBox(height: Space.md),
                  rivals,
                ],
              ),
      ),
    );
  }
}

class _CashCard extends StatelessWidget {
  const _CashCard({required this.plot, required this.earned});

  final TycoonPlot plot;
  final int earned;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      color: p.surface1.withValues(alpha: 0.92),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash',
                  style: context.text.labelMedium?.copyWith(
                    color: p.textTertiary,
                  ),
                ),
                Row(
                  children: [
                    const PipIcon(size: 20),
                    const SizedBox(width: Space.xs),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: plot.cash.toDouble()),
                      duration: Motion.normal,
                      builder: (context, v, _) => Text(
                        formatNumber(v.round()),
                        style: context.text.headlineMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Income',
                style: context.text.labelMedium?.copyWith(
                  color: p.textTertiary,
                ),
              ),
              Text(
                '+${formatNumber(plot.incomePerSecond())}/s',
                style: context.text.titleLarge?.copyWith(
                  color: BrickColors.mint,
                ),
              ),
              Text(
                'Earned this match: ${formatNumber(earned)}',
                style: context.text.bodySmall?.copyWith(color: p.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlotBoard extends StatelessWidget {
  const _PlotBoard({
    required this.plot,
    required this.selected,
    required this.removeMode,
    required this.flashCell,
    required this.onTap,
  });

  final TycoonPlot plot;
  final String? selected;
  final bool removeMode;
  final int? flashCell;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF3B7A4A) : const Color(0xFF7AD08F),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: dark ? const Color(0xFF2E5C3A) : const Color(0xFF4EA366),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: TycoonPlot.size,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: TycoonPlot.size * TycoonPlot.size,
        itemBuilder: (context, i) {
          final id = plot.cells[i];
          final type = id == null ? null : brickTypeById[id];
          final affordable =
              selected != null && plot.cash >= brickTypeById[selected]!.cost;
          return _Cell(
            type: type,
            highlight: type == null
                ? (selected != null
                      ? (affordable ? p.surface0.withValues(alpha: 0.25) : null)
                      : null)
                : (removeMode
                      ? BrickColors.cherry.withValues(alpha: 0.4)
                      : null),
            flash: flashCell == i,
            onTap: () => onTap(i),
            removable: removeMode && type != null,
          );
        },
      ),
    );
  }
}

class _Cell extends StatefulWidget {
  const _Cell({
    required this.type,
    required this.highlight,
    required this.flash,
    required this.onTap,
    required this.removable,
  });

  final BrickType? type;
  final Color? highlight;
  final bool flash;
  final bool removable;
  final VoidCallback onTap;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          decoration: BoxDecoration(
            color: type == null
                ? (_hover && widget.highlight != null
                      ? widget.highlight
                      : (dark
                            ? const Color(0xFF4A8C58)
                            : const Color(0xFF8FDB9F)))
                : Color(type.color),
            borderRadius: BorderRadius.circular(6),
            border: widget.removable && _hover
                ? Border.all(color: BrickColors.cherry, width: 2)
                : null,
            boxShadow: type == null
                ? null
                : [
                    BoxShadow(
                      color: Color.lerp(Color(type.color), Colors.black, 0.45)!,
                      offset: const Offset(0, 4),
                    ),
                    if (widget.flash)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                  ],
          ),
          margin: type == null
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 4),
          child: type == null
              ? null
              : LayoutBuilder(
                  builder: (context, c) {
                    final s = c.maxWidth;
                    return Stack(
                      children: [
                        // studs
                        for (var r = 0; r < 2; r++)
                          for (var col = 0; col < 2; col++)
                            Positioned(
                              left: s * (0.18 + col * 0.42),
                              top: s * (0.12 + r * 0.42),
                              child: Container(
                                width: s * 0.22,
                                height: s * 0.22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.lerp(
                                    Color(type.color),
                                    Colors.white,
                                    0.25,
                                  ),
                                  border: Border.all(
                                    color: Color.lerp(
                                      Color(type.color),
                                      Colors.black,
                                      0.2,
                                    )!,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                        if (widget.removable && _hover)
                          const Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette({
    required this.plot,
    required this.selected,
    required this.removeMode,
    required this.onSelect,
    required this.onToggleRemove,
    required this.onUpgrade,
  });

  final TycoonPlot plot;
  final String selected;
  final bool removeMode;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleRemove;
  final ValueChanged<String> onUpgrade;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      color: p.surface1.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Bricks', style: context.text.titleMedium)),
              FilterChip(
                label: const Text('Remove'),
                avatar: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: removeMode ? Colors.white : null,
                ),
                selected: removeMode,
                onSelected: (_) => onToggleRemove(),
                selectedColor: BrickColors.cherry,
                labelStyle: TextStyle(color: removeMode ? Colors.white : null),
                showCheckmark: false,
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final b in brickTypes)
            _PaletteRow(
              color: Color(b.color),
              name: b.name,
              blurb: b.blurb,
              cost: b.cost,
              selected: !removeMode && selected == b.id,
              affordable: plot.cash >= b.cost,
              onTap: () => onSelect(b.id),
            ),
          const Divider(height: Space.xl),
          Text('Upgrades', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          for (final u in tycoonUpgrades)
            _PaletteRow(
              color: BrickColors.grape,
              icon: Icons.bolt_rounded,
              name: u.name,
              blurb: u.blurb,
              cost: u.cost,
              owned: plot.upgrades.contains(u.id),
              affordable: plot.cash >= u.cost,
              onTap: plot.upgrades.contains(u.id) || plot.cash < u.cost
                  ? null
                  : () => onUpgrade(u.id),
              buyLabel: true,
            ),
        ],
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.color,
    required this.name,
    required this.blurb,
    required this.cost,
    required this.affordable,
    this.selected = false,
    this.owned = false,
    this.icon,
    this.onTap,
    this.buyLabel = false,
  });

  final Color color;
  final IconData? icon;
  final String name;
  final String blurb;
  final int cost;
  final bool selected;
  final bool owned;
  final bool affordable;
  final VoidCallback? onTap;
  final bool buyLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Material(
        color: selected
            ? BrickColors.sky.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(
                color: selected ? BrickColors.sky : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(color, Colors.black, 0.45)!,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: icon != null
                      ? Icon(icon, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.text.titleSmall),
                      Text(
                        blurb,
                        style: context.text.bodySmall?.copyWith(
                          color: p.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                if (owned)
                  const Tag(
                    'Owned',
                    icon: Icons.check_rounded,
                    color: BrickColors.mint,
                    onColor: Colors.white,
                  )
                else
                  Tag(
                    buyLabel ? 'Buy ${formatNumber(cost)}' : formatNumber(cost),
                    icon: Icons.paid_rounded,
                    color: affordable
                        ? BrickColors.sun.withValues(alpha: 0.2)
                        : p.surface3,
                    onColor: affordable
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? BrickColors.sun
                              : const Color(0xFF8A6412))
                        : p.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rivals extends StatelessWidget {
  const _Rivals({
    required this.earned,
    required this.members,
    required this.myId,
  });

  final Map<String, int> earned;
  final Map<String, PlayerSummary> members;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = earned.entries.toList()
      ..sort(
        (a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key),
      );
    final top = rows.isEmpty ? 1 : math.max(1, rows.first.value);
    return Panel(
      color: p.surface1.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Earnings race', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          if (rows.isEmpty)
            Text(
              'Waiting for the first payout…',
              style: context.text.bodySmall?.copyWith(color: p.textTertiary),
            ),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: context.text.labelMedium?.copyWith(
                        color: p.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                members[rows[i].key]?.name ?? rows[i].key,
                                style: context.text.bodyMedium?.copyWith(
                                  fontWeight: rows[i].key == myId
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatNumber(rows[i].value),
                              style: context.text.labelMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: rows[i].value / top,
                            color: rows[i].key == myId
                                ? BrickColors.sky
                                : experienceColor(ExperienceKind.tycoon),
                            backgroundColor: p.surface3,
                          ),
                        ),
                      ],
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
