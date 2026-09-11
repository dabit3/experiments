import 'package:nitro_core/nitro_core.dart';
import 'package:test/test.dart';

List<Racer> botField(int n) => [
  for (var i = 0; i < n; i++)
    Racer(slot: i, playerId: '', name: 'Bot $i', characterId: characters[i % characters.length].id, kartId: karts[i % karts.length].id, isBot: true),
];

RaceSim runRace(String trackId, int seed, {int laps = 3, GameMode mode = GameMode.race, int maxTicks = 30 * 60 * 6}) {
  final track = trackById(trackId);
  final racers = botField(8);
  final sim = RaceSim(track: track, racers: racers, seed: seed, laps: laps, mode: mode, battleSeconds: 30);
  final bots = {for (final r in racers) r.slot: BotDriver(slot: r.slot, seed: seed, skill: 0.5 + 0.06 * r.slot)};
  while (sim.phase != RacePhase.finished && sim.tick < maxTicks) {
    sim.step(const {}, (s, r) => bots[r.slot]!.drive(s, r));
  }
  return sim;
}

void main() {
  test('rng is deterministic', () {
    final a = Rng(42);
    final b = Rng(42);
    for (var i = 0; i < 1000; i++) {
      expect(a.nextInt(100), b.nextInt(100));
    }
  });

  test('every track samples cleanly and has a full grid', () {
    for (final def in allTrackDefs) {
      final t = Track(def);
      expect(t.samples.length, Track.sampleCount);
      expect(t.startGrid.length, 8);
      for (final s in t.samples) {
        expect(s.width, greaterThan(10));
        expect(s.pos.x.isFinite && s.pos.y.isFinite, isTrue);
      }
    }
  });

  for (final def in raceTrackDefs) {
    test('bots finish 3 laps on ${def.name} deterministically', () {
      final a = runRace(def.id, 7);
      final b = runRace(def.id, 7);
      expect(a.phase, RacePhase.finished, reason: 'race did not finish in time on ${def.name}');
      expect(a.results!.map((r) => r.slot).toList(), b.results!.map((r) => r.slot).toList());
      expect(a.results!.map((r) => r.finishTick).toList(), b.results!.map((r) => r.finishTick).toList());
      expect(a.results!.first.points, 15);
      final finished = a.racers.where((r) => r.finished).length;
      expect(finished, greaterThanOrEqualTo(6), reason: 'only $finished bots finished on ${def.name}');
      for (final r in a.racers.where((r) => r.finished)) {
        expect(r.lapTicks.length, 3);
        expect(r.raceTicks, r.lapTicks.fold(0, (s, t) => s + t), reason: 'race time must exclude the countdown');
      }
      final winner = a.results!.first;
      expect(winner.raceTicks, winner.finishTick - countdownTicks);
    });
  }

  test('different seeds produce different item draws', () {
    final a = runRace('sprinkle', 1);
    final b = runRace('sprinkle', 2);
    expect(a.results!.map((r) => r.finishTick).toList(), isNot(b.results!.map((r) => r.finishTick).toList()));
  });

  test('battle mode ends on the timer and awards points', () {
    final sim = runRace('bumper', 3, mode: GameMode.battle);
    expect(sim.phase, RacePhase.finished);
    expect(sim.results!.length, 8);
    expect(sim.results!.first.place, 1);
  });

  test('snapshot round-trips through wire format', () {
    final sim = runRace('mossy', 11, maxTicks: 30 * 20);
    final wire = snapshotToWire(sim);
    final copy = RaceSim(track: sim.track, racers: botField(8), seed: 11);
    applySnapshot(copy, wire);
    expect(copy.tick, sim.tick);
    for (var i = 0; i < 8; i++) {
      expect(copy.racers[i].pos.distanceTo(sim.racers[i].pos), lessThan(0.02));
      expect(copy.racers[i].lap, sim.racers[i].lap);
      expect(copy.racers[i].item, sim.racers[i].item);
    }
  });

  test('grand prix standings accumulate points', () {
    final r1 = runRace('sprinkle', 5).results!;
    final r2 = runRace('mossy', 5).results!;
    final standings = computeStandings([r1, r2]);
    expect(standings.length, 8);
    expect(standings.first.points, greaterThanOrEqualTo(standings.last.points));
    final total = standings.fold<int>(0, (s, x) => s + x.points);
    expect(total, 2 * pointsTable.fold<int>(0, (s, x) => s + x));
  });
}
