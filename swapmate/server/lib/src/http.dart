import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'hub.dart';
import 'room.dart';

/// Wraps a [Hub] in an HTTP server: `/ws` for gameplay, `/healthz`, and the
/// test channel under `/test/*` when the server runs in test mode.
class SwapmateServer {
  SwapmateServer(this.config, {this._staticDir}) : hub = Hub(config);

  final ServerConfig config;
  final Hub hub;
  final String? _staticDir;
  HttpServer? _server;

  int get port => _server!.port;

  Future<void> start({String host = '0.0.0.0', int port = 8787}) async {
    final handler = const Pipeline().addMiddleware(_cors).addHandler(_route);
    _server = await shelf_io.serve(handler, host, port);
  }

  Future<void> stop() async {
    hub.dispose();
    await _server?.close(force: true);
  }

  Middleware get _cors =>
      (inner) => (req) async {
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

  Future<Response> _route(Request req) async {
    final path = req.url.path;
    if (path == 'ws') {
      return webSocketHandler((WebSocketChannel ch, _) => hub.handle(ch))(req);
    }
    if (path == 'healthz') {
      return _json({
        'ok': true,
        'rooms': hub.rooms.length,
        'clients': hub.connections.length,
        'testMode': config.testMode,
      });
    }
    if (path.startsWith('rooms/')) {
      final code = path.substring('rooms/'.length);
      final r = hub.roomJson(code);
      return r == null ? _json({'error': 'room_not_found'}, 404) : _json(r);
    }
    if (config.testMode && path.startsWith('test/')) {
      return _test(req, path.substring('test/'.length));
    }
    if (_staticDir != null) return _static(path);
    return Response.notFound('not found');
  }

  Future<Response> _test(Request req, String path) async {
    if (path == 'clients') return _json({'clients': hub.testClientList()});
    if (path == 'command' && req.method == 'POST') {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final testId = body['testId'] as String;
      final command = body['command'] as Map<String, dynamic>;
      final timeoutMs = body['timeoutMs'] as int? ?? 20000;
      try {
        final result = await hub.testCommand(
          testId,
          command,
          timeout: Duration(milliseconds: timeoutMs),
        );
        return _json({'ok': true, 'result': result});
      } on StateError catch (e) {
        return _json({'ok': false, 'error': e.message}, 504);
      }
    }
    return Response.notFound('unknown test endpoint');
  }

  Future<Response> _static(String path) async {
    final rel = path.isEmpty ? 'index.html' : path;
    var file = File('$_staticDir/$rel');
    if (!await file.exists()) file = File('$_staticDir/index.html');
    if (!await file.exists()) return Response.notFound('not found');
    final ext = rel.split('.').last;
    final type = switch (ext) {
      'html' => 'text/html; charset=utf-8',
      'js' => 'application/javascript',
      'mjs' => 'application/javascript',
      'json' => 'application/json',
      'wasm' => 'application/wasm',
      'png' => 'image/png',
      'svg' => 'image/svg+xml',
      'css' => 'text/css',
      'otf' => 'font/otf',
      'ttf' => 'font/ttf',
      _ => 'application/octet-stream',
    };
    return Response.ok(
      file.openRead(),
      headers: {'Content-Type': type, 'Cache-Control': 'no-cache'},
    );
  }

  Response _json(Object body, [int status = 200]) => Response(
    status,
    body: jsonEncode(body),
    headers: {'Content-Type': 'application/json'},
  );
}
