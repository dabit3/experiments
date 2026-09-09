import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitro_core/nitro_core.dart';

import '../theme/tokens.dart';

/// Aggregates keyboard + touch state into a [KartInput] once per frame.
class InputController {
  InputController({required this.autoAccelerate});

  bool autoAccelerate;

  // Keyboard.
  final Set<LogicalKeyboardKey> _keys = {};
  // Touch.
  double touchSteer = 0;
  bool touchGas = false;
  bool touchBrake = false;
  bool touchDrift = false;
  bool touchLookBack = false;
  bool _itemPressed = false;
  bool _pausePressed = false;

  bool handleKey(KeyEvent e) {
    final k = e.logicalKey;
    if (e is KeyDownEvent) {
      if (!_keys.contains(k)) {
        if (k == LogicalKeyboardKey.keyZ ||
            k == LogicalKeyboardKey.keyX ||
            k == LogicalKeyboardKey.enter ||
            k == LogicalKeyboardKey.keyE ||
            k == LogicalKeyboardKey.controlLeft ||
            k == LogicalKeyboardKey.controlRight) {
          _itemPressed = true;
        }
        if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.keyP) _pausePressed = true;
      }
      _keys.add(k);
      return true;
    }
    if (e is KeyUpEvent) {
      _keys.remove(k);
      return true;
    }
    return false;
  }

  bool _any(List<LogicalKeyboardKey> ks) => ks.any(_keys.contains);

  void pressItem() => _itemPressed = true;

  /// Whether the pause key was hit since the last poll (edge-triggered).
  bool consumePause() {
    final p = _pausePressed;
    _pausePressed = false;
    return p;
  }

  KartInput poll() {
    var steer = touchSteer;
    if (_any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA])) steer -= 1;
    if (_any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD])) steer += 1;
    var throttle = 0.0;
    final gas = touchGas || _any([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW]);
    final brake = touchBrake || _any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS]);
    if (gas) throttle = 1;
    if (brake) throttle = -1;
    if (!gas && !brake && autoAccelerate) throttle = 1;
    final drift = touchDrift || _any([LogicalKeyboardKey.space, LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight]);
    final lookBack = touchLookBack || _any([LogicalKeyboardKey.keyQ, LogicalKeyboardKey.altLeft]);
    final item = _itemPressed;
    _itemPressed = false;
    return KartInput(throttle: throttle, steer: steer.clamp(-1, 1), drift: drift, item: item, lookBack: lookBack);
  }

  void clear() {
    _keys.clear();
    touchSteer = 0;
    touchGas = false;
    touchBrake = false;
    touchDrift = false;
    touchLookBack = false;
  }
}

/// On-screen controls for phones/tablets: steer pad on the left, action
/// cluster on the right. Sized for thumbs; respects safe areas.
class TouchControls extends StatelessWidget {
  const TouchControls({super.key, required this.input, required this.showGas});
  final InputController input;
  final bool showGas;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).shortestSide < 420;
    final big = compact ? 68.0 : 80.0;
    final small = compact ? 54.0 : 62.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 14 : 22, 0, compact ? 14 : 22, compact ? 14 : 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SteerPad(input: input, size: compact ? 150 : 180),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HoldButton(label: 'Item', icon: Icons.auto_awesome_rounded, color: NtColors.grape, size: small, onDown: input.pressItem, onUp: () {}),
                  const SizedBox(width: 10),
                  _HoldButton(
                    label: 'Look back',
                    icon: Icons.u_turn_left_rounded,
                    color: NtColors.inkSoft,
                    size: small,
                    onDown: () => input.touchLookBack = true,
                    onUp: () => input.touchLookBack = false,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showGas) ...[
                    _HoldButton(
                      label: 'Brake',
                      icon: Icons.remove_rounded,
                      color: NtColors.bubblegum,
                      size: small,
                      onDown: () => input.touchBrake = true,
                      onUp: () => input.touchBrake = false,
                    ),
                    const SizedBox(width: 10),
                    _HoldButton(
                      label: 'Gas',
                      icon: Icons.keyboard_double_arrow_up_rounded,
                      color: NtColors.lime,
                      size: big,
                      onDown: () => input.touchGas = true,
                      onUp: () => input.touchGas = false,
                    ),
                    const SizedBox(width: 10),
                  ],
                  _HoldButton(
                    label: 'Drift',
                    icon: Icons.local_fire_department_rounded,
                    color: NtColors.nitro,
                    size: big,
                    onDown: () => input.touchDrift = true,
                    onUp: () => input.touchDrift = false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({required this.label, required this.icon, required this.color, required this.size, required this.onDown, required this.onUp});
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (v == _down) return;
    setState(() => _down = v);
    v ? widget.onDown() : widget.onUp();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: NtMotion.fast,
          width: widget.size,
          height: widget.size,
          transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _down ? widget.color : widget.color.withValues(alpha: 0.82),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), offset: Offset(0, _down ? 1 : 4), blurRadius: 6)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: widget.size * 0.4),
              Text(widget.label.toUpperCase(), style: NtType.caption(Colors.white).copyWith(fontSize: widget.size * 0.13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal steering slider: drag left/right anywhere on the pad.
class _SteerPad extends StatefulWidget {
  const _SteerPad({required this.input, required this.size});
  final InputController input;
  final double size;

  @override
  State<_SteerPad> createState() => _SteerPadState();
}

class _SteerPadState extends State<_SteerPad> {
  double _x = 0;
  bool _active = false;

  void _update(Offset local) {
    final half = widget.size / 2;
    final v = ((local.dx - half) / (half * 0.7)).clamp(-1.0, 1.0);
    setState(() => _x = v);
    widget.input.touchSteer = v;
  }

  void _release() {
    setState(() {
      _x = 0;
      _active = false;
    });
    widget.input.touchSteer = 0;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.size * 0.5;
    return Semantics(
      label: 'Steering pad',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          setState(() => _active = true);
          _update(e.localPosition);
        },
        onPointerMove: (e) => _update(e.localPosition),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: Container(
          width: widget.size,
          height: h,
          decoration: BoxDecoration(
            color: NtColors.inkDark.withValues(alpha: _active ? 0.7 : 0.5),
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(left: 16, child: Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.6), size: 32)),
              Positioned(right: 16, child: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.6), size: 32)),
              AnimatedAlign(
                duration: _active ? Duration.zero : NtMotion.fast,
                alignment: Alignment(_x * 0.7, 0),
                child: Container(
                  width: h - 14,
                  height: h - 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Icon(Icons.drag_handle_rounded, color: NtColors.inkSoft, size: h * 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
