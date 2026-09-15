import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:swapmate_core/swapmate_core.dart';

import 'src/app_config.dart';
import 'src/net/game_client.dart';
import 'src/net/test_channel.dart';
import 'src/screens/game_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/lobby_screen.dart';
import 'src/screens/results_screen.dart';
import 'src/theme/theme.dart';
import 'src/theme/tokens.dart';
import 'src/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  debugPrint(
    'swapmate config server=${config.serverUrl} name=${config.name} '
    'testId=${config.testId} autoConnect=${config.autoConnect} '
    'room=${config.roomCode} theme=${config.theme}',
  );
  runApp(SwapmateApp(config: config));
}

class SwapmateApp extends StatefulWidget {
  const SwapmateApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<SwapmateApp> createState() => _SwapmateAppState();
}

class _SwapmateAppState extends State<SwapmateApp> {
  late final GameClient _client = GameClient(platform: AppConfig.platformName);
  late ThemeMode _mode = switch (widget.config.theme) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
  TestChannel? _test;
  bool _autoRoomDone = false;
  final _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _test = TestChannel(
      client: _client,
      setTheme: (m) => setState(
        () => _mode = m == 'light' ? ThemeMode.light : ThemeMode.dark,
      ),
      currentTheme: () => _mode.name,
      capture: _capture,
    );
    if (widget.config.autoConnect) {
      _connect(widget.config.name, widget.config.serverUrl);
      _client.addListener(_maybeAutoRoom);
    }
  }

  void _maybeAutoRoom() {
    final code = widget.config.roomCode;
    if (code == null || _autoRoomDone || !_client.isOnline) return;
    _autoRoomDone = true;
    _client.joinRoom(code);
  }

  /// Rasterizes the whole app (including overlays) at the view's device pixel
  /// ratio, so a test can capture what the client shows independently of the
  /// host's display pipeline.
  Future<ui.Image> _capture() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    return boundary.toImage(
      pixelRatio: MediaQuery.devicePixelRatioOf(_captureKey.currentContext!),
    );
  }

  Future<void> _connect(String name, String server) =>
      _client.connect(url: server, name: name, testId: widget.config.testId);

  void _toggleTheme() => setState(() {
    final dark =
        _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    _mode = dark ? ThemeMode.light : ThemeMode.dark;
  });

  @override
  void dispose() {
    _test?.dispose();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Swapmate',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: _mode,
    builder: (context, child) =>
        RepaintBoundary(key: _captureKey, child: child!),
    home: AnimatedBuilder(
      animation: _client,
      builder: (context, _) {
        final room = _client.room;
        final game = _client.game;
        Widget screen;
        String key;
        if (room == null) {
          key = 'home';
          screen = HomeScreen(
            client: _client,
            initialName: widget.config.name,
            initialServer: widget.config.serverUrl,
            onConnect: _connect,
            onToggleTheme: _toggleTheme,
          );
        } else if (room.phase == RoomPhase.lobby || game == null) {
          key = 'lobby';
          screen = LobbyScreen(client: _client, onToggleTheme: _toggleTheme);
        } else if (room.phase == RoomPhase.finished && game.isOver) {
          key = 'results';
          screen = ResultsScreen(client: _client, onToggleTheme: _toggleTheme);
        } else {
          key = 'game';
          screen = GameScreen(client: _client, onToggleTheme: _toggleTheme);
        }
        return Stack(
          children: [
            AnimatedSwitcher(
              duration: Motion.slow,
              switchInCurve: Motion.curve,
              switchOutCurve: Motion.curve,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.985, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(key), child: screen),
            ),
            if (_client.status == ConnectionStatus.reconnecting && room != null)
              const _ReconnectBanner(),
          ],
        );
      },
    ),
  );
}

class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      left: 0,
      right: 0,
      bottom: Space.lg,
      child: SafeArea(
        child: Center(
          child: Panel(
            raised: true,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            borderColor: c.warning.withValues(alpha: 0.6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.warning,
                  ),
                ),
                const SizedBox(width: Space.md),
                Text(
                  'Connection lost — reconnecting…',
                  style: context.type.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
