import 'dart:async';
import 'dart:convert';

import 'package:gambit_court_core/gambit_court_core.dart';
import 'package:gambit_court_server/gambit_court_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal scripted client used to exercise the wire protocol end to end.
class TestClient {
  TestClient._(this.id, this._channel) {
    _channel.stream.listen((raw) {
      final message =
          (jsonDecode(raw as String) as Map).cast<String, Object?>();
      received.add(message);
      if (message['type'] == Protocol.roomState) {
        room = RoomSnapshot.fromJson((message['room'] as Map).cast());
      }
      if (message['type'] == Protocol.welcome && message['room'] != null) {
        room = RoomSnapshot.fromJson((message['room'] as Map).cast());
      }
      if (message['type'] == Protocol.left) room = null;
      _controller.add(message);
    });
  }

  static Future<TestClient> connect(
      int port, String id, String platform) async {
    final channel =
        WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:$port/ws'));
    await channel.ready;
    final client = TestClient._(id, channel);
    client.send({
      'type': Protocol.hello,
      'clientId': id,
      'name': id,
      'platform': platform,
    });
    await client.next(Protocol.welcome);
    return client;
  }

  final String id;
  final WebSocketChannel _channel;
  final received = <Map<String, Object?>>[];
  final _controller = StreamController<Map<String, Object?>>.broadcast();
  RoomSnapshot? room;

  void send(Map<String, Object?> message) =>
      _channel.sink.add(jsonEncode(message));

  Future<Map<String, Object?>> next(
    String type, {
    bool Function(Map<String, Object?>)? where,
  }) =>
      _controller.stream
          .firstWhere((m) => m['type'] == type && (where?.call(m) ?? true))
          .timeout(const Duration(seconds: 10));

  Future<RoomSnapshot> nextRoom(bool Function(RoomSnapshot) where) async {
    final current = room;
    if (current != null && where(current)) return current;
    final message = await next(
      Protocol.roomState,
      where: (m) => where(RoomSnapshot.fromJson((m['room'] as Map).cast())),
    );
    return RoomSnapshot.fromJson((message['room'] as Map).cast());
  }

  Future<void> close() async {
    await _channel.sink.close();
    await _controller.close();
  }
}

void main() {
  late GambitCourtServer server;
  late ManualWallClock wall;
  late Hub hub;

  setUp(() async {
    wall = ManualWallClock();
    hub = Hub(
      config: const HubConfig(
        seed: 7,
        frozenClocks: false,
        botDelayMs: 10,
        reconnectGraceMs: 200,
      ),
      wall: wall,
    );
    server = GambitCourtServer(hub: hub, enableControl: true);
    await server.start(host: '127.0.0.1', port: 0);
  });

  tearDown(() async {
    await server.stop();
  });

  test('two players and two spectators converge on the same state', () async {
    final web = await TestClient.connect(server.port, 'web', 'web');
    final ios = await TestClient.connect(server.port, 'ios', 'ios');
    final android = await TestClient.connect(server.port, 'android', 'android');
    final macos = await TestClient.connect(server.port, 'macos', 'macos');

    web.send({
      'type': Protocol.createRoom,
      'timeControl': {'initialMs': 300000, 'incrementMs': 2000},
      'side': 'white',
    });
    final created = await web.nextRoom((r) => r.status == RoomStatus.waiting);
    expect(created.code, hasLength(6));
    expect(created.white?.clientId, 'web');

    ios.send({'type': Protocol.joinRoom, 'code': created.code});
    final started = await ios.nextRoom((r) => r.status == RoomStatus.playing);
    expect(started.black?.clientId, 'ios');

    for (final spectator in [android, macos]) {
      spectator.send({
        'type': Protocol.joinRoom,
        'code': created.code,
        'asSpectator': true,
      });
    }
    await web.nextRoom((r) => r.spectators.length == 2);

    // Scholar's mate: 1.e4 e5 2.Qh5 Nc6 3.Bc4 Nf6 4.Qxf7#
    final script = ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7'];
    for (var i = 0; i < script.length; i++) {
      final mover = i.isEven ? web : ios;
      mover.send({'type': Protocol.move, 'uci': script[i]});
      wall.advance(1500);
      await mover.nextRoom((r) => r.moves.length == i + 1);
    }

    final finals = await Future.wait([
      for (final c in [web, ios, android, macos])
        c.nextRoom((r) => r.status == RoomStatus.finished),
    ]);
    for (final snapshot in finals) {
      expect(snapshot.result?.outcome, GameOutcome.whiteWins);
      expect(snapshot.result?.reason, GameEndReason.checkmate);
      expect(snapshot.fen, finals.first.fen);
      expect(snapshot.moves.map((m) => m.san).join(' '),
          'e4 e5 Qh5 Nc6 Bc4 Nf6 Qxf7#');
    }
    // Each side's first move is untimed; every later move is charged 1.5s and
    // refunded the 2s increment.
    expect(finals.first.clocks.whiteMs, 300000 + 3 * 500);
    expect(finals.first.clocks.blackMs, 300000 + 2 * 500);
    expect(finals.first.clocks.running, isNull);

    // Rematch swaps colours and resets the board.
    web.send({'type': Protocol.offerRematch});
    await ios.nextRoom((r) => r.offers.rematch == PieceColor.white);
    ios.send({'type': Protocol.acceptRematch});
    final rematch = await macos.nextRoom((r) => r.status == RoomStatus.playing);
    expect(rematch.white?.clientId, 'ios');
    expect(rematch.black?.clientId, 'web');
    expect(rematch.moves, isEmpty);

    for (final c in [web, ios, android, macos]) {
      await c.close();
    }
  });

  test('illegal, out-of-turn and spectator moves are rejected', () async {
    final a = await TestClient.connect(server.port, 'a', 'web');
    final b = await TestClient.connect(server.port, 'b', 'web');
    final s = await TestClient.connect(server.port, 's', 'web');
    a.send({'type': Protocol.createRoom, 'side': 'white'});
    final room = await a.nextRoom((r) => r.white != null);
    b.send({'type': Protocol.joinRoom, 'code': room.code});
    s.send({'type': Protocol.joinRoom, 'code': room.code, 'asSpectator': true});
    await a.nextRoom((r) => r.status == RoomStatus.playing);

    b.send({'type': Protocol.move, 'uci': 'e7e5'});
    expect((await b.next(Protocol.error))['code'], ErrorCodes.notYourTurn);
    a.send({'type': Protocol.move, 'uci': 'e2e5'});
    expect((await a.next(Protocol.error))['code'], ErrorCodes.illegalMove);
    s.send({'type': Protocol.move, 'uci': 'e2e4'});
    expect((await s.next(Protocol.error))['code'], ErrorCodes.notAllowed);
    a.send({'type': Protocol.joinRoom, 'code': 'ZZZZZZ'});
    expect((await a.next(Protocol.error))['code'], ErrorCodes.roomNotFound);

    for (final c in [a, b, s]) {
      await c.close();
    }
  });

  test('bot fills a room, replies deterministically, and accepts takebacks',
      () async {
    final human = await TestClient.connect(server.port, 'h', 'macos');
    human.send({
      'type': Protocol.createRoom,
      'side': 'white',
      'botLevel': 2,
      'timeControl': {'initialMs': 0, 'incrementMs': 0},
    });
    final playing = await human.nextRoom((r) => r.status == RoomStatus.playing);
    expect(playing.black?.isBot, isTrue);
    human.send({'type': Protocol.move, 'uci': 'e2e4'});
    final replied = await human.nextRoom((r) => r.moves.length == 2);
    final firstReply = replied.moves[1].move.uci;

    human.send({'type': Protocol.offerTakeback});
    final undone = await human.nextRoom((r) => r.moves.isEmpty);
    expect(undone.status, RoomStatus.playing);

    human.send({'type': Protocol.move, 'uci': 'e2e4'});
    final again = await human.nextRoom((r) => r.moves.length == 2);
    expect(again.moves[1].move.uci, firstReply);

    human.send({'type': Protocol.resign});
    final done = await human.nextRoom((r) => r.status == RoomStatus.finished);
    expect(done.result?.outcome, GameOutcome.blackWins);
    expect(done.result?.reason, GameEndReason.resignation);
    await human.close();
  });

  test('quick pair matches two waiting clients with the same time control',
      () async {
    final a = await TestClient.connect(server.port, 'qa', 'ios');
    final b = await TestClient.connect(server.port, 'qb', 'android');
    final tc = {'initialMs': 180000, 'incrementMs': 2000};
    a.send({'type': Protocol.quickPair, 'timeControl': tc});
    await a.next(Protocol.queued);
    b.send({'type': Protocol.quickPair, 'timeControl': tc});
    final ra = await a.nextRoom((r) => r.status == RoomStatus.playing);
    final rb = await b.nextRoom((r) => r.status == RoomStatus.playing);
    expect(ra.code, rb.code);
    expect({ra.white?.clientId, ra.black?.clientId}, {'qa', 'qb'});
    await a.close();
    await b.close();
  });

  test('a disconnected player can reconnect and resume', () async {
    final a = await TestClient.connect(server.port, 'ra', 'web');
    final b = await TestClient.connect(server.port, 'rb', 'ios');
    a.send({'type': Protocol.createRoom, 'side': 'white'});
    final room = await a.nextRoom((r) => r.white != null);
    b.send({'type': Protocol.joinRoom, 'code': room.code});
    await a.nextRoom((r) => r.status == RoomStatus.playing);
    a.send({'type': Protocol.move, 'uci': 'd2d4'});
    await b.nextRoom((r) => r.moves.length == 1);

    await a.close();
    await b.nextRoom((r) => r.white?.connected == false);

    final a2 = await TestClient.connect(server.port, 'ra', 'web');
    expect(a2.room?.code, room.code);
    expect(a2.room?.moves.length, 1);
    await b.nextRoom((r) => r.white?.connected == true);

    // Letting the grace period lapse forfeits the game by abandonment.
    await b.close();
    final abandoned = await a2.nextRoom((r) => r.status == RoomStatus.finished);
    expect(abandoned.result?.reason, GameEndReason.abandonment);
    expect(abandoned.result?.outcome, GameOutcome.whiteWins);
    await a2.close();
  });

  test('flag falls when the running clock hits zero', () async {
    final a = await TestClient.connect(server.port, 'ta', 'web');
    final b = await TestClient.connect(server.port, 'tb', 'web');
    a.send({
      'type': Protocol.createRoom,
      'side': 'white',
      'timeControl': {'initialMs': 1000, 'incrementMs': 0},
    });
    final room = await a.nextRoom((r) => r.white != null);
    b.send({'type': Protocol.joinRoom, 'code': room.code});
    await a.nextRoom((r) => r.status == RoomStatus.playing);
    a.send({'type': Protocol.move, 'uci': 'e2e4'});
    await b.nextRoom((r) => r.moves.length == 1);
    b.send({'type': Protocol.move, 'uci': 'e7e5'});
    final ticking = await a.nextRoom((r) => r.moves.length == 2);
    expect(ticking.clocks.running, PieceColor.white);
    wall.advance(2000);
    a.send({'type': Protocol.move, 'uci': 'g1f3'});
    final done = await a.nextRoom((r) => r.status == RoomStatus.finished);
    expect(done.moves.length, 2);
    expect(done.result?.reason, GameEndReason.timeout);
    expect(done.result?.outcome, GameOutcome.blackWins);
    await a.close();
    await b.close();
  });
}
