import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import 'config.dart';
import 'net/client.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/results_screen.dart';
import 'theme/tokens.dart';
import 'widgets/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  await AppConfig.load();
  runApp(const PanicPantryApp());
}

class PanicPantryApp extends StatefulWidget {
  const PanicPantryApp({super.key});

  @override
  State<PanicPantryApp> createState() => _PanicPantryAppState();
}

class _PanicPantryAppState extends State<PanicPantryApp> {
  late final GameClient _client = GameClient(platform: AppConfig.platform);
  ThemeMode _mode = ThemeMode.system;
  bool _autoJoinAttempted = false;

  @override
  void initState() {
    super.initState();
    _client.addListener(_onClient);
    _client.commands.stream.listen(_onCommand);
    if (AppConfig.autoJoin) {
      _client.connect(AppConfig.serverUrl, withName: AppConfig.name);
    }
  }

  @override
  void dispose() {
    _client.removeListener(_onClient);
    _client.dispose();
    super.dispose();
  }

  void _onClient() {
    if (AppConfig.autoJoin &&
        !_autoJoinAttempted &&
        _client.conn == ConnState.connected &&
        _client.playerId != null &&
        _client.room == null) {
      _autoJoinAttempted = true;
      final code = AppConfig.roomCode;
      if (code != null) {
        _client.joinRoom(code);
      } else {
        _client.createRoom(level: AppConfig.levelId);
      }
    }
    setState(() {});
  }

  void _onCommand(Map<String, dynamic> cmd) {
    switch (cmd['cmd']) {
      case 'theme':
        setState(
          () => _mode = cmd['mode'] == 'dark'
              ? ThemeMode.dark
              : (cmd['mode'] == 'light' ? ThemeMode.light : ThemeMode.system),
        );
      case 'ready':
        _client.setReady(cmd['value'] != false);
      case 'join':
        _client.joinRoom(cmd['code'] as String);
      case 'leave':
        _client.leaveRoom();
      case 'rematch':
        _client.rematch();
    }
  }

  void _toggleTheme() {
    final dark =
        _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system && MediaQueryData.fromView(View.of(context)).platformBrightness == Brightness.dark);
    setState(() => _mode = dark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panic Pantry',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _mode,
      home: Builder(
        builder: (context) => ToastHost(
          stream: _client.toasts.stream,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: PPScheme.of(context).isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: AnimatedSwitcher(
              duration: PPMotion.slow,
              switchInCurve: PPMotion.emphasized,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: _screen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _screen() {
    final c = _client;
    if (c.room == null) {
      if (AppConfig.autoJoin &&
          (c.conn == ConnState.connecting ||
              c.conn == ConnState.reconnecting ||
              (c.conn == ConnState.connected && !_autoJoinAttempted))) {
        return const Scaffold(
          key: ValueKey('auto'),
          body: StatePanel(title: 'Joining kitchen…', message: 'Connecting to the server.', busy: true),
        );
      }
      return HomeScreen(key: const ValueKey('home'), client: c, onToggleTheme: _toggleTheme);
    }
    final g = c.game;
    if (c.results != null && (g == null || g.phase == Phase.finished || g.phase == Phase.lobby)) {
      return ResultsScreen(key: ValueKey('results-${c.resultsMatch}'), client: c);
    }
    if (g == null || g.phase == Phase.lobby) {
      return LobbyScreen(key: const ValueKey('lobby'), client: c, onToggleTheme: _toggleTheme);
    }
    return GameScreen(key: ValueKey('game-${c.room!.match}'), client: c, onToggleTheme: _toggleTheme);
  }
}
