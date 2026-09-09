/// Ingredients that can be picked from crates.
enum Ingredient {
  tomato,
  onion,
  mushroom,
  lettuce;

  static Ingredient parse(String s) => Ingredient.values.byName(s);
}

/// Dishes that customers order.
enum Dish {
  tomatoSoup('Tomato Soup', [Ingredient.tomato, Ingredient.tomato, Ingredient.tomato], true),
  onionSoup('Onion Soup', [Ingredient.onion, Ingredient.onion, Ingredient.onion], true),
  mushroomSoup('Mushroom Soup', [Ingredient.mushroom, Ingredient.mushroom, Ingredient.mushroom], true),
  gardenSalad('Garden Salad', [Ingredient.lettuce, Ingredient.tomato], false);

  const Dish(this.label, this.ingredients, this.cooked);

  final String label;
  final List<Ingredient> ingredients;

  /// Whether the ingredients must be cooked in a pot before plating.
  final bool cooked;

  static Dish parse(String s) => Dish.values.byName(s);

  /// The dish represented by [contents] (order-insensitive), or null.
  static Dish? match(List<Ingredient> contents, {required bool cooked}) {
    if (contents.isEmpty) return null;
    final sorted = [...contents]..sort((a, b) => a.index.compareTo(b.index));
    for (final dish in Dish.values) {
      if (dish.cooked != cooked) continue;
      final want = [...dish.ingredients]..sort((a, b) => a.index.compareTo(b.index));
      if (want.length != sorted.length) continue;
      var same = true;
      for (var i = 0; i < want.length; i++) {
        if (want[i] != sorted[i]) {
          same = false;
          break;
        }
      }
      if (same) return dish;
    }
    return null;
  }

  /// Whether [contents] + [extra] is still a strict sub-multiset of some dish.
  static bool canAdd(List<Ingredient> contents, Ingredient extra, {required bool cooked}) {
    final next = [...contents, extra];
    for (final dish in Dish.values) {
      if (dish.cooked != cooked) continue;
      final pool = [...dish.ingredients];
      var ok = true;
      for (final i in next) {
        if (!pool.remove(i)) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }
}

enum PotState { empty, raw, cooking, cooked, burnt }

/// Anything a chef can hold or that can sit on a tile.
sealed class Item {
  const Item();

  Map<String, dynamic> toJson();

  static Item fromJson(Map<String, dynamic> json) {
    switch (json['t'] as String) {
      case 'ing':
        return IngredientItem(Ingredient.parse(json['i'] as String), chopped: json['c'] as bool);
      case 'pot':
        return Pot(
          contents: (json['n'] as List).map((e) => Ingredient.parse(e as String)).toList(),
          cook: (json['k'] as num).toDouble(),
          burn: (json['b'] as num).toDouble(),
          burnt: json['x'] as bool,
        );
      case 'plate':
        return Plate(
          contents: (json['n'] as List).map((e) => Ingredient.parse(e as String)).toList(),
          cooked: json['k'] as bool,
        );
      case 'stack':
        return PlateStack(count: json['c'] as int, dirty: json['d'] as bool);
      case 'ext':
        return const Extinguisher();
    }
    throw ArgumentError('unknown item ${json['t']}');
  }

  Item copy() => Item.fromJson(toJson());
}

class IngredientItem extends Item {
  const IngredientItem(this.ingredient, {this.chopped = false});

  final Ingredient ingredient;
  final bool chopped;

  @override
  Map<String, dynamic> toJson() => {'t': 'ing', 'i': ingredient.name, 'c': chopped};
}

class Pot extends Item {
  Pot({List<Ingredient>? contents, this.cook = 0, this.burn = 0, this.burnt = false}) : contents = contents ?? [];

  final List<Ingredient> contents;

  /// 0..1 cooking progress.
  double cook;

  /// 0..1 time spent on the stove after being cooked.
  double burn;
  bool burnt;

  PotState get state {
    if (burnt) return PotState.burnt;
    if (contents.isEmpty) return PotState.empty;
    if (cook >= 1) return PotState.cooked;
    if (cook > 0) return PotState.cooking;
    return PotState.raw;
  }

  bool get isFull => contents.length >= 3;

  Dish? get dish => burnt ? null : Dish.match(contents, cooked: true);

  @override
  Map<String, dynamic> toJson() => {
    't': 'pot',
    'n': contents.map((e) => e.name).toList(),
    'k': _r(cook),
    'b': _r(burn),
    'x': burnt,
  };
}

class Plate extends Item {
  Plate({List<Ingredient>? contents, this.cooked = false}) : contents = contents ?? [];

  final List<Ingredient> contents;

  /// True when the contents came out of a pot.
  bool cooked;

  bool get isEmpty => contents.isEmpty;

  Dish? get dish => Dish.match(contents, cooked: cooked);

  @override
  Map<String, dynamic> toJson() => {'t': 'plate', 'n': contents.map((e) => e.name).toList(), 'k': cooked};
}

class PlateStack extends Item {
  const PlateStack({required this.count, required this.dirty});

  final int count;
  final bool dirty;

  @override
  Map<String, dynamic> toJson() => {'t': 'stack', 'c': count, 'd': dirty};
}

class Extinguisher extends Item {
  const Extinguisher();

  @override
  Map<String, dynamic> toJson() => {'t': 'ext'};
}

double _r(double v) => (v * 1000).round() / 1000;
