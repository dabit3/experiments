import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

/// User preferences persisted across launches.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Settings> load() async => Settings._(await SharedPreferences.getInstance());

  ThemeMode get themeMode => ThemeMode.values[_prefs.getInt('theme') ?? 0];
  set themeMode(ThemeMode m) {
    _prefs.setInt('theme', m.index);
    notifyListeners();
  }

  String get playerName => _prefs.getString('name') ?? '';
  set playerName(String v) {
    _prefs.setString('name', v);
    notifyListeners();
  }

  String get serverUrl => _prefs.getString('server') ?? '';
  set serverUrl(String v) {
    _prefs.setString('server', v);
    notifyListeners();
  }

  double get sensitivity => _prefs.getDouble('sens') ?? 1.0;
  set sensitivity(double v) {
    _prefs.setDouble('sens', v);
    notifyListeners();
  }

  bool get invertY => _prefs.getBool('invertY') ?? false;
  set invertY(bool v) {
    _prefs.setBool('invertY', v);
    notifyListeners();
  }

  double get fov => _prefs.getDouble('fov') ?? 70;
  set fov(double v) {
    _prefs.setDouble('fov', v);
    notifyListeners();
  }

  bool get showFps => _prefs.getBool('fps') ?? false;
  set showFps(bool v) {
    _prefs.setBool('fps', v);
    notifyListeners();
  }

  bool get haptics => _prefs.getBool('haptics') ?? true;
  set haptics(bool v) {
    _prefs.setBool('haptics', v);
    notifyListeners();
  }

  int get renderQuality => _prefs.getInt('quality') ?? 1; // 0 low 1 auto 2 high
  set renderQuality(int v) {
    _prefs.setInt('quality', v);
    notifyListeners();
  }

  bool get touchControls => _prefs.getBool('touch') ?? defaultTouch;
  set touchControls(bool v) {
    _prefs.setBool('touch', v);
    notifyListeners();
  }

  static bool get defaultTouch =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
}

/// Launch-time configuration: platform label, default server, automation flags.
class LaunchConfig {
  LaunchConfig({
    required this.platform,
    required this.defaultServer,
    required this.autoName,
    required this.autoJoin,
    required this.autoCreate,
    required this.testMode,
  });

  final String platform;
  final String defaultServer;
  final String? autoName;
  final String? autoJoin;
  final bool autoCreate;
  final bool testMode;

  static const _envServer = String.fromEnvironment('VH_SERVER');
  static const _envName = String.fromEnvironment('VH_NAME');
  static const _envJoin = String.fromEnvironment('VH_JOIN');
  static const _envTest = bool.fromEnvironment('VH_TEST');
  static const _envCreate = bool.fromEnvironment('VH_CREATE');

  static LaunchConfig detect({Map<String, String> query = const {}}) {
    final platform = kIsWeb
        ? Platform.web
        : switch (defaultTargetPlatform) {
            TargetPlatform.iOS => Platform.ios,
            TargetPlatform.android => Platform.android,
            TargetPlatform.macOS => Platform.macos,
            _ => Platform.unknown,
          };
    var server = query['server'] ?? (_envServer.isEmpty ? '' : _envServer);
    if (server.isEmpty) {
      // Android emulators reach the host through 10.0.2.2.
      final host = platform == Platform.android ? '10.0.2.2' : 'localhost';
      server = 'ws://$host:8787/ws';
    }
    return LaunchConfig(
      platform: platform,
      defaultServer: server,
      autoName: query['name'] ?? (_envName.isEmpty ? null : _envName),
      autoJoin: query['join'] ?? (_envJoin.isEmpty ? null : _envJoin),
      autoCreate: (query['create'] ?? '') == '1' || _envCreate,
      testMode: (query['test'] ?? '') == '1' || _envTest,
    );
  }
}
