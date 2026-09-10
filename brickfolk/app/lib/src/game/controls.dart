import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Whether this device most likely wants on-screen controls.
bool wantsTouchControls(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      return true;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return false;
  }
}

/// A large translucent circular button for thumbs.
class TouchButton extends StatefulWidget {
  const TouchButton({
    super.key,
    required this.icon,
    required this.onChanged,
    this.label,
    this.size = 72,
    this.color,
  });

  final IconData icon;
  final String? label;
  final double size;
  final Color? color;
  final ValueChanged<bool> onChanged;

  @override
  State<TouchButton> createState() => _TouchButtonState();
}

class _TouchButtonState extends State<TouchButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? BrickColors.sky;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedContainer(
          duration: Motion.fast,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _down ? color : color.withValues(alpha: 0.55),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: widget.size * 0.45,
          ),
        ),
      ),
    );
  }
}

/// Virtual joystick reporting a normalized direction in [-1, 1].
class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({super.key, required this.onChanged, this.size = 140});

  final void Function(double dx, double dy) onChanged;
  final double size;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knob = Offset.zero;
  bool _active = false;

  void _update(Offset local) {
    final r = widget.size / 2;
    var v = (local - Offset(r, r)) / r;
    if (v.distance > 1) v = v / v.distance;
    setState(() {
      _knob = v;
      _active = true;
    });
    // Deadzone then rescale so tiny drags don't move the player.
    final d = v.distance;
    if (d < 0.18) {
      widget.onChanged(0, 0);
    } else {
      final s = ((d - 0.18) / 0.82).clamp(0.0, 1.0) / d;
      widget.onChanged(v.dx * s, v.dy * s);
    }
  }

  void _release() {
    setState(() {
      _knob = Offset.zero;
      _active = false;
    });
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.size / 2;
    return Semantics(
      label: 'Movement joystick',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _update(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Motion.fast,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: _active ? 0.35 : 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              Positioned(
                left: r + _knob.dx * r * 0.6 - r * 0.32,
                top: r + _knob.dy * r * 0.6 - r * 0.32,
                child: Container(
                  width: r * 0.64,
                  height: r * 0.64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrickColors.sky.withValues(
                      alpha: _active ? 1 : 0.75,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maps a set of pressed logical keys to a 2D direction.
({double dx, double dy}) directionFromKeys(Set<String> pressed) {
  var dx = 0.0;
  var dy = 0.0;
  if (pressed.contains('left')) dx -= 1;
  if (pressed.contains('right')) dx += 1;
  if (pressed.contains('up')) dy -= 1;
  if (pressed.contains('down')) dy += 1;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len > 1) {
    dx /= len;
    dy /= len;
  }
  return (dx: dx, dy: dy);
}
