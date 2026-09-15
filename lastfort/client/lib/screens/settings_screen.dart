import 'package:flutter/material.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import '../net/connection.dart' as net;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController serverCtl;
  late final TextEditingController nameCtl;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.read(context);
    serverCtl = TextEditingController(
      text: scope.profile.serverUrl ?? scope.config.serverUrl,
    );
    nameCtl = TextEditingController(text: scope.profile.name);
  }

  @override
  void dispose() {
    serverCtl.dispose();
    nameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final profile = scope.profile;
    final session = scope.session;
    final layout = LfLayout.of(context);
    final c = context.lf;
    final pad = layout.isPhone ? LfTokens.s4 : LfTokens.s6;

    return ListenableBuilder(
      listenable: Listenable.merge([profile, session.connection]),
      builder: (context, _) {
        final conn = session.connection;
        return LfPage(
          maxWidth: 820,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              pad,
              layout.isPhone ? LfTokens.s5 : LfTokens.s6,
              pad,
              LfTokens.s6,
            ),
            children: [
              Text('Settings', style: context.text.displaySmall),
              const SizedBox(height: LfTokens.s5),
              LfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LfEyebrow('PROFILE'),
                    const SizedBox(height: LfTokens.s3),
                    TextField(
                      controller: nameCtl,
                      maxLength: 16,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        counterText: '',
                      ),
                      onSubmitted: (v) => profile.setName(
                        v.trim().isEmpty ? profile.name : v.trim(),
                      ),
                      onEditingComplete: () => profile.setName(
                        nameCtl.text.trim().isEmpty
                            ? profile.name
                            : nameCtl.text.trim(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LfTokens.s4),
              LfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LfEyebrow('APPEARANCE'),
                    const SizedBox(height: LfTokens.s3),
                    Wrap(
                      spacing: LfTokens.s2,
                      children: [
                        for (final (v, label, icon) in const [
                          ('system', 'System', Icons.brightness_auto_rounded),
                          ('dark', 'Dark', Icons.dark_mode_rounded),
                          ('light', 'Light', Icons.light_mode_rounded),
                        ])
                          LfChip(
                            label: label,
                            icon: icon,
                            selected: profile.themeMode == v,
                            color: LfTokens.ember,
                            onTap: () => profile.setThemeMode(v),
                          ),
                      ],
                    ),
                    const SizedBox(height: LfTokens.s3),
                    _Toggle(
                      label: 'Reduce motion',
                      detail: 'Disables camera shake, storm pulses and idle animation.',
                      value: profile.reducedMotion,
                      onChanged: (v) => profile.setToggles(reducedMotion: v),
                    ),
                    _Toggle(
                      label: 'Haptics',
                      detail: 'Vibration feedback on touch devices.',
                      value: profile.haptics,
                      onChanged: (v) => profile.setToggles(haptics: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LfTokens.s4),
              LfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LfEyebrow('SERVER'),
                        const Spacer(),
                        _ConnDot(conn: conn),
                      ],
                    ),
                    const SizedBox(height: LfTokens.s3),
                    TextField(
                      controller: serverCtl,
                      decoration: InputDecoration(
                        labelText: 'WebSocket URL',
                        hintText: scope.config.serverUrl,
                        suffixIcon: IconButton(
                          tooltip: 'Reset to default',
                          icon: const Icon(Icons.restart_alt_rounded),
                          onPressed: () {
                            serverCtl.text = scope.config.serverUrl;
                            profile.setServerUrl(null);
                          },
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      onSubmitted: (v) => profile.setServerUrl(
                        v.trim().isEmpty ? null : v.trim(),
                      ),
                    ),
                    const SizedBox(height: LfTokens.s3),
                    Row(
                      children: [
                        LfButton(
                          label: 'Connect',
                          size: LfButtonSize.sm,
                          variant: LfButtonVariant.secondary,
                          icon: Icons.link_rounded,
                          onPressed: () => profile.setServerUrl(
                            serverCtl.text.trim().isEmpty
                                ? null
                                : serverCtl.text.trim(),
                          ),
                        ),
                        const SizedBox(width: LfTokens.s3),
                        Expanded(
                          child: Text(
                            conn.isConnected
                                ? 'Connected · ${conn.rttMs} ms'
                                : (conn.lastError ?? 'Not connected'),
                            style: context.text.bodySmall?.copyWith(
                              color: c.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LfTokens.s4),
              LfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LfEyebrow('CONTROLS'),
                    const SizedBox(height: LfTokens.s3),
                    Wrap(
                      spacing: LfTokens.s4,
                      runSpacing: LfTokens.s2,
                      children: const [
                        _Key('WASD / arrows', 'Move'),
                        _Key('Mouse', 'Aim'),
                        _Key('Click', 'Fire / swing / place'),
                        _Key('Shift', 'Sprint'),
                        _Key('Space', 'Leave bus / jump'),
                        _Key('E', 'Interact'),
                        _Key('R', 'Reload'),
                        _Key('Q', 'Build mode'),
                        _Key('Z X C V', 'Wall · Floor · Ramp · Roof'),
                        _Key('M', 'Cycle material'),
                        _Key('F', 'Edit piece'),
                        _Key('1–6', 'Pickaxe / hotbar'),
                        _Key('Tab', 'Spectate next'),
                      ],
                    ),
                    const SizedBox(height: LfTokens.s3),
                    Text(
                      'On touch screens: left stick moves, right stick aims and fires, buttons on the right handle build, interact and reload.',
                      style: context.text.bodySmall?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LfTokens.s4),
              LfPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LfEyebrow('ABOUT'),
                    const SizedBox(height: LfTokens.s2),
                    Text(
                      'Lastfort · protocol v${Protocol.version} · ${scope.config.platformName}',
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Original battle-royale with building. All art, names and cosmetics are Lastfort originals.',
                      style: context.text.bodySmall?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: context.text.titleMedium),
    subtitle: Text(
      detail,
      style: context.text.bodySmall?.copyWith(color: context.lf.muted),
    ),
    value: value,
    activeThumbColor: LfTokens.ember,
    onChanged: onChanged,
  );
}

class _Key extends StatelessWidget {
  const _Key(this.key_, this.action);
  final String key_;
  final String action;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.line),
          ),
          child: Text(
            key_,
            style: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(action, style: context.text.bodySmall?.copyWith(color: c.muted)),
      ],
    );
  }
}

class _ConnDot extends StatelessWidget {
  const _ConnDot({required this.conn});
  final net.Connection conn;

  @override
  Widget build(BuildContext context) {
    final color = switch (conn.state) {
      net.ConnectionState.connected => LfTokens.health,
      net.ConnectionState.connecting ||
      net.ConnectionState.reconnecting => LfTokens.warning,
      net.ConnectionState.disconnected => LfTokens.danger,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
    );
  }
}
