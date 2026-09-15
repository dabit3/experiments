import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gambit_court_core/gambit_court_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'clock.dart';
import 'hub.dart';

/// HTTP + WebSocket front for a [Hub].
///
/// Routes:
/// - `GET /ws`        game protocol (JSON text frames)
/// - `GET /health`    liveness + counters
/// - `GET /rooms`     public room listings
/// - `/control/...`   test automation bridge, only when [enableControl] is set
class GambitCourtServer {
  GambitCourtServer({
    required this.hub,
    this.enableControl = false,
    this.log,
  });

  final Hub hub;
  final bool enableControl;
  final void Function(String line)? log;
  HttpServer? _http;

  int get port => _http?.port ?? 0;

  Handler get handler {
    final router = Router()
      ..get('/',
          (_) => _json({'name': 'Gambit Court', 'protocol': Protocol.version}))
      ..get(
          '/health',
          (_) => _json({
                'ok': true,
                'clients': hub.sessions.values.where((s) => s.connected).length,
                'rooms': hub.rooms.length,
                'serverTimeMs': hub.wall.nowMs(),
                'frozenClocks': hub.config.frozenClocks,
              }))
      ..get(
          '/rooms',
          (_) => _json({
                'rooms': hub.listings().map((l) => l.toJson()).toList(),
              }))
      ..get('/ws', webSocketHandler(_onSocket));
    if (enableControl) {
      router
        ..get('/control/state', (_) => _json(hub.debugState()))
        ..get('/control/rooms/<code>', (Request _, String code) {
          final room = hub.rooms[code.toUpperCase()];
          if (room == null) return _json({'error': 'room_not_found'}, 404);
          return _json(room.snapshot().toJson());
        })
        ..post('/control/clients/<clientId>/ui',
            (Request request, String clientId) async {
          final body = decodeJson(await request.readAsString());
          if (body == null) return _json({'error': 'bad_json'}, 400);
          final timeoutMs =
              (body.remove('timeoutMs') as num?)?.toInt() ?? 15000;
          try {
            final report = await hub.uiCommand(
              clientId,
              body,
              Duration(milliseconds: timeoutMs),
            );
            return _json(report);
          } on HubError catch (e) {
            return _json({'error': e.code, 'message': e.message}, 409);
          }
        })
        ..post('/control/clock/advance', (Request request) async {
          final wall = hub.wall;
          if (wall is! ManualWallClock) {
            return _json({'error': 'clock_not_manual'}, 409);
          }
          final body = decodeJson(await request.readAsString()) ?? {};
          wall.advance((body['ms'] as num?)?.toInt() ?? 0);
          return _json({'serverTimeMs': wall.nowMs()});
        });
    }
    return const Pipeline().addMiddleware(_cors).addHandler(router.call);
  }

  Future<void> start({String host = '0.0.0.0', int port = 8765}) async {
    _http = await shelf_io.serve(handler, host, port);
    log?.call('Gambit Court server listening on ws://$host:${_http!.port}/ws'
        '${enableControl ? ' (control channel enabled)' : ''}');
  }

  Future<void> stop() async {
    hub.dispose();
    await _http?.close(force: true);
  }

  void _onSocket(WebSocketChannel channel, String? protocol) {
    Session? session;
    void send(Json message) {
      try {
        channel.sink.add(jsonEncode(message));
      } on StateError {
        // Socket already closing; the onDone handler detaches the session.
      }
    }

    channel.stream.listen(
      (raw) {
        final message = decodeJson(raw);
        if (message == null) {
          send({
            'type': Protocol.error,
            'code': ErrorCodes.badRequest,
            'message': 'Messages must be JSON objects.',
          });
          return;
        }
        if (session == null) {
          if (message['type'] != Protocol.hello) {
            send({
              'type': Protocol.error,
              'code': ErrorCodes.badRequest,
              'message': 'Send hello first.',
            });
            return;
          }
          final clientId = (message['clientId'] as String? ?? '').trim();
          if (clientId.isEmpty || clientId.length > 64) {
            send({
              'type': Protocol.error,
              'code': ErrorCodes.badRequest,
              'message': 'hello.clientId is required.',
              'fatal': true,
            });
            channel.sink.close();
            return;
          }
          final name = (message['name'] as String? ?? '').trim();
          session = hub.attach(
            clientId,
            name.isEmpty
                ? 'Guest'
                : name.substring(0, name.length.clamp(0, 24)),
            (message['platform'] as String? ?? 'unknown'),
            send,
          );
          return;
        }
        hub.handle(session!, message);
      },
      onDone: () {
        if (session != null) hub.detach(session!, send);
      },
      onError: (Object _) {
        if (session != null) hub.detach(session!, send);
      },
      cancelOnError: true,
    );
  }
}

Response _json(Object body, [int status = 200]) => Response(
      status,
      body: jsonEncode(body),
      headers: const {'content-type': 'application/json'},
    );

Handler _cors(Handler inner) => (request) async {
      const headers = {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, OPTIONS',
        'access-control-allow-headers': 'content-type',
      };
      if (request.method == 'OPTIONS') return Response.ok('', headers: headers);
      final response = await inner(request);
      return response.change(headers: headers);
    };
