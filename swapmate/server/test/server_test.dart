import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:swapmate_core/swapmate_core.dart';
import 'package:swapmate_server/swapmate_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal scripted client used by the tests.
class TestClient {
  TestClient(this.channel) {
    channel.stream.listen((data) {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      messages.add(msg);
      switch (msg['type']) {
        case MsgType.welcome:
          playerId = msg['playerId'] as String;
          resumeToken = msg['resumeToken'] as String;
        case MsgType.roomState:
          room = msg['room'] == null
              ? null
              : RoomState.fromJson(msg['room'] as Map<String, dynamic>);
        case MsgType.gameState:
          game = GameState.fromJson(msg['game'] as Map<String, dynamic>);
        case MsgType.chatMessage:
          chats.add(
            ChatMessage.fromJson(msg['message'] as Map<String, dynamic>),
          );
        case MsgType.gameEvent:
          events.add(GameEvent.fromJson(msg['event'] as Map<String, dynamic>));
        case MsgType.error:
          errors.add(msg);
      }
      _changed.add(null);
    });
  }

  static Future<TestClient> connect(int port) async {
    final ch = WebSocketChannel.connect(Uri.parse('ws://127.0.0.1:$port/ws'));
    await ch.ready;
    return TestClient(ch);
  }

  final WebSocketChannel channel;
  final messages = <Map<String, dynamic>>[];
  final chats = <ChatMessage>[];
  final events = <GameEvent>[];
  final errors = <Map<String, dynamic>>[];
  final _changed = StreamController<void>.broadcast();
  String? playerId;
  String? resumeToken;
  RoomState? room;
  GameState? game;

  void send(Map<String, dynamic> msg) => channel.sink.add(jsonEncode(msg));

  Future<void> until(
    bool Function() cond, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (cond()) return;
    final done = Completer<void>();
    final sub = _changed.stream.listen((_) {
      if (cond() && !done.isCompleted) done.complete();
    });
    try {
      await done.future.timeout(timeout);
    } finally {
      await sub.cancel();
    }
  }

  Seat? get seat => room?.byId(playerId!)?.seat;

  Future<void> close() => channel.sink.close();
}

void main() {
  late SwapmateServer server;

  setUp(() async {
    server = SwapmateServer(
      const ServerConfig(
        seed: 42,
        botDelayMs: 5,
        reconnectGraceMs: 500,
        testMode: true,
      ),
    );
    await server.start(host: '127.0.0.1', port: 0);
  });

  tearDown(() => server.stop());

  Future<TestClient> hello(
    String name,
    String platform, {
    String? testId,
  }) async {
    final c = await TestClient.connect(server.port);
    c.send(ClientMsg.hello(name: name, platform: platform, testId: testId));
    await c.until(() => c.playerId != null);
    return c;
  }

  test('four clients on four platforms play a complete match to checkmate', () async {
    final web = await hello('Web', 'web', testId: 'web');
    final ios = await hello('iOS', 'ios', testId: 'ios');
    final android = await hello('Android', 'android', testId: 'android');
    final mac = await hello('macOS', 'macos', testId: 'macos');
    final all = [web, ios, android, mac];

    web.send(
      ClientMsg.roomCreate(
        code: 'TEST',
        timeControl: const TimeControl(initialMs: 300000, incrementMs: 0),
      ),
    );
    await web.until(() => web.room != null);
    expect(web.room!.code, 'TEST');
    for (final c in [ios, android, mac]) {
      c.send(ClientMsg.roomJoin('TEST'));
      await c.until(() => c.room != null);
    }
    await web.until(() => web.room!.players.length == 4);
    // Auto-seating filled the chairs in order; put everyone where we want.
    expect(web.seat, Seat.aWhite);
    expect(ios.seat, Seat.aBlack);
    expect(android.seat, Seat.bWhite);
    expect(mac.seat, Seat.bBlack);

    for (final c in all) {
      c.send(ClientMsg.roomReady(true));
    }
    for (final c in all) {
      await c.until(() => c.room?.phase == RoomPhase.playing && c.game != null);
    }

    Future<void> play(TestClient c, String uci) async {
      final before = c.game!.moves.length;
      c.send(ClientMsg.gameMove(Move.parse(uci)));
      await c.until(() => c.game!.moves.length > before || c.errors.isNotEmpty);
      expect(c.errors, isEmpty, reason: 'move $uci by ${c.playerId}');
    }

    // Board A: white grabs a pawn so B-Black gets a drop piece.
    await play(web, 'e2e4');
    await play(ios, 'd7d5');
    await play(web, 'e4d5');
    await mac.until(
      () => mac.game!.boards[BoardId.b]!.position.blackReserve.has(
        PieceType.pawn,
      ),
    );

    // Board B: scholar's mate, with the passed pawn dropped along the way.
    await play(android, 'e2e4');
    await play(mac, 'e7e5');
    await play(android, 'd1h5');
    await play(mac, 'P@d6'); // pre-drop of the pawn passed from board A
    await play(android, 'f1c4');
    await play(mac, 'b8c6');
    await play(android, 'h5f7');

    for (final c in all) {
      await c.until(() => c.game?.isOver == true);
      expect(c.game!.result!.reason, ResultReason.checkmate);
      expect(c.game!.result!.winner, Team.two);
      expect(c.game!.result!.board, BoardId.b);
      expect(c.room!.phase, RoomPhase.finished);
      expect(c.game!.bpgn, contains('{BB checkmated} 0-1'));
      expect(c.game!.bpgn, contains('2b. P@d6'));
    }
    // Every client agrees on both final positions.
    final fens = all
        .map(
          (c) =>
              '${c.game!.boards[BoardId.a]!.fen}|${c.game!.boards[BoardId.b]!.fen}',
        )
        .toSet();
    expect(fens.length, 1);
    expect(all.map((c) => c.game!.moves.length).toSet(), {10});
    expect(web.events.where((e) => e.kind == 'pass').length, 2);

    // Test channel lists all four registered clients.
    final list = server.hub.testClientList();
    expect(list.map((e) => e['testId']).toSet(), {
      'web',
      'ios',
      'android',
      'macos',
    });
    expect(server.hub.roomJson('TEST')!['bpgn'], contains('[Result "0-1"]'));

    for (final c in all) {
      await c.close();
    }
  });

  test('bots fill a room and finish a match on their own', () async {
    final c = await hello('Solo', 'macos');
    c.send(
      ClientMsg.roomCreate(
        fillBots: true,
        timeControl: const TimeControl(initialMs: 60000, incrementMs: 0),
      ),
    );
    await c.until(() => c.room != null && c.room!.players.length == 4);
    expect(c.room!.players.where((p) => p.isBot).length, 3);
    c.send(ClientMsg.roomReady(true));
    await c.until(() => c.game != null);
    // The human resigns; bots on board B keep playing until the finish message.
    c.send(ClientMsg.gameResign());
    await c.until(() => c.game!.isOver);
    expect(c.game!.result!.reason, ResultReason.resignation);
    expect(c.game!.result!.winner, Team.two);
    await c.close();
  });

  test('two bots facing each other end the game by themselves', () async {
    final c = await hello('Watcher', 'web');
    c.send(
      ClientMsg.roomCreate(
        timeControl: const TimeControl(initialMs: 60000, incrementMs: 0),
      ),
    );
    await c.until(() => c.room != null);
    c.send(ClientMsg.roomSeat(null)); // become a spectator
    await c.until(() => c.room!.spectators.isNotEmpty);
    for (final s in Seat.values) {
      c.send(ClientMsg.roomBot(s, add: true));
    }
    await c.until(() => c.room!.players.length == 4);
    c.send(ClientMsg.roomStart());
    await c.until(
      () => c.game?.isOver == true,
      timeout: const Duration(seconds: 60),
    );
    expect(c.game!.moves, isNotEmpty);
    await c.close();
  });

  test(
    'premove executes when it becomes legal, and is dropped when it is not',
    () async {
      final w = await hello('W', 'web');
      final b = await hello('B', 'ios');
      w.send(
        ClientMsg.roomCreate(
          timeControl: const TimeControl(initialMs: 300000, incrementMs: 0),
        ),
      );
      await w.until(() => w.room != null);
      b.send(ClientMsg.roomJoin(w.room!.code));
      await b.until(() => b.room != null);
      w.send(ClientMsg.roomBot(Seat.bWhite, add: true));
      w.send(ClientMsg.roomBot(Seat.bBlack, add: true));
      w.send(ClientMsg.roomReady(true));
      b.send(ClientMsg.roomReady(true));
      await b.until(() => b.game != null);

      b.send(ClientMsg.gamePremove(Move.parse('e7e5')));
      await b.until(() => b.game!.premove == Move.parse('e7e5'));
      w.send(ClientMsg.gameMove(Move.parse('e2e4')));
      await b.until(
        () => b.game!.moves.where((m) => m.board == BoardId.a).length == 2,
      );
      expect(b.game!.moves.where((m) => m.board == BoardId.a).last.san, 'e5');
      expect(b.game!.premove, isNull);

      // Illegal premove (pawn jumping over own piece) is silently discarded.
      b.send(ClientMsg.gamePremove(Move.parse('e5e3')));
      await b.until(() => b.game!.premove != null);
      w.send(ClientMsg.gameMove(Move.parse('g1f3')));
      await b.until(
        () =>
            b.game!.moves.where((m) => m.board == BoardId.a).length == 3 &&
            b.game!.premove == null,
      );
      expect(b.game!.boards[BoardId.a]!.position.turn, PieceColor.black);
      await w.close();
      await b.close();
    },
  );

  test('reconnecting with a resume token restores the seat', () async {
    final w = await hello('W', 'web');
    w.send(ClientMsg.roomCreate());
    await w.until(() => w.room != null);
    final code = w.room!.code;
    final token = w.resumeToken!;
    final id = w.playerId!;
    await w.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(server.hub.rooms[code]!.find(id)!.connected, isFalse);

    final again = await TestClient.connect(server.port);
    again.send(ClientMsg.hello(name: 'W', platform: 'web', resumeToken: token));
    await again.until(() => again.room != null);
    expect(again.playerId, id);
    expect(again.room!.code, code);
    expect(again.seat, Seat.aWhite);
    expect(again.room!.byId(id)!.connected, isTrue);
    await again.close();
  });

  test(
    'quick chat goes to the partner only; room chat reaches spectators',
    () async {
      final a = await hello('A', 'web');
      final b = await hello('B', 'ios');
      final s = await hello('S', 'android');
      a.send(ClientMsg.roomCreate());
      await a.until(() => a.room != null);
      b.send(ClientMsg.roomJoin(a.room!.code));
      await b.until(() => b.room != null);
      b.send(ClientMsg.roomSeat(Seat.bBlack)); // A's partner
      s.send(ClientMsg.roomJoin(a.room!.code, spectate: true));
      await s.until(() => s.room != null);
      await a.until(() => a.room!.seated(Seat.bBlack) != null);

      a.send(ClientMsg.chatQuick(QuickChat.needKnight));
      await b.until(() => b.chats.isNotEmpty);
      expect(b.chats.single.quick, QuickChat.needKnight);
      expect(b.chats.single.display, 'Need a knight!');
      a.send(ClientMsg.chatText('hello room'));
      await s.until(() => s.chats.isNotEmpty);
      expect(s.chats.single.text, 'hello room');
      expect(s.chats.where((c) => c.quick != null), isEmpty);
      for (final c in [a, b, s]) {
        await c.close();
      }
    },
  );

  test('errors are reported for illegal moves and wrong turns', () async {
    final w = await hello('W', 'web');
    w.send(ClientMsg.roomCreate(fillBots: true));
    await w.until(() => w.room?.players.length == 4);
    w.send(ClientMsg.roomReady(true));
    await w.until(() => w.game != null);
    w.send(ClientMsg.gameMove(Move.parse('e2e5')));
    await w.until(() => w.errors.isNotEmpty);
    expect(w.errors.single['code'], ErrorCode.illegalMove);
    await w.close();
  });

  test('chat flooding is rate limited', () async {
    final w = await hello('W', 'web');
    w.send(ClientMsg.roomCreate(code: 'CHAT'));
    await w.until(() => w.room != null);
    for (var i = 0; i <= chatBurst; i++) {
      w.send(ClientMsg.chatText('hi $i'));
    }
    await w.until(() => w.errors.isNotEmpty);
    expect(w.errors.single['code'], ErrorCode.rateLimited);
    expect(w.chats.length, chatBurst);
    await w.close();
  });

  test('over-long chat text is truncated', () async {
    final w = await hello('W', 'web');
    w.send(ClientMsg.roomCreate(code: 'LONG'));
    await w.until(() => w.room != null);
    w.send(ClientMsg.chatText('x' * (chatMaxLength + 50)));
    await w.until(() => w.chats.isNotEmpty);
    expect(w.chats.single.text!.length, chatMaxLength);
    expect(w.errors, isEmpty);
    await w.close();
  });

  test('healthz and rooms endpoints answer over HTTP', () async {
    final c = await hello('W', 'web');
    c.send(ClientMsg.roomCreate(code: 'HTTP'));
    await c.until(() => c.room != null);
    final client = HttpClientShim(server.port);
    final health = await client.getJson('/healthz');
    expect(health['ok'], isTrue);
    final room = await client.getJson('/rooms/HTTP');
    expect((room['room'] as Map)['code'], 'HTTP');
    expect(await client.status('/rooms/NOPE'), 404);
    await c.close();
  });
}

class HttpClientShim {
  HttpClientShim(this.port);
  final int port;

  Future<Map<String, dynamic>> getJson(String path) async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port$path'));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<int> status(String path) async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://127.0.0.1:$port$path'));
    final res = await req.close();
    await res.drain<void>();
    client.close();
    return res.statusCode;
  }
}
