import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/game/art_assets.dart';
import 'package:nitro_tots/game/kart_art.dart';
import 'package:nitro_tots/game/track_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ArtAssets.load);

  test('all worlds and kart effects produce rasterizable race art', () async {
    for (final id in ['sprinkle', 'mossy', 'tincity', 'frostbite', 'bowl']) {
      final art = TrackArt(trackById(id));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.save();
      canvas.scale(256 / art.bounds.width);
      canvas.translate(-art.bounds.left, -art.bounds.top);
      canvas.drawPicture(art.picture);
      canvas.restore();
      for (final (i, kart) in karts.indexed) {
        canvas.save();
        canvas.translate(24 + i * 40, 220);
        KartArt.drawKart(canvas, body: const ui.Color(0xFFFF6B35), kart: kart, drifting: true, driftTier: i % 3 + 1, boosting: true, shield: true, time: 0.25);
        canvas.restore();
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(256, 256);
      final pixels = await image.toByteData();
      expect(pixels, isNotNull, reason: id);
      expect(pixels!.buffer.asUint8List().any((channel) => channel > 0), isTrue, reason: id);
      image.dispose();
      picture.dispose();
      art.dispose();
    }
  });
}
