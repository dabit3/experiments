import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart' hide Material;

import 'theme.dart';

/// Primary/secondary/ghost button with press feedback and haptics.
class LfButton extends StatefulWidget {
  const LfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = LfButtonVariant.primary,
    this.expand = false,
    this.size = LfButtonSize.md,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LfButtonVariant variant;
  final bool expand;
  final LfButtonSize size;
  final String? semanticLabel;

  @override
  State<LfButton> createState() => _LfButtonState();
}

enum LfButtonVariant { primary, secondary, ghost, danger }

enum LfButtonSize { sm, md, lg }

class _LfButtonState extends State<LfButton> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final enabled = widget.onPressed != null;
    final (bg, fg, border) = switch (widget.variant) {
      LfButtonVariant.primary => (
        LfTokens.teal,
        const Color(0xFF032523),
        Colors.transparent,
      ),
      LfButtonVariant.secondary => (
        LfTokens.ember,
        Colors.white,
        Colors.transparent,
      ),
      LfButtonVariant.ghost => (Colors.transparent, c.text, c.line),
      LfButtonVariant.danger => (
        LfTokens.danger,
        Colors.white,
        Colors.transparent,
      ),
    };
    final height = switch (widget.size) {
      LfButtonSize.sm => 36.0,
      LfButtonSize.md => 48.0,
      LfButtonSize.lg => 60.0,
    };
    final textStyle = switch (widget.size) {
      LfButtonSize.sm => context.text.labelMedium,
      LfButtonSize.md => context.text.labelLarge,
      LfButtonSize.lg => context.text.titleLarge?.copyWith(letterSpacing: 1.4),
    };
    final scale = _down ? 0.97 : (_hover ? 1.02 : 1.0);
    final child = AnimatedScale(
      scale: scale,
      duration: LfTokens.fast,
      curve: LfTokens.ease,
      child: AnimatedOpacity(
        duration: LfTokens.fast,
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: widget.size == LfButtonSize.sm
                ? LfTokens.s3
                : LfTokens.s5,
          ),
          decoration: BoxDecoration(
            color: _hover && widget.variant == LfButtonVariant.ghost
                ? c.surface2
                : bg,
            borderRadius: BorderRadius.circular(LfTokens.rMd),
            border: Border.all(color: border, width: 1.5),
            boxShadow: widget.variant == LfButtonVariant.ghost || !enabled
                ? null
                : [
                    BoxShadow(
                      color: bg.withValues(alpha: _hover ? 0.45 : 0.28),
                      blurRadius: _hover ? 18 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: fg),
                const SizedBox(width: LfTokens.s2),
              ],
              Text(
                widget.label.toUpperCase(),
                style: textStyle?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _down = true) : null,
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Elevated translucent panel used for cards, HUD blocks and dialogs.
class LfPanel extends StatelessWidget {
  const LfPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LfTokens.s4),
    this.strong = false,
    this.accent,
    this.radius = LfTokens.rLg,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool strong;
  final Color? accent;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: strong ? c.glassStrong : c.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent?.withValues(alpha: 0.6) ?? c.line,
          width: accent == null ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: box,
      ),
    );
  }
}

/// Uppercase eyebrow label.
class LfEyebrow extends StatelessWidget {
  const LfEyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.labelSmall?.copyWith(
      color: color ?? context.lf.muted,
      letterSpacing: 2,
    ),
  );
}

class LfChip extends StatelessWidget {
  const LfChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final accent = color ?? LfTokens.teal;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: AnimatedContainer(
            duration: LfTokens.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: LfTokens.s3,
              vertical: LfTokens.s2,
            ),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.18) : c.surface2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? accent : c.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? accent : c.muted),
                  const SizedBox(width: 6),
                ],
                Text(
                  label.toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    color: selected ? (c.isDark ? accent : c.text) : c.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RarityBadge extends StatelessWidget {
  const RarityBadge(this.rarity, {super.key, this.compact = false});
  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final col = LfTokens.rarity(rarity);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : LfTokens.s2,
        vertical: compact ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(LfTokens.rSm),
        border: Border.all(color: col.withValues(alpha: 0.8)),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: col,
          fontSize: compact ? 9 : 11,
        ),
      ),
    );
  }
}

/// Animated horizontal bar (health, shield, XP, storm).
class LfBar extends StatelessWidget {
  const LfBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 12,
    this.background,
    this.segments = 0,
    this.radius = 6,
  });

  final double value;
  final Color color;
  final double height;
  final Color? background;
  final int segments;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          Container(
            height: height,
            color: background ?? c.surface2.withValues(alpha: 0.9),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0, 1)),
            duration: LfTokens.base,
            curve: LfTokens.ease,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              alignment: Alignment.centerLeft,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.85), color],
                  ),
                ),
              ),
            ),
          ),
          if (segments > 1)
            Positioned.fill(
              child: CustomPaint(
                painter: _SegmentPainter(segments, c.bg.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter(this.segments, this.color);
  final int segments;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var i = 1; i < segments; i++) {
      final x = size.width * i / segments;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentPainter old) =>
      old.segments != segments || old.color != color;
}

/// Procedural avatar for an outfit cosmetic: a stylised drop-suit bust drawn
/// from the cosmetic palette (original art, generated at runtime).
class OutfitAvatar extends StatelessWidget {
  const OutfitAvatar(this.cosmetic, {super.key, this.size = 72});
  final Cosmetic cosmetic;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${cosmetic.name} outfit',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: _OutfitPainter(cosmetic),
    ),
  );
}

class _OutfitPainter extends CustomPainter {
  _OutfitPainter(this.c);
  final Cosmetic c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final primary = Paint()..color = Color(c.primary);
    final secondary = Paint()..color = Color(c.secondary);
    final accent = Paint()..color = Color(c.accent);
    // Shoulders / torso.
    final torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.52, w * 0.72, h * 0.48),
      Radius.circular(w * 0.2),
    );
    canvas.drawRRect(torso, primary);
    // Chest stripe varies by shape.
    switch (c.shape % 4) {
      case 0:
        canvas.drawRect(
          Rect.fromLTWH(w * 0.46, h * 0.56, w * 0.08, h * 0.4),
          accent,
        );
      case 1:
        final path = Path()
          ..moveTo(w * 0.2, h * 0.6)
          ..lineTo(w * 0.8, h * 0.6)
          ..lineTo(w * 0.5, h * 0.9)
          ..close();
        canvas.drawPath(path, accent);
      case 2:
        canvas.drawCircle(Offset(w * 0.5, h * 0.74), w * 0.11, accent);
      default:
        canvas.drawRect(
          Rect.fromLTWH(w * 0.2, h * 0.6, w * 0.6, h * 0.06),
          accent,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.2, h * 0.72, w * 0.6, h * 0.06),
          accent,
        );
    }
    // Helmet.
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.24, secondary);
    // Visor.
    final visor = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.26, w * 0.36, h * 0.14),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(visor, accent);
    canvas.drawRRect(
      visor,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );
  }

  @override
  bool shouldRepaint(covariant _OutfitPainter old) => old.c.id != c.id;
}

/// Procedural icon for pickaxe / glider / banner cosmetics.
class CosmeticGlyph extends StatelessWidget {
  const CosmeticGlyph(this.cosmetic, {super.key, this.size = 72});
  final Cosmetic cosmetic;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (cosmetic.slot == CosmeticSlot.outfit) {
      return OutfitAvatar(cosmetic, size: size);
    }
    return Semantics(
      label: '${cosmetic.name} ${cosmetic.slot.name}',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _GlyphPainter(cosmetic),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.c);
  final Cosmetic c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final primary = Paint()..color = Color(c.primary);
    final secondary = Paint()..color = Color(c.secondary);
    final accent = Paint()..color = Color(c.accent);
    final centre = Offset(w / 2, w / 2);
    switch (c.slot) {
      case CosmeticSlot.pickaxe:
        canvas.save();
        canvas.translate(centre.dx, centre.dy);
        canvas.rotate(-math.pi / 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 0.12,
              height: w * 0.8,
            ),
            Radius.circular(w * 0.04),
          ),
          secondary,
        );
        final head = Path()
          ..moveTo(-w * 0.34, -w * 0.4)
          ..quadraticBezierTo(0, -w * 0.62, w * 0.34, -w * 0.4)
          ..lineTo(w * 0.2, -w * 0.28)
          ..quadraticBezierTo(0, -w * 0.42, -w * 0.2, -w * 0.28)
          ..close();
        canvas.drawPath(head, primary);
        canvas.drawCircle(Offset(0, -w * 0.36), w * 0.05, accent);
        canvas.restore();
      case CosmeticSlot.glider:
        final canopy = Path()
          ..moveTo(w * 0.08, w * 0.48)
          ..quadraticBezierTo(w * 0.5, w * 0.02, w * 0.92, w * 0.48)
          ..quadraticBezierTo(w * 0.5, w * 0.34, w * 0.08, w * 0.48)
          ..close();
        canvas.drawPath(canopy, primary);
        for (var i = 1; i < 4; i++) {
          final x = w * 0.08 + (w * 0.84) * i / 4;
          canvas.drawLine(
            Offset(x, w * 0.36 + (i == 2 ? 0 : w * 0.04)),
            Offset(w * 0.5, w * 0.82),
            secondary..strokeWidth = w * 0.025,
          );
        }
        canvas.drawCircle(Offset(w * 0.5, w * 0.84), w * 0.08, accent);
      case CosmeticSlot.banner:
        final flag = Path()
          ..moveTo(w * 0.18, w * 0.12)
          ..lineTo(w * 0.82, w * 0.12)
          ..lineTo(w * 0.82, w * 0.7)
          ..lineTo(w * 0.5, w * 0.92)
          ..lineTo(w * 0.18, w * 0.7)
          ..close();
        canvas.drawPath(flag, primary);
        canvas.drawPath(
          flag,
          secondary
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.05,
        );
        switch (c.shape % 3) {
          case 0:
            canvas.drawCircle(Offset(w * 0.5, w * 0.46), w * 0.16, accent);
          case 1:
            final bolt = Path()
              ..moveTo(w * 0.55, w * 0.22)
              ..lineTo(w * 0.38, w * 0.5)
              ..lineTo(w * 0.5, w * 0.5)
              ..lineTo(w * 0.44, w * 0.76)
              ..lineTo(w * 0.64, w * 0.44)
              ..lineTo(w * 0.52, w * 0.44)
              ..close();
            canvas.drawPath(bolt, accent);
          default:
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(w * 0.5, w * 0.46),
                width: w * 0.3,
                height: w * 0.3,
              ),
              accent,
            );
        }
      case CosmeticSlot.outfit:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) => old.c.id != c.id;
}

/// Animated storm backdrop used behind lobby/results screens.
class StormBackdrop extends StatefulWidget {
  const StormBackdrop({super.key, this.intensity = 1});
  final double intensity;

  @override
  State<StormBackdrop> createState() => _StormBackdropState();
}

class _StormBackdropState extends State<StormBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _StormPainter(_ctrl.value, c.isDark, widget.intensity),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StormPainter extends CustomPainter {
  _StormPainter(this.t, this.dark, this.intensity);
  final double t;
  final bool dark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          dark
              ? [
                  const Color(0xFF0B1220),
                  const Color(0xFF15102E),
                  const Color(0xFF0B1A22),
                ]
              : [
                  const Color(0xFFF2F5FA),
                  const Color(0xFFE6E4FA),
                  const Color(0xFFDDF3F1),
                ],
          const [0, 0.55, 1],
        ),
    );
    // Slow drifting storm rings.
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1;
      final r = size.longestSide * (0.25 + phase * 0.75);
      final alpha = (1 - phase) * 0.18 * intensity;
      canvas.drawCircle(
        Offset(size.width * 0.72, size.height * 0.35),
        r,
        Paint()
          ..color = LfTokens.storm.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 14 * (1 - phase),
      );
    }
    // Ember glow bottom-left.
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.95),
      size.shortestSide * 0.6,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.1, size.height * 0.95),
          size.shortestSide * 0.6,
          [
            LfTokens.ember.withValues(alpha: 0.28 * intensity),
            LfTokens.ember.withValues(alpha: 0),
          ],
        ),
    );
    // Teal glow top-right.
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.1),
      size.shortestSide * 0.5,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.85, size.height * 0.1),
          size.shortestSide * 0.5,
          [
            LfTokens.teal.withValues(alpha: 0.22 * intensity),
            LfTokens.teal.withValues(alpha: 0),
          ],
        ),
    );
    // Fine grid for a tactical feel.
    final grid = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _StormPainter old) =>
      old.t != t || old.dark != dark;
}

/// Wordmark: "LAST" in text + "FORT" in ember with a tower glyph.
class LastfortWordmark extends StatelessWidget {
  const LastfortWordmark({super.key, this.size = 40, this.iconOnly = false});
  final double size;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return Semantics(
      label: 'Lastfort',
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomPaint(
            size: Size(size * 0.9, size * 0.9),
            painter: _TowerPainter(c.text),
          ),
          if (!iconOnly) SizedBox(width: size * 0.25),
          if (!iconOnly)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'LAST',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: 'FORT',
                    style: const TextStyle(
                      color: LfTokens.ember,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: size,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _TowerPainter extends CustomPainter {
  _TowerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = color;
    // Battlements.
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (0.1 + i * 0.3), h * 0.08, w * 0.2, h * 0.16),
        p,
      );
    }
    canvas.drawRect(Rect.fromLTWH(w * 0.1, h * 0.22, w * 0.8, h * 0.7), p);
    // Ember window.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, h * 0.42, w * 0.2, h * 0.28),
        Radius.circular(w * 0.1),
      ),
      Paint()..color = LfTokens.ember,
    );
    // Storm ring behind.
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.6,
      Paint()
        ..color = LfTokens.teal.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06,
    );
  }

  @override
  bool shouldRepaint(covariant _TowerPainter old) => old.color != color;
}

/// Stat tile used on results / lobby.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s3,
        vertical: LfTokens.s3,
      ),
      decoration: BoxDecoration(
        color: c.surface2.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(LfTokens.rMd),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          LfEyebrow(label),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.text.headlineMedium?.copyWith(
              color: color ?? c.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Constrains content width on large screens while staying edge-to-edge on
/// phones.
class LfPage extends StatelessWidget {
  const LfPage({super.key, required this.child, this.maxWidth = 1180});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
