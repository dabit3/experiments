import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/game/race_game.dart';
import 'package:nitro_tots/game/session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final chase in [true, false]) {
    test('Look back reveals the rear and restores ${chase ? 'chase' : 'fixed'} view on release', () async {
      final session = LocalSession(
        sim: RaceSim(
          track: trackById('sprinkle'),
          racers: [Racer(slot: 0, playerId: 'p', name: 'Pip', characterId: 'pip', kartId: 'jellybean', isBot: false, platform: 'test')],
          seed: 4242,
        ),
        info: const MatchInfo(trackId: 'sprinkle', laps: 3, mode: GameMode.race, raceIndex: 0, totalRaces: 1),
        localSlot: 0,
        seed: 4242,
      );
      final game = RaceGame(session: session, chaseCamera: chase, reduceMotion: true);
      addTearDown(game.onRemove);
      addTearDown(session.dispose);
      game.onGameResize(Vector2(800, 532));
      await game.onLoad();
      game.update(1 / 120);
      final me = session.local!;
      final heading = me.heading;
      final ahead = me.pos + V2.fromAngle(heading, 60);
      final behind = me.pos - V2.fromAngle(heading, 60);
      final originalAhead = game.worldToScreen(ahead);
      final originalKart = game.worldToScreen(me.pos);

      session.input = const KartInput(lookBack: true);
      game.update(1 / 120);
      expect(game.worldToScreen(behind).dy, lessThan(game.worldToScreen(me.pos).dy));
      expect(game.worldToScreen(ahead).dy, greaterThan(game.worldToScreen(me.pos).dy));
      expect(me.heading, heading);

      session.input = KartInput.idle;
      game.update(1 / 120);
      expect((game.worldToScreen(ahead) - originalAhead).distance, lessThan(0.001));
      expect((game.worldToScreen(me.pos) - originalKart).distance, lessThan(0.001));
    });
  }
}
