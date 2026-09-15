import 'dart:collection';
import 'dart:math' as math;

import 'items.dart';
import 'rng.dart';
import 'state.dart';
import 'tiles.dart';

/// Shared between the bots of one kitchen so they do not all chase the same tile.
class BotCoordinator {
  final Map<String, (int, int)> claims = {};

  bool claimedByOther(String id, int x, int y) {
    for (final e in claims.entries) {
      if (e.key != id && e.value == (x, y)) return true;
    }
    return false;
  }
}

class _Goal {
  _Goal(this.kind, this.x, this.y, {this.hold = false, this.tile});

  /// What the bot will do once adjacent: `interact` (edge) or `hold` (action).
  final String kind;
  int x;
  int y;
  final bool hold;

  /// The target tile object, so goals on moving platforms can be re-located.
  final Tile? tile;
  List<(int, int)> path = const [];
  double age = 0;

  /// Update [x],[y] if the target tile has moved with its platform.
  void relocate(GameState s) {
    final t = tile;
    if (t == null || identical(s.tileAt(x, y), t)) return;
    for (final (tx, ty, tt) in s.allTiles()) {
      if (identical(tt, t)) {
        x = tx;
        y = ty;
        path = const [];
        return;
      }
    }
  }
}

/// Deterministic scripted chef. Given the same [GameState] sequence and seed it
/// always produces the same inputs, which keeps automated matches reproducible.
class Bot {
  Bot(this.chefId, {required int seed, required this.coordinator}) : rng = Rng(seed);

  final String chefId;
  final Rng rng;
  final BotCoordinator coordinator;

  _Goal? _goal;
  double _stuckTime = 0;
  double _lastX = -1;
  double _lastY = -1;
  bool _interactedLastTick = false;

  /// Current goal as text, for debugging and test logs.
  String get debugGoal => _goal == null ? 'idle' : '${_goal!.kind}@${_goal!.x},${_goal!.y}';

  /// What the bot would choose right now (no side effects).
  String debugChoose(GameState s) {
    final c = s.chefById(chefId);
    if (c == null) return 'no chef';
    final g = _choose(s, c);
    return g == null ? 'none' : '${g.kind}@${g.x},${g.y}';
  }

  ChefInput think(GameState s, double dt) {
    final c = s.chefById(chefId);
    if (c == null || !s.running) return ChefInput.none;

    // Edge-triggered interact: never fire two ticks in a row.
    if (_interactedLastTick) {
      _interactedLastTick = false;
      return ChefInput.none;
    }

    if (_goal != null) {
      _goal!.age += dt;
      _goal!.relocate(s);
      if (_goal!.age > 10 || !_goalStillValid(s, c, _goal!)) _goal = null;
    }
    _goal ??= _choose(s, c);
    final g = _goal;
    if (g == null) {
      coordinator.claims.remove(chefId);
      return ChefInput.none;
    }
    coordinator.claims[chefId] = (g.x, g.y);

    // Stuck detection.
    final moved = (c.x - _lastX).abs() + (c.y - _lastY).abs();
    _lastX = c.x;
    _lastY = c.y;
    if (moved < 0.005) {
      _stuckTime += dt;
    } else {
      _stuckTime = 0;
    }

    final adjacent = _isAdjacent(c, g.x, g.y);
    if (!adjacent) {
      if (g.path.isEmpty || (g.age * 20).round() % 10 == 0) {
        g.path = _pathToAdjacent(s, c, g.x, g.y, any: false);
        if (g.path.isEmpty) g.path = _pathToAdjacent(s, c, g.x, g.y, any: true);
        if (g.path.isEmpty) {
          _goal = null;
          return ChefInput.none;
        }
      }
      if (_stuckTime > 0.8) {
        _stuckTime = 0;
        _goal = null;
        final a = rng.nextInt(4);
        return ChefInput(dx: Dir.values[a].dx.toDouble(), dy: Dir.values[a].dy.toDouble());
      }
      return _follow(s, c, g.path);
    }

    // Adjacent: face the target and act.
    final fx = (g.x + 0.5) - c.x;
    final fy = (g.y + 0.5) - c.y;
    final face = Dir.fromVector(fx, fy);
    final nudgeX = face.dx * 0.02;
    final nudgeY = face.dy * 0.02;
    if (g.kind == 'wait') {
      return ChefInput(dx: nudgeX, dy: nudgeY);
    }
    if (g.hold) {
      return ChefInput(dx: nudgeX, dy: nudgeY, action: true, targetX: g.x, targetY: g.y);
    }
    _interactedLastTick = true;
    _goal = null;
    coordinator.claims.remove(chefId);
    return ChefInput(dx: nudgeX, dy: nudgeY, interact: true, targetX: g.x, targetY: g.y);
  }

  bool _isAdjacent(Chef c, int x, int y) {
    final dx = (x + 0.5) - c.x;
    final dy = (y + 0.5) - c.y;
    // Must be in a 4-neighbour cell and roughly centred on the shared edge.
    return (dx.abs() <= 1.25 && dy.abs() <= 0.3) || (dy.abs() <= 1.25 && dx.abs() <= 0.3);
  }

  ChefInput _follow(GameState s, Chef c, List<(int, int)> path) {
    while (path.isNotEmpty) {
      final (px, py) = path.first;
      final tx = px + 0.5;
      final ty = py + 0.5;
      final dx = tx - c.x;
      final dy = ty - c.y;
      if (dx.abs() < 0.12 && dy.abs() < 0.12) {
        path.removeAt(0);
        continue;
      }
      // Waiting for a moving platform to arrive: stand still and face it.
      if (!s.walkable(px, py)) {
        _stuckTime = 0;
        return ChefInput.none;
      }
      final len = math.sqrt(dx * dx + dy * dy);
      return ChefInput(dx: dx / len, dy: dy / len, dash: len > 3 && c.dashCooldown == 0);
    }
    return ChefInput.none;
  }

  bool _goalStillValid(GameState s, Chef c, _Goal g) {
    final t = s.tileAt(g.x, g.y);
    if (t == null) return false;
    switch (g.kind) {
      case 'chop':
        return c.held == null && t.item is IngredientItem && !(t.item as IngredientItem).chopped;
      case 'wash':
        return c.held == null && t.item is PlateStack && (t.item as PlateStack).dirty;
      case 'spray':
        return c.held is Extinguisher && t.onFire;
      case 'wait':
        return c.held is Plate &&
            (c.held as Plate).isEmpty &&
            t.item is Pot &&
            (t.item as Pot).state == PotState.cooking;
      case 'drop':
        return t.item == null || t.type == TileType.rack || t.type == TileType.sink;
      case 'ship':
        return t.item == null;
      case 'serve':
        final p = c.held;
        return p is Plate && p.dish != null && s.orders.any((o) => o.dish == p.dish);
      default:
        return true;
    }
  }

  // ------------------------------------------------------------------ goals

  _Goal? _choose(GameState s, Chef c) {
    final held = c.held;
    final distNow = _distances(s, (c.tileX, c.tileY), any: false);
    final distAny = _distances(s, (c.tileX, c.tileY), any: true);
    const unreachable = 1 << 30;

    int distanceTo(int x, int y) {
      var d = unreachable;
      for (final p in _standTiles(s, x, y, any: true)) {
        final dd = distAny[p];
        if (dd != null && dd < d) d = dd;
      }
      // Prefer targets reachable right now over ones that need a platform.
      if (d != unreachable && !_standTiles(s, x, y, any: false).any(distNow.containsKey)) d += 6;
      return d;
    }

    bool reachableNow(int x, int y) => _standTiles(s, x, y, any: false).any(distNow.containsKey);

    _Goal? goal(String kind, int x, int y, {bool hold = false}) {
      if (distanceTo(x, y) == unreachable) return null;
      return _Goal(kind, x, y, hold: hold, tile: s.tileAt(x, y));
    }

    /// Nearest tile matching [test]. With [anywhere] unreachable tiles are
    /// included (ranked last) so callers can detect "exists but can't get there".
    (int, int, Tile)? nearest(
      bool Function(int x, int y, Tile t) test, {
      bool avoidClaims = true,
      bool anywhere = false,
    }) {
      (int, int, Tile)? best;
      var bestD = anywhere ? unreachable + 1 : unreachable;
      for (final (x, y, t) in s.allTiles()) {
        // Items on belts are in transit; only the belt's end counter is a target.
        if (t.type == TileType.conveyor) continue;
        if (!test(x, y, t)) continue;
        if (avoidClaims && coordinator.claimedByOther(chefId, x, y)) continue;
        final d = distanceTo(x, y);
        if (d < bestD) {
          bestD = d;
          best = (x, y, t);
        }
      }
      return best;
    }

    /// Go to a matching tile, or if one exists only beyond a wall, put the
    /// held item on a conveyor that flows towards it.
    _Goal? deliver(String kind, bool Function(int x, int y, Tile t) test, {bool avoidClaims = true}) {
      final near = nearest(test, avoidClaims: avoidClaims);
      if (near != null && reachableNow(near.$1, near.$2)) return goal(kind, near.$1, near.$2);
      final far = near ?? nearest(test, avoidClaims: false, anywhere: true);
      if (far == null) return null;
      // Target is across a gap: leave the item on a counter both sides can
      // reach, or on a belt that flows there; otherwise wait for the platform.
      final hand = _handoverCounter(s, far.$1, far.$2, distNow);
      if (hand != null) return _Goal('drop', hand.$1, hand.$2, tile: s.tileAt(hand.$1, hand.$2));
      final belt = _shipVia(s, far.$1, far.$2, distNow);
      if (belt != null) return _Goal('ship', belt.$1, belt.$2, tile: s.tileAt(belt.$1, belt.$2));
      return near == null ? null : goal(kind, near.$1, near.$2);
    }

    // Empty counter that is not the end of a belt (those must stay clear).
    bool freeCounterAt(int x, int y, Tile t) {
      if (t.type != TileType.counter || t.item != null) return false;
      for (final d in Dir.values) {
        final n = s.tileAt(x - d.dx, y - d.dy);
        if (n != null && n.type == TileType.conveyor && n.conveyorDir == d) return false;
      }
      return true;
    }

    // --- Fire has top priority.
    final fire = nearest((x, y, t) => t.onFire, avoidClaims: false);
    if (fire != null) {
      if (held is Extinguisher) return goal('spray', fire.$1, fire.$2, hold: true);
      if (held != null) {
        final drop = nearest(freeCounterAt);
        if (drop != null) return goal('drop', drop.$1, drop.$2);
      } else {
        final ext = nearest((x, y, t) => t.item is Extinguisher);
        if (ext != null) return goal('pick', ext.$1, ext.$2);
      }
    }

    final wanted = s.orders.map((o) => o.dish).toList();

    if (held != null) {
      switch (held) {
        case Extinguisher():
          final drop = nearest(freeCounterAt);
          return drop == null ? null : goal('drop', drop.$1, drop.$2);
        case PlateStack():
          final sink = deliver(
            'drop',
            (x, y, t) => t.type == TileType.sink && (t.item == null || t.item is PlateStack),
          );
          if (sink != null) return sink;
          final drop = nearest(freeCounterAt);
          return drop == null ? null : goal('drop', drop.$1, drop.$2);
        case Plate():
          if (held.dish != null) {
            if (wanted.contains(held.dish)) {
              final pass = deliver('serve', (x, y, t) => t.type == TileType.pass, avoidClaims: false);
              if (pass != null) return pass;
            }
            final drop = nearest(freeCounterAt);
            return drop == null ? null : goal('drop', drop.$1, drop.$2);
          }
          if (held.isEmpty) {
            final pot = deliver(
              'scoop',
              (x, y, t) => t.item is Pot && (t.item as Pot).state == PotState.cooked,
              avoidClaims: false,
            );
            if (pot != null) return pot;
            // Stand by a cooking pot so the soup is plated the moment it is ready.
            final cooking = deliver('wait', (x, y, t) => t.item is Pot && (t.item as Pot).state == PotState.cooking);
            if (cooking != null) return cooking;
          }
          // Salad assembly: find a chopped ingredient the plate can take.
          final ing = nearest((x, y, t) {
            final i = t.item;
            return i is IngredientItem &&
                i.chopped &&
                Dish.canAdd(held.contents, i.ingredient, cooked: false) &&
                _saladWanted(wanted, held.contents, i.ingredient);
          });
          if (ing != null) return goal('combine', ing.$1, ing.$2);
          if (held.isEmpty) {
            final rack = nearest((x, y, t) => t.type == TileType.rack);
            if (rack != null) return goal('drop', rack.$1, rack.$2);
          }
          final drop = nearest(freeCounterAt);
          return drop == null ? null : goal('drop', drop.$1, drop.$2);
        case Pot():
          if (held.burnt) {
            final trash = nearest((x, y, t) => t.type == TileType.trash, avoidClaims: false);
            if (trash != null) return goal('trash', trash.$1, trash.$2);
          }
          final stove = nearest((x, y, t) => t.type == TileType.stove && t.item == null);
          if (stove != null) return goal('drop', stove.$1, stove.$2);
          final drop = nearest(freeCounterAt);
          return drop == null ? null : goal('drop', drop.$1, drop.$2);
        case IngredientItem():
          if (!held.chopped) {
            final board = nearest((x, y, t) => t.type == TileType.board && t.item == null);
            if (board != null) return goal('drop', board.$1, board.$2);
            final drop = nearest(freeCounterAt);
            return drop == null ? null : goal('drop', drop.$1, drop.$2);
          }
          final needsCooking = wanted.any((d) => d.cooked && d.ingredients.contains(held.ingredient));
          if (needsCooking) {
            final pot = deliver('combine', (x, y, t) {
              final p = t.item;
              return p is Pot &&
                  !p.burnt &&
                  p.cook < 1 &&
                  Dish.canAdd(p.contents, held.ingredient, cooked: true) &&
                  _potWanted(wanted, p.contents, held.ingredient);
            }, avoidClaims: false);
            if (pot != null) return pot;
          }
          final plate = nearest((x, y, t) {
            final p = t.item;
            return p is Plate &&
                !p.cooked &&
                Dish.canAdd(p.contents, held.ingredient, cooked: false) &&
                _saladWanted(wanted, p.contents, held.ingredient);
          });
          if (plate != null && !needsCooking) return goal('combine', plate.$1, plate.$2);
          final drop = nearest(freeCounterAt);
          return drop == null ? null : goal('drop', drop.$1, drop.$2);
      }
    }

    // --- Hands free.
    (int, int, Tile)? nearestNow(bool Function(int x, int y, Tile t) test, {bool avoidClaims = true}) =>
        nearest((x, y, t) => reachableNow(x, y) && test(x, y, t), avoidClaims: avoidClaims);

    // A hatch is a counter that another region can also reach; items left on
    // one are for the other side unless their destination is on my side.
    bool onHatch(int x, int y) => _standTiles(s, x, y, any: true).any((p) => !distNow.containsKey(p));

    final burnt = nearest((x, y, t) => t.item is Pot && (t.item as Pot).burnt && !t.onFire);
    if (burnt != null) return goal('pick', burnt.$1, burnt.$2);

    // A belt is backed up behind a full end counter: clear the end counter.
    final jam = _jammedBeltEnd(s);
    if (jam != null && !coordinator.claimedByOther(chefId, jam.$1, jam.$2)) {
      final g = goal('pick', jam.$1, jam.$2);
      if (g != null) return g;
    }

    final activePot = nearest(
      (x, y, t) =>
          t.item is Pot && ((t.item as Pot).state == PotState.cooked || (t.item as Pot).state == PotState.cooking),
      avoidClaims: false,
      anywhere: true,
    );
    final activePotNow = activePot != null && reachableNow(activePot.$1, activePot.$2);
    if (activePot != null && _emptyPlatesHeld(s) < _activePots(s)) {
      final staged = nearestNow(
        (x, y, t) =>
            t.type != TileType.rack && t.item is Plate && (t.item as Plate).isEmpty && (activePotNow || !onHatch(x, y)),
      );
      if (staged != null) return goal('pick', staged.$1, staged.$2);
    }
    if (activePot != null && _emptyPlatesHeld(s) + _emptyPlatesStaged(s) < _activePots(s)) {
      final plate = nearestNow((x, y, t) => t.item is PlateStack && !(t.item as PlateStack).dirty);
      if (plate != null) return goal('pick', plate.$1, plate.$2);
    }

    final passNow = nearestNow((x, y, t) => t.type == TileType.pass, avoidClaims: false) != null;
    final ready = nearestNow(
      (x, y, t) =>
          t.item is Plate &&
          (t.item as Plate).dish != null &&
          wanted.contains((t.item as Plate).dish) &&
          (passNow || !onHatch(x, y)),
    );
    if (ready != null) return goal('pick', ready.$1, ready.$2);

    final saladPlate = nearest(
      (x, y, t) =>
          t.item is Plate &&
          !(t.item as Plate).cooked &&
          (t.item as Plate).contents.isNotEmpty &&
          (t.item as Plate).dish == null,
    );
    if (saladPlate != null && wanted.any((d) => !d.cooked)) return goal('pick', saladPlate.$1, saladPlate.$2);

    final chopped = nearestNow((x, y, t) {
      final i = t.item;
      if (i is! IngredientItem || !i.chopped) return false;
      return _hasDestination(s, wanted, i.ingredient, where: onHatch(x, y) ? reachableNow : null);
    });
    if (chopped != null) return goal('pick', chopped.$1, chopped.$2);

    final raw = nearestNow(
      (x, y, t) => t.type == TileType.board && t.item is IngredientItem && !(t.item as IngredientItem).chopped,
    );
    if (raw != null) return goal('chop', raw.$1, raw.$2, hold: true);

    final freeBoard = nearestNow((x, y, t) => t.type == TileType.board && t.item == null);
    final looseRaw = nearestNow(
      (x, y, t) => t.type != TileType.board && t.item is IngredientItem && !(t.item as IngredientItem).chopped,
    );
    if (freeBoard != null && looseRaw != null) return goal('pick', looseRaw.$1, looseRaw.$2);
    if (freeBoard == null && looseRaw != null) {
      // Boards are blocked by chopped food with nowhere to go: move it aside.
      final blocked = nearest((x, y, t) => t.type == TileType.board && t.item is IngredientItem);
      final counter = nearest(freeCounterAt);
      if (blocked != null && counter != null) return goal('pick', blocked.$1, blocked.$2);
    }

    final dirtySink = nearestNow((x, y, t) => t.type == TileType.sink && t.item is PlateStack);
    final sinkNow = nearestNow((x, y, t) => t.type == TileType.sink, avoidClaims: false) != null;
    final dirtyReturn = nearestNow(
      (x, y, t) =>
          t.type != TileType.sink &&
          t.item is PlateStack &&
          (t.item as PlateStack).dirty &&
          (sinkNow || !onHatch(x, y)),
    );
    final cleanPlates = _cleanPlateCount(s);
    if (cleanPlates < 2) {
      if (dirtySink != null) return goal('wash', dirtySink.$1, dirtySink.$2, hold: true);
      if (dirtyReturn != null) return goal('pick', dirtyReturn.$1, dirtyReturn.$2);
    }

    final need = _potCompletion(s, wanted) ?? _nextNeededIngredient(s, wanted);
    if (need != null && _looseRawCount(s) < _freeBoardCount(s)) {
      final crate = nearestNow((x, y, t) => t.type == TileType.crate && t.crate == need, avoidClaims: false);
      if (crate != null) return goal('pick', crate.$1, crate.$2);
    }

    if (dirtySink != null) return goal('wash', dirtySink.$1, dirtySink.$2, hold: true);
    if (dirtyReturn != null) return goal('pick', dirtyReturn.$1, dirtyReturn.$2);

    // Salad plates: grab a plate when a salad is wanted and chopped salad items exist.
    if (wanted.any((d) => !d.cooked)) {
      final rack = nearestNow((x, y, t) => t.type == TileType.rack && t.item is PlateStack);
      if (rack != null) return goal('pick', rack.$1, rack.$2);
    }
    // Nothing to do on this side: cross over to where the work is.
    if (activePot != null && _emptyPlatesHeld(s) + _emptyPlatesStaged(s) < _activePots(s)) {
      final plate = nearest((x, y, t) => t.item is PlateStack && !(t.item as PlateStack).dirty);
      if (plate != null) return goal('pick', plate.$1, plate.$2);
    }
    final farChopped = nearest((x, y, t) {
      final i = t.item;
      return i is IngredientItem && i.chopped && !onHatch(x, y) && _hasDestination(s, wanted, i.ingredient);
    });
    if (farChopped != null) return goal('pick', farChopped.$1, farChopped.$2);
    final farRaw = nearest(
      (x, y, t) => t.type == TileType.board && t.item is IngredientItem && !(t.item as IngredientItem).chopped,
    );
    if (farRaw != null) return goal('chop', farRaw.$1, farRaw.$2, hold: true);
    if (need != null && _looseRawCount(s) < _freeBoardCount(s)) {
      final crate = nearest((x, y, t) => t.type == TileType.crate && t.crate == need, avoidClaims: false);
      if (crate != null) return goal('pick', crate.$1, crate.$2);
    }
    if (dirtyReturn == null && cleanPlates < 2) {
      final dirty = nearest((x, y, t) => t.item is PlateStack && (t.item as PlateStack).dirty && !onHatch(x, y));
      if (dirty != null) {
        return goal(
          dirty.$3.type == TileType.sink ? 'wash' : 'pick',
          dirty.$1,
          dirty.$2,
          hold: dirty.$3.type == TileType.sink,
        );
      }
    }
    return null;
  }

  bool _potWanted(List<Dish> wanted, List<Ingredient> contents, Ingredient extra) {
    final next = [...contents, extra];
    for (final d in wanted) {
      if (!d.cooked) continue;
      final pool = [...d.ingredients];
      if (next.every(pool.remove)) return true;
    }
    return false;
  }

  bool _saladWanted(List<Dish> wanted, List<Ingredient> contents, Ingredient extra) {
    final next = [...contents, extra];
    for (final d in wanted) {
      if (d.cooked) continue;
      final pool = [...d.ingredients];
      if (next.every(pool.remove)) return true;
    }
    return false;
  }

  /// Whether a chopped [ing] could go somewhere useful right now: a pot that
  /// accepts it towards a wanted soup, or a plate for a wanted salad.
  bool _hasDestination(GameState s, List<Dish> wanted, Ingredient ing, {bool Function(int x, int y)? where}) {
    final soup = wanted.any((d) => d.cooked && d.ingredients.contains(ing));
    final salad = wanted.any((d) => !d.cooked && d.ingredients.contains(ing));
    for (final (x, y, t) in s.allTiles()) {
      if (where != null && !where(x, y)) continue;
      final p = t.item;
      if (soup &&
          p is Pot &&
          !p.burnt &&
          p.cook < 1 &&
          Dish.canAdd(p.contents, ing, cooked: true) &&
          _potWanted(wanted, p.contents, ing)) {
        return true;
      }
      if (salad &&
          p is Plate &&
          !p.cooked &&
          Dish.canAdd(p.contents, ing, cooked: false) &&
          _saladWanted(wanted, p.contents, ing)) {
        return true;
      }
      if (salad && p is PlateStack && !p.dirty) return true;
    }
    return false;
  }

  /// Ingredient that would complete a partially filled pot, unless one is
  /// already chopped and waiting somewhere.
  Ingredient? _potCompletion(GameState s, List<Dish> wanted) {
    final loose = <Ingredient>[];
    for (final (_, _, t) in s.allTiles()) {
      final i = t.item;
      if (i is IngredientItem) loose.add(i.ingredient);
    }
    for (final c in s.chefs) {
      final i = c.held;
      if (i is IngredientItem) loose.add(i.ingredient);
    }
    for (final (_, _, t) in s.allTiles()) {
      final p = t.item;
      if (p is! Pot || p.burnt || p.cook > 0 || p.contents.isEmpty || p.dish != null) continue;
      for (final d in wanted) {
        if (!d.cooked) continue;
        final pool = [...d.ingredients];
        if (!p.contents.every(pool.remove)) continue;
        for (final ing in pool) {
          if (!loose.remove(ing)) return ing;
        }
      }
    }
    return null;
  }

  /// End counter of a conveyor that currently holds an item while a belt tile
  /// feeding it also holds one.
  (int, int)? _jammedBeltEnd(GameState s) {
    for (final (x, y, t) in s.allTiles()) {
      if (t.type != TileType.conveyor || t.item == null) continue;
      final nx = x + t.conveyorDir!.dx;
      final ny = y + t.conveyorDir!.dy;
      final n = s.tileAt(nx, ny);
      if (n == null || n.type == TileType.conveyor || n.item == null) continue;
      return (nx, ny);
    }
    return null;
  }

  int _freeBoardCount(GameState s) =>
      s.allTiles().where((e) => e.$3.type == TileType.board && e.$3.item == null).length;

  int _looseRawCount(GameState s) =>
      s
          .allTiles()
          .where(
            (e) => e.$3.type != TileType.crate && e.$3.item is IngredientItem && !(e.$3.item as IngredientItem).chopped,
          )
          .length +
      s.chefs.where((c) => c.held is IngredientItem && !(c.held as IngredientItem).chopped).length;

  int _emptyPlatesHeld(GameState s) => s.chefs.where((c) => c.held is Plate && (c.held as Plate).isEmpty).length;

  int _activePots(GameState s) => s
      .allTiles()
      .where(
        (e) =>
            e.$3.item is Pot &&
            ((e.$3.item as Pot).state == PotState.cooked || (e.$3.item as Pot).state == PotState.cooking),
      )
      .length;

  /// Empty plates already taken off the rack and left on counters/belts.
  int _emptyPlatesStaged(GameState s) => s
      .allTiles()
      .where((e) => e.$3.type != TileType.rack && e.$3.item is Plate && (e.$3.item as Plate).isEmpty)
      .length;

  int _cleanPlateCount(GameState s) {
    var n = 0;
    for (final (_, _, t) in s.allTiles()) {
      final i = t.item;
      if (i is PlateStack && !i.dirty) n += i.count;
      if (i is Plate && i.isEmpty) n++;
    }
    for (final c in s.chefs) {
      final i = c.held;
      if (i is Plate && i.isEmpty) n++;
    }
    return n;
  }

  /// Ingredient still missing for the oldest order that is not already covered
  /// by food in pots, on plates, on boards/counters or in hands.
  Ingredient? _nextNeededIngredient(GameState s, List<Dish> wanted) {
    final available = <Ingredient, int>{};
    void add(Ingredient i) => available[i] = (available[i] ?? 0) + 1;
    for (final (_, _, t) in s.allTiles()) {
      final i = t.item;
      if (i is IngredientItem) add(i.ingredient);
      if (i is Pot && !i.burnt) i.contents.forEach(add);
      if (i is Plate) i.contents.forEach(add);
    }
    for (final c in s.chefs) {
      final i = c.held;
      if (i is IngredientItem) add(i.ingredient);
      if (i is Pot && !i.burnt) i.contents.forEach(add);
      if (i is Plate) i.contents.forEach(add);
    }
    for (final d in wanted) {
      for (final ing in d.ingredients) {
        final have = available[ing] ?? 0;
        if (have > 0) {
          available[ing] = have - 1;
        } else {
          return ing;
        }
      }
    }
    return null;
  }

  // ------------------------------------------------------------------ paths

  bool _walk(GameState s, int x, int y, bool any) => any ? s.walkableAny(x, y) : s.walkable(x, y);

  List<(int, int)> _standTiles(GameState s, int x, int y, {required bool any}) {
    final out = <(int, int)>[];
    for (final d in Dir.values) {
      final sx = x + d.dx;
      final sy = y + d.dy;
      if (_walk(s, sx, sy, any)) out.add((sx, sy));
    }
    return out;
  }

  Map<(int, int), int> _distances(GameState s, (int, int) start, {required bool any}) {
    final dist = <(int, int), int>{start: 0};
    final q = Queue<(int, int)>()..add(start);
    while (q.isNotEmpty) {
      final (x, y) = q.removeFirst();
      final d = dist[(x, y)]!;
      for (final dir in Dir.values) {
        final n = (x + dir.dx, y + dir.dy);
        if (dist.containsKey(n) || !_walk(s, n.$1, n.$2, any)) continue;
        dist[n] = d + 1;
        q.add(n);
      }
    }
    return dist;
  }

  /// Empty counter reachable from here now, that is also reachable from the
  /// destination ([dx],[dy]) side right now - i.e. a hatch between two regions.
  (int, int)? _handoverCounter(GameState s, int dx, int dy, Map<(int, int), int> distNow) {
    final destStands = _standTiles(s, dx, dy, any: false);
    if (destStands.isEmpty) return null;
    final fromDest = _distances(s, destStands.first, any: false);
    (int, int)? best;
    var bestD = 1 << 30;
    for (final (x, y, t) in s.allTiles()) {
      if (t.type != TileType.counter || t.item != null) continue;
      var mine = 1 << 30;
      var theirs = false;
      for (final d in Dir.values) {
        final p = (x + d.dx, y + d.dy);
        final dd = distNow[p];
        if (dd != null && dd < mine) mine = dd;
        if (dd == null && fromDest.containsKey(p)) theirs = true;
      }
      if (!theirs || mine >= bestD) continue;
      bestD = mine;
      best = (x, y);
    }
    return best;
  }

  /// Empty conveyor tile, reachable now, whose belt ends somewhere that can
  /// reach the destination ([dx],[dy]) on foot.
  (int, int)? _shipVia(GameState s, int dx, int dy, Map<(int, int), int> distNow) {
    final destStands = _standTiles(s, dx, dy, any: true);
    if (destStands.isEmpty) return null;
    final fromDest = _distances(s, destStands.first, any: true);
    (int, int)? best;
    var bestD = 1 << 30;
    for (final (x, y, t) in s.allTiles()) {
      if (t.type != TileType.conveyor || t.item != null) continue;
      var d = 1 << 30;
      for (final p in _standTiles(s, x, y, any: false)) {
        final dd = distNow[p];
        if (dd != null && dd < d) d = dd;
      }
      if (d >= bestD) continue;
      // Follow the belt to its end.
      var ex = x;
      var ey = y;
      var guard = 0;
      while (guard++ < 64) {
        final tile = s.tileAt(ex, ey);
        if (tile == null || tile.type != TileType.conveyor) break;
        ex += tile.conveyorDir!.dx;
        ey += tile.conveyorDir!.dy;
      }
      final end = s.tileAt(ex, ey);
      if (end == null || !end.type.holdsItems || end.type.walkable) continue;
      if (!_standTiles(s, ex, ey, any: true).any(fromDest.containsKey)) continue;
      bestD = d;
      best = (x, y);
    }
    return best;
  }

  List<(int, int)> _pathToAdjacent(GameState s, Chef c, int tx, int ty, {required bool any}) {
    final goals = _standTiles(s, tx, ty, any: any).toSet();
    if (goals.isEmpty) return const [];
    final start = (c.tileX, c.tileY);
    if (goals.contains(start)) return [start];
    final prev = <(int, int), (int, int)?>{start: null};
    final q = Queue<(int, int)>()..add(start);
    (int, int)? found;
    while (q.isNotEmpty && found == null) {
      final cur = q.removeFirst();
      for (final dir in Dir.values) {
        final n = (cur.$1 + dir.dx, cur.$2 + dir.dy);
        if (prev.containsKey(n) || !_walk(s, n.$1, n.$2, any)) continue;
        prev[n] = cur;
        if (goals.contains(n)) {
          found = n;
          break;
        }
        q.add(n);
      }
    }
    if (found == null) return const [];
    final path = <(int, int)>[];
    (int, int)? p = found;
    while (p != null) {
      path.insert(0, p);
      p = prev[p];
    }
    if (path.length > 1) path.removeAt(0);
    return path;
  }
}
