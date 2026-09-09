import 'dart:typed_data';

/// World constants shared by every client and the server.
class WorldConst {
  static const chunkSize = 16;
  static const height = 64;
  static const seaLevel = 26;
  static const dayTicks = 24000;
  static const ticksPerSecond = 20;
  static const chunkVolume = chunkSize * chunkSize * height;
}

/// One 16x16 column of blocks, 64 high. Index = (y * 16 + z) * 16 + x.
class Chunk {
  Chunk(this.cx, this.cz) : blocks = Uint8List(WorldConst.chunkVolume);

  final int cx;
  final int cz;
  final Uint8List blocks;

  /// Player edits applied on top of the generated terrain. Index -> id.
  final Map<int, int> edits = <int, int>{};

  static int index(int x, int y, int z) => (y * 16 + z) * 16 + x;

  int get(int x, int y, int z) {
    if (y < 0 || y >= WorldConst.height) return 0;
    return blocks[index(x, y, z)];
  }

  void set(int x, int y, int z, int id) {
    if (y < 0 || y >= WorldConst.height) return;
    blocks[index(x, y, z)] = id;
  }

  /// Top-most non-air y in the column, or -1.
  int heightAt(int x, int z) {
    for (var y = WorldConst.height - 1; y >= 0; y--) {
      if (blocks[index(x, y, z)] != 0) return y;
    }
    return -1;
  }
}

class ChunkKey {
  static int of(int cx, int cz) => (cx + 0x8000) * 0x10000 + (cz + 0x8000);
  static int cxOf(int key) => key ~/ 0x10000 - 0x8000;
  static int czOf(int key) => key % 0x10000 - 0x8000;
}

/// Packs a world block position into one int (used as map key / wire id).
class BlockPos {
  static int key(int x, int y, int z) => ((x + 0x800000) * 64 + y) * 0x1000000 + (z + 0x800000);

  static int xOf(int key) => key ~/ (64 * 0x1000000) - 0x800000;
  static int yOf(int key) => (key ~/ 0x1000000) % 64;
  static int zOf(int key) => key % 0x1000000 - 0x800000;
}

int floorDiv(int a, int b) => (a / b).floor();

int floorMod(int a, int b) => a - floorDiv(a, b) * b;
