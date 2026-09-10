import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import 'app_state.dart';
import 'game/game_controller.dart';
import 'game/renderer.dart';
import 'net/game_client.dart';
import 'ui/game_screen.dart';
import 'ui/home_screen.dart';
import 'ui/lobby_screen.dart';
import 'ui/results_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

/// Owns the network client and render assets and routes between the
/// home, lobby, gameplay and results screens.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.settings, required this.config});
  final Settings settings;
  final LaunchConfig config;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final GameClient client;
  RenderAssets? assets;
  Object? assetError;
  GameController? game;
  RoomSession? _gameSession;
  bool _autoJoined = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings, c = widget.config;
    client = GameClient(platform: c.platform);
    client.serverUrl = s.serverUrl.isNotEmpty && c.autoName == null ? s.serverUrl : c.defaultServer;
    client.playerName = c.autoName ?? (s.playerName.isNotEmpty ? s.playerName : _defaultName(c.platform));
    client.driveHandler = _drive;
    client.addListener(_onClient);
    RenderAssets.load().then((a) => setState(() => assets = a), onError: (Object e) => setState(() => assetError = e));
    if (c.autoName != null || c.autoJoin != null) {
      client.connect();
    }
  }

  static String _defaultName(String platform) => switch (platform) {
    'web' => 'Web Wanderer',
    'ios' => 'Pocket Pioneer',
    'android' => 'Droid Delver',
    'macos' => 'Desk Dweller',
    _ => 'Wanderer',
  };

  void _onClient() {
    final s = client.session;
    if (s != null && s != _gameSession) {
      game?.dispose();
      game = null;
      _gameSession = s;
    }
    if (s == null && _gameSession != null) {
      game?.dispose();
      game = null;
      _gameSession = null;
    }
    final a = assets;
    if (s != null && a != null && s.phase != Phase.lobby && game == null) {
      game = GameController(client, s, a);
      _applySettings(game!);
    }
    if (!_autoJoined && client.state == ConnState.connected && client.session == null) {
      final code = widget.config.autoJoin;
      if (code != null && code.isNotEmpty) {
        _autoJoined = true;
        client.joinRoom(code);
      } else if (widget.config.autoCreate) {
        _autoJoined = true;
        client.createRoom(name: '${client.playerName}\'s world', mode: GameMode.survival);
      }
    }
    if (mounted) setState(() {});
  }

  void _applySettings(GameController g) {
    final s = widget.settings;
    g.lookSensitivity = 0.0022 * s.sensitivity;
    g.invertY = s.invertY;
    g.camera.fovDeg = s.fov;
  }

  @override
  void dispose() {
    client.removeListener(_onClient);
    game?.dispose();
    client.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- drive (automation)

  String get screenName {
    final s = client.session;
    if (s == null) return 'home';
    return s.phase;
  }

  Future<Map<String, Object?>> _drive(Map<String, Object?> a) async {
    final t = jstr(a, 't');
    switch (t) {
      case 'screen':
        return {
          'ok': true,
          'screen': screenName,
          'connected': client.state == ConnState.connected,
          'name': client.playerName,
          'autoName': widget.config.autoName,
          'server': client.serverUrl,
        };
      case 'wait_screen':
        final want = jstr(a, 'screen');
        final deadline = DateTime.now().add(Duration(seconds: jint(a, 'timeout', 20)));
        while (screenName != want && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return {'ok': screenName == want, 'screen': screenName};
      case 'create_room':
        client.createRoom(
          name: jstr(a, 'name', '${client.playerName}\'s world'),
          mode: jstr(a, 'mode', GameMode.survival),
          seed: a.containsKey('seed') ? jint(a, 'seed') : null,
          code: a.containsKey('code') ? jstr(a, 'code') : null,
          bots: jint(a, 'bots'),
          freezeTime: jbool(a, 'freezeTime'),
          spawnMobs: jbool(a, 'spawnMobs', true),
          durationTicks: jint(a, 'durationTicks'),
          startTime: jint(a, 'startTime', 1000),
        );
        return {'ok': true};
      case 'join_room':
        client.joinRoom(jstr(a, 'code'));
        return {'ok': true};
      case 'leave_room':
        client.leaveRoom();
        return {'ok': true};
      case 'ready':
        client.send({'t': 'ready', 'ready': jbool(a, 'on', true)});
        return {'ok': true};
      case 'start_match':
        client.send({'t': Msg.startMatch});
        return {'ok': true};
      case 'end_match':
        client.send({'t': Msg.endMatch});
        return {'ok': true};
      case 'back_to_lobby':
        client.send({'t': Msg.backToLobby});
        return {'ok': true};
      case 'set_theme':
        widget.settings.themeMode = switch (jstr(a, 'mode')) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return {'ok': true};
      case 'set_touch':
        widget.settings.touchControls = jbool(a, 'on', true);
        return {'ok': true};
      case 'results':
        final s = client.session;
        return {
          'ok': s != null && s.phase == Phase.results,
          'phase': screenName,
          'worldHash': s?.resultsWorldHash,
          'chatHash': s?.resultsChatHash,
          'results': [
            for (final r in s?.results ?? const <PlayerInfo>[])
              {
                'name': r.name,
                'platform': r.platform,
                'bot': r.bot,
                'score': r.score,
                'placed': r.placed,
                'broken': r.broken,
                'crafted': r.crafted,
                'kills': r.kills,
                'deaths': r.deaths,
              },
          ],
        };
      case 'chat_log':
        final s = client.session;
        return {
          'ok': s != null,
          'chatHash': s?.chatHash(),
          'chat': [
            for (final c in s?.chat ?? const <ChatEntry>[]) {'from': c.from, 'text': c.text},
          ],
        };
      case 'wait_game':
        final deadline = DateTime.now().add(Duration(seconds: jint(a, 'timeout', 20)));
        while (game == null && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        final g = game;
        if (g == null) return {'ok': false, 'error': 'game not started'};
        return g.drive({'t': 'wait_ready'});
      default:
        final g = game;
        if (g == null) return {'ok': false, 'error': 'not in a match (screen=$screenName)'};
        return g.drive(a);
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final s = client.session;
    final a = assets;
    Widget child;
    String key;
    if (assetError != null) {
      key = 'error';
      child = Scaffold(
        body: Center(
          child: StateBlock(
            icon: Icons.broken_image_outlined,
            title: 'Could not load renderer',
            message: '$assetError',
          ),
        ),
      );
    } else if (s == null) {
      key = 'home';
      child = HomeScreen(client: client, settings: widget.settings, config: widget.config, assets: a);
    } else if (s.phase == Phase.lobby || a == null) {
      key = 'lobby';
      child = LobbyScreen(client: client, session: s, settings: widget.settings, assets: a);
    } else if (s.phase == Phase.results && game != null) {
      key = 'results';
      child = ResultsScreen(client: client, game: game!, settings: widget.settings, assets: a);
    } else if (game != null) {
      key = 'game';
      child = GameScreen(client: client, game: game!, settings: widget.settings, assets: a);
    } else {
      key = 'loading';
      child = const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedSwitcher(
      duration: VhMotion.slow,
      switchInCurve: VhMotion.curve,
      switchOutCurve: VhMotion.curve,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 1.02, end: 1.0).animate(anim), child: child),
      ),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}
