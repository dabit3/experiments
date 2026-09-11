import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/main.dart';
import 'package:nitro_tots/net/client.dart';
import 'package:nitro_tots/screens/lobby_screen.dart';
import 'package:nitro_tots/screens/podium_screen.dart';
import 'package:nitro_tots/state/app_state.dart';
import 'package:nitro_tots/state/audio.dart';
import 'package:nitro_tots/state/test_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matchStart = {
  'type': Msg.matchStart,
  'racers': [
    {'slot': 0, 'playerId': 'player', 'name': 'Racer', 'character': 'pip', 'kart': 'jellybean', 'bot': false, 'platform': 'test'},
  ],
  'mode': 'race',
  'trackId': 'sprinkle',
  'seed': 4242,
  'laps': 1,
  'battleSeconds': 120,
  'raceIndex': 0,
  'totalRaces': 1,
};

void main() {
  test('Starting another match in the same room clears the previous match outcome', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = NetClient(platform: 'test');
    WebSocket? socket;
    addTearDown(() async {
      await client.disconnect();
      await socket?.close();
      await server.close(force: true);
    });
    server.transform(WebSocketTransformer()).listen((connection) {
      socket = connection;
      connection.listen((data) {
        final packet = jsonDecode(data as String) as Map<String, dynamic>;
        if (packet['type'] == Msg.hello) {
          connection.add(jsonEncode({'type': Msg.welcome, 'playerId': 'player', 'token': 'fixture-token'}));
          connection.add(jsonEncode(_matchStart));
        }
      });
    });
    final firstStart = client.events.firstWhere((packet) => packet['type'] == Msg.matchStart);
    await client.connect('ws://127.0.0.1:${server.port}/ws', name: 'Racer', character: 'pip', kart: 'jellybean');
    await firstStart.timeout(const Duration(seconds: 5));
    final previous = client.session!;
    previous.sim.phase = RacePhase.finished;
    client.matchOutcome.value = MatchOutcome(standings: [], hash: 'previous-match', races: []);
    final nextStart = client.events.firstWhere((packet) => packet['type'] == Msg.matchStart);
    socket!.add(jsonEncode(_matchStart));
    await nextStart.timeout(const Duration(seconds: 5));
    expect(client.session, isNot(same(previous)));
    expect(client.session!.finished, isFalse);
    expect(client.matchOutcome.value, isNull);
  });

  testWidgets('Returning to lobby stays there when a finished room broadcasts an update', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance(), const TestConfig(active: true, screen: 'lobby'))
      ..reduceMotion = true
      ..musicVolume = 0
      ..sfxVolume = 0;
    await tester.pumpWidget(NitroTotsApp(app: app, feedback: NtFeedback(app)));
    await tester.pump();
    final client = tester.widget<LobbyScreen>(find.byType(LobbyScreen)).client;
    client.room = RoomView(
      code: 'TEST',
      hostId: 'player',
      status: 'matchOver',
      settings: const RoomSettings(grandPrix: false),
      players: [],
      raceIndex: 0,
      totalRaces: 1,
      standings: [],
    );
    client.session = NetSession.fromMatchStart(client, _matchStart, 'player')..sim.phase = RacePhase.finished;
    client.matchOutcome.value = MatchOutcome(
      standings: [
        Standing(slot: 0, name: 'Racer', characterId: 'pip', kartId: 'jellybean', isBot: false, platform: 'test', points: 15, places: [1]),
      ],
      hash: 'fixture',
      races: [],
    );
    await tester.pump();
    expect(find.byType(PodiumScreen), findsOneWidget);
    await tester.tap(find.text('Back to lobby'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LobbyScreen), findsOneWidget);
    client.notifyListeners();
    await tester.pump();
    await tester.pump();
    expect(find.byType(LobbyScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
