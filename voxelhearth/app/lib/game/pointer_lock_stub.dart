import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native pointer capture. macOS implements it in the Runner
/// (`voxelhearth/cursor`): the cursor is hidden and frozen and raw mouse
/// deltas stream back over the channel. Touch platforms report unsupported.
class PointerLock {
  static final bool supported = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  static const _channel = MethodChannel('voxelhearth/cursor');
  static bool _installed = false;
  static bool _locked = false;

  static bool get locked => _locked;
  static void Function(double dx, double dy)? onMove;
  static void Function()? onChange;

  static void _install() {
    if (_installed) return;
    _installed = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'move':
          final a = call.arguments;
          if (a is List && a.length == 2 && a[0] is num && a[1] is num) {
            onMove?.call((a[0] as num).toDouble(), (a[1] as num).toDouble());
          }
        case 'released':
          if (_locked) {
            _locked = false;
            onChange?.call();
          }
      }
      return null;
    });
  }

  static Future<void> request() async {
    if (!supported || _locked) return;
    _install();
    try {
      await _channel.invokeMethod<void>('capture');
    } on MissingPluginException {
      return;
    }
    _locked = true;
    onChange?.call();
  }

  static void release() {
    if (!_locked) return;
    _locked = false;
    _channel.invokeMethod<void>('release').catchError((Object _) {});
    onChange?.call();
  }
}
