import 'package:lastfort_core/lastfort_core.dart';
import 'dart:convert';

import 'package:test/test.dart';

Sim _match(int seed) {
  final rules = const Rules.fast();
  final sim = Sim(rules: rules, seed: seed, mode: SquadMode.squads);
  final bots = <BotBrain>[];
  for (var i = 0; i < 16; i++) {
    final p = sim.addPlayer(
      id: i + 1,
      name: 'Bot $i',
      team: i ~/ 4,
      isBot: true,
      loadout: const Loadout(),
    );
    bots.add(BotBrain(p, seed ^ (i * 977), sim));
  }
  sim.start();
  var guard = 0;
  while (sim.phase != MatchPhase.ended && guard < 20 * 60 * 10) {
    for (final b in bots) {
      sim.applyInput(b.player, b.think());
    }
    sim.step();
    guard++;
  }
  return sim;
}

void main() {
  _replicaTests();
  test('world generation is deterministic', () {
    final a = World.generate(const Rules(), 42);
    final b = World.generate(const Rules(), 42);
    expect(a.terrain, equals(b.terrain));
    expect(a.chests.length, equals(b.chests.length));
    expect(a.nodes.length, equals(b.nodes.length));
    expect(a.pois.map((p) => p.name).toList(),
        equals(b.pois.map((p) => p.name).toList()));
    expect(a.pois.length, greaterThanOrEqualTo(4));
    expect(a.chests.length, greaterThan(20));
    expect(a.nodes.length, greaterThan(200));
  });

  test('a full bot match is deterministic and ends with a winner', () {
    final a = _match(7);
    final b = _match(7);
    expect(a.phase, MatchPhase.ended);
    expect(a.winnerTeam, isNotNull);
    expect(a.buildSummary(), equals(b.buildSummary()));
    final summary = a.buildSummary();
    final players = summary['players'] as List<Object?>;
    final placements = players
        .map((p) => (p as Map<String, Object?>)['placement'] as int)
        .toSet();
    expect(placements.contains(1), isTrue);
    expect(placements.contains(0), isFalse);
    print(
        'ended at tick ${a.endedAtTick} (${a.endedAtTick / 20}s), winner ${a.winnerTeam}');
    for (final p in players) {
      print(p);
    }
  });

  test('building costs materials and blocks movement', () {
    final sim = Sim(rules: const Rules.fast(), seed: 3, mode: SquadMode.solo);
    final p = sim.addPlayer(
        id: 1, name: 'A', team: 0, isBot: false, loadout: const Loadout());
    sim.addPlayer(
        id: 2, name: 'B', team: 1, isBot: false, loadout: const Loadout());
    sim.start();
    for (var i = 0; i < 20 * 10; i++) {
      sim.step();
    }
    expect(p.alive, isTrue);
    p.materials[0] = 50;
    p.aim = 0;
    p.buildPiece = Piece.wall;
    final gx = sim.world.toTile(p.x) + 1;
    final gy = sim.world.toTile(p.y);
    final s = sim.place(p, gx, gy);
    expect(s, isNotNull);
    expect(p.materials[0], 40);
    final before = p.x;
    sim.applyInput(p, const InputFrame(seq: 1, moveX: 1));
    for (var i = 0; i < 40; i++) {
      sim.step();
    }
    expect(p.x - before, lessThan(sim.rules.tileSize * 1.5));
  });
}

void _replicaTests() {
  test('snapshots replicate structures, storm and players to a client replica',
      () {
    final rules = const Rules.fast();
    final server = Sim(rules: rules, seed: 11, mode: SquadMode.duos);
    final bots = <BotBrain>[];
    for (var i = 0; i < 8; i++) {
      final p = server.addPlayer(
          id: i + 1,
          name: 'B$i',
          team: i ~/ 2,
          isBot: true,
          loadout: const Loadout());
      bots.add(BotBrain(p, 11 ^ (i * 31), server));
    }
    server.start();
    final replica = Sim(rules: rules, seed: 11, mode: SquadMode.duos);
    final cache = ViewerCache();
    final viewer = server.players[1]!;
    var snapshotsWithStructs = 0;
    for (var t = 0; t < 20 * 60 && server.phase != MatchPhase.ended; t++) {
      for (final b in bots) {
        server.applyInput(b.player, b.think());
      }
      server.step();
      final snap =
          server.snapshotFor(viewer, cache, events: server.drainEvents());
      // Round-trip through JSON like the wire would.
      final wire = jsonDecode(jsonEncode(snap)) as Map<String, Object?>;
      if ((wire['structs'] as List<Object?>).isNotEmpty) snapshotsWithStructs++;
      replica.applySnapshot(wire);
    }
    expect(snapshotsWithStructs, greaterThan(0));
    expect(replica.tick, server.tick);
    expect(replica.storm.radius, closeTo(server.storm.radius, 0.01));
    expect(replica.storm.phase, server.storm.phase);
    final sp = server.players[1]!;
    final rp = replica.players[1]!;
    expect(rp.x, closeTo(sp.x, 0.01));
    expect(rp.health, sp.health);
    expect(rp.materials, sp.materials);
    // Every player-built structure the viewer can see exists in the replica.
    for (final s in server.structures.values) {
      if (s.team == -1 && s.version == 0) continue;
      if (!server.inInterest(
          sp, server.world.tileCenter(s.gx), server.world.tileCenter(s.gy))) {
        continue;
      }
      final r = replica.structures[replica.world.tileKey(s.gx, s.gy)];
      expect(r, isNotNull, reason: 'structure ${s.id} missing');
      expect(r!.hp, s.hp);
    }
  });
}
