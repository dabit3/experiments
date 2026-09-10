import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'net/client.dart';

/// App-level preferences and the client instance.
class AppState extends ChangeNotifier {
  AppState(this.config, this.client, this._prefs)
    : themeMode = switch (config.forceTheme ?? _prefs.getString('theme')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      soundEnabled = _prefs.getBool('sound') ?? true,
      // Browsers refuse vibration before the first tap, so haptics are opt-in
      // on the web.
      hapticsEnabled = _prefs.getBool('haptics') ?? !kIsWeb;

  final AppConfig config;
  final BrickfolkClient client;
  final SharedPreferences _prefs;

  ThemeMode themeMode;
  bool soundEnabled;
  bool hapticsEnabled;

  final StreamController<String> _screenRequests = StreamController.broadcast();

  /// Hub screen ids (`hub`, `avatar`, `social`, `chat`, `profile`, `daily`)
  /// requested programmatically, e.g. by the test driver's visual tour.
  Stream<String> get screenRequests => _screenRequests.stream;

  void requestScreen(String id) => _screenRequests.add(id);

  static const _tokenKey = 'session.token';
  static const _nameKey = 'session.name';

  String? get savedToken => _prefs.getString(_tokenKey);
  String? get savedName => _prefs.getString(_nameKey);

  static Future<AppState> create(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final client = BrickfolkClient(
      serverUrl: config.serverUrl,
      platform: config.platformLabel,
    );
    final state = AppState(config, client, prefs);
    client.addListener(state._syncSession);
    return state;
  }

  void _syncSession() {
    final token = client.token;
    final name = client.me?.summary.name;
    if (token != null && token != savedToken) {
      _prefs.setString(_tokenKey, token);
    }
    if (name != null && name != savedName) {
      _prefs.setString(_nameKey, name);
    }
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    _prefs.setString('theme', mode.name);
    notifyListeners();
  }

  void setSound(bool on) {
    soundEnabled = on;
    _prefs.setBool('sound', on);
    notifyListeners();
  }

  void setHaptics(bool on) {
    hapticsEnabled = on;
    _prefs.setBool('haptics', on);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _prefs.remove(_tokenKey);
    client.signOut();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without subscribing; safe in initState/dispose/callbacks.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// Rebuilds when the client notifies.
class ClientScope extends InheritedNotifier<BrickfolkClient> {
  const ClientScope({
    super.key,
    required BrickfolkClient client,
    required super.child,
  }) : super(notifier: client);

  static BrickfolkClient of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClientScope>()!.notifier!;

  static BrickfolkClient read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ClientScope>()!.notifier!;
}
