import 'dart:async';

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

Future<void> showDailyRewardSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    constraints: const BoxConstraints(maxWidth: 520),
    isScrollControlled: true,
    builder: (_) => const _DailyRewardSheet(),
  );
}

class _DailyRewardSheet extends StatefulWidget {
  const _DailyRewardSheet();

  @override
  State<_DailyRewardSheet> createState() => _DailyRewardSheetState();
}

class _DailyRewardSheetState extends State<_DailyRewardSheet> {
  StreamSubscription<DailyResult>? _sub;
  DailyResult? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sub = AppScope.read(context).client.dailyResults.listen((r) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = r;
      });
      if (r.claimed && AppScope.read(context).hapticsEnabled) {
        HapticFeedback.mediumImpact();
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
    final client = ClientScope.of(context);
    final me = client.me!;
    final p = context.palette;
    final now = client.serverNow();
    final canClaim =
        _result == null && DailyReward.canClaim(me.lastDailyClaim, now);
    final streak =
        _result?.streak ??
        DailyReward.nextStreak(me.lastDailyClaim, me.dailyStreak, now);
    final todayIndex = ((canClaim ? streak : me.dailyStreak) - 1).clamp(
      0,
      DailyReward.streakRewards.length - 1,
    );
    final nextAt =
        _result?.nextClaimAt ?? ((me.lastDailyClaim ?? 0) + DailyReward.dayMs);
    final remaining = Duration(
      milliseconds: (nextAt - now).clamp(0, DailyReward.dayMs),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: BrickColors.sun.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: BrickColors.sun,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily reward', style: context.text.headlineSmall),
                      Text(
                        'Come back every day to grow your streak.',
                        style: context.text.bodySmall?.copyWith(
                          color: p.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            LayoutBuilder(
              builder: (context, c) {
                final cell = ((c.maxWidth - Space.sm * 6) / 7).clamp(
                  36.0,
                  64.0,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < DailyReward.streakRewards.length; i++)
                      _DayCell(
                        day: i + 1,
                        reward: DailyReward.streakRewards[i],
                        size: cell,
                        state:
                            i < todayIndex ||
                                (!canClaim &&
                                    i == todayIndex &&
                                    _result == null &&
                                    me.dailyStreak > 0)
                            ? _DayState.done
                            : (i == todayIndex &&
                                  (canClaim || _result?.claimed == true))
                            ? (_result?.claimed == true
                                  ? _DayState.done
                                  : _DayState.today)
                            : _DayState.future,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: Space.xl),
            AnimatedSwitcher(
              duration: Motion.normal,
              child: _result?.claimed == true
                  ? Panel(
                      key: const ValueKey('claimed'),
                      color: BrickColors.mint.withValues(alpha: 0.12),
                      borderColor: BrickColors.mint.withValues(alpha: 0.4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: BrickColors.mint,
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Text(
                              'You claimed ${_result!.reward} Pips. Streak: ${_result!.streak} day${_result!.streak == 1 ? '' : 's'}.'
                              '${_result!.badges.isNotEmpty ? ' New badge unlocked!' : ''}',
                              style: context.text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('claim'),
                      height: 52,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canClaim && !_busy
                            ? () {
                                setState(() => _busy = true);
                                client.claimDaily();
                              }
                            : null,
                        icon: const PipIcon(size: 18),
                        label: Text(
                          canClaim
                              ? 'Claim ${DailyReward.rewardForStreak(streak)} Pips'
                              : 'Next reward in ${_fmt(remaining)}',
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

enum _DayState { done, today, future }

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.reward,
    required this.size,
    required this.state,
  });

  final int day;
  final int reward;
  final double size;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (state) {
      _DayState.done => BrickColors.mint,
      _DayState.today => BrickColors.sun,
      _DayState.future => p.surface2,
    };
    return AnimatedContainer(
      duration: Motion.normal,
      width: size,
      height: size * 1.35,
      decoration: BoxDecoration(
        color: state == _DayState.future
            ? p.surface2
            : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: state == _DayState.today
              ? BrickColors.sun
              : (state == _DayState.done
                    ? BrickColors.mint.withValues(alpha: 0.5)
                    : p.outline),
          width: state == _DayState.today ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'D$day',
            style: context.text.labelSmall?.copyWith(color: p.textTertiary),
          ),
          const SizedBox(height: Space.xs),
          state == _DayState.done
              ? const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: BrickColors.mint,
                )
              : PipIcon(size: size * 0.32),
          const SizedBox(height: Space.xxs),
          Text('$reward', style: context.text.labelMedium),
        ],
      ),
    );
  }
}
