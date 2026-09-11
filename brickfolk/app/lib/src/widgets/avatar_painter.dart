import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Paints a blocky Brickfolk avatar into [rect]. Shared by the Flutter UI and
/// the Flame game components so the figure looks identical everywhere.
///
/// The figure is 6 units wide and 10 units tall: head 3x3 (top), torso 4x4,
/// arms 1x4 beside the torso, legs 2x3 each below.
void paintAvatar(
  Canvas canvas,
  Rect rect,
  Avatar avatar, {
  bool facingRight = true,
  double walk = 0,
  bool frozen = false,
  double alpha = 1,
}) {
  final unit = math.min(rect.width / 6, rect.height / 10);
  final w = unit * 6;
  final h = unit * 10;
  final ox = rect.left + (rect.width - w) / 2;
  final oy = rect.top + (rect.height - h) / 2;

  canvas.save();
  if (!facingRight) {
    canvas.translate(ox + w, oy);
    canvas.scale(-1, 1);
  } else {
    canvas.translate(ox, oy);
  }

  Color c(int argb) {
    var color = Color(argb);
    if (frozen) color = Color.lerp(color, const Color(0xFF9BDDFF), 0.6)!;
    return color.withValues(alpha: alpha);
  }

  Paint fill(Color color) => Paint()..color = color;
  Color shade(Color color, double amount) =>
      Color.lerp(color, Colors.black, amount)!.withValues(alpha: alpha);
  Color tint(Color color, double amount) =>
      Color.lerp(color, Colors.white, amount)!.withValues(alpha: alpha);

  void block(Rect r, Color color, {double radius = 0.18}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(unit * radius));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint(color, 0.15), color, shade(color, 0.16)],
        ).createShader(r),
    );
    // Bevel: light top edge, dark bottom edge.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.top, r.width, unit * 0.22),
        Radius.circular(unit * radius),
      ),
      fill(tint(color, 0.28)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.bottom - unit * 0.22, r.width, unit * 0.22),
        Radius.circular(unit * radius),
      ),
      fill(shade(color, 0.22)),
    );
  }

  final swing = math.sin(walk * math.pi * 2) * unit * 0.9;

  // Legs.
  final leg = c(avatar.legColor);
  block(
    Rect.fromLTWH(
      unit * 1,
      unit * 7 + swing.abs() * 0.1,
      unit * 1.9,
      unit * 3 - swing.abs() * 0.1,
    ),
    leg,
  );
  block(
    Rect.fromLTWH(
      unit * 3.1,
      unit * 7 + swing.abs() * 0.1,
      unit * 1.9,
      unit * 3 - swing.abs() * 0.1,
    ),
    shade(leg, 0.12),
  );
  // Torso.
  final torso = c(avatar.torsoColor);
  block(Rect.fromLTWH(unit * 1, unit * 3, unit * 4, unit * 4), torso);
  // Arms.
  final arm = c(avatar.armColor);
  block(
    Rect.fromLTWH(0, unit * 3 + swing * 0.15, unit * 0.95, unit * 3.8),
    arm,
  );
  block(
    Rect.fromLTWH(
      unit * 5.05,
      unit * 3 - swing * 0.15,
      unit * 0.95,
      unit * 3.8,
    ),
    shade(arm, 0.1),
  );
  // Head.
  final head = c(avatar.headColor);
  block(Rect.fromLTWH(unit * 1.5, 0, unit * 3, unit * 3), head, radius: 0.35);

  _paintAccessory(canvas, unit, avatar.accessory, alpha);
  _paintFace(canvas, unit, avatar.face, alpha, frozen);
  _paintHat(canvas, unit, avatar.hat, alpha);

  canvas.restore();
}

void _paintFace(
  Canvas canvas,
  double u,
  String face,
  double alpha,
  bool frozen,
) {
  final ink = const Color(0xFF1B1F27).withValues(alpha: alpha);
  final white = Colors.white.withValues(alpha: alpha);
  final paint = Paint()..color = ink;
  final stroke = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = u * 0.22
    ..strokeCap = StrokeCap.round;
  // Eyes are centred on the head (x 1.5..4.5); face features are drawn in
  // the "right facing" orientation.
  final leftEye = Offset(u * 2.35, u * 1.2);
  final rightEye = Offset(u * 3.65, u * 1.2);
  switch (face) {
    case 'face_shades':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.75, u * 0.85, u * 1.15, u * 0.7),
          Radius.circular(u * 0.2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 3.1, u * 0.85, u * 1.15, u * 0.7),
          Radius.circular(u * 0.2),
        ),
        paint,
      );
      canvas.drawLine(
        Offset(u * 2.9, u * 1.1),
        Offset(u * 3.1, u * 1.1),
        stroke,
      );
      canvas.drawLine(
        Offset(u * 2.4, u * 2.3),
        Offset(u * 3.6, u * 2.3),
        stroke,
      );
    case 'face_wink':
      canvas.drawCircle(leftEye, u * 0.28, paint);
      canvas.drawLine(
        Offset(u * 3.35, u * 1.2),
        Offset(u * 3.95, u * 1.2),
        stroke,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(u * 3, u * 2.05),
          width: u * 1.4,
          height: u * 0.9,
        ),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        stroke,
      );
    case 'face_grin':
      canvas.drawCircle(leftEye, u * 0.28, paint);
      canvas.drawCircle(rightEye, u * 0.28, paint);
      final mouth = Path()
        ..moveTo(u * 2.1, u * 1.95)
        ..lineTo(u * 3.9, u * 1.95)
        ..arcToPoint(
          Offset(u * 2.1, u * 1.95),
          radius: Radius.circular(u * 1),
          clockwise: true,
        )
        ..close();
      canvas.drawPath(mouth, paint);
      canvas.drawRect(
        Rect.fromLTWH(u * 2.3, u * 1.95, u * 1.4, u * 0.3),
        Paint()..color = white,
      );
    case 'face_sleepy':
      canvas.drawLine(
        Offset(u * 2.05, u * 1.25),
        Offset(u * 2.65, u * 1.25),
        stroke,
      );
      canvas.drawLine(
        Offset(u * 3.35, u * 1.25),
        Offset(u * 3.95, u * 1.25),
        stroke,
      );
      canvas.drawCircle(Offset(u * 3, u * 2.15), u * 0.22, paint);
    case 'face_robot':
      canvas.drawRect(
        Rect.fromCenter(center: leftEye, width: u * 0.6, height: u * 0.5),
        Paint()..color = const Color(0xFF35B8D6).withValues(alpha: alpha),
      );
      canvas.drawRect(
        Rect.fromCenter(center: rightEye, width: u * 0.6, height: u * 0.5),
        Paint()..color = const Color(0xFF35B8D6).withValues(alpha: alpha),
      );
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(u * (2.2 + i * 0.5), u * 2.1),
          Offset(u * (2.2 + i * 0.5), u * 2.4),
          stroke,
        );
      }
      canvas.drawLine(
        Offset(u * 2.2, u * 2.1),
        Offset(u * 3.8, u * 2.1),
        stroke,
      );
    default: // face_smile
      canvas.drawCircle(leftEye, u * 0.28, paint);
      canvas.drawCircle(rightEye, u * 0.28, paint);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(u * 3, u * 1.95),
          width: u * 1.4,
          height: u * 0.9,
        ),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        stroke,
      );
  }
  if (frozen) {
    final ice = Paint()
      ..color = const Color(0xFFBFEFFF).withValues(alpha: 0.55 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.18;
    canvas.drawLine(Offset(u * 1.2, u * 3.4), Offset(u * 2.4, u * 5.4), ice);
    canvas.drawLine(Offset(u * 4.6, u * 4.2), Offset(u * 3.4, u * 6.6), ice);
  }
}

void _paintHat(Canvas canvas, double u, String hat, double alpha) {
  Paint p(Color c) => Paint()..color = c.withValues(alpha: alpha);
  switch (hat) {
    case 'hat_cap':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.35, -u * 0.55, u * 3.3, u * 1.0),
          Radius.circular(u * 0.35),
        ),
        p(const Color(0xFF3E7BFA)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 3.6, u * 0.05, u * 1.9, u * 0.42),
          Radius.circular(u * 0.2),
        ),
        p(const Color(0xFF2B5FD1)),
      );
    case 'hat_crown':
      final path = Path()
        ..moveTo(u * 1.5, u * 0.35)
        ..lineTo(u * 1.5, -u * 0.9)
        ..lineTo(u * 2.25, -u * 0.2)
        ..lineTo(u * 3.0, -u * 1.1)
        ..lineTo(u * 3.75, -u * 0.2)
        ..lineTo(u * 4.5, -u * 0.9)
        ..lineTo(u * 4.5, u * 0.35)
        ..close();
      canvas.drawPath(path, p(const Color(0xFFF5C04A)));
      canvas.drawCircle(
        Offset(u * 3, -u * 0.1),
        u * 0.18,
        p(const Color(0xFFE8455C)),
      );
    case 'hat_helmet':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.3, -u * 0.7, u * 3.4, u * 1.15),
          Radius.circular(u * 0.55),
        ),
        p(const Color(0xFFF5C04A)),
      );
      canvas.drawRect(
        Rect.fromLTWH(u * 1.15, u * 0.2, u * 3.7, u * 0.3),
        p(const Color(0xFFCB9A1C)),
      );
    case 'hat_wizard':
      final path = Path()
        ..moveTo(u * 1.2, u * 0.4)
        ..lineTo(u * 4.8, u * 0.4)
        ..lineTo(u * 3.7, -u * 0.1)
        ..lineTo(u * 3.3, -u * 2.4)
        ..lineTo(u * 2.3, -u * 0.1)
        ..close();
      canvas.drawPath(path, p(const Color(0xFF8C5CF6)));
      canvas.drawCircle(
        Offset(u * 2.9, -u * 1.0),
        u * 0.2,
        p(const Color(0xFFF5C04A)),
      );
    case 'hat_beanie':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.35, -u * 0.75, u * 3.3, u * 1.3),
          Radius.circular(u * 0.7),
        ),
        p(const Color(0xFFE8455C)),
      );
      canvas.drawRect(
        Rect.fromLTWH(u * 1.35, u * 0.15, u * 3.3, u * 0.4),
        p(const Color(0xFFC2354A)),
      );
      canvas.drawCircle(Offset(u * 3, -u * 0.85), u * 0.3, p(Colors.white));
    case 'hat_propeller':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.5, -u * 0.35, u * 3, u * 0.8),
          Radius.circular(u * 0.5),
        ),
        p(const Color(0xFF2FBF8A)),
      );
      canvas.drawRect(
        Rect.fromLTWH(u * 2.9, -u * 1.1, u * 0.2, u * 0.8),
        p(const Color(0xFF6B7789)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.6, -u * 1.25, u * 2.8, u * 0.3),
          Radius.circular(u * 0.15),
        ),
        p(const Color(0xFFF5C04A)),
      );
    default:
      break;
  }
}

void _paintAccessory(Canvas canvas, double u, String accessory, double alpha) {
  Paint p(Color c) => Paint()..color = c.withValues(alpha: alpha);
  switch (accessory) {
    case 'acc_scarf':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 1.2, u * 2.85, u * 3.6, u * 0.75),
          Radius.circular(u * 0.3),
        ),
        p(const Color(0xFFE8455C)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(u * 3.6, u * 3.4, u * 0.9, u * 1.8),
          Radius.circular(u * 0.25),
        ),
        p(const Color(0xFFC2354A)),
      );
    case 'acc_backpack':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-u * 0.1, u * 3.3, u * 1.3, u * 3.2),
          Radius.circular(u * 0.35),
        ),
        p(const Color(0xFFFF6B4A)),
      );
      canvas.drawRect(
        Rect.fromLTWH(u * 0.1, u * 4.2, u * 0.9, u * 0.3),
        p(const Color(0xFFD94E31)),
      );
    case 'acc_cape':
      final path = Path()
        ..moveTo(u * 1.0, u * 3.2)
        ..lineTo(u * 0.1, u * 8.4)
        ..lineTo(u * 1.4, u * 7.9)
        ..lineTo(u * 1.1, u * 3.2)
        ..close();
      canvas.drawPath(path, p(const Color(0xFF8C5CF6)));
    case 'acc_tie':
      canvas.drawPath(
        Path()
          ..moveTo(u * 2.3, u * 3.2)
          ..lineTo(u * 3.0, u * 3.55)
          ..lineTo(u * 3.7, u * 3.2)
          ..lineTo(u * 3.7, u * 3.9)
          ..lineTo(u * 3.0, u * 3.55)
          ..lineTo(u * 2.3, u * 3.9)
          ..close(),
        p(const Color(0xFFE8455C)),
      );
    case 'acc_wings':
      final wing = p(const Color(0xFFBFEFFF));
      canvas.drawPath(
        Path()
          ..moveTo(u * 1.0, u * 3.6)
          ..lineTo(-u * 1.3, u * 2.6)
          ..lineTo(-u * 0.9, u * 5.2)
          ..lineTo(u * 1.0, u * 5.4)
          ..close(),
        wing,
      );
      canvas.drawPath(
        Path()
          ..moveTo(u * 5.0, u * 3.6)
          ..lineTo(u * 7.3, u * 2.6)
          ..lineTo(u * 6.9, u * 5.2)
          ..lineTo(u * 5.0, u * 5.4)
          ..close(),
        wing,
      );
    default:
      break;
  }
}

/// Widget wrapper around [paintAvatar].
class AvatarView extends StatelessWidget {
  const AvatarView(
    this.avatar, {
    super.key,
    this.size = 72,
    this.facingRight = true,
    this.frozen = false,
    this.background,
  });

  final Avatar avatar;
  final double size;
  final bool facingRight;
  final bool frozen;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final body = CustomPaint(
      size: Size(size * 0.6, size),
      painter: _AvatarWidgetPainter(avatar, facingRight, frozen),
    );
    if (background == null) return body;
    return Container(
      width: size * 1.1,
      height: size * 1.1,
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: size * 0.05),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: SizedBox(
        height: size * 0.85,
        child: FittedBox(child: body),
      ),
    );
  }
}

class _AvatarWidgetPainter extends CustomPainter {
  const _AvatarWidgetPainter(this.avatar, this.facingRight, this.frozen);

  final Avatar avatar;
  final bool facingRight;
  final bool frozen;

  @override
  void paint(Canvas canvas, Size size) {
    // Leave headroom for tall hats.
    final rect = Rect.fromLTWH(
      0,
      size.height * 0.18,
      size.width,
      size.height * 0.82,
    );
    paintAvatar(canvas, rect, avatar, facingRight: facingRight, frozen: frozen);
  }

  @override
  bool shouldRepaint(_AvatarWidgetPainter old) =>
      old.avatar != avatar ||
      old.facingRight != facingRight ||
      old.frozen != frozen;
}

/// Circular avatar crop used for greetings and friend bubbles.
class Headshot extends StatelessWidget {
  const Headshot(this.avatar, {super.key, required this.size, this.online});

  final Avatar avatar;
  final double size;
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              color: p.surface2,
              alignment: Alignment.topCenter,
              child: OverflowBox(
                maxHeight: size * 1.9,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: size * 0.12),
                  child: AvatarView(avatar, size: size * 1.9),
                ),
              ),
            ),
          ),
          if (online != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: online! ? BrickColors.mint : p.textTertiary,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface0, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
