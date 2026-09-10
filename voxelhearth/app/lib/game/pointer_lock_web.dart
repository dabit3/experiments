import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser Pointer Lock: while locked the cursor is hidden and confined and
/// look input arrives as `movementX/Y` deltas instead of positions.
class PointerLock {
  static const bool supported = true;
  static bool _installed = false;
  static bool _wasLocked = false;

  static bool get locked => web.document.pointerLockElement != null;
  static void Function(double dx, double dy)? onMove;
  static void Function()? onChange;

  static void _install() {
    if (_installed) return;
    _installed = true;
    web.document.addEventListener(
      'mousemove',
      (web.MouseEvent e) {
        if (locked) onMove?.call(e.movementX.toDouble(), e.movementY.toDouble());
      }.toJS,
    );
    web.document.addEventListener(
      'pointerlockchange',
      (web.Event _) {
        final now = locked;
        if (now != _wasLocked) {
          _wasLocked = now;
          onChange?.call();
        }
      }.toJS,
    );
  }

  static Future<void> request() async {
    _install();
    if (locked) return;
    web.document.documentElement?.requestPointerLock();
  }

  static void release() {
    if (locked) web.document.exitPointerLock();
  }
}
