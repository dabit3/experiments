/// Block and item registry. Ids below 100 are blocks (placeable in the
/// world); ids from 100 are items that only live in inventories.
class Ids {
  static const air = 0;
  static const stone = 1;
  static const dirt = 2;
  static const grass = 3;
  static const sand = 4;
  static const water = 5;
  static const log = 6;
  static const leaves = 7;
  static const planks = 8;
  static const cobble = 9;
  static const coalOre = 10;
  static const ironOre = 11;
  static const goldOre = 12;
  static const emberOre = 13;
  static const bedrock = 14;
  static const torch = 15;
  static const workbench = 16;
  static const kiln = 17;
  static const chest = 18;
  static const bed = 19;
  static const glass = 20;
  static const gravel = 21;
  static const snow = 22;
  static const flower = 23;
  static const tallGrass = 24;
  static const brick = 25;
  static const stoneBrick = 26;
  static const lantern = 27;
  static const cactus = 28;
  static const wool = 29;
  static const mossStone = 30;
  static const frostLog = 31;
  static const frostLeaves = 32;
  static const clay = 33;
  static const lastBlock = 33;

  static const stick = 101;
  static const coal = 102;
  static const ironIngot = 103;
  static const goldIngot = 104;
  static const emberGem = 105;
  static const rawIron = 106;
  static const rawGold = 107;
  static const woodPick = 110;
  static const stonePick = 111;
  static const ironPick = 112;
  static const woodAxe = 113;
  static const stoneAxe = 114;
  static const ironAxe = 115;
  static const woodShovel = 116;
  static const stoneShovel = 117;
  static const ironShovel = 118;
  static const woodSword = 119;
  static const stoneSword = 120;
  static const ironSword = 121;
  static const emberPick = 122;
  static const emberSword = 123;
  static const apple = 130;
  static const rawChop = 131;
  static const cookedChop = 132;
  static const mossberry = 133;
  static const heartyStew = 134;
  static const brickItem = 135;
  static const ballOfClay = 136;
  static const woolTuft = 137;
}

enum ToolClass { none, pick, axe, shovel, sword }

enum ToolTier { none, wood, stone, iron, ember }

class BlockDef {
  const BlockDef({
    required this.id,
    required this.name,
    this.hardness = 1.0,
    this.tool = ToolClass.none,
    this.minTier = ToolTier.none,
    this.solid = true,
    this.opaque = true,
    this.light = 0,
    this.drop,
    this.dropCount = 1,
    this.replaceable = false,
    this.interactive = false,
    this.fluid = false,
    this.decoration = false,
  });

  final int id;
  final String name;

  /// Seconds to break by hand. Negative = unbreakable.
  final double hardness;
  final ToolClass tool;
  final ToolTier minTier;
  final bool solid;
  final bool opaque;
  final int light;
  final int? drop;
  final int dropCount;
  final bool replaceable;
  final bool interactive;
  final bool fluid;
  final bool decoration;

  int get dropId => drop ?? id;
}

class ItemDef {
  const ItemDef({
    required this.id,
    required this.name,
    this.maxStack = 64,
    this.tool = ToolClass.none,
    this.tier = ToolTier.none,
    this.food = 0,
    this.attack = 1,
    this.fuelTicks = 0,
  });

  final int id;
  final String name;
  final int maxStack;
  final ToolClass tool;
  final ToolTier tier;
  final int food;
  final int attack;
  final int fuelTicks;

  bool get isBlock => id <= Ids.lastBlock && id != Ids.air;
  bool get isTool => tool != ToolClass.none;
}

class Registry {
  static const blocks = <int, BlockDef>{
    Ids.air: BlockDef(id: 0, name: 'Air', solid: false, opaque: false, replaceable: true),
    Ids.stone: BlockDef(
      id: 1,
      name: 'Stone',
      hardness: 7.5,
      tool: ToolClass.pick,
      minTier: ToolTier.wood,
      drop: Ids.cobble,
    ),
    Ids.dirt: BlockDef(id: 2, name: 'Dirt', hardness: 0.75, tool: ToolClass.shovel),
    Ids.grass: BlockDef(id: 3, name: 'Grass Block', hardness: 0.9, tool: ToolClass.shovel, drop: Ids.dirt),
    Ids.sand: BlockDef(id: 4, name: 'Sand', hardness: 0.75, tool: ToolClass.shovel),
    Ids.water: BlockDef(
      id: 5,
      name: 'Water',
      hardness: -1,
      solid: false,
      opaque: false,
      replaceable: true,
      fluid: true,
    ),
    Ids.log: BlockDef(id: 6, name: 'Oakheart Log', hardness: 3.0, tool: ToolClass.axe),
    Ids.leaves: BlockDef(id: 7, name: 'Oakheart Leaves', hardness: 0.3, opaque: false, drop: Ids.apple, dropCount: 0),
    Ids.planks: BlockDef(id: 8, name: 'Planks', hardness: 3.0, tool: ToolClass.axe),
    Ids.cobble: BlockDef(id: 9, name: 'Cobblestone', hardness: 10.0, tool: ToolClass.pick, minTier: ToolTier.wood),
    Ids.coalOre: BlockDef(
      id: 10,
      name: 'Coal Ore',
      hardness: 15.0,
      tool: ToolClass.pick,
      minTier: ToolTier.wood,
      drop: Ids.coal,
    ),
    Ids.ironOre: BlockDef(
      id: 11,
      name: 'Iron Ore',
      hardness: 15.0,
      tool: ToolClass.pick,
      minTier: ToolTier.stone,
      drop: Ids.rawIron,
    ),
    Ids.goldOre: BlockDef(
      id: 12,
      name: 'Gold Ore',
      hardness: 15.0,
      tool: ToolClass.pick,
      minTier: ToolTier.iron,
      drop: Ids.rawGold,
    ),
    Ids.emberOre: BlockDef(
      id: 13,
      name: 'Ember Ore',
      hardness: 15.0,
      tool: ToolClass.pick,
      minTier: ToolTier.iron,
      drop: Ids.emberGem,
    ),
    Ids.bedrock: BlockDef(id: 14, name: 'Deepstone', hardness: -1),
    Ids.torch: BlockDef(
      id: 15,
      name: 'Torch',
      hardness: 0.05,
      solid: false,
      opaque: false,
      light: 14,
      decoration: true,
    ),
    Ids.workbench: BlockDef(id: 16, name: 'Workbench', hardness: 3.75, tool: ToolClass.axe, interactive: true),
    Ids.kiln: BlockDef(
      id: 17,
      name: 'Kiln',
      hardness: 17.5,
      tool: ToolClass.pick,
      minTier: ToolTier.wood,
      interactive: true,
    ),
    Ids.chest: BlockDef(id: 18, name: 'Chest', hardness: 3.75, tool: ToolClass.axe, interactive: true),
    Ids.bed: BlockDef(id: 19, name: 'Bed', hardness: 0.3, interactive: true, opaque: false),
    Ids.glass: BlockDef(id: 20, name: 'Glass', hardness: 0.45, opaque: false, dropCount: 0),
    Ids.gravel: BlockDef(id: 21, name: 'Gravel', hardness: 0.9, tool: ToolClass.shovel),
    Ids.snow: BlockDef(id: 22, name: 'Snow', hardness: 0.3, tool: ToolClass.shovel),
    Ids.flower: BlockDef(id: 23, name: 'Emberbloom', hardness: 0.0, solid: false, opaque: false, decoration: true),
    Ids.tallGrass: BlockDef(
      id: 24,
      name: 'Tall Grass',
      hardness: 0.0,
      solid: false,
      opaque: false,
      decoration: true,
      drop: Ids.mossberry,
      dropCount: 0,
      replaceable: true,
    ),
    Ids.brick: BlockDef(id: 25, name: 'Bricks', hardness: 10.0, tool: ToolClass.pick, minTier: ToolTier.wood),
    Ids.stoneBrick: BlockDef(id: 26, name: 'Stone Bricks', hardness: 7.5, tool: ToolClass.pick, minTier: ToolTier.wood),
    Ids.lantern: BlockDef(
      id: 27,
      name: 'Lantern',
      hardness: 5.0,
      tool: ToolClass.pick,
      opaque: false,
      light: 15,
      decoration: true,
    ),
    Ids.cactus: BlockDef(id: 28, name: 'Cactus', hardness: 0.6, opaque: false),
    Ids.wool: BlockDef(id: 29, name: 'Wool', hardness: 1.2),
    Ids.mossStone: BlockDef(id: 30, name: 'Mossy Stone', hardness: 10.0, tool: ToolClass.pick, minTier: ToolTier.wood),
    Ids.frostLog: BlockDef(id: 31, name: 'Frostpine Log', hardness: 3.0, tool: ToolClass.axe),
    Ids.frostLeaves: BlockDef(id: 32, name: 'Frostpine Needles', hardness: 0.3, opaque: false, dropCount: 0),
    Ids.clay: BlockDef(id: 33, name: 'Clay', hardness: 0.9, tool: ToolClass.shovel, drop: Ids.ballOfClay, dropCount: 4),
  };

  static const items = <int, ItemDef>{
    Ids.stick: ItemDef(id: Ids.stick, name: 'Stick', fuelTicks: 100),
    Ids.coal: ItemDef(id: Ids.coal, name: 'Coal', fuelTicks: 1600),
    Ids.ironIngot: ItemDef(id: Ids.ironIngot, name: 'Iron Ingot'),
    Ids.goldIngot: ItemDef(id: Ids.goldIngot, name: 'Gold Ingot'),
    Ids.emberGem: ItemDef(id: Ids.emberGem, name: 'Ember Gem'),
    Ids.rawIron: ItemDef(id: Ids.rawIron, name: 'Raw Iron'),
    Ids.rawGold: ItemDef(id: Ids.rawGold, name: 'Raw Gold'),
    Ids.woodPick: ItemDef(
      id: Ids.woodPick,
      name: 'Wooden Pick',
      maxStack: 1,
      tool: ToolClass.pick,
      tier: ToolTier.wood,
      attack: 2,
      fuelTicks: 200,
    ),
    Ids.stonePick: ItemDef(
      id: Ids.stonePick,
      name: 'Stone Pick',
      maxStack: 1,
      tool: ToolClass.pick,
      tier: ToolTier.stone,
      attack: 3,
    ),
    Ids.ironPick: ItemDef(
      id: Ids.ironPick,
      name: 'Iron Pick',
      maxStack: 1,
      tool: ToolClass.pick,
      tier: ToolTier.iron,
      attack: 4,
    ),
    Ids.emberPick: ItemDef(
      id: Ids.emberPick,
      name: 'Ember Pick',
      maxStack: 1,
      tool: ToolClass.pick,
      tier: ToolTier.ember,
      attack: 5,
    ),
    Ids.woodAxe: ItemDef(
      id: Ids.woodAxe,
      name: 'Wooden Axe',
      maxStack: 1,
      tool: ToolClass.axe,
      tier: ToolTier.wood,
      attack: 3,
      fuelTicks: 200,
    ),
    Ids.stoneAxe: ItemDef(
      id: Ids.stoneAxe,
      name: 'Stone Axe',
      maxStack: 1,
      tool: ToolClass.axe,
      tier: ToolTier.stone,
      attack: 4,
    ),
    Ids.ironAxe: ItemDef(
      id: Ids.ironAxe,
      name: 'Iron Axe',
      maxStack: 1,
      tool: ToolClass.axe,
      tier: ToolTier.iron,
      attack: 5,
    ),
    Ids.woodShovel: ItemDef(
      id: Ids.woodShovel,
      name: 'Wooden Shovel',
      maxStack: 1,
      tool: ToolClass.shovel,
      tier: ToolTier.wood,
      attack: 2,
      fuelTicks: 200,
    ),
    Ids.stoneShovel: ItemDef(
      id: Ids.stoneShovel,
      name: 'Stone Shovel',
      maxStack: 1,
      tool: ToolClass.shovel,
      tier: ToolTier.stone,
      attack: 2,
    ),
    Ids.ironShovel: ItemDef(
      id: Ids.ironShovel,
      name: 'Iron Shovel',
      maxStack: 1,
      tool: ToolClass.shovel,
      tier: ToolTier.iron,
      attack: 3,
    ),
    Ids.woodSword: ItemDef(
      id: Ids.woodSword,
      name: 'Wooden Sword',
      maxStack: 1,
      tool: ToolClass.sword,
      tier: ToolTier.wood,
      attack: 4,
      fuelTicks: 200,
    ),
    Ids.stoneSword: ItemDef(
      id: Ids.stoneSword,
      name: 'Stone Sword',
      maxStack: 1,
      tool: ToolClass.sword,
      tier: ToolTier.stone,
      attack: 5,
    ),
    Ids.ironSword: ItemDef(
      id: Ids.ironSword,
      name: 'Iron Sword',
      maxStack: 1,
      tool: ToolClass.sword,
      tier: ToolTier.iron,
      attack: 6,
    ),
    Ids.emberSword: ItemDef(
      id: Ids.emberSword,
      name: 'Ember Sword',
      maxStack: 1,
      tool: ToolClass.sword,
      tier: ToolTier.ember,
      attack: 8,
    ),
    Ids.apple: ItemDef(id: Ids.apple, name: 'Apple', food: 4),
    Ids.rawChop: ItemDef(id: Ids.rawChop, name: 'Raw Chop', food: 3),
    Ids.cookedChop: ItemDef(id: Ids.cookedChop, name: 'Cooked Chop', food: 8),
    Ids.mossberry: ItemDef(id: Ids.mossberry, name: 'Mossberry', food: 2),
    Ids.heartyStew: ItemDef(id: Ids.heartyStew, name: 'Hearty Stew', maxStack: 16, food: 10),
    Ids.brickItem: ItemDef(id: Ids.brickItem, name: 'Brick'),
    Ids.ballOfClay: ItemDef(id: Ids.ballOfClay, name: 'Ball of Clay'),
    Ids.woolTuft: ItemDef(id: Ids.woolTuft, name: 'Wool Tuft'),
  };

  static BlockDef block(int id) => blocks[id] ?? blocks[Ids.air]!;

  static ItemDef item(int id) {
    final it = items[id];
    if (it != null) return it;
    final b = blocks[id];
    if (b != null) {
      return ItemDef(
        id: id,
        name: b.name,
        fuelTicks: (id == Ids.planks || id == Ids.log || id == Ids.frostLog || id == Ids.workbench || id == Ids.chest)
            ? 300
            : 0,
      );
    }
    return const ItemDef(id: 0, name: 'Unknown');
  }

  static bool isBlock(int id) => id > 0 && id <= Ids.lastBlock;

  static String nameOf(int id) => item(id).name;

  static bool isOre(int id) => id == Ids.coalOre || id == Ids.ironOre || id == Ids.goldOre || id == Ids.emberOre;

  /// Items offered by the creative palette, in display order.
  static const creativePalette = <int>[
    Ids.grass,
    Ids.dirt,
    Ids.stone,
    Ids.cobble,
    Ids.mossStone,
    Ids.stoneBrick,
    Ids.brick,
    Ids.sand,
    Ids.gravel,
    Ids.clay,
    Ids.snow,
    Ids.log,
    Ids.frostLog,
    Ids.planks,
    Ids.leaves,
    Ids.frostLeaves,
    Ids.glass,
    Ids.wool,
    Ids.torch,
    Ids.lantern,
    Ids.workbench,
    Ids.kiln,
    Ids.chest,
    Ids.bed,
    Ids.flower,
    Ids.tallGrass,
    Ids.cactus,
    Ids.coalOre,
    Ids.ironOre,
    Ids.goldOre,
    Ids.emberOre,
    Ids.water,
    Ids.bedrock,
    Ids.stick,
    Ids.coal,
    Ids.ironIngot,
    Ids.goldIngot,
    Ids.emberGem,
    Ids.rawIron,
    Ids.rawGold,
    Ids.woodPick,
    Ids.stonePick,
    Ids.ironPick,
    Ids.emberPick,
    Ids.woodAxe,
    Ids.stoneAxe,
    Ids.ironAxe,
    Ids.woodShovel,
    Ids.stoneShovel,
    Ids.ironShovel,
    Ids.woodSword,
    Ids.stoneSword,
    Ids.ironSword,
    Ids.emberSword,
    Ids.apple,
    Ids.rawChop,
    Ids.cookedChop,
    Ids.mossberry,
    Ids.heartyStew,
    Ids.brickItem,
    Ids.ballOfClay,
    Ids.woolTuft,
  ];

  static double tierMultiplier(ToolTier t) => switch (t) {
    ToolTier.none => 1,
    ToolTier.wood => 2,
    ToolTier.stone => 4,
    ToolTier.iron => 6,
    ToolTier.ember => 9,
  };

  /// Seconds needed to break [blockId] while holding [heldItem] (0 = empty hand).
  /// Returns -1 for unbreakable blocks and `double.infinity` when the tool tier
  /// is too low to harvest the block at all (the block still breaks, but drops
  /// nothing - callers use [canHarvest]).
  static double breakSeconds(int blockId, int heldItem) {
    final b = block(blockId);
    if (b.hardness < 0) return -1;
    if (b.hardness == 0) return 0.05;
    final tool = item(heldItem);
    if (b.tool == ToolClass.none || tool.tool != b.tool) return b.hardness;
    final speed = tierMultiplier(tool.tier);
    // Hand-time for tier-gated blocks already includes the "wrong tool"
    // penalty; a capable tool removes it (x0.3) on top of its speed.
    final base = b.minTier != ToolTier.none && canHarvest(blockId, heldItem) ? b.hardness * 0.3 : b.hardness;
    return base / speed;
  }

  static bool canHarvest(int blockId, int heldItem) {
    final b = block(blockId);
    if (b.minTier == ToolTier.none) return true;
    final tool = item(heldItem);
    if (tool.tool != b.tool) return false;
    return tool.tier.index >= b.minTier.index;
  }
}
