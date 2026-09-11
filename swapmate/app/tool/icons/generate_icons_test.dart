// Regenerates every platform launcher icon from the in-app Swapmate mark so
// the branding is drawn by the same code on every platform.
//
//   cd app && flutter test tool/icons/generate_icons_test.dart
//
// Lives outside test/ so `flutter test` does not run it as part of the suite.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swapmate/src/theme/tokens.dart';
import 'package:swapmate/src/widgets/piece_painter.dart';

const _root = '.';

const _android = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const _ios = {
  'Icon-App-20x20@1x': 20,
  'Icon-App-20x20@2x': 40,
  'Icon-App-20x20@3x': 60,
  'Icon-App-29x29@1x': 29,
  'Icon-App-29x29@2x': 58,
  'Icon-App-29x29@3x': 87,
  'Icon-App-40x40@1x': 40,
  'Icon-App-40x40@2x': 80,
  'Icon-App-40x40@3x': 120,
  'Icon-App-60x60@2x': 120,
  'Icon-App-60x60@3x': 180,
  'Icon-App-76x76@1x': 76,
  'Icon-App-76x76@2x': 152,
  'Icon-App-83.5x83.5@2x': 167,
  'Icon-App-1024x1024@1x': 1024,
};

const _macos = [16, 32, 64, 128, 256, 512, 1024];

const _web = {
  'Icon-192': 192,
  'Icon-512': 512,
  'Icon-maskable-192': 192,
  'Icon-maskable-512': 512,
};

/// Rounded tile with the mark, as used by launchers that do not mask icons.
class _Tile extends StatelessWidget {
  const _Tile({required this.size, required this.rounded});
  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(extensions: const [SwapColors.dark]),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SwapColors.dark.canvas,
        borderRadius: rounded ? BorderRadius.circular(size * 0.22) : null,
      ),
      alignment: Alignment.center,
      child: SwapmateMark(size: size * 0.78),
    ),
  );
}

Future<void> _write(
  WidgetTester tester,
  String path,
  int px, {
  bool rounded = false,
}) async {
  final key = GlobalKey();
  await tester.binding.setSurfaceSize(Size.square(px.toDouble()));
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: _Tile(size: px.toDouble(), rounded: rounded),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_root/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate launcher icons', (tester) async {
    for (final e in _android.entries) {
      await _write(
        tester,
        'android/app/src/main/res/${e.key}/ic_launcher.png',
        e.value,
        rounded: true,
      );
    }
    for (final e in _ios.entries) {
      await _write(
        tester,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/${e.key}.png',
        e.value,
      );
    }
    for (final px in _macos) {
      await _write(
        tester,
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$px.png',
        px,
        rounded: true,
      );
    }
    for (final e in _web.entries) {
      await _write(
        tester,
        'web/icons/${e.key}.png',
        e.value,
        rounded: !e.key.contains('maskable'),
      );
    }
    await _write(tester, 'web/favicon.png', 32, rounded: true);
    for (final (name, px) in [
      ('LaunchImage', 96),
      ('LaunchImage@2x', 192),
      ('LaunchImage@3x', 288),
    ]) {
      await _write(
        tester,
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/$name.png',
        px,
      );
    }
  });
}
