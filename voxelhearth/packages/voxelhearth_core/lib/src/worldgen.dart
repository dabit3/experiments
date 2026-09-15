import 'blocks.dart';
import 'chunk.dart';
import 'noise.dart';
import 'rng.dart';

enum Biome { plains, forest, desert, tundra, mountains }

/// Deterministic terrain generator. The same seed produces the same chunk
/// bytes on the server and on every client platform, so only edits travel
/// over the wire.
class WorldGen {
  WorldGen(this.seed)
    : _height = ValueNoise(seed),
      _detail = ValueNoise(seed + 101),
      _temp = ValueNoise(seed + 202),
      _moist = ValueNoise(seed + 303),
      _cave = ValueNoise(seed + 404),
      _cave2 = ValueNoise(seed + 505),
      _ore = ValueNoise(seed + 606);

  final int seed;
  final ValueNoise _height, _detail, _temp, _moist, _cave, _cave2, _ore;

  Biome biomeAt(int x, int z) {
    final t = _temp.fbm2(x / 180.0, z / 180.0, 2);
    final m = _moist.fbm2(x / 150.0 + 40, z / 150.0 - 40, 2);
    final h = _rawHeight(x, z);
    if (h > 44) return Biome.mountains;
    if (t < 0.36) return Biome.tundra;
    if (t > 0.66 && m < 0.45) return Biome.desert;
    if (m > 0.55) return Biome.forest;
    return Biome.plains;
  }

  double _rawHeight(int x, int z) {
    final base = _height.fbm2(x / 140.0, z / 140.0, 4, persistence: 0.55);
    final d = _detail.fbm2(x / 32.0, z / 32.0, 3);
    final mountain = clamp01((base - 0.55) * 4.0);
    var h = 22 + base * 20 + d * 5 + mountain * mountain * 22;
    return h;
  }

  int surfaceHeight(int x, int z) {
    final h = _rawHeight(x, z).floor();
    return h.clamp(4, WorldConst.height - 4);
  }

  bool _isCave(int x, int y, int z) {
    if (y <= 2) return false;
    final a = _cave.noise3(x / 22.0, y / 14.0, z / 22.0);
    final b = _cave2.noise3(x / 22.0 + 100, y / 14.0, z / 22.0 - 100);
    final tunnel = (a - 0.5).abs() < 0.055 && (b - 0.5).abs() < 0.055;
    return tunnel;
  }

  int _oreAt(int x, int y, int z, Biome biome) {
    final n = _ore.noise3(x / 5.0, y / 5.0, z / 5.0);
    final h = hash3(x, y, z) & 0xffff;
    if (y < 10 && n > 0.78 && h < 9000) return Ids.emberOre;
    if (y < 16 && n > 0.76 && h < 14000) return Ids.goldOre;
    if (y < 30 && n > 0.74) return Ids.ironOre;
    if (y < 45 && n < 0.24) return Ids.coalOre;
    if (n > 0.86 && h < 6000) return Ids.gravel;
    return Ids.stone;
  }

  bool _hasTree(int x, int z, Biome biome) {
    final h = hash3(x, 7, z) & 0xffff;
    final dens = switch (biome) {
      Biome.forest => 0.045,
      Biome.plains => 0.0045,
      Biome.tundra => 0.018,
      Biome.mountains => 0.004,
      Biome.desert => 0.0,
    };
    if (h >= dens * 65536) return false;
    // Keep trees at least 2 apart by rejecting if a neighbour also wins.
    for (var dx = -2; dx <= 2; dx++) {
      for (var dz = -2; dz <= 2; dz++) {
        if (dx == 0 && dz == 0) continue;
        final nh = hash3(x + dx, 7, z + dz) & 0xffff;
        if (nh < dens * 65536 && nh < h) return false;
      }
    }
    final sh = surfaceHeight(x, z);
    return sh > WorldConst.seaLevel + 1 && sh < WorldConst.height - 10;
  }

  Chunk generate(int cx, int cz) {
    final c = Chunk(cx, cz);
    final baseX = cx * 16, baseZ = cz * 16;
    for (var lz = 0; lz < 16; lz++) {
      for (var lx = 0; lx < 16; lx++) {
        final x = baseX + lx, z = baseZ + lz;
        final biome = biomeAt(x, z);
        final sh = surfaceHeight(x, z);
        for (var y = 0; y <= sh; y++) {
          int id;
          if (y == 0 || (y == 1 && (hash3(x, y, z) & 1) == 0)) {
            id = Ids.bedrock;
          } else if (y == sh) {
            id = switch (biome) {
              Biome.desert => Ids.sand,
              Biome.tundra => Ids.snow,
              Biome.mountains => sh > 50 ? Ids.snow : Ids.stone,
              _ => sh <= WorldConst.seaLevel + 1 ? Ids.sand : Ids.grass,
            };
          } else if (y > sh - 4) {
            id = switch (biome) {
              Biome.desert => y > sh - 3 ? Ids.sand : Ids.stone,
              Biome.mountains => Ids.stone,
              _ => Ids.dirt,
            };
            if (id == Ids.dirt && y == sh - 1 && sh <= WorldConst.seaLevel + 1) {
              id = Ids.sand;
            }
          } else {
            id = _oreAt(x, y, z, biome);
          }
          if (id != Ids.bedrock && y > 2 && y < sh - 1 && _isCave(x, y, z)) {
            id = Ids.air;
          }
          c.set(lx, y, lz, id);
        }
        // Water fill.
        if (sh < WorldConst.seaLevel) {
          for (var y = sh + 1; y <= WorldConst.seaLevel; y++) {
            c.set(lx, y, lz, Ids.water);
          }
          if (biome != Biome.desert) {
            c.set(lx, sh, lz, hash3(x, 3, z) % 5 == 0 ? Ids.clay : Ids.sand);
          }
        } else {
          _decorate(c, lx, lz, x, z, sh, biome);
        }
      }
    }
    _trees(c, baseX, baseZ);
    return c;
  }

  void _decorate(Chunk c, int lx, int lz, int x, int z, int sh, Biome biome) {
    final top = c.get(lx, sh, lz);
    final h = hash3(x, 11, z) & 0xffff;
    if (top == Ids.grass) {
      if (h < 5500) {
        c.set(lx, sh + 1, lz, Ids.tallGrass);
      } else if (h < 6200) {
        c.set(lx, sh + 1, lz, Ids.flower);
      }
    } else if (top == Ids.sand && biome == Biome.desert && h < 500) {
      final height = 1 + (h % 3);
      for (var i = 1; i <= height; i++) {
        c.set(lx, sh + i, lz, Ids.cactus);
      }
    }
  }

  void _trees(Chunk c, int baseX, int baseZ) {
    for (var lz = -3; lz < 19; lz++) {
      for (var lx = -3; lx < 19; lx++) {
        final x = baseX + lx, z = baseZ + lz;
        final biome = biomeAt(x, z);
        if (biome == Biome.desert || !_hasTree(x, z, biome)) continue;
        final sh = surfaceHeight(x, z);
        final frost = biome == Biome.tundra;
        final trunk = 4 + (hash3(x, 9, z) % 3);
        final logId = frost ? Ids.frostLog : Ids.log;
        final leafId = frost ? Ids.frostLeaves : Ids.leaves;
        void put(int wx, int wy, int wz, int id, {bool onlyAir = true}) {
          final px = wx - baseX, pz = wz - baseZ;
          if (px < 0 || px > 15 || pz < 0 || pz > 15) return;
          if (wy < 0 || wy >= WorldConst.height) return;
          if (onlyAir && c.get(px, wy, pz) != Ids.air) return;
          c.set(px, wy, pz, id);
        }

        for (var i = 1; i <= trunk; i++) {
          put(x, sh + i, z, logId, onlyAir: false);
        }
        if (frost) {
          for (var layer = 0; layer < trunk; layer++) {
            final y = sh + trunk + 1 - layer;
            final r = layer % 2 == 0 ? (layer ~/ 2) + 1 : (layer ~/ 2) + 1;
            for (var dx = -r; dx <= r; dx++) {
              for (var dz = -r; dz <= r; dz++) {
                if (dx.abs() + dz.abs() > r + (layer % 2)) continue;
                put(x + dx, y, z + dz, leafId);
              }
            }
          }
          put(x, sh + trunk + 2, z, leafId);
        } else {
          for (var dy = -2; dy <= 1; dy++) {
            final y = sh + trunk + dy;
            final r = dy >= 0 ? 1 : 2;
            for (var dx = -r; dx <= r; dx++) {
              for (var dz = -r; dz <= r; dz++) {
                if (dx.abs() == r && dz.abs() == r && dy != -1) continue;
                if (dy == 1 && (dx.abs() + dz.abs()) > 1) continue;
                put(x + dx, y, z + dz, leafId);
              }
            }
          }
        }
      }
    }
  }

  /// Whether any tree canopy can reach column (x, z).
  bool _nearTree(int x, int z) {
    for (var dx = -3; dx <= 3; dx++) {
      for (var dz = -3; dz <= 3; dz++) {
        final b = biomeAt(x + dx, z + dz);
        if (b != Biome.desert && _hasTree(x + dx, z + dz, b)) return true;
      }
    }
    return false;
  }

  /// Safe spawn point near the origin: a dry, reasonably flat grass column
  /// with no tree canopy overhead. Falls back to any dry column, then sea level.
  List<int> findSpawn() {
    List<int>? fallback;
    for (var r = 0; r < 96; r++) {
      for (var dx = -r; dx <= r; dx++) {
        for (var dz = -r; dz <= r; dz++) {
          if (dx.abs() != r && dz.abs() != r) continue;
          final x = dx, z = dz;
          final sh = surfaceHeight(x, z);
          if (sh <= WorldConst.seaLevel + 1) continue;
          final biome = biomeAt(x, z);
          if (biome == Biome.mountains) continue;
          fallback ??= [x, sh + 1, z];
          if (biome != Biome.plains && biome != Biome.forest) continue;
          if (_nearTree(x, z)) continue;
          var flat = true;
          for (var ox = -2; ox <= 2 && flat; ox++) {
            for (var oz = -2; oz <= 2; oz++) {
              if ((surfaceHeight(x + ox, z + oz) - sh).abs() > 1) {
                flat = false;
                break;
              }
            }
          }
          if (flat) return [x, sh + 1, z];
        }
      }
    }
    return fallback ?? [0, WorldConst.seaLevel + 3, 0];
  }
}
