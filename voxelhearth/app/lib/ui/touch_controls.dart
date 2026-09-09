import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_controller.dart';
import 'game_screen.dart';
import 'theme.dart';

/// Virtual joystick (bottom-left) and action buttons (bottom-right) for
/// phones and tablets. The world layer beneath handles look / break.
class TouchControls extends StatefulWidget {
  const TouchControls({super.key, required this.game, required this.frame});
  final GameController game;
  final FrameNotifier frame;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  Offset? _stickCenter;
  Offset _knob = Offset.zero;
  static const _radius = 58.0;

  void _start(DragStartDetails d) {
    setState(() {
      _stickCenter = d.localPosition;
      _knob = Offset.zero;
    });
  }

  void _update(DragUpdateDetails d) {
    final c = _stickCenter;
    if (c == null) return;
    var v = d.localPosition - c;
    if (v.distance > _radius) v = v / v.distance * _radius;
    setState(() => _knob = v);
    widget.game.joyX = v.dx / _radius;
    widget.game.joyY = -v.dy / _radius;
    widget.game.touchSprint = v.distance > _radius * 0.92;
  }

  void _end(DragEndDetails _) => _release();

  void _release() {
    setState(() {
      _stickCenter = null;
      _knob = Offset.zero;
    });
    widget.game.joyX = 0;
    widget.game.joyY = 0;
    widget.game.touchSprint = false;
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final size = MediaQuery.sizeOf(context);
    final compact = size.shortestSide < 500;
    final btn = compact ? 54.0 : 64.0;
    return SafeArea(
      child: Stack(
        children: [
          // Joystick zone: left 45% of the screen, lower 70%
          Positioned(
            left: 0,
            bottom: compact ? 70 : 96,
            width: size.width * 0.45,
            height: size.height * 0.62,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _start,
              onPanUpdate: _update,
              onPanEnd: _end,
              onPanCancel: _release,
              child: CustomPaint(
                painter: _StickPainter(
                  _stickCenter,
                  _knob,
                  _radius,
                  Offset(compact ? 84 : 110, size.height * 0.62 - (compact ? 84 : 110)),
                ),
              ),
            ),
          ),
          // Action cluster
          Positioned(
            right: VhSpace.md,
            bottom: compact ? 84 : 112,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Btn(icon: Icons.add_box_outlined, label: 'Place', size: btn, onTap: g.use),
                    const SizedBox(width: VhSpace.sm),
                    _HoldBtn(
                      icon: g.flying ? Icons.arrow_upward_rounded : Icons.keyboard_double_arrow_up_rounded,
                      label: g.flying ? 'Up' : 'Jump',
                      size: btn * 1.15,
                      onDown: () => g.touchJump = true,
                      onUp: () => g.touchJump = false,
                    ),
                  ],
                ),
                const SizedBox(height: VhSpace.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (g.isCreative)
                      Padding(
                        padding: const EdgeInsets.only(right: VhSpace.sm),
                        child: _Btn(
                          icon: Icons.flight_rounded,
                          label: 'Fly',
                          size: btn * 0.85,
                          active: g.flying,
                          onTap: g.toggleFly,
                        ),
                      ),
                    _HoldBtn(
                      icon: g.flying ? Icons.arrow_downward_rounded : Icons.keyboard_double_arrow_down_rounded,
                      label: g.flying ? 'Down' : 'Sneak',
                      size: btn * 0.85,
                      onDown: () => g.touchSneak = true,
                      onUp: () => g.touchSneak = false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickPainter extends CustomPainter {
  _StickPainter(this.center, this.knob, this.radius, this.rest);
  final Offset? center;
  final Offset knob;
  final double radius;
  final Offset rest;

  @override
  void paint(Canvas c, Size s) {
    final ctr = center ?? rest;
    final active = center != null;
    c.drawCircle(ctr, radius, Paint()..color = Colors.black.withValues(alpha: active ? 0.35 : 0.22));
    c.drawCircle(
      ctr,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: active ? 0.5 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // sprint ring hint
    c.drawCircle(
      ctr,
      radius * 0.92,
      Paint()
        ..color = VhColors.gold.withValues(alpha: knob.distance > radius * 0.9 ? 0.8 : 0.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final k = ctr + knob;
    c.drawCircle(k, radius * 0.42, Paint()..color = Colors.white.withValues(alpha: active ? 0.85 : 0.45));
    c.drawCircle(
      k,
      radius * 0.42,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (!active) {
      final p = Paint()..color = Colors.white.withValues(alpha: 0.5);
      for (final a in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
        final d = Offset(math.cos(a), math.sin(a));
        final tip = ctr + d * (radius * 0.72);
        final path = Path()
          ..moveTo(tip.dx + d.dx * 5, tip.dy + d.dy * 5)
          ..lineTo(tip.dx - d.dy * 4, tip.dy + d.dx * 4)
          ..lineTo(tip.dx + d.dy * 4, tip.dy - d.dx * 4)
          ..close();
        c.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StickPainter old) => old.center != center || old.knob != knob;
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.label, required this.size, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: _Round(icon: icon, label: label, size: size, pressed: active),
    ),
  );
}

class _HoldBtn extends StatefulWidget {
  const _HoldBtn({
    required this.icon,
    required this.label,
    required this.size,
    required this.onDown,
    required this.onUp,
  });
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onDown, onUp;

  @override
  State<_HoldBtn> createState() => _HoldBtnState();
}

class _HoldBtnState extends State<_HoldBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _down = true);
        widget.onDown();
      },
      onPointerUp: (_) {
        setState(() => _down = false);
        widget.onUp();
      },
      onPointerCancel: (_) {
        setState(() => _down = false);
        widget.onUp();
      },
      child: _Round(icon: widget.icon, label: widget.label, size: widget.size, pressed: _down),
    ),
  );
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.label, required this.size, required this.pressed});
  final IconData icon;
  final String label;
  final double size;
  final bool pressed;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 90),
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: pressed ? VhColors.gold.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.38),
      border: Border.all(color: Colors.white.withValues(alpha: pressed ? 0.9 : 0.35), width: 1.5),
      boxShadow: pressed ? [BoxShadow(color: VhColors.gold.withValues(alpha: 0.4), blurRadius: 16)] : null,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: size * 0.42),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: size * 0.16,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
