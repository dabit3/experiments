/// Item set. Each item is original to Nitro Tots; the role each one plays is
/// documented in the README's design notes.
enum ItemKind {
  /// Short speed boost.
  turbo,

  /// Three turbo charges.
  tripleTurbo,

  /// Homing projectile that chases the racer directly ahead.
  rocket,

  /// Straight projectile that bounces off walls.
  orb,

  /// Dropped puddle that spins out whoever drives through it.
  slick,

  /// Bubble that absorbs one hit.
  shield,

  /// Zaps every other racer: brief spin and slowdown.
  zap,

  /// Auto-pilot comet: fast, invincible, follows the racing line.
  comet,
}

extension ItemKindInfo on ItemKind {
  String get label => switch (this) {
        ItemKind.turbo => 'Turbo Can',
        ItemKind.tripleTurbo => 'Triple Turbo',
        ItemKind.rocket => 'Homing Rocket',
        ItemKind.orb => 'Bouncy Orb',
        ItemKind.slick => 'Syrup Slick',
        ItemKind.shield => 'Bubble Shield',
        ItemKind.zap => 'Thunder Zap',
        ItemKind.comet => 'Comet Ride',
      };

  String get description => switch (this) {
        ItemKind.turbo => 'A quick burst of speed.',
        ItemKind.tripleTurbo => 'Three bursts of speed. Use them wisely.',
        ItemKind.rocket => 'Chases the racer ahead and spins them out.',
        ItemKind.orb => 'Flies straight and bounces off walls.',
        ItemKind.slick => 'Drop it behind you; anyone who hits it spins.',
        ItemKind.shield => 'Blocks one incoming hit for eight seconds.',
        ItemKind.zap => 'Everyone else spins and shrinks for a moment.',
        ItemKind.comet => 'Ride a comet down the racing line at full tilt.',
      };

  String get wire => name;

  static ItemKind? fromWire(String? s) {
    if (s == null) return null;
    for (final k in ItemKind.values) {
      if (k.name == s) return k;
    }
    return null;
  }
}

/// Position-based item odds (weights) for an 8-racer field. Index 0 is first
/// place. Leaders get defensive items; trailing racers get catch-up items.
const itemOdds = <List<int>>[
  // turbo, triple, rocket, orb, slick, shield, zap, comet
  [0, 0, 0, 30, 40, 30, 0, 0], // 1st
  [20, 0, 25, 30, 10, 15, 0, 0], // 2nd
  [20, 0, 30, 30, 10, 10, 0, 0], // 3rd
  [30, 15, 30, 10, 0, 10, 5, 0], // 4th
  [30, 15, 30, 10, 0, 10, 5, 0], // 5th
  [20, 30, 20, 0, 0, 0, 15, 15], // 6th
  [20, 30, 20, 0, 0, 0, 15, 15], // 7th
  [0, 25, 15, 0, 0, 0, 25, 35], // 8th
];

/// Battle mode odds are position independent but skewed to offensive items.
const battleOdds = <int>[15, 5, 30, 30, 10, 10, 0, 0];

List<int> oddsForPosition(int position, int fieldSize, {bool battle = false}) {
  if (battle) return battleOdds;
  if (fieldSize <= 1) return itemOdds[0];
  // Map position within field onto the 8-row table.
  final row = ((position - 1) * 7 / (fieldSize - 1)).round().clamp(0, 7);
  return itemOdds[row];
}
