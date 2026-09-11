import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum GcButtonKind { primary, secondary, ghost, danger }

/// Button primitive with press feedback and consistent sizing.
class GcButton extends StatefulWidget {
  const GcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = GcButtonKind.secondary,
    this.icon,
    this.expand = false,
    this.compact = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final GcButtonKind kind;
  final IconData? icon;
  final bool expand;
  final bool compact;
  final String? tooltip;

  @override
  State<GcButton> createState() => _GcButtonState();
}

class _GcButtonState extends State<GcButton> {
  bool _hover = false;
  bool _down = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final enabled = widget.onPressed != null;
    final (Color bg, Color fg, Color border) = switch (widget.kind) {
      GcButtonKind.primary => (
        GcArcade.sunshine,
        GcArcade.midnight,
        GcArcade.sunshine,
      ),
      GcButtonKind.secondary => (c.surfaceRaised, c.text, c.borderStrong),
      GcButtonKind.ghost => (
        Colors.transparent,
        c.textMuted,
        Colors.transparent,
      ),
      GcButtonKind.danger => (
        c.dangerSoft,
        c.danger,
        c.danger.withValues(alpha: 0.4),
      ),
    };
    final hoverBg = switch (widget.kind) {
      GcButtonKind.primary => Color.lerp(bg, Colors.white, 0.08)!,
      GcButtonKind.secondary => Color.lerp(bg, c.text, 0.06)!,
      GcButtonKind.ghost => c.text.withValues(alpha: 0.06),
      GcButtonKind.danger => c.danger.withValues(alpha: 0.28),
    };
    final height = widget.compact ? 36.0 : 44.0;
    final style = GcType.button(fg, size: widget.compact ? 13 : 14);
    Widget child = AnimatedContainer(
      duration: GcMotion.micro,
      curve: GcMotion.enter,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 18),
      decoration: BoxDecoration(
        color: !enabled
            ? bg.withValues(alpha: 0.45)
            : (_down
                  ? Color.lerp(hoverBg, c.bg, 0.12)
                  : (_hover ? hoverBg : bg)),
        borderRadius: GcRadius.mdAll,
        border: Border.all(
          color: _focus
              ? c.brass
              : (enabled ? border : border.withValues(alpha: 0.4)),
          width: _focus ? 1.5 : 1,
        ),
        boxShadow: widget.kind == GcButtonKind.primary && enabled && !_down
            ? [
                BoxShadow(
                  color: Color.lerp(GcArcade.sunshine, GcArcade.midnight, 0.5)!,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: GcArcade.sunshine.withValues(alpha: _hover ? 0.24 : 0),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 18,
              color: enabled ? fg : fg.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: enabled
                  ? style
                  : style.copyWith(color: fg.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
    child = AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: GcMotion.micro,
      child: child,
    );
    child = FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: widget.label,
          child: child,
        ),
      ),
    );
    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}

/// Square icon button with hover/press feedback.
class GcIconButton extends StatelessWidget {
  const GcIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.active = false,
    this.size = 40,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  final double size;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final enabled = onPressed != null;
    final color = danger
        ? c.danger
        : active
        ? c.brass
        : enabled
        ? c.textMuted
        : c.textFaint.withValues(alpha: 0.6);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: active ? c.brassSoft : Colors.transparent,
          borderRadius: GcRadius.smAll,
          child: InkWell(
            onTap: onPressed,
            borderRadius: GcRadius.smAll,
            hoverColor: c.text.withValues(alpha: 0.06),
            splashColor: c.brass.withValues(alpha: 0.2),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Icon(icon, size: size * 0.5, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GcCard extends StatelessWidget {
  const GcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GcSpace.xl),
    this.raised = false,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool raised;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (raised ? c.surfaceRaised : c.surface),
        borderRadius: GcRadius.lgAll,
        border: Border.all(color: raised ? c.borderStrong : c.border),
        boxShadow: raised
            ? [
                BoxShadow(
                  color: c.shadow.withValues(
                    alpha: context.isDark ? 0.3 : 0.08,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Small uppercase section label.
class GcLabel extends StatelessWidget {
  const GcLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: GcType.label(color ?? context.gc.textMuted, size: 11),
  );
}

/// Selectable chip used for time controls, sides, bot levels.
class GcChip extends StatelessWidget {
  const GcChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.caption,
    this.icon,
  });

  final String label;
  final String? caption;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: GcRadius.mdAll,
          hoverColor: c.text.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: GcMotion.fast,
            curve: GcMotion.enter,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? c.brassSoft : c.surfaceSunken,
              borderRadius: GcRadius.mdAll,
              border: Border.all(
                color: selected ? c.brass : c.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? c.brass : c.textMuted),
                  const SizedBox(width: 6),
                ],
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GcType.mono(
                        selected ? c.text : c.textMuted,
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (caption != null)
                      Text(caption!, style: GcType.body(c.textFaint, size: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status pill (online, spectating, reconnecting…).
class GcPill extends StatelessWidget {
  const GcPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.pulse = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final tint = color ?? c.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 5),
          ] else ...[
            _Dot(color: tint, pulse: pulse),
            const SizedBox(width: 6),
          ],
          Text(label, style: GcType.label(tint, size: 10.5)),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});
  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.pulse && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withValues(
          alpha: widget.pulse ? 0.45 + 0.55 * _c.value : 1,
        ),
      ),
    ),
  );
}

/// Subtle divider with optional centred label.
class GcDivider extends StatelessWidget {
  const GcDivider({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    if (label == null) return Divider(color: c.border);
    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GcSpace.md),
          child: Text(label!, style: GcType.label(c.textFaint, size: 10.5)),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }
}

/// Shimmer placeholder used for loading states.
class GcShimmer extends StatefulWidget {
  const GcShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });
  final double width;
  final double height;
  final double radius;

  @override
  State<GcShimmer> createState() => _GcShimmerState();
}

class _GcShimmerState extends State<GcShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _c.value, 0),
            end: Alignment(1 + 2 * _c.value, 0),
            colors: [c.surfaceSunken, c.surfaceRaised, c.surfaceSunken],
          ),
        ),
      ),
    );
  }
}
