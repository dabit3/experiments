import 'package:flutter/foundation.dart';

/// Launch configuration. Values come from `--dart-define` at build time and,
/// on the web, from URL query parameters (`?server=...&room=...&auto=1`).
/// The automated multiplayer test uses these to point every client at the
/// same server and room without touching the UI.
class AppConfig {
  AppConfig._({
    required this.serverUrl,
    required this.platformName,
    required this.playerName,
    required this.roomCode,
    required this.auto,
    required this.autoStartPlayers,
    required this.seed,
    required this.fast,
    required this.mode,
    required this.themeMode,
    required this.testId,
  });

  final String serverUrl;
  final String platformName;
  final String? playerName;
  final String? roomCode;

  /// Test mode: join [roomCode] immediately, enable server-side autopilot and
  /// report the final summary back to the server.
  final bool auto;

  /// When > 0 and this client is the host, start the match (filling with bots)
  /// once this many humans are in the room.
  final int autoStartPlayers;
  final int? seed;
  final bool fast;
  final String mode;
  final String themeMode;
  final String testId;

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._load();

  static String detectPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.windows => 'windows',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  static String defaultServer(String platform) {
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://$host:8787/ws';
    }
    if (platform == 'android') return 'ws://10.0.2.2:8787/ws';
    return 'ws://localhost:8787/ws';
  }

  static AppConfig _load() {
    final platform = detectPlatform();
    final q = kIsWeb ? Uri.base.queryParameters : const <String, String>{};
    String pick(String key, String define) {
      final fromQuery = q[key];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
      return define;
    }

    final server = pick(
      'server',
      const String.fromEnvironment('LASTFORT_SERVER'),
    );
    final name = pick('name', const String.fromEnvironment('LASTFORT_NAME'));
    final room = pick('room', const String.fromEnvironment('LASTFORT_ROOM'));
    final auto = pick('auto', const String.fromEnvironment('LASTFORT_AUTO'));
    final autoStart = pick(
      'autostart',
      const String.fromEnvironment('LASTFORT_AUTOSTART'),
    );
    final seed = pick('seed', const String.fromEnvironment('LASTFORT_SEED'));
    final fast = pick('fast', const String.fromEnvironment('LASTFORT_FAST'));
    final mode = pick('mode', const String.fromEnvironment('LASTFORT_MODE'));
    final theme = pick('theme', const String.fromEnvironment('LASTFORT_THEME'));
    final testId = pick('test', const String.fromEnvironment('LASTFORT_TEST'));
    return AppConfig._(
      serverUrl: server.isEmpty ? defaultServer(platform) : server,
      platformName: platform,
      playerName: name.isEmpty ? null : name,
      roomCode: room.isEmpty ? null : room.toUpperCase(),
      auto: auto == '1' || auto == 'true',
      autoStartPlayers: int.tryParse(autoStart) ?? 0,
      seed: int.tryParse(seed),
      fast: fast == '1' || fast == 'true',
      mode: mode.isEmpty ? 'squads' : mode,
      themeMode: theme.isEmpty ? 'system' : theme,
      testId: testId,
    );
  }
}
