import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:test/test.dart';

void main() {
  group('tycoon', () {
    test('placing bricks costs cash and earns income', () {
      final plot = TycoonPlot();
      expect(plot.place(0, 'dropper'), isNull);
      expect(plot.cash, 80);
      expect(plot.place(1, 'conveyor'), isNull);
      expect(plot.incomePerSecond(), 2 + 4 + 1);
      plot.collect();
      expect(plot.earned, 7);
      expect(plot.place(1, 'dropper'), TycoonError.occupied);
      expect(plot.place(2, 'fountain'), TycoonError.notEnoughCash);
    });

    test('autopilot is deterministic', () {
      TycoonPlot run() {
        final plot = TycoonPlot();
        final bot = TycoonAutopilot(42);
        for (var s = 90; s > 0; s--) {
          bot.decide(plot, s)?.apply(plot);
          plot.collect();
        }
        return plot;
      }

      final a = run();
      final b = run();
      expect(a.toJson(), b.toJson());
      expect(a.earned, greaterThan(500));
    });

    test('plot round-trips through json', () {
      final plot = TycoonPlot()..place(3, 'vault');
      plot.buyUpgrade('boost1');
      final copy = TycoonPlot.fromJson(plot.toJson());
      expect(copy.toJson(), plot.toJson());
    });
  });

  group('tag', () {
    Map<String, TagPlayerState> makePlayers(int n) => {
      for (var i = 0; i < n; i++) 'p$i': TagPlayerState(x: 0, y: 0),
    };

    test('tagger freezes runners and round ends when all frozen', () {
      final arena = TagArena.instance;
      final players = makePlayers(4);
      final rng = SeededRng(1);
      TagSim.startRound(arena, players, 0, rng);
      expect(players.values.where((p) => p.isTagger).length, 1);
      final bots = {
        for (final id in players.keys) id: TagAutopilot(id.hashCode),
      };
      var frozenEvents = 0;
      var tick = 0;
      while (tick < ticksPerSecond * TagSim.roundSeconds &&
          !TagSim.allRunnersFrozen(players)) {
        final inputs = {
          for (final id in players.keys)
            id: bots[id]!.decide(arena, id, players),
        };
        final events = TagSim.step(arena, players, inputs);
        frozenEvents += events
            .where((e) => e.kind == TagEventKind.freeze)
            .length;
        tick++;
      }
      expect(frozenEvents, greaterThan(0));
      TagSim.endRound(players);
      expect(
        players.values.map((p) => p.totalScore).reduce((a, b) => a + b),
        greaterThan(0),
      );
    });

    test('players never end up inside walls', () {
      final arena = TagArena.instance;
      final players = makePlayers(8);
      TagSim.startRound(arena, players, 1, SeededRng(7));
      final bots = {
        for (final id in players.keys) id: TagAutopilot(id.hashCode),
      };
      for (var tick = 0; tick < ticksPerSecond * 30; tick++) {
        final inputs = {
          for (final id in players.keys)
            id: bots[id]!.decide(arena, id, players),
        };
        TagSim.step(arena, players, inputs);
        for (final p in players.values) {
          for (final w in arena.walls) {
            final inside =
                p.x > w.x + 0.01 &&
                p.x < w.x + w.w - 0.01 &&
                p.y > w.y + 0.01 &&
                p.y < w.y + w.h - 0.01;
            expect(inside, isFalse, reason: 'player inside wall at tick $tick');
          }
        }
      }
    });

    test('state packs round-trip', () {
      final s = TagPlayerState(x: 1.5, y: 2.25, isTagger: true, freezes: 2);
      final copy = TagPlayerState.fromPacked(s.toPacked());
      expect(copy.toPacked(), s.toPacked());
    });
  });
}
