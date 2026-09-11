import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

/// Client configuration, resolved in this order:
///
/// 1. web query string (`?server=…&room=…&name=…&level=…&auto=1`)
/// 2. launch parameters (`PP_SERVER`, `PP_ROOM`, …): the process environment on
///    macOS, `SIMCTL_CHILD_*` environment / launch arguments on the iOS
///    Simulator (read natively, since dart:io sees no environment on iOS) and
///    `am start --es PP_ROOM …` intent extras on Android
/// 3. build-time `--dart-define` with the same names
/// 4. platform defaults
///
/// The automated cross-platform test uses these to make every client connect
/// and join the shared room without any manual input.
abstract final class AppConfig {
  static const _server = String.fromEnvironment('PP_SERVER');
  static const _room = String.fromEnvironment('PP_ROOM');
  static const _name = String.fromEnvironment('PP_NAME');
  static const _level = String.fromEnvironment('PP_LEVEL');
  static const _auto = String.fromEnvironment('PP_AUTO');

  static const _launchChannel = MethodChannel('panic_pantry/launch');
  static Map<String, String> _launch = const {};

  static Map<String, String> get _query => kIsWeb ? Uri.base.queryParameters : const {};

  static Map<String, String> get _env => kIsWeb ? const {} : Platform.environment;

  /// Loads native launch parameters (iOS/Android). Must run before `runApp`.
  static Future<void> load() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final raw = await _launchChannel.invokeMapMethod<String, String>('config');
      _launch = Map.unmodifiable(raw ?? const <String, String>{});
    } on MissingPluginException {
      _launch = const {};
    }
  }

  static String _get(String key, String define) {
    final q = _query[key.toLowerCase()];
    if (q != null && q.isNotEmpty) return q;
    final name = 'PP_${key.toUpperCase()}';
    final l = _launch[name];
    if (l != null && l.isNotEmpty) return l;
    final e = _env[name];
    if (e != null && e.isNotEmpty) return e;
    return define;
  }

  static String get platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  static String get platformLabel => switch (platform) {
    'web' => 'Web',
    'ios' => 'iOS',
    'android' => 'Android',
    'macos' => 'macOS',
    final p => p,
  };

  static bool get isTouch =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  static String get serverUrl {
    final v = _get('server', _server);
    if (v.isNotEmpty) return v;
    // The Android emulator reaches the host machine through 10.0.2.2.
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';
    return 'ws://$host:$kDefaultPort/ws';
  }

  static String get name {
    final v = _get('name', _name);
    if (v.isNotEmpty) return v;
    return switch (platform) {
      'web' => 'Webby',
      'ios' => 'Pip',
      'android' => 'Andi',
      'macos' => 'Mac',
      _ => 'Chef',
    };
  }

  static String? get roomCode {
    final v = _get('room', _room);
    return v.isEmpty ? null : v.toUpperCase();
  }

  static String? get levelId {
    final v = _get('level', _level);
    return v.isEmpty ? null : v;
  }

  static bool get autoJoin {
    final v = _get('auto', _auto);
    return v == '1' || v == 'true';
  }
}
