import 'dart:math' as math;

import 'package:flutter/material.dart';

class Hearth {
  static const ink = Color(0xff071e2b);
  static const navy = Color(0xff102e3b);
  static const teal = Color(0xff70e2c4);
  static const gold = Color(0xffffcc75);
  static const cream = Color(0xfffff4dc);
  static const muted = Color(0xffa9c5cd);
}

TextStyle arcadeType(double size, {Color color = Hearth.cream, FontWeight weight = FontWeight.w600}) => TextStyle(
  fontFamily: 'Outfit',
  fontSize: size,
  height: 1.1,
  fontWeight: weight,
  color: color,
  decoration: TextDecoration.none,
);

class HearthBackdrop extends StatefulWidget {
  const HearthBackdrop({super.key, this.celebrate = false});
  final bool celebrate;

  @override
  State<HearthBackdrop> createState() => _HearthBackdropState();
}

class _HearthBackdropState extends State<HearthBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _time.stop();
      _time.value = 0.25;
    } else {
      _time.repeat();
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (!widget.celebrate) ...[
          Image.asset('assets/hearth-keyart.png', fit: BoxFit.cover, alignment: Alignment.centerRight),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xef071e2b), Color(0x66071e2b), Color(0x00071e2b)],
                stops: [0, 0.46, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x30071e2b), Colors.transparent, Color(0xe0071e2b)],
                stops: [0, 0.65, 1],
              ),
            ),
          ),
        ],
        IgnorePointer(child: CustomPaint(painter: _Embers(_time, widget.celebrate))),
      ],
    ),
  );
}

class _Embers extends CustomPainter {
  _Embers(this.time, this.celebrate) : super(repaint: time);
  final Animation<double> time;
  final bool celebrate;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(82);
    for (var i = 0; i < (celebrate ? 48 : 24); i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final speed = 0.3 + random.nextDouble() * 0.7;
      final t = (y + time.value * speed) % 1;
      final alpha = math.sin(t * math.pi) * (celebrate ? 0.65 : 0.45);
      final p = Offset(size.width * x + math.sin(t * 8 + i) * 16, size.height * (1 - t));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(celebrate ? t * 8 + i : math.pi / 4);
      final radius = celebrate ? 4.0 : 1.5 + random.nextDouble() * 2;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius),
        Paint()..color = (i.isEven ? Hearth.gold : Hearth.teal).withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Embers old) => old.celebrate != celebrate;
}

class ArcadeBadge extends StatelessWidget {
  const ArcadeBadge(this.label, {super.key, this.icon, this.color = Hearth.teal});
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Hearth.ink.withValues(alpha: 0.85),
      border: Border.all(color: color.withValues(alpha: 0.35)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, color: color, size: 16), const SizedBox(width: 7)],
        Flexible(
          child: Text(
            label,
            style: arcadeType(13, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class ArcadeHeading extends StatelessWidget {
  const ArcadeHeading(this.title, {super.key, this.eyebrow, this.compact = false});
  final String title;
  final String? eyebrow;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (eyebrow != null)
        Text(eyebrow!, style: arcadeType(compact ? 11 : 13, color: Hearth.teal).copyWith(letterSpacing: 3)),
      if (eyebrow != null) SizedBox(height: compact ? 2 : 6),
      Text(
        title,
        style: arcadeType(compact ? 25 : 40, weight: FontWeight.w800),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
