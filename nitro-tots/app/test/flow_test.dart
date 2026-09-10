import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/state/app_state.dart';
import 'package:nitro_tots/state/flow.dart';
import 'package:nitro_tots/state/test_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fakes a finished race in which the grid finishes in reverse slot order.
List<RaceResult> _finish(RaceSim sim) {
  final order = sim.racers.reversed.toList();
  return [
    for (final (i, r) in order.indexed)
      RaceResult(
        slot: r.slot,
        name: r.name,
        characterId: r.characterId,
        kartId: r.kartId,
        isBot: r.isBot,
        platform: r.platform,
        place: i + 1,
        finishTick: countdownTicks + 3000 + i * 30,
        lapTicks: const [1000, 1000, 1000],
        points: pointsForPlace(i + 1),
        score: 0,
      ),
  ];
}

void main() {
  late GameFlow flow;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance(), const TestConfig());
    flow = GameFlow(app)..choose(PlayMode.grandPrix);
  });

  tearDown(() => flow.endSeries());

  test('cup rivals keep their identity across every race', () {
    flow.startSeries();
    final first = [for (final r in flow.session!.sim.racers) (r.slot, r.name, r.characterId, r.kartId)];
    expect(first.length, 8);
    expect(first.map((r) => r.$3).toSet().length, 8, reason: 'no duplicate characters on the grid');
    for (var i = 1; i < flow.totalRaces; i++) {
      flow.recordResults(_finish(flow.session!.sim));
      flow.nextRace();
      expect([for (final r in flow.session!.sim.racers) (r.slot, r.name, r.characterId, r.kartId)], first);
    }
  });

  test('cup standings accumulate under the right names', () {
    flow.startSeries();
    final results = _finish(flow.session!.sim);
    final preview = flow.standingsAfter(results);
    expect(flow.standings, isEmpty, reason: 'preview must not record');
    flow.recordResults(results);
    expect(
      [for (final s in flow.sortedStandings) '${s.slot}:${s.name}:${s.points}:${s.places}'],
      [for (final s in preview) '${s.slot}:${s.name}:${s.points}:${s.places}'],
    );

    flow.nextRace();
    flow.recordResults(_finish(flow.session!.sim));
    final winner = flow.sortedStandings.first;
    final byName = {for (final r in flow.session!.sim.racers) r.slot: r.name};
    expect(winner.name, byName[winner.slot]);
    expect(winner.places, [1, 1]);
    expect(winner.points, 2 * pointsForPlace(1));
    expect(flow.sortedStandings.last.slot, 0);
    expect(flow.sortedStandings.last.places, [8, 8]);
  });
}
