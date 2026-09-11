import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lastfort/app/arcade_art.dart';
import 'package:lastfort/game/controls.dart';
import 'package:lastfort/game/lastfort_game.dart';
import 'package:lastfort/game/match_client.dart';
import 'package:lastfort_core/lastfort_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every scout outfit paints with the native Canvas API', () {
    for (final outfit in cosmetics.where(
      (c) => c.slot == CosmeticSlot.outfit,
    )) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final saves = canvas.getSaveCount();
      ScoutPainter(outfit).paint(canvas, const ui.Size(240, 240));
      expect(canvas.getSaveCount(), saves, reason: outfit.id);
      recorder.endRecording().dispose();
    }
  });

  testWidgets(
    'a native gameplay frame paints resources and players completely',
    (tester) async {
      final client = MatchClient(
        start: {
          'rules': const Rules.fast().toJson(),
          'seed': 4242,
          'mode': 'squads',
          'players': <Object?>[],
        },
        localName: 'Renderer',
      )..localId = 1;
      final player = client.sim.addPlayer(
        id: 1,
        name: 'Renderer',
        team: 0,
        isBot: false,
        loadout: const Loadout(),
      )..state = PlayerState.alive;
      player.x = 500;
      player.y = 500;
      client.sim.phase = MatchPhase.playing;
      client.sim.world.nodes.clear();
      for (final kind in ResourceKind.values) {
        client.sim.world.nodes.add(
          ResourceNode(kind.index, kind, 490 + kind.index * 5, 490, kind.hp, 0),
        );
      }
      final controls = Controls();
      final game = LastfortGame(
        client: client,
        controls: controls,
        onInput: (_) {},
      );
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final saves = canvas.getSaveCount();
      game.render(canvas);
      expect(canvas.getSaveCount(), saves);
      recorder.endRecording().dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      controls.dispose();
      client.dispose();
    },
  );
}
