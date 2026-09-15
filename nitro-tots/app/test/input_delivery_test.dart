import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/game/controls.dart';
import 'package:nitro_tots/game/session.dart';
import 'package:nitro_tots/net/client.dart';

RaceSession _session(bool online) {
  if (online) {
    return NetSession.fromMatchStart(NetClient(platform: 'test'), {
      'racers': [
        {'slot': 0, 'playerId': 'p', 'name': 'Pip', 'character': 'pip', 'kart': 'jellybean', 'bot': false, 'platform': 'test'},
      ],
      'mode': 'battle',
      'trackId': 'bowl',
      'seed': 4242,
      'laps': 3,
      'battleSeconds': 120,
      'raceIndex': 0,
      'totalRaces': 1,
    }, 'p');
  }
  return LocalSession(
    sim: RaceSim(
      track: trackById('bowl'),
      racers: [Racer(slot: 0, playerId: 'p', name: 'Pip', characterId: 'pip', kartId: 'jellybean', isBot: false, platform: 'test')],
      seed: 4242,
      mode: GameMode.battle,
    ),
    info: const MatchInfo(trackId: 'bowl', laps: 3, mode: GameMode.battle, raceIndex: 0, totalRaces: 1),
    localSlot: 0,
    seed: 4242,
  );
}

void main() {
  for (final online in [false, true]) {
    for (final fps in [60, 120]) {
      test('${online ? 'network prediction' : 'local'} preserves a single item tap at $fps fps', () {
        final session = _session(online);
        addTearDown(session.dispose);
        session.sim
          ..phase = RacePhase.racing
          ..tick = countdownTicks;
        session.local!.item = ItemKind.rocket;
        final input = InputController(autoAccelerate: false)..pressItem();
        for (var frame = 0; frame < fps ~/ ticksPerSecond; frame++) {
          session.input = input.poll();
          session.advance(1 / fps);
        }
        expect(session.local!.item, isNull);
        expect(session.sim.projectiles, hasLength(1));
      });
    }
    test('${online ? 'network prediction' : 'local'} consumes one charge through a slow frame and accepts the next tap', () {
      final session = _session(online);
      addTearDown(session.dispose);
      session.sim
        ..phase = RacePhase.racing
        ..tick = countdownTicks;
      session.local!
        ..item = ItemKind.tripleTurbo
        ..itemCharges = 3;
      session.input = const KartInput(throttle: 1, steer: 0.5, drift: true, item: true, lookBack: true);
      session.advance(tickDt * 3.1);
      expect(session.local!.itemCharges, 2);
      expect(session.input.throttle, 1);
      expect(session.input.steer, 0.5);
      expect(session.input.drift, isTrue);
      expect(session.input.lookBack, isTrue);
      session.input = const KartInput(item: true);
      session.advance(tickDt);
      expect(session.local!.itemCharges, 1);
    });
  }
}
