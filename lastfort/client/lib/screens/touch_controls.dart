import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/theme.dart';
import '../game/controls.dart';
import '../game/match_client.dart';
import 'hud.dart';

/// Floating dual-stick touch layer. The left half of the screen owns
/// movement, the right half owns aim + fire; action buttons sit above the
/// right stick. Sticks appear where the finger lands.
class TouchControls extends StatefulWidget {
  const TouchControls({
    super.key,
    required this.controls,
    required this.client,
    required this.haptics,
  });
  final Controls controls;
  final MatchClient client;
  final bool haptics;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  _Stick? left;
  _Stick? right;
  static const radius = 58.0;

  @override
  Widget build(BuildContext context) {
    final p = widget.client.me;
    final inBus = p?.state == PlayerState.inBus;
    final dropping = p?.state == PlayerState.dropping;
    final eliminated = p?.eliminated ?? false;
    final buildMode = p?.buildMode ?? false;
    final mq = MediaQuery.of(context);
    final pad = mq.padding;

    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
        ),
        if (left != null) _StickView(stick: left!, color: LfTokens.teal),
        if (right != null) _StickView(stick: right!, color: LfTokens.ember),
        if (!eliminated)
          Positioned(
            right: LfTokens.s4 + pad.right,
            bottom: 128 + pad.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (inBus || dropping)
                  _ActionButton(
                    icon: inBus
                        ? Icons.flight_land_rounded
                        : Icons.paragliding_rounded,
                    label: inBus ? 'JUMP' : 'GLIDING',
                    big: true,
                    color: LfTokens.teal,
                    onTap: inBus
                        ? () => _tap(GameAction(ActionType.jump))
                        : null,
                  )
                else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.handyman_rounded,
                        label: buildMode ? 'COMBAT' : 'BUILD',
                        color: LfTokens.wood,
                        active: buildMode,
                        onTap: () {
                          _haptic();
                          widget.controls.toggleBuild();
                        },
                      ),
                      const SizedBox(width: LfTokens.s2),
                      _ActionButton(
                        icon: buildMode
                            ? Icons.edit_rounded
                            : Icons.replay_rounded,
                        label: buildMode ? 'EDIT' : 'RELOAD',
                        onTap: () => _tap(
                          GameAction(
                            buildMode ? ActionType.edit : ActionType.reload,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LfTokens.s2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.directions_run_rounded,
                        label: 'SPRINT',
                        active: widget.controls.touchSprint,
                        onTap: () {
                          _haptic();
                          widget.controls.touchSprint =
                              !widget.controls.touchSprint;
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: LfTokens.s2),
                      _ActionButton(
                        icon: Icons.back_hand_rounded,
                        label: 'USE',
                        big: true,
                        color: LfTokens.teal,
                        onTap: () => _tap(GameAction(ActionType.interact)),
                      ),
                    ],
                  ),
                  if (buildMode) ...[
                    const SizedBox(height: LfTokens.s2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final piece in Piece.values) ...[
                          _ActionButton(
                            icon: switch (piece) {
                              Piece.wall => Icons.crop_portrait_rounded,
                              Piece.floor => Icons.crop_landscape_rounded,
                              Piece.ramp => Icons.signal_cellular_4_bar_rounded,
                              Piece.roof => Icons.change_history_rounded,
                            },
                            label: piece.name.toUpperCase(),
                            small: true,
                            active: p?.buildPiece == piece,
                            onTap: () {
                              _haptic();
                              widget.controls.selectPiece(piece);
                            },
                          ),
                          if (piece != Piece.roof) const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        if (eliminated)
          Positioned(
            right: LfTokens.s4 + pad.right,
            bottom: 128 + pad.bottom,
            child: _ActionButton(
              icon: Icons.skip_next_rounded,
              label: 'NEXT',
              color: LfTokens.teal,
              onTap: () => _tap(GameAction(ActionType.spectateNext)),
            ),
          ),
      ],
    );
  }

  void _haptic() {
    if (widget.haptics) HapticFeedback.lightImpact();
  }

  void _tap(GameAction a) {
    _haptic();
    widget.controls.queue(a);
  }

  void _down(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.touch) return;
    final w = MediaQuery.sizeOf(context).width;
    if (e.position.dx < w / 2) {
      if (left != null) return;
      setState(() => left = _Stick(e.pointer, e.position));
    } else {
      if (right != null) return;
      setState(() => right = _Stick(e.pointer, e.position));
      widget.controls.stickFire = true;
    }
  }

  void _move(PointerMoveEvent e) {
    final s = e.pointer == left?.pointer
        ? left
        : (e.pointer == right?.pointer ? right : null);
    if (s == null) return;
    s.current = e.position;
    final v = s.vector(radius);
    if (s == left) {
      widget.controls.stickMoveX = v.dx;
      widget.controls.stickMoveY = v.dy;
      if (v.distance > 0.92) widget.controls.touchSprint = true;
    } else {
      if (v.distance > 0.15) {
        widget.controls.stickAimX = v.dx;
        widget.controls.stickAimY = v.dy;
      }
    }
    setState(() {});
  }

  void _up(PointerEvent e) {
    if (e.pointer == left?.pointer) {
      widget.controls.stickMoveX = 0;
      widget.controls.stickMoveY = 0;
      setState(() => left = null);
    } else if (e.pointer == right?.pointer) {
      widget.controls.stickFire = false;
      widget.controls.stickAimX = 0;
      widget.controls.stickAimY = 0;
      setState(() => right = null);
    }
  }
}

class _Stick {
  _Stick(this.pointer, this.origin) : current = origin;
  final int pointer;
  final Offset origin;
  Offset current;

  Offset vector(double radius) {
    final d = current - origin;
    final len = d.distance;
    if (len <= 1) return Offset.zero;
    final k = math.min(len, radius) / radius;
    return Offset(d.dx / len * k, d.dy / len * k);
  }
}

class _StickView extends StatelessWidget {
  const _StickView({required this.stick, required this.color});
  final _Stick stick;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const r = _TouchControlsState.radius;
    final v = stick.vector(r);
    final knob = stick.origin + v * r;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: stick.origin.dx - r,
            top: stick.origin.dy - r,
            child: Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
                border: Border.all(
                  color: color.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            left: knob.dx - 22,
            top: knob.dy - 22,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.big = false,
    this.small = false,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool big;
  final bool small;
  final bool active;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.big ? 72.0 : (widget.small ? 48.0 : 58.0);
    final col = widget.color ?? Colors.white;
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => pressed = false) : null,
        onTapCancel: () => setState(() => pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: LfTokens.fast,
          scale: pressed ? 0.92 : 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.active
                  ? col.withValues(alpha: 0.45)
                  : const Color(0xB30B0F17),
              border: Border.all(
                color: col.withValues(alpha: enabled ? 0.7 : 0.25),
                width: widget.active ? 2 : 1.5,
              ),
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: col.withValues(alpha: 0.4),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: enabled ? hudText : hudMuted,
                  size: widget.small ? 18 : 22,
                ),
                if (!widget.small) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: enabled ? hudText : hudMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
