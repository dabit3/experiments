import 'dart:convert';
import 'dart:io';

import 'package:panic_pantry_core/panic_pantry_core.dart';

/// Generates a deterministic input script for the automated multiplayer test.
///
/// The match is simulated offline with the same fixed-step rules the server
/// uses. Every chef is driven by the deterministic [Bot] planner; the per-tick
/// inputs of the chefs listed in `--scripted` are recorded so the test can
/// replay them through the server's test-input channel, while the remaining
/// slots are left to the server's own bots (seeded identically). Because the
/// simulation is deterministic, the real match must end with exactly the
/// `expected` results printed here.
///
/// Usage:
///   dart run bin/plan.dart --level corner-cafe --seed 4242 --match 1 \
///       --players 4 --scripted 0,1,2 [--emotes]
Future<void> main(List<String> args) async {
  var levelId = kLevels.first.id;
  var seed = 4242;
  var match = 1;
  var players = 4;
  var scripted = <int>[0, 1, 2, 3];
  var emotes = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--level':
        levelId = args[++i];
      case '--seed':
        seed = int.parse(args[++i]);
      case '--match':
        match = int.parse(args[++i]);
      case '--players':
        players = int.parse(args[++i]);
      case '--scripted':
        scripted = args[++i].split(',').where((s) => s.isNotEmpty).map(int.parse).toList();
      case '--emotes':
        emotes = true;
    }
  }

  final level = levelById(levelId);
  final matchSeed = seed + match * 7919;
  final state = GameState(level, playerCount: players);
  for (var slot = 0; slot < players; slot++) {
    state.chefs.add(
      Chef(id: 'c$slot', slot: slot, name: 'Chef $slot', x: 0, y: 0, bot: !scripted.contains(slot))..connected = true,
    );
  }
  final sim = Simulation(state, seed: matchSeed);
  final coordinator = BotCoordinator();
  final bots = {for (final c in state.chefs) c.id: Bot(c.id, seed: matchSeed + c.slot, coordinator: coordinator)};
  sim.startRound();

  final steps = {for (final s in scripted) s: <Map<String, dynamic>>[]};
  final emoteRng = Rng(matchSeed ^ 0x5eed);
  var safety = 0;
  while (state.phase != Phase.finished && safety++ < 200000) {
    for (final c in state.chefs) {
      var input = bots[c.id]!.think(state, Rules.tickSeconds);
      if (scripted.contains(c.slot)) {
        // Sprinkle emotes so the quick-chat system shows up in recordings.
        if (emotes && state.phase == Phase.playing && input.emote == null && emoteRng.nextInt(400) == 0) {
          input = input.copyWith(emote: emoteRng.nextInt(kEmotes.length));
        }
        // Round-trip through JSON so the replayed values match bit-for-bit.
        input = ChefInput.fromJson(input.toJson());
        _record(steps[c.slot]!, input);
      }
      sim.pending[c.id] = input;
    }
    sim.step();
    sim.pending.clear();
    state.events.clear();
  }

  final out = {
    'level': level.id,
    'seed': seed,
    'match': match,
    'matchSeed': matchSeed,
    'players': players,
    'scripted': scripted,
    'ticks': state.tick,
    'expected': state.results(),
    'steps': {for (final e in steps.entries) '${e.key}': e.value},
  };
  stdout.writeln(jsonEncode(out));
}

/// Run-length encodes consecutive identical held inputs. Edge-triggered flags
/// (interact, dash, emote) are never merged so they fire on the exact tick.
void _record(List<Map<String, dynamic>> steps, ChefInput input) {
  final json = input.toJson();
  final edge = input.interact || input.dash || input.emote != null;
  if (!edge && steps.isNotEmpty) {
    final last = steps.last;
    final lastEdge = last['i'] == true || last['d'] == true || last.containsKey('e');
    if (!lastEdge && _sameHeld(last, json)) {
      last['ticks'] = (last['ticks'] as int) + 1;
      return;
    }
  }
  steps.add({...json, 'ticks': 1});
}

bool _sameHeld(Map<String, dynamic> a, Map<String, dynamic> b) =>
    a['dx'] == b['dx'] && a['dy'] == b['dy'] && a['a'] == b['a'] && a['tx'] == b['tx'] && a['ty'] == b['ty'];
