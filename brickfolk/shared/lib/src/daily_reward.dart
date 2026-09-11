/// Daily reward rules. All times are epoch milliseconds from the server clock.
abstract final class DailyReward {
  static const int dayMs = 24 * 60 * 60 * 1000;
  static const List<int> streakRewards = [25, 35, 50, 65, 80, 100, 150];

  /// Reward for the given 1-based streak day (capped at the last tier).
  static int rewardForStreak(int streak) {
    if (streak <= 0) return streakRewards.first;
    if (streak > streakRewards.length) return streakRewards.last;
    return streakRewards[streak - 1];
  }

  /// Whether a claim is available given the last claim time.
  static bool canClaim(int? lastClaimMs, int nowMs) =>
      lastClaimMs == null || nowMs - lastClaimMs >= dayMs;

  /// The streak after a successful claim at [nowMs].
  static int nextStreak(int? lastClaimMs, int currentStreak, int nowMs) {
    if (lastClaimMs == null) return 1;
    final elapsed = nowMs - lastClaimMs;
    if (elapsed < dayMs) return currentStreak;
    if (elapsed < 2 * dayMs) return currentStreak + 1;
    return 1;
  }
}
