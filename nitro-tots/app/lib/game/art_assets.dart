import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class ArtAssets {
  static final Map<String, ui.Image> images = {};
  static Future<void>? _loading;

  static Future<void> load() => _loading ??= _loadAll();

  static Future<void> _loadAll() async {
    await Future.wait([
      for (final name in [
        'prop-candy.png',
        'prop-forest.png',
        'prop-tower.png',
        'prop-ice.png',
        'prop-grandstand.png',
        'prop-pit.png',
        'kart-jellybean.png',
        'kart-tincan.png',
        'kart-bubble.png',
        'kart-pinewood.png',
        'kart-rocketscoot.png',
        'kart-bigwheel.png',
        'ground-sand.jpg',
        'ground-moss.jpg',
        'ground-asphalt.jpg',
        'ground-ice.jpg',
      ])
        _load(name),
    ]);
  }

  static Future<void> _load(String name) async {
    final data = await rootBundle.load('assets/art/$name');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    images[name] = (await codec.getNextFrame()).image;
    codec.dispose();
  }

  static bool draw(ui.Canvas canvas, String name, ui.Rect target, {double opacity = 1}) {
    final image = images[name];
    if (image == null) return false;
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      target,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..color = ui.Color.fromRGBO(255, 255, 255, opacity),
    );
    return true;
  }
}
