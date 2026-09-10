import 'dart:async';

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';

/// The signed-in player's profile: stats, badges, inventory.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = ClientScope.of(context).me!;
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xxl,
        ),
        children: [
          SectionHeader('Profile'),
          Entrance(child: ProfileCard(me, isMe: true)),
        ],
      ),
    );
  }
}

Future<void> showProfileDialog(BuildContext context, String playerId) {
  final client = AppScope.of(context).client;
  client.profileGet(playerId);
  return showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(Space.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: _ProfileLoader(playerId: playerId),
      ),
    ),
  );
}

class _ProfileLoader extends StatefulWidget {
  const _ProfileLoader({required this.playerId});

  final String playerId;

  @override
  State<_ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<_ProfileLoader> {
  PlayerProfile? _profile;
  StreamSubscription<PlayerProfile>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = AppScope.read(context).client.profiles.listen((p) {
      if (p.summary.id == widget.playerId && mounted) {
        setState(() => _profile = p);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: profile == null
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : ProfileCard(
              profile,
              isMe: profile.summary.id == ClientScope.of(context).myId,
            ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard(this.profile, {super.key, required this.isMe});

  final PlayerProfile profile;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final client = ClientScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.phone;
    final joined = DateTime.fromMillisecondsSinceEpoch(profile.createdAt);
    final isFriend = client.friends.friends.any(
      (f) => f.id == profile.summary.id,
    );
    final stats = <(String, String, IconData)>[
      (
        'Matches',
        '${profile.stats['matches'] ?? 0}',
        Icons.sports_esports_rounded,
      ),
      ('Wins', '${profile.stats['wins'] ?? 0}', Icons.emoji_events_rounded),
      (
        'Obby finishes',
        '${profile.stats['obbyFinishes'] ?? 0}',
        Icons.flag_rounded,
      ),
      (
        'Bricks placed',
        '${profile.stats['bricksPlaced'] ?? 0}',
        Icons.grid_view_rounded,
      ),
      ('Freezes', '${profile.stats['freezes'] ?? 0}', Icons.ac_unit_rounded),
      (
        'Pips earned',
        formatNumber(profile.stats['pipsEarned'] ?? 0),
        Icons.savings_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.all(Space.xl),
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.center,
            children: [
              AvatarView(
                profile.summary.avatar,
                size: 120,
                background: p.surface2,
              ),
              SizedBox(width: wide ? Space.xl : 0, height: wide ? 0 : Space.lg),
              Expanded(
                flex: wide ? 1 : 0,
                child: Column(
                  crossAxisAlignment: wide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      profile.summary.name,
                      style: context.text.headlineMedium,
                    ),
                    const SizedBox(height: Space.xs),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      alignment: wide
                          ? WrapAlignment.start
                          : WrapAlignment.center,
                      children: [
                        Tag(
                          'Joined ${joined.year}-${joined.month.toString().padLeft(2, '0')}-${joined.day.toString().padLeft(2, '0')}',
                          icon: Icons.calendar_today_outlined,
                        ),
                        Tag(
                          '${profile.dailyStreak}-day streak',
                          icon: Icons.local_fire_department_rounded,
                          color: BrickColors.brick.withValues(alpha: 0.16),
                          onColor: BrickColors.brick,
                        ),
                        PlatformTag(profile.summary),
                      ],
                    ),
                    const SizedBox(height: Space.md),
                    Row(
                      mainAxisAlignment: wide
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        PipChip(profile.pips),
                        const SizedBox(width: Space.sm),
                        Tag(
                          '${profile.badges.length} badges',
                          icon: Icons.military_tech_rounded,
                        ),
                      ],
                    ),
                    if (!isMe) ...[
                      const SizedBox(height: Space.lg),
                      Wrap(
                        spacing: Space.sm,
                        children: [
                          if (!isFriend)
                            FilledButton.icon(
                              onPressed: () =>
                                  client.friendRequest(profile.summary.name),
                              icon: const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 18,
                              ),
                              label: const Text('Add friend'),
                            )
                          else
                            const Tag(
                              'Friends',
                              icon: Icons.favorite_rounded,
                              color: BrickColors.cherry,
                              onColor: Colors.white,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stats', style: context.text.titleMedium),
              const SizedBox(height: Space.md),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 700
                      ? 6
                      : (c.maxWidth >= 420 ? 3 : 2);
                  final w = (c.maxWidth - Space.sm * (cols - 1)) / cols;
                  return Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final (label, value, icon) in stats)
                        Container(
                          width: w,
                          padding: const EdgeInsets.all(Space.md),
                          decoration: BoxDecoration(
                            color: p.surface2,
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, size: 18, color: p.textTertiary),
                              const SizedBox(height: Space.sm),
                              Text(
                                value,
                                style: context.text.headlineSmall?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Text(
                                label,
                                style: context.text.bodySmall?.copyWith(
                                  color: p.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Badges · ${profile.badges.length}/${badges.length}',
                style: context.text.titleMedium,
              ),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.lg,
                runSpacing: Space.lg,
                children: [
                  for (final b in badges)
                    SizedBox(
                      width: 84,
                      child: BadgeChip(
                        b.id,
                        size: 48,
                        showLabel: true,
                        locked: !profile.badges.contains(b.id),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (isMe) ...[
          const SizedBox(height: Space.lg),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory · ${profile.owned.length} items',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: Space.md),
                if (profile.owned.isEmpty)
                  Text(
                    'Buy hats, faces and accessories from the Avatar tab.',
                    style: context.text.bodySmall?.copyWith(
                      color: p.textTertiary,
                    ),
                  )
                else
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final id in profile.owned)
                        Tag(
                          catalogById[id]?.name ?? id,
                          icon: Icons.check_rounded,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
