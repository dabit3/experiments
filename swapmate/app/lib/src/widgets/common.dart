import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../net/game_client.dart';
import '../theme/tokens.dart';
import 'board_view.dart';
import 'piece_painter.dart';

/// Rounded panel used for every card-like surface.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.raised = false,
    this.color,
    this.borderColor,
    this.radius = Radii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? (raised ? c.surfaceRaised : c.surface),
            color ?? c.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.outline),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: raised ? 0.25 : 0.14),
            blurRadius: raised ? 22 : 0,
            offset: Offset(0, raised ? 8 : 3),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Small capsule label.
class Chip2 extends StatelessWidget {
  const Chip2(
    this.label, {
    super.key,
    this.color,
    this.background,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.textMuted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Space.sm : Space.md,
        vertical: dense ? 2 : Space.xs,
      ),
      decoration: BoxDecoration(
        color: background ?? c.surfaceRaised,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: Space.xs),
          ],
          Text(label, style: context.type.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Connection indicator shown in headers.
class StatusPill extends StatelessWidget {
  const StatusPill(this.client, {super.key, this.compact = false});
  final GameClient client;

  /// Dot only (no label) for narrow headers; the label stays in semantics.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, color) = switch (client.status) {
      ConnectionStatus.offline => ('Offline', c.textFaint),
      ConnectionStatus.connecting => ('Connecting', c.warning),
      ConnectionStatus.reconnecting => ('Reconnecting', c.warning),
      ConnectionStatus.online => ('Online', c.success),
    };
    final detail = client.isOnline && client.latencyMs > 0
        ? '$label · ${client.latencyMs} ms'
        : label;
    return Semantics(
      label: 'Connection $detail',
      child: Tooltip(
        message: compact || detail != label ? detail : '',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Space.sm : Space.md,
            vertical: compact ? Space.sm : 6,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: c.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(
                color: color,
                pulsing:
                    client.status != ConnectionStatus.online &&
                    client.status != ConnectionStatus.offline,
              ),
              if (!compact) ...[
                const SizedBox(width: Space.sm),
                Text(
                  label,
                  style: context.type.labelSmall?.copyWith(color: c.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulsing});
  final Color color;
  final bool pulsing;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.pulsing && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: widget.pulsing
        ? Tween(begin: 0.35, end: 1.0).animate(_c)
        : const AlwaysStoppedAnimation(1),
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

/// Ticking clock for one side of a board.
class ClockView extends StatefulWidget {
  const ClockView({
    super.key,
    required this.snapshot,
    required this.color,
    required this.sampledAt,
    required this.serverNow,
    this.compact = false,
    this.isMine = false,
  });

  final BoardSnapshot snapshot;
  final PieceColor color;

  /// Server timestamp when the snapshot was taken.
  final int sampledAt;
  final int Function() serverNow;
  final bool compact;
  final bool isMine;

  static String format(int ms) {
    final total = (ms / 1000).ceil();
    final m = total ~/ 60;
    final s = total % 60;
    if (ms < 10000) {
      final tenths = ((ms % 1000) / 100).floor();
      return '0:${(ms ~/ 1000).toString().padLeft(2, '0')}.$tenths';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  Timer? _timer;

  bool get _running => widget.snapshot.running == widget.color;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ClockView old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    _timer?.cancel();
    if (_running) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _remaining {
    final base = widget.color == PieceColor.white
        ? widget.snapshot.whiteMs
        : widget.snapshot.blackMs;
    if (!_running) return base;
    final left = base - (widget.serverNow() - widget.sampledAt);
    return left < 0 ? 0 : left;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ms = _remaining;
    final low = ms < 10000 && _running;
    final bg = _running ? (low ? c.danger : c.accent) : c.surfaceSunken;
    final fg = _running ? (low ? Colors.white : c.onAccent) : c.textMuted;
    return Semantics(
      label: '${widget.color.name} clock ${ClockView.format(ms)}',
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? Space.sm : Space.md,
          vertical: widget.compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: _running
                ? (low ? c.danger : c.accent).withValues(alpha: 0.6)
                : c.outline,
          ),
        ),
        child: Text(
          ClockView.format(ms),
          style:
              (widget.compact
                      ? context.type.titleMedium
                      : context.type.headlineSmall)
                  ?.copyWith(
                    color: fg,
                    fontFamily: 'BarlowCondensed',
                    fontWeight: FontWeight.w800,
                    fontSize: widget.compact ? 22 : 30,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
        ),
      ),
    );
  }
}

/// A player's reserve tray. Pieces can be tapped (select for drop) or dragged
/// onto the board.
class ReserveTray extends StatelessWidget {
  const ReserveTray({
    super.key,
    required this.reserve,
    required this.color,
    required this.boardId,
    this.interactive = false,
    this.selected,
    this.onSelect,
    this.compact = false,
    this.dense = false,
    this.trayKey,
  });

  final Reserve reserve;
  final PieceColor color;
  final BoardId boardId;
  final bool interactive;
  final PieceType? selected;
  final void Function(PieceType)? onSelect;
  final bool compact;

  /// Slightly smaller pieces for phone-width player bars.
  final bool dense;
  final Key? trayKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = compact ? 26.0 : (dense ? 30.0 : 36.0);
    final items = PieceType.droppable
        .where((t) => reserve.count(t) > 0)
        .toList();
    return Container(
      key: trayKey,
      constraints: BoxConstraints(minHeight: size + 12),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.xs : Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: c.outline),
      ),
      child: items.isEmpty
          ? Center(
              child: Text(
                compact ? '—' : 'RESERVE · AWAITING CAPTURES',
                style: context.type.labelSmall?.copyWith(
                  color: c.textFaint,
                  fontSize: compact ? 10 : 9,
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final t in items)
                    _ReserveItem(
                      piece: Piece(color, t),
                      count: reserve.count(t),
                      size: size,
                      boardId: boardId,
                      selected: selected == t,
                      interactive: interactive,
                      onTap: () => onSelect?.call(t),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ReserveItem extends StatelessWidget {
  const _ReserveItem({
    required this.piece,
    required this.count,
    required this.size,
    required this.boardId,
    required this.selected,
    required this.interactive,
    required this.onTap,
  });

  final Piece piece;
  final int count;
  final double size;
  final BoardId boardId;
  final bool selected;
  final bool interactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glyph = Stack(
      clipBehavior: Clip.none,
      children: [
        PieceGlyph(piece, size: size),
        if (count > 1)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '$count',
                style: context.type.labelSmall?.copyWith(
                  color: c.onAccent,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
    final tile = AnimatedContainer(
      duration: Motion.fast,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: selected ? c.highlightSelect : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: glyph,
    );
    if (!interactive) return tile;
    return Semantics(
      button: true,
      label: 'Drop ${piece.type.name}, $count in hand',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Draggable<ReserveDrag>(
            data: ReserveDrag(piece, boardId),
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: onTap,
            feedback: Transform.translate(
              offset: Offset(-size * 0.7, -size * 0.8),
              child: PieceGlyph(piece, size: size * 1.4),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: tile),
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// Avatar circle with initials, coloured by team.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.team,
    this.size = 32,
    this.isBot = false,
    this.platform,
  });

  final String name;
  final Team? team;
  final double size;
  final bool isBot;
  final String? platform;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = team == null ? c.textFaint : c.team(team!);
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      alignment: Alignment.center,
      child: isBot
          ? Icon(Icons.smart_toy_outlined, size: size * 0.55, color: color)
          : Text(
              initials,
              style: context.type.labelMedium?.copyWith(
                color: color,
                fontSize: size * 0.38,
              ),
            ),
    );
  }
}

IconData platformIcon(String? platform) => switch (platform) {
  'web' => Icons.language,
  'ios' => Icons.phone_iphone,
  'android' => Icons.phone_android,
  'macos' => Icons.laptop_mac,
  'server' => Icons.smart_toy_outlined,
  _ => Icons.devices_other,
};

String platformLabel(String? platform) => switch (platform) {
  'web' => 'Web',
  'ios' => 'iOS',
  'android' => 'Android',
  'macos' => 'macOS',
  'server' => 'Bot',
  _ => 'Device',
};

/// Copies text and confirms with a snackbar.
Future<void> copyToClipboard(
  BuildContext context,
  String text,
  String toast,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(toast), duration: const Duration(seconds: 2)),
    );
}
