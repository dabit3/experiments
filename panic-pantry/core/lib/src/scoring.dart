/// Scoring rules. Integers only so every platform agrees bit-for-bit.
class Scoring {
  static const int basePoints = 20;
  static const int expiredPenalty = 10;
  static const int maxCombo = 4;

  /// Tip tier for an order served with [fraction] of its time remaining.
  static int tipTier(double fraction) {
    if (fraction >= 0.6) return 8;
    if (fraction >= 0.3) return 5;
    return 3;
  }

  static int serveValue({required double fraction, required int combo}) => basePoints + tipTier(fraction) * combo;
}
