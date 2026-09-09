import 'package:panic_pantry_core/panic_pantry_core.dart';

void main() {
  final level = levelById('split-shift');
  final state = GameState(level, playerCount: 4);
  final sim = Simulation(state, seed: 1234);
  final coordinator = BotCoordinator();
  final bots = <Bot>[];
  for (var i = 0; i < 4; i++) {
    state.chefs.add(Chef(id: 'bot$i', slot: i, name: 'Bot $i', x: 0, y: 0, bot: true));
    bots.add(Bot('bot$i', seed: 1234 + i, coordinator: coordinator));
  }
  sim.startRound();
  while (state.time < 17) {
    for (final b in bots) {
      sim.pending[b.chefId] = b.think(state, Rules.tickSeconds);
    }
    sim.step();
    state.events.clear();
  }
  print(state.orders.map((o) => o.dish));
  for (final (x, y, t) in state.allTiles()) {
    if (t.item != null) print('$x,$y ${t.type} ${t.item!.toJson()}');
  }
  print(coordinator.claims);
  for (final b in bots) {
    print(
      '${b.chefId} ${b.debugGoal} -> ${b.debugChoose(state)} held=${state.chefById(b.chefId)!.held?.toJson()} at ${state.chefById(b.chefId)!.x},${state.chefById(b.chefId)!.y}',
    );
  }
}
