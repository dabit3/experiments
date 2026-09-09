import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_config.dart';

enum ControlScheme { auto, touch, keyboard }

enum CameraMode { chase, north }

/// Persisted player profile + preferences.
class AppState extends ChangeNotifier {
  AppState(this._prefs, this.testConfig) {
    _load();
  }

  final SharedPreferences _prefs;
  final TestConfig testConfig;

  String name = 'Racer';
  String characterId = characters.first.id;
  String kartId = karts.first.id;
  String serverUrl = defaultServerUrl();
  ThemeMode themeMode = ThemeMode.system;
  ControlScheme controls = ControlScheme.auto;
  CameraMode camera = CameraMode.chase;
  bool autoAccelerate = true;
  bool haptics = true;
  bool reduceMotion = false;
  double musicVolume = 0.5;
  double sfxVolume = 0.8;
  String lastRoomCode = '';
  String? resumePlayerId;
  String? resumeToken;

  /// Best time-trial ghosts per track, serialized.
  final Map<String, Map<String, dynamic>> ghosts = {};

  static String defaultServerUrl() {
    if (kIsWeb) return 'ws://localhost:8787/ws';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator reaches the host machine via 10.0.2.2.
        return 'ws://10.0.2.2:8787/ws';
      default:
        return 'ws://localhost:8787/ws';
    }
  }

  static String get platformId {
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

  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

  bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  /// Whether on-screen touch controls should show for the current scheme.
  bool showTouchControls(BuildContext context) {
    switch (controls) {
      case ControlScheme.touch:
        return true;
      case ControlScheme.keyboard:
        return false;
      case ControlScheme.auto:
        if (isMobile) return true;
        if (isDesktop) return false;
        // Web: infer from pointer/screen size.
        final mq = MediaQuery.of(context);
        return mq.size.shortestSide < 700;
    }
  }

  Character get character => characters.firstWhere((c) => c.id == characterId, orElse: () => characters.first);
  Kart get kart => karts.firstWhere((k) => k.id == kartId, orElse: () => karts.first);

  void _load() {
    name = _prefs.getString('name') ?? name;
    characterId = _prefs.getString('character') ?? characterId;
    kartId = _prefs.getString('kart') ?? kartId;
    serverUrl = _prefs.getString('server') ?? serverUrl;
    themeMode = ThemeMode.values[_prefs.getInt('theme') ?? ThemeMode.system.index];
    controls = ControlScheme.values[_prefs.getInt('controls') ?? 0];
    camera = CameraMode.values[_prefs.getInt('camera') ?? 0];
    autoAccelerate = _prefs.getBool('autoAccel') ?? true;
    haptics = _prefs.getBool('haptics') ?? true;
    reduceMotion = _prefs.getBool('reduceMotion') ?? false;
    musicVolume = _prefs.getDouble('music') ?? 0.5;
    sfxVolume = _prefs.getDouble('sfx') ?? 0.8;
    lastRoomCode = _prefs.getString('lastRoom') ?? '';
    resumePlayerId = _prefs.getString('resumeId');
    resumeToken = _prefs.getString('resumeToken');
    final g = _prefs.getString('ghosts');
    if (g != null) {
      try {
        (jsonDecode(g) as Map<String, dynamic>).forEach((k, v) => ghosts[k] = (v as Map).cast<String, dynamic>());
      } catch (_) {}
    }

    // Test/automation overrides (never persisted).
    final t = testConfig;
    if (t.name != null) name = t.name!;
    if (t.character != null) characterId = t.character!;
    if (t.kart != null) kartId = t.kart!;
    serverUrl = t.resolveServer(serverUrl) ?? serverUrl;
    if (t.theme != null) themeMode = t.theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (t.active) {
      resumePlayerId = null;
      resumeToken = null;
      reduceMotion = false;
    }
  }

  Future<void> _save() async {
    await _prefs.setString('name', name);
    await _prefs.setString('character', characterId);
    await _prefs.setString('kart', kartId);
    await _prefs.setString('server', serverUrl);
    await _prefs.setInt('theme', themeMode.index);
    await _prefs.setInt('controls', controls.index);
    await _prefs.setInt('camera', camera.index);
    await _prefs.setBool('autoAccel', autoAccelerate);
    await _prefs.setBool('haptics', haptics);
    await _prefs.setBool('reduceMotion', reduceMotion);
    await _prefs.setDouble('music', musicVolume);
    await _prefs.setDouble('sfx', sfxVolume);
    await _prefs.setString('lastRoom', lastRoomCode);
    if (resumePlayerId != null) {
      await _prefs.setString('resumeId', resumePlayerId!);
      await _prefs.setString('resumeToken', resumeToken ?? '');
    } else {
      await _prefs.remove('resumeId');
      await _prefs.remove('resumeToken');
    }
    await _prefs.setString('ghosts', jsonEncode(ghosts));
  }

  void update(void Function(AppState s) fn) {
    fn(this);
    notifyListeners();
    if (!testConfig.active) _save();
  }

  void setResume(String? id, String? token) {
    resumePlayerId = id;
    resumeToken = token;
    if (!testConfig.active) _save();
  }

  void saveGhost(String trackId, Map<String, dynamic> ghost) {
    ghosts[trackId] = ghost;
    notifyListeners();
    if (!testConfig.active) _save();
  }
}
