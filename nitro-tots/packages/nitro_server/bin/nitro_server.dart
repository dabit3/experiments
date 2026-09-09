import 'dart:io';

import 'package:args/args.dart';
import 'package:nitro_server/nitro_server.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('host', defaultsTo: '0.0.0.0', help: 'Interface to bind.')
    ..addOption('port', abbr: 'p', defaultsTo: '8787', help: 'TCP port.')
    ..addOption('seed', help: 'Fixed seed for deterministic room codes and race seeds.')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false, help: 'Log connections and room events.')
    ..addFlag('help', abbr: 'h', negatable: false);
  final opts = parser.parse(args);
  if (opts['help'] == true) {
    stdout.writeln('Nitro Tots server\n\n${parser.usage}');
    return;
  }
  final server = NitroServer(ServerConfig(
    host: opts['host'] as String,
    port: int.parse(opts['port'] as String),
    seed: opts['seed'] == null ? null : int.parse(opts['seed'] as String),
    verbose: opts['verbose'] as bool,
  ));
  await server.start();
  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
}
