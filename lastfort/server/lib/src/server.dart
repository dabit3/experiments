import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:lastfort_core/lastfort_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'client.dart';
import 'room.dart';

const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// The Lastfort match server: one process, many rooms.
class LastfortServer {
  LastfortServer({
    this.webRoot,
    this.verbose = false,
    this.defaultFast = false,
    int? seed,
  }) : _rng = math.Random(seed);

  final String? webRoot;
  final bool verbose;
  final bool defaultFast;
  final math.Random _rng;
  final Map<String, Room> rooms = {};

  /// room code -> platform -> latest client report. Kept after the room is
  /// disposed so the test harness can read results at its own pace.
  final Map<String, Map<String, Object?>> reports = {};

  void _storeReport(Room room, Map<String, Object?> report) {
    final byPlatform = reports.putIfAbsent(room.code, () => {});
    byPlatform['${report['platform']}'] = report;
    _log(
        'report ${room.code} ${report['platform']} digest=${report['digest']}');
  }

  final Map<String, Client> clients = {}; // token -> client
  HttpServer? _http;
  final DateTime startedAt = DateTime.now();

  int get port => _http?.port ?? 0;

  Future<void> start({String host = '0.0.0.0', int port = 8787}) async {
    final router = Cascade()
        .add(_apiHandler)
        .add(webRoot == null
            ? (Request r) => Response.notFound('not found')
            : createStaticHandler(webRoot!, defaultDocument: 'index.html'))
        .handler;
    final pipeline = const Pipeline().addMiddleware(_cors).addHandler(router);
    _http = await shelf_io.serve(pipeline, host, port);
    _log('lastfort server listening on ws://$host:${_http!.port}/ws');
  }

  Future<void> stop() async {
    for (final r in rooms.values.toList()) {
      r.dispose();
    }
    await _http?.close(force: true);
  }

  Middleware get _cors => (inner) => (req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final res = await inner(req);
        return res.change(headers: _corsHeaders);
      };

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  Future<Response> _apiHandler(Request req) async {
    final path = req.url.path;
    if (path == 'ws') {
      return webSocketHandler((WebSocketChannel ws, String? protocol) {
        _onConnection(ws);
      })(req);
    }
    if (path == 'health') {
      return Response.ok(
        jsonEncode({
          'ok': true,
          'version': Protocol.version,
          'rooms': rooms.length,
          'clients': clients.values.where((c) => c.connected).length,
          'uptimeSec': DateTime.now().difference(startedAt).inSeconds,
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    if (path == 'rooms') {
      return Response.ok(
        jsonEncode({
          'rooms': [for (final r in rooms.values) r.roomStateJson()],
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.startsWith('rooms/') && path.endsWith('/reports')) {
      final code = path.split('/')[1].toUpperCase();
      return Response.ok(
        jsonEncode({
          'code': code,
          'reports': reports[code] ?? const <String, Object?>{},
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.startsWith('rooms/') && path.endsWith('/summary')) {
      final code = path.split('/')[1].toUpperCase();
      final r = rooms[code];
      if (r == null) return Response.notFound('{"error":"room_not_found"}');
      return Response.ok(
        jsonEncode({
          'code': code,
          'phase': r.sim?.phase.name,
          'summary': r.sim?.summary
        }),
        headers: {'content-type': 'application/json'},
      );
    }
    return Response.notFound('not found');
  }

  void _onConnection(WebSocketChannel ws) {
    Client? client;
    ws.stream.listen(
      (dynamic raw) {
        Map<String, Object?> msg;
        try {
          msg = (jsonDecode(raw as String) as Map).cast<String, Object?>();
        } catch (_) {
          ws.sink.add(jsonEncode(
              {'t': Protocol.error, 'code': ProtocolError.badMessage}));
          return;
        }
        final type = msg['t'];
        if (client == null) {
          if (type != Protocol.hello) {
            ws.sink.add(jsonEncode({
              't': Protocol.error,
              'code': ProtocolError.badMessage,
              'message': 'hello first',
            }));
            return;
          }
          client = _hello(ws, msg);
          return;
        }
        try {
          _dispatch(client!, msg);
        } catch (e, st) {
          _log('dispatch error: $e\n$st');
          client!.error(ProtocolError.badMessage, '$e');
        }
      },
      onDone: () {
        final c = client;
        if (c == null || c.channel != ws) return;
        c.channel = null;
        c.room?.leave(c, graceful: false);
        _log('disconnected ${c.name} (${c.token.substring(0, 6)})');
      },
      onError: (Object e) {
        final c = client;
        if (c == null || c.channel != ws) return;
        c.channel = null;
        c.room?.leave(c, graceful: false);
      },
    );
  }

  Client _hello(WebSocketChannel ws, Map<String, Object?> msg) {
    final version = (msg['v'] as num? ?? 0).toInt();
    final requested = msg['token'] as String?;
    Client c;
    if (requested != null && clients.containsKey(requested)) {
      c = clients[requested]!;
      final old = c.channel;
      if (old != null) {
        c.error(
          ProtocolError.superseded,
          'This session was resumed from another connection',
        );
      }
      // Rebind before closing: the old socket's onDone may fire synchronously
      // and must see that it no longer owns this client.
      c.channel = ws;
      old?.sink.close();
    } else {
      final token =
          requested != null && requested.length >= 8 ? requested : _newToken();
      c = Client(ws, token);
      clients[token] = c;
    }
    c.name = _cleanName(msg['name'] as String? ?? c.name);
    c.platform = (msg['platform'] as String? ?? 'unknown').toLowerCase();
    final ld = msg['ld'];
    if (ld is Map<String, Object?>) c.loadout = Loadout.fromJson(ld);
    c.helloDone = true;
    c.send({
      't': Protocol.welcome,
      'v': Protocol.version,
      'token': c.token,
      'name': c.name,
      'serverTime': DateTime.now().millisecondsSinceEpoch,
      if (version != Protocol.version) 'warning': ProtocolError.versionMismatch,
    });
    final room = c.room;
    if (room != null) {
      final resumed = room.rejoin(c);
      if (resumed) {
        c.send(room.matchStartJsonFor(c.token));
        c.send({'t': 'you', 'id': room.idFor(c.token)});
        if (room.ended) {
          c.send({'t': Protocol.matchEnd, 'summary': room.sim!.summary});
        }
      }
    }
    _log('hello ${c.name} [${c.platform}] token=${c.token.substring(0, 6)}');
    return c;
  }

  void _dispatch(Client c, Map<String, Object?> msg) {
    final type = msg['t'] as String? ?? '';
    switch (type) {
      case Protocol.hello:
        c.name = _cleanName(msg['name'] as String? ?? c.name);
        c.room?.broadcastRoomState();
      case Protocol.ping:
        c.send({
          't': Protocol.pong,
          'c': msg['c'],
          'serverTime': DateTime.now().millisecondsSinceEpoch,
          'tick': c.room?.sim?.tick,
        });
      case Protocol.createRoom:
        if (c.room != null) c.room!.leave(c);
        final mode = SquadMode.parse(msg['mode'] as String? ?? 'squads');
        final fast = msg['fast'] as bool? ?? defaultFast;
        final seed = (msg['seed'] as num?)?.toInt() ?? _rng.nextInt(1 << 30);
        var code = (msg['code'] as String? ?? '').toUpperCase();
        if (code.isNotEmpty && rooms.containsKey(code)) {
          final existing = rooms[code]!;
          if (existing.inLobby && existing.members.isEmpty) {
            existing.dispose();
          } else {
            existing.join(c);
            return;
          }
        }
        if (code.isEmpty || !RegExp(r'^[A-Z0-9]{4,8}$').hasMatch(code)) {
          code = _newCode();
        }
        final room = Room(
          code: code,
          mode: mode,
          fast: fast,
          seed: seed,
          hostToken: c.token,
          onEmpty: (r) => rooms.remove(r.code),
          onReport: _storeReport,
        );
        rooms[code] = room;
        room.join(c);
        _log(
            'room $code created by ${c.name} (mode=${mode.name} fast=$fast seed=$seed)');
      case Protocol.joinRoom:
        final code = (msg['code'] as String? ?? '').toUpperCase().trim();
        final room = rooms[code];
        if (room == null) {
          c.error(ProtocolError.roomNotFound, 'No room with code $code');
          return;
        }
        if (c.room == room) {
          room.broadcastRoomState();
          return;
        }
        if (c.room != null) c.room!.leave(c);
        if (!room.inLobby) {
          c.error(ProtocolError.matchInProgress, 'Match already started');
          return;
        }
        if (room.isFull) {
          c.error(ProtocolError.roomFull, 'Room is full');
          return;
        }
        room.join(c);
        _log(
            '${c.name} [${c.platform}] joined $code (${room.humanCount} humans)');
      case Protocol.leaveRoom:
        c.room?.leave(c);
      case Protocol.ready:
        final room = _requireRoom(c);
        room?.setReady(c, msg['ready'] != false);
      case Protocol.setLoadout:
        final ld = msg['ld'];
        if (ld is Map<String, Object?>) c.loadout = Loadout.fromJson(ld);
        c.room?.broadcastRoomState();
      case 'setMode':
        final room = _requireRoom(c);
        if (room == null) return;
        if (room.hostToken != c.token) {
          c.error(ProtocolError.notHost, 'Only the host can change the mode');
          return;
        }
        room.setMode(SquadMode.parse(msg['mode'] as String? ?? 'squads'));
      case 'returnToLobby':
        final room = _requireRoom(c);
        if (room == null) return;
        if (room.hostToken != c.token) {
          c.error(ProtocolError.notHost, 'Only the host can reset the room');
          return;
        }
        room.resetToLobby();
      case Protocol.startMatch:
        final room = _requireRoom(c);
        if (room == null) return;
        if (room.hostToken != c.token) {
          c.error(ProtocolError.notHost, 'Only the host can start');
          return;
        }
        room.scheduleStart(
          fill: (msg['fill'] as num?)?.toInt(),
          countdownMs: (msg['countdownMs'] as num? ?? 3000).toInt(),
        );
      case Protocol.input:
        final room = _requireRoom(c, quiet: true);
        if (room == null || room.sim == null) return;
        final f = msg['f'];
        if (f is Map<String, Object?>) {
          room.queueInput(c, InputFrame.fromJson(f));
        }
      case Protocol.testControl:
        final room = _requireRoom(c);
        if (room == null) return;
        final ack = room.testControl(c, msg);
        c.send({'t': Protocol.testAck, 'id': msg['id'], ...ack});
      default:
        c.error(ProtocolError.badMessage, 'Unknown message type "$type"');
    }
  }

  Room? _requireRoom(Client c, {bool quiet = false}) {
    final r = c.room;
    if (r == null && !quiet) {
      c.error(ProtocolError.notInRoom, 'Join a room first');
    }
    return r;
  }

  String _newCode() {
    while (true) {
      final code = List.generate(
          5, (_) => _codeAlphabet[_rng.nextInt(_codeAlphabet.length)]).join();
      if (!rooms.containsKey(code)) return code;
    }
  }

  String _newToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(24, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  static String _cleanName(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'[^\w \-]'), '');
    if (trimmed.isEmpty) return 'Player';
    return trimmed.length > 16 ? trimmed.substring(0, 16) : trimmed;
  }

  void _log(String s) {
    if (verbose) stdout.writeln('[${DateTime.now().toIso8601String()}] $s');
  }
}
