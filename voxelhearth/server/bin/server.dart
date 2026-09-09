import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:voxelhearth_server/server.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8787')
    ..addOption('host', defaultsTo: '0.0.0.0')
    ..addOption('save-dir', defaultsTo: 'saves')
    ..addOption('web-root', help: 'Serve a built Flutter web client from this directory')
    ..addOption('seed', help: 'Default seed for new rooms (random when omitted)')
    ..addOption('director-key', defaultsTo: 'voxelhearth-director')
    ..addFlag('test-mode', help: 'Enable the director channel, fixed tokens and requested room codes', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts['help'] as bool) {
    stdout.writeln('Voxelhearth server\n${parser.usage}');
    return;
  }

  final hub = Hub(
    saveDir: opts['save-dir'] as String,
    testMode: opts['test-mode'] as bool,
    directorKey: opts['director-key'] as String,
    defaultSeed: opts['seed'] == null ? null : int.tryParse(opts['seed'] as String),
    log: (s) => stdout.writeln('[${DateTime.now().toIso8601String()}] $s'),
  );
  hub.start();

  final wsHandler = webSocketHandler((WebSocketChannel channel, String? protocol) => hub.onConnect(channel));
  final webRoot = opts['web-root'] as String?;
  final staticHandler = webRoot != null && Directory(webRoot).existsSync()
      ? createStaticHandler(webRoot, defaultDocument: 'index.html')
      : null;

  Response cors(Response r) => r.change(
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    },
  );

  Future<Response> handler(Request req) async {
    final path = req.url.path;
    if (req.method == 'OPTIONS') return cors(Response.ok(''));
    if (path == 'ws') return wsHandler(req);
    if (path == 'health') {
      return cors(
        Response.ok(
          '{"ok":true,"rooms":${hub.rooms.length},"clients":${hub.clients.length},"testMode":${hub.testMode}}',
          headers: {'content-type': 'application/json'},
        ),
      );
    }
    if (path == 'rooms') {
      final list = hub.rooms.values
          .map((r) => '{"code":"${r.code}","name":${_q(r.name)},"phase":"${r.phase}","players":${r.players.length}}')
          .join(',');
      return cors(Response.ok('[$list]', headers: {'content-type': 'application/json'}));
    }
    if (staticHandler != null) return staticHandler(req);
    return Response.notFound('Voxelhearth server: connect via WebSocket at /ws');
  }

  final server = await shelf_io.serve(
    logRequests(
      logger: (m, isError) {
        if (isError) stderr.writeln(m);
      },
    ).addHandler(handler),
    opts['host'] as String,
    int.parse(opts['port'] as String),
  );
  hub.log(
    'Voxelhearth server listening on ws://${server.address.host}:${server.port}/ws'
    '${hub.testMode ? ' (TEST MODE)' : ''}${webRoot != null ? ', serving web client from $webRoot' : ''}',
  );

  Future<void> shutdown(ProcessSignal s) async {
    hub.log('shutting down ($s)');
    await hub.stop();
    await server.close(force: true);
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  ProcessSignal.sigterm.watch().listen(shutdown);
}

String _q(String s) => '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
