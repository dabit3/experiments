import 'dart:math' as math;
import 'dart:typed_data';

import 'constants.dart';
import 'items.dart';
import 'rng.dart';

enum Terrain { water, sand, grass, meadow, dirt, road, rock }

class Poi {
  Poi(this.name, this.x, this.y, this.radius);
  final String name;
  final double x;
  final double y;
  final double radius;

  Map<String, Object?> toJson() => {'name': name, 'x': x, 'y': y, 'r': radius};
}

class ResourceNode {
  ResourceNode(this.id, this.kind, this.x, this.y, this.hp, this.variant);
  final int id;
  final ResourceKind kind;
  final double x;
  final double y;
  int hp;

  /// Small deterministic visual variant (0-3) so forests do not look cloned.
  final int variant;
  int version = 0;

  bool get alive => hp > 0;

  Map<String, Object?> toJson() => {
        'id': id,
        'k': kind.name,
        'x': x,
        'y': y,
        'hp': hp,
        'max': kind.hp,
        'v': variant,
      };
}

class Chest {
  Chest(this.id, this.x, this.y);
  final int id;
  final double x;
  final double y;
  bool opened = false;
  int version = 0;

  Map<String, Object?> toJson() => {'id': id, 'x': x, 'y': y, 'o': opened};
}

class LootDrop {
  LootDrop(this.id, this.x, this.y, this.item);
  final int id;
  double x;
  double y;
  final Item item;

  Map<String, Object?> toJson() =>
      {'id': id, 'x': x, 'y': y, 'i': item.toJson()};
}

class Structure {
  Structure({
    required this.id,
    required this.gx,
    required this.gy,
    required this.piece,
    required this.material,
    required this.team,
    required this.hp,
    required this.maxHp,
    this.edit = PieceEdit.none,
    this.direction = 0,
    this.builtAtTick = 0,
  });

  final int id;
  final int gx;
  final int gy;
  final Piece piece;
  final Material material;

  /// -1 for pre-placed world buildings, otherwise the owning squad.
  final int team;
  int hp;
  int maxHp;
  PieceEdit edit;

  /// Ramp facing: 0 east, 1 south, 2 west, 3 north.
  int direction;
  final int builtAtTick;
  int version = 0;

  bool get blocksMovement => piece == Piece.wall && edit != PieceEdit.door;
  bool get blocksBullets => piece == Piece.wall && edit == PieceEdit.none;

  Map<String, Object?> toJson() => {
        'id': id,
        'gx': gx,
        'gy': gy,
        'p': piece.name,
        'm': material.name,
        't': team,
        'hp': hp,
        'max': maxHp,
        'e': edit.name,
        'd': direction,
        'b': builtAtTick,
      };
}

/// The generated island. Terrain, points of interest, pre-placed buildings,
/// resource nodes, chests and floor loot all derive from the seed with
/// integer-only noise so the server and every client agree bit for bit.
class World {
  World._(this.rules, this.seed, this.terrain, this.pois);

  final Rules rules;
  final int seed;
  final Uint8List terrain;
  final List<Poi> pois;
  final List<ResourceNode> nodes = [];
  final List<Chest> chests = [];
  final List<LootDrop> floorLoot = [];
  final List<Structure> buildings = [];
  final Map<int, List<ResourceNode>> nodesByTile = {};

  int get n => rules.tilesPerSide;
  double get centerX => rules.mapSize / 2;
  double get centerY => rules.mapSize / 2;

  int toTile(double v) => (v / rules.tileSize).floor();
  double tileCenter(int g) => (g + 0.5) * rules.tileSize;
  int tileKey(int gx, int gy) => gy * n + gx;
  bool inBounds(int gx, int gy) => gx >= 0 && gy >= 0 && gx < n && gy < n;

  Terrain terrainAt(int gx, int gy) {
    if (gx < 0 || gy < 0 || gx >= n || gy >= n) return Terrain.water;
    return Terrain.values[terrain[gy * n + gx]];
  }

  Terrain terrainAtWorld(double x, double y) =>
      terrainAt((x / rules.tileSize).floor(), (y / rules.tileSize).floor());

  bool isLand(int gx, int gy) => terrainAt(gx, gy) != Terrain.water;

  static const poiNames = [
    'Ember Yards',
    'Saltwick',
    'Hollow Pines',
    'Gridlock Depot',
    'Marrow Heights',
    'Cinder Flats',
    'Old Tidewall',
    'Quillmarket',
  ];

  static World generate(Rules rules, int seed) {
    final n = rules.tilesPerSide;
    final rng = Rng(seed);
    final noise = _Noise(rng.fork(11));
    final terrain = Uint8List(n * n);
    final half = n / 2;
    final radiusTiles = rules.islandRadius / rules.tileSize;

    for (var gy = 0; gy < n; gy++) {
      for (var gx = 0; gx < n; gx++) {
        final dx = gx + 0.5 - half;
        final dy = gy + 0.5 - half;
        final dist = math.sqrt(dx * dx + dy * dy) / radiusTiles;
        final shape = noise.fbm(gx / 46, gy / 46, 3) * 0.34 - 0.17;
        final height = 1 - dist + shape;
        final lake = noise.fbm(gx / 22 + 900, gy / 22 + 900, 2);
        Terrain t;
        if (height < 0.02) {
          t = Terrain.water;
        } else if (height < 0.075) {
          t = Terrain.sand;
        } else if (lake > 0.74 && height > 0.25) {
          t = Terrain.water;
        } else if (lake > 0.70 && height > 0.25) {
          t = Terrain.sand;
        } else {
          final detail = noise.fbm(gx / 9 + 300, gy / 9 + 300, 2);
          if (height > 0.62 && detail > 0.55) {
            t = Terrain.rock;
          } else if (detail > 0.63) {
            t = Terrain.meadow;
          } else if (detail < 0.36) {
            t = Terrain.dirt;
          } else {
            t = Terrain.grass;
          }
        }
        terrain[gy * n + gx] = t.index;
      }
    }

    final world = World._(rules, seed, terrain, []);
    world._placePois(rng.fork(21));
    world._carveRoads();
    world._placeBuildings(rng.fork(31));
    world._placeNodes(noise, rng.fork(41));
    world._placeFloorLoot(rng.fork(51));
    for (final node in world.nodes) {
      world.nodesByTile
          .putIfAbsent(
              world.tileKey(world.toTile(node.x), world.toTile(node.y)),
              () => [])
          .add(node);
    }
    return world;
  }

  void _placePois(Rng rng) {
    final names = List.of(poiNames);
    final count = 6;
    var attempts = 0;
    while (pois.length < count && attempts < 4000) {
      attempts++;
      final x = rng.range(rules.mapSize * 0.22, rules.mapSize * 0.78);
      final y = rng.range(rules.mapSize * 0.22, rules.mapSize * 0.78);
      final gx = (x / rules.tileSize).floor();
      final gy = (y / rules.tileSize).floor();
      if (!_landPatch(gx, gy, 9)) continue;
      var ok = true;
      for (final p in pois) {
        final dx = p.x - x;
        final dy = p.y - y;
        if (dx * dx + dy * dy < 170 * 170) ok = false;
      }
      if (!ok) continue;
      final idx = rng.nextInt(names.length);
      pois.add(Poi(names.removeAt(idx), x, y, rng.range(48, 70)));
    }
  }

  bool _landPatch(int gx, int gy, int r) {
    for (var y = gy - r; y <= gy + r; y++) {
      for (var x = gx - r; x <= gx + r; x++) {
        if (!isLand(x, y)) return false;
      }
    }
    return true;
  }

  void _carveRoads() {
    for (var i = 0; i < pois.length; i++) {
      final a = pois[i];
      final b = pois[(i + 1) % pois.length];
      _road(a, b);
    }
  }

  void _road(Poi a, Poi b) {
    var x0 = (a.x / rules.tileSize).floor();
    var y0 = (a.y / rules.tileSize).floor();
    final x1 = (b.x / rules.tileSize).floor();
    final y1 = (b.y / rules.tileSize).floor();
    final dx = (x1 - x0).abs();
    final dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx + dy;
    while (true) {
      for (var oy = 0; oy <= 1; oy++) {
        for (var ox = 0; ox <= 1; ox++) {
          final gx = x0 + ox;
          final gy = y0 + oy;
          if (gx >= 0 && gy >= 0 && gx < n && gy < n) {
            final t = terrainAt(gx, gy);
            if (t != Terrain.water && t != Terrain.sand) {
              terrain[gy * n + gx] = Terrain.road.index;
            }
          }
        }
      }
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
  }

  void _placeBuildings(Rng rng) {
    var structureId = 1;
    var chestId = 1;
    final occupied = <int>{};
    for (final poi in pois) {
      final houses = 3 + rng.nextInt(3);
      var placed = 0;
      var attempts = 0;
      while (placed < houses && attempts < 60) {
        attempts++;
        final w = 4 + rng.nextInt(3);
        final h = 3 + rng.nextInt(3);
        final cx = poi.x + rng.range(-poi.radius, poi.radius);
        final cy = poi.y + rng.range(-poi.radius, poi.radius);
        final gx0 = (cx / rules.tileSize).floor() - w ~/ 2;
        final gy0 = (cy / rules.tileSize).floor() - h ~/ 2;
        var ok = true;
        for (var y = gy0 - 1; y <= gy0 + h && ok; y++) {
          for (var x = gx0 - 1; x <= gx0 + w && ok; x++) {
            if (!isLand(x, y) || occupied.contains(y * n + x)) ok = false;
          }
        }
        if (!ok) continue;
        final material = rng.chance(0.3) ? Material.metal : Material.stone;
        final doorSide = rng.nextInt(4);
        final doorOffset =
            1 + rng.nextInt(math.max(1, (doorSide.isEven ? w : h) - 2));
        for (var y = gy0; y < gy0 + h; y++) {
          for (var x = gx0; x < gx0 + w; x++) {
            occupied.add(y * n + x);
            final edge =
                x == gx0 || x == gx0 + w - 1 || y == gy0 || y == gy0 + h - 1;
            if (!edge) {
              buildings.add(Structure(
                id: structureId++,
                gx: x,
                gy: y,
                piece: Piece.floor,
                material: Material.wood,
                team: -1,
                hp: Material.wood.maxHp,
                maxHp: Material.wood.maxHp,
              ));
              continue;
            }
            var edit = PieceEdit.none;
            final isDoor = switch (doorSide) {
              0 => y == gy0 && x == gx0 + doorOffset,
              1 => x == gx0 + w - 1 && y == gy0 + doorOffset,
              2 => y == gy0 + h - 1 && x == gx0 + doorOffset,
              _ => x == gx0 && y == gy0 + doorOffset,
            };
            if (isDoor) {
              edit = PieceEdit.door;
            } else if (rng.chance(0.18)) {
              edit = PieceEdit.window;
            }
            buildings.add(Structure(
              id: structureId++,
              gx: x,
              gy: y,
              piece: Piece.wall,
              material: material,
              team: -1,
              hp: material.maxHp,
              maxHp: material.maxHp,
              edit: edit,
            ));
          }
        }
        // Chest inside every house, sometimes two.
        final chestCount = 1 + (rng.chance(0.35) ? 1 : 0);
        for (var c = 0; c < chestCount; c++) {
          final x = gx0 + 1 + rng.nextInt(math.max(1, w - 2));
          final y = gy0 + 1 + rng.nextInt(math.max(1, h - 2));
          chests.add(Chest(chestId++, (x + 0.5) * rules.tileSize,
              (y + 0.5) * rules.tileSize));
        }
        placed++;
      }
      // Loose chests around the point of interest.
      for (var c = 0; c < 3; c++) {
        final x = poi.x + rng.range(-poi.radius, poi.radius);
        final y = poi.y + rng.range(-poi.radius, poi.radius);
        final gx = (x / rules.tileSize).floor();
        final gy = (y / rules.tileSize).floor();
        if (isLand(gx, gy) && !occupied.contains(gy * n + gx)) {
          occupied.add(gy * n + gx);
          chests.add(Chest(chestId++, (gx + 0.5) * rules.tileSize,
              (gy + 0.5) * rules.tileSize));
        }
      }
    }
    // Wilderness chests.
    var attempts = 0;
    while (chests.length < pois.length * 6 + 24 && attempts < 3000) {
      attempts++;
      final gx = rng.nextInt(n);
      final gy = rng.nextInt(n);
      if (!isLand(gx, gy) || occupied.contains(gy * n + gx)) continue;
      if (terrainAt(gx, gy) == Terrain.sand) continue;
      occupied.add(gy * n + gx);
      chests.add(Chest(
          chestId++, (gx + 0.5) * rules.tileSize, (gy + 0.5) * rules.tileSize));
    }
    _occupied = occupied;
  }

  Set<int> _occupied = {};

  void _placeNodes(_Noise noise, Rng rng) {
    var id = 1;
    final step = 3;
    for (var gy = 2; gy < n - 2; gy += step) {
      for (var gx = 2; gx < n - 2; gx += step) {
        final t = terrainAt(gx, gy);
        if (t == Terrain.water || t == Terrain.sand || t == Terrain.road) {
          continue;
        }
        if (_occupied.contains(gy * n + gx)) continue;
        final forest = noise.fbm(gx / 14 + 5000, gy / 14 + 5000, 2);
        ResourceKind? kind;
        if (t == Terrain.rock) {
          if (rng.chance(0.55)) kind = ResourceKind.rock;
        } else if (forest > 0.56 && rng.chance(0.7)) {
          kind = ResourceKind.tree;
        } else if (t == Terrain.dirt && rng.chance(0.12)) {
          kind = ResourceKind.rock;
        }
        if (kind == null) continue;
        final x = (gx + rng.range(0.2, 0.8)) * rules.tileSize;
        final y = (gy + rng.range(0.2, 0.8)) * rules.tileSize;
        nodes.add(ResourceNode(id++, kind, x, y, kind.hp, rng.nextInt(4)));
      }
    }
    // Cars near roads and points of interest.
    for (final poi in pois) {
      for (var c = 0; c < 5; c++) {
        final x = poi.x + rng.range(-poi.radius * 1.3, poi.radius * 1.3);
        final y = poi.y + rng.range(-poi.radius * 1.3, poi.radius * 1.3);
        final gx = (x / rules.tileSize).floor();
        final gy = (y / rules.tileSize).floor();
        if (!isLand(gx, gy) || _occupied.contains(gy * n + gx)) continue;
        nodes.add(ResourceNode(
            id++, ResourceKind.car, x, y, ResourceKind.car.hp, rng.nextInt(4)));
      }
    }
  }

  void _placeFloorLoot(Rng rng) {
    var id = 1;
    for (final poi in pois) {
      for (var i = 0; i < 14; i++) {
        final x = poi.x + rng.range(-poi.radius, poi.radius);
        final y = poi.y + rng.range(-poi.radius, poi.radius);
        if (!isLand(
            (x / rules.tileSize).floor(), (y / rules.tileSize).floor())) {
          continue;
        }
        floorLoot.add(LootDrop(id++, x, y, rollFloorLoot(rng)));
      }
    }
    var attempts = 0;
    while (floorLoot.length < pois.length * 14 + 60 && attempts < 3000) {
      attempts++;
      final x = rng.range(0, rules.mapSize);
      final y = rng.range(0, rules.mapSize);
      final gx = (x / rules.tileSize).floor();
      final gy = (y / rules.tileSize).floor();
      if (!isLand(gx, gy) || terrainAt(gx, gy) == Terrain.sand) continue;
      floorLoot.add(LootDrop(id++, x, y, rollFloorLoot(rng)));
    }
  }

  static Item rollFloorLoot(Rng rng) {
    final roll = rng.nextDouble();
    if (roll < 0.42) {
      return rollWeapon(rng, LootTable.floorRarityWeights);
    } else if (roll < 0.66) {
      final ammo = AmmoType.values[rng.nextInt(AmmoType.values.length)];
      return Item.ammo(ammo, LootTable.ammoPerPickup[ammo]!);
    } else if (roll < 0.86) {
      final kinds = [
        ConsumableKind.bandage,
        ConsumableKind.bandage,
        ConsumableKind.smallShield,
        ConsumableKind.smallShield,
        ConsumableKind.bigShield,
        ConsumableKind.medkit,
      ];
      final kind = rng.pick(kinds);
      return Item.consumable(kind, kind == ConsumableKind.bandage ? 3 : 2);
    } else {
      final mat = Material.values[rng.nextInt(3)];
      return Item.material(mat, 30);
    }
  }

  static Item rollWeapon(Rng rng, List<double> rarityWeights) {
    final kind = WeaponKind.values[rng.weighted(LootTable.weaponWeights)];
    var rarity = Rarity.values[rng.weighted(rarityWeights)];
    if (rarity.index < kind.def.minRarity.index) rarity = kind.def.minRarity;
    return Item.weapon(kind, rarity);
  }

  static List<Item> rollChest(Rng rng) {
    final weapon = rollWeapon(rng, LootTable.chestRarityWeights);
    final ammo = weapon.weapon!.def.ammo;
    final consumables = [
      ConsumableKind.smallShield,
      ConsumableKind.bigShield,
      ConsumableKind.bandage,
      ConsumableKind.medkit,
    ];
    final c = rng.pick(consumables);
    return [
      weapon,
      Item.ammo(ammo, LootTable.ammoPerPickup[ammo]! * 2),
      Item.consumable(c, c == ConsumableKind.bandage ? 3 : 2),
      Item.material(Material.values[rng.nextInt(3)], 60),
    ];
  }

  /// Deterministic bus path: enters from one edge of the island and exits
  /// through the opposite side, passing near the centre.
  ({double x0, double y0, double x1, double y1}) busPath(Rng rng) {
    final centre = rules.mapSize / 2;
    final reach = rules.islandRadius * 0.92;
    final offset = rng.range(-reach * 0.35, reach * 0.35);
    final side = rng.nextInt(4);
    final lo = centre - reach;
    final hi = centre + reach;
    return switch (side) {
      0 => (x0: lo, y0: centre + offset, x1: hi, y1: centre - offset),
      1 => (x0: hi, y0: centre + offset, x1: lo, y1: centre - offset),
      2 => (x0: centre + offset, y0: lo, x1: centre - offset, y1: hi),
      _ => (x0: centre + offset, y0: hi, x1: centre - offset, y1: lo),
    };
  }
}

/// Integer-hash value noise with bilinear interpolation. Uses no
/// transcendental functions so results are identical on the Dart VM and on
/// the web.
class _Noise {
  _Noise(Rng rng) : _salt = rng.nextInt32();
  final int _salt;

  double _hash(int x, int y) {
    var h = (x * 374761393 + y * 668265263 + _salt) & 0xFFFFFFFF;
    h = mul32(h ^ (h >> 13), 1274126177);
    h ^= h >> 16;
    return (h & 0xFFFF) / 65535.0;
  }

  double value(double x, double y) {
    final x0 = x.floor();
    final y0 = y.floor();
    final fx = x - x0;
    final fy = y - y0;
    final sx = fx * fx * (3 - 2 * fx);
    final sy = fy * fy * (3 - 2 * fy);
    final a = _hash(x0, y0);
    final b = _hash(x0 + 1, y0);
    final c = _hash(x0, y0 + 1);
    final d = _hash(x0 + 1, y0 + 1);
    final top = a + (b - a) * sx;
    final bottom = c + (d - c) * sx;
    return top + (bottom - top) * sy;
  }

  double fbm(double x, double y, int octaves) {
    var amp = 0.5;
    var freq = 1.0;
    var sum = 0.0;
    var norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += value(x * freq, y * freq) * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2;
    }
    return sum / norm;
  }
}
