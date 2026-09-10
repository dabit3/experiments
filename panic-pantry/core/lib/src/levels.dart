import 'items.dart';
import 'tiles.dart';

/// A block of tiles that slides along one axis on a fixed schedule.
///
/// Its cells are laid over the base grid (which must be [TileType.pit] wherever
/// the block can travel). Chefs standing on it are carried along.
class MoverDef {
  const MoverDef({
    required this.id,
    required this.x,
    required this.y,
    required this.rows,
    required this.axis,
    required this.range,
    required this.travelSeconds,
    required this.dwellSeconds,
    this.phaseSeconds = 0,
  });

  final String id;
  final int x;
  final int y;
  final List<String> rows;

  /// 'x' or 'y'.
  final String axis;

  /// Cells travelled from the base position (may be negative).
  final int range;
  final double travelSeconds;
  final double dwellSeconds;
  final double phaseSeconds;

  int get width => rows.first.length;
  int get height => rows.length;

  double get cycle => 2 * (travelSeconds + dwellSeconds);

  /// Continuous offset in cells at simulation time [t].
  double offsetAt(double t) {
    final u = (t + phaseSeconds) % cycle;
    if (u < dwellSeconds) return 0;
    if (u < dwellSeconds + travelSeconds) return range * (u - dwellSeconds) / travelSeconds;
    if (u < 2 * dwellSeconds + travelSeconds) return range.toDouble();
    return range * (1 - (u - 2 * dwellSeconds - travelSeconds) / travelSeconds);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'rows': rows,
    'axis': axis,
    'range': range,
    'travel': travelSeconds,
    'dwell': dwellSeconds,
    'phase': phaseSeconds,
  };
}

class LevelDef {
  const LevelDef({
    required this.id,
    required this.name,
    required this.tagline,
    required this.gimmick,
    required this.rows,
    required this.menu,
    required this.roundSeconds,
    required this.starThresholds,
    this.movers = const [],
    this.orderIntervalSeconds = 14,
    this.orderDurationSeconds = 55,
    this.startingPlates = 3,
    this.tutorial = false,
    this.accent = 0xFFE8593C,
  });

  final String id;
  final String name;
  final String tagline;
  final String gimmick;
  final List<String> rows;
  final List<Dish> menu;
  final int roundSeconds;

  /// Single-player coin thresholds for 1, 2 and 3 stars. Scaled by player count.
  final List<int> starThresholds;
  final List<MoverDef> movers;
  final double orderIntervalSeconds;
  final double orderDurationSeconds;
  final int startingPlates;
  final bool tutorial;

  /// ARGB accent colour used for the level card and kitchen floor.
  final int accent;

  int get width => rows.first.length;
  int get height => rows.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'gimmick': gimmick,
    'rows': rows,
    'menu': menu.map((d) => d.name).toList(),
    'roundSeconds': roundSeconds,
    'starThresholds': starThresholds,
    'movers': movers.map((m) => m.toJson()).toList(),
    'orderInterval': orderIntervalSeconds,
    'orderDuration': orderDurationSeconds,
    'startingPlates': startingPlates,
    'tutorial': tutorial,
    'accent': accent,
  };

  /// Star thresholds for [players] chefs. More chefs must earn more coins.
  List<int> thresholdsFor(int players) {
    const factors = [100, 140, 170, 200];
    final f = factors[(players.clamp(1, 4)) - 1];
    return starThresholds.map((t) => (t * f) ~/ 100).toList();
  }

  static int starsFor(int score, List<int> thresholds) {
    var stars = 0;
    for (final t in thresholds) {
      if (score >= t) stars++;
    }
    return stars;
  }
}

/// Legend:
/// `.` floor, `#` wall, `~` pit (mover track), `C` counter, `B` cutting board,
/// `S` stove with pot, `K` sink, `R` clean plate rack, `D` dirty plate return,
/// `P` pass, `X` trash, `E` counter holding an extinguisher,
/// `T`/`O`/`M`/`L` crates (tomato/onion/mushroom/lettuce),
/// `>` `<` `^` `v` conveyors, `1`-`4` spawn floor tiles.
const List<LevelDef> kLevels = [
  LevelDef(
    id: 'training',
    name: 'Training Kitchen',
    tagline: 'Learn the ropes',
    gimmick: 'A calm kitchen with one recipe and step-by-step guidance.',
    tutorial: true,
    accent: 0xFF4C9BE8,
    rows: ['CTTCBBCPP', 'C.......C', 'K.1...2.C', 'R.......D', 'C.3...4.X', 'CSSECCCCC'],
    menu: [Dish.tomatoSoup],
    roundSeconds: 180,
    orderIntervalSeconds: 30,
    orderDurationSeconds: 90,
    starThresholds: [20, 60, 120],
  ),
  LevelDef(
    id: 'corner-cafe',
    name: 'Corner Café',
    tagline: 'Three soups, one room',
    gimmick: 'Everything is within reach. Find your rhythm before the kitchen turns on you.',
    accent: 0xFFE8593C,
    rows: [
      'CTTBBCCOOCCPP',
      'C...........C',
      'K.1.......2.C',
      'R...CBCBC...C',
      'D.3.......4.X',
      'C...........C',
      'CSSECCCMMCCCC',
    ],
    menu: [Dish.tomatoSoup, Dish.onionSoup, Dish.mushroomSoup],
    roundSeconds: 150,
    starThresholds: [120, 240, 380],
  ),
  LevelDef(
    id: 'conveyor-canteen',
    name: 'Conveyor Canteen',
    tagline: 'Split by belts',
    gimmick: 'A wall divides prep from cooking. Belts carry chopped food right and dirty plates left.',
    accent: 0xFF2FA37A,
    rows: [
      'CTTOO>>>CCCPP',
      'C.....#.....C',
      'K.1...#...2.C',
      'R.....#.....D',
      'C.3...#...4.X',
      'C.....#.....C',
      'CMBBC<<<CSSEC',
    ],
    menu: [Dish.tomatoSoup, Dish.onionSoup, Dish.mushroomSoup],
    roundSeconds: 150,
    starThresholds: [100, 220, 360],
  ),
  LevelDef(
    id: 'split-shift',
    name: 'Split Shift',
    tagline: 'The kitchen drifts apart',
    gimmick: 'The cooking half slides away every few seconds. Hand things over while the doorway lines up.',
    accent: 0xFF9B5DE5,
    rows: [
      'CTTLOC~~~~~~~',
      'C....C~~~~~~~',
      'K.1...~~~~~~~',
      'R....C~~~~~~~',
      'D.3..C~~~~~~~',
      'C....C~~~~~~~',
      'CBBCCC~~~~~~~',
      '######~~~~~~~',
      '######~~~~~~~',
    ],
    movers: [
      MoverDef(
        id: 'east-wing',
        x: 6,
        y: 0,
        rows: ['CCCCCPP', '..2...C', '......C', 'C.....C', 'C.4...X', 'C.....C', 'CSSECCC'],
        axis: 'y',
        range: 2,
        travelSeconds: 2,
        dwellSeconds: 9,
      ),
    ],
    menu: [Dish.tomatoSoup, Dish.onionSoup, Dish.gardenSalad],
    roundSeconds: 160,
    starThresholds: [90, 200, 330],
  ),
  LevelDef(
    id: 'drift-deck',
    name: 'Drift Deck',
    tagline: 'Ride the ferries',
    gimmick: 'Prep is north, stoves and plates are south. Two ferries shuttle chopped food across the river.',
    accent: 0xFF1FA8C9,
    rows: [
      'CTTBBCOOCMMBC',
      'C.1.......2.C',
      'C...........C',
      '~~~~~~~~~~~~~',
      '~~~~~~~~~~~~~',
      '~~~~~~~~~~~~~',
      'D...........X',
      'R.3.......4.K',
      'CSSECCPPCCSSC',
    ],
    movers: [
      MoverDef(
        id: 'ferry-west',
        x: 2,
        y: 3,
        rows: ['...', '...'],
        axis: 'y',
        range: 1,
        travelSeconds: 1.5,
        dwellSeconds: 4,
      ),
      MoverDef(
        id: 'ferry-east',
        x: 8,
        y: 3,
        rows: ['...', '...'],
        axis: 'y',
        range: 1,
        travelSeconds: 1.5,
        dwellSeconds: 4,
        phaseSeconds: 5.5,
      ),
    ],
    menu: [Dish.tomatoSoup, Dish.onionSoup, Dish.mushroomSoup],
    roundSeconds: 160,
    starThresholds: [90, 200, 330],
  ),
];

LevelDef levelById(String id) => kLevels.firstWhere((l) => l.id == id, orElse: () => kLevels[1]);

/// Levels shown on the world map (everything except the tutorial).
List<LevelDef> get kCampaignLevels => kLevels.where((l) => !l.tutorial).toList();

Tile tileFromChar(String c) => switch (c) {
  '.' || '1' || '2' || '3' || '4' => Tile(TileType.floor),
  '#' => Tile(TileType.wall),
  '~' => Tile(TileType.pit),
  'C' || 'E' => Tile(TileType.counter),
  'B' => Tile(TileType.board),
  'S' => Tile(TileType.stove),
  'K' => Tile(TileType.sink),
  'R' => Tile(TileType.rack),
  'D' => Tile(TileType.plateReturn),
  'P' => Tile(TileType.pass),
  'X' => Tile(TileType.trash),
  'T' => Tile(TileType.crate, crate: Ingredient.tomato),
  'O' => Tile(TileType.crate, crate: Ingredient.onion),
  'M' => Tile(TileType.crate, crate: Ingredient.mushroom),
  'L' => Tile(TileType.crate, crate: Ingredient.lettuce),
  '>' => Tile(TileType.conveyor, conveyorDir: Dir.right),
  '<' => Tile(TileType.conveyor, conveyorDir: Dir.left),
  '^' => Tile(TileType.conveyor, conveyorDir: Dir.up),
  'v' => Tile(TileType.conveyor, conveyorDir: Dir.down),
  _ => throw ArgumentError('unknown tile char $c'),
};
