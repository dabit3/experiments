import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:nitro_core/nitro_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'room.dart';

class ServerConfig {
  const ServerConfig({
    this.host = '0.0.0.0',
    this.port = 8787,
    this.seed,
    this.allowCustomCodes = true,
    this.verbose = false,
    this.tickIntervalMs = 1000 ~/ ticksPerSecond,
    this.resultsDelayMs = 9000,
  });

  final String host;
  final int port;

  /// Fixed seed for deterministic room codes and race seeds (tests).
  final int? seed;
  final bool allowCustomCodes;
  final bool verbose;
  final int tickIntervalMs;
  final int resultsDelayMs;
}

/// A WebSocket session for one connected client.
class Session {
  Session(this.channel, this.server);
  final WebSocketChannel channel;
  final NitroServer server;
  Player? player;
  Room? room;
  bool closed = false;

  void send(Map<String, dynamic> msg) {
    if (closed) return;
    try {
      channel.sink.add(jsonEncode(msg));
    } catch (_) {
      closed = true;
    }
  }

  void error(String code, String message) => send({'type': Msg.error, 'code': code, 'message': message});
}

class NitroServer {
  NitroServer(this.config)
      : _rng = Rng(config.seed ?? DateTime.now().millisecondsSinceEpoch & 0x7fffffff),
        _seed = config.seed ?? DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  final ServerConfig config;
  final Rng _rng;
  final int _seed;
  final Map<String, Room> rooms = {};
  final Map<String, Player> playersById = {};
  final Set<Session> sessions = {};
  HttpServer? _http;
  Timer? _ticker;
  final _startedAt = DateTime.now();
  int _roomsCreated = 0;

  int now() => DateTime.now().millisecondsSinceEpoch;

  /// Bound port (useful when the config asked for port 0).
  int get port => _http?.port ?? config.port;

  void log(String s) {
    if (config.verbose) {
      stdout.writeln('[${DateTime.now().toIso8601String()}] $s');
    }
  }

  Future<void> start() async {
    final router = Router()
      ..get('/', (Request r) => _json({'name': 'Nitro Tots server', 'protocol': protocolVersion, 'rooms': rooms.length}))
      ..get('/health', (Request r) => _json({'ok': true, 'uptimeMs': DateTime.now().difference(_startedAt).inMilliseconds}))
      ..get('/rooms', (Request r) => _json({'rooms': [for (final room in rooms.values) room.inspectJson()]}))
      ..get('/rooms/<code>', (Request r, String code) {
        final room = rooms[code.toUpperCase()];
        if (room == null) return Response.notFound(jsonEncode({'error': 'no_such_room'}), headers: _jsonHeaders);
        return _json(room.inspectJson());
      })
      ..get('/ws', webSocketHandler((WebSocketChannel channel, String? protocol) => _onConnect(channel)));

    final handler = const Pipeline().addMiddleware(_cors()).addHandler(router.call);
    _http = await shelf_io.serve(handler, config.host, config.port);
    _ticker = Timer.periodic(Duration(milliseconds: config.tickIntervalMs), (_) => _tick());
    stdout.writeln('Nitro Tots server listening on ws://${config.host}:$port/ws (seed=$_seed)');
  }

  Future<void> stop() async {
    _ticker?.cancel();
    for (final s in sessions.toList()) {
      await s.channel.sink.close();
    }
    await _http?.close(force: true);
  }

  static const _jsonHeaders = {'content-type': 'application/json'};

  Response _json(Object body) => Response.ok(jsonEncode(body), headers: _jsonHeaders);

  Middleware _cors() => (inner) => (req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final res = await inner(req);
        return res.change(headers: _corsHeaders);
      };

  static const _corsHeaders = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, OPTIONS',
    'access-control-allow-headers': 'content-type',
  };

  void _tick() {
    for (final room in rooms.values.toList()) {
      room.tick();
    }
    // Reap rooms nobody has touched for ten minutes.
    final cutoff = now() - 10 * 60 * 1000;
    for (final room in rooms.values.toList()) {
      if (room.isEmpty && room.lastActivity < cutoff) rooms.remove(room.code);
    }
  }

  // ---------------------------------------------------------------------------
  // Connections

  void _onConnect(WebSocketChannel channel) {
    final session = Session(channel, this);
    sessions.add(session);
    log('connect (${sessions.length} sessions)');
    channel.stream.listen(
      (data) {
        Map<String, dynamic> msg;
        try {
          msg = jsonDecode(data as String) as Map<String, dynamic>;
        } catch (_) {
          session.error('bad_json', 'Message was not a JSON object.');
          return;
        }
        try {
          _handle(session, msg);
        } catch (e, st) {
          log('handler error: $e\n$st');
          session.error('server_error', '$e');
        }
      },
      onDone: () => _onDisconnect(session),
      onError: (_) => _onDisconnect(session),
      cancelOnError: true,
    );
  }

  void _onDisconnect(Session session) {
    if (session.closed) return;
    session.closed = true;
    sessions.remove(session);
    final p = session.player;
    final room = session.room;
    if (p != null) {
      p.connected = false;
      p.send = (_) {};
      if (room != null) {
        log('player ${p.name} disconnected from ${room.code}');
        room.broadcastRoomState();
        // Give the player two minutes to resume before they're dropped.
        Timer(const Duration(minutes: 2), () {
          if (!p.connected && room.playerById(p.id) != null) {
            room.removePlayer(p.id);
            playersById.remove(p.id);
          }
        });
      }
    }
  }

  String _newId() => List.generate(12, (_) => _alphabet[_rng.nextInt(_alphabet.length)]).join();

  String _newCode() {
    for (var attempt = 0; attempt < 100; attempt++) {
      final code = List.generate(4, (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)]).join();
      if (!rooms.containsKey(code)) return code;
    }
    return 'R${(_roomsCreated++).toRadixString(36).toUpperCase()}';
  }

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ';

  void _handle(Session s, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == Msg.ping) {
      s.send({'type': Msg.pong, 't': msg['t'], 'serverTime': now()});
      return;
    }
    if (type == Msg.hello) {
      _hello(s, msg);
      return;
    }
    if (type == Msg.resume) {
      _resume(s, msg);
      return;
    }
    final p = s.player;
    if (p == null) {
      s.error('not_identified', 'Send hello first.');
      return;
    }
    switch (type) {
      case Msg.createRoom:
        _createRoom(s, p, msg);
      case Msg.joinRoom:
        _joinRoom(s, p, msg);
      case Msg.leaveRoom:
        _leaveRoom(s, p);
      case Msg.setReady:
        s.room?.setReady(p.id, msg['ready'] == true);
      case Msg.updateProfile:
        p.name = _cleanName(msg['name'] as String? ?? p.name);
        s.room?.updateProfile(p.id, msg);
        if (s.room == null) {
          if (msg['character'] is String) p.characterId = msg['character'] as String;
          if (msg['kart'] is String) p.kartId = msg['kart'] as String;
        }
      case Msg.updateSettings:
        s.room?.updateSettings(p.id, (msg['settings'] as Map?)?.cast<String, dynamic>() ?? const {});
      case Msg.startMatch:
        final err = s.room == null ? 'no_room' : s.room!.startMatch(p.id);
        if (err != null) s.error(err, _describe(err));
      case Msg.nextRace:
        final err = s.room == null ? 'no_room' : s.room!.nextRace(p.id);
        if (err != null) s.error(err, _describe(err));
      case Msg.input:
        s.room?.handleInput(p.id, msg);
      case Msg.testReport:
        s.room?.recordTestReport(p.id, msg);
        log('test report from ${p.name}/${p.platform}: ${msg['hash']}');
      default:
        s.error('unknown_type', 'Unknown message type "$type".');
    }
  }

  String _describe(String code) => switch (code) {
        'not_host' => 'Only the host can do that.',
        'already_racing' => 'A race is already running.',
        'room_full' => 'That room is full.',
        'match_in_progress' => 'That room is mid-match. Try again after the race.',
        'no_such_room' => 'No room with that code.',
        'no_room' => 'You are not in a room.',
        'not_in_results' => 'No results to skip.',
        _ => code,
      };

  String _cleanName(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return 'Racer';
    return t.substring(0, math.min(14, t.length));
  }

  void _hello(Session s, Map<String, dynamic> msg) {
    final v = (msg['v'] as num?)?.toInt();
    if (v != protocolVersion) {
      s.error('bad_version', 'Client protocol $v does not match server protocol $protocolVersion.');
      return;
    }
    final p = Player(
      id: _newId(),
      token: _newId(),
      name: _cleanName(msg['name'] as String? ?? 'Racer'),
      characterId: characters.any((c) => c.id == msg['character']) ? msg['character'] as String : characters.first.id,
      kartId: karts.any((k) => k.id == msg['kart']) ? msg['kart'] as String : karts.first.id,
      platform: (msg['platform'] as String?) ?? 'unknown',
      send: s.send,
    );
    playersById[p.id] = p;
    s.player = p;
    s.send({'type': Msg.welcome, 'playerId': p.id, 'token': p.token, 'serverTime': now(), 'v': protocolVersion});
    log('hello ${p.name} (${p.platform})');
  }

  void _resume(Session s, Map<String, dynamic> msg) {
    final p = playersById[msg['playerId']];
    if (p == null || p.token != msg['token']) {
      s.error('resume_failed', 'Session expired. Please rejoin.');
      return;
    }
    p.connected = true;
    p.send = s.send;
    s.player = p;
    final room = rooms.values.where((r) => r.playerById(p.id) != null).firstOrNull;
    s.room = room;
    s.send({'type': Msg.welcome, 'playerId': p.id, 'token': p.token, 'serverTime': now(), 'v': protocolVersion, 'resumed': true});
    if (room != null) {
      s.send(room.roomStateJson());
      if (room.status == RoomStatus.racing && room.sim != null) {
        s.send(room.matchStartJson());
      }
      room.broadcastRoomState();
    }
    log('resume ${p.name}');
  }

  void _createRoom(Session s, Player p, Map<String, dynamic> msg) {
    if (s.room != null) _leaveRoom(s, p);
    var code = _newCode();
    final wanted = (msg['code'] as String?)?.toUpperCase();
    if (wanted != null && wanted.isNotEmpty && config.allowCustomCodes) {
      if (rooms.containsKey(wanted)) {
        // Joining an existing custom-coded room is friendlier than failing.
        _joinRoom(s, p, {'code': wanted});
        return;
      }
      code = wanted;
    }
    final settings = RoomSettings.fromJson((msg['settings'] as Map?)?.cast<String, dynamic>() ?? const {});
    final room = Room(
      code: code,
      seed: config.seed != null ? config.seed! + rooms.length : _rng.nextInt(1 << 30),
      settings: settings,
      now: now,
      onEmpty: (r) => rooms.remove(r.code),
      resultsDelayMs: config.resultsDelayMs,
    )..createdAt = now();
    rooms[code] = room;
    _roomsCreated++;
    room.addPlayer(p);
    s.room = room;
    log('room $code created by ${p.name}');
  }

  void _joinRoom(Session s, Player p, Map<String, dynamic> msg) {
    final code = (msg['code'] as String? ?? '').toUpperCase().trim();
    final room = rooms[code];
    if (room == null) {
      s.error('no_such_room', _describe('no_such_room'));
      return;
    }
    if (s.room != null && s.room != room) _leaveRoom(s, p);
    final err = room.addPlayer(p);
    if (err != null) {
      s.error(err, _describe(err));
      return;
    }
    s.room = room;
    log('${p.name} joined $code (${room.players.length} players)');
  }

  void _leaveRoom(Session s, Player p) {
    final room = s.room;
    if (room == null) return;
    room.removePlayer(p.id);
    s.room = null;
  }
}
