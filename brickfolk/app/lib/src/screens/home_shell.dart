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
  final _search = TextEditingController();
  String _query = '';
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
      case 'place':
        _select(HubTab.play);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PlaceDetailsPage(ExperienceKind.obby),
          ),
        );
    }
  }

  @override
  void dispose() {
    _errSub?.cancel();
    _screenSub?.cancel();
    _search.dispose();
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
      const _Dest(HubTab.play, 'Home', Icons.home_outlined, Icons.home_rounded),
      const _Dest(
        HubTab.avatar,
        'Avatar',
        Icons.accessibility_new_outlined,
        Icons.accessibility_new_rounded,
      ),
      _Dest(
        HubTab.social,
        'Friends',
        Icons.people_outline_rounded,
        Icons.people_rounded,
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
        HubTab.play => PlacesScreen(
          key: const ValueKey('play'),
          query: _query,
          onOpenFriends: () => _select(HubTab.social),
        ),
        HubTab.avatar => const AvatarScreen(key: ValueKey('avatar')),
        HubTab.social => const SocialScreen(key: ValueKey('social')),
        HubTab.chat => const ChatPanel(key: ValueKey('chat'), standalone: true),
        HubTab.profile => const ProfileScreen(key: ValueKey('profile')),
      },
    );

    final topBar = _ChromeBar(
      searchController: _search,
      onSearch: (q) => setState(() {
        _query = q;
        if (q.isNotEmpty) _tab = HubTab.play;
      }),
    );

    if (form == FormFactor.phone) {
      return Scaffold(
        appBar: topBar,
        body: body,
        bottomNavigationBar: _ChromeTabBar(
          destinations: destinations,
          selected: _tab,
          onSelect: _select,
        ),
      );
    }

    return Scaffold(
      appBar: topBar,
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: _SideNav(
              destinations: destinations,
              selected: _tab,
              onSelect: _select,
              extended: form == FormFactor.desktop,
            ),
          ),
          Expanded(child: body),
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
      backgroundColor: BrickColors.cherry,
      textColor: Colors.white,
      child: child,
    );
  }
}

/// Brickfolk mark: a white two-by-two stud on a rounded tile.
class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.grid_view_rounded,
        size: size * 0.6,
        color: BrickColors.chrome,
      ),
    );
  }
}

const _chromeHeight = 52.0;
const _sideNavWidth = 200.0;
const _sideNavCompactWidth = 72.0;

/// Near-black top bar shared by every form factor: brand, search, wallet,
/// daily gift, theme, settings, avatar.
class _ChromeBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChromeBar({required this.searchController, required this.onSearch});

  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Size get preferredSize => const Size.fromHeight(_chromeHeight);

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final app = AppScope.of(context);
    final me = client.me!;
    final form = context.formFactor;
    final phone = form == FormFactor.phone;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final canClaim = DailyReward.canClaim(
      me.lastDailyClaim,
      client.serverNow(),
    );
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: BrickColors.chrome,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _chromeHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              children: [
                const _Logo(size: 28),
                if (!compact) ...[
                  const SizedBox(width: Space.sm),
                  Text(
                    'Brickfolk',
                    style: context.text.titleMedium?.copyWith(
                      color: BrickColors.onChrome,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
                if (phone)
                  const Spacer()
                else ...[
                  const SizedBox(width: Space.xl),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _SearchField(
                          controller: searchController,
                          onChanged: onSearch,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.lg),
                ],
                _ChromePips(me.pips, compact: phone),
                const SizedBox(width: Space.xs),
                Tooltip(
                  message: canClaim ? 'Daily reward ready!' : 'Daily reward',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ChromeIconButton(
                        icon: Icons.card_giftcard_rounded,
                        color: canClaim ? BrickColors.sun : null,
                        onPressed: () => showDailyRewardSheet(context),
                      ),
                      if (canClaim)
                        Positioned(
                          right: 7,
                          top: 7,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: BrickColors.cherry,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: BrickColors.chrome,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!phone)
                  _ChromeIconButton(
                    tooltip: dark ? 'Light theme' : 'Dark theme',
                    icon: dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    onPressed: () =>
                        app.setTheme(dark ? ThemeMode.light : ThemeMode.dark),
                  ),
                _ChromeIconButton(
                  tooltip: 'Settings',
                  icon: Icons.settings_outlined,
                  onPressed: () => showSettingsSheet(context),
                ),
                if (!compact) ...[
                  const SizedBox(width: Space.xs),
                  Tooltip(
                    message: me.summary.name,
                    child: Headshot(me.summary.avatar, size: 30),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: context.text.bodyMedium?.copyWith(color: BrickColors.onChrome),
        cursorColor: BrickColors.onChrome,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search',
          hintStyle: context.text.bodyMedium?.copyWith(
            color: BrickColors.onChromeMuted,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: Space.sm, right: Space.xs),
            child: Icon(
              Icons.search_rounded,
              size: 18,
              color: BrickColors.onChromeMuted,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  color: BrickColors.onChromeMuted,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: BrickColors.chromeRaised,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            borderSide: const BorderSide(color: BrickColors.sky, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 22,
      color: color ?? BrickColors.onChrome,
      hoverColor: Colors.white12,
      icon: Icon(icon),
    );
  }
}

/// Wallet balance in the dark chrome.
class _ChromePips extends StatelessWidget {
  const _ChromePips(this.pips, {required this.compact});

  final int pips;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Pips',
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? Space.sm : Space.md,
        ),
        decoration: BoxDecoration(
          color: BrickColors.chromeRaised,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PipIcon(size: 16),
            const SizedBox(width: Space.xs + 2),
            Text(
              formatNumber(pips),
              style: context.text.labelLarge?.copyWith(
                color: BrickColors.onChrome,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Left navigation list (desktop shows labels, tablet shows icons only).
class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.extended,
  });

  final List<_Dest> destinations;
  final HubTab selected;
  final ValueChanged<HubTab> onSelect;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final me = ClientScope.of(context).me!;
    return Container(
      width: extended ? _sideNavWidth : _sideNavCompactWidth,
      color: p.surface0,
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.md,
        Space.md,
        Space.lg,
      ),
      child: Column(
        children: [
          _NavRow(
            icon: null,
            selectedIcon: null,
            avatar: me.summary.avatar,
            label: me.summary.name,
            selected: false,
            extended: extended,
            onTap: () => onSelect(HubTab.profile),
          ),
          const SizedBox(height: Space.sm),
          for (final d in destinations)
            _NavRow(
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              label: d.label,
              badge: d.badge,
              selected: d.tab == selected,
              extended: extended,
              onTap: () => onSelect(d.tab),
            ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.extended,
    required this.onTap,
    this.avatar,
    this.badge = 0,
  });

  final IconData? icon;
  final IconData? selectedIcon;
  final Avatar? avatar;
  final String label;
  final int badge;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.textPrimary : p.textSecondary;
    final leading = avatar != null
        ? Headshot(avatar!, size: 28)
        : _Badged(
            count: badge,
            child: Icon(selected ? selectedIcon : icon, size: 22, color: fg),
          );
    final row = Material(
      color: selected ? p.surface2 : Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: extended ? Space.md : 0),
          alignment: Alignment.centerLeft,
          child: extended
              ? Row(
                  children: [
                    leading,
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Text(
                        label,
                        style: context.text.titleSmall?.copyWith(
                          color: fg,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(child: leading),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: extended ? row : Tooltip(message: label, child: row),
    );
  }
}

/// Phone bottom tabs on the dark chrome.
class _ChromeTabBar extends StatelessWidget {
  const _ChromeTabBar({
    required this.destinations,
    required this.selected,
    required this.onSelect,
  });

  final List<_Dest> destinations;
  final HubTab selected;
  final ValueChanged<HubTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrickColors.chrome,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final d in destinations)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(d.tab),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Badged(
                          count: d.badge,
                          child: Icon(
                            d.tab == selected ? d.selectedIcon : d.icon,
                            size: 24,
                            color: d.tab == selected
                                ? BrickColors.onChrome
                                : BrickColors.onChromeMuted,
                          ),
                        ),
                        const SizedBox(height: Space.xxs),
                        Text(
                          d.label,
                          style: context.text.labelSmall?.copyWith(
                            color: d.tab == selected
                                ? BrickColors.onChrome
                                : BrickColors.onChromeMuted,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
