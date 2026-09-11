import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../board/piece_glyph.dart';

/// Player identity, captured material, and a live clock.
class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.color,
    required this.participant,
    required this.clocks,
    required this.receivedLocalMs,
    required this.active,
    required this.captured,
    required this.materialLead,
    required this.timeControl,
    required this.gameOver,
    this.isMe = false,
    this.compact = false,
    this.inCheck = false,
  });

  final PieceColor color;
  final Participant? participant;
  final ClockState? clocks;
  final int receivedLocalMs;
  final bool active;
  final List<PieceType> captured;
  final int materialLead;
  final TimeControl timeControl;
  final bool gameOver;
  final bool isMe;
  final bool compact;
  final bool inCheck;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final p = participant;
    final name = p?.name ?? 'Waiting for opponent…';
    final subtitle = p == null
        ? 'Seat open'
        : p.isBot
        ? 'Server engine · depth ${EngineLevel.fromId(p.botLevel ?? 2).depth}'
        : '${active && !gameOver ? (isMe ? 'YOUR MOVE · ' : 'TO MOVE · ') : ''}'
              '${_platformLabel(p.platform)}${p.connected ? '' : ' · reconnecting'}';
    return AnimatedContainer(
      duration: GcMotion.fast,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? GcSpace.md : GcSpace.lg,
        vertical: compact ? GcSpace.sm : GcSpace.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            active ? c.brassSoft : c.surface,
            active ? c.surfaceRaised : c.surface,
          ],
        ),
        borderRadius: GcRadius.mdAll,
        border: Border.all(
          color: active ? c.brass : c.border,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _Avatar(
            color: color,
            connected: p?.connected ?? false,
            isBot: p?.isBot ?? false,
          ),
          const SizedBox(width: GcSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GcType.heading(
                          p == null ? c.textMuted : c.text,
                          size: compact ? 14 : 15,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text('you', style: GcType.label(c.brass, size: 9.5)),
                    ],
                    if (inCheck && !gameOver) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: c.dangerSoft,
                          borderRadius: GcRadius.smAll,
                        ),
                        child: Text(
                          'CHECK',
                          style: GcType.label(c.danger, size: 9),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GcType.body(
                          (p?.connected ?? true) ? c.textMuted : c.danger,
                          size: 12,
                        ),
                      ),
                    ),
                    if (captured.isNotEmpty || materialLead > 0) ...[
                      const SizedBox(width: 8),
                      _Captured(
                        captured: captured,
                        lead: materialLead,
                        victimColor: color.opposite,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (clocks != null) ...[
            const SizedBox(width: GcSpace.md),
            ClockDisplay(
              color: color,
              clocks: clocks!,
              receivedLocalMs: receivedLocalMs,
              timeControl: timeControl,
              active: active && !gameOver,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }

  static String _platformLabel(String platform) => switch (platform) {
    'web' => 'Web',
    'ios' => 'iOS',
    'android' => 'Android',
    'macos' => 'macOS',
    'linux' => 'Linux',
    'windows' => 'Windows',
    _ => 'Guest',
  };
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.color,
    required this.connected,
    required this.isBot,
  });
  final PieceColor color;
  final bool connected;
  final bool isBot;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color == PieceColor.white
                  ? const Color(0xFF5474AD)
                  : const Color(0xFFB7D6F1),
              borderRadius: GcRadius.smAll,
              border: Border.all(color: c.borderStrong),
            ),
            child: Center(
              child: PieceGlyph(
                Piece(color, isBot ? PieceType.knight : PieceType.king),
                size: 26,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected ? c.verdigris : c.textFaint,
                border: Border.all(color: c.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Captured extends StatelessWidget {
  const _Captured({
    required this.captured,
    required this.lead,
    required this.victimColor,
  });
  final List<PieceType> captured;
  final int lead;
  final PieceColor victimColor;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final sorted = [...captured]..sort((a, b) => b.value.compareTo(a.value));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...sorted
            .take(10)
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 1),
                child: PieceGlyph(Piece(victimColor, t), size: 15),
              ),
            ),
        if (lead > 0) ...[
          const SizedBox(width: 4),
          Text(
            '+$lead',
            style: GcType.mono(c.textMuted, size: 11, weight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

/// Ticking clock. The server sends exact remaining times at a moment; the
/// widget extrapolates the running side locally between snapshots.
class ClockDisplay extends StatefulWidget {
  const ClockDisplay({
    super.key,
    required this.color,
    required this.clocks,
    required this.receivedLocalMs,
    required this.timeControl,
    required this.active,
    this.compact = false,
  });

  final PieceColor color;
  final ClockState clocks;
  final int receivedLocalMs;
  final TimeControl timeControl;
  final bool active;
  final bool compact;

  @override
  State<ClockDisplay> createState() => _ClockDisplayState();
}

class _ClockDisplayState extends State<ClockDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ClockDisplay old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final running =
        widget.clocks.running == widget.color &&
        !widget.clocks.frozen &&
        widget.active;
    if (running && _timer == null) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => setState(() {}),
      );
    } else if (!running && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _remaining {
    final base = widget.color == PieceColor.white
        ? widget.clocks.whiteMs
        : widget.clocks.blackMs;
    final running =
        widget.clocks.running == widget.color && !widget.clocks.frozen;
    if (!running || !widget.active) return base;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - widget.receivedLocalMs;
    return max(0, base - elapsed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    if (widget.timeControl.isUnlimited) {
      return _Shell(
        active: widget.active,
        low: false,
        compact: widget.compact,
        child: Text(
          '∞',
          style: GcType.mono(c.textMuted, size: widget.compact ? 20 : 24),
        ),
      );
    }
    final ms = _remaining;
    final low = ms < 20000 && widget.active;
    final text = formatClock(ms);
    return _Shell(
      active: widget.active,
      low: low,
      compact: widget.compact,
      child: Text(
        text,
        style: GcType.mono(
          low ? c.danger : (widget.active ? GcArcade.midnight : c.textMuted),
          size: widget.compact ? 20 : 24,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({
    required this.active,
    required this.low,
    required this.compact,
    required this.child,
  });
  final bool active;
  final bool low;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return AnimatedContainer(
      duration: GcMotion.fast,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: low
            ? c.dangerSoft
            : active
            ? GcArcade.sunshine
            : c.surfaceSunken,
        borderRadius: GcRadius.smAll,
        border: Border.all(
          color: low
              ? c.danger.withValues(alpha: 0.6)
              : active
              ? c.brass.withValues(alpha: 0.5)
              : c.border,
        ),
      ),
      child: child,
    );
  }
}

String formatClock(int ms) {
  if (ms < 0) ms = 0;
  final totalSeconds = ms ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  if (ms < 20000) {
    final tenths = (ms % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
