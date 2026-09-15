import 'dart:math' as math;

import 'blocks.dart';
import 'world.dart';

/// Axis-aligned body used for players and creatures.
class Body {
  Body({required this.width, required this.height});

  final double width;
  final double height;

  double x = 0, y = 0, z = 0;
  double vx = 0, vy = 0, vz = 0;
  bool onGround = false;
  bool inWater = false;
  bool flying = false;

  double get halfW => width / 2;

  void setPos(double nx, double ny, double nz) {
    x = nx;
    y = ny;
    z = nz;
  }
}

/// Deterministic movement constants (blocks / second).
class Move {
  static const walkSpeed = 4.3;
  static const sprintSpeed = 5.6;
  static const sneakSpeed = 1.3;
  static const swimSpeed = 2.2;
  static const flySpeed = 10.5;
  static const jumpVelocity = 8.4;
  static const gravity = 28.0;
  static const waterGravity = 6.0;
  static const terminal = 60.0;
  static const reach = 5.5;
  static const playerWidth = 0.6;
  static const playerHeight = 1.8;
  static const eyeHeight = 1.62;
  static const sneakEye = 1.27;
}

class Physics {
  Physics(this.world);

  final World world;

  bool _collides(Body b, double x, double y, double z) {
    final x0 = (x - b.halfW).floor(), x1 = (x + b.halfW - 1e-6).floor();
    final z0 = (z - b.halfW).floor(), z1 = (z + b.halfW - 1e-6).floor();
    final y0 = y.floor(), y1 = (y + b.height - 1e-6).floor();
    for (var bx = x0; bx <= x1; bx++) {
      for (var by = y0; by <= y1; by++) {
        for (var bz = z0; bz <= z1; bz++) {
          if (world.isSolid(bx, by, bz)) return true;
        }
      }
    }
    return false;
  }

  bool bodyInFluid(Body b) {
    final x0 = (b.x - b.halfW).floor(), x1 = (b.x + b.halfW - 1e-6).floor();
    final z0 = (b.z - b.halfW).floor(), z1 = (b.z + b.halfW - 1e-6).floor();
    final y0 = b.y.floor(), y1 = (b.y + b.height * 0.6).floor();
    for (var bx = x0; bx <= x1; bx++) {
      for (var by = y0; by <= y1; by++) {
        for (var bz = z0; bz <= z1; bz++) {
          if (Registry.block(world.peek(bx, by, bz)).fluid) return true;
        }
      }
    }
    return false;
  }

  bool headInFluid(Body b) {
    final hy = (b.y + b.height - 0.2).floor();
    return Registry.block(world.peek(b.x.floor(), hy, b.z.floor())).fluid;
  }

  /// Integrates one step. [wishX]/[wishZ] is the desired horizontal velocity,
  /// [jump] requests a jump/swim-up, [wishY] is only used when flying.
  void step(Body b, double dt, double wishX, double wishZ, {bool jump = false, double wishY = 0}) {
    b.inWater = bodyInFluid(b);
    if (b.flying) {
      b.vx = wishX;
      b.vz = wishZ;
      b.vy = wishY;
    } else if (b.inWater) {
      b.vx = b.vx * 0.8 + wishX * 0.2;
      b.vz = b.vz * 0.8 + wishZ * 0.2;
      b.vy -= Move.waterGravity * dt;
      if (jump) b.vy = math.max(b.vy, 3.2);
      b.vy = b.vy.clamp(-3.0, 4.0);
    } else {
      final accel = b.onGround ? 0.35 : 0.12;
      b.vx = b.vx + (wishX - b.vx) * accel;
      b.vz = b.vz + (wishZ - b.vz) * accel;
      if (jump && b.onGround) {
        b.vy = Move.jumpVelocity;
        b.onGround = false;
      }
      b.vy -= Move.gravity * dt;
      if (b.vy < -Move.terminal) b.vy = -Move.terminal;
    }
    _moveAxis(b, b.vx * dt, 0, 0);
    _moveAxis(b, 0, 0, b.vz * dt);
    final wasFalling = b.vy < 0;
    final moved = _moveAxis(b, 0, b.vy * dt, 0);
    if (!moved) {
      if (wasFalling) b.onGround = true;
      b.vy = 0;
    } else {
      b.onGround = false;
    }
    // Snap check: standing on ground exactly.
    if (!b.onGround && b.vy <= 0 && _collides(b, b.x, b.y - 0.02, b.z)) {
      b.onGround = true;
    }
  }

  /// Moves along one axis, stopping at collisions. Returns false if blocked.
  bool _moveAxis(Body b, double dx, double dy, double dz) {
    const steps = 4;
    final sx = dx / steps, sy = dy / steps, sz = dz / steps;
    for (var i = 0; i < steps; i++) {
      final nx = b.x + sx, ny = b.y + sy, nz = b.z + sz;
      if (_collides(b, nx, ny, nz)) {
        if (dx != 0) b.vx = 0;
        if (dz != 0) b.vz = 0;
        return false;
      }
      b.x = nx;
      b.y = ny;
      b.z = nz;
    }
    return true;
  }

  /// Auto step-up: if blocked horizontally and a 1-block step is free, hop.
  bool tryStepUp(Body b, double dirX, double dirZ) {
    if (!b.onGround) return false;
    final tx = b.x + dirX * 0.3, tz = b.z + dirZ * 0.3;
    if (_collides(b, tx, b.y, tz) && !_collides(b, tx, b.y + 1.05, tz)) {
      return true;
    }
    return false;
  }

  bool blocked(Body b, double x, double y, double z) => _collides(b, x, y, z);

  /// Whether a block at [bx,by,bz] would overlap the body.
  bool blockOverlaps(Body b, int bx, int by, int bz) {
    final x0 = b.x - b.halfW, x1 = b.x + b.halfW;
    final z0 = b.z - b.halfW, z1 = b.z + b.halfW;
    final y0 = b.y, y1 = b.y + b.height;
    return bx + 1 > x0 && bx < x1 && by + 1 > y0 && by < y1 && bz + 1 > z0 && bz < z1;
  }
}

/// Result of a ray cast against the block grid.
class RayHit {
  const RayHit(this.x, this.y, this.z, this.nx, this.ny, this.nz, this.dist, this.id);

  final int x, y, z;
  final int nx, ny, nz;
  final double dist;
  final int id;
}

/// DDA voxel traversal; identical to the shader's walk so the block a player
/// targets is the one they see under the crosshair.
RayHit? raycast(
  World w,
  double ox,
  double oy,
  double oz,
  double dx,
  double dy,
  double dz,
  double maxDist, {
  bool hitFluid = false,
}) {
  var x = ox.floor(), y = oy.floor(), z = oz.floor();
  final stepX = dx > 0 ? 1 : -1, stepY = dy > 0 ? 1 : -1, stepZ = dz > 0 ? 1 : -1;
  final tdx = dx == 0 ? 1e30 : (1 / dx).abs();
  final tdy = dy == 0 ? 1e30 : (1 / dy).abs();
  final tdz = dz == 0 ? 1e30 : (1 / dz).abs();
  var tmx = dx == 0 ? 1e30 : ((dx > 0 ? x + 1 - ox : ox - x) * tdx);
  var tmy = dy == 0 ? 1e30 : ((dy > 0 ? y + 1 - oy : oy - y) * tdy);
  var tmz = dz == 0 ? 1e30 : ((dz > 0 ? z + 1 - oz : oz - z) * tdz);
  var nx = 0, ny = 0, nz = 0;
  var t = 0.0;
  for (var i = 0; i < 400; i++) {
    final id = w.peek(x, y, z);
    final def = Registry.block(id);
    if (id != Ids.air && (def.solid || def.decoration || (hitFluid && def.fluid))) {
      return RayHit(x, y, z, nx, ny, nz, t, id);
    }
    if (tmx < tmy && tmx < tmz) {
      x += stepX;
      t = tmx;
      tmx += tdx;
      nx = -stepX;
      ny = 0;
      nz = 0;
    } else if (tmy < tmz) {
      y += stepY;
      t = tmy;
      tmy += tdy;
      nx = 0;
      ny = -stepY;
      nz = 0;
    } else {
      z += stepZ;
      t = tmz;
      tmz += tdz;
      nx = 0;
      ny = 0;
      nz = -stepZ;
    }
    if (t > maxDist) return null;
    if (y < 0 || y >= 64) return null;
  }
  return null;
}
