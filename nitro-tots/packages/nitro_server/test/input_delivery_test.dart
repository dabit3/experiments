import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_server/nitro_server.dart';
import 'package:test/test.dart';

void main() {
  test('an item packet survives newer steering packets before the server tick', () {
    final room = Room(
      code: 'TEST',
      seed: 4242,
      settings: const RoomSettings(mode: GameMode.battle, trackId: 'bowl', grandPrix: false, fillBots: false),
      now: () => 0,
    );
    room.addPlayer(Player(id: 'p', token: 'test-only', name: 'Pip', characterId: 'pip', kartId: 'jellybean', platform: 'test', send: (_) {}));
    room.startMatch('p');
    room.sim!
      ..phase = RacePhase.racing
      ..tick = countdownTicks;
    final racer = room.sim!.racers.single
      ..item = ItemKind.tripleTurbo
      ..itemCharges = 3;
    room.handleInput('p', {'tick': countdownTicks, 'i': 1});
    room.handleInput('p', {'tick': countdownTicks + 1, 't': 1, 's': 0.5});
    room.tick();
    expect(racer.itemCharges, 2);
    expect(racer.speed, greaterThan(0));
    room.tick();
    room.tick();
    expect(racer.itemCharges, 2);
    room.handleInput('p', {'tick': countdownTicks + 3, 'i': 1});
    room.tick();
    expect(racer.itemCharges, 1);
  });
}
