import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/audio.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.app, required this.feedback, required this.onBack});
  final AppState app;
  final NtFeedback feedback;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => NtScreen(
        title: 'Settings',
        onBack: onBack,
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Group(
              title: 'Controls',
              children: [
                _Segmented<ControlScheme>(
                  label: 'Scheme',
                  value: app.controls,
                  items: const {ControlScheme.auto: 'Auto', ControlScheme.touch: 'Touch', ControlScheme.keyboard: 'Keys'},
                  onChanged: (v) => _set((s) => s.controls = v),
                ),
                _Toggle(
                  label: 'Auto-accelerate',
                  hint: 'Kart drives forward on its own; you steer and drift.',
                  value: app.autoAccelerate,
                  onChanged: (v) => _set((s) => s.autoAccelerate = v),
                ),
                _Segmented<CameraMode>(
                  label: 'Camera',
                  value: app.camera,
                  items: const {CameraMode.chase: 'Chase', CameraMode.north: 'Fixed'},
                  onChanged: (v) => _set((s) => s.camera = v),
                ),
                if (app.isMobile)
                  _Toggle(label: 'Haptics', hint: 'Vibrate on boosts, hits and pickups.', value: app.haptics, onChanged: (v) => _set((s) => s.haptics = v)),
              ],
            ),
            _Group(
              title: 'Audio',
              children: [
                _SliderRow(
                  label: 'Music',
                  value: app.musicVolume,
                  icon: Icons.music_note_rounded,
                  onChanged: (v) => app.update((s) => s.musicVolume = v),
                  onEnd: (_) => feedback.applyVolumes(),
                ),
                _SliderRow(
                  label: 'Sound effects',
                  value: app.sfxVolume,
                  icon: Icons.volume_up_rounded,
                  onChanged: (v) => app.update((s) => s.sfxVolume = v),
                  onEnd: (_) {
                    feedback.applyVolumes();
                    feedback.sfx('pickup');
                  },
                ),
              ],
            ),
            _Group(
              title: 'Display',
              children: [
                _Segmented<ThemeMode>(
                  label: 'Theme',
                  value: app.themeMode,
                  items: const {ThemeMode.system: 'System', ThemeMode.light: 'Light', ThemeMode.dark: 'Dark'},
                  onChanged: (v) => _set((s) => s.themeMode = v),
                ),
                _Toggle(
                  label: 'Reduce motion',
                  hint: 'Calmer camera, fewer particles and confetti.',
                  value: app.reduceMotion,
                  onChanged: (v) => _set((s) => s.reduceMotion = v),
                ),
              ],
            ),
            _Group(
              title: 'Keyboard',
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final (k, v) in const [
                      ('↑ / W', 'Gas'),
                      ('↓ / S', 'Brake / reverse'),
                      ('← → / A D', 'Steer'),
                      ('Space / Shift', 'Hop + drift'),
                      ('Z / Enter', 'Use item'),
                      ('Q', 'Look back'),
                      ('Esc / P', 'Pause'),
                    ])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: nt.bgAlt,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: nt.outline),
                            ),
                            child: Text(k, style: NtType.caption(nt.ink)),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(v, style: NtType.small(nt.inkSoft), softWrap: false, overflow: TextOverflow.fade),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: NtSpace.x4),
            Text(
              'Nitro Tots is an original game. All names, art and audio were made for it. Build ${AppState.platformId}.',
              style: NtType.caption(nt.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _set(void Function(AppState s) fn) {
    feedback.tap();
    app.update(fn);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NtSpace.x4),
      child: NtCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title),
            const SizedBox(height: NtSpace.x2),
            for (final c in children) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: c),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.hint, required this.value, required this.onChanged});
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: NtType.label(nt.ink)),
                Text(hint, style: NtType.small(nt.inkSoft)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: NtSpace.x3,
      runSpacing: NtSpace.x2,
      children: [
        Text(label, style: NtType.label(nt.ink)),
        SegmentedButton<T>(
          segments: [for (final e in items.entries) ButtonSegment(value: e.key, label: Text(e.value))],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.icon, required this.onChanged, required this.onEnd});
  final String label;
  final double value;
  final IconData icon;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onEnd;
  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Row(
      children: [
        Icon(icon, color: nt.inkSoft),
        const SizedBox(width: NtSpace.x2),
        SizedBox(width: 110, child: Text(label, style: NtType.label(nt.ink))),
        Expanded(
          child: Slider(value: value, onChanged: onChanged, onChangeEnd: onEnd, label: '${(value * 100).round()}%'),
        ),
        SizedBox(
          width: 44,
          child: Text('${(value * 100).round()}%', style: NtType.mono(nt.inkSoft), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
