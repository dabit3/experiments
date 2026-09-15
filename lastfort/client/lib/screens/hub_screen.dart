import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import '../net/connection.dart' as net;
import '../net/session.dart';
import 'lobby_play.dart';
import 'locker_screen.dart';
import 'pass_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

enum HubTab {
  play('Play', Icons.sports_esports_rounded),
  locker('Locker', Icons.checkroom_rounded),
  pass('Pass', Icons.military_tech_rounded),
  settings('Settings', Icons.tune_rounded);

  const HubTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Lobby hub: a top tab bar (wordmark, PLAY / LOCKER / PASS / SETTINGS,
/// profile + tier) over the active tab. Also hosts the post-match results
/// while the room is back in lobby.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  HubTab tab = HubTab.play;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final layout = LfLayout.of(context);
    final c = context.lf;

    return Scaffold(
      backgroundColor: c.bg,
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (session.phase == SessionPhase.results &&
              session.lastSummary != null) {
            return ResultsScreen(
              summary: session.lastSummary!,
              myId: session.myId,
              xpGained: session.lastXpGained,
              onContinue: session.backToLobby,
            );
          }
          final body = switch (tab) {
            HubTab.play => const PlayTab(),
            HubTab.locker => const LockerScreen(),
            HubTab.pass => const PassScreen(),
            HubTab.settings => const SettingsScreen(),
          };
          return Stack(
            fit: StackFit.expand,
            children: [
              StormBackdrop(intensity: tab == HubTab.play ? 1 : 0.5),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(tab: tab, onSelect: _select, phone: layout.isPhone),
                    Expanded(child: _animated(body)),
                  ],
                ),
              ),
              const _ConnectionBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _animated(Widget body) => AnimatedSwitcher(
    duration: LfTokens.base,
    switchInCurve: LfTokens.ease,
    switchOutCurve: LfTokens.ease,
    transitionBuilder: (child, anim) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    ),
    child: KeyedSubtree(key: ValueKey(tab), child: body),
  );

  void _select(HubTab t) {
    if (t == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = t);
  }
}

/// Top navigation: wordmark, uppercase tabs with an ember underline on the
/// active one, then the player's outfit / name / tier on the right.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tab,
    required this.onSelect,
    required this.phone,
  });
  final HubTab tab;
  final ValueChanged<HubTab> onSelect;
  final bool phone;

  static const double height = 76;
  static const double phoneHeight = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final profile = AppScope.of(context).profile;
    return Container(
      height: phone ? phoneHeight : height,
      padding: EdgeInsets.symmetric(
        horizontal: phone ? LfTokens.s3 : LfTokens.s5,
      ),
      decoration: BoxDecoration(
        color: c.glass,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          LastfortWordmark(size: phone ? 26 : 30, iconOnly: phone),
          SizedBox(width: phone ? LfTokens.s3 : LfTokens.s6),
          Expanded(
            child: Semantics(
              container: true,
              label: 'Main navigation',
              child: Row(
                mainAxisAlignment: phone
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  for (final t in HubTab.values)
                    _Tab(
                      tab: t,
                      selected: t == tab,
                      phone: phone,
                      onTap: () => onSelect(t),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: phone ? LfTokens.s3 : LfTokens.s4),
          IconButton(
            tooltip: 'How a match works',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const SingleChildScrollView(child: _HowToPlay()),
                ),
              ),
            ),
            icon: Icon(Icons.help_outline_rounded, color: c.muted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          if (!phone) const SizedBox(width: LfTokens.s2),
          ListenableBuilder(
            listenable: profile,
            builder: (context, _) => _ProfilePill(phone: phone),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.phone,
    required this.onTap,
  });
  final HubTab tab;
  final bool selected;
  final bool phone;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final on = widget.selected;
    final style =
        (widget.phone ? context.text.labelMedium : context.text.titleMedium)
            ?.copyWith(
              letterSpacing: widget.phone ? 1 : 1.6,
              fontWeight: FontWeight.w700,
              color: on ? c.text : (_hover ? c.text : c.muted),
            );
    return Semantics(
      button: true,
      selected: on,
      label: '${widget.tab.label} tab',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: on
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        LfTokens.teal.withValues(alpha: 0),
                        LfTokens.teal.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.phone ? LfTokens.s1 : LfTokens.s4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(widget.tab.label.toUpperCase(), style: style),
                const Spacer(),
                AnimatedContainer(
                  duration: LfTokens.fast,
                  height: 3,
                  width: on ? (widget.phone ? 28 : 44) : 0,
                  decoration: BoxDecoration(
                    color: LfTokens.teal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.phone});
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    final c = context.lf;
    final outfit = profile.equipped(CosmeticSlot.outfit);
    return Semantics(
      label: '${profile.name}, tier ${profile.level}',
      child: Container(
        padding: EdgeInsets.fromLTRB(phone ? 2 : 4, 2, phone ? 2 : 12, 2),
        decoration: BoxDecoration(
          color: c.surface2.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutfitAvatar(outfit, size: 32),
            if (!phone) ...[
              const SizedBox(width: LfTokens.s2),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      profile.name,
                      style: context.text.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'TIER ${profile.level}',
                        style: context.text.labelSmall?.copyWith(
                          color: c.readable(LfTokens.teal),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 64,
                        child: LfBar(
                          value: profile.tierProgress,
                          color: LfTokens.teal,
                          height: 4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows connection status when not connected (slides in from the top).
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner();

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session.connection,
      builder: (context, _) {
        final conn = session.connection;
        final show = conn.state != net.ConnectionState.connected;
        final c = context.lf;
        final (label, color, icon) = switch (conn.state) {
          net.ConnectionState.connecting => (
            'Connecting to ${conn.url}',
            LfTokens.warning,
            Icons.sync_rounded,
          ),
          net.ConnectionState.reconnecting => (
            'Reconnecting (attempt ${conn.attempts})… ${conn.lastError ?? ''}',
            LfTokens.warning,
            Icons.wifi_find_rounded,
          ),
          net.ConnectionState.disconnected => (
            'Offline — ${conn.lastError ?? 'server unreachable'}',
            LfTokens.danger,
            Icons.wifi_off_rounded,
          ),
          net.ConnectionState.connected => (
            'Connected',
            LfTokens.health,
            Icons.wifi_rounded,
          ),
        };
        return IgnorePointer(
          ignoring: !show,
          child: AnimatedSlide(
            duration: LfTokens.base,
            curve: LfTokens.ease,
            offset: show ? Offset.zero : const Offset(0, -1.5),
            child: AnimatedOpacity(
              duration: LfTokens.base,
              opacity: show ? 1 : 0,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: LfTokens.s3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: LfTokens.s4,
                      vertical: LfTokens.s2,
                    ),
                    decoration: BoxDecoration(
                      color: c.glassStrong,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withValues(alpha: 0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: LfTokens.s2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Text(
                            label,
                            style: context.text.labelLarge?.copyWith(
                              color: c.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conn.state == net.ConnectionState.disconnected) ...[
                          const SizedBox(width: LfTokens.s3),
                          LfButton(
                            label: 'Retry',
                            size: LfButtonSize.sm,
                            variant: LfButtonVariant.secondary,
                            onPressed: conn.connect,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Small pill naming the client platform a player is on.
class PlatformBadge extends StatelessWidget {
  const PlatformBadge(this.platform, {super.key, this.compact = false});
  final String platform;
  final bool compact;

  static (String, IconData, Color) describe(String p) => switch (p) {
    'web' => ('Web', Icons.language_rounded, Color(0xFF4DA3FF)),
    'ios' => ('iOS', Icons.phone_iphone_rounded, Color(0xFFB5B9C2)),
    'android' => ('Android', Icons.android_rounded, Color(0xFF5FD068)),
    'macos' => ('macOS', Icons.laptop_mac_rounded, Color(0xFFB86BFF)),
    'server' => ('Bot', Icons.smart_toy_rounded, Color(0xFF93A0B8)),
    _ => (p, Icons.devices_other_rounded, Color(0xFF93A0B8)),
  };

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = describe(platform);
    return Semantics(
      label: 'Platform: $label',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LobbyNotice extends StatelessWidget {
  const LobbyNotice({super.key, required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => LfPanel(
    accent: LfTokens.danger,
    padding: const EdgeInsets.symmetric(
      horizontal: LfTokens.s4,
      vertical: LfTokens.s3,
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: LfTokens.danger,
          size: 20,
        ),
        const SizedBox(width: LfTokens.s3),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
        IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close_rounded, size: 18),
          tooltip: 'Dismiss',
        ),
      ],
    ),
  );
}

class _HowToPlay extends StatelessWidget {
  const _HowToPlay();

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final layout = LfLayout.of(context);
    final items = const [
      (
        Icons.flight_takeoff_rounded,
        'Drop',
        'Ride the balloon bus over the island and jump when you like the spot.',
      ),
      (
        Icons.inventory_2_rounded,
        'Loot',
        'Open chests for weapons, shields and ammo. Rarer is better.',
      ),
      (
        Icons.handyman_rounded,
        'Harvest & build',
        'Swing your tool at trees, rocks and cars. Build walls, floors, ramps and roofs.',
      ),
      (
        Icons.cyclone_rounded,
        'Survive the storm',
        'The circle shrinks in phases. Stay inside or take damage.',
      ),
    ];
    final tiles = [
      for (final it in items)
        Container(
          padding: const EdgeInsets.all(LfTokens.s3),
          decoration: BoxDecoration(
            color: c.surface2.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(LfTokens.rMd),
            border: Border.all(color: c.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(it.$1, color: LfTokens.teal, size: 22),
              const SizedBox(width: LfTokens.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.$2, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      it.$3,
                      style: context.text.bodySmall?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
    return LfPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LfEyebrow('HOW A MATCH WORKS'),
          const SizedBox(height: LfTokens.s3),
          if (layout.isPhone)
            Column(
              children: [
                for (final t in tiles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LfTokens.s2),
                    child: t,
                  ),
              ],
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final n = layout.isDesktop ? 4 : 2;
                final w = (box.maxWidth - LfTokens.s2 * (n - 1)) / n;
                return Wrap(
                  spacing: LfTokens.s2,
                  runSpacing: LfTokens.s2,
                  children: [
                    for (final t in tiles) SizedBox(width: w, child: t),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
