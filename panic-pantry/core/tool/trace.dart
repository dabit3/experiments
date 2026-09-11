// Debug helper: run a bot-only round and print events.
// Usage: dart run tool/trace.dart [levelId] [players] [seed]
import 'package:panic_pantry_core/panic_pantry_core.dart';

void main(List<String> args) {
  final levelId = args.isNotEmpty ? args[0] : 'training';
  final players = args.length > 1 ? int.parse(args[1]) : 4;
  final seed = args.length > 2 ? int.parse(args[2]) : 1234;
  final level = levelById(levelId);
  final state = GameState(level, playerCount: players);
  final sim = Simulation(state, seed: seed);
  final coordinator = BotCoordinator();
  final bots = <Bot>[];
  for (var i = 0; i < players; i++) {
    state.chefs.add(Chef(id: 'bot$i', slot: i, name: 'Bot $i', x: 0, y: 0, bot: true));
    bots.add(Bot('bot$i', seed: seed + i, coordinator: coordinator));
  }
  sim.startRound();
  var guard = 0;
  while (state.phase != Phase.finished && guard++ < 20000) {
    for (final b in bots) {
      sim.pending[b.chefId] = b.think(state, Rules.tickSeconds);
    }
    sim.step();
    for (final e in state.events) {
      if (e.kind == 'pickup' || e.kind == 'drop') continue;
      print(
        't=${state.time.toStringAsFixed(2)} ${e.kind} ${e.text ?? ''} ${e.value ?? ''} '
        '@${e.x},${e.y} ${e.chef ?? ''}',
      );
    }
    if (state.tick % 100 == 0) {
      for (var i = 0; i < state.chefs.length; i++) {
        final c = state.chefs[i];
        print(
          '  ${c.id} (${c.x.toStringAsFixed(1)},${c.y.toStringAsFixed(1)}) ${bots[i].debugGoal} held=${c.held?.toJson()}',
        );
      }
    }
    state.events.clear();
  }
  print(state.results());
}
