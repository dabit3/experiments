import 'rng.dart';

/// Brick Tycoon: place bricks on a 6x6 plot; every brick earns pips per second.
class BrickType {
  const BrickType(
    this.id,
    this.name,
    this.cost,
    this.income,
    this.color,
    this.blurb,
  );

  final String id;
  final String name;
  final int cost;

  /// Base income per second.
  final int income;
  final int color;
  final String blurb;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'cost': cost,
    'income': income,
    'color': color,
    'blurb': blurb,
  };
}

class TycoonUpgrade {
  const TycoonUpgrade(
    this.id,
    this.name,
    this.cost,
    this.multiplier,
    this.blurb,
  );

  final String id;
  final String name;
  final int cost;

  /// Multiplier applied to plot income (stacks multiplicatively).
  final double multiplier;
  final String blurb;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'cost': cost,
    'multiplier': multiplier,
    'blurb': blurb,
  };
}

const List<BrickType> brickTypes = [
  BrickType('dropper', 'Dropper', 20, 2, 0xFF3E7BFA, 'Drops 2 pips a second.'),
  BrickType(
    'conveyor',
    'Conveyor',
    50,
    4,
    0xFF9AA3AF,
    'Earns 4, plus 1 for each adjacent dropper.',
  ),
  BrickType(
    'vault',
    'Vault',
    150,
    12,
    0xFFF5C04A,
    'A sturdy 12 pips a second.',
  ),
  BrickType(
    'fountain',
    'Pip Fountain',
    400,
    40,
    0xFF35B8D6,
    'Gushes 40 pips a second.',
  ),
];

const List<TycoonUpgrade> tycoonUpgrades = [
  TycoonUpgrade('boost1', 'Oiled Gears', 100, 1.5, 'Plot income x1.5.'),
  TycoonUpgrade('boost2', 'Golden Mortar', 350, 2.0, 'Plot income x2.'),
  TycoonUpgrade('boost3', 'Sky Crane', 900, 3.0, 'Plot income x3.'),
];

final Map<String, BrickType> brickTypeById = {
  for (final b in brickTypes) b.id: b,
};
final Map<String, TycoonUpgrade> tycoonUpgradeById = {
  for (final u in tycoonUpgrades) u.id: u,
};

class TycoonPlot {
  TycoonPlot({
    List<String?>? cells,
    Set<String>? upgrades,
    this.cash = startingCash,
    this.earned = 0,
    this.bricksPlaced = 0,
  }) : cells = cells ?? List<String?>.filled(size * size, null),
       upgrades = upgrades ?? <String>{};

  static const size = 6;
  static const startingCash = 100;

  final List<String?> cells;
  final Set<String> upgrades;

  /// Spendable pips inside the tycoon (match-local).
  int cash;

  /// Total pips earned this session; used as the score.
  int earned;
  int bricksPlaced;

  int get brickCount => cells.where((c) => c != null).length;

  double get multiplier => upgrades.fold(
    1.0,
    (m, id) => m * (tycoonUpgradeById[id]?.multiplier ?? 1.0),
  );

  /// Income per second including adjacency bonuses and upgrades.
  int incomePerSecond() {
    var base = 0;
    for (var i = 0; i < cells.length; i++) {
      final id = cells[i];
      if (id == null) continue;
      final type = brickTypeById[id];
      if (type == null) continue;
      base += type.income;
      if (id == 'conveyor') {
        base += _neighbours(i).where((n) => cells[n] == 'dropper').length;
      }
    }
    return (base * multiplier).floor();
  }

  Iterable<int> _neighbours(int i) sync* {
    final x = i % size;
    final y = i ~/ size;
    if (x > 0) yield i - 1;
    if (x < size - 1) yield i + 1;
    if (y > 0) yield i - size;
    if (y < size - 1) yield i + size;
  }

  /// Applies one second of income.
  void collect() {
    final income = incomePerSecond();
    cash += income;
    earned += income;
  }

  TycoonError? place(int cell, String brickId) {
    if (cell < 0 || cell >= cells.length) return TycoonError.badCell;
    if (cells[cell] != null) return TycoonError.occupied;
    final type = brickTypeById[brickId];
    if (type == null) return TycoonError.unknownItem;
    if (cash < type.cost) return TycoonError.notEnoughCash;
    cash -= type.cost;
    cells[cell] = brickId;
    bricksPlaced += 1;
    return null;
  }

  TycoonError? remove(int cell) {
    if (cell < 0 || cell >= cells.length) return TycoonError.badCell;
    final id = cells[cell];
    if (id == null) return TycoonError.empty;
    cells[cell] = null;
    cash += (brickTypeById[id]!.cost / 2).floor();
    return null;
  }

  TycoonError? buyUpgrade(String id) {
    final upgrade = tycoonUpgradeById[id];
    if (upgrade == null) return TycoonError.unknownItem;
    if (upgrades.contains(id)) return TycoonError.alreadyOwned;
    if (cash < upgrade.cost) return TycoonError.notEnoughCash;
    cash -= upgrade.cost;
    upgrades.add(id);
    return null;
  }

  Map<String, Object?> toJson() => {
    'cells': cells,
    'upgrades': upgrades.toList()..sort(),
    'cash': cash,
    'earned': earned,
    'bricksPlaced': bricksPlaced,
  };

  static TycoonPlot fromJson(Map<String, Object?> json) => TycoonPlot(
    cells: ((json['cells'] as List?) ?? List.filled(size * size, null))
        .map((c) => c as String?)
        .toList(),
    upgrades: ((json['upgrades'] as List?) ?? const []).cast<String>().toSet(),
    cash: (json['cash'] as num?)?.toInt() ?? startingCash,
    earned: (json['earned'] as num?)?.toInt() ?? 0,
    bricksPlaced: (json['bricksPlaced'] as num?)?.toInt() ?? 0,
  );
}

enum TycoonError {
  badCell,
  occupied,
  empty,
  unknownItem,
  notEnoughCash,
  alreadyOwned,
}

class TycoonAction {
  const TycoonAction.place(this.cell, this.item) : kind = 'place';
  const TycoonAction.remove(this.cell) : kind = 'remove', item = null;
  const TycoonAction.upgrade(this.item) : kind = 'upgrade', cell = -1;

  final String kind;
  final int cell;
  final String? item;

  Map<String, Object?> toJson() => {'a': kind, 'cell': cell, 'item': item};

  static TycoonAction? fromJson(Map<String, Object?> json) {
    final cell = (json['cell'] as num?)?.toInt() ?? -1;
    final item = json['item'] as String?;
    switch (json['a']) {
      case 'place':
        return item == null ? null : TycoonAction.place(cell, item);
      case 'remove':
        return TycoonAction.remove(cell);
      case 'upgrade':
        return item == null ? null : TycoonAction.upgrade(item);
    }
    return null;
  }

  TycoonError? apply(TycoonPlot plot) {
    switch (kind) {
      case 'place':
        return plot.place(cell, item!);
      case 'remove':
        return plot.remove(cell);
      case 'upgrade':
        return plot.buyUpgrade(item!);
    }
    return TycoonError.unknownItem;
  }
}

/// Deterministic tycoon bot: fills the plot in a fixed order with the best
/// brick it can afford, buying upgrades when they pay back within the match.
class TycoonAutopilot {
  TycoonAutopilot(int seed) : _rng = SeededRng(seed);

  final SeededRng _rng;

  TycoonAction? decide(TycoonPlot plot, int secondsLeft) {
    for (final upgrade in tycoonUpgrades) {
      if (!plot.upgrades.contains(upgrade.id) &&
          plot.cash >= upgrade.cost &&
          plot.incomePerSecond() * (upgrade.multiplier - 1) * secondsLeft >
              upgrade.cost) {
        return TycoonAction.upgrade(upgrade.id);
      }
    }
    final free = <int>[];
    for (var i = 0; i < plot.cells.length; i++) {
      if (plot.cells[i] == null) free.add(i);
    }
    if (free.isEmpty) return null;
    BrickType? best;
    for (final b in brickTypes) {
      if (plot.cash >= b.cost && (best == null || b.income > best.income)) {
        best = b;
      }
    }
    if (best == null) return null;
    final cell = free[_rng.nextInt(free.length.clamp(1, 3))];
    return TycoonAction.place(cell, best.id);
  }
}
