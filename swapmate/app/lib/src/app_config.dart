import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'env_stub.dart' if (dart.library.io) 'env_io.dart';

/// Configuration, highest priority first: URL query (`?key=value`, web),
/// native launch arguments (`--SWAPMATE_*=` argv on iOS via `simctl launch`,
/// `-e SWAPMATE_*` intent extras on Android), process environment
/// (`SWAPMATE_*`, desktop), then `--dart-define`.
class AppConfig {
  AppConfig._({
    required this.serverUrl,
    required this.name,
    required this.testId,
    required this.autoConnect,
    required this.theme,
    required this.roomCode,
  });

  final String serverUrl;
  final String name;
  final String? testId;
  final bool autoConnect;

  /// `dark`, `light` or `system`.
  final String theme;

  /// Room to create/join immediately after connecting (test automation).
  final String? roomCode;

  static const _server = String.fromEnvironment('SWAPMATE_SERVER');
  static const _name = String.fromEnvironment('SWAPMATE_NAME');
  static const _testId = String.fromEnvironment('SWAPMATE_TEST_ID');
  static const _auto = String.fromEnvironment('SWAPMATE_AUTOCONNECT');
  static const _theme = String.fromEnvironment(
    'SWAPMATE_THEME',
    defaultValue: 'dark',
  );
  static const _room = String.fromEnvironment('SWAPMATE_ROOM');

  static String get platformName {
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

  static String get defaultServer {
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'wss' : 'ws';
      final host = base.host.isEmpty ? 'localhost' : base.host;
      // When served by the game server itself, reuse its port.
      final port = base.hasPort ? base.port : 8787;
      return '$scheme://$host:$port/ws';
    }
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:8787/ws';
    }
    return 'ws://localhost:8787/ws';
  }

  static String get defaultName => switch (platformName) {
    'web' => 'Web player',
    'ios' => 'iPhone player',
    'android' => 'Android player',
    'macos' => 'Mac player',
    _ => 'Player',
  };

  static const _launch = MethodChannel('swapmate/launch');

  /// `SWAPMATE_*` values handed over by the native host at launch time; empty
  /// on platforms without the channel (web) or hosts that do not implement it.
  static Future<Map<String, String>> _launchConfig() async {
    if (kIsWeb) return const {};
    try {
      final raw = await _launch.invokeMapMethod<String, String>('config');
      return raw ?? const {};
    } on MissingPluginException {
      return const {};
    } on PlatformException {
      return const {};
    }
  }

  static Future<AppConfig> load() async {
    final q = kIsWeb ? Uri.base.queryParameters : const <String, String>{};
    final env = {...processEnvironment(), ...await _launchConfig()};
    String pick(String key, String envKey, String define, String fallback) {
      final fromUrl = q[key];
      if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
      final fromEnv = env[envKey];
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
      return define.isNotEmpty ? define : fallback;
    }

    final testId = pick('testId', 'SWAPMATE_TEST_ID', _testId, '');
    final auto = pick('autoconnect', 'SWAPMATE_AUTOCONNECT', _auto, '');
    final room = pick('room', 'SWAPMATE_ROOM', _room, '');
    return AppConfig._(
      serverUrl: pick('server', 'SWAPMATE_SERVER', _server, defaultServer),
      name: pick('name', 'SWAPMATE_NAME', _name, defaultName),
      testId: testId.isEmpty ? null : testId,
      autoConnect: auto == '1' || auto == 'true' || testId.isNotEmpty,
      theme: pick('theme', 'SWAPMATE_THEME', _theme, 'dark'),
      roomCode: room.isEmpty ? null : room.toUpperCase(),
    );
  }
}
