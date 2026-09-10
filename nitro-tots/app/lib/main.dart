import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/session.dart';
import 'net/client.dart';
import 'screens/garage_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/online_screen.dart';
import 'screens/podium_screen.dart';
import 'screens/race_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/title_screen.dart';
import 'screens/track_screen.dart';
import 'state/app_state.dart';
import 'state/audio.dart';
import 'state/flow.dart';
import 'state/test_config.dart';
import 'theme/tokens.dart';
import 'widgets/nt_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  final prefs = await SharedPreferences.getInstance();
  final test = TestConfig.resolve(await TestConfig.runtimeQuery(), AppState.platformId);
  if (test.active) debugPrint('nitro-tots $test');
  final app = AppState(prefs, test);
  final feedback = NtFeedback(app);
  unawaited(feedback.preload());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent));
  runApp(NitroTotsApp(app: app, feedback: feedback));
}

class NitroTotsApp extends StatelessWidget {
  const NitroTotsApp({super.key, required this.app, required this.feedback});
  final AppState app;
  final NtFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => MaterialApp(
        title: 'Nitro Tots',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: app.themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: app.reduceMotion || MediaQuery.of(context).disableAnimations),
          child: child!,
        ),
        home: AppShell(app: app, feedback: feedback),
      ),
    );
  }
}

enum Screen { title, garage, track, settings, online, lobby, race, podium }

/// Top-level state machine. Screens are swapped with a shared transition so
/// every platform navigates identically (no platform-specific route stacks).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.app, required this.feedback});
  final AppState app;
  final NtFeedback feedback;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final GameFlow flow = GameFlow(widget.app);
  late final NetClient client = NetClient(platform: AppState.platformId);
  Screen screen = Screen.title;
  Screen _garageReturn = Screen.title;
  bool _forward = true;
  MatchOutcome? _netOutcome;
  StreamSubscription<Map<String, dynamic>>? _eventsSub;
  Timer? _testTimer;
  bool _testReportedMatch = false;
  String? _lastTestPhase;
  int _lastStartRequestMs = 0;
  int? _lobbyEnteredMs;

  AppState get app => widget.app;
  NtFeedback get feedback => widget.feedback;
  TestConfig get test => app.testConfig;

  @override
  void initState() {
    super.initState();
    client.onCredentials = (id, token) => app.setResume(id.isEmpty ? null : id, token.isEmpty ? null : token);
    client.addListener(_onClient);
    client.matchOutcome.addListener(_onMatchOver);
    _eventsSub = client.events.listen(_onServerEvent);
    if (test.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTestFlow());
    } else {
      feedback.music('music_menu');
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _testTimer?.cancel();
    client.removeListener(_onClient);
    client.matchOutcome.removeListener(_onMatchOver);
    client.dispose();
    flow.dispose();
    super.dispose();
  }

  void _go(Screen s, {bool forward = true}) {
    if (!mounted) return;
    setState(() {
      _forward = forward;
      screen = s;
    });
  }

  // Online transitions --------------------------------------------------------

  void _onClient() {
    final room = client.room;
    if (screen == Screen.online && room != null) {
      _go(Screen.lobby);
    } else if (screen == Screen.lobby && room == null && client.state == ConnState.online) {
      _go(Screen.online, forward: false);
    }
    if (client.session != null && screen == Screen.lobby) {
      _go(Screen.race);
    }
    if (test.active && test.screen == null) _driveTest();
  }

  void _onServerEvent(Map<String, dynamic> m) {
    if (m['type'] == Msg.matchStart && (screen == Screen.lobby || screen == Screen.podium || screen == Screen.race)) {
      _netOutcome = null;
      _go(Screen.race);
    }
  }

  void _onMatchOver() {
    final o = client.matchOutcome.value;
    if (o == null) return;
    _netOutcome = o;
    _go(Screen.podium);
    if (test.active && !_testReportedMatch) {
      _testReportedMatch = true;
      _lastTestPhase = 'matchOver';
      client.testReport({
        'phase': 'matchOver',
        'hash': o.hash,
        'standings': [for (final s in o.standings) s.toJson()],
        'platform': AppState.platformId,
      });
    }
  }

  void _leaveOnline() {
    client.leaveRoom();
    _netOutcome = null;
    feedback.music('music_menu');
    _go(Screen.online, forward: false);
  }

  // Offline transitions -------------------------------------------------------

  void _startOffline() {
    flow.startSeries();
    _go(Screen.race);
  }

  void _afterOfflineRace() {
    final s = flow.session;
    if (s == null) return;
    final results = s.results.value;
    if (results != null) flow.recordResults(results);
    if (flow.mode == PlayMode.timeTrial || flow.mode == PlayMode.battle || flow.mode == PlayMode.quickRace) {
      _go(Screen.podium);
      return;
    }
    if (flow.isLastRace) {
      _go(Screen.podium);
    } else {
      flow.nextRace();
      _go(Screen.race);
    }
  }

  void _quitOffline() {
    flow.endSeries();
    feedback.music('music_menu');
    _go(Screen.title, forward: false);
  }

  // Automated test flow -------------------------------------------------------

  Future<void> _startTestFlow() async {
    final still = Screen.values.where((s) => s.name == test.screen).firstOrNull;
    if (still != null) {
      _go(still);
      return;
    }
    _go(Screen.online);
    await client.connect(app.serverUrl, name: app.name, character: app.characterId, kart: app.kartId);
    _testTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _driveTest());
  }

  void _driveTest() {
    if (client.state != ConnState.online) return;
    final room = client.room;
    final code = test.room ?? 'TEST';
    if (room == null) {
      if (screen == Screen.online) {
        client.createRoom(
          RoomSettings(
            mode: test.mode == 'battle' ? GameMode.battle : GameMode.race,
            grandPrix: test.mode != 'race' && test.mode != 'battle',
            cupId: test.cup ?? 'sugar',
            trackId: test.mode == 'battle' ? arenaDefs.first.id : raceTrackDefs.first.id,
            laps: test.laps ?? 1,
            minPlayers: test.players ?? 4,
          ),
          code: code,
        );
      }
      return;
    }
    final me = room.players.where((p) => p.id == client.playerId).firstOrNull;
    if (me == null) return;
    final phase = switch (screen) {
      Screen.lobby => 'lobby',
      Screen.race => client.session?.sim.phase.name ?? 'race',
      Screen.podium => 'matchOver',
      _ => screen.name,
    };
    if (phase != _lastTestPhase) {
      _lastTestPhase = phase;
      client.testReport({'phase': phase, 'platform': AppState.platformId, 'screen': screen.name});
    }
    if (room.status != 'lobby' || client.session != null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _lobbyEnteredMs ??= nowMs;
    // Linger in the lobby briefly so every client renders (and captures) it.
    if (test.autoReady && !me.ready && nowMs - _lobbyEnteredMs! >= 3000) client.setReady(true);
    if (client.isHost && nowMs - _lastStartRequestMs > 2000 && room.players.length >= (test.players ?? 4) && room.players.every((p) => p.ready)) {
      _lastStartRequestMs = nowMs;
      client.startMatch();
    }
  }

  // Build ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: ValueKey('$screen-${flow.raceIndex}-${client.session.hashCode}'), child: _buildScreen());
    final reduce = MediaQuery.of(context).disableAnimations;
    return PageTransitionSwitcher(forward: _forward, duration: reduce ? Duration.zero : NtMotion.normal, child: child);
  }

  Widget _buildScreen() {
    switch (screen) {
      case Screen.title:
        return TitleScreen(
          app: app,
          onPlay: (mode) {
            feedback.tap();
            if (mode == PlayMode.online) {
              _go(Screen.online);
            } else {
              flow.choose(mode);
              _go(Screen.track);
            }
          },
          onSettings: () {
            feedback.tap();
            _go(Screen.settings);
          },
          onGarage: () {
            feedback.tap();
            _garageReturn = Screen.title;
            _go(Screen.garage);
          },
        );
      case Screen.garage:
        return GarageScreen(
          app: app,
          feedback: feedback,
          onBack: () => _go(_garageReturn, forward: false),
          onDone: () {
            if (client.state == ConnState.online) {
              client.updateProfile(name: app.name, character: app.characterId, kart: app.kartId);
            }
            _go(_garageReturn, forward: false);
          },
        );
      case Screen.settings:
        return SettingsScreen(app: app, feedback: feedback, onBack: () => _go(Screen.title, forward: false));
      case Screen.track:
        return TrackScreen(flow: flow, feedback: feedback, onBack: () => _go(Screen.title, forward: false), onStart: _startOffline);
      case Screen.online:
        return OnlineScreen(
          app: app,
          client: client,
          feedback: feedback,
          onBack: () {
            client.disconnect();
            _go(Screen.title, forward: false);
          },
        );
      case Screen.lobby:
        return LobbyScreen(
          app: app,
          client: client,
          feedback: feedback,
          onLeave: _leaveOnline,
          onGarage: () {
            _garageReturn = Screen.lobby;
            _go(Screen.garage);
          },
        );
      case Screen.race:
        final RaceSession? session = client.session ?? flow.session;
        if (session == null) {
          return const Scaffold(
            body: NtBackdrop(child: StatePanel(loading: true, title: 'Loading race…')),
          );
        }
        final online = session is NetSession;
        return RaceScreen(
          key: ValueKey(session),
          session: session,
          app: app,
          feedback: feedback,
          client: online ? client : null,
          scriptedDriver: test.active ? Autopilot(lane: test.lane ?? 0) : null,
          onQuit: online ? _leaveOnline : _quitOffline,
          onContinue: online ? () {} : _afterOfflineRace,
        );
      case Screen.podium:
        if (_netOutcome != null) {
          final o = _netOutcome!;
          return PodiumScreen(
            title: client.room?.settings.mode == GameMode.battle
                ? 'Battle results'
                : (o.races.length > 1 ? '${cupById(client.room?.settings.cupId ?? cups.first.id).name} results' : 'Race results'),
            standings: o.standings,
            localSlot: o.standings.where((s) => s.platform == AppState.platformId && s.name == app.name).firstOrNull?.slot ?? -1,
            feedback: feedback,
            hash: o.hash,
            races: o.races,
            onHome: _leaveOnline,
            onAgain: () {
              _netOutcome = null;
              _go(Screen.lobby, forward: false);
            },
            againLabel: 'Back to lobby',
          );
        }
        final ttBest = flow.mode == PlayMode.timeTrial ? app.ghosts[flow.trackId] : null;
        return PodiumScreen(
          title: switch (flow.mode) {
            PlayMode.grandPrix => '${cupById(flow.cupId).name} results',
            PlayMode.timeTrial => 'Time trial',
            PlayMode.battle => 'Battle results',
            _ => 'Race results',
          },
          standings: flow.sortedStandings,
          localSlot: 0,
          feedback: feedback,
          races: flow.raceHistory,
          hash: ttBest == null ? null : 'best ${(ttBest['ticks'] as int) / ticksPerSecond}s',
          onHome: _quitOffline,
          onAgain: () {
            feedback.tap();
            flow.startSeries();
            _go(Screen.race);
          },
          againLabel: flow.mode == PlayMode.grandPrix ? 'Race cup again' : 'Race again',
        );
    }
  }
}

/// Slide + fade between top-level screens; direction follows navigation.
class PageTransitionSwitcher extends StatelessWidget {
  const PageTransitionSwitcher({super.key, required this.child, required this.forward, required this.duration});
  final Widget child;
  final bool forward;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: NtMotion.emphasized,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, anim) {
        final incoming = child.key == this.child.key;
        final dx = incoming ? (forward ? 0.06 : -0.06) : 0.0;
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
