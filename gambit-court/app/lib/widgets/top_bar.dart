import 'package:flutter/material.dart';

import '../net/connection.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'brand.dart';
import 'ui.dart';

/// App header: wordmark, connection status, identity and preference toggles.
class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.controller,
    this.leading,
    this.trailing = const [],
    this.compact = false,
  });

  final AppController controller;
  final Widget? leading;
  final List<Widget> trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    // Narrow phones with contextual trailing content (room code, status)
    // collapse the wordmark to the mark and drop the connection pill; the
    // connection banner below the bar still surfaces any outage.
    final tight = compact && trailing.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? GcSpace.md : GcSpace.xl,
        vertical: compact ? GcSpace.sm : GcSpace.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: GcSpace.sm)],
          if (tight)
            const GcMark(size: 26)
          else
            GcWordmark(size: compact ? 17 : 20),
          if (!tight) ...[
            const SizedBox(width: GcSpace.md),
            ConnectionPill(
              connection: controller.connection,
              online: controller.online,
            ),
          ],
          const Spacer(),
          ...trailing,
          if (trailing.isNotEmpty) const SizedBox(width: GcSpace.xs),
          if (!compact) ...[
            NameButton(controller: controller),
            const SizedBox(width: GcSpace.xs),
          ],
          GcIconButton(
            icon: controller.soundOn
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            tooltip: controller.soundOn ? 'Mute sounds' : 'Unmute sounds',
            onPressed: controller.toggleSound,
          ),
          ThemeToggle(controller: controller),
        ],
      ),
    );
  }
}

class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key, required this.connection, this.online});
  final Connection connection;
  final int? online;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return ValueListenableBuilder<ConnectionPhase>(
      valueListenable: connection.phase,
      builder: (context, phase, _) {
        final (label, color, pulse) = switch (phase) {
          ConnectionPhase.online => (
            online != null && online! > 0 ? 'Online · $online' : 'Online',
            c.verdigris,
            false,
          ),
          ConnectionPhase.connecting => ('Connecting', c.brass, true),
          ConnectionPhase.reconnecting => ('Reconnecting', c.brass, true),
          ConnectionPhase.offline => ('Offline', c.danger, false),
        };
        return GcPill(label: label, color: color, pulse: pulse);
      },
    );
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return GcIconButton(
      icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      tooltip: dark ? 'Switch to light theme' : 'Switch to dark theme',
      onPressed: () =>
          controller.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

class NameButton extends StatelessWidget {
  const NameButton({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Tooltip(
      message: 'Change display name',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showNameDialog(context, controller),
          borderRadius: GcRadius.smAll,
          hoverColor: c.text.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: c.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.name,
                  style: GcType.body(c.text, size: 13, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showNameDialog(
  BuildContext context,
  AppController controller,
) async {
  final text = TextEditingController(text: controller.name);
  final c = context.gc;
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Display name', style: GcType.heading(c.text, size: 18)),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: text,
          autofocus: true,
          maxLength: 24,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(context).pop(v),
          decoration: const InputDecoration(hintText: 'How opponents see you'),
          style: GcType.body(c.text, size: 15),
        ),
      ),
      actions: [
        GcButton(
          label: 'Cancel',
          kind: GcButtonKind.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GcButton(
          label: 'Save',
          kind: GcButtonKind.primary,
          onPressed: () => Navigator.of(context).pop(text.text),
        ),
      ],
    ),
  );
  if (result != null) controller.setName(result);
}
