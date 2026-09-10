import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../game/atlas.dart';
import '../game/game_controller.dart';
import 'theme.dart';

/// Draws one atlas tile (block or item art) crisply scaled.
class TileIcon extends StatelessWidget {
  const TileIcon(this.atlasImage, this.tile, {super.key, this.size = 32, this.opacity = 1});
  final ui.Image atlasImage;
  final int tile;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _TilePainter(atlasImage, tile, opacity)),
  );
}

class _TilePainter extends CustomPainter {
  _TilePainter(this.img, this.tile, this.opacity);
  final ui.Image img;
  final int tile;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = (tile % Tiles.columns) * Tiles.size.toDouble();
    final sy = (tile ~/ Tiles.columns) * Tiles.size.toDouble();
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(sx, sy, Tiles.size.toDouble(), Tiles.size.toDouble()),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..color = Color.fromRGBO(0, 0, 0, opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _TilePainter old) => old.tile != tile || old.img != img || old.opacity != opacity;
}

/// Item stack icon with count badge.
class StackIcon extends StatelessWidget {
  const StackIcon(this.atlasImage, this.stack, {super.key, this.size = 40, this.dim = false});
  final ui.Image atlasImage;
  final ItemStack stack;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    if (stack.isEmpty) return SizedBox(width: size, height: size);
    final t = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: TileIcon(atlasImage, itemTileFor(stack.id), size: size * 0.78, opacity: dim ? 0.4 : 1),
          ),
          if (stack.count > 1)
            Positioned(
              right: -2,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: t.colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1))],
                ),
                child: Text(
                  '${stack.count}',
                  style: t.textTheme.labelSmall?.copyWith(
                    color: t.colorScheme.onInverseSurface,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Frosted panel used by HUD overlays.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VhSpace.lg),
    this.radius = VhRadius.lg,
    this.tint,
    this.blur = 18,
    this.border = true,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  final double blur;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? (dark ? const Color(0xcc121826) : const Color(0xd9f7f1e6)),
            borderRadius: BorderRadius.circular(radius),
            border: border ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)) : null,
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PlatformBadge extends StatelessWidget {
  const PlatformBadge(this.platform, {super.key, this.compact = false});
  final String platform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = platformColor(platform);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(platformIcon(platform), size: compact ? 12 : 14, color: c),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(platformLabel(platform), style: t.labelSmall?.copyWith(color: c, letterSpacing: 0.4)),
          ],
        ],
      ),
    );
  }
}

/// Fade + slide entrance used for staggered lists and dialogs.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero, this.offset = 16});
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: VhMotion.slow + delay,
    curve: Interval(delay.inMilliseconds / (VhMotion.slow + delay).inMilliseconds, 1, curve: VhMotion.curve),
    builder: (context, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, (1 - v) * offset), child: child),
    ),
    child: child,
  );
}

/// Section label used above groups of controls.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: VhSpace.sm),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: t.textTheme.labelSmall?.copyWith(letterSpacing: 1.4))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Voxelhearth wordmark with a small ember glyph.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 40, this.subtitle, this.onDark = false, this.center = false});
  final double size;
  final String? subtitle;

  /// Render in light ink for use over the dark scene backdrop.
  final bool onDark;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ink = onDark ? Colors.white : null;
    final sub = onDark ? Colors.white70 : t.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            EmberGlyph(size: size * 0.9),
            SizedBox(width: size * 0.3),
            Text(
              'Voxelhearth',
              style: t.textTheme.displayMedium?.copyWith(fontSize: size, height: 1, color: ink),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: VhSpace.sm),
          Text(subtitle!, style: t.textTheme.bodyLarge?.copyWith(color: sub)),
        ],
      ],
    );
  }
}

class EmberGlyph extends StatelessWidget {
  const EmberGlyph({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _EmberPainter()),
  );
}

class _EmberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final u = s / 8;
    // stacked isometric-ish cubes: hearth stones with an ember glowing in the middle
    void cube(double x, double y, Color top, Color left, Color right) {
      final p = Paint()..style = PaintingStyle.fill;
      p.color = top;
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..lineTo(x + 2 * u, y - u)
          ..lineTo(x + 4 * u, y)
          ..lineTo(x + 2 * u, y + u)
          ..close(),
        p,
      );
      p.color = left;
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..lineTo(x + 2 * u, y + u)
          ..lineTo(x + 2 * u, y + 3 * u)
          ..lineTo(x, y + 2 * u)
          ..close(),
        p,
      );
      p.color = right;
      canvas.drawPath(
        Path()
          ..moveTo(x + 4 * u, y)
          ..lineTo(x + 2 * u, y + u)
          ..lineTo(x + 2 * u, y + 3 * u)
          ..lineTo(x + 4 * u, y + 2 * u)
          ..close(),
        p,
      );
    }

    const stoneTop = Color(0xff8a8f99), stoneL = Color(0xff5c6270), stoneR = Color(0xff6f7583);
    cube(0, 4 * u, stoneTop, stoneL, stoneR);
    cube(4 * u, 4 * u, stoneTop, stoneL, stoneR);
    cube(2 * u, 3 * u, const Color(0xff9aa0aa), stoneL, stoneR);
    // ember
    final glow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(4 * u, 2.6 * u),
        3.2 * u,
        [
          VhColors.gold.withValues(alpha: 0.95),
          VhColors.ember.withValues(alpha: 0.6),
          VhColors.emberDeep.withValues(alpha: 0),
        ],
        [0, 0.45, 1],
      );
    canvas.drawCircle(Offset(4 * u, 2.6 * u), 3.2 * u, glow);
    final flame = Path()
      ..moveTo(4 * u, 0.2 * u)
      ..quadraticBezierTo(6.2 * u, 1.8 * u, 5.2 * u, 3.4 * u)
      ..quadraticBezierTo(4.6 * u, 4.2 * u, 4 * u, 3.9 * u)
      ..quadraticBezierTo(3.4 * u, 4.2 * u, 2.8 * u, 3.4 * u)
      ..quadraticBezierTo(1.8 * u, 1.8 * u, 4 * u, 0.2 * u)
      ..close();
    canvas.drawPath(flame, Paint()..color = VhColors.ember);
    canvas.drawPath(
      Path()
        ..moveTo(4 * u, 1.6 * u)
        ..quadraticBezierTo(5 * u, 2.6 * u, 4.4 * u, 3.5 * u)
        ..quadraticBezierTo(4 * u, 3.9 * u, 3.6 * u, 3.5 * u)
        ..quadraticBezierTo(3 * u, 2.6 * u, 4 * u, 1.6 * u)
        ..close(),
      Paint()..color = VhColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Empty / loading / error state block.
class StateBlock extends StatelessWidget {
  const StateBlock({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.loading = false,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VhSpace.xxl, horizontal: VhSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3, color: t.colorScheme.primary),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: t.colorScheme.surfaceContainerHigh, shape: BoxShape.circle),
              child: Icon(icon, color: t.colorScheme.onSurfaceVariant, size: 28),
            ),
          const SizedBox(height: VhSpace.lg),
          Text(title, style: t.textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: VhSpace.xs),
            Text(message!, style: t.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: VhSpace.lg), action!],
        ],
      ),
    );
  }
}

/// Large monospaced room code with copy affordance.
class RoomCodeChip extends StatelessWidget {
  const RoomCodeChip(this.code, {super.key, this.onCopy, this.compact = false});
  final String code;
  final VoidCallback? onCopy;

  /// Tighter variant for phone headers where the room title needs the width.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: t.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(VhRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(VhRadius.md),
        onTap: onCopy,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: (compact ? t.textTheme.titleMedium : t.textTheme.headlineSmall)?.copyWith(
                  fontFamily: 'Outfit',
                  letterSpacing: compact ? 2 : 4,
                  fontWeight: FontWeight.w700,
                  color: t.colorScheme.onSecondaryContainer,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 16, color: t.colorScheme.onSecondaryContainer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive helper.
enum FormFactor { phone, tablet, desktop }

FormFactor formFactorOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 620) return FormFactor.phone;
  if (w < 1000) return FormFactor.tablet;
  return FormFactor.desktop;
}
