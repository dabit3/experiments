import 'dart:io';

import 'package:args/args.dart';
import 'package:gambit_court_server/gambit_court_server.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('host', defaultsTo: '0.0.0.0')
    ..addOption('port', defaultsTo: '8765')
    ..addOption('seed',
        help: 'Fixed RNG seed for room codes, colours and bots.')
    ..addOption('bot-delay-ms', defaultsTo: '600')
    ..addOption('reconnect-grace-ms', defaultsTo: '45000')
    ..addFlag(
      'frozen-clocks',
      help: 'Clocks never tick (deterministic test mode).',
    )
    ..addFlag(
      'control',
      help: 'Expose the /control test-automation HTTP endpoints.',
    )
    ..addFlag('quiet', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }
  if (options['help'] as bool) {
    stdout.writeln('Gambit Court server\n\n${parser.usage}');
    return;
  }
  final quiet = options['quiet'] as bool;
  void log(String line) {
    if (!quiet) stdout.writeln('[${DateTime.now().toIso8601String()}] $line');
  }

  final seedText = options['seed'] as String?;
  final frozen = options['frozen-clocks'] as bool;
  final hub = Hub(
    config: HubConfig(
      seed: seedText == null ? null : int.parse(seedText),
      frozenClocks: frozen,
      botDelayMs: int.parse(options['bot-delay-ms'] as String),
      reconnectGraceMs: int.parse(options['reconnect-grace-ms'] as String),
      log: log,
    ),
    wall: frozen ? ManualWallClock() : const SystemWallClock(),
  );
  final server = GambitCourtServer(
    hub: hub,
    enableControl: options['control'] as bool,
    log: log,
  );
  await server.start(
    host: options['host'] as String,
    port: int.parse(options['port'] as String),
  );
  ProcessSignal.sigint.watch().listen((_) async {
    log('shutting down');
    await server.stop();
    exit(0);
  });
}
