import 'dart:convert';

import 'package:panic_pantry_core/panic_pantry_core.dart';
import 'package:test/test.dart';

/// Runs a full bot-only round and returns the final state.
GameState runRound(String levelId, {int seed = 42, int players = 4}) {
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
    state.events.clear();
  }
  return state;
}

void main() {
  test('levels parse and have spawns for four chefs', () {
    for (final level in kLevels) {
      final s = GameState(level, playerCount: 4);
      expect(s.spawns.length, 4, reason: level.id);
      expect(level.menu, isNotEmpty);
    }
  });

  test('snapshot round-trips', () {
    final s = runRound('training', seed: 7, players: 2);
    final json = jsonDecode(jsonEncode(s.toSnapshot())) as Map<String, dynamic>;
    final copy = GameState(s.level, playerCount: 2)..applySnapshot(json);
    expect(copy.score, s.score);
    expect(copy.chefs.length, 2);
    expect(jsonEncode(copy.toSnapshot()), jsonEncode(s.toSnapshot()));
  });

  test('bot rounds are deterministic and score', () {
    for (final level in kLevels) {
      final a = runRound(level.id, seed: 1234);
      final b = runRound(level.id, seed: 1234);
      expect(a.phase, Phase.finished, reason: level.id);
      expect(jsonEncode(a.results()), jsonEncode(b.results()), reason: level.id);
      // ignore: avoid_print
      print(
        '${level.id}: score=${a.score} stars=${a.stars} served=${a.served} '
        'expired=${a.expired} burnt=${a.burntPots} wrong=${a.wrongServes} tick=${a.tick}',
      );
      expect(a.served, greaterThan(0), reason: '${level.id} bots never served a dish');
    }
  });

  test('gimmick levels: bots ship across belts, hatches and ferries', () {
    // Each gimmick level splits the kitchen; bots must route food across.
    for (final id in ['conveyor-canteen', 'split-shift', 'drift-deck']) {
      final s = runRound(id, seed: 1234);
      expect(s.served, greaterThanOrEqualTo(5), reason: id);
      expect(s.wrongServes, 0, reason: id);
    }
  });

  test('moving platform tiles are walkable at both ends of travel', () {
    final s = GameState(levelById('split-shift'), playerCount: 4);
    // Doorway into the east wing exists when docked north (offset 0)...
    expect(s.walkable(6, 2), isTrue);
    // ...and the same cell is a counter once the wing has slid south.
    s.moverOffsets[0] = 2;
    expect(s.walkable(6, 2), isFalse);
    expect(s.tileAt(6, 2)!.type, TileType.counter);
    expect(s.walkableAny(6, 2), isTrue);
  });

  test('scoring tiers', () {
    expect(Scoring.serveValue(fraction: 0.9, combo: 1), 28);
    expect(Scoring.serveValue(fraction: 0.5, combo: 2), 30);
    expect(Scoring.serveValue(fraction: 0.1, combo: 4), 32);
  });
}
