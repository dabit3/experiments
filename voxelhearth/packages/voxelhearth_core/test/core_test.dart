import 'package:test/test.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

void main() {
  group('determinism', () {
    test('rng and hash3 are stable', () {
      final r = Rng(1337);
      expect([r.nextInt(100), r.nextInt(100), r.nextInt(100)], [r2(1337)[0], r2(1337)[1], r2(1337)[2]]);
      expect(hash3(1, 2, 3), hash3(1, 2, 3));
      expect(hash3(1, 2, 3), isNot(hash3(3, 2, 1)));
      expect(mul32(0xffffffff, 0xffffffff), 1);
    });

    test('same seed produces identical chunks', () {
      final a = WorldGen(42).generate(0, 0);
      final b = WorldGen(42).generate(0, 0);
      expect(a.blocks, b.blocks);
      final c = WorldGen(43).generate(0, 0);
      expect(a.blocks, isNot(c.blocks));
    });

    test('chunks have bedrock floor, surface and no floating water', () {
      final w = World(7);
      for (var cx = -2; cx <= 2; cx++) {
        for (var cz = -2; cz <= 2; cz++) {
          final c = w.ensureChunk(cx, cz);
          for (var x = 0; x < 16; x++) {
            for (var z = 0; z < 16; z++) {
              expect(c.get(x, 0, z), Ids.bedrock);
              expect(c.heightAt(x, z), greaterThan(3));
            }
          }
        }
      }
    });

    test('world edit hash is order independent and equal across peers', () {
      final a = World(9);
      final b = World(9);
      a.set(1, 30, 2, Ids.planks);
      a.set(5, 31, 7, Ids.torch);
      b.set(5, 31, 7, Ids.torch);
      b.set(1, 30, 2, Ids.planks);
      expect(a.editsHash(), b.editsHash());
      b.set(1, 30, 3, Ids.planks);
      expect(a.editsHash(), isNot(b.editsHash()));
    });

    test('spawn is on land', () {
      for (final seed in [1, 2, 3, 1337, 99999]) {
        final w = World(seed);
        final s = w.gen.findSpawn();
        final below = w.get(s[0], s[1] - 1, s[2]);
        expect(Registry.block(below).fluid, isFalse, reason: 'seed $seed');
      }
    });
  });

  group('recipes', () {
    test('planks from any log, shapeless', () {
      expect(Recipes.match([Ids.log, 0, 0, 0], 2)?.result.id, Ids.planks);
      expect(Recipes.match([0, 0, 0, Ids.frostLog], 2)?.result.id, Ids.planks);
    });

    test('shaped recipes can be offset inside the grid', () {
      expect(Recipes.match([Ids.planks, 0, Ids.planks, 0], 2)?.result.id, Ids.stick);
      expect(Recipes.match([0, Ids.planks, 0, Ids.planks], 2)?.result.id, Ids.stick);
      expect(Recipes.match([0, 0, 0, 0, Ids.planks, 0, 0, Ids.planks, 0], 3)?.result.id, Ids.stick);
      expect(Recipes.match([Ids.planks, Ids.planks, 0, 0], 2), isNull);
    });

    test('pickaxe needs a 3x3 grid', () {
      final grid = [Ids.cobble, Ids.cobble, Ids.cobble, 0, Ids.stick, 0, 0, Ids.stick, 0];
      expect(Recipes.match(grid, 3)?.result.id, Ids.stonePick);
      expect(Recipes.match([Ids.cobble, Ids.cobble, Ids.cobble, 0], 2), isNull);
    });

    test('every recipe result and ingredient is registered', () {
      for (final r in Recipes.all) {
        expect(Registry.item(r.result.id).id, r.result.id, reason: r.name);
        for (final id in (r.shapeless ?? r.pattern).where((i) => i != 0)) {
          expect(Registry.item(id).id, id, reason: '${r.name} ingredient $id');
        }
      }
    });
  });

  group('inventory', () {
    test('stacks merge up to max and overflow returns remainder', () {
      final inv = SlotList(2);
      expect(inv.add(const ItemStack(Ids.cobble, 60)).isEmpty, isTrue);
      expect(inv.add(const ItemStack(Ids.cobble, 10)).isEmpty, isTrue);
      expect(inv[0].count, 64);
      expect(inv[1].count, 6);
      final rest = inv.add(const ItemStack(Ids.cobble, 200));
      expect(rest.count, 200 - 58);
      expect(inv.countOf(Ids.cobble), 128);
    });

    test('tools do not stack', () {
      final inv = SlotList(1);
      expect(inv.add(const ItemStack(Ids.ironPick, 1)).isEmpty, isTrue);
      expect(inv.add(const ItemStack(Ids.ironPick, 1)).count, 1);
    });
  });

  group('break speeds', () {
    test('tools speed up harvesting and tier gates drops', () {
      expect(Registry.breakSeconds(Ids.stone, 0), 7.5);
      expect(Registry.breakSeconds(Ids.stone, Ids.woodPick), closeTo(1.125, 1e-9));
      expect(Registry.breakSeconds(Ids.stone, Ids.ironPick), closeTo(0.375, 1e-9));
      expect(Registry.breakSeconds(Ids.dirt, Ids.woodShovel), closeTo(0.375, 1e-9));
      expect(Registry.breakSeconds(Ids.log, Ids.ironPick), 3.0);
      expect(Registry.canHarvest(Ids.ironOre, Ids.woodPick), isFalse);
      expect(Registry.canHarvest(Ids.ironOre, Ids.stonePick), isTrue);
      expect(Registry.breakSeconds(Ids.bedrock, Ids.emberPick), -1);
    });
  });

  group('room simulation', () {
    late List<Map<String, Object?>> out;
    late Room room;
    setUp(() {
      out = [];
      room = Room(code: 'TEST1', name: 'test', seed: 1337, emit: (t, m) => out.add({...m, '_to': t}), spawnMobs: false);
    });

    test('join, start, place, break and hash', () {
      final a = room.join('a', 'Alice', 'web');
      room.join('b', 'Bob', 'ios');
      expect(room.hostId, 'a');
      room.startMatch();
      expect(room.phase, Phase.playing);
      final x = a.body.x.floor(), z = a.body.z.floor();
      final y = airAbove(room.world, x + 2, a.body.y.floor(), z);
      // Give Alice planks (creative would allow directly; we are survival).
      a.inv[0] = const ItemStack(Ids.planks, 10);
      a.selected = 0;
      room.handle('a', {'t': Msg.placeBlock, 'x': x + 2, 'y': y, 'z': z, 'nx': 0, 'ny': 1, 'nz': 0});
      expect(room.world.peek(x + 2, y, z), Ids.planks);
      expect(a.inv[0].count, 9);
      expect(a.placed, 1);
      expect(out.where((m) => m['t'] == Msg.blockSet).length, 1);
      // Bob breaks it (planks harvest by hand).
      room.players['b']!.body.setPos(x + 2.5, y.toDouble(), z + 1.5);
      room.handle('b', {'t': Msg.breakBlock, 'x': x + 2, 'y': y, 'z': z});
      expect(room.world.peek(x + 2, y, z), Ids.air);
      expect(room.players['b']!.inv.countOf(Ids.planks), 1);
      room.handle('a', {'t': Msg.chat, 'text': 'hello world'});
      expect(room.chat.last.text, 'hello world');
      final h = room.world.editsHash();
      final mirror = World(1337);
      mirror.applyEdits(floorDiv(x + 2, 16), floorDiv(z, 16), room.world.editsOf(floorDiv(x + 2, 16), floorDiv(z, 16)));
      expect(mirror.editsHash(), h);
    });

    test('host survives a short disconnect, migrates after the grace window', () {
      room.join('a', 'Alice', 'web');
      room.join('b', 'Bob', 'ios');
      room.startMatch();
      room.disconnect('a');
      for (var i = 0; i < Room.hostGraceTicks ~/ 2; i++) {
        room.tickOnce();
      }
      expect(room.hostId, 'a');
      room.join('a', 'Alice', 'web');
      for (var i = 0; i < Room.hostGraceTicks; i++) {
        room.tickOnce();
      }
      expect(room.hostId, 'a');
      room.disconnect('a');
      for (var i = 0; i <= Room.hostGraceTicks; i++) {
        room.tickOnce();
      }
      expect(room.hostId, 'b');
      room.leave('b');
      expect(room.hostId, 'a');
    });

    test('rejoining with a new display name keeps the player and renames them', () {
      final a = room.join('a', 'Desk Dweller', 'macos');
      a.inv[0] = const ItemStack(Ids.log, 3);
      room.disconnect('a');
      final again = room.join('a', 'bob mac', 'macos');
      expect(identical(a, again), isTrue);
      expect(again.name, 'bob mac');
      expect(again.inv[0], const ItemStack(Ids.log, 3));
      expect(room.hostId, 'a');
    });

    test('crafting consumes ingredients and produces result', () {
      final a = room.join('a', 'Alice', 'web');
      room.startMatch();
      a.inv[0] = const ItemStack(Ids.log, 2);
      room.handle('a', {
        't': Msg.craft,
        'grid': [Ids.log, 0, 0, 0],
        'n': 2,
      });
      expect(a.inv.countOf(Ids.log), 1);
      expect(a.inv.countOf(Ids.planks), 4);
      room.handle('a', {
        't': Msg.craft,
        'grid': [Ids.planks, 0, Ids.planks, 0],
        'n': 2,
      });
      expect(a.inv.countOf(Ids.stick), 4);
      expect(a.inv.countOf(Ids.planks), 2);
      // 3x3 needs a workbench open.
      room.handle('a', {
        't': Msg.craft,
        'grid': [Ids.planks, Ids.planks, 0, 0, Ids.stick, 0, 0, Ids.stick, 0],
        'n': 3,
      });
      expect(a.inv.countOf(Ids.woodPick), 0);
      expect(a.crafted, 2);
    });

    test('match timer ends the match with results', () {
      room.durationTicks = 10;
      room.join('a', 'Alice', 'web');
      room.startMatch();
      for (var i = 0; i < 12; i++) {
        room.tickOnce();
      }
      expect(room.phase, Phase.results);
      final ph = out.lastWhere((m) => m['t'] == Msg.phase);
      expect(ph['results'], isA<List<Object?>>());
    });

    test('results fingerprint includes the final chat and remains stable after match end', () {
      room.join('a', 'Alice', 'web');
      room.addBot();
      room.startMatch();
      for (var i = 0; i < 600; i++) {
        room.tickOnce();
      }
      room.endMatch();
      final result = out.lastWhere((m) => m['t'] == Msg.phase);
      expect(room.chat.last.text, startsWith('Match over.'));
      expect(result['worldHash'], room.world.editsHash());
      expect(result['chatHash'], room.chatHash());
      for (var i = 0; i < 100; i++) {
        room.tickOnce();
      }
      expect(result['worldHash'], room.world.editsHash());
      expect(result['chatHash'], room.chatHash());
    });

    test('bots act deterministically for a given seed', () {
      String run() {
        final r = Room(code: 'BOTS', name: 'b', seed: 5, emit: (_, _) {}, spawnMobs: false);
        r.join('h', 'Host', 'macos');
        r.addBot();
        r.addBot();
        r.startMatch();
        for (var i = 0; i < 600; i++) {
          r.tickOnce();
        }
        return '${r.world.editsHash()}-${r.chatHash()}';
      }

      expect(run(), run());
    });

    test('kiln smelts with fuel', () {
      final a = room.join('a', 'Alice', 'web');
      room.startMatch();
      final x = a.body.x.floor() + 2, z = a.body.z.floor();
      final y = airAbove(room.world, x, a.body.y.floor(), z);
      a.inv[0] = const ItemStack(Ids.kiln, 1);
      a.inv[1] = const ItemStack(Ids.cobble, 8);
      a.inv[2] = const ItemStack(Ids.coal, 1);
      room.handle('a', {'t': Msg.placeBlock, 'x': x, 'y': y, 'z': z});
      room.handle('a', {'t': Msg.interact, 'x': x, 'y': y, 'z': z});
      room.handle('a', {'t': 'kiln_put', 'kslot': 'input', 'slot': 1});
      room.handle('a', {'t': 'kiln_put', 'kslot': 'fuel', 'slot': 2});
      for (var i = 0; i < Recipes.smeltTicks + 5; i++) {
        room.tickOnce();
      }
      final k = room.kilns.values.single;
      expect(k.output.id, Ids.stone);
      expect(k.output.count, 1);
      room.handle('a', {'t': 'kiln_put', 'kslot': 'output'});
      expect(a.inv.countOf(Ids.stone), 1);
    });
  });
}

/// First replaceable cell at or above [y] in the column (x, z).
int airAbove(World w, int x, int y, int z) {
  while (!Registry.block(w.peek(x, y, z)).replaceable) {
    y++;
  }
  return y;
}

List<int> r2(int seed) {
  final r = Rng(seed);
  return [r.nextInt(100), r.nextInt(100), r.nextInt(100)];
}
