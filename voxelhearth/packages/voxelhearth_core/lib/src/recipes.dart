import 'blocks.dart';
import 'items.dart';

/// A crafting recipe. Shaped recipes use a pattern of item ids (0 = empty)
/// in a width x height grid; the pattern may be placed anywhere inside the
/// crafting grid (2x2 or 3x3). Shapeless recipes match a multiset.
class Recipe {
  const Recipe.shaped({
    required this.result,
    required this.width,
    required this.height,
    required this.pattern,
    this.name,
  }) : shapeless = null;

  const Recipe.shapeless({required this.result, required List<int> items, this.name})
    : shapeless = items,
      width = 0,
      height = 0,
      pattern = const [];

  final ItemStack result;
  final int width;
  final int height;
  final List<int> pattern;
  final List<int>? shapeless;
  final String? name;

  bool get isShapeless => shapeless != null;

  /// Number of grid cells this recipe needs on the smallest square grid.
  int get gridNeeded => isShapeless ? (shapeless!.length <= 4 ? 2 : 3) : (width > 2 || height > 2 ? 3 : 2);
}

class Recipes {
  static const _p = Ids.planks, _s = Ids.stick, _c = Ids.cobble, _i = Ids.ironIngot;
  static const _e = Ids.emberGem;

  static const all = <Recipe>[
    Recipe.shapeless(result: ItemStack(Ids.planks, 4), items: [Ids.log], name: 'Planks'),
    Recipe.shapeless(result: ItemStack(Ids.planks, 4), items: [Ids.frostLog], name: 'Planks (frostpine)'),
    Recipe.shaped(result: ItemStack(Ids.stick, 4), width: 1, height: 2, pattern: [_p, _p], name: 'Sticks'),
    Recipe.shaped(
      result: ItemStack(Ids.workbench, 1),
      width: 2,
      height: 2,
      pattern: [_p, _p, _p, _p],
      name: 'Workbench',
    ),
    Recipe.shaped(result: ItemStack(Ids.torch, 4), width: 1, height: 2, pattern: [Ids.coal, _s], name: 'Torches'),
    Recipe.shaped(
      result: ItemStack(Ids.chest, 1),
      width: 3,
      height: 3,
      pattern: [_p, _p, _p, _p, 0, _p, _p, _p, _p],
      name: 'Chest',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.kiln, 1),
      width: 3,
      height: 3,
      pattern: [_c, _c, _c, _c, 0, _c, _c, _c, _c],
      name: 'Kiln',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.bed, 1),
      width: 3,
      height: 2,
      pattern: [Ids.wool, Ids.wool, Ids.wool, _p, _p, _p],
      name: 'Bed',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.wool, 1),
      width: 2,
      height: 2,
      pattern: [Ids.woolTuft, Ids.woolTuft, Ids.woolTuft, Ids.woolTuft],
      name: 'Wool',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.stoneBrick, 4),
      width: 2,
      height: 2,
      pattern: [Ids.stone, Ids.stone, Ids.stone, Ids.stone],
      name: 'Stone Bricks',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.brick, 1),
      width: 2,
      height: 2,
      pattern: [Ids.brickItem, Ids.brickItem, Ids.brickItem, Ids.brickItem],
      name: 'Bricks',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.lantern, 1),
      width: 3,
      height: 3,
      pattern: [_i, _i, _i, _i, Ids.torch, _i, _i, _i, _i],
      name: 'Lantern',
    ),
    Recipe.shapeless(result: ItemStack(Ids.mossStone, 1), items: [Ids.cobble, Ids.tallGrass], name: 'Mossy Stone'),
    Recipe.shapeless(
      result: ItemStack(Ids.heartyStew, 1),
      items: [Ids.cookedChop, Ids.mossberry, Ids.apple],
      name: 'Hearty Stew',
    ),
    // Picks
    Recipe.shaped(
      result: ItemStack(Ids.woodPick, 1),
      width: 3,
      height: 3,
      pattern: [_p, _p, _p, 0, _s, 0, 0, _s, 0],
      name: 'Wooden Pick',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.stonePick, 1),
      width: 3,
      height: 3,
      pattern: [_c, _c, _c, 0, _s, 0, 0, _s, 0],
      name: 'Stone Pick',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.ironPick, 1),
      width: 3,
      height: 3,
      pattern: [_i, _i, _i, 0, _s, 0, 0, _s, 0],
      name: 'Iron Pick',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.emberPick, 1),
      width: 3,
      height: 3,
      pattern: [_e, _e, _e, 0, _s, 0, 0, _s, 0],
      name: 'Ember Pick',
    ),
    // Axes
    Recipe.shaped(
      result: ItemStack(Ids.woodAxe, 1),
      width: 2,
      height: 3,
      pattern: [_p, _p, _p, _s, 0, _s],
      name: 'Wooden Axe',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.stoneAxe, 1),
      width: 2,
      height: 3,
      pattern: [_c, _c, _c, _s, 0, _s],
      name: 'Stone Axe',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.ironAxe, 1),
      width: 2,
      height: 3,
      pattern: [_i, _i, _i, _s, 0, _s],
      name: 'Iron Axe',
    ),
    // Shovels
    Recipe.shaped(
      result: ItemStack(Ids.woodShovel, 1),
      width: 1,
      height: 3,
      pattern: [_p, _s, _s],
      name: 'Wooden Shovel',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.stoneShovel, 1),
      width: 1,
      height: 3,
      pattern: [_c, _s, _s],
      name: 'Stone Shovel',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.ironShovel, 1),
      width: 1,
      height: 3,
      pattern: [_i, _s, _s],
      name: 'Iron Shovel',
    ),
    // Swords
    Recipe.shaped(
      result: ItemStack(Ids.woodSword, 1),
      width: 1,
      height: 3,
      pattern: [_p, _p, _s],
      name: 'Wooden Sword',
    ),
    Recipe.shaped(
      result: ItemStack(Ids.stoneSword, 1),
      width: 1,
      height: 3,
      pattern: [_c, _c, _s],
      name: 'Stone Sword',
    ),
    Recipe.shaped(result: ItemStack(Ids.ironSword, 1), width: 1, height: 3, pattern: [_i, _i, _s], name: 'Iron Sword'),
    Recipe.shaped(
      result: ItemStack(Ids.emberSword, 1),
      width: 1,
      height: 3,
      pattern: [_e, _e, _s],
      name: 'Ember Sword',
    ),
  ];

  /// Smelting: input id -> output stack.
  static const smelting = <int, ItemStack>{
    Ids.cobble: ItemStack(Ids.stone, 1),
    Ids.sand: ItemStack(Ids.glass, 1),
    Ids.rawIron: ItemStack(Ids.ironIngot, 1),
    Ids.rawGold: ItemStack(Ids.goldIngot, 1),
    Ids.rawChop: ItemStack(Ids.cookedChop, 1),
    Ids.log: ItemStack(Ids.coal, 1),
    Ids.frostLog: ItemStack(Ids.coal, 1),
    Ids.ballOfClay: ItemStack(Ids.brickItem, 1),
    Ids.emberOre: ItemStack(Ids.emberGem, 2),
  };

  static const smeltTicks = 200;

  /// Finds the recipe matching a square crafting [grid] of size n x n
  /// (n = 2 or 3), given as ids row-major (0 = empty). Returns null if none.
  static Recipe? match(List<int> grid, int n) {
    final nonEmpty = grid.where((g) => g != 0).toList()..sort();
    if (nonEmpty.isEmpty) return null;
    for (final r in all) {
      if (r.isShapeless) {
        final want = List<int>.of(r.shapeless!)..sort();
        if (_listEq(want, nonEmpty)) return r;
      } else {
        if (r.width > n || r.height > n) continue;
        for (var oy = 0; oy + r.height <= n; oy++) {
          for (var ox = 0; ox + r.width <= n; ox++) {
            if (_shapedMatches(r, grid, n, ox, oy)) return r;
          }
        }
      }
    }
    return null;
  }

  static bool _shapedMatches(Recipe r, List<int> grid, int n, int ox, int oy) {
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final g = grid[y * n + x];
        final px = x - ox, py = y - oy;
        var want = 0;
        if (px >= 0 && px < r.width && py >= 0 && py < r.height) {
          want = r.pattern[py * r.width + px];
        }
        if (g != want) return false;
      }
    }
    return true;
  }

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
