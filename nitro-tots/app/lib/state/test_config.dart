import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Automation hooks for the cross-platform multiplayer test.
///
/// Values come from `--dart-define=NT_*` at build time, from `NT_*` process
/// environment variables on desktop and the iOS Simulator
/// (`SIMCTL_CHILD_NT_TEST=1`), or from URL query parameters on the web
/// (`?test=1&room=ABCD`). They are never persisted.
class TestConfig {
  const TestConfig({
    this.active = false,
    this.room,
    this.host = false,
    this.server,
    this.port,
    this.name,
    this.character,
    this.kart,
    this.lane,
    this.theme,
    this.laps,
    this.cup,
    this.mode,
    this.players,
    this.autoReady = true,
    this.screenshotLabel,
    this.screen,
    this.still = false,
  });

  final bool active;
  final String? room;

  /// This client creates the room and starts the match once [players] joined.
  final bool host;
  final String? server;
  final int? port;
  final String? name;
  final String? character;
  final String? kart;
  final double? lane;
  final String? theme;
  final int? laps;
  final String? cup;
  final String? mode;
  final int? players;
  final bool autoReady;
  final String? screenshotLabel;

  /// Opens this menu screen offline instead of joining a room (visual parity
  /// captures): `title`, `garage`, `track`, `settings` or `online`.
  final String? screen;

  /// Deterministic captures: freezes intro/idle animations, ignores persisted
  /// preferences and hides live numbers such as the connection latency.
  final bool still;

  static const _defActive = bool.fromEnvironment('NT_TEST');
  static const _defRoom = String.fromEnvironment('NT_ROOM');
  static const _defHost = bool.fromEnvironment('NT_HOST');
  static const _defServer = String.fromEnvironment('NT_SERVER');
  static const _defPort = String.fromEnvironment('NT_PORT');
  static const _defName = String.fromEnvironment('NT_NAME');
  static const _defCharacter = String.fromEnvironment('NT_CHARACTER');
  static const _defKart = String.fromEnvironment('NT_KART');
  static const _defLane = String.fromEnvironment('NT_LANE');
  static const _defTheme = String.fromEnvironment('NT_THEME');
  static const _defLaps = String.fromEnvironment('NT_LAPS');
  static const _defCup = String.fromEnvironment('NT_CUP');
  static const _defMode = String.fromEnvironment('NT_MODE');
  static const _defPlayers = String.fromEnvironment('NT_PLAYERS');
  static const _defScreen = String.fromEnvironment('NT_SCREEN');
  static const _defStill = bool.fromEnvironment('NT_STILL');

  static const _launchChannel = MethodChannel('nitrotots/launch');

  /// Runtime overrides for the current process: URL query parameters on the
  /// web, `NT_*` environment variables elsewhere (`NT_ROOM=ABCD` -> `room`).
  /// The iOS runner exposes its environment and `--NT_*` launch arguments over
  /// a method channel because the sandboxed process environment is not
  /// visible to Dart there.
  static Future<Map<String, String>> runtimeQuery() async {
    if (kIsWeb) return Uri.base.queryParameters;
    final raw = <String, String>{...Platform.environment};
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final fromRunner = await _launchChannel.invokeMapMethod<String, String>('config');
        if (fromRunner != null) raw.addAll(fromRunner);
      } on MissingPluginException {
        // Runner without the launch channel: environment only.
      }
    }
    return {
      for (final e in raw.entries)
        if (e.key.startsWith('NT_') && e.value.isNotEmpty) e.key.substring(3).toLowerCase(): e.value,
    };
  }

  /// Builds config from compile-time defines merged with runtime [query]
  /// parameters. Query values win.
  factory TestConfig.resolve(Map<String, String> query, String platformId) {
    String? pick(String key, String def) {
      final q = query[key];
      if (q != null && q.isNotEmpty) return q;
      return def.isEmpty ? null : def;
    }

    final active = query['test'] == '1' || _defActive;
    if (!active) return const TestConfig();
    final server = pick('server', _defServer);
    final port = pick('port', _defPort);
    final nameByPlatform = {'web': 'Web', 'ios': 'iOS', 'android': 'Android', 'macos': 'macOS'};
    final charByPlatform = {'web': 'juno', 'ios': 'mabel', 'android': 'ozzie', 'macos': 'bea'};
    final kartByPlatform = {'web': 'bubble', 'ios': 'pinewood', 'android': 'tincan', 'macos': 'rocketscoot'};
    final laneByPlatform = {'web': -9.0, 'ios': -3.0, 'android': 3.0, 'macos': 9.0};
    return TestConfig(
      active: true,
      room: pick('room', _defRoom),
      host: query['host'] == '1' || _defHost,
      server: server,
      port: port == null ? null : int.tryParse(port),
      name: pick('name', _defName) ?? nameByPlatform[platformId] ?? platformId,
      character: pick('character', _defCharacter) ?? charByPlatform[platformId],
      kart: pick('kart', _defKart) ?? kartByPlatform[platformId],
      lane: double.tryParse(pick('lane', _defLane) ?? '') ?? laneByPlatform[platformId] ?? 0,
      theme: pick('theme', _defTheme),
      laps: int.tryParse(pick('laps', _defLaps) ?? ''),
      cup: pick('cup', _defCup),
      mode: pick('mode', _defMode),
      players: int.tryParse(pick('players', _defPlayers) ?? ''),
      autoReady: query['ready'] != '0',
      screen: pick('screen', _defScreen),
      still: query['still'] == '1' || _defStill,
    );
  }

  /// Resolves the server URL: explicit override, or the platform default
  /// host with an overridden port.
  String? resolveServer(String fallback) {
    if (server != null) return server;
    if (port != null) {
      final u = Uri.parse(fallback);
      return u.replace(port: port).toString();
    }
    return null;
  }

  @override
  String toString() =>
      'TestConfig(active: $active, room: $room, host: $host, name: $name, lane: $lane, laps: $laps, players: $players, screen: $screen, still: $still)';

  static TestConfig none() => const TestConfig();

  static bool get isDebugDefine => kDebugMode && _defActive;
}
