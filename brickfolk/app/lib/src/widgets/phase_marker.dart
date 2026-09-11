import 'dart:async';

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/tokens.dart';

/// Test-only overlay: a solid block at the middle of the left edge whose
/// colour names the screen the app is showing ([colors]). A harness that can
/// only read a device display trailing the app by many seconds samples the
/// block to tell which state a grabbed frame really shows.
///
/// The colour changes only after the screen transition it describes has
/// finished, so any frame carrying a colour shows that screen fully drawn.
class PhaseMarker extends StatefulWidget {
  const PhaseMarker({super.key, required this.child});

  final Widget child;

  static const size = Size(16, 48);

  /// Marker colours by screen: sign-in paints none.
  static const colors = <String, Color>{
    'hub': Color(0xFFF0C800),
    'lobby': Color(0xFF0050FF),
    'countdown': Color(0xFF00C8FF),
    'gameplay': Color(0xFF00DC28),
    'results': Color(0xFFE600E6),
  };

  static String? screenOf(BuildContext context) {
    final client = ClientScope.of(context);
    if (client.me == null) return null;
    final room = client.room;
    if (room == null) return 'hub';
    return switch (room.phase) {
      RoomPhase.lobby => 'lobby',
      RoomPhase.countdown => 'countdown',
      RoomPhase.playing => 'gameplay',
      RoomPhase.results => client.results == null ? null : 'results',
    };
  }

  @override
  State<PhaseMarker> createState() => _PhaseMarkerState();
}

class _PhaseMarkerState extends State<PhaseMarker> {
  static const settle = Duration(milliseconds: 200);

  String? _shown;
  String? _pending;
  bool _hasPending = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _track(String? screen) {
    if (screen == (_hasPending ? _pending : _shown)) return;
    _timer?.cancel();
    _hasPending = screen != _shown;
    if (!_hasPending) return;
    _pending = screen;
    _timer = Timer(Motion.slow + settle, () {
      if (!mounted) return;
      setState(() {
        _shown = _pending;
        _hasPending = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _track(PhaseMarker.screenOf(context));
    final color = PhaseMarker.colors[_shown];
    return Stack(
      children: [
        widget.child,
        if (color != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  width: PhaseMarker.size.width,
                  height: PhaseMarker.size.height,
                  color: color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
