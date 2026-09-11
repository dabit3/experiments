import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_server/nitro_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal headless client: mirrors the authoritative sim from snapshots and
/// drives its kart with the shared [Autopilot].
class HeadlessClient {
  HeadlessClient(this.name, this.platform, this.lane);

  final String name;
  final String platform;
  final double lane;
  late WebSocketChannel ws;
  String? playerId;
  String? token;
  int slot = -1;
  RaceSim? sim;
  Autopilot? pilot;
  final matchOver = Completer<Map<String, dynamic>>();
  final roomStates = <Map<String, dynamic>>[];
  final raceFinished = <Map<String, dynamic>>[];
  final welcome = Completer<void>();
  final joined = Completer<void>();
  Map<String, dynamic>? lastSnapshot;
  int snapshots = 0;

  Future<void> connect(int port) async {
    ws = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:$port/ws'));
    await ws.ready;
    ws.stream.listen((data) => _onMessage(jsonDecode(data as String) as Map<String, dynamic>));
    send({'type': Msg.hello, 'v': protocolVersion, 'name': name, 'character': 'pip', 'kart': 'jellybean', 'platform': platform});
    await welcome.future;
  }

  void send(Map<String, dynamic> m) => ws.sink.add(jsonEncode(m));

  void _onMessage(Map<String, dynamic> m) {
    switch (m['type']) {
      case Msg.welcome:
        playerId = m['playerId'] as String;
        token = m['token'] as String;
        if (!welcome.isCompleted) welcome.complete();
      case Msg.roomState:
        roomStates.add(m);
        if (!joined.isCompleted) joined.complete();
      case Msg.matchStart:
        final racers = (m['racers'] as List).cast<Map<String, dynamic>>();
        final list = [
          for (final r in racers)
            Racer(
              slot: r['slot'] as int,
              playerId: r['playerId'] as String,
              name: r['name'] as String,
              characterId: r['character'] as String,
              kartId: r['kart'] as String,
              isBot: r['bot'] as bool,
              platform: r['platform'] as String,
            ),
        ];
        slot = list.firstWhere((r) => r.playerId == playerId).slot;
        sim = RaceSim(
          track: trackById(m['trackId'] as String),
          racers: list,
          seed: m['seed'] as int,
          laps: m['laps'] as int,
          mode: GameMode.values.byName(m['mode'] as String),
          battleSeconds: m['battleSeconds'] as int,
        );
        pilot = Autopilot(lane: lane);
      case Msg.snapshot:
        snapshots++;
        lastSnapshot = m;
        final s = sim;
        if (s == null) return;
        applySnapshot(s, m);
        final me = s.racerBySlot(slot);
        if (me != null && s.phase != RacePhase.finished) {
          final input = pilot!.drive(s, me);
          send({'type': Msg.input, 'tick': s.tick, ...input.toJson()});
        }
      case Msg.raceFinished:
        raceFinished.add(m);
      case Msg.matchOver:
        send({'type': Msg.testReport, 'hash': m['hash'], 'standings': m['standings']});
        if (!matchOver.isCompleted) matchOver.complete(m);
      case Msg.error:
        stderr.writeln('[$name] error: ${m['code']} ${m['message']}');
    }
  }

  Future<void> close() => ws.sink.close();
}

void main() {
  late NitroServer server;
  late int port;

  setUp(() async {
    // Run the loop 10x faster than real time so a full match takes seconds.
    server = NitroServer(const ServerConfig(host: '127.0.0.1', port: 0, seed: 1234, tickIntervalMs: 3, resultsDelayMs: 300));
    await server.start();
    port = server.port;
  });

  tearDown(() => server.stop());

  test('health endpoint responds', () async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/health'));
    final res = await req.close();
    expect(res.statusCode, 200);
    final body = jsonDecode(await utf8.decodeStream(res)) as Map<String, dynamic>;
    expect(body['ok'], isTrue);
    client.close();
  });

  test('two clients race a one-lap grand prix and agree on the result', () async {
    final a = HeadlessClient('Alpha', 'test-a', -8);
    final b = HeadlessClient('Bravo', 'test-b', 8);
    await a.connect(port);
    await b.connect(port);
    a.send({
      'type': Msg.createRoom,
      'code': 'TEST',
      'settings': {'laps': 1, 'cupId': 'sugar', 'grandPrix': true, 'maxPlayers': 6},
    });
    await a.joined.future;
    b.send({'type': Msg.joinRoom, 'code': 'TEST'});
    await b.joined.future;
    // Ready-up auto-starts the match.
    a.send({'type': Msg.setReady, 'ready': true});
    b.send({'type': Msg.setReady, 'ready': true});

    final results = await Future.wait([a.matchOver.future, b.matchOver.future]).timeout(const Duration(minutes: 3));
    expect(results[0]['hash'], results[1]['hash']);
    expect((results[0]['races'] as List).length, 4);
    expect(a.raceFinished.length, 4);
    expect(a.snapshots, greaterThan(100));

    final standingsA = (results[0]['standings'] as List).cast<Map<String, dynamic>>();
    final standingsB = (results[1]['standings'] as List).cast<Map<String, dynamic>>();
    expect(standingsA.map((s) => '${s['slot']}:${s['points']}').toList(), standingsB.map((s) => '${s['slot']}:${s['points']}').toList());
    expect(standingsA.length, 6);
    expect(standingsA.where((s) => s['bot'] == false).length, 2);

    // Both humans actually drove: they completed the lap themselves.
    for (final race in (results[0]['races'] as List).cast<Map<String, dynamic>>()) {
      final res = (race['results'] as List).cast<Map<String, dynamic>>();
      for (final r in res.where((r) => r['bot'] == false)) {
        expect((r['lapTicks'] as List).length, 1, reason: '${r['name']} did not finish on ${race['trackId']}');
      }
    }

    // The inspection endpoint exposes the same hash and both test reports.
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port/rooms/TEST'));
    final res = await req.close();
    final body = jsonDecode(await utf8.decodeStream(res)) as Map<String, dynamic>;
    client.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(body['hash'], results[0]['hash']);
    await a.close();
    await b.close();
  });

  test('a player can resume after disconnecting mid-lobby', () async {
    final a = HeadlessClient('Alpha', 'test-a', 0);
    await a.connect(port);
    a.send({'type': Msg.createRoom, 'code': 'RSME'});
    await a.joined.future;
    await a.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final ws = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:$port/ws'));
    await ws.ready;
    final first = Completer<Map<String, dynamic>>();
    final states = <Map<String, dynamic>>[];
    ws.stream.listen((d) {
      final m = jsonDecode(d as String) as Map<String, dynamic>;
      if (m['type'] == Msg.welcome && !first.isCompleted) first.complete(m);
      if (m['type'] == Msg.roomState) states.add(m);
    });
    ws.sink.add(jsonEncode({'type': Msg.resume, 'playerId': a.playerId, 'token': a.token}));
    final w = await first.future.timeout(const Duration(seconds: 5));
    expect(w['resumed'], isTrue);
    expect(w['playerId'], a.playerId);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(states, isNotEmpty);
    expect(states.last['code'], 'RSME');
    expect((states.last['players'] as List).single['connected'], isTrue);
    await ws.sink.close();
  });
}
