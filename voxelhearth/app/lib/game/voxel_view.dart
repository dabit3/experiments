import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:voxelhearth_core/voxelhearth_core.dart';

/// The renderable window of the world: a 128x64x128 block volume around the
/// player, with sky/block lighting, packed into four 512x512 RGBA textures
/// (one per 64x64 quadrant, 8x8 slices of 64x64 per texture).
class VoxelView {
  VoxelView(this.world);

  static const w = 128, h = 64;
  static const quadSize = 512;

  final World world;
  int ox = 0, oz = 0;
  bool _hasOrigin = false;

  final List<Uint8List> quads = List.generate(4, (_) => Uint8List(quadSize * quadSize * 4));
  final List<bool> dirty = [true, true, true, true];
  final List<ui.Image?> images = [null, null, null, null];
  final List<bool> _uploading = [false, false, false, false];

  final Uint8List sky = Uint8List(w * w * h);
  final Uint8List blk = Uint8List(w * w * h);
  final Uint8List ids = Uint8List(w * w * h);

  static final Uint8List _opacity = _buildOpacity();
  static final Uint8List _emission = _buildEmission();

  static Uint8List _buildOpacity() {
    final o = Uint8List(256);
    for (var id = 0; id < 256; id++) {
      if (id == Ids.air ||
          id == Ids.torch ||
          id == Ids.flower ||
          id == Ids.tallGrass ||
          id == Ids.lantern ||
          id == Ids.glass) {
        o[id] = 0;
      } else if (id == Ids.leaves || id == Ids.frostLeaves || id == Ids.water) {
        o[id] = 1;
      } else if (id == Ids.bed) {
        o[id] = 0;
      } else {
        o[id] = 15;
      }
    }
    return o;
  }

  static Uint8List _buildEmission() {
    final e = Uint8List(256);
    e[Ids.torch] = 14;
    e[Ids.lantern] = 15;
    e[Ids.emberOre] = 7;
    e[Ids.kiln] = 6;
    return e;
  }

  static int idx(int x, int y, int z) => (y * w + z) * w + x;

  bool get ready => images.every((i) => i != null);

  /// Ensures the window covers the player, rebuilding when they wander near
  /// the edge. Returns true when a full rebuild happened.
  bool follow(double px, double pz) {
    final fx = px.floor(), fz = pz.floor();
    if (!_hasOrigin || fx < ox + 32 || fx >= ox + 96 || fz < oz + 32 || fz >= oz + 96) {
      ox = ((fx - 64) / 16).floor() * 16;
      oz = ((fz - 64) / 16).floor() * 16;
      _hasOrigin = true;
      rebuild();
      return true;
    }
    return false;
  }

  void rebuild() {
    // ids
    for (var cz = 0; cz < w ~/ 16; cz++) {
      for (var cx = 0; cx < w ~/ 16; cx++) {
        final chunk = world.ensureChunk(floorDiv(ox, 16) + cx, floorDiv(oz, 16) + cz);
        for (var y = 0; y < h; y++) {
          for (var lz = 0; lz < 16; lz++) {
            final base = idx(cx * 16, y, cz * 16 + lz);
            final cbase = (y * 16 + lz) * 16;
            for (var lx = 0; lx < 16; lx++) {
              ids[base + lx] = chunk.blocks[cbase + lx];
            }
          }
        }
      }
    }
    _relight(0, w - 1, 0, w - 1);
    _writeAll();
    for (var i = 0; i < 4; i++) {
      dirty[i] = true;
    }
  }

  /// Applies a single block change (world already updated).
  void blockChanged(int x, int y, int z) {
    final lx = x - ox, lz = z - oz;
    if (lx < 0 || lz < 0 || lx >= w || lz >= w || y < 0 || y >= h) return;
    ids[idx(lx, y, lz)] = world.peek(x, y, z);
    const r = 15;
    final x0 = (lx - r).clamp(0, w - 1), x1 = (lx + r).clamp(0, w - 1);
    final z0 = (lz - r).clamp(0, w - 1), z1 = (lz + r).clamp(0, w - 1);
    _relight(x0, x1, z0, z1);
    for (var zz = z0; zz <= z1; zz++) {
      for (var yy = 0; yy < h; yy++) {
        for (var xx = x0; xx <= x1; xx++) {
          _write(xx, yy, zz);
        }
      }
    }
    dirty[_quad(x0, z0)] = true;
    dirty[_quad(x1, z0)] = true;
    dirty[_quad(x0, z1)] = true;
    dirty[_quad(x1, z1)] = true;
  }

  /// Refreshes ids for a whole chunk (after its edits arrive).
  void chunkChanged(int cx, int cz) {
    final bx = cx * 16 - ox, bz = cz * 16 - oz;
    if (bx + 16 <= 0 || bz + 16 <= 0 || bx >= w || bz >= w) return;
    final chunk = world.ensureChunk(cx, cz);
    var changed = false;
    for (var y = 0; y < h; y++) {
      for (var lz = 0; lz < 16; lz++) {
        for (var lx = 0; lx < 16; lx++) {
          final id = chunk.blocks[(y * 16 + lz) * 16 + lx];
          final i = idx(bx + lx, y, bz + lz);
          if (ids[i] != id) {
            ids[i] = id;
            changed = true;
          }
        }
      }
    }
    if (!changed) return;
    final x0 = (bx - 15).clamp(0, w - 1), x1 = (bx + 31).clamp(0, w - 1);
    final z0 = (bz - 15).clamp(0, w - 1), z1 = (bz + 31).clamp(0, w - 1);
    _relight(x0, x1, z0, z1);
    for (var zz = z0; zz <= z1; zz++) {
      for (var yy = 0; yy < h; yy++) {
        for (var xx = x0; xx <= x1; xx++) {
          _write(xx, yy, zz);
        }
      }
    }
    for (var i = 0; i < 4; i++) {
      dirty[i] = true;
    }
  }

  int _quad(int x, int z) => (x >= 64 ? 2 : 0) + (z >= 64 ? 1 : 0);

  // ---------------------------------------------------------------- lighting

  final Int32List _queue = Int32List(w * w * h);

  void _relight(int x0, int x1, int z0, int z1) {
    // Reset and seed sunlight columns.
    var qn = 0;
    for (var z = z0; z <= z1; z++) {
      for (var x = x0; x <= x1; x++) {
        var light = 15;
        for (var y = h - 1; y >= 0; y--) {
          final i = idx(x, y, z);
          final op = _opacity[ids[i]];
          if (op >= 15) {
            light = 0;
          } else if (op > 0 && light > 0) {
            light -= op + 1;
            if (light < 0) light = 0;
          }
          sky[i] = light;
          blk[i] = _emission[ids[i]];
        }
      }
    }
    // Seeds: lit cells inside the box next to darker passable cells, plus the
    // ring just outside the box (existing light flowing in).
    final bx0 = (x0 - 1).clamp(0, w - 1), bx1 = (x1 + 1).clamp(0, w - 1);
    final bz0 = (z0 - 1).clamp(0, w - 1), bz1 = (z1 + 1).clamp(0, w - 1);
    for (var z = bz0; z <= bz1; z++) {
      for (var x = bx0; x <= bx1; x++) {
        final inside = x >= x0 && x <= x1 && z >= z0 && z <= z1;
        for (var y = 0; y < h; y++) {
          final i = idx(x, y, z);
          final l = sky[i];
          if (l <= 1) continue;
          if (!inside) {
            _queue[qn++] = i;
            continue;
          }
          // Only seed if a horizontal neighbour could receive light.
          if ((x > 0 && sky[i - 1] < l - 1 && _opacity[ids[i - 1]] < 15) ||
              (x < w - 1 && sky[i + 1] < l - 1 && _opacity[ids[i + 1]] < 15) ||
              (z > 0 && sky[i - w] < l - 1 && _opacity[ids[i - w]] < 15) ||
              (z < w - 1 && sky[i + w] < l - 1 && _opacity[ids[i + w]] < 15) ||
              (y > 0 && sky[i - w * w] < l - 1 && _opacity[ids[i - w * w]] < 15)) {
            _queue[qn++] = i;
          }
        }
      }
    }
    _propagate(sky, qn, x0, x1, z0, z1);

    // Block light: seeds are emitters in the box and the outside ring.
    qn = 0;
    for (var z = bz0; z <= bz1; z++) {
      for (var x = bx0; x <= bx1; x++) {
        for (var y = 0; y < h; y++) {
          final i = idx(x, y, z);
          if (blk[i] > 1) _queue[qn++] = i;
        }
      }
    }
    _propagate(blk, qn, x0, x1, z0, z1);
  }

  int _qn = 0;

  void _propagate(Uint8List light, int qn, int x0, int x1, int z0, int z1) {
    var head = 0;
    _qn = qn;
    final q = _queue;
    while (head < _qn) {
      final i = q[head++];
      final l = light[i];
      if (l <= 1) continue;
      final x = i % w;
      final z = (i ~/ w) % w;
      final y = i ~/ (w * w);
      if (x < x0 || x > x1 || z < z0 || z > z1) {
        // Ring cell outside the box: only push light inward.
        if (x < x0 && z >= z0 && z <= z1) _spread(light, i + 1, l);
        if (x > x1 && z >= z0 && z <= z1) _spread(light, i - 1, l);
        if (z < z0 && x >= x0 && x <= x1) _spread(light, i + w, l);
        if (z > z1 && x >= x0 && x <= x1) _spread(light, i - w, l);
        continue;
      }
      if (x > x0) _spread(light, i - 1, l);
      if (x < x1) _spread(light, i + 1, l);
      if (z > z0) _spread(light, i - w, l);
      if (z < z1) _spread(light, i + w, l);
      if (y > 0) _spread(light, i - w * w, l);
      if (y < h - 1) _spread(light, i + w * w, l);
    }
  }

  void _spread(Uint8List light, int j, int l) {
    final op = _opacity[ids[j]];
    if (op >= 15) return;
    final nl = l - 1 - op;
    if (nl > light[j]) {
      light[j] = nl;
      if (_qn < _queue.length) _queue[_qn++] = j;
    }
  }

  // ---------------------------------------------------------------- texture

  void _writeAll() {
    for (var z = 0; z < w; z++) {
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          _write(x, y, z);
        }
      }
    }
  }

  void _write(int x, int y, int z) {
    final q = _quad(x, z);
    final lx = x & 63, lz = z & 63;
    final px = (y & 7) * 64 + lx;
    final py = (y >> 3) * 64 + lz;
    final o = (py * quadSize + px) * 4;
    final i = idx(x, y, z);
    final buf = quads[q];
    final id = ids[i];
    buf[o] = id;
    // Solid cells carry no light so that the shader's smooth lighting reads
    // them as occluders.
    final passable = _opacity[id] < 15;
    buf[o + 1] = passable ? sky[i] * 17 : 0;
    buf[o + 2] = passable ? blk[i] * 17 : 0;
    buf[o + 3] = 255;
  }

  /// Uploads dirty quadrants. Returns a future that resolves when everything
  /// currently dirty has been uploaded.
  Future<void> upload() async {
    final futures = <Future<void>>[];
    for (var q = 0; q < 4; q++) {
      if (!dirty[q] || _uploading[q]) continue;
      dirty[q] = false;
      _uploading[q] = true;
      final c = Completer<void>();
      final copy = Uint8List.fromList(quads[q]);
      ui.decodeImageFromPixels(copy, quadSize, quadSize, ui.PixelFormat.rgba8888, (img) {
        images[q]?.dispose();
        images[q] = img;
        _uploading[q] = false;
        c.complete();
      });
      futures.add(c.future);
    }
    await Future.wait(futures);
  }

  /// Light (0..15) at a world position for HUD purposes.
  int skyLightAt(int x, int y, int z) {
    final lx = x - ox, lz = z - oz;
    if (lx < 0 || lz < 0 || lx >= w || lz >= w || y < 0 || y >= h) return 15;
    return sky[idx(lx, y, lz)];
  }

  void dispose() {
    for (final i in images) {
      i?.dispose();
    }
  }
}
