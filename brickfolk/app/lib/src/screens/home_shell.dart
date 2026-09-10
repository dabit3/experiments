import 'dart:async';

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';
import 'avatar_screen.dart';
import 'chat_panel.dart';
import 'daily_reward_sheet.dart';
import 'places_screen.dart';
import 'profile_screen.dart';
import 'social_screen.dart';

enum HubTab { play, avatar, social, chat, profile }

/// The hub: responsive navigation around the five main destinations.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HubTab _tab = HubTab.play;
  StreamSubscription<ServerError>? _errSub;
  StreamSubscription<String>? _screenSub;
  int _seenChat = 0;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    final client = app.client;
    client.refreshPlaces();
    _screenSub = app.screenRequests.listen(_showRequested);
    _errSub = client.errors.listen((e) {
      if (!mounted || e.inReplyTo == MsgType.hello) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferDaily());
  }

  void _maybeOfferDaily() {
    final app = AppScope.read(context);
    if (app.config.testMode) return;
    final me = app.client.me;
    if (me == null) return;
    if (DailyReward.canClaim(me.lastDailyClaim, app.client.serverNow())) {
      showDailyRewardSheet(context);
    }
  }

  void _showRequested(String id) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    switch (id) {
      case 'hub':
        _select(HubTab.play);
      case 'avatar':
        _select(HubTab.avatar);
      case 'social':
        _select(HubTab.social);
      case 'chat':
        _select(HubTab.chat);
      case 'profile':
        _select(HubTab.profile);
      case 'daily':
        showDailyRewardSheet(context);
    }
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _screenSub?.cancel();
    super.dispose();
  }

  void _select(HubTab tab) {
    setState(() {
      _tab = tab;
      if (tab == HubTab.chat) {
        _seenChat = AppScope.read(context).client.chat.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final form = context.formFactor;
    final unreadChat = (client.chat.length - _seenChat).clamp(0, 99);
    final pendingFriends = client.friends.incoming.length;

    final destinations = [
      const _Dest(
        HubTab.play,
        'Play',
        Icons.sports_esports_outlined,
        Icons.sports_esports_rounded,
      ),
      const _Dest(
        HubTab.avatar,
        'Avatar',
        Icons.face_outlined,
        Icons.face_rounded,
      ),
      _Dest(
        HubTab.social,
        'Friends',
        Icons.group_outlined,
        Icons.group_rounded,
        badge: pendingFriends,
      ),
      _Dest(
        HubTab.chat,
        'Chat',
        Icons.chat_bubble_outline_rounded,
        Icons.chat_bubble_rounded,
        badge: _tab == HubTab.chat ? 0 : unreadChat,
      ),
      const _Dest(
        HubTab.profile,
        'Profile',
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];

    final body = AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: switch (_tab) {
        HubTab.play => const PlacesScreen(key: ValueKey('play')),
        HubTab.avatar => const AvatarScreen(key: ValueKey('avatar')),
        HubTab.social => const SocialScreen(key: ValueKey('social')),
        HubTab.chat => const ChatPanel(key: ValueKey('chat'), standalone: true),
        HubTab.profile => const ProfileScreen(key: ValueKey('profile')),
      },
    );

    if (form == FormFactor.phone) {
      return Scaffold(
        appBar: _HubAppBar(),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (i) => _select(HubTab.values[i]),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: _Badged(count: d.badge, child: Icon(d.icon)),
                selectedIcon: _Badged(
                  count: d.badge,
                  child: Icon(d.selectedIcon),
                ),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              extended: form == FormFactor.desktop,
              minExtendedWidth: _railExtendedWidth,
              selectedIndex: _tab.index,
              onDestinationSelected: (i) => _select(HubTab.values[i]),
              labelType: form == FormFactor.desktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.lg),
                child: form == FormFactor.desktop
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Logo(size: 28),
                          const SizedBox(width: Space.sm),
                          Text('Brickfolk', style: context.text.titleLarge),
                        ],
                      )
                    : const _Logo(size: 28),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    child: _PlayerPill(extended: form == FormFactor.desktop),
                  ),
                ),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: _Badged(count: d.badge, child: Icon(d.icon)),
                    selectedIcon: _Badged(
                      count: d.badge,
                      child: Icon(d.selectedIcon),
                    ),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: context.palette.outline),
          Expanded(
            child: Column(
              children: [
                _HubAppBar(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dest {
  const _Dest(
    this.tab,
    this.label,
    this.icon,
    this.selectedIcon, {
    this.badge = 0,
  });

  final HubTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badge;
}

class _Badged extends StatelessWidget {
  const _Badged({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;
    return Badge.count(
      count: count,
      backgroundColor: BrickColors.brick,
      textColor: Colors.white,
      child: child,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: BrickColors.brick,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.grid_view_rounded,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}

/// Top bar: greeting, pips, daily reward, theme, settings.
class _HubAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final app = AppScope.of(context);
    final me = client.me!;
    final p = context.palette;
    final phone = context.isPhone;
    final canClaim = DailyReward.canClaim(
      me.lastDailyClaim,
      client.serverNow(),
    );

    return Material(
      color: p.surface0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(
              children: [
                if (phone) ...[
                  AvatarView(
                    me.summary.avatar,
                    size: 36,
                    background: p.surface2,
                  ),
                  const SizedBox(width: Space.md),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phone
                            ? me.summary.name
                            : 'Welcome back, ${me.summary.name}',
                        style: context.text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${client.onlineCount} online · ${me.badges.length} badge${me.badges.length == 1 ? '' : 's'}',
                        style: context.text.bodySmall?.copyWith(
                          color: p.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                PipChip(me.pips, compact: phone),
                const SizedBox(width: Space.sm),
                Tooltip(
                  message: canClaim ? 'Daily reward ready!' : 'Daily reward',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => showDailyRewardSheet(context),
                        icon: Icon(
                          Icons.card_giftcard_rounded,
                          color: canClaim ? BrickColors.sun : null,
                        ),
                      ),
                      if (canClaim)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: BrickColors.brick,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.surface0, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!phone)
                  IconButton(
                    tooltip: Theme.of(context).brightness == Brightness.dark
                        ? 'Light theme'
                        : 'Dark theme',
                    onPressed: () => app.setTheme(
                      Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => showSettingsSheet(context),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _railExtendedWidth = 200.0;

class _PlayerPill extends StatelessWidget {
  const _PlayerPill({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final me = ClientScope.of(context).me!;
    final p = context.palette;
    final avatar = AvatarView(
      me.summary.avatar,
      size: 40,
      background: p.surface2,
    );
    if (!extended) return avatar;
    return Container(
      width: _railExtendedWidth - Space.md * 2,
      margin: const EdgeInsets.symmetric(horizontal: Space.md),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  me.summary.name,
                  style: context.text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                PlatformTag(me.summary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (ctx) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: context.text.headlineSmall),
              const SizedBox(height: Space.lg),
              Text(
                'Appearance',
                style: context.text.labelMedium?.copyWith(
                  color: p.textTertiary,
                ),
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {app.themeMode},
                onSelectionChanged: (s) => app.setTheme(s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: Space.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptic feedback'),
                subtitle: const Text('Tiny taps on checkpoints and freezes'),
                value: app.hapticsEnabled,
                onChanged: app.setHaptics,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound effects'),
                subtitle: const Text('Jumps, coins and countdown blips'),
                value: app.soundEnabled,
                onChanged: app.setSound,
              ),
              const Divider(height: Space.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Connected to ${app.client.serverUrl}',
                      style: context.text.bodySmall?.copyWith(
                        color: p.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      app.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
