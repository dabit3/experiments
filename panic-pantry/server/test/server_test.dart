import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:panic_pantry_core/panic_pantry_core.dart';
import 'package:panic_pantry_server/panic_pantry_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal scripted client used to exercise the wire protocol.
class TestClient {
  TestClient(this.channel) {
    channel.stream.listen((raw) {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      received.add(msg);
      for (final c in _waiters.toList()) {
        if (c.$1(msg)) {
          _waiters.remove(c);
          c.$2.complete(msg);
        }
      }
    });
  }

  static Future<TestClient> connect(int port) async {
    final ch = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:$port/ws'));
    await ch.ready;
    return TestClient(ch);
  }

  final WebSocketChannel channel;
  final List<Map<String, dynamic>> received = [];
  final List<(bool Function(Map<String, dynamic>), Completer<Map<String, dynamic>>)> _waiters = [];

  void send(Map<String, dynamic> m) => channel.sink.add(jsonEncode(m));

  Future<Map<String, dynamic>> next(
    bool Function(Map<String, dynamic>) test, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    for (final m in received) {
      if (test(m)) return Future.value(m);
    }
    final c = Completer<Map<String, dynamic>>();
    _waiters.add((test, c));
    return c.future.timeout(timeout);
  }

  Future<Map<String, dynamic>> nextType(String type, {Duration timeout = const Duration(seconds: 20)}) =>
      next((m) => m['type'] == type, timeout: timeout);

  Future<void> close() => channel.sink.close();
}

void main() {
  late PanicPantryServer server;
  late int port;

  setUp(() async {
    server = PanicPantryServer(seed: 1);
    final http = await server.serve(address: InternetAddress.loopbackIPv4, port: 0);
    port = http.port;
  });

  tearDown(() => server.close());

  test('hello, create, join, ready, start, results and rematch', () async {
    final a = await TestClient.connect(port);
    final b = await TestClient.connect(port);
    a.send({'type': Msg.hello, 'name': 'Ada', 'platform': 'test'});
    b.send({'type': Msg.hello, 'name': 'Bo', 'platform': 'test'});
    final wa = await a.nextType(Msg.welcome);
    await b.nextType(Msg.welcome);
    expect(wa['protocol'], kProtocolVersion);
    expect((wa['levels'] as List).length, kLevels.length);

    // Pre-create the room through the harness so the round runs at 10x wall speed.
    await http.post(
      Uri.parse('http://127.0.0.1:$port/test/rooms'),
      body: jsonEncode({'code': 'FAST', 'seed': 99, 'level': 'training', 'speed': 10}),
    );
    a.send({'type': Msg.roomJoin, 'code': 'FAST'});
    final rs = await a.nextType(Msg.roomState);
    final code = (rs['room'] as Map)['code'] as String;
    expect(code.length, 4);

    b.send({'type': Msg.roomJoin, 'code': code.toLowerCase()});
    final joined = await b.nextType(Msg.roomState);
    expect(((joined['room'] as Map)['players'] as List).length, 2);

    // Only the host may add bots.
    b.send({'type': Msg.roomAddBot});
    final err = await b.nextType(Msg.error);
    expect(err['code'], 'not_host');
    a.send({'type': Msg.roomAddBot});
    a.send({'type': Msg.roomAddBot});
    await a.next((m) => m['type'] == Msg.roomState && ((m['room'] as Map)['players'] as List).length == 4);

    // Start requires everyone ready.
    a.send({'type': Msg.roomStart});
    expect((await a.nextType(Msg.error))['code'], 'not_ready');
    a.send({'type': Msg.roomReady, 'ready': true});
    b.send({'type': Msg.roomReady, 'ready': true});
    await a.next(
      (m) => m['type'] == Msg.roomState && ((m['room'] as Map)['players'] as List).every((p) => p['ready'] == true),
    );
    a.send({'type': Msg.roomStart});

    final snap = await b.nextType(Msg.snapshot);
    expect((snap['state'] as Map)['phase'], 'countdown');

    // Drive a human chef a little and make sure the server moves it.
    a.send({'type': Msg.input, 'dx': 1});
    await Future<void>.delayed(const Duration(milliseconds: 400));
    a.send({'type': Msg.input});
    final later = await a.next((m) => m['type'] == Msg.snapshot && ((m['state'] as Map)['tick'] as int) > 20);
    final chefs = ((later['state'] as Map)['chefs'] as List).cast<Map<String, dynamic>>();
    final first = ((snap['state'] as Map)['chefs'] as List).cast<Map<String, dynamic>>();
    final ada0 = first.firstWhere((c) => c['id'] == wa['playerId']);
    final ada1 = chefs.firstWhere((c) => c['id'] == wa['playerId']);
    expect((ada1['x'] as num) > (ada0['x'] as num), isTrue);

    // Results arrive on both clients and match the HTTP view.
    final ra = await a.nextType(Msg.results, timeout: const Duration(seconds: 90));
    final rb = await b.nextType(Msg.results, timeout: const Duration(seconds: 90));
    expect(jsonEncode(ra['results']), jsonEncode(rb['results']));
    expect(((ra['results'] as Map)['served'] as int) > 0, isTrue);

    final viaHttp = jsonDecode((await http.get(Uri.parse('http://127.0.0.1:$port/test/rooms/$code'))).body) as Map;
    expect(jsonEncode(viaHttp['results']), jsonEncode(ra['results']));

    a.send({'type': Msg.roomRematch});
    final lobby = await a.next(
      (m) => m['type'] == Msg.roomState && (m['room'] as Map)['phase'] == 'lobby' && (m['room'] as Map)['match'] == 1,
    );
    expect((lobby['room'] as Map)['phase'], 'lobby');
    await a.close();
    await b.close();
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('reconnect with token resumes seat mid-match', () async {
    final a = await TestClient.connect(port);
    a.send({'type': Msg.hello, 'name': 'Ada', 'platform': 'test'});
    final w = await a.nextType(Msg.welcome);
    a.send({'type': Msg.roomCreate, 'level': 'training'});
    final rs = await a.nextType(Msg.roomState);
    final code = (rs['room'] as Map)['code'] as String;
    a.send({'type': Msg.roomAddBot});
    a.send({'type': Msg.roomReady});
    await a.next((m) => m['type'] == Msg.roomState && ((m['room'] as Map)['players'] as List).length == 2);
    a.send({'type': Msg.roomStart});
    await a.nextType(Msg.snapshot);
    await a.close();

    final a2 = await TestClient.connect(port);
    a2.send({'type': Msg.hello, 'name': 'Ada', 'platform': 'test', 'token': w['token']});
    final w2 = await a2.nextType(Msg.welcome);
    expect(w2['resumed'], isTrue);
    expect(w2['playerId'], w['playerId']);
    final snap = await a2.nextType(Msg.snapshot);
    expect(snap['code'], code);
    final chefs = ((snap['state'] as Map)['chefs'] as List).cast<Map<String, dynamic>>();
    expect(chefs.any((c) => c['id'] == w['playerId']), isTrue);
    await a2.close();
  });

  test('test harness: fixed code/seed room, server-side scripted input, client test channel', () async {
    final created = jsonDecode(
      (await http.post(
        Uri.parse('http://127.0.0.1:$port/test/rooms'),
        body: jsonEncode({'code': 'ZZZZ', 'seed': 4242, 'level': 'training', 'bots': 1}),
      )).body,
    ) as Map;
    expect(created['code'], 'ZZZZ');
    expect(created['seed'], 4242);

    final a = await TestClient.connect(port);
    a.send({'type': Msg.hello, 'name': 'Web', 'platform': 'web'});
    final w = await a.nextType(Msg.welcome);
    a.send({'type': Msg.roomJoin, 'code': 'ZZZZ'});
    await a.nextType(Msg.roomState);

    // Forwarded test input reaches the client untouched.
    final fwd = await http.post(
      Uri.parse('http://127.0.0.1:$port/test/rooms/ZZZZ/players/${w['playerId']}/input'),
      body: jsonEncode({
        'steps': [
          {'dx': 1, 'ticks': 10},
        ],
      }),
    );
    expect(jsonDecode(fwd.body)['forwarded'], 1);
    final ti = await a.nextType(Msg.testInput);
    expect((ti['steps'] as List).first['dx'], 1);

    // Client test reports are exposed to the harness.
    await http.post(
      Uri.parse('http://127.0.0.1:$port/test/rooms/ZZZZ/players/${w['playerId']}/command'),
      body: jsonEncode({'cmd': 'report'}),
    );
    final tc = await a.nextType(Msg.testCommand);
    expect(tc['cmd'], 'report');
    a.send({'type': Msg.testReport, 'phase': 'lobby', 'score': 0});
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await http.post(Uri.parse('http://127.0.0.1:$port/test/rooms/ZZZZ/start'));
    final before = await a.next((m) => m['type'] == Msg.snapshot && ((m['state'] as Map)['phase']) == 'playing');
    // Server-side scripted movement is applied on consecutive ticks.
    await http.post(
      Uri.parse('http://127.0.0.1:$port/test/rooms/ZZZZ/players/${w['playerId']}/input'),
      body: jsonEncode({
        'via': 'server',
        'steps': [
          {'dy': 1, 'ticks': 20},
        ],
      }),
    );
    final after = await a.next(
      (m) =>
          m['type'] == Msg.snapshot &&
          ((m['state'] as Map)['tick'] as int) > ((before['state'] as Map)['tick'] as int) + 25,
    );
    double yOf(Map<String, dynamic> snap) =>
        (((snap['state'] as Map)['chefs'] as List).cast<Map<String, dynamic>>().firstWhere(
                  (c) => c['id'] == w['playerId'],
                )['y']
                as num)
            .toDouble();
    expect(yOf(after) - yOf(before) > 0.3, isTrue, reason: 'scripted input should move the chef down');

    final view = jsonDecode((await http.get(Uri.parse('http://127.0.0.1:$port/test/rooms/ZZZZ'))).body) as Map;
    expect((view['reports'] as Map)[w['playerId']]['phase'], 'lobby');
    expect(view['phase'], 'playing');
    await a.close();
  });
}
