import 'package:flutter/foundation.dart';

/// Launch configuration. Values come from `--dart-define` at build time and
/// may be overridden at launch: by URL query parameters on the web and by
/// `BRICKFOLK_*` environment variables on macOS, so the automated test can
/// point those clients at the same server and party without rebuilding. iOS
/// and Android see only the build-time defines (Dart's `Platform.environment`
/// is empty on iOS).
class AppConfig {
  const AppConfig({
    required this.serverUrl,
    required this.platformLabel,
    this.testMode = false,
    this.autoName,
    this.partyCode,
    this.isHost = false,
    this.expectedPlayers = 1,
    this.bots = 2,
    this.experience = 'obby',
    this.forceTheme,
    this.visualTour = false,
    this.frameIntervalMs = 0,
    this.phaseMarker = false,
    this.autoReady = true,
  });

  final String serverUrl;
  final String platformLabel;

  /// When true the client is driven by [TestDriver]: it signs in, joins the
  /// party, readies up, plays with the shared autopilot and reports results.
  final bool testMode;
  final String? autoName;
  final String? partyCode;
  final bool isHost;
  final int expectedPlayers;
  final int bots;
  final String experience;
  final String? forceTheme;

  /// Test-mode variant: sign in, then show hub screens on request from the
  /// harness (`test.control` `show`) so clients can be captured in identical
  /// states for the cross-platform visual comparison.
  final bool visualTour;

  /// Minimum milliseconds between rendered frames (0 = uncapped). Software-
  /// emulated devices cannot afford 60 fps, and gameplay stays server-driven
  /// regardless of how often the client paints.
  final int frameIntervalMs;

  /// Test-mode variant: paints a small solid block at the left edge whose
  /// colour encodes the screen state ([PhaseMarker]), so a harness reading a
  /// device display that trails the app can tell which state a grabbed frame
  /// shows.
  final bool phaseMarker;

  /// Test-mode: ready up as soon as the first lobby is shown. When false the
  /// harness sends `test.control` `ready` once it has captured the lobby.
  final bool autoReady;

  static const _defineServer = String.fromEnvironment('BRICKFOLK_SERVER');
  static const _defineTest = bool.fromEnvironment('BRICKFOLK_TEST');
  static const _defineName = String.fromEnvironment('BRICKFOLK_NAME');
  static const _defineParty = String.fromEnvironment('BRICKFOLK_PARTY');
  static const _defineHost = bool.fromEnvironment('BRICKFOLK_HOST');
  static const _definePlayers = int.fromEnvironment(
    'BRICKFOLK_PLAYERS',
    defaultValue: 1,
  );
  static const _defineBots = int.fromEnvironment(
    'BRICKFOLK_BOTS',
    defaultValue: 2,
  );
  static const _defineExperience = String.fromEnvironment(
    'BRICKFOLK_EXPERIENCE',
    defaultValue: 'obby',
  );
  static const _defineTheme = String.fromEnvironment('BRICKFOLK_THEME');
  static const _defineTour = bool.fromEnvironment('BRICKFOLK_TOUR');
  static const _defineFrameInterval = int.fromEnvironment(
    'BRICKFOLK_FRAME_INTERVAL_MS',
  );
  static const _defineMarker = bool.fromEnvironment('BRICKFOLK_PHASE_MARKER');
  static const _defineAutoReady = bool.fromEnvironment(
    'BRICKFOLK_AUTO_READY',
    defaultValue: true,
  );

  /// [query] holds launch overrides keyed without the `BRICKFOLK_` prefix in
  /// lower case (`server`, `test`, `name`, `party`, `host`, `players`, `bots`,
  /// `experience`, `theme`, `tour`, `frame`, `marker`, `autoready`).
  static AppConfig load(Map<String, String> query) {
    String? pick(String key, String define) {
      final q = query[key];
      if (q != null && q.isNotEmpty) return q;
      return define.isEmpty ? null : define;
    }

    bool flag(String key, bool define) {
      final q = query[key];
      if (q == null || q.isEmpty) return define;
      return q == '1' || q == 'true';
    }

    final tour = flag('tour', _defineTour);
    return AppConfig(
      serverUrl: pick('server', _defineServer) ?? defaultServer(),
      platformLabel: platformName(),
      testMode: tour || flag('test', _defineTest),
      autoName: pick('name', _defineName),
      partyCode: tour ? null : pick('party', _defineParty),
      isHost: flag('host', _defineHost),
      expectedPlayers: int.tryParse(query['players'] ?? '') ?? _definePlayers,
      bots: int.tryParse(query['bots'] ?? '') ?? _defineBots,
      experience: pick('experience', _defineExperience) ?? 'obby',
      forceTheme: pick('theme', _defineTheme),
      visualTour: tour,
      frameIntervalMs: frameInterval(query),
      phaseMarker: flag('marker', _defineMarker),
      autoReady: flag('autoready', _defineAutoReady),
    );
  }

  /// Resolved before the widget binding exists, so it is separate from [load].
  static int frameInterval(Map<String, String> query) =>
      (int.tryParse(query['frame'] ?? '') ?? _defineFrameInterval).clamp(
        0,
        2000,
      );

  static String platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  static String defaultServer() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // The Android emulator reaches the host machine through 10.0.2.2.
      return 'ws://10.0.2.2:8080/ws';
    }
    return 'ws://localhost:8080/ws';
  }
}
