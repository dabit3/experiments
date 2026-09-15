import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../theme/tokens.dart';
import 'piece_painter.dart';

String teamName(Team team) => team == Team.one ? 'TIDAL' : 'EMBER';

class ArcadeScaffold extends StatelessWidget {
  const ArcadeScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
  });
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: floatingActionButton,
    body: Stack(
      children: [
        const Positioned.fill(child: SafeArea(child: ArcadeBackdrop())),
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Motion.slow,
            curve: Motion.curve,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 10),
                child: child,
              ),
            ),
            child: body,
          ),
        ),
      ],
    ),
  );
}

class ArcadeBackdrop extends StatelessWidget {
  const ArcadeBackdrop({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _Backdrop(context.colors)),
      ),
    ),
  );
}

class _Backdrop extends CustomPainter {
  _Backdrop(this.c);
  final SwapColors c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.canvas, c.surfaceSunken, c.canvas],
        ).createShader(Offset.zero & size),
    );
    final ink = Paint()..color = c.text.withValues(alpha: 0.035);
    for (double y = 20; y < size.height; y += 28) {
      for (double x = 20; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 1, ink);
      }
    }
    final stroke = Paint()
      ..color = c.teamOne.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.12, size.height * 0.48),
        190 + i * 52,
        stroke,
      );
    }
    final corner = Path()
      ..moveTo(size.width, size.height * 0.6)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      corner,
      Paint()..color = c.teamTwo.withValues(alpha: 0.035),
    );
  }

  @override
  bool shouldRepaint(_Backdrop old) => c != old.c;
}

class ArcadeEyebrow extends StatelessWidget {
  const ArcadeEyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.colors.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 3, color: ink),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: context.type.labelSmall?.copyWith(
              color: ink,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class TeamEmblem extends StatelessWidget {
  const TeamEmblem({super.key, required this.team, this.size = 40});
  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.team(team);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        team == Team.one
            ? Icons.waves_rounded
            : Icons.local_fire_department_rounded,
        color: context.colors.canvas,
        size: size * 0.68,
      ),
    );
  }
}

class ArcadeWordmark extends StatelessWidget {
  const ArcadeWordmark({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SwapmateMark(size: 32),
      const SizedBox(width: 10),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Swapmate', style: context.type.headlineLarge),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.accent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '2 VS 2',
          style: context.type.labelSmall?.copyWith(
            color: context.colors.onAccent,
            fontSize: 9,
          ),
        ),
      ),
    ],
  );
}

/// Original miniature arena; all artwork shares the playable piece renderer.
class ArenaIllustration extends StatelessWidget {
  const ArenaIllustration({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 2.15,
      child: RepaintBoundary(
        child: CustomPaint(painter: _ArenaPainter(context.colors)),
      ),
    ),
  );
}

class _ArenaPainter extends CustomPainter {
  _ArenaPainter(this.c);
  final SwapColors c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 480, size.height / 224);
    final halo = Paint()..color = c.teamOne.withValues(alpha: 0.10);
    canvas.drawOval(const Rect.fromLTWH(35, 24, 400, 170), halo);
    void arena(double x, double y, double angle, Color accent, Piece piece) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final slab = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-78, -54, 156, 110),
        const Radius.circular(16),
      );
      canvas.drawRRect(
        slab.shift(const Offset(0, 12)),
        Paint()..color = c.canvas,
      );
      canvas.drawRRect(slab, Paint()..color = accent);
      canvas.save();
      canvas.clipRRect(slab.deflate(6));
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 6; col++) {
          canvas.drawRect(
            Rect.fromLTWH(-72 + col * 24, -48 + row * 24, 24, 24),
            Paint()
              ..color = (row + col).isEven
                  ? c.boardLight
                  : accent.withValues(alpha: 0.45),
          );
        }
      }
      canvas.restore();
      canvas.rotate(-angle);
      canvas.translate(-50, -117);
      PiecePainter(piece: piece, colors: c).paint(canvas, const Size(100, 128));
      canvas.restore();
    }

    arena(
      148,
      135,
      -0.15,
      c.teamOne,
      const Piece(PieceColor.white, PieceType.knight),
    );
    arena(
      330,
      145,
      0.16,
      c.teamTwo,
      const Piece(PieceColor.black, PieceType.queen),
    );
    final line = Paint()
      ..color = c.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(188, 56)
        ..quadraticBezierTo(245, 14, 290, 53),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(278, 51)
        ..lineTo(291, 54)
        ..lineTo(288, 41),
      line,
    );
    for (final p in const [Offset(58, 83), Offset(410, 67), Offset(247, 176)]) {
      canvas.drawLine(p - const Offset(4, 0), p + const Offset(4, 0), line);
      canvas.drawLine(p - const Offset(0, 4), p + const Offset(0, 4), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArenaPainter old) => c != old.c;
}

class ResultMedal extends StatelessWidget {
  const ResultMedal({super.key, required this.color, required this.won});
  final Color color;
  final bool won;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 88,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: const Size.square(88), painter: _MedalPainter(color)),
        Icon(
          won ? Icons.emoji_events_rounded : Icons.shield_rounded,
          color: context.colors.canvas,
          size: 42,
        ),
      ],
    ),
  );
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final star = Path();
    for (var i = 0; i < 32; i++) {
      final a = i * math.pi / 16;
      final r = i.isEven ? 42.0 : 36.0;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star.shift(const Offset(0, 3)),
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawPath(star, Paint()..color = color);
    canvas.drawCircle(
      center,
      29,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_MedalPainter old) => color != old.color;
}
