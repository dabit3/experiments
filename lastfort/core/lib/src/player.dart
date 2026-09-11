import 'constants.dart';
import 'cosmetics.dart';
import 'items.dart';

/// Per-match statistics that end up on the results screen and in career XP.
class PlayerStats {
  int kills = 0;
  int damage = 0;
  int harvested = 0;
  int built = 0;
  int chests = 0;
  int shotsFired = 0;
  int shotsHit = 0;
  int survivedTicks = 0;
  int placement = 0;
  int xp = 0;

  Map<String, Object?> toJson() => {
        'kills': kills,
        'damage': damage,
        'harvested': harvested,
        'built': built,
        'chests': chests,
        'shotsFired': shotsFired,
        'shotsHit': shotsHit,
        'survivedTicks': survivedTicks,
        'placement': placement,
        'xp': xp,
      };

  static PlayerStats fromJson(Map<String, Object?> j) {
    final s = PlayerStats();
    s.kills = (j['kills'] as num? ?? 0).toInt();
    s.damage = (j['damage'] as num? ?? 0).toInt();
    s.harvested = (j['harvested'] as num? ?? 0).toInt();
    s.built = (j['built'] as num? ?? 0).toInt();
    s.chests = (j['chests'] as num? ?? 0).toInt();
    s.shotsFired = (j['shotsFired'] as num? ?? 0).toInt();
    s.shotsHit = (j['shotsHit'] as num? ?? 0).toInt();
    s.survivedTicks = (j['survivedTicks'] as num? ?? 0).toInt();
    s.placement = (j['placement'] as num? ?? 0).toInt();
    s.xp = (j['xp'] as num? ?? 0).toInt();
    return s;
  }

  void copyFrom(PlayerStats o) {
    kills = o.kills;
    damage = o.damage;
    harvested = o.harvested;
    built = o.built;
    chests = o.chests;
    shotsFired = o.shotsFired;
    shotsHit = o.shotsHit;
    survivedTicks = o.survivedTicks;
    placement = o.placement;
    xp = o.xp;
  }
}

class Player {
  Player({
    required this.id,
    required this.name,
    required this.team,
    required this.isBot,
    required this.loadout,
    this.platform = 'server',
  });

  final int id;
  final String name;
  final int team;
  final bool isBot;
  final String platform;
  Loadout loadout;

  PlayerState state = PlayerState.inBus;
  double x = 0;
  double y = 0;
  double aim = 0;
  double moveX = 0;
  double moveY = 0;
  bool sprint = false;
  bool fireHeld = false;

  /// 1 at the bus, 0 on the ground.
  double altitude = 1;

  int health = 100;
  int shield = 0;
  final List<int> materials = [0, 0, 0];

  /// Slot 0 is the pickaxe and is always null here; 1..5 hold items.
  final List<Item?> inventory = List<Item?>.filled(6, null);
  final Map<AmmoType, int> ammo = {for (final a in AmmoType.values) a: 0};
  int selectedSlot = 0;

  bool buildMode = false;
  Piece buildPiece = Piece.wall;
  Material buildMaterial = Material.wood;

  double fireCooldown = 0;
  double reloadRemaining = 0;
  double useRemaining = 0;
  int usingSlot = -1;
  double emoteRemaining = 0;
  bool thankedDriver = false;

  int lastDamageFrom = 0;
  int lastDamageTick = -100000;
  double stormAccumulator = 0;
  bool inStorm = false;
  bool elevated = false;
  bool sheltered = false;

  int eliminatedBy = 0;
  String eliminatedWith = '';
  int spectating = 0;

  int lastInputSeq = 0;
  int lastSeenTick = 0;
  bool connected = true;
  int disconnectedAtTick = -1;
  final PlayerStats stats = PlayerStats();

  int _maxHealth = 100;

  int get maxHealth => _maxHealth;
  set maxHealth(int v) {
    _maxHealth = v;
    health = v;
  }

  bool get alive => state == PlayerState.alive;
  bool get onGround => state == PlayerState.alive;
  bool get eliminated => state == PlayerState.eliminated;
  bool get busy => reloadRemaining > 0 || useRemaining > 0;

  Item? get selectedItem => selectedSlot == 0 ? null : inventory[selectedSlot];

  /// Attribute kill credit for a short window after the last hit.
  bool recentlyDamagedBy(int tick, int window) =>
      lastDamageFrom != 0 && tick - lastDamageTick <= window;

  /// Mirrors a snapshot produced by [toSnapshotJson] into this replica.
  /// Movement fields are skipped when [keepPosition] is set so client
  /// prediction can reconcile them separately.
  void applySnapshotJson(Map<String, Object?> j, {bool keepPosition = false}) {
    state = PlayerState.values.byName(j['s'] as String);
    if (!keepPosition) {
      x = (j['x'] as num).toDouble();
      y = (j['y'] as num).toDouble();
      aim = (j['a'] as num).toDouble();
    }
    altitude = (j['alt'] as num).toDouble();
    health = (j['hp'] as num).toInt();
    shield = (j['sh'] as num).toInt();
    selectedSlot = (j['slot'] as num).toInt();
    buildMode = j['bm'] as bool;
    moving = j['mv'] as bool;
    firing = j['fire'] as bool;
    loadout = Loadout.fromJson(j['ld'] as Map<String, Object?>?);
    stats.kills = (j['k'] as num).toInt();
    emoting = j['em'] as bool;
    reloading = j['rl'] as bool;
    using = j['us'] as bool;
    connected = j['con'] as bool;
    final mats = j['mats'];
    if (mats is List<Object?>) {
      for (var i = 0; i < 3 && i < mats.length; i++) {
        materials[i] = (mats[i] as num).toInt();
      }
      final inv = j['inv'] as List<Object?>;
      for (var i = 0; i < inventory.length && i < inv.length; i++) {
        final it = inv[i];
        inventory[i] =
            it == null ? null : Item.fromJson(it as Map<String, Object?>);
      }
      final am = j['ammo'] as Map<String, Object?>;
      for (final a in AmmoType.values) {
        ammo[a] = (am[a.name] as num? ?? 0).toInt();
      }
      buildPiece = Piece.values.byName(j['bp'] as String);
      buildMaterial = Material.values.byName(j['bmat'] as String);
      lastInputSeq = (j['seq'] as num).toInt();
      spectating = (j['spec'] as num).toInt();
      fireCooldown = (j['cd'] as num).toDouble();
      reloadRemaining = (j['rlt'] as num).toDouble();
      useRemaining = (j['ust'] as num).toDouble();
      final st = j['st'];
      if (st is Map<String, Object?>) stats.copyFrom(PlayerStats.fromJson(st));
    }
  }

  /// Presentation flags mirrored from snapshots (replicas only).
  bool moving = false;
  bool firing = false;
  bool emoting = false;
  bool reloading = false;
  bool using = false;

  Map<String, Object?> toSnapshotJson({required bool full}) => {
        'id': id,
        'n': name,
        't': team,
        'b': isBot,
        'p': platform,
        's': state.name,
        'x': double.parse(x.toStringAsFixed(2)),
        'y': double.parse(y.toStringAsFixed(2)),
        'a': double.parse(aim.toStringAsFixed(3)),
        'alt': double.parse(altitude.toStringAsFixed(3)),
        'hp': health,
        'sh': shield,
        'slot': selectedSlot,
        'bm': buildMode,
        'mv': moveX != 0 || moveY != 0,
        'fire': fireHeld && fireCooldown > 0.0,
        'ld': loadout.toJson(),
        'k': stats.kills,
        'em': emoteRemaining > 0,
        'rl': reloadRemaining > 0,
        'us': useRemaining > 0,
        'con': connected,
        if (full) ...{
          'mats': materials,
          'inv': [for (final i in inventory) i?.toJson()],
          'ammo': {for (final e in ammo.entries) e.key.name: e.value},
          'bp': buildPiece.name,
          'bmat': buildMaterial.name,
          'seq': lastInputSeq,
          'spec': spectating,
          'cd': double.parse(fireCooldown.toStringAsFixed(3)),
          'rlt': double.parse(reloadRemaining.toStringAsFixed(2)),
          'ust': double.parse(useRemaining.toStringAsFixed(2)),
          'st': stats.toJson(),
        },
      };
}
