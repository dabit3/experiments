import 'package:flutter/material.dart';

import '../app_state.dart';
import '../audio.dart';
import '../game/game_controller.dart';
import 'pixel.dart';

/// Full-screen options menu: two columns of 150x20 controls under a title,
/// "Done" at the bottom. [background] is drawn behind it (dirt on the title
/// screen, a dim gradient in game).
Future<void> showOptionsScreen(
  BuildContext context,
  Settings settings, {
  GameController? game,
  required Widget background,
}) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => OptionsScreen(settings: settings, game: game, background: background),
  ),
);

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key, required this.settings, this.game, required this.background});
  final Settings settings;
  final GameController? game;
  final Widget background;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final gui = Gui.guiSize(context);
    final twoCol = gui.width >= 320;
    final colW = twoCol ? 150.0 : 200.0;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final g = game;
        if (g != null) {
          g.lookSensitivity = 0.0022 * settings.sensitivity;
          g.invertY = settings.invertY;
          g.camera.fovDeg = settings.fov;
        }
        final controls = <Widget>[
          PxSlider(
            label: 'Sensitivity: ${(settings.sensitivity * 100).round()}%',
            value: ((settings.sensitivity - 0.3) / 2.2).clamp(0.0, 1.0),
            width: colW,
            onChanged: (v) => settings.sensitivity = 0.3 + v * 2.2,
          ),
          PxSlider(
            label: 'FOV: ${settings.fov.round()}',
            value: ((settings.fov - 50) / 60).clamp(0.0, 1.0),
            width: colW,
            onChanged: (v) => settings.fov = 50 + v * 60,
          ),
          PxButton(
            'Invert Mouse: ${settings.invertY ? 'ON' : 'OFF'}',
            width: colW,
            onPressed: () => settings.invertY = !settings.invertY,
          ),
          PxButton(
            'Touch Controls: ${settings.touchControls ? 'ON' : 'OFF'}',
            width: colW,
            onPressed: () => settings.touchControls = !settings.touchControls,
          ),
          PxButton(
            'Vibration: ${settings.haptics ? 'ON' : 'OFF'}',
            width: colW,
            onPressed: () => settings.haptics = !settings.haptics,
          ),
          PxButton(
            'Sound: ${settings.sound ? 'ON' : 'OFF'}',
            width: colW,
            onPressed: () {
              settings.sound = !settings.sound;
              if (settings.sound) Sfx.play('ui_confirm');
            },
          ),
          PxButton(
            'Graphics: ${switch (settings.renderQuality) {
              0 => 'Fast',
              2 => 'Fancy',
              _ => 'Auto',
            }}',
            width: colW,
            onPressed: () => settings.renderQuality = (settings.renderQuality + 1) % 3,
          ),
          PxButton(
            'Menu Tint: ${switch (settings.themeMode) {
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
              ThemeMode.system => 'Auto',
            }}',
            width: colW,
            onPressed: () => settings.themeMode = switch (settings.themeMode) {
              ThemeMode.system => ThemeMode.light,
              ThemeMode.light => ThemeMode.dark,
              ThemeMode.dark => ThemeMode.system,
            },
          ),
          PxButton(
            'Show FPS: ${settings.showFps ? 'ON' : 'OFF'}',
            width: colW,
            onPressed: () => settings.showFps = !settings.showFps,
          ),
        ];
        final rows = <Widget>[];
        if (twoCol) {
          for (var i = 0; i < controls.length; i += 2) {
            rows.add(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  controls[i],
                  SizedBox(width: 4.0 * s),
                  if (i + 1 < controls.length) controls[i + 1] else SizedBox(width: colW * s),
                ],
              ),
            );
          }
        } else {
          rows.addAll(controls);
        }
        return PxScreen(
          background: background,
          title: 'Options',
          footer: Padding(
            padding: EdgeInsets.only(bottom: 8.0 * s),
            child: PxButton('Done', sound: 'ui_back', onPressed: () => Navigator.of(context).pop()),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.0 * s),
                    child: r,
                  ),
                SizedBox(height: 4.0 * s),
                SizedBox(
                  width: (twoCol ? 304.0 : 200.0) * s,
                  child: const PxText(
                    'Auto graphics lowers render resolution when the frame rate drops.',
                    color: Px.gray,
                    align: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
