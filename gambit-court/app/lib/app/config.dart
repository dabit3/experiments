import 'package:flutter/foundation.dart';

/// Launch configuration. Values come from `--dart-define` at build time and,
/// on the web, may be overridden by URL query parameters so that a single
/// build can target several servers/identities during automated tests.
///
/// ```
/// flutter run --dart-define=GC_SERVER=ws://127.0.0.1:8765/ws \
///             --dart-define=GC_CLIENT_ID=ios-sim --dart-define=GC_NAME=Ada
/// ```
class AppConfig {
  AppConfig._({
    required this.serverUrl,
    required this.clientId,
    required this.name,
    required this.automation,
    required this.theme,
    required this.safeBottom,
    required this.platformLabel,
  });

  static const _server = String.fromEnvironment('GC_SERVER');
  static const _clientId = String.fromEnvironment('GC_CLIENT_ID');
  static const _name = String.fromEnvironment('GC_NAME');
  static const _automation = bool.fromEnvironment('GC_AUTOMATION');
  static const _theme = String.fromEnvironment('GC_THEME');
  static const _safeBottom = String.fromEnvironment('GC_SAFE_BOTTOM');

  final String serverUrl;

  /// Stable identity used by the server for reconnects. Empty means
  /// "generate and persist one".
  final String clientId;
  final String name;

  /// When true the client answers `ui_command` messages from the server's
  /// test-control bridge and disables a few non-deterministic flourishes
  /// (random side choice, ambient animations).
  final bool automation;

  /// `dark`, `light`, or empty for system.
  final String theme;

  /// Extra bottom safe-area inset in logical pixels, so a client without a
  /// system home indicator can lay out exactly like one that has it.
  final double safeBottom;
  final String platformLabel;

  static AppConfig load() {
    final params = kIsWeb ? Uri.base.queryParameters : const <String, String>{};
    String pick(String key, String fallback) =>
        (params[key]?.trim().isNotEmpty ?? false)
        ? params[key]!.trim()
        : fallback;
    return AppConfig._(
      serverUrl: pick('server', _server.isEmpty ? defaultServer() : _server),
      clientId: pick('client', _clientId),
      name: pick('name', _name),
      automation: params['automation'] == '1' || _automation,
      theme: pick('theme', _theme),
      safeBottom: double.tryParse(pick('safeBottom', _safeBottom)) ?? 0,
      platformLabel: platformName(),
    );
  }

  static String defaultServer() {
    if (kIsWeb) {
      final base = Uri.base;
      final scheme = base.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${base.host}:8765/ws';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // The Android emulator reaches the host machine via 10.0.2.2.
      return 'ws://10.0.2.2:8765/ws';
    }
    return 'ws://127.0.0.1:8765/ws';
  }

  static String platformName() {
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
}
