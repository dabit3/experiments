import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import 'audio.dart';

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

  bool get sound => _prefs.getBool('sound') ?? true;
  set sound(bool v) {
    _prefs.setBool('sound', v);
    Sfx.enabled = v;
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

  /// Compile-time `--dart-define` values can be overridden at launch by
  /// process environment variables (macOS binary) or by the host launch
  /// channel (iOS `SIMCTL_CHILD_VH_*` / `-VH_KEY value` arguments, Android
  /// intent extras), which the automation harness uses.
  static String _env(String key, String compiled, Map<String, String> overrides) {
    final o = overrides[key];
    if (o != null && o.isNotEmpty) return o;
    if (!kIsWeb) {
      final v = io.Platform.environment[key];
      if (v != null && v.isNotEmpty) return v;
    }
    return compiled;
  }

  static bool _flag(String v) => v == '1' || v == 'true';

  static const _channel = MethodChannel('voxelhearth/launch');

  /// `VH_*` overrides supplied by the native host at launch, if it has any.
  static Future<Map<String, String>> hostOverrides() async {
    if (kIsWeb) return const {};
    try {
      final m = await _channel.invokeMapMethod<String, String>('overrides');
      return m ?? const {};
    } on MissingPluginException {
      return const {};
    }
  }

  static LaunchConfig detect({Map<String, String> query = const {}, Map<String, String> overrides = const {}}) {
    final envServer = _env('VH_SERVER', _envServer, overrides);
    final envName = _env('VH_NAME', _envName, overrides);
    final envJoin = _env('VH_JOIN', _envJoin, overrides);
    final envTest = _flag(_env('VH_TEST', '', overrides)) || _envTest;
    final envCreate = _flag(_env('VH_CREATE', '', overrides)) || _envCreate;
    final platform = kIsWeb
        ? Platform.web
        : switch (defaultTargetPlatform) {
            TargetPlatform.iOS => Platform.ios,
            TargetPlatform.android => Platform.android,
            TargetPlatform.macOS => Platform.macos,
            _ => Platform.unknown,
          };
    var server = query['server'] ?? envServer;
    if (server.isEmpty) {
      // Android emulators reach the host through 10.0.2.2.
      final host = platform == Platform.android ? '10.0.2.2' : 'localhost';
      server = 'ws://$host:8787/ws';
    }
    return LaunchConfig(
      platform: platform,
      defaultServer: server,
      autoName: query['name'] ?? (envName.isEmpty ? null : envName),
      autoJoin: query['join'] ?? (envJoin.isEmpty ? null : envJoin),
      autoCreate: (query['create'] ?? '') == '1' || envCreate,
      testMode: (query['test'] ?? '') == '1' || envTest,
    );
  }
}
