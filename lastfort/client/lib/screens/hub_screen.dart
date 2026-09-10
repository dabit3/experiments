import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/profile.dart';
import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import '../net/connection.dart' as net;
import '../net/session.dart';
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

/// Lobby hub: navigation rail/bar plus the Play, Locker, Pass and Settings
/// tabs. Also hosts the post-match results while the room is back in lobby.
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
                child: layout.isPhone
                    ? Column(
                        children: [
                          Expanded(child: _animated(body)),
                          _BottomNav(tab: tab, onSelect: _select),
                        ],
                      )
                    : Row(
                        children: [
                          _SideNav(
                            tab: tab,
                            onSelect: _select,
                            compact: layout == LfLayout.tablet,
                          ),
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

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.tab,
    required this.onSelect,
    required this.compact,
  });
  final HubTab tab;
  final ValueChanged<HubTab> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final profile = AppScope.of(context).profile;
    return Container(
      width: compact ? 88 : 232,
      margin: const EdgeInsets.all(LfTokens.s4),
      padding: const EdgeInsets.symmetric(
        vertical: LfTokens.s5,
        horizontal: LfTokens.s3,
      ),
      decoration: BoxDecoration(
        color: c.glass,
        borderRadius: BorderRadius.circular(LfTokens.rLg),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LfTokens.s2),
            child: compact
                ? const Center(
                    child: LastfortWordmark(size: 28, iconOnly: true),
                  )
                : const LastfortWordmark(size: 28),
          ),
          const SizedBox(height: LfTokens.s6),
          for (final t in HubTab.values)
            _NavItem(
              tab: t,
              selected: t == tab,
              compact: compact,
              onTap: () => onSelect(t),
              badge: t == HubTab.pass ? profile.claimable.length : 0,
            ),
          const Spacer(),
          ListenableBuilder(
            listenable: profile,
            builder: (context, _) => _ProfileCard(compact: compact),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.compact,
    required this.onTap,
    this.badge = 0,
  });
  final HubTab tab;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final sel = widget.selected;
    final fg = sel ? LfTokens.ember : (hover ? c.text : c.muted);
    return Semantics(
      button: true,
      selected: sel,
      label: widget.tab.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: LfTokens.fast,
            margin: const EdgeInsets.only(bottom: LfTokens.s1),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 0 : LfTokens.s3,
              vertical: LfTokens.s3,
            ),
            decoration: BoxDecoration(
              color: sel
                  ? LfTokens.ember.withValues(alpha: 0.12)
                  : (hover
                        ? c.surface2.withValues(alpha: 0.6)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(LfTokens.rMd),
              border: Border.all(
                color: sel
                    ? LfTokens.ember.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(widget.tab.icon, color: fg, size: 22),
                    if (widget.badge > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: LfTokens.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.badge}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF062B29),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!widget.compact) ...[
                  const SizedBox(width: LfTokens.s3),
                  Text(
                    widget.tab.label.toUpperCase(),
                    style: context.text.labelLarge?.copyWith(
                      color: fg,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tab, required this.onSelect});
  final HubTab tab;
  final ValueChanged<HubTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final profile = AppScope.of(context).profile;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        LfTokens.s3,
        0,
        LfTokens.s3,
        LfTokens.s3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s2,
        vertical: LfTokens.s2,
      ),
      decoration: BoxDecoration(
        color: c.glassStrong,
        borderRadius: BorderRadius.circular(LfTokens.rLg),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (final t in HubTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == tab,
                label: t.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(t),
                  child: AnimatedContainer(
                    duration: LfTokens.fast,
                    padding: const EdgeInsets.symmetric(vertical: LfTokens.s2),
                    decoration: BoxDecoration(
                      color: t == tab
                          ? LfTokens.ember.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(LfTokens.rMd),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              t.icon,
                              size: 22,
                              color: t == tab ? LfTokens.ember : c.muted,
                            ),
                            if (t == HubTab.pass &&
                                profile.claimable.isNotEmpty)
                              Positioned(
                                right: -4,
                                top: -3,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: LfTokens.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.label,
                          style: context.text.labelSmall?.copyWith(
                            color: t == tab ? LfTokens.ember : c.muted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    final c = context.lf;
    final outfit = profile.equipped(CosmeticSlot.outfit);
    if (compact) {
      return Center(child: OutfitAvatar(outfit, size: 44));
    }
    return Container(
      padding: const EdgeInsets.all(LfTokens.s3),
      decoration: BoxDecoration(
        color: c.surface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(LfTokens.rMd),
      ),
      child: Row(
        children: [
          OutfitAvatar(outfit, size: 40),
          const SizedBox(width: LfTokens.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: context.text.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'TIER ${profile.level}',
                      style: context.text.labelSmall?.copyWith(
                        color: LfTokens.teal,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: LfTokens.s2),
                    Expanded(
                      child: LfBar(
                        value: profile.tierProgress,
                        color: LfTokens.teal,
                        height: 5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// ------------------------------------------------------------------ Play tab

class PlayTab extends StatefulWidget {
  const PlayTab({super.key});

  @override
  State<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<PlayTab> {
  final codeCtl = TextEditingController();
  SquadMode mode = SquadMode.squads;

  @override
  void dispose() {
    codeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final layout = LfLayout.of(context);
    final pad = layout.isPhone ? LfTokens.s4 : LfTokens.s6;

    return ListenableBuilder(
      listenable: Listenable.merge([session, session.connection]),
      builder: (context, _) => _buildPage(context, session, layout, pad),
    );
  }

  Widget _buildPage(
    BuildContext context,
    Session session,
    LfLayout layout,
    double pad,
  ) {
    final room = session.room;
    return LfPage(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          pad,
          layout.isPhone ? LfTokens.s5 : LfTokens.s6,
          pad,
          LfTokens.s6,
        ),
        children: [
          _Hero(),
          const SizedBox(height: LfTokens.s5),
          AnimatedSwitcher(
            duration: LfTokens.base,
            child: room == null
                ? _CreateJoinPanel(
                    key: const ValueKey('create'),
                    codeCtl: codeCtl,
                    mode: mode,
                    onMode: (m) => setState(() => mode = m),
                  )
                : _RoomPanel(key: ValueKey(room.code), room: room),
          ),
          if (session.notice != null && room == null) ...[
            const SizedBox(height: LfTokens.s3),
            _Notice(text: session.notice!, onDismiss: session.clearNotice),
          ],
          const SizedBox(height: LfTokens.s5),
          const _HowToPlay(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    final layout = LfLayout.of(context);
    final c = context.lf;
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final outfit = profile.equipped(CosmeticSlot.outfit);
        final stats = profile.career;
        final phone = layout.isPhone;
        return LfPanel(
          strong: true,
          padding: EdgeInsets.all(phone ? LfTokens.s4 : LfTokens.s5),
          child: Row(
            children: [
              OutfitAvatar(outfit, size: phone ? 72 : 104),
              SizedBox(width: phone ? LfTokens.s4 : LfTokens.s5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LfEyebrow('WELCOME BACK'),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: (phone
                                ? context.text.headlineMedium
                                : context.text.headlineLarge),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: LfTokens.s2),
                        IconButton(
                          tooltip: 'Change name',
                          onPressed: () => _editName(context, profile),
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: c.muted,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: LfTokens.s2),
                    Wrap(
                      spacing: LfTokens.s4,
                      runSpacing: LfTokens.s1,
                      children: [
                        _MiniStat('Wins', '${stats.wins}', LfTokens.warning),
                        _MiniStat('Matches', '${stats.matches}', c.text),
                        _MiniStat('Elims', '${stats.kills}', LfTokens.ember),
                        _MiniStat('Tier', '${profile.level}', LfTokens.teal),
                      ],
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

  Future<void> _editName(BuildContext context, Profile profile) async {
    final ctl = TextEditingController(text: profile.name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 16,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v != null && v.trim().isNotEmpty) await profile.setName(v.trim());
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(value, style: context.text.titleLarge?.copyWith(color: color)),
      const SizedBox(width: 4),
      Text(
        label.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: context.lf.muted,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

class _CreateJoinPanel extends StatelessWidget {
  const _CreateJoinPanel({
    super.key,
    required this.codeCtl,
    required this.mode,
    required this.onMode,
  });
  final TextEditingController codeCtl;
  final SquadMode mode;
  final ValueChanged<SquadMode> onMode;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final layout = LfLayout.of(context);
    final c = context.lf;
    final connected = session.connection.isConnected;

    final create = LfPanel(
      accent: LfTokens.ember,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LfEyebrow('NEW MATCH'),
          const SizedBox(height: LfTokens.s1),
          Text('Create a room', style: context.text.headlineSmall),
          const SizedBox(height: LfTokens.s3),
          Text(
            'Pick a squad size. Empty slots fill with bots when the host starts.',
            style: context.text.bodyMedium?.copyWith(color: c.muted),
          ),
          const SizedBox(height: LfTokens.s4),
          Wrap(
            spacing: LfTokens.s2,
            runSpacing: LfTokens.s2,
            children: [
              for (final m in SquadMode.values)
                LfChip(
                  label: '${m.label} · ${m.size}',
                  selected: m == mode,
                  onTap: () => onMode(m),
                  color: LfTokens.ember,
                ),
            ],
          ),
          const SizedBox(height: LfTokens.s5),
          LfButton(
            label: 'Create room',
            icon: Icons.add_rounded,
            size: LfButtonSize.lg,
            expand: true,
            onPressed: connected ? () => session.createRoom(mode: mode) : null,
          ),
        ],
      ),
    );

    final join = LfPanel(
      accent: LfTokens.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LfEyebrow('WITH FRIENDS', color: LfTokens.teal),
          const SizedBox(height: LfTokens.s1),
          Text('Join with a code', style: context.text.headlineSmall),
          const SizedBox(height: LfTokens.s3),
          Text(
            'Codes work across web, iOS, Android and macOS.',
            style: context.text.bodyMedium?.copyWith(color: c.muted),
          ),
          const SizedBox(height: LfTokens.s4),
          TextField(
            controller: codeCtl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              UpperCaseTextFormatter(),
              FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            style: context.text.headlineSmall?.copyWith(
              letterSpacing: 6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'ROOM CODE'),
            onSubmitted: (v) => _join(session, v),
          ),
          const SizedBox(height: LfTokens.s4),
          ValueListenableBuilder(
            valueListenable: codeCtl,
            builder: (context, v, _) => LfButton(
              label: 'Join room',
              icon: Icons.login_rounded,
              variant: LfButtonVariant.secondary,
              size: LfButtonSize.lg,
              expand: true,
              onPressed: connected && v.text.trim().length >= 4
                  ? () => _join(session, v.text)
                  : null,
            ),
          ),
        ],
      ),
    );

    if (layout.isPhone) {
      return Column(
        children: [
          create,
          const SizedBox(height: LfTokens.s4),
          join,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: create),
        const SizedBox(width: LfTokens.s4),
        Expanded(child: join),
      ],
    );
  }

  void _join(Session s, String v) {
    final code = v.trim().toUpperCase();
    if (code.isEmpty) return;
    s.joinRoom(code);
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _RoomPanel extends StatelessWidget {
  const _RoomPanel({super.key, required this.room});
  final RoomState room;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final layout = LfLayout.of(context);
    final c = context.lf;
    final members = room.members;
    final humans = members.length;
    final isHost = session.isHost;
    final ready = session.isReady;
    final allReady = members.every((m) => m.ready || m.host);
    final counting = room.phase == 'countdown';

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LfEyebrow('ROOM CODE'),
              const SizedBox(height: 2),
              Row(
                children: [
                  SelectableText(
                    room.code,
                    style: context.text.displaySmall?.copyWith(
                      letterSpacing: 6,
                      color: LfTokens.ember,
                    ),
                  ),
                  const SizedBox(width: LfTokens.s2),
                  IconButton(
                    tooltip: 'Copy code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: room.code));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room code copied'),
                          behavior: SnackBarBehavior.floating,
                          width: 240,
                        ),
                      );
                    },
                    icon: Icon(Icons.copy_rounded, color: c.muted, size: 20),
                  ),
                ],
              ),
              Wrap(
                spacing: LfTokens.s2,
                children: [
                  LfChip(
                    label: room.mode.label,
                    selected: true,
                    color: LfTokens.teal,
                    icon: Icons.groups_rounded,
                  ),
                  LfChip(
                    label: '$humans / ${room.maxPlayers} players',
                    color: c.muted,
                    icon: Icons.person_rounded,
                  ),
                  if (room.fast)
                    LfChip(
                      label: 'Fast rules',
                      color: LfTokens.warning,
                      icon: Icons.bolt_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
        LfButton(
          label: 'Leave',
          icon: Icons.logout_rounded,
          variant: LfButtonVariant.ghost,
          size: LfButtonSize.sm,
          onPressed: session.leaveRoom,
        ),
      ],
    );

    final roster = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LfEyebrow('SQUAD LOBBY'),
        const SizedBox(height: LfTokens.s2),
        for (final m in members) _MemberRow(m: m, me: m.id == session.myId),
        for (
          var i = humans;
          i <
              (layout.isPhone
                  ? humans + 1
                  : (humans + 2).clamp(0, room.maxPlayers));
          i++
        )
          const _EmptySlotRow(),
        if (humans < room.maxPlayers)
          Padding(
            padding: const EdgeInsets.only(top: LfTokens.s2),
            child: Text(
              '${room.maxPlayers - humans} slot${room.maxPlayers - humans == 1 ? '' : 's'} will be filled with bots.',
              style: context.text.bodySmall?.copyWith(color: c.muted),
            ),
          ),
      ],
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isHost) ...[
          const LfEyebrow('HOST CONTROLS'),
          const SizedBox(height: LfTokens.s2),
          Wrap(
            spacing: LfTokens.s2,
            runSpacing: LfTokens.s2,
            children: [
              for (final m in SquadMode.values)
                LfChip(
                  label: m.label,
                  selected: m == room.mode,
                  onTap: () => session.setMode(m),
                  color: LfTokens.teal,
                ),
            ],
          ),
          const SizedBox(height: LfTokens.s4),
          LfButton(
            label: counting ? 'Starting…' : 'Start match',
            icon: Icons.rocket_launch_rounded,
            size: LfButtonSize.lg,
            expand: true,
            onPressed: counting
                ? null
                : () => session.startMatch(fill: room.maxPlayers),
          ),
          const SizedBox(height: LfTokens.s2),
          Text(
            allReady
                ? 'Everyone is ready.'
                : 'You can start before everyone readies up.',
            style: context.text.bodySmall?.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const LfEyebrow('READY UP'),
          const SizedBox(height: LfTokens.s2),
          LfButton(
            label: ready ? 'Ready ✓' : 'I\'m ready',
            icon: ready
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            variant: ready
                ? LfButtonVariant.secondary
                : LfButtonVariant.primary,
            size: LfButtonSize.lg,
            expand: true,
            onPressed: () => session.setReady(!ready),
          ),
          const SizedBox(height: LfTokens.s2),
          Text(
            counting ? 'Match starting…' : 'Waiting for the host to start.',
            style: context.text.bodySmall?.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
        if (counting) ...[
          const SizedBox(height: LfTokens.s3),
          const LinearProgressIndicator(
            minHeight: 4,
            color: LfTokens.ember,
            backgroundColor: Colors.transparent,
          ),
        ],
      ],
    );

    return LfPanel(
      strong: true,
      accent: LfTokens.ember,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: LfTokens.s4),
          Divider(color: c.line, height: 1),
          const SizedBox(height: LfTokens.s4),
          if (layout.isPhone) ...[
            roster,
            const SizedBox(height: LfTokens.s5),
            actions,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: roster),
                const SizedBox(width: LfTokens.s5),
                Expanded(flex: 2, child: actions),
              ],
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.m, required this.me});
  final RoomMember m;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final outfit = cosmeticById(m.loadout.outfit);
    return Container(
      margin: const EdgeInsets.only(bottom: LfTokens.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s3,
        vertical: LfTokens.s2,
      ),
      decoration: BoxDecoration(
        color: me
            ? LfTokens.ember.withValues(alpha: 0.08)
            : c.surface2.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(LfTokens.rMd),
        border: Border.all(
          color: me ? LfTokens.ember.withValues(alpha: 0.4) : c.line,
        ),
      ),
      child: Row(
        children: [
          OutfitAvatar(outfit, size: 36),
          const SizedBox(width: LfTokens.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.name,
                        style: context.text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (me)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'YOU',
                          style: context.text.labelSmall?.copyWith(
                            color: LfTokens.ember,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Team ${m.team + 1}',
                  style: context.text.bodySmall?.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          PlatformBadge(m.platform),
          const SizedBox(width: LfTokens.s2),
          if (m.host)
            Tooltip(
              message: 'Host',
              child: Icon(
                Icons.star_rounded,
                color: LfTokens.warning,
                size: 20,
              ),
            )
          else
            Tooltip(
              message: m.ready ? 'Ready' : 'Not ready',
              child: Icon(
                m.ready
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: m.ready ? LfTokens.health : c.muted,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySlotRow extends StatelessWidget {
  const _EmptySlotRow();

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return Container(
      margin: const EdgeInsets.only(bottom: LfTokens.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s3,
        vertical: LfTokens.s3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LfTokens.rMd),
        border: Border.all(color: c.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.line),
            ),
            child: Icon(Icons.smart_toy_outlined, size: 18, color: c.muted),
          ),
          const SizedBox(width: LfTokens.s3),
          Text(
            'Open slot · bot fills on start',
            style: context.text.bodyMedium?.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
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

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.onDismiss});
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
