import 'package:nitro_core/nitro_core.dart';

void main(List<String> args) {
  final trackId = args.isNotEmpty ? args[0] : 'sprinkle';
  final track = trackById(trackId);
  final racers = [
    for (var i = 0; i < 8; i++) Racer(slot: i, playerId: '', name: 'Bot $i', characterId: characters[i].id, kartId: karts[i % karts.length].id, isBot: true),
  ];
  final sim = RaceSim(track: track, racers: racers, seed: 7);
  final bots = {for (final r in racers) r.slot: BotDriver(slot: r.slot, seed: 7, skill: (args.length > 1 ? double.parse(args[1]) : 0.5 + 0.06 * r.slot))};
  print('track ${track.def.name} length=${track.length.toStringAsFixed(0)} grid0=${track.startGrid[0]} heading=${track.startHeading}');
  while (sim.phase != RacePhase.finished && sim.tick < 30 * 60 * 4) {
    sim.step(const {}, (s, r) => bots[r.slot]!.drive(s, r));
    if (sim.tick % 150 == 0) {
      final r = racers[args.length > 2 ? int.parse(args[2]) : 0];
      print(
        't=${sim.tick} pos=${r.pos} spd=${r.speed.toStringAsFixed(1)} lap=${r.lap} cp=${r.checkpoint} near=${r.nearest} surf=${r.surface} spin=${r.spinTicks} drift=${r.driftDir} ww=${r.wrongWayTicks}',
      );
    }
    for (final e in sim.events) {
      if (e.type == 'lap' || e.type == 'finish' || e.type == 'raceOver') print('  t=${sim.tick} ${e.type} slot=${e.slot} v=${e.value}');
    }
  }
  print('phase=${sim.phase} tick=${sim.tick}');
  for (final r in sim.results ?? const <RaceResult>[]) {
    print('${r.place}. ${r.name} ${r.finishTick} pts=${r.points} laps=${r.lapTicks}');
  }
}
