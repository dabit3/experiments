import 'blocks.dart';
import 'chunk.dart';
import 'hash.dart';
import 'worldgen.dart';

/// Chunk store with generated terrain plus an edit overlay. Used by the
/// server (authoritative) and by clients (mirror of what the server sent).
class World {
  World(this.seed) : gen = WorldGen(seed);

  final int seed;
  final WorldGen gen;
  final Map<int, Chunk> chunks = <int, Chunk>{};

  Chunk? chunkAt(int cx, int cz) => chunks[ChunkKey.of(cx, cz)];

  bool hasChunk(int cx, int cz) => chunks.containsKey(ChunkKey.of(cx, cz));

  Chunk ensureChunk(int cx, int cz) => chunks.putIfAbsent(ChunkKey.of(cx, cz), () => gen.generate(cx, cz));

  /// Returns the block id at world coordinates, generating the chunk if the
  /// server needs it. Clients call [peek] instead so they never generate
  /// chunks the server has not confirmed.
  int get(int x, int y, int z) {
    if (y < 0 || y >= WorldConst.height) return Ids.air;
    final c = ensureChunk(floorDiv(x, 16), floorDiv(z, 16));
    return c.get(floorMod(x, 16), y, floorMod(z, 16));
  }

  int peek(int x, int y, int z) {
    if (y < 0 || y >= WorldConst.height) return Ids.air;
    final c = chunkAt(floorDiv(x, 16), floorDiv(z, 16));
    if (c == null) return Ids.bedrock;
    return c.get(floorMod(x, 16), y, floorMod(z, 16));
  }

  bool isLoaded(int x, int z) => hasChunk(floorDiv(x, 16), floorDiv(z, 16));

  /// Sets a block and records it as an edit. Returns false if unchanged.
  bool set(int x, int y, int z, int id) {
    if (y < 0 || y >= WorldConst.height) return false;
    final c = ensureChunk(floorDiv(x, 16), floorDiv(z, 16));
    final lx = floorMod(x, 16), lz = floorMod(z, 16);
    final idx = Chunk.index(lx, y, lz);
    if (c.blocks[idx] == id) return false;
    c.blocks[idx] = id;
    c.edits[idx] = id;
    return true;
  }

  bool isSolid(int x, int y, int z) => Registry.block(peek(x, y, z)).solid;

  /// Highest solid/fluid block in the column, -1 if none (client-safe).
  int heightAt(int x, int z) {
    final c = chunkAt(floorDiv(x, 16), floorDiv(z, 16));
    if (c == null) return -1;
    return c.heightAt(floorMod(x, 16), floorMod(z, 16));
  }

  /// Sky exposure test: no opaque block above y in this column.
  bool skyVisible(int x, int y, int z) {
    for (var yy = y + 1; yy < WorldConst.height; yy++) {
      if (Registry.block(peek(x, yy, z)).opaque) return false;
    }
    return true;
  }

  /// Edits of a chunk as a flat list [idx, id, idx, id, ...].
  List<int> editsOf(int cx, int cz) {
    final c = chunkAt(cx, cz);
    if (c == null) return const [];
    final out = <int>[];
    final keys = c.edits.keys.toList()..sort();
    for (final k in keys) {
      out
        ..add(k)
        ..add(c.edits[k]!);
    }
    return out;
  }

  void applyEdits(int cx, int cz, List<int> flat) {
    final c = ensureChunk(cx, cz);
    for (var i = 0; i + 1 < flat.length; i += 2) {
      c.blocks[flat[i]] = flat[i + 1];
      c.edits[flat[i]] = flat[i + 1];
    }
  }

  /// Deterministic fingerprint of the world state: seed plus every edit,
  /// sorted by chunk then index. Identical on every peer that has the same
  /// edits applied, regardless of which chunks it has loaded.
  String editsHash() {
    final h = Fnv32()..addInt(seed);
    final keys = chunks.keys.toList()..sort();
    for (final k in keys) {
      final c = chunks[k]!;
      if (c.edits.isEmpty) continue;
      h.addInt(c.cx);
      h.addInt(c.cz);
      final idx = c.edits.keys.toList()..sort();
      for (final i in idx) {
        h.addInt(i);
        h.addByte(c.edits[i]!);
      }
    }
    return h.hex;
  }

  /// Fingerprint of the raw block bytes inside a region (inclusive corners).
  String regionHash(int x0, int y0, int z0, int x1, int y1, int z1) {
    final h = Fnv32();
    for (var y = y0; y <= y1; y++) {
      for (var z = z0; z <= z1; z++) {
        for (var x = x0; x <= x1; x++) {
          h.addByte(peek(x, y, z));
        }
      }
    }
    return h.hex;
  }

  Map<String, Object?> editsToJson() {
    final out = <String, Object?>{};
    for (final c in chunks.values) {
      if (c.edits.isEmpty) continue;
      out['${c.cx},${c.cz}'] = editsOf(c.cx, c.cz);
    }
    return out;
  }

  void editsFromJson(Map<String, Object?> j) {
    for (final e in j.entries) {
      final parts = e.key.split(',');
      final cx = int.parse(parts[0]), cz = int.parse(parts[1]);
      final flat = (e.value as List).map((v) => (v as num).toInt()).toList();
      applyEdits(cx, cz, flat);
    }
  }
}
