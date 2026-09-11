import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class WorldArt extends StatelessWidget {
  const WorldArt(
    this.kind, {
    super.key,
    this.alignment = Alignment.center,
    this.fallback,
  });

  final ExperienceKind kind;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final name = switch (kind) {
      ExperienceKind.obby => 'skyline',
      ExperienceKind.tycoon => 'factory',
      ExperienceKind.tag => 'freeze',
    };
    return Image.asset(
      'assets/worlds/$name.webp',
      fit: BoxFit.cover,
      alignment: alignment,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, error, stackTrace) =>
          fallback ?? const ColoredBox(color: BrickColors.skyDark),
    );
  }
}

class ArcadeLabel extends StatelessWidget {
  const ArcadeLabel(this.text, {super.key, this.color = BrickColors.sun});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.labelSmall?.copyWith(
      color: color,
      letterSpacing: 2.2,
      fontWeight: FontWeight.w800,
    ),
  );
}

class ArcadeBackdrop extends StatelessWidget {
  const ArcadeBackdrop({
    super.key,
    required this.child,
    this.celebrate = false,
  });

  final Widget child;
  final bool celebrate;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ArcadePattern(
      color: context.palette.textPrimary,
      celebrate: celebrate,
    ),
    child: child,
  );
}

class _ArcadePattern extends CustomPainter {
  const _ArcadePattern({required this.color, required this.celebrate});

  final Color color;
  final bool celebrate;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.04);
    for (var x = 16.0; x < size.width; x += 32) {
      for (var y = 16.0; y < size.height; y += 32) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
    if (!celebrate) return;
    final random = math.Random(24);
    const colors = [
      BrickColors.sun,
      BrickColors.sky,
      BrickColors.mint,
      BrickColors.brick,
    ];
    for (var i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * math.min(size.height, 420);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 4, 9),
          const Radius.circular(1),
        ),
        Paint()..color = colors[i % colors.length].withValues(alpha: 0.45),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ArcadePattern oldDelegate) =>
      color != oldDelegate.color || celebrate != oldDelegate.celebrate;
}

class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    this.color = BrickColors.sun,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.fast,
      transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Color.lerp(widget.color, Colors.black, 0.5)!,
                  offset: Offset(0, _pressed ? 1 : 5),
                ),
              ]
            : null,
      ),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: BrickColors.ink,
            minimumSize: const Size(48, 52),
            textStyle: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: 25),
          label: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
