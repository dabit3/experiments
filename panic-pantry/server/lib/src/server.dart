import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:panic_pantry_core/panic_pantry_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'room.dart';

/// One WebSocket connection.
class _Conn {
  _Conn(this.channel);

  final WebSocketChannel channel;
  Player? player;
  Room? room;

  void send(Map<String, dynamic> msg) {
    try {
      channel.sink.add(jsonEncode(msg));
    } catch (_) {
      // Socket already closed; the disconnect handler cleans up.
    }
  }

  void error(String code, String message) => send({'type': Msg.error, 'code': code, 'message': message});
}

/// Authoritative Panic Pantry server: rooms, lobbies, bots, tick loop and the
/// HTTP test harness used by the cross-platform automated match.
class PanicPantryServer {
  PanicPantryServer({int? seed, this.log = _defaultLog}) : _rng = math.Random(seed);

  final math.Random _rng;
  final void Function(String) log;
  final Map<String, Room> rooms = {};
  final Set<_Conn> _conns = {};

  /// Players by resume token (kept while their room exists).
  final Map<String, (Room, Player)> _byToken = {};

  HttpServer? _http;

  static void _defaultLog(String s) => stdout.writeln('[server] $s');

  Future<HttpServer> serve({InternetAddress? address, int port = kDefaultPort}) async {
    final router = Router()
      ..get('/health', (Request r) => _json({'ok': true, 'rooms': rooms.length, 'protocol': kProtocolVersion}))
      ..get('/levels', (Request r) => _json({'levels': kLevels.map(_levelJson).toList()}))
      ..get('/ws', webSocketHandler(_onSocket))
      ..get('/test/rooms', (Request r) => _json({'rooms': rooms.values.map((x) => x.toJson()).toList()}))
      ..post('/test/rooms', _testCreateRoom)
      ..get('/test/rooms/<code>', (Request r, String code) {
        final room = rooms[code.toUpperCase()];
        if (room == null) return _json({'error': 'no such room'}, 404);
        return _json({
          ...room.toJson(),
          'reports': {for (final p in room.players.values) p.id: p.lastReport},
          'state': room.state?.toSnapshot(includeEvents: false),
        });
      })
      ..post('/test/rooms/<code>/start', (Request r, String code) {
        final room = rooms[code.toUpperCase()];
        if (room == null) return _json({'error': 'no such room'}, 404);
        room.start();
        return _json(room.toJson());
      })
      ..post('/test/rooms/<code>/rematch', (Request r, String code) {
        final room = rooms[code.toUpperCase()];
        if (room == null) return _json({'error': 'no such room'}, 404);
        room.rematch();
        return _json(room.toJson());
      })
      ..post('/test/rooms/<code>/bots', (Request r, String code) async {
        final room = rooms[code.toUpperCase()];
        if (room == null) return _json({'error': 'no such room'}, 404);
        final body = await _body(r);
        final n = (body['count'] as num?)?.toInt() ?? 1;
        for (var i = 0; i < n; i++) {
          room.addBot();
        }
        _roomChanged(room);
        return _json(room.toJson());
      })
      ..post('/test/rooms/<code>/players/<id>/input', (Request r, String code, String id) async {
        // Scripted inputs. `via: "client"` (default) forwards them to the
        // client, which feeds them through its own input pipeline and sends
        // them back as normal `input` messages; `via: "server"` applies them
        // directly on consecutive ticks.
        final room = rooms[code.toUpperCase()];
        if (room == null) return _json({'error': 'no such room'}, 404);
        final body = await _body(r);
        final via = body['via'] as String? ?? 'client';
        final steps = (body['steps'] as List? ?? const []).cast<Map<String, dynamic>>();
        if (via == 'server') {
          final inputs = <ChefInput>[];
          for (final s in steps) {
            final input = ChefInput.fromJson(s);
            final ticks = (s['ticks'] as num?)?.toInt() ?? 1;
            for (var i = 0; i < ticks; i++) {
              inputs.add(i == 0 ? input : ChefInput(dx: input.dx, dy: input.dy, action: input.action));
            }
          }
          room.script(id, inputs);
          return _json({'queued': inputs.length});
        }
        final p = room.players[id];
        if (p == null) return _json({'error': 'no such player'}, 404);
        if (p.send == null) return _json({'error': 'player disconnected'}, 409);
        p.send!({'type': Msg.testInput, 'steps': steps});
        return _json({'forwarded': steps.length});
      })
      ..post('/test/rooms/<code>/players/<id>/command', (Request r, String code, String id) async {
        final room = rooms[code.toUpperCase()];
        if (room == null) return _json({'error': 'no such room'}, 404);
        final body = await _body(r);
        if (id == '*') {
          room.broadcast({'type': Msg.testCommand, ...body});
          return _json({'forwarded': room.players.values.where((p) => p.send != null).length});
        }
        final p = room.players[id];
        if (p == null) return _json({'error': 'no such player'}, 404);
        if (p.send == null) return _json({'error': 'player disconnected'}, 409);
        p.lastReport = null;
        p.send!({'type': Msg.testCommand, ...body});
        return _json({'forwarded': 1});
      })
      ..delete('/test/rooms/<code>', (Request r, String code) {
        final room = rooms.remove(code.toUpperCase());
        room?.dispose();
        return _json({'removed': room != null});
      });

    final handler = const Pipeline()
        .addMiddleware(_cors())
        .addMiddleware(logRequests(logger: (m, _) {}))
        .addHandler(router.call);
    _http = await shelf_io.serve(handler, address ?? InternetAddress.anyIPv4, port);
    log('listening on ws://${_http!.address.host}:${_http!.port}/ws');
    return _http!;
  }

  Future<void> close() async {
    for (final r in rooms.values) {
      r.dispose();
    }
    rooms.clear();
    for (final c in _conns.toList()) {
      await c.channel.sink.close();
    }
    await _http?.close(force: true);
  }

  Middleware _cors() =>
      (inner) => (req) async {
        const headers = {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        };
        if (req.method == 'OPTIONS') return Response.ok('', headers: headers);
        final res = await inner(req);
        return res.change(headers: headers);
      };

  static Response _json(Object body, [int status = 200]) =>
      Response(status, body: jsonEncode(body), headers: {'content-type': 'application/json'});

  static Future<Map<String, dynamic>> _body(Request r) async {
    final text = await r.readAsString();
    if (text.trim().isEmpty) return {};
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static Map<String, dynamic> _levelJson(LevelDef l) => {
    'id': l.id,
    'name': l.name,
    'tagline': l.tagline,
    'gimmick': l.gimmick,
    'roundSeconds': l.roundSeconds,
    'menu': l.menu.map((d) => d.name).toList(),
    'tutorial': l.tutorial,
  };

  Future<Response> _testCreateRoom(Request r) async {
    final body = await _body(r);
    final room = _createRoom(
      code: body['code'] as String?,
      seed: (body['seed'] as num?)?.toInt(),
      level: body['level'] as String?,
      speed: (body['speed'] as num?)?.toDouble(),
    );
    if (room == null) return _json({'error': 'room code taken'}, 409);
    final bots = (body['bots'] as num?)?.toInt() ?? 0;
    for (var i = 0; i < bots; i++) {
      room.addBot();
    }
    return _json(room.toJson());
  }

  Room? _createRoom({String? code, int? seed, String? level, double? speed}) {
    var c = code?.toUpperCase();
    if (c != null && rooms.containsKey(c)) return null;
    c ??= _freshCode();
    final room = Room(
      code: c,
      seed: seed ?? _rng.nextInt(1 << 30),
      level: levelById(level ?? 'corner-cafe'),
      onChange: _roomChanged,
      speed: (speed ?? 1).clamp(0.25, 20),
    );
    rooms[c] = room;
    log('room $c created (seed ${room.seed}, level ${room.level.id})');
    return room;
  }

  String _freshCode() {
    for (var i = 0; i < 1000; i++) {
      final c = makeRoomCode(_rng);
      if (!rooms.containsKey(c)) return c;
    }
    throw StateError('room codes exhausted');
  }

  void _roomChanged(Room room) {
    room.broadcast({'type': Msg.roomState, 'room': room.toJson()});
  }

  // --- WebSocket protocol -------------------------------------------------

  void _onSocket(WebSocketChannel channel, String? protocol) {
    final conn = _Conn(channel);
    _conns.add(conn);
    channel.stream.listen(
      (raw) {
        Map<String, dynamic> msg;
        try {
          msg = jsonDecode(raw as String) as Map<String, dynamic>;
        } catch (_) {
          conn.error('bad_json', 'Messages must be JSON objects');
          return;
        }
        try {
          _handle(conn, msg);
        } catch (e, st) {
          log('error handling ${msg['type']}: $e\n$st');
          conn.error('internal', '$e');
        }
      },
      onDone: () => _disconnect(conn),
      onError: (_) => _disconnect(conn),
      cancelOnError: true,
    );
  }

  void _disconnect(_Conn conn) {
    _conns.remove(conn);
    final p = conn.player;
    final room = conn.room;
    if (p == null || room == null) return;
    p.connected = false;
    p.send = null;
    room.state?.chefById(p.id)?.connected = false;
    if (room.inLobby && room.hostId == p.id) {
      room.hostId = room.players.values.where((x) => x.connected).map((x) => x.id).firstOrNull;
    }
    log('${p.name} disconnected from ${room.code}');
    _roomChanged(room);
    // Empty rooms linger a while so players can resume after a reconnect.
    if (room.isEmpty) {
      Timer(const Duration(minutes: 5), () {
        if (room.isEmpty && rooms[room.code] == room) {
          rooms.remove(room.code);
          room.dispose();
          for (final p in room.players.values) {
            _byToken.remove(p.token);
          }
          log('room ${room.code} expired');
        }
      });
    }
  }

  void _handle(_Conn conn, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    switch (type) {
      case Msg.hello:
        _hello(conn, msg);
      case Msg.ping:
        conn.send({'type': Msg.pong, 't': msg['t'], 'serverTime': DateTime.now().millisecondsSinceEpoch});
      case Msg.roomCreate:
        _requirePlayer(conn, (p) {
          _leaveRoom(conn);
          final room = _createRoom(
            code: msg['code'] as String?,
            seed: (msg['seed'] as num?)?.toInt(),
            level: msg['level'] as String?,
          );
          if (room == null) return conn.error('code_taken', 'That room code is already in use');
          _join(conn, room, p.name, p.platform, token: p.token);
        });
      case Msg.roomJoin:
        _requirePlayer(conn, (p) {
          final code = (msg['code'] as String? ?? '').trim().toUpperCase();
          final room = rooms[code];
          if (room == null) return conn.error('no_room', 'No kitchen with code $code');
          if (conn.room == room) return _roomChanged(room);
          _leaveRoom(conn);
          if (!room.inLobby) return conn.error('in_progress', 'That match is already in progress');
          if (room.occupancy >= Room.maxPlayers) return conn.error('full', 'That kitchen is full');
          _join(conn, room, p.name, p.platform, token: p.token);
        });
      case Msg.roomLeave:
        _leaveRoom(conn);
        conn.send({'type': Msg.roomState, 'room': null});
      case Msg.roomReady:
        _requireRoom(conn, (room, p) {
          p.ready = msg['ready'] != false;
          _roomChanged(room);
        });
      case Msg.roomSetLevel:
        _requireHost(conn, (room, p) {
          room.setLevel(msg['level'] as String? ?? room.level.id);
          _roomChanged(room);
        });
      case Msg.roomAddBot:
        _requireHost(conn, (room, p) {
          if (!room.addBot()) return conn.error('full', 'No free seats for a bot');
          _roomChanged(room);
        });
      case Msg.roomRemoveBot:
        _requireHost(conn, (room, p) {
          room.removeBot(msg['id'] as String?);
          _roomChanged(room);
        });
      case Msg.roomStart:
        _requireHost(conn, (room, p) {
          if (!room.inLobby) return conn.error('in_progress', 'Match already running');
          if (!room.everyoneReady && msg['force'] != true) {
            return conn.error('not_ready', 'Everyone must be ready first');
          }
          log('room ${room.code} starting ${room.level.id} with ${room.occupancy} chefs');
          room.start();
        });
      case Msg.roomRematch:
        _requireHost(conn, (room, p) {
          room.rematch();
        });
      case Msg.input:
        _requireRoom(conn, (room, p) => room.input(p.id, ChefInput.fromJson(msg)));
      case Msg.testReport:
        _requireRoom(conn, (room, p) => p.lastReport = {...msg, 'receivedAt': DateTime.now().toIso8601String()});
      default:
        conn.error('unknown_type', 'Unknown message type "$type"');
    }
  }

  void _hello(_Conn conn, Map<String, dynamic> msg) {
    final version = (msg['protocol'] as num?)?.toInt() ?? kProtocolVersion;
    if (version != kProtocolVersion) {
      conn.error('protocol', 'Server speaks protocol $kProtocolVersion, client sent $version');
    }
    final name = _cleanName(msg['name'] as String?);
    final platform = (msg['platform'] as String? ?? 'unknown').toLowerCase();
    final token = msg['token'] as String?;

    // Resume: same token reattaches to the existing seat, even mid-match.
    final existing = token == null ? null : _byToken[token];
    if (existing != null) {
      final (room, player) = existing;
      if (rooms[room.code] == room) {
        player.connected = true;
        player.send = conn.send;
        conn.player = player;
        conn.room = room;
        room.state?.chefById(player.id)?.connected = true;
        room.hostId ??= player.id;
        conn.send(_welcome(player, resumed: true));
        _roomChanged(room);
        if (room.state != null) conn.send({'type': Msg.snapshot, 'code': room.code, 'state': room.state!.toSnapshot()});
        if (room.lastResults != null) {
          conn.send({
            'type': Msg.results,
            'code': room.code,
            'results': room.lastResults,
            'seed': room.seed,
            'match': room.matchNumber,
          });
        }
        log('${player.name} resumed ${room.code}');
        return;
      }
    }
    final p = Player(
      id: 'p${_rng.nextInt(1 << 30).toRadixString(36)}',
      token: token ?? _rng.nextInt(1 << 30).toRadixString(36) + _rng.nextInt(1 << 30).toRadixString(36),
      name: name,
      slot: -1,
      platform: platform,
    );
    conn.player = p;
    conn.send(_welcome(p, resumed: false));
  }

  Map<String, dynamic> _welcome(Player p, {required bool resumed}) => {
    'type': Msg.welcome,
    'playerId': p.id,
    'token': p.token,
    'name': p.name,
    'protocol': kProtocolVersion,
    'resumed': resumed,
    'tickSeconds': Rules.tickSeconds,
    'levels': kLevels.map(_levelJson).toList(),
  };

  void _join(_Conn conn, Room room, String name, String platform, {required String token}) {
    final id = conn.player!.id;
    final p = room.addPlayer(id: id, token: token, name: name, platform: platform);
    if (p == null) return conn.error('full', 'That kitchen is full');
    p.send = conn.send;
    conn.player = p;
    conn.room = room;
    _byToken[token] = (room, p);
    log('$name joined ${room.code} (${room.occupancy}/${Room.maxPlayers})');
    _roomChanged(room);
  }

  void _leaveRoom(_Conn conn) {
    final room = conn.room;
    final p = conn.player;
    if (room == null || p == null) return;
    room.removePlayer(p.id);
    _byToken.remove(p.token);
    conn.room = null;
    conn.player = Player(id: p.id, token: p.token, name: p.name, slot: -1, platform: p.platform);
    log('${p.name} left ${room.code}');
    if (room.players.isEmpty) {
      rooms.remove(room.code);
      room.dispose();
      log('room ${room.code} closed');
    } else {
      _roomChanged(room);
    }
  }

  void _requirePlayer(_Conn conn, void Function(Player p) f) {
    final p = conn.player;
    if (p == null) return conn.error('no_hello', 'Send hello first');
    f(p);
  }

  void _requireRoom(_Conn conn, void Function(Room room, Player p) f) {
    final p = conn.player;
    final room = conn.room;
    if (p == null || room == null) return conn.error('no_room', 'Join a kitchen first');
    f(room, p);
  }

  void _requireHost(_Conn conn, void Function(Room room, Player p) f) {
    _requireRoom(conn, (room, p) {
      if (room.hostId != p.id) return conn.error('not_host', 'Only the host can do that');
      f(room, p);
    });
  }

  static String _cleanName(String? raw) {
    final n = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return 'Chef';
    return n.length > 16 ? n.substring(0, 16) : n;
  }
}
