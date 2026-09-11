/// Tunable rules for a Lastfort match. All distances are world units
/// (roughly metres), all durations are seconds, all rates are per second.
class Rules {
  const Rules({
    this.tickRate = 20,
    this.mapSize = 1000,
    this.tileSize = 4,
    this.islandRadius = 440,
    this.maxPlayers = 16,
    this.moveSpeed = 7,
    this.sprintMultiplier = 1.4,
    this.dropSpeed = 15,
    this.glideSpeed = 11,
    this.playerRadius = 0.6,
    this.maxHealth = 100,
    this.maxShield = 100,
    this.materialCap = 500,
    this.pieceCost = 10,
    this.harvestRange = 3.2,
    this.interactRange = 2.6,
    this.buildRange = 2,
    this.interestRadius = 90,
    this.busDuration = 24,
    this.dropDuration = 4,
    this.stormPhases = defaultStormPhases,
    this.reconnectGrace = 60,
    this.busJumpGraceTicks = 40,
  });

  /// Rules for the automated cross-platform test and the bots-only smoke
  /// match: identical mechanics, shorter timers.
  const Rules.fast()
      : this(
          busDuration: 5,
          dropDuration: 2,
          stormPhases: fastStormPhases,
        );

  final int tickRate;
  final double mapSize;
  final double tileSize;
  final double islandRadius;
  final int maxPlayers;
  final double moveSpeed;
  final double sprintMultiplier;
  final double dropSpeed;
  final double glideSpeed;
  final double playerRadius;
  final int maxHealth;
  final int maxShield;
  final int materialCap;
  final int pieceCost;
  final double harvestRange;
  final double interactRange;
  final double buildRange;
  final double interestRadius;
  final double busDuration;
  final double dropDuration;
  final List<StormPhase> stormPhases;
  final double reconnectGrace;
  final int busJumpGraceTicks;

  double get dt => 1 / tickRate;
  int get tilesPerSide => (mapSize / tileSize).round();

  Map<String, Object?> toJson() => {
        'tickRate': tickRate,
        'mapSize': mapSize,
        'tileSize': tileSize,
        'islandRadius': islandRadius,
        'maxPlayers': maxPlayers,
        'moveSpeed': moveSpeed,
        'sprintMultiplier': sprintMultiplier,
        'dropSpeed': dropSpeed,
        'glideSpeed': glideSpeed,
        'playerRadius': playerRadius,
        'maxHealth': maxHealth,
        'maxShield': maxShield,
        'materialCap': materialCap,
        'pieceCost': pieceCost,
        'harvestRange': harvestRange,
        'interactRange': interactRange,
        'buildRange': buildRange,
        'interestRadius': interestRadius,
        'busDuration': busDuration,
        'dropDuration': dropDuration,
        'stormPhases': [for (final p in stormPhases) p.toJson()],
        'reconnectGrace': reconnectGrace,
        'busJumpGraceTicks': busJumpGraceTicks,
      };

  static Rules fromJson(Map<String, Object?> j) => Rules(
        tickRate: (j['tickRate'] as num).toInt(),
        mapSize: (j['mapSize'] as num).toDouble(),
        tileSize: (j['tileSize'] as num).toDouble(),
        islandRadius: (j['islandRadius'] as num).toDouble(),
        maxPlayers: (j['maxPlayers'] as num).toInt(),
        moveSpeed: (j['moveSpeed'] as num).toDouble(),
        sprintMultiplier: (j['sprintMultiplier'] as num).toDouble(),
        dropSpeed: (j['dropSpeed'] as num).toDouble(),
        glideSpeed: (j['glideSpeed'] as num).toDouble(),
        playerRadius: (j['playerRadius'] as num).toDouble(),
        maxHealth: (j['maxHealth'] as num).toInt(),
        maxShield: (j['maxShield'] as num).toInt(),
        materialCap: (j['materialCap'] as num).toInt(),
        pieceCost: (j['pieceCost'] as num).toInt(),
        harvestRange: (j['harvestRange'] as num).toDouble(),
        interactRange: (j['interactRange'] as num).toDouble(),
        buildRange: (j['buildRange'] as num).toDouble(),
        interestRadius: (j['interestRadius'] as num).toDouble(),
        busDuration: (j['busDuration'] as num).toDouble(),
        dropDuration: (j['dropDuration'] as num).toDouble(),
        stormPhases: [
          for (final p in j['stormPhases'] as List<Object?>)
            StormPhase.fromJson(p as Map<String, Object?>)
        ],
        reconnectGrace: (j['reconnectGrace'] as num).toDouble(),
        busJumpGraceTicks: (j['busJumpGraceTicks'] as num).toInt(),
      );
}

/// One storm phase: the storm waits, then shrinks to [radius] over
/// [shrink] seconds while dealing [dps] damage to anyone outside the eye.
class StormPhase {
  const StormPhase(this.wait, this.shrink, this.radius, this.dps);

  final double wait;
  final double shrink;
  final double radius;
  final double dps;

  Map<String, Object?> toJson() =>
      {'wait': wait, 'shrink': shrink, 'radius': radius, 'dps': dps};

  static StormPhase fromJson(Map<String, Object?> j) => StormPhase(
        (j['wait'] as num).toDouble(),
        (j['shrink'] as num).toDouble(),
        (j['radius'] as num).toDouble(),
        (j['dps'] as num).toDouble(),
      );
}

/// Publicly documented shape: long early waits, accelerating damage
/// (1 → 2 → 5 → 8 → 10 per second), the eye closing to nothing at the end.
const defaultStormPhases = <StormPhase>[
  StormPhase(30, 0, 560, 0),
  StormPhase(35, 30, 340, 1),
  StormPhase(25, 25, 230, 1),
  StormPhase(20, 20, 150, 2),
  StormPhase(15, 20, 90, 5),
  StormPhase(10, 15, 50, 8),
  StormPhase(8, 12, 20, 10),
  StormPhase(5, 15, 0, 10),
];

const fastStormPhases = <StormPhase>[
  StormPhase(20, 0, 560, 0),
  StormPhase(15, 12, 340, 1),
  StormPhase(10, 10, 230, 1),
  StormPhase(8, 8, 150, 2),
  StormPhase(6, 6, 90, 5),
  StormPhase(5, 5, 50, 8),
  StormPhase(4, 4, 20, 10),
  StormPhase(3, 3, 0, 10),
];

enum Material {
  wood,
  stone,
  metal;

  /// Structure hit points once fully built.
  int get maxHp => switch (this) {
        Material.wood => 150,
        Material.stone => 300,
        Material.metal => 500,
      };

  /// Seconds for a piece to reach full hit points.
  double get buildTime => switch (this) {
        Material.wood => 3,
        Material.stone => 5,
        Material.metal => 8,
      };

  String get label => switch (this) {
        Material.wood => 'Wood',
        Material.stone => 'Stone',
        Material.metal => 'Metal',
      };
}

enum Piece {
  wall,
  floor,
  ramp,
  roof;

  String get label => switch (this) {
        Piece.wall => 'Wall',
        Piece.floor => 'Floor',
        Piece.ramp => 'Ramp',
        Piece.roof => 'Roof',
      };
}

/// Edits available for a placed piece. `none` is the unedited shape.
enum PieceEdit { none, door, window }

enum MatchPhase { lobby, bus, playing, ended }

enum PlayerState { inBus, dropping, alive, eliminated }

enum SquadMode {
  solo(1, 'Solo'),
  duos(2, 'Duos'),
  squads(4, 'Squads');

  const SquadMode(this.size, this.label);
  final int size;
  final String label;

  static SquadMode parse(String s) =>
      SquadMode.values.firstWhere((m) => m.name == s, orElse: () => squads);
}

enum ResourceKind {
  tree(Material.wood, 90, 10, 1.4),
  rock(Material.stone, 120, 8, 1.6),
  car(Material.metal, 110, 8, 2.2);

  const ResourceKind(this.material, this.hp, this.yield, this.radius);
  final Material material;
  final int hp;
  final int yield;
  final double radius;
}

const pickaxeDamage = 30;
const pickaxeCooldown = 0.55;
const stormWarningSeconds = 10;
const eliminationFeedTtl = 6.0;
