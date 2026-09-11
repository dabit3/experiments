import 'items.dart';

enum TileType {
  floor,
  wall,
  pit,
  counter,
  crate,
  board,
  stove,
  sink,
  rack,
  plateReturn,
  pass,
  trash,
  conveyor,
  platform;

  bool get walkable => this == floor || this == platform;

  /// Whether items can be placed on this tile.
  bool get holdsItems => switch (this) {
    TileType.counter ||
    TileType.board ||
    TileType.stove ||
    TileType.rack ||
    TileType.plateReturn ||
    TileType.conveyor ||
    TileType.sink ||
    TileType.floor ||
    TileType.platform => true,
    _ => false,
  };
}

/// Cardinal direction, also used for chef facing.
enum Dir {
  up(0, -1),
  right(1, 0),
  down(0, 1),
  left(-1, 0);

  const Dir(this.dx, this.dy);

  final int dx;
  final int dy;

  static Dir fromVector(double x, double y) {
    if (x.abs() >= y.abs()) return x >= 0 ? Dir.right : Dir.left;
    return y >= 0 ? Dir.down : Dir.up;
  }
}

/// One kitchen cell. Mutable: the simulation edits tiles in place.
class Tile {
  Tile(this.type, {this.crate, this.conveyorDir});

  final TileType type;

  /// Ingredient dispensed by a [TileType.crate].
  final Ingredient? crate;

  /// Direction items travel on a [TileType.conveyor].
  final Dir? conveyorDir;

  Item? item;

  /// Cutting progress (board) or washing progress (sink), 0..1.
  double progress = 0;

  /// Conveyor transport progress 0..1.
  double conveyor = 0;

  /// Fire intensity 0..1; 0 means no fire.
  double fire = 0;

  /// Seconds until the fire tries to spread.
  double spreadTimer = 0;

  bool get onFire => fire > 0;

  Map<String, dynamic> toJson() => {
    if (item != null) 'i': item!.toJson(),
    if (progress != 0) 'p': (progress * 1000).round() / 1000,
    if (conveyor != 0) 'c': (conveyor * 1000).round() / 1000,
    if (fire != 0) 'f': (fire * 1000).round() / 1000,
  };

  void applyJson(Map<String, dynamic> json) {
    item = json['i'] == null ? null : Item.fromJson(json['i'] as Map<String, dynamic>);
    progress = ((json['p'] ?? 0) as num).toDouble();
    conveyor = ((json['c'] ?? 0) as num).toDouble();
    fire = ((json['f'] ?? 0) as num).toDouble();
  }
}
