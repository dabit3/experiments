import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'atlas.dart';
import 'voxel_view.dart';

/// GPU-side assets shared by every frame.
class RenderAssets {
  RenderAssets._(this.program, this.atlas, this.atlasImage, this.tileMap);

  final ui.FragmentProgram program;
  final AtlasData atlas;
  final ui.Image atlasImage;
  final ui.Image tileMap;

  static Future<RenderAssets> load() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/voxel.frag');
    final atlas = buildAtlas();
    final img = await atlas.toImage();
    final tiles = await atlas.tileMapImage();
    return RenderAssets._(program, atlas, img, tiles);
  }
}

class EntityDraw {
  EntityDraw(this.x, this.y, this.z, this.yaw, this.kind, this.seed, this.hurt);
  final double x, y, z, yaw;
  final int kind, seed;
  final bool hurt;
}

class Camera {
  double x = 0, y = 40, z = 0;
  double yaw = 0, pitch = 0;
  double fovDeg = 70;

  List<double> get forward => [math.cos(pitch) * math.sin(yaw), math.sin(pitch), math.cos(pitch) * math.cos(yaw)];
  List<double> get right => [math.cos(yaw), 0, -math.sin(yaw)];
  double distanceTo(double px, double py, double pz) {
    final dx = px - x, dy = py - y, dz = pz - z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  List<double> get up {
    final f = forward, r = right;
    return [f[1] * r[2] - f[2] * r[1], f[2] * r[0] - f[0] * r[2], f[0] * r[1] - f[1] * r[0]];
  }
}

class SceneFrame {
  SceneFrame({
    required this.camera,
    required this.view,
    required this.dayFraction,
    required this.anim,
    required this.entities,
    this.target,
    this.breakProgress = 0,
    this.underwater = false,
    this.damage = 0,
    this.maxDist = 96,
    this.pixelScale = 1,
  });
  final Camera camera;
  final VoxelView view;
  final double dayFraction;
  final double anim;
  final List<EntityDraw> entities;
  final List<int>? target;
  final double breakProgress;
  final bool underwater;
  final double damage;
  final double maxDist;
  final double pixelScale;
}

/// Draws the voxel scene with the shared fragment shader.
class VoxelPainter extends CustomPainter {
  VoxelPainter(this.assets, this.frame, this.entityImage);

  final RenderAssets assets;
  final SceneFrame frame;
  final ui.Image? entityImage;

  static ui.FragmentShader? _shader;

  @override
  void paint(Canvas canvas, Size size) {
    final view = frame.view;
    if (!view.ready) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff0b1020));
      return;
    }
    final shader = _shader ??= assets.program.fragmentShader();
    final k = frame.pixelScale;
    final w = (size.width / k).ceilToDouble(), h = (size.height / k).ceilToDouble();
    _setUniforms(shader, w, h);
    final paint = Paint()..shader = shader;
    if (k <= 1.001) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    final pic = rec.endRecording();
    final img = pic.toImageSync(w.toInt(), h.toInt());
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, w, h),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
    img.dispose();
    pic.dispose();
  }

  void _setUniforms(ui.FragmentShader s, double w, double h) {
    final cam = frame.camera;
    final f = cam.forward, r = cam.right, u = cam.up;
    final aspect = w / h;
    final tanY = math.tan(cam.fovDeg * math.pi / 360);
    final tanX = tanY * aspect;
    var i = 0;
    void set(double v) => s.setFloat(i++, v);
    set(w);
    set(h);
    set(cam.x);
    set(cam.y);
    set(cam.z);
    set(f[0]);
    set(f[1]);
    set(f[2]);
    set(r[0]);
    set(r[1]);
    set(r[2]);
    set(u[0]);
    set(u[1]);
    set(u[2]);
    set(tanX);
    set(tanY);
    set(frame.view.ox.toDouble());
    set(0);
    set(frame.view.oz.toDouble());
    set(frame.dayFraction);
    set(frame.anim);
    final t = frame.target;
    if (t == null) {
      set(-1000);
      set(-1000);
      set(-1000);
    } else {
      set((t[0] - frame.view.ox).toDouble());
      set(t[1].toDouble());
      set((t[2] - frame.view.oz).toDouble());
    }
    set(frame.breakProgress);
    set(frame.maxDist);
    set(frame.underwater ? 1 : 0);
    set(math.min(frame.entities.length, 24).toDouble());
    set(Tiles.width.toDouble());
    set(Tiles.height.toDouble());
    set(frame.damage);
    for (var q = 0; q < 4; q++) {
      s.setImageSampler(q, frame.view.images[q]!);
    }
    s.setImageSampler(4, assets.tileMap);
    s.setImageSampler(5, assets.atlasImage);
    s.setImageSampler(6, entityImage ?? assets.tileMap);
  }

  @override
  bool shouldRepaint(covariant VoxelPainter old) => true;
}

/// Packs entity positions into a 128x1 RGBA image, 3 texels per entity.
Uint8List packEntities(List<EntityDraw> ents, int ox, int oz) {
  final buf = Uint8List(128 * 4);
  for (var i = 3; i < buf.length; i += 4) {
    buf[i] = 255;
  }
  final n = math.min(ents.length, 24);
  for (var i = 0; i < n; i++) {
    final e = ents[i];
    final ex = (((e.x - ox) + 16) * 256).round().clamp(0, 65535);
    final ez = (((e.z - oz) + 16) * 256).round().clamp(0, 65535);
    final ey = ((e.y + 16) * 256).round().clamp(0, 65535);
    final o = i * 12;
    buf[o] = ex >> 8;
    buf[o + 1] = ex & 255;
    buf[o + 2] = ez >> 8;
    buf[o + 4] = ez & 255;
    buf[o + 5] = ey >> 8;
    buf[o + 6] = ey & 255;
    buf[o + 8] = (e.seed % 10) * 10 + e.kind;
    var yaw = (e.yaw + math.pi) % (2 * math.pi);
    if (yaw < 0) yaw += 2 * math.pi;
    buf[o + 9] = (yaw / (2 * math.pi) * 255).round().clamp(0, 255);
    buf[o + 10] = e.hurt ? 255 : 0;
  }
  return buf;
}
