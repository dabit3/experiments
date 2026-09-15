import 'dart:convert';

import 'package:voxelhearth_core/voxelhearth_core.dart';

void check(String name, bool passed) {
  if (!passed) throw StateError(name);
  print('PASS $name');
}

void main() {
  final room = Room(
    code: 'PROBE',
    name: 'Final acceptance',
    seed: 1234,
    spawnMobs: false,
    durationTicks: 0,
    emit: (_, _) {},
  );
  final player = room.join('host', 'Host', 'web');
  room.startMatch();
  final x = player.body.x.floor();
  final y = player.body.y.floor();
  final z = player.body.z.floor();
  final time = room.timeOfDay;
  room.tickOnce();
  check('day clock advances during play', room.timeOfDay == time + 1);

  room.world.set(x + 1, y, z, Ids.bed);
  room.setTime(6000);
  room.handle('host', {'t': Msg.sleep, 'x': x + 1, 'y': y, 'z': z});
  check('bed sets a spawn point during the day', player.bedPos != null);
  room.setTime(18000);
  room.handle('host', {'t': Msg.sleep, 'x': x + 1, 'y': y, 'z': z});
  check(
    'sleep skips night and clears sleeping state',
    !room.isNight && !player.sleeping,
  );

  room.world.set(x - 1, y, z, Ids.chest);
  room.handle('host', {'t': Msg.interact, 'x': x - 1, 'y': y, 'z': z});
  player.inv[0] = const ItemStack(Ids.stone, 7);
  room.handle('host', {
    't': 'chest_put',
    'slot': 0,
    'cslot': 0,
    'toChest': true,
  });
  check(
    'chest transfer removes inventory and stores seven blocks',
    player.inv[0].isEmpty && room.chests.values.single[0].count == 7,
  );
  player.inv[1] = const ItemStack(Ids.coal, 3);
  room.handle('host', {'t': Msg.chat, 'text': 'persistent acceptance'});
  room.world.set(x, y, z + 1, Ids.kiln);
  room.handle('host', {'t': Msg.interact, 'x': x, 'y': y, 'z': z + 1});
  room.kilns.values.single.input = const ItemStack(Ids.cobble, 2);
  room.kilns.values.single.burnLeft = 100;
  final saved = jsonDecode(jsonEncode(room.toSave())) as Map<String, Object?>;
  final restored = Room(
    code: 'PROBE',
    name: 'Restored',
    seed: 1234,
    emit: (_, _) {},
  )..loadSave(saved);
  final persistedChat = restored.chatHash();
  final rejoined = restored.join(
    'host',
    'Host',
    'ios',
    saved: restored.savedPlayers.remove('host'),
  );
  check(
    'JSON save/load preserves world, chat, chest, kiln and inventory',
    restored.world.editsHash() == room.world.editsHash() &&
        persistedChat == room.chatHash() &&
        restored.chests.values.single[0].count == 7 &&
        restored.kilns.values.single.input.count == 2 &&
        restored.kilns.values.single.burnLeft == 100 &&
        rejoined.inv[1].count == 3,
  );

  player.health = 20;
  player.hunger = 0;
  player.regenTimer = 0;
  for (var i = 0; i < 80; i++) {
    room.tickOnce();
  }
  check('starvation reduces health', player.health == 19);
  player.hunger = 10;
  player.air = 1;
  room.world.set(x, y, z, Ids.water);
  room.world.set(x, y + 1, z, Ids.water);
  for (var i = 0; i < 20; i++) {
    room.tickOnce();
  }
  check(
    'submersion drains air and damages health',
    player.air == 0 && player.health < 19,
  );
  room.setMode(GameMode.creative);
  final health = player.health;
  for (var i = 0; i < 40; i++) {
    room.tickOnce();
  }
  check('creative mode prevents survival damage', player.health == health);
  room.endMatch();
  final finalWorld = room.world.editsHash();
  final finalChat = room.chatHash();
  for (var i = 0; i < 100; i++) {
    room.tickOnce();
  }
  check(
    'results remain stable after ticking',
    room.world.editsHash() == finalWorld && room.chatHash() == finalChat,
  );
}
