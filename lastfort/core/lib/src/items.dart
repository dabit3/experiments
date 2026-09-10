import 'constants.dart';

enum Rarity {
  common('Common', 0xFFB5B9C2),
  uncommon('Uncommon', 0xFF5FD068),
  rare('Rare', 0xFF3FA2FF),
  epic('Epic', 0xFFB86BFF),
  legendary('Legendary', 0xFFFFB13D);

  const Rarity(this.label, this.argb);
  final String label;
  final int argb;

  /// Damage multiplier relative to the common tier.
  double get damageMultiplier => 1 + index * 0.06;

  static Rarity parse(String s) =>
      Rarity.values.firstWhere((r) => r.name == s, orElse: () => common);
}

enum AmmoType {
  light('Light'),
  medium('Medium'),
  heavy('Heavy'),
  shells('Shells');

  const AmmoType(this.label);
  final String label;

  static AmmoType parse(String s) =>
      AmmoType.values.firstWhere((a) => a.name == s, orElse: () => light);
}

enum WeaponKind {
  pistol,
  smg,
  rifle,
  shotgun,
  sniper;

  WeaponDef get def => weaponDefs[this]!;
}

/// Original weapon definitions for Lastfort. Names, stats and pellets are
/// Lastfort's own; only the archetypes follow the documented genre roles.
class WeaponDef {
  const WeaponDef({
    required this.kind,
    required this.name,
    required this.ammo,
    required this.damage,
    required this.structureDamage,
    required this.range,
    required this.fireInterval,
    required this.magazine,
    required this.reload,
    required this.spread,
    this.pellets = 1,
    this.minRarity = Rarity.common,
  });

  final WeaponKind kind;
  final String name;
  final AmmoType ammo;
  final int damage;
  final int structureDamage;
  final double range;
  final double fireInterval;
  final int magazine;
  final double reload;

  /// Half angle of the spread cone in radians.
  final double spread;
  final int pellets;
  final Rarity minRarity;

  int damageFor(Rarity r) => (damage * r.damageMultiplier).round();
}

const weaponDefs = <WeaponKind, WeaponDef>{
  WeaponKind.pistol: WeaponDef(
    kind: WeaponKind.pistol,
    name: 'Scrapper',
    ammo: AmmoType.light,
    damage: 24,
    structureDamage: 24,
    range: 42,
    fireInterval: 0.28,
    magazine: 12,
    reload: 1.4,
    spread: 0.035,
  ),
  WeaponKind.smg: WeaponDef(
    kind: WeaponKind.smg,
    name: 'Hornet',
    ammo: AmmoType.light,
    damage: 15,
    structureDamage: 14,
    range: 32,
    fireInterval: 0.085,
    magazine: 30,
    reload: 1.9,
    spread: 0.075,
  ),
  WeaponKind.rifle: WeaponDef(
    kind: WeaponKind.rifle,
    name: 'Ridgeline',
    ammo: AmmoType.medium,
    damage: 30,
    structureDamage: 30,
    range: 64,
    fireInterval: 0.17,
    magazine: 30,
    reload: 2.2,
    spread: 0.04,
  ),
  WeaponKind.shotgun: WeaponDef(
    kind: WeaponKind.shotgun,
    name: 'Boomstick',
    ammo: AmmoType.shells,
    damage: 11,
    structureDamage: 12,
    range: 15,
    fireInterval: 0.9,
    magazine: 5,
    reload: 3.6,
    spread: 0.16,
    pellets: 8,
  ),
  WeaponKind.sniper: WeaponDef(
    kind: WeaponKind.sniper,
    name: 'Longshot',
    ammo: AmmoType.heavy,
    damage: 96,
    structureDamage: 60,
    range: 130,
    fireInterval: 1.6,
    magazine: 1,
    reload: 2.9,
    spread: 0.0,
    minRarity: Rarity.rare,
  ),
};

enum ConsumableKind {
  bandage('Wrap', 3.0, 6, 15, 0, 75, 0),
  medkit('Medkit', 8.0, 1, 100, 0, 100, 0),
  smallShield('Fizz', 2.0, 6, 0, 25, 100, 50),
  bigShield('Big Fizz', 4.0, 2, 0, 50, 100, 100);

  const ConsumableKind(
    this.label,
    this.useTime,
    this.maxStack,
    this.heal,
    this.shield,
    this.healCap,
    this.shieldCap,
  );

  final String label;
  final double useTime;
  final int maxStack;
  final int heal;
  final int shield;

  /// Healing cannot raise health above this value (e.g. bandages cap at 75).
  final int healCap;

  /// Shield gain cannot raise shield above this value (small shields cap at 50).
  final int shieldCap;

  static ConsumableKind parse(String s) => ConsumableKind.values
      .firstWhere((c) => c.name == s, orElse: () => bandage);
}

enum ItemType { weapon, consumable, ammo, material }

/// An inventory item or a loot drop payload.
class Item {
  Item.weapon(this.weapon, this.rarity, {int? loaded})
      : type = ItemType.weapon,
        consumable = null,
        ammoType = null,
        material = null,
        count = 1,
        loaded = loaded ?? weapon!.def.magazine;

  Item.consumable(this.consumable, this.count)
      : type = ItemType.consumable,
        weapon = null,
        rarity = Rarity.common,
        ammoType = null,
        material = null,
        loaded = 0;

  Item.ammo(this.ammoType, this.count)
      : type = ItemType.ammo,
        weapon = null,
        rarity = Rarity.common,
        consumable = null,
        material = null,
        loaded = 0;

  Item.material(this.material, this.count)
      : type = ItemType.material,
        weapon = null,
        rarity = Rarity.common,
        consumable = null,
        ammoType = null,
        loaded = 0;

  Item._raw({
    required this.type,
    required this.weapon,
    required this.rarity,
    required this.consumable,
    required this.ammoType,
    required this.material,
    required this.count,
    required this.loaded,
  });

  final ItemType type;
  final WeaponKind? weapon;
  final Rarity rarity;
  final ConsumableKind? consumable;
  final AmmoType? ammoType;
  final Material? material;
  int count;
  int loaded;

  String get label => switch (type) {
        ItemType.weapon => weapon!.def.name,
        ItemType.consumable => consumable!.label,
        ItemType.ammo => '${ammoType!.label} Ammo',
        ItemType.material => material!.label,
      };

  bool get isWeapon => type == ItemType.weapon;
  bool get isConsumable => type == ItemType.consumable;

  Item copy() => Item._raw(
        type: type,
        weapon: weapon,
        rarity: rarity,
        consumable: consumable,
        ammoType: ammoType,
        material: material,
        count: count,
        loaded: loaded,
      );

  Map<String, Object?> toJson() => {
        't': type.name,
        if (weapon != null) 'w': weapon!.name,
        if (type == ItemType.weapon) 'r': rarity.name,
        if (consumable != null) 'c': consumable!.name,
        if (ammoType != null) 'a': ammoType!.name,
        if (material != null) 'm': material!.name,
        'n': count,
        if (type == ItemType.weapon) 'l': loaded,
      };

  static Item fromJson(Map<String, Object?> j) {
    final type = ItemType.values.firstWhere((t) => t.name == j['t']);
    return Item._raw(
      type: type,
      weapon: j['w'] == null
          ? null
          : WeaponKind.values.firstWhere((w) => w.name == j['w']),
      rarity: j['r'] == null ? Rarity.common : Rarity.parse(j['r'] as String),
      consumable:
          j['c'] == null ? null : ConsumableKind.parse(j['c'] as String),
      ammoType: j['a'] == null ? null : AmmoType.parse(j['a'] as String),
      material: j['m'] == null
          ? null
          : Material.values.firstWhere((m) => m.name == j['m']),
      count: (j['n'] as num?)?.toInt() ?? 1,
      loaded: (j['l'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Loot tables. Floor loot favours common/uncommon; chests favour rare and up
/// and never roll common weapons, following the documented convention.
class LootTable {
  static const floorRarityWeights = <double>[42, 34, 18, 5, 1];
  static const chestRarityWeights = <double>[0, 30, 40, 22, 8];
  static const weaponWeights = <double>[26, 24, 26, 20, 4];

  static const ammoPerPickup = <AmmoType, int>{
    AmmoType.light: 24,
    AmmoType.medium: 20,
    AmmoType.heavy: 4,
    AmmoType.shells: 6,
  };
}

int maxStackFor(Item item) => switch (item.type) {
      ItemType.weapon => 1,
      ItemType.consumable => item.consumable!.maxStack,
      ItemType.ammo => 999,
      ItemType.material => 999,
    };
