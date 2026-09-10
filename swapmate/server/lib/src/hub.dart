import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:swapmate_core/swapmate_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'room.dart';

/// One WebSocket connection.
class Connection {
  Connection(this.channel, this.hub);

  final WebSocketChannel channel;
  final Hub hub;
  Player? player;
  Room? room;
  String? testId;
  bool closed = false;

  void send(Map<String, dynamic> msg) {
    if (closed) return;
    channel.sink.add(jsonEncode(msg));
  }

  void error(String code, String message, {String? ref}) => send({
    'type': MsgType.error,
    'code': code,
    'message': message,
    'ref': ?ref,
  });
}

/// Owns all rooms and connections.
class Hub {
  Hub(this.config) : _rng = Random(config.seed);

  final ServerConfig config;
  final Random _rng;
  final Map<String, Room> rooms = {};
  final Set<Connection> connections = {};

  /// Players indexed by resume token so a reconnecting client can reclaim
  /// its seat.
  final Map<String, (Room, Player)> _resumable = {};

  /// Connections registered for the automated test channel, by test id.
  final Map<String, Connection> testClients = {};
  final Map<String, Completer<Map<String, dynamic>>> _pendingTests = {};
  int _ids = 0;

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ';

  String _newCode() {
    while (true) {
      final code = List.generate(
        4,
        (_) => _alphabet[_rng.nextInt(_alphabet.length)],
      ).join();
      if (!rooms.containsKey(code)) return code;
    }
  }

  String _newId(String prefix) =>
      '$prefix-${(++_ids).toRadixString(36)}-${_rng.nextInt(1 << 30).toRadixString(36)}';

  void handle(WebSocketChannel channel) {
    final conn = Connection(channel, this);
    connections.add(conn);
    channel.stream.listen(
      (data) {
        Map<String, dynamic> msg;
        try {
          msg = jsonDecode(data as String) as Map<String, dynamic>;
        } catch (_) {
          conn.error(ErrorCode.badRequest, 'Messages must be JSON objects');
          return;
        }
        try {
          _dispatch(conn, msg);
        } catch (e) {
          conn.error(
            ErrorCode.badRequest,
            'Malformed ${msg['type']}: $e',
            ref: msg['type'] as String?,
          );
        }
      },
      onDone: () => _closed(conn),
      onError: (_) => _closed(conn),
    );
  }

  void _closed(Connection conn) {
    conn.closed = true;
    connections.remove(conn);
    if (conn.testId != null && testClients[conn.testId] == conn) {
      testClients.remove(conn.testId);
    }
    final p = conn.player;
    final r = conn.room;
    if (p != null && r != null) r.disconnected(p);
  }

  void _dispatch(Connection conn, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == MsgType.hello) return _hello(conn, msg);
    if (type == MsgType.ping) {
      return conn.send({
        'type': MsgType.pong,
        't': msg['t'],
        'serverTime': config.now(),
      });
    }
    final p = conn.player;
    if (p == null) {
      return conn.error(ErrorCode.badRequest, 'Send hello first', ref: type);
    }

    switch (type) {
      case MsgType.roomCreate:
        _create(conn, p, msg);
      case MsgType.roomJoin:
        _join(conn, p, msg);
      case MsgType.roomLeave:
        _leave(conn);
      case MsgType.testResult:
        final id = msg['id'] as String?;
        final c = id == null ? null : _pendingTests.remove(id);
        c?.complete(msg);
      default:
        final room = conn.room;
        if (room == null) {
          return conn.error(
            ErrorCode.roomNotFound,
            'Join a room first',
            ref: type,
          );
        }
        final err = _roomCommand(room, p, type!, msg);
        if (err != null) conn.error(err, _describe(err), ref: type);
    }
  }

  String _describe(String code) => switch (code) {
    ErrorCode.roomNotFound => 'That room does not exist',
    ErrorCode.roomFull => 'That room is full',
    ErrorCode.seatTaken => 'That seat is taken',
    ErrorCode.notHost => 'Only the host can do that',
    ErrorCode.notSeated => 'Take a seat first',
    ErrorCode.notYourTurn => 'Not your turn',
    ErrorCode.illegalMove => 'Illegal move',
    ErrorCode.notPlaying => 'No match in progress',
    ErrorCode.notReady => 'Everyone must be ready',
    ErrorCode.rateLimited => 'Slow down a little',
    _ => 'Bad request',
  };

  String? _roomCommand(
    Room room,
    Player p,
    String type,
    Map<String, dynamic> msg,
  ) {
    switch (type) {
      case MsgType.roomSeat:
        final s = msg['seat'] as String?;
        return room.takeSeat(p, s == null ? null : Seat.parse(s));
      case MsgType.roomBot:
        return room.setBot(
          p,
          Seat.parse(msg['seat'] as String),
          add: msg['add'] as bool? ?? true,
        );
      case MsgType.roomReady:
        return room.setReady(p, msg['ready'] as bool? ?? true);
      case MsgType.roomStart:
        return room.requestStart(p);
      case MsgType.roomTimeControl:
        return room.setTimeControl(
          p,
          TimeControl.fromJson(msg['timeControl'] as Map<String, dynamic>),
        );
      case MsgType.roomRematch:
        return room.voteRematch(p);
      case MsgType.gameMove:
        return room.playMove(
          p,
          Move.fromJson(msg['move'] as Map<String, dynamic>),
        );
      case MsgType.gamePremove:
        final m = msg['move'];
        return room.setPremove(
          p,
          m == null ? null : Move.fromJson(m as Map<String, dynamic>),
        );
      case MsgType.gameResign:
        return room.resign(p);
      case MsgType.gameDraw:
        return room.draw(p, msg['action'] as String? ?? 'offer');
      case MsgType.chatSend:
        final q = msg['quick'] as String?;
        return room.sendChat(
          p,
          quick: q == null ? null : QuickChat.byCode(q),
          text: (msg['text'] as String?)?.substring(
            0,
            min(chatMaxLength, (msg['text'] as String).length),
          ),
          scope: msg['scope'] as String? ?? (q != null ? 'team' : 'room'),
        );
      default:
        return ErrorCode.badRequest;
    }
  }

  void _hello(Connection conn, Map<String, dynamic> msg) {
    final v = msg['v'] as int? ?? 0;
    if (v != protocolVersion) {
      conn.error(
        ErrorCode.badRequest,
        'Protocol version $v is not supported (server speaks $protocolVersion)',
      );
      return;
    }
    final name = _cleanName(msg['name'] as String? ?? 'Player');
    final platform = (msg['platform'] as String? ?? 'unknown').toLowerCase();
    final testId = msg['testId'] as String?;
    if (config.testMode && testId != null) {
      conn.testId = testId;
      testClients[testId] = conn;
    }

    final token = msg['resumeToken'] as String?;
    final resumed = token == null ? null : _resumable[token];
    if (resumed != null &&
        resumed.$1.find(resumed.$2.id) != null &&
        rooms[resumed.$1.code] == resumed.$1) {
      final (room, player) = resumed;
      conn.player = player;
      conn.room = room;
      player.name = name;
      conn.send(_welcome(player, room.code));
      room.reconnected(player, conn.send);
      return;
    }

    final player = Player(
      id: _newId('p'),
      name: name,
      platform: platform,
      resumeToken: _newId('r'),
    )..send = conn.send;
    conn.player = player;
    conn.send(_welcome(player, null));
  }

  Map<String, dynamic> _welcome(Player p, String? roomCode) => {
    'type': MsgType.welcome,
    'v': protocolVersion,
    'playerId': p.id,
    'resumeToken': p.resumeToken,
    'room': roomCode,
    'serverTime': config.now(),
    'testMode': config.testMode,
  };

  String _cleanName(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return 'Player';
    return t.length > 24 ? t.substring(0, 24) : t;
  }

  void _create(Connection conn, Player p, Map<String, dynamic> msg) {
    _leave(conn);
    final requested = msg['code'] as String?;
    var code = _newCode();
    if (config.testMode && requested != null && requested.isNotEmpty) {
      code = requested.toUpperCase();
      final existing = rooms[code];
      if (existing != null) {
        // Fixed test codes are reusable: joining an existing test room.
        _join(conn, p, {'code': code});
        return;
      }
    }
    final tcJson = msg['timeControl'];
    final room = Room(
      code: code,
      hostId: p.id,
      config: config,
      timeControl: tcJson == null
          ? TimeControl.blitz3
          : TimeControl.fromJson(tcJson as Map<String, dynamic>),
      onEmpty: _roomEmpty,
    );
    rooms[code] = room;
    conn.room = room;
    _resumable[p.resumeToken] = (room, p);
    room.addPlayer(p);
    if (msg['fillBots'] == true) room.fillBots();
  }

  void _join(Connection conn, Player p, Map<String, dynamic> msg) {
    final code = (msg['code'] as String? ?? '').trim().toUpperCase();
    final room = rooms[code];
    if (room == null) {
      return conn.error(
        ErrorCode.roomNotFound,
        _describe(ErrorCode.roomNotFound),
        ref: MsgType.roomJoin,
      );
    }
    if (conn.room == room) return room.broadcastRoom();
    _leave(conn);
    conn.room = room;
    _resumable[p.resumeToken] = (room, p);
    room.addPlayer(p, spectate: msg['spectate'] == true);
  }

  void _leave(Connection conn) {
    final room = conn.room;
    final p = conn.player;
    if (room == null || p == null) return;
    conn.room = null;
    _resumable.remove(p.resumeToken);
    room.removePlayer(p.id);
    conn.send({'type': MsgType.roomState, 'room': null});
  }

  void _roomEmpty(Room room) {
    if (rooms[room.code] == room) {
      rooms.remove(room.code);
      room.dispose();
      _resumable.removeWhere((_, v) => v.$1 == room);
    }
  }

  // ---------------------------------------------------------------------------
  // Test channel
  // ---------------------------------------------------------------------------

  /// Sends a command to a test-registered client and waits for its result.
  Future<Map<String, dynamic>> testCommand(
    String testId,
    Map<String, dynamic> command, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final conn = testClients[testId];
    if (conn == null) throw StateError('no test client "$testId"');
    final id = _newId('t');
    final completer = Completer<Map<String, dynamic>>();
    _pendingTests[id] = completer;
    conn.send({'type': MsgType.testCommand, 'id': id, ...command});
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _pendingTests.remove(id);
      throw StateError(
        'test client "$testId" did not answer ${command['cmd']} within ${timeout.inSeconds}s',
      );
    }
  }

  List<Map<String, dynamic>> testClientList() => [
    for (final e in testClients.entries)
      {
        'testId': e.key,
        'playerId': e.value.player?.id,
        'name': e.value.player?.name,
        'platform': e.value.player?.platform,
        'room': e.value.room?.code,
        'seat': e.value.player?.seat?.id,
      },
  ];

  Map<String, dynamic>? roomJson(String code) {
    final r = rooms[code.toUpperCase()];
    if (r == null) return null;
    return {
      'room': r.state().toJson(),
      'game': r.gameState()?.toJson(),
      'bpgn': r.match != null && r.match!.isOver ? r.bpgn() : null,
    };
  }

  void dispose() {
    for (final r in rooms.values) {
      r.dispose();
    }
    for (final c in connections.toList()) {
      c.channel.sink.close();
    }
  }
}
