import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

/// Aggregates keyboard, mouse/trackpad and touch input into the per-tick
/// [InputFrame] fields. The match screen writes here; the game loop reads and
/// clears queued actions every simulation tick.
class Controls extends ChangeNotifier {
  final Set<LogicalKeyboardKey> _keys = {};
  final List<GameAction> _pending = [];

  // Touch sticks (unit vectors, zero when released).
  double stickMoveX = 0;
  double stickMoveY = 0;
  double stickAimX = 0;
  double stickAimY = 0;
  bool stickFire = false;
  bool touchSprint = false;

  /// Screen-space pointer position (mouse / trackpad hover) or null.
  Offset? pointer;
  bool mouseFire = false;

  /// Aim angle in radians, updated by the game from [pointer] or sticks.
  double aim = 0;
  bool _hasMouseAim = false;
  bool buildModeLocal = false;
  bool get usesPointer => _hasMouseAim;

  void queue(GameAction a) {
    _pending.add(a);
    notifyListeners();
  }

  List<GameAction> drainActions() {
    if (_pending.isEmpty) return const [];
    final out = List<GameAction>.unmodifiable(_pending);
    _pending.clear();
    return out;
  }

  bool isDown(LogicalKeyboardKey k) => _keys.contains(k);

  /// Returns true when the event was consumed.
  bool handleKey(KeyEvent e) {
    final k = e.logicalKey;
    if (e is KeyDownEvent) {
      final repeat = _keys.contains(k);
      _keys.add(k);
      if (!repeat) _onPress(k);
      return true;
    }
    if (e is KeyUpEvent) {
      _keys.remove(k);
      return true;
    }
    return false;
  }

  void _onPress(LogicalKeyboardKey k) {
    if (k == LogicalKeyboardKey.space) queue(const GameAction(ActionType.jump));
    if (k == LogicalKeyboardKey.keyE)
      queue(const GameAction(ActionType.interact));
    if (k == LogicalKeyboardKey.keyR)
      queue(const GameAction(ActionType.reload));
    if (k == LogicalKeyboardKey.keyQ) toggleBuild();
    if (k == LogicalKeyboardKey.keyF) queue(const GameAction(ActionType.edit));
    if (k == LogicalKeyboardKey.keyG) queue(const GameAction(ActionType.drop));
    if (k == LogicalKeyboardKey.keyB) queue(const GameAction(ActionType.emote));
    if (k == LogicalKeyboardKey.keyT) queue(const GameAction(ActionType.thank));
    if (k == LogicalKeyboardKey.keyM) cycleMaterial();
    if (k == LogicalKeyboardKey.keyZ) selectPiece(Piece.wall);
    if (k == LogicalKeyboardKey.keyX) selectPiece(Piece.floor);
    if (k == LogicalKeyboardKey.keyC) selectPiece(Piece.ramp);
    if (k == LogicalKeyboardKey.keyV) selectPiece(Piece.roof);
    if (k == LogicalKeyboardKey.tab)
      queue(const GameAction(ActionType.spectateNext));
    for (var i = 1; i <= 6; i++) {
      if (k == LogicalKeyboardKey(0x30 + i)) selectSlot(i - 1);
    }
  }

  void selectSlot(int slot) {
    if (buildModeLocal) {
      buildModeLocal = false;
      queue(const GameAction(ActionType.buildMode, value: 'off'));
    }
    queue(GameAction(ActionType.select, slot: slot));
  }

  void selectPiece(Piece p) {
    if (!buildModeLocal) {
      buildModeLocal = true;
      queue(const GameAction(ActionType.buildMode, value: 'on'));
    }
    queue(GameAction(ActionType.setPiece, value: p.name));
  }

  void toggleBuild() {
    buildModeLocal = !buildModeLocal;
    queue(
      GameAction(ActionType.buildMode, value: buildModeLocal ? 'on' : 'off'),
    );
  }

  void setMaterial(Material m) =>
      queue(GameAction(ActionType.setMaterial, value: m.name));

  /// Mirrors the local player's build material so the key cycle knows where
  /// it is; the game loop keeps it in sync.
  Material currentMaterial = Material.wood;

  void cycleMaterial() {
    final next =
        Material.values[(currentMaterial.index + 1) % Material.values.length];
    currentMaterial = next;
    setMaterial(next);
  }

  /// Fire in build mode places a piece; otherwise it shoots / swings.
  bool get fire => mouseFire || stickFire;

  bool get sprint =>
      touchSprint ||
      _keys.contains(LogicalKeyboardKey.shiftLeft) ||
      _keys.contains(LogicalKeyboardKey.shiftRight);

  ({double x, double y}) get move {
    var x = stickMoveX;
    var y = stickMoveY;
    if (x == 0 && y == 0) {
      if (_keys.contains(LogicalKeyboardKey.keyA) ||
          _keys.contains(LogicalKeyboardKey.arrowLeft))
        x -= 1;
      if (_keys.contains(LogicalKeyboardKey.keyD) ||
          _keys.contains(LogicalKeyboardKey.arrowRight))
        x += 1;
      if (_keys.contains(LogicalKeyboardKey.keyW) ||
          _keys.contains(LogicalKeyboardKey.arrowUp))
        y -= 1;
      if (_keys.contains(LogicalKeyboardKey.keyS) ||
          _keys.contains(LogicalKeyboardKey.arrowDown))
        y += 1;
    }
    final len = math.sqrt(x * x + y * y);
    if (len > 1) {
      x /= len;
      y /= len;
    }
    return (x: x, y: y);
  }

  /// Updates [aim] from the active pointing device. [pointerWorld] is the
  /// pointer's world position (if any) and (px,py) the local player position.
  void updateAim({
    required double px,
    required double py,
    ({double x, double y})? pointerWorld,
  }) {
    if (stickAimX != 0 || stickAimY != 0) {
      aim = math.atan2(stickAimY, stickAimX);
      _hasMouseAim = false;
      return;
    }
    if (pointerWorld != null) {
      final dx = pointerWorld.x - px;
      final dy = pointerWorld.y - py;
      if (dx.abs() + dy.abs() > 0.01) aim = math.atan2(dy, dx);
      _hasMouseAim = true;
      return;
    }
    final m = move;
    if (m.x != 0 || m.y != 0) aim = math.atan2(m.y, m.x);
  }

  void releaseAll() {
    _keys.clear();
    stickMoveX = stickMoveY = stickAimX = stickAimY = 0;
    stickFire = false;
    mouseFire = false;
    touchSprint = false;
  }
}
