import 'package:flutter/material.dart';

import '../app_state.dart';
import '../game/game_controller.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> showSettingsSheet(BuildContext context, Settings settings, GameController? game) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => SettingsPanel(settings: settings, game: game),
    );

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, required this.settings, this.game, this.embedded = false});
  final Settings settings;
  final GameController? game;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final g = game;
        if (g != null) {
          g.lookSensitivity = 0.0022 * settings.sensitivity;
          g.invertY = settings.invertY;
          g.camera.fovDeg = settings.fov;
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(VhSpace.xl, embedded ? 0 : VhSpace.sm, VhSpace.xl, VhSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!embedded) Text('Settings', style: t.textTheme.headlineSmall),
              const SizedBox(height: VhSpace.lg),
              const SectionLabel('Appearance'),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Auto'),
                    icon: Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.themeMode = s.first,
                showSelectedIcon: false,
              ),
              const SizedBox(height: VhSpace.xl),
              const SectionLabel('Controls'),
              _SliderRow(
                label: 'Look sensitivity',
                value: settings.sensitivity,
                min: 0.3,
                max: 2.5,
                display: '${(settings.sensitivity * 100).round()}%',
                onChanged: (v) => settings.sensitivity = v,
              ),
              _SliderRow(
                label: 'Field of view',
                value: settings.fov,
                min: 50,
                max: 110,
                display: '${settings.fov.round()}°',
                onChanged: (v) => settings.fov = v,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Invert vertical look'),
                value: settings.invertY,
                onChanged: (v) => settings.invertY = v,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Touch controls'),
                subtitle: const Text('On-screen joystick and action buttons'),
                value: settings.touchControls,
                onChanged: (v) => settings.touchControls = v,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptic feedback'),
                value: settings.haptics,
                onChanged: (v) => settings.haptics = v,
              ),
              const SizedBox(height: VhSpace.lg),
              const SectionLabel('Graphics'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Battery')),
                  ButtonSegment(value: 1, label: Text('Auto')),
                  ButtonSegment(value: 2, label: Text('Crisp')),
                ],
                selected: {settings.renderQuality},
                onSelectionChanged: (s) => settings.renderQuality = s.first,
                showSelectedIcon: false,
              ),
              const SizedBox(height: VhSpace.xs),
              Text(
                'Auto lowers the render resolution when the frame rate drops, keeping the game at 60 fps.',
                style: t.textTheme.bodySmall,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show frame rate'),
                value: settings.showFps,
                onChanged: (v) => settings.showFps = v,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });
  final String label;
  final double value, min, max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: t.textTheme.bodyLarge)),
            Text(display, style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary)),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
