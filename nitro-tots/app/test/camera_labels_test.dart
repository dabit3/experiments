import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/game/race_game.dart';
import 'package:nitro_tots/game/session.dart';

class _OrientationCanvas extends TestRecordingCanvas {
  final _angles = <double>[0];
  final labelAngles = <double>[];
  final textAngles = <double>[];

  @override
  void save() {
    _angles.add(_angles.last);
    super.save();
  }

  @override
  void restore() {
    _angles.removeLast();
    super.restore();
  }

  @override
  void rotate(double radians) {
    _angles[_angles.length - 1] += radians;
    super.rotate(radians);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    if (paint.color.toARGB32() == 0xED102B3B) labelAngles.add(_angles.last);
    super.drawRRect(rrect, paint);
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    textAngles.add(_angles.last);
    super.drawParagraph(paragraph, offset);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final chase in [true, false]) {
    test('Names and turbo captions stay upright in ${chase ? 'chase' : 'fixed'} and rear views', () async {
      final sim = RaceSim(
        track: trackById('sprinkle'),
        racers: [
          Racer(slot: 0, playerId: 'local', name: 'Pip', characterId: 'pip', kartId: 'jellybean', isBot: false, platform: 'test'),
          Racer(slot: 1, playerId: 'rival', name: 'Bea', characterId: 'bea', kartId: 'jellybean', isBot: false, platform: 'test'),
        ],
        seed: 4242,
      );
      sim.racers[1].pos = sim.racers[0].pos + V2.fromAngle(sim.racers[0].heading, 45);
      final session = LocalSession(
        sim: sim,
        info: const MatchInfo(trackId: 'sprinkle', laps: 3, mode: GameMode.race, raceIndex: 0, totalRaces: 1),
        localSlot: 0,
        seed: 4242,
      );
      final game = RaceGame(session: session, chaseCamera: chase, reduceMotion: true);
      addTearDown(game.onRemove);
      addTearDown(session.dispose);
      game.onGameResize(Vector2(800, 532));
      await game.onLoad();
      session.frameEvents.add(const SimEvent('miniTurbo', slot: 0, value: 2));

      for (final rear in [false, true, false]) {
        session.input = KartInput(lookBack: rear);
        game.update(1 / 120);
        final canvas = _OrientationCanvas();
        game.render(canvas);
        expect(canvas.labelAngles, isNotEmpty, reason: 'A rival name must be visible');
        for (final angle in canvas.labelAngles) {
          expect(angle, closeTo(0, 1e-9), reason: 'Rival capsule orientation, rear=$rear');
        }
        expect(canvas.textAngles.last, closeTo(0, 1e-9), reason: 'Super turbo caption orientation, rear=$rear');
      }
    });
  }
}
