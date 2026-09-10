import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/net/client.dart';
import 'package:nitro_tots/screens/garage_screen.dart';
import 'package:nitro_tots/screens/lobby_screen.dart';
import 'package:nitro_tots/screens/online_screen.dart';
import 'package:nitro_tots/screens/podium_screen.dart';
import 'package:nitro_tots/screens/settings_screen.dart';
import 'package:nitro_tots/screens/title_screen.dart';
import 'package:nitro_tots/screens/track_screen.dart';
import 'package:nitro_tots/state/app_state.dart';
import 'package:nitro_tots/state/audio.dart';
import 'package:nitro_tots/state/flow.dart';
import 'package:nitro_tots/state/test_config.dart';
import 'package:nitro_tots/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every menu screen at phone, tablet and desktop sizes with the
/// semantics tree enabled (as VoiceOver / the iOS accessibility bridge does),
/// so debug-only layout assertions surface here instead of as a blank window.

Map<String, dynamic> _player(String id, String platform, {bool host = false, bool ready = false}) => {
  'id': id,
  'name': platform,
  'character': 'pip',
  'kart': 'jellybean',
  'platform': platform,
  'ready': ready,
  'connected': true,
  'host': host,
};

RoomView _lobby() => RoomView.fromJson({
  'type': 'room_state',
  'code': 'E2E',
  'status': 'lobby',
  'seed': 4242,
  'hostId': 'a',
  'settings': const RoomSettings(laps: 1, minPlayers: 3).toJson(),
  'players': [_player('a', 'macos', host: true, ready: true), _player('b', 'ios'), _player('c', 'web', ready: true)],
  'raceIndex': 0,
  'totalRaces': 4,
  'races': <Object>[],
  'standings': <Object>[],
});

List<Standing> _standings() => [
  for (var i = 0; i < 8; i++)
    Standing(
      slot: i,
      name: i == 1 ? 'You' : 'Bot $i',
      characterId: characters[i % characters.length].id,
      kartId: karts[i % karts.length].id,
      isBot: i != 1,
      platform: i == 1 ? 'ios' : 'bot',
      points: 60 - i * 6,
      places: [i + 1, (i + 2) % 8 + 1, (i + 3) % 8 + 1, (i + 4) % 8 + 1],
    ),
];

List<({String trackId, List<RaceResult> results})> _races() => [
  for (final track in raceTrackDefs)
    (
      trackId: track.id,
      results: [
        for (final s in _standings())
          RaceResult(
            slot: s.slot,
            name: s.name,
            characterId: s.characterId,
            kartId: s.kartId,
            isBot: s.isBot,
            platform: s.platform,
            place: s.slot + 1,
            finishTick: 3000 + s.slot * 45,
            lapTicks: const [1000, 1000, 1000],
            points: s.points ~/ 4,
            score: 0,
          ),
      ],
    ),
];

const _sizes = <String, (Size, double)>{
  'phone landscape': (Size(2556, 1179), 3),
  'phone portrait': (Size(1179, 2556), 3),
  'tablet': (Size(2048, 1536), 2),
  'desktop': (Size(1440, 900), 1),
};

Future<void> _pumpScreen(WidgetTester tester, Widget screen, Size physical, double dpr) async {
  final handle = tester.ensureSemantics();
  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  // Dump layout errors with the error-causing widget so failures point at a file:line.
  final record = FlutterError.onError;
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    record?.call(details);
  };
  addTearDown(() => FlutterError.onError = record);
  for (final brightness in Brightness.values) {
    await tester.pumpWidget(MaterialApp(theme: buildTheme(brightness), home: screen));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: '${screen.runtimeType} threw at $physical (${brightness.name})');
  }
  handle.dispose();
}

void main() {
  late AppState app;
  late NtFeedback feedback;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppState(await SharedPreferences.getInstance(), const TestConfig());
    feedback = NtFeedback(app);
  });

  for (final MapEntry(key: label, value: (size, dpr)) in _sizes.entries) {
    group(label, () {
      testWidgets('title', (t) => _pumpScreen(t, TitleScreen(app: app, onPlay: (_) {}, onSettings: () {}, onGarage: () {}), size, dpr));

      testWidgets('garage', (t) => _pumpScreen(t, GarageScreen(app: app, feedback: feedback, onBack: () {}, onDone: () {}), size, dpr));

      testWidgets('track select', (t) => _pumpScreen(t, TrackScreen(flow: GameFlow(app), feedback: feedback, onBack: () {}, onStart: () {}), size, dpr));

      testWidgets('settings', (t) => _pumpScreen(t, SettingsScreen(app: app, feedback: feedback, onBack: () {}), size, dpr));

      for (final state in [ConnState.online, ConnState.failed]) {
        testWidgets('online (${state.name})', (t) async {
          final client = NetClient(platform: 'ios')
            ..state = state
            ..lastError = state == ConnState.failed ? 'Could not reach ws://example.invalid/ws' : null;
          await _pumpScreen(t, OnlineScreen(app: app, client: client, feedback: feedback, onBack: () {}), size, dpr);
        });
      }

      testWidgets('lobby', (t) async {
        final client = NetClient(platform: 'ios')
          ..playerId = 'b'
          ..room = _lobby();
        await _pumpScreen(t, LobbyScreen(app: app, client: client, feedback: feedback, onLeave: () {}, onGarage: () {}), size, dpr);
        expect(find.text('Room E2E'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Join code')), findsOneWidget);
      });

      testWidgets('podium', (t) async {
        await _pumpScreen(
          t,
          PodiumScreen(
            title: 'Sugar Cup',
            standings: _standings(),
            localSlot: 1,
            feedback: feedback,
            onHome: () {},
            onAgain: () {},
            hash: '0e4b29a3',
            races: _races(),
          ),
          size,
          dpr,
        );
      });
    });
  }
}
