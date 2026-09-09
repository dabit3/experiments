import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum PPButtonKind { primary, secondary, ghost, danger }

/// The one button. Pill-shaped, chunky, with a press squash.
class PPButton extends StatefulWidget {
  const PPButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = PPButtonKind.primary,
    this.expand = false,
    this.compact = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PPButtonKind kind;
  final bool expand;
  final bool compact;
  final String? tooltip;

  @override
  State<PPButton> createState() => _PPButtonState();
}

class _PPButtonState extends State<PPButton> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final enabled = widget.onPressed != null;
    final (bg, fg, border) = switch (widget.kind) {
      PPButtonKind.primary => (PPColor.paprika, Colors.white, Colors.transparent),
      PPButtonKind.secondary => (s.surface2, s.text, s.outline),
      PPButtonKind.ghost => (Colors.transparent, s.text2, Colors.transparent),
      PPButtonKind.danger => (s.surface2, PPColor.paprikaDark, PPColor.paprika.withValues(alpha: 0.35)),
    };
    final child = AnimatedScale(
      scale: _down ? 0.96 : (_hover && enabled ? 1.02 : 1),
      duration: PPMotion.fast,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: PPMotion.fast,
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: widget.compact ? 40 : 52,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? PPSpace.x4 : PPSpace.x6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: PPRadius.button,
            border: Border.all(color: border, width: 1.5),
            boxShadow: widget.kind == PPButtonKind.primary && enabled ? PPElevation.low(s.brightness) : null,
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 20, color: fg), const SizedBox(width: PPSpace.x2)],
              Text(widget.label, style: PPType.h3(fg).copyWith(fontSize: widget.compact ? 15 : 16)),
            ],
          ),
        ),
      ),
    );
    final w = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: Semantics(button: true, enabled: enabled, label: widget.label, child: child),
      ),
    );
    return widget.tooltip == null ? w : Tooltip(message: widget.tooltip!, child: w);
  }
}

class PPCard extends StatelessWidget {
  const PPCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PPSpace.x5),
    this.elevated = true,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool elevated;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? s.surface,
        borderRadius: PPRadius.card,
        border: Border.all(color: s.outline),
        boxShadow: elevated ? PPElevation.mid(s.brightness) : null,
      ),
      child: child,
    );
  }
}

class PPChip extends StatelessWidget {
  const PPChip({super.key, required this.label, this.color, this.icon, this.filled = false});
  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final c = color ?? s.text3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PPSpace.x3, vertical: 5),
      decoration: BoxDecoration(color: filled ? c : c.withValues(alpha: 0.12), borderRadius: PPRadius.chip),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: filled ? Colors.white : c), const SizedBox(width: 4)],
          Text(label.toUpperCase(), style: PPType.caption(filled ? Colors.white : c)),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PPSpace.x3),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: PPType.caption(s.text3)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Wordmark: "PANIC" in paprika on a tilted plate, "PANTRY" below.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.rotate(
          angle: -0.04,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.3, vertical: size * 0.08),
            decoration: BoxDecoration(
              color: PPColor.paprika,
              borderRadius: BorderRadius.circular(size * 0.3),
              boxShadow: PPElevation.low(s.brightness),
            ),
            child: Text('PANIC', style: PPType.display(Colors.white).copyWith(fontSize: size)),
          ),
        ),
        SizedBox(height: size * 0.12),
        Padding(
          padding: EdgeInsets.only(left: size * 0.12),
          child: Text('PANTRY', style: PPType.display(s.text).copyWith(fontSize: size)),
        ),
      ],
    );
  }
}

/// Shows toast strings coming from a stream at the top of the screen.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.stream, required this.child});
  final Stream<String> stream;
  final Widget child;

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost> {
  final List<(int, String)> _items = [];
  StreamSubscription? _sub;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((m) {
      final id = _n++;
      setState(() => _items.add((id, m)));
      Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _items.removeWhere((e) => e.$1 == id));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + PPSpace.x3,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (final (id, m) in _items)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(id),
                      tween: Tween(begin: 0, end: 1),
                      duration: PPMotion.base,
                      curve: PPMotion.emphasized,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(offset: Offset(0, (1 - v) * -12), child: child),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: PPSpace.x2),
                        padding: const EdgeInsets.symmetric(horizontal: PPSpace.x4, vertical: PPSpace.x3),
                        decoration: BoxDecoration(
                          color: s.text,
                          borderRadius: PPRadius.chip,
                          boxShadow: PPElevation.mid(s.brightness),
                        ),
                        child: Text(m, style: PPType.small(s.bg)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fullscreen state for loading / error / reconnecting.
class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.busy = false,
    this.actions = const [],
  });
  final String title;
  final String? message;
  final IconData? icon;
  final bool busy;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: PPCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3.5, color: PPColor.paprika),
                )
              else if (icon != null)
                Icon(icon, size: 40, color: PPColor.paprika),
              const SizedBox(height: PPSpace.x4),
              Text(title, style: PPType.h2(s.text), textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: PPSpace.x2),
                Text(message!, style: PPType.body(s.text2), textAlign: TextAlign.center),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: PPSpace.x5),
                Wrap(spacing: PPSpace.x2, runSpacing: PPSpace.x2, alignment: WrapAlignment.center, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple staggered fade+rise entrance for lists.
class Enter extends StatelessWidget {
  const Enter({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PPMotion.slow + PPMotion.stagger * index,
      curve: PPMotion.emphasized,
      builder: (context, v, child) {
        final t = ((v - index * 0.08).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
        );
      },
      child: child,
    );
  }
}
