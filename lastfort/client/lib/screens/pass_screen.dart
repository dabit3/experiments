import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/profile.dart';
import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';

/// Season pass: XP progress, tier track with claimable rewards and career
/// stats.
class PassScreen extends StatelessWidget {
  const PassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    final layout = LfLayout.of(context);
    final c = context.lf;
    final pad = layout.isPhone ? LfTokens.s4 : LfTokens.s6;

    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final maxed = profile.level >= passTiers.length;
        final nextTier = maxed ? null : passTiers[profile.level];
        final career = profile.career;
        return LfPage(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              pad,
              layout.isPhone ? LfTokens.s5 : LfTokens.s6,
              pad,
              LfTokens.s6,
            ),
            children: [
              Text('Season pass', style: context.text.displaySmall),
              const SizedBox(height: LfTokens.s1),
              Text(
                'Earn XP from placement, eliminations, damage and survival. Claim rewards as you tier up.',
                style: context.text.bodyLarge?.copyWith(color: c.muted),
              ),
              const SizedBox(height: LfTokens.s5),
              LfPanel(
                strong: true,
                accent: LfTokens.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LfEyebrow(
                                'CURRENT TIER',
                                color: LfTokens.teal,
                              ),
                              Text(
                                '${profile.level}',
                                style: context.text.displayMedium?.copyWith(
                                  color: c.readable(LfTokens.teal),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${profile.xp} XP',
                              style: context.text.titleLarge,
                            ),
                            Text(
                              maxed
                                  ? 'Pass complete'
                                  : '${nextTier!.xpRequired - profile.xp} XP to tier ${nextTier.tier}',
                              style: context.text.bodySmall?.copyWith(
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: LfTokens.s3),
                    LfBar(
                      value: profile.tierProgress,
                      color: LfTokens.teal,
                      height: 12,
                      segments: 6,
                    ),
                    if (profile.claimable.isNotEmpty) ...[
                      const SizedBox(height: LfTokens.s4),
                      LfButton(
                        label:
                            'Claim ${profile.claimable.length} reward${profile.claimable.length == 1 ? '' : 's'}',
                        icon: Icons.redeem_rounded,
                        expand: true,
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          for (final t in profile.claimable.toList()) {
                            await profile.claim(t);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: LfTokens.s5),
              const LfEyebrow('REWARD TRACK'),
              const SizedBox(height: LfTokens.s3),
              _TierTrack(profile: profile),
              const SizedBox(height: LfTokens.s5),
              const LfEyebrow('CAREER'),
              const SizedBox(height: LfTokens.s3),
              GridView.count(
                crossAxisCount: layout.isPhone ? 2 : (layout.isDesktop ? 6 : 3),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: LfTokens.s2,
                crossAxisSpacing: LfTokens.s2,
                childAspectRatio: layout.isPhone ? 1.9 : 1.6,
                children: [
                  StatTile(label: 'MATCHES', value: '${career.matches}'),
                  StatTile(
                    label: 'VICTORIES',
                    value: '${career.wins}',
                    color: LfTokens.warning,
                  ),
                  StatTile(
                    label: 'ELIMINATIONS',
                    value: '${career.kills}',
                    color: LfTokens.ember,
                  ),
                  StatTile(label: 'DAMAGE', value: '${career.damage}'),
                  StatTile(
                    label: 'HARVESTED',
                    value: '${career.harvested}',
                    color: LfTokens.wood,
                  ),
                  StatTile(
                    label: 'BEST PLACE',
                    value: career.bestPlacement == 0
                        ? '—'
                        : '#${career.bestPlacement}',
                    color: LfTokens.teal,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TierTrack extends StatelessWidget {
  const _TierTrack({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: passTiers.length,
        separatorBuilder: (_, _) => const SizedBox(width: LfTokens.s2),
        itemBuilder: (context, i) {
          final t = passTiers[i];
          final reward = cosmeticById(t.rewardId);
          final reached = profile.xp >= t.xpRequired;
          final claimed = profile.claimedTiers.contains(t.tier);
          final claimable = reached && !claimed;
          final rar = LfTokens.rarity(reward.rarity);
          return Semantics(
            label:
                'Tier ${t.tier}: ${reward.name}, ${claimed
                    ? 'claimed'
                    : claimable
                    ? 'ready to claim'
                    : 'locked'}',
            button: claimable,
            child: GestureDetector(
              onTap: claimable
                  ? () {
                      HapticFeedback.mediumImpact();
                      profile.claim(t);
                    }
                  : null,
              child: AnimatedContainer(
                duration: LfTokens.base,
                width: 132,
                padding: const EdgeInsets.all(LfTokens.s3),
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(LfTokens.rMd),
                  border: Border.all(
                    color: claimable
                        ? LfTokens.teal
                        : (claimed ? rar.withValues(alpha: 0.6) : c.line),
                    width: claimable ? 2 : 1,
                  ),
                  boxShadow: claimable
                      ? [
                          BoxShadow(
                            color: LfTokens.teal.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TIER ${t.tier}',
                          style: context.text.labelSmall?.copyWith(
                            color: reached
                                ? c.readable(LfTokens.teal)
                                : c.muted,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          claimed
                              ? Icons.check_circle_rounded
                              : (claimable
                                    ? Icons.redeem_rounded
                                    : Icons.lock_rounded),
                          size: 16,
                          color: claimed
                              ? LfTokens.health
                              : (claimable ? LfTokens.teal : c.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: LfTokens.s2),
                    Expanded(
                      child: Center(
                        child: Opacity(
                          opacity: reached ? 1 : 0.45,
                          child: reward.slot == CosmeticSlot.outfit
                              ? OutfitAvatar(reward, size: 56)
                              : CosmeticGlyph(reward, size: 56),
                        ),
                      ),
                    ),
                    Text(
                      reward.name,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${t.xpRequired} XP',
                      style: context.text.labelSmall?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
