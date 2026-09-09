import 'dart:io';

import 'package:panic_pantry_core/panic_pantry_core.dart';
import 'package:panic_pantry_server/panic_pantry_server.dart';

/// Usage: dart run bin/server.dart [--port 8787] [--seed 1234] [--host 0.0.0.0]
Future<void> main(List<String> args) async {
  var port = int.tryParse(Platform.environment['PORT'] ?? '') ?? kDefaultPort;
  int? seed;
  var host = '0.0.0.0';
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--port':
        port = int.parse(args[++i]);
      case '--seed':
        seed = int.parse(args[++i]);
      case '--host':
        host = args[++i];
    }
  }
  final server = PanicPantryServer(seed: seed);
  await server.serve(address: InternetAddress(host), port: port);
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}
