import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      case 'drop_connection':
        final code = client.session?.code;
        final phase = client.session?.phase;
        await client.dropConnection();
        final dropped = client.state != ConnState.connected;
        final deadline = DateTime.now().add(Duration(seconds: jint(a, 'timeout', 30)));
        bool rejoined() =>
            client.state == ConnState.connected && !client.awaitingRejoin && client.session?.code == code;
        while (!rejoined() && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return {
          'ok': dropped && rejoined(),
          'dropped': dropped,
          'rejoined': rejoined(),
          'room': client.session?.code,
          'phase': client.session?.phase,
          'phaseBefore': phase,
          'state': client.state.name,
          'error': client.lastError,
        };
      case 'fixture':
        return _fixture(jstr(a, 'screen'));
      case 'layout':
        return _layout();
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

  /// Shows a screen populated from fixed synthetic data so every platform
  /// renders the identical state for cross-platform visual comparison.
  Future<Map<String, Object?>> _fixture(String screen) async {
    if (client.session != null) {
      client.leaveRoom();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    client.playerName = 'Hearthling';
    if (screen == 'home') {
      client.showFixture(null);
      return {'ok': true, 'screen': 'home'};
    }
    if (screen != 'lobby' && screen != 'results') {
      return {'ok': false, 'error': 'unknown fixture $screen'};
    }
    PlayerInfo info(String id, String name, String platform, int score, int placed, int broken, {bool bot = false}) =>
        PlayerInfo.fromJson({
          'id': id,
          'name': name,
          'platform': platform,
          'bot': bot,
          'connected': true,
          'ready': true,
          'score': score,
          'placed': placed,
          'broken': broken,
          'crafted': 0,
          'kills': 0,
          'deaths': 0,
        });
    final roster = [
      info('fx-1', 'Hearthling', 'web', 9, 7, 2),
      info('fx-2', 'Pocket Pioneer', 'ios', 6, 4, 2),
      info('fx-3', 'Droid Delver', 'android', 5, 3, 2),
      info('fx-4', 'Desk Dweller', 'macos', 8, 6, 2),
      info('fx-5', 'Ember Bot', 'server', 3, 3, 0, bot: true),
    ];
    final s = RoomSession(1234)
      ..code = 'FIXTR'
      ..roomName = 'Fixture world'
      ..mode = GameMode.survival
      ..hostId = 'fx-1'
      ..youId = 'fx-1'
      ..time = 6000
      ..tick = 2400
      ..durationTicks = 6000
      ..matchEndTick = 6000
      ..roster = roster;
    final t0 = DateTime(2026, 1, 1);
    s.chat
      ..add(ChatEntry(10, 'system', 'Hearthling created the world.', true, t0))
      ..add(ChatEntry(400, 'Pocket Pioneer', 'hello from the pocket', false, t0))
      ..add(ChatEntry(410, 'Desk Dweller', 'hearth is warm', false, t0));
    if (screen == 'results') {
      s
        ..phase = Phase.results
        ..results = (roster.toList()..sort((a, b) => b.score.compareTo(a.score)))
        ..resultsWorldHash = 'f1x7ur3d'
        ..resultsChatHash = 'c4a7f1x7';
    }
    client.showFixture(s);
    await Future<void>.delayed(VhMotion.slow);
    return {'ok': true, 'screen': screen};
  }

  /// Logical-pixel boxes of every laid-out text and icon glyph, independent
  /// of the platform rasterizer, for layout parity comparisons.
  Map<String, Object?> _layout() {
    final out = <Map<String, Object?>>[];
    void visit(Element e) {
      final r = e.renderObject;
      if (r is RenderParagraph && r.attached && r.hasSize) {
        final o = r.localToGlobal(Offset.zero);
        out.add({
          'text': r.text.toPlainText(),
          'x': o.dx.round(),
          'y': o.dy.round(),
          'w': r.size.width.round(),
          'h': r.size.height.round(),
        });
      }
      e.visitChildElements(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root != null) visit(root);
    final view = View.of(context);
    return {
      'ok': true,
      'screen': screenName,
      'viewport': [
        (view.physicalSize.width / view.devicePixelRatio).round(),
        (view.physicalSize.height / view.devicePixelRatio).round(),
      ],
      'dpr': view.devicePixelRatio,
      'nodes': out,
    };
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
