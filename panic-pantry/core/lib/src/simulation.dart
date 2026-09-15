import 'dart:math' as math;

import 'items.dart';
import 'rng.dart';
import 'scoring.dart';
import 'state.dart';
import 'tiles.dart';

/// Tunable constants shared by server, bots and client prediction.
class Rules {
  static const double tickSeconds = 0.05;
  static const double chefSpeed = 4.2;
  static const double chefRadius = 0.34;
  static const double dashSeconds = 0.18;
  static const double dashCooldown = 0.7;
  static const double chopSeconds = 1.6;
  static const double cookSeconds = 7;
  static const double burnSeconds = 12;
  static const double washSeconds = 2;
  static const double sprayPerSecond = 1 / 1.2;
  static const double fireSpreadSeconds = 6;
  static const double plateReturnSeconds = 9;
  static const double conveyorSeconds = 0.9;
  static const double countdownSeconds = 3;
  static const double overtimeSeconds = 5;
  static const double emoteSeconds = 2.2;
  static const int maxOrders = 4;
  static const int initialOrders = 2;

  /// Max distance (tile centres) between a chef and a client-reported target
  /// for the server to honour that target instead of its own facing tile.
  static const double targetTolerance = 1.7;
}

/// Deterministic, server-authoritative kitchen simulation.
class Simulation {
  Simulation(this.state, {required int seed}) : rng = Rng(seed);

  final GameState state;
  final Rng rng;

  /// Inputs to apply on the next [step], keyed by chef id.
  final Map<String, ChefInput> pending = {};

  void startRound() {
    final s = state;
    s.phase = Phase.countdown;
    s.countdown = Rules.countdownSeconds;
    s.timeLeft = s.level.roundSeconds.toDouble();
    s.time = 0;
    s.tick = 0;
    s.score = 0;
    s.combo = 1;
    s.bestCombo = 1;
    s.served = 0;
    s.expired = 0;
    s.tips = 0;
    s.wrongServes = 0;
    s.burntPots = 0;
    s.servedByDish.clear();
    s.orders.clear();
    s.plateReturns.clear();
    s.nextOrderIn = s.level.orderIntervalSeconds;
    for (var i = 0; i < s.chefs.length; i++) {
      final c = s.chefs[i];
      final spawn = s.spawns[c.slot] ?? s.spawns.values.elementAt(i % s.spawns.length);
      c.x = spawn.$1;
      c.y = spawn.$2;
      c.facing = Dir.down;
      c.held = null;
      c.dash = 0;
      c.dashCooldown = 0;
      c.working = false;
      c.emote = null;
    }
  }

  void step() {
    final s = state;
    const dt = Rules.tickSeconds;
    s.tick++;
    if (s.phase == Phase.lobby || s.phase == Phase.finished) return;
    s.time += dt;
    _updateMovers(dt);

    if (s.phase == Phase.countdown) {
      s.countdown -= dt;
      if (s.countdown <= 0) {
        s.countdown = 0;
        s.phase = Phase.playing;
        for (var i = 0; i < Rules.initialOrders; i++) {
          _spawnOrder();
        }
        s.events.add(const GameEvent('go'));
      }
    }

    for (final c in s.chefs) {
      _stepChef(c, pending[c.id] ?? ChefInput.none, dt);
    }
    _resolveChefCollisions();
    _stepTiles(dt);

    if (s.phase == Phase.playing || s.phase == Phase.overtime) {
      for (final o in [...s.orders]) {
        o.remaining -= dt;
        if (o.remaining <= 0) {
          s.orders.remove(o);
          s.expired++;
          s.combo = 1;
          s.score = math.max(0, s.score - Scoring.expiredPenalty);
          s.events.add(GameEvent('expired', value: -Scoring.expiredPenalty, text: o.dish.label));
        }
      }
    }

    if (s.phase == Phase.playing) {
      s.nextOrderIn -= dt;
      if (s.nextOrderIn <= 0 && s.orders.length < Rules.maxOrders) {
        _spawnOrder();
        s.nextOrderIn = s.level.orderIntervalSeconds;
      }
      s.timeLeft -= dt;
      if (s.timeLeft <= 0) {
        s.timeLeft = 0;
        if (s.orders.isNotEmpty && _platedOrderExists()) {
          s.phase = Phase.overtime;
          s.overtimeLeft = Rules.overtimeSeconds;
          s.events.add(const GameEvent('overtime'));
        } else {
          _finish();
        }
      }
    } else if (s.phase == Phase.overtime) {
      s.overtimeLeft -= dt;
      if (s.overtimeLeft <= 0 || s.orders.isEmpty || !_platedOrderExists()) {
        s.overtimeLeft = 0;
        _finish();
      }
    }
    pending.clear();
  }

  void _finish() {
    state.phase = Phase.finished;
    state.events.add(GameEvent('finished', value: state.score));
  }

  /// Whether a plated dish matching an open order exists anywhere (held or on a tile).
  bool _platedOrderExists() {
    final wanted = state.orders.map((o) => o.dish).toSet();
    bool matches(Item? i) => i is Plate && i.dish != null && wanted.contains(i.dish);
    for (final c in state.chefs) {
      if (matches(c.held)) return true;
    }
    for (final (_, _, t) in state.allTiles()) {
      if (matches(t.item)) return true;
    }
    return false;
  }

  void _spawnOrder() {
    final menu = state.level.menu;
    final dish = menu[rng.nextInt(menu.length)];
    state.orders.add(
      Order(
        id: state.nextOrderId++,
        dish: dish,
        remaining: state.level.orderDurationSeconds,
        duration: state.level.orderDurationSeconds,
      ),
    );
    state.events.add(GameEvent('order', text: dish.label));
  }

  // ---------------------------------------------------------------- movers

  void _updateMovers(double dt) {
    final s = state;
    for (var i = 0; i < s.level.movers.length; i++) {
      final m = s.level.movers[i];
      final before = s.moverOffsets[i];
      final after = m.offsetAt(s.time);
      final delta = after - before;
      if (delta == 0) continue;
      // Carry chefs standing on the block.
      for (final c in s.chefs) {
        if (s.moverAt(c.tileX, c.tileY) == i) {
          if (m.axis == 'x') {
            c.x += delta;
          } else {
            c.y += delta;
          }
        }
      }
      s.moverOffsets[i] = after;
    }
    for (final c in s.chefs) {
      if (!s.walkable(c.tileX, c.tileY)) _rescue(c);
    }
  }

  void _rescue(Chef c) {
    (double, double)? best;
    var bestD = double.infinity;
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        final tx = c.tileX + dx;
        final ty = c.tileY + dy;
        if (!state.walkable(tx, ty)) continue;
        final cx = tx + 0.5;
        final cy = ty + 0.5;
        final d = (cx - c.x) * (cx - c.x) + (cy - c.y) * (cy - c.y);
        if (d < bestD) {
          bestD = d;
          best = (cx, cy);
        }
      }
    }
    if (best != null) {
      c.x = best.$1;
      c.y = best.$2;
    }
  }

  // ---------------------------------------------------------------- chefs

  void _stepChef(Chef c, ChefInput input, double dt) {
    if (c.emote != null) {
      c.emoteTtl -= dt;
      if (c.emoteTtl <= 0) c.emote = null;
    }
    if (input.emote != null && input.emote! >= 0 && input.emote! < kEmotes.length) {
      c.emote = input.emote;
      c.emoteTtl = Rules.emoteSeconds;
      state.events.add(GameEvent('emote', chef: c.id, value: input.emote));
    }
    if (!state.running && state.phase != Phase.countdown) return;

    c.dashCooldown = math.max(0, c.dashCooldown - dt);
    if (input.dash && c.dashCooldown == 0 && c.dash == 0) {
      c.dash = Rules.dashSeconds;
      c.dashCooldown = Rules.dashCooldown;
      state.events.add(GameEvent('dash', chef: c.id));
    }
    c.dash = math.max(0, c.dash - dt);

    var dx = input.dx;
    var dy = input.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > 1) {
      dx /= len;
      dy /= len;
    }
    if (len > 0.01) {
      c.facing = Dir.fromVector(dx, dy);
    }
    if (c.dash > 0 && len < 0.01) {
      dx = c.facing.dx.toDouble();
      dy = c.facing.dy.toDouble();
    }
    final speed = Rules.chefSpeed * c.speedMultiplier * dt;
    _move(c, dx * speed, dy * speed);

    // Interactions only during play.
    c.working = false;
    if (!state.running) return;
    final target = _targetFor(c, input);
    if (target == null) return;
    final (tx, ty, tile) = target;
    if (input.interact) _interact(c, tile, tx, ty);
    if (input.action) _act(c, tile, tx, ty, dt);
  }

  void _move(Chef c, double mx, double my) {
    const r = Rules.chefRadius;
    if (mx != 0) {
      final nx = c.x + mx;
      final edge = mx > 0 ? nx + r : nx - r;
      final ex = edge.floor();
      final y0 = (c.y - r + 0.01).floor();
      final y1 = (c.y + r - 0.01).floor();
      if (state.walkable(ex, y0) && state.walkable(ex, y1)) {
        c.x = nx;
      } else {
        c.x = mx > 0 ? ex - r - 0.001 : ex + 1 + r + 0.001;
      }
    }
    if (my != 0) {
      final ny = c.y + my;
      final edge = my > 0 ? ny + r : ny - r;
      final ey = edge.floor();
      final x0 = (c.x - r + 0.01).floor();
      final x1 = (c.x + r - 0.01).floor();
      if (state.walkable(x0, ey) && state.walkable(x1, ey)) {
        c.y = ny;
      } else {
        c.y = my > 0 ? ey - r - 0.001 : ey + 1 + r + 0.001;
      }
    }
  }

  void _resolveChefCollisions() {
    final chefs = state.chefs;
    const minD = Rules.chefRadius * 2;
    for (var i = 0; i < chefs.length; i++) {
      for (var j = i + 1; j < chefs.length; j++) {
        final a = chefs[i];
        final b = chefs[j];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d >= minD || d == 0) continue;
        final push = (minD - d) / 2;
        final ux = dx / d;
        final uy = dy / d;
        _tryShift(a, -ux * push, -uy * push);
        _tryShift(b, ux * push, uy * push);
      }
    }
  }

  void _tryShift(Chef c, double dx, double dy) {
    final ox = c.x;
    final oy = c.y;
    _move(c, dx, dy);
    if (!state.walkable(c.tileX, c.tileY)) {
      c.x = ox;
      c.y = oy;
    }
  }

  /// The tile a chef is interacting with. Honours the client's reported target
  /// when it is close enough (lag compensation for pick up / drop).
  (int, int, Tile)? _targetFor(Chef c, ChefInput input) {
    if (input.targetX != null && input.targetY != null) {
      final cx = input.targetX! + 0.5;
      final cy = input.targetY! + 0.5;
      final d = math.sqrt((cx - c.x) * (cx - c.x) + (cy - c.y) * (cy - c.y));
      if (d <= Rules.targetTolerance) {
        final t = state.tileAt(input.targetX!, input.targetY!);
        if (t != null && t.type != TileType.wall && t.type != TileType.pit) {
          return (input.targetX!, input.targetY!, t);
        }
      }
    }
    return facingTarget(c);
  }

  /// The tile directly in front of [c].
  (int, int, Tile)? facingTarget(Chef c) {
    final tx = c.tileX + c.facing.dx;
    final ty = c.tileY + c.facing.dy;
    final t = state.tileAt(tx, ty);
    if (t == null || t.type == TileType.wall || t.type == TileType.pit) return null;
    return (tx, ty, t);
  }

  // ---------------------------------------------------------------- interact

  void _interact(Chef c, Tile t, int tx, int ty) {
    final held = c.held;
    if (t.onFire && held is! Extinguisher) return;
    if (held == null) {
      _pickUp(c, t, tx, ty);
      return;
    }
    switch (t.type) {
      case TileType.trash:
        _trash(c, held);
        return;
      case TileType.pass:
        if (held is Plate && !held.isEmpty) _serve(c, held, tx, ty);
        return;
      case TileType.crate:
        return;
      case TileType.sink:
        if (held is PlateStack && held.dirty) {
          final existing = t.item;
          if (existing == null) {
            t.item = held;
          } else if (existing is PlateStack && existing.dirty) {
            t.item = PlateStack(count: existing.count + held.count, dirty: true);
          } else {
            return;
          }
          c.held = null;
        }
        return;
      case TileType.board:
        if (t.item == null && held is IngredientItem && !held.chopped) {
          t.item = held;
          t.progress = 0;
          c.held = null;
          return;
        }
        _combine(c, t, tx, ty);
        return;
      case TileType.stove:
        if (t.item == null && held is Pot) {
          t.item = held;
          c.held = null;
          return;
        }
        _combine(c, t, tx, ty);
        return;
      case TileType.rack:
        if (held is Plate && held.isEmpty) {
          final existing = t.item;
          if (existing == null) {
            t.item = const PlateStack(count: 1, dirty: false);
            c.held = null;
          } else if (existing is PlateStack && !existing.dirty) {
            t.item = PlateStack(count: existing.count + 1, dirty: false);
            c.held = null;
          }
          return;
        }
        _combine(c, t, tx, ty);
        return;
      default:
        if (t.item == null) {
          if (t.type.holdsItems) {
            t.item = held;
            t.conveyor = 0;
            c.held = null;
            state.events.add(GameEvent('drop', x: tx, y: ty, chef: c.id));
          }
          return;
        }
        _combine(c, t, tx, ty);
    }
  }

  void _pickUp(Chef c, Tile t, int tx, int ty) {
    if (t.type == TileType.crate) {
      c.held = IngredientItem(t.crate!);
      state.events.add(GameEvent('pickup', x: tx, y: ty, chef: c.id));
      return;
    }
    final item = t.item;
    if (item == null) return;
    if (item is PlateStack && !item.dirty) {
      c.held = Plate();
      t.item = item.count > 1 ? PlateStack(count: item.count - 1, dirty: false) : null;
    } else {
      if (t.type == TileType.sink) return; // dirty plates leave the sink only by washing
      c.held = item;
      t.item = null;
      t.progress = 0;
      t.conveyor = 0;
    }
    state.events.add(GameEvent('pickup', x: tx, y: ty, chef: c.id));
  }

  /// Held item + tile item combinations (plating, filling pots, stacking).
  void _combine(Chef c, Tile t, int tx, int ty) {
    final held = c.held!;
    final item = t.item;
    if (item == null) return;
    // Chopped ingredient into a pot on the tile.
    if (held is IngredientItem && held.chopped && item is Pot && !item.burnt) {
      if (_addToPot(item, held.ingredient)) c.held = null;
      return;
    }
    // Chopped ingredient onto a plate on the tile (salads).
    if (held is IngredientItem && held.chopped && item is Plate) {
      if (_addToPlate(item, held.ingredient)) c.held = null;
      return;
    }
    // Pot in hand, plate on tile: pour the soup.
    if (held is Pot && item is Plate && item.isEmpty) {
      if (_pour(held, item)) state.events.add(GameEvent('plated', x: tx, y: ty, chef: c.id));
      return;
    }
    // Plate in hand, pot on tile: scoop the soup.
    if (held is Plate && held.isEmpty && item is Pot) {
      if (_pour(item, held)) state.events.add(GameEvent('plated', x: tx, y: ty, chef: c.id));
      return;
    }
    // Plate in hand, chopped ingredient on tile: add it to the plate.
    if (held is Plate && item is IngredientItem && item.chopped) {
      if (_addToPlate(held, item.ingredient)) {
        t.item = null;
        t.progress = 0;
      }
      return;
    }
    // Pot in hand, chopped ingredient on tile: add it to the pot.
    if (held is Pot && !held.burnt && item is IngredientItem && item.chopped) {
      if (_addToPot(held, item.ingredient)) {
        t.item = null;
        t.progress = 0;
      }
      return;
    }
    // Empty plate onto a clean stack.
    if (held is Plate && held.isEmpty && item is PlateStack && !item.dirty) {
      t.item = PlateStack(count: item.count + 1, dirty: false);
      c.held = null;
      return;
    }
    // Dirty stacks merge.
    if (held is PlateStack && held.dirty && item is PlateStack && item.dirty) {
      t.item = PlateStack(count: item.count + held.count, dirty: true);
      c.held = null;
      return;
    }
  }

  bool _addToPot(Pot pot, Ingredient ing) {
    if (pot.isFull) return false;
    if (pot.cook >= 1) return false;
    if (!Dish.canAdd(pot.contents, ing, cooked: true)) return false;
    pot.contents.add(ing);
    return true;
  }

  bool _addToPlate(Plate plate, Ingredient ing) {
    if (plate.cooked) return false;
    if (!Dish.canAdd(plate.contents, ing, cooked: false)) return false;
    plate.contents.add(ing);
    return true;
  }

  bool _pour(Pot pot, Plate plate) {
    if (pot.state != PotState.cooked || pot.dish == null) return false;
    plate.contents
      ..clear()
      ..addAll(pot.contents);
    plate.cooked = true;
    pot.contents.clear();
    pot.cook = 0;
    pot.burn = 0;
    return true;
  }

  void _trash(Chef c, Item held) {
    switch (held) {
      case Pot():
        held.contents.clear();
        held.cook = 0;
        held.burn = 0;
        held.burnt = false;
      case Plate():
        held.contents.clear();
        held.cooked = false;
      case IngredientItem():
        c.held = null;
      case PlateStack():
      case Extinguisher():
        return;
    }
    state.events.add(GameEvent('trash', chef: c.id));
  }

  void _serve(Chef c, Plate plate, int tx, int ty) {
    final s = state;
    final dish = plate.dish;
    Order? order;
    if (dish != null) {
      for (final o in s.orders) {
        if (o.dish == dish) {
          order = o;
          break;
        }
      }
    }
    c.held = null;
    s.plateReturns.add(Rules.plateReturnSeconds);
    if (order == null) {
      s.wrongServes++;
      s.combo = 1;
      s.events.add(GameEvent('wrong', x: tx, y: ty, chef: c.id));
      return;
    }
    final inOrder = s.orders.first == order;
    s.combo = inOrder ? math.min(Scoring.maxCombo, s.combo + 1) : 1;
    if (s.combo > s.bestCombo) s.bestCombo = s.combo;
    final value = Scoring.serveValue(fraction: order.fraction, combo: s.combo);
    s.tips += value - Scoring.basePoints;
    s.score += value;
    s.served++;
    s.servedByDish[dish!.name] = (s.servedByDish[dish.name] ?? 0) + 1;
    s.orders.remove(order);
    s.events.add(GameEvent('served', x: tx, y: ty, chef: c.id, value: value, text: dish.label));
  }

  // ---------------------------------------------------------------- held action

  void _act(Chef c, Tile t, int tx, int ty, double dt) {
    final held = c.held;
    if (held is Extinguisher) {
      if (t.onFire) {
        c.working = true;
        t.fire -= Rules.sprayPerSecond * dt;
        if (t.fire <= 0) {
          t.fire = 0;
          state.events.add(GameEvent('extinguished', x: tx, y: ty, chef: c.id));
        }
      }
      return;
    }
    if (held != null || t.onFire) return;
    if (t.type == TileType.board) {
      final item = t.item;
      if (item is IngredientItem && !item.chopped) {
        c.working = true;
        t.progress += dt / Rules.chopSeconds;
        if (t.progress >= 1) {
          t.item = IngredientItem(item.ingredient, chopped: true);
          t.progress = 0;
          state.events.add(GameEvent('chopped', x: tx, y: ty, chef: c.id));
        }
      }
    } else if (t.type == TileType.sink) {
      final item = t.item;
      if (item is PlateStack && item.dirty) {
        c.working = true;
        t.progress += dt / Rules.washSeconds;
        if (t.progress >= 1) {
          t.progress = 0;
          t.item = item.count > 1 ? PlateStack(count: item.count - 1, dirty: true) : null;
          _addCleanPlate(tx, ty);
          state.events.add(GameEvent('washed', x: tx, y: ty, chef: c.id));
        }
      }
    }
  }

  void _addCleanPlate(int sinkX, int sinkY) {
    Tile? rack;
    var best = double.infinity;
    for (final (x, y, t) in state.allTiles()) {
      if (t.type != TileType.rack) continue;
      final d = ((x - sinkX) * (x - sinkX) + (y - sinkY) * (y - sinkY)).toDouble();
      if (d < best) {
        best = d;
        rack = t;
      }
    }
    if (rack == null) return;
    final existing = rack.item;
    if (existing == null) {
      rack.item = const PlateStack(count: 1, dirty: false);
    } else if (existing is PlateStack && !existing.dirty) {
      rack.item = PlateStack(count: existing.count + 1, dirty: false);
    }
  }

  // ---------------------------------------------------------------- tiles

  void _stepTiles(double dt) {
    final s = state;
    if (!s.running) return;
    for (final (x, y, t) in s.allTiles()) {
      final item = t.item;
      if (t.type == TileType.stove && item is Pot && !item.burnt && item.dish != null && !t.onFire) {
        if (item.cook < 1) {
          item.cook = math.min(1, item.cook + dt / Rules.cookSeconds);
          if (item.cook >= 1) s.events.add(GameEvent('cooked', x: x, y: y));
        } else {
          item.burn += dt / Rules.burnSeconds;
          if (item.burn >= 1) {
            item.burnt = true;
            item.burn = 1;
            t.fire = 1;
            t.spreadTimer = Rules.fireSpreadSeconds;
            s.burntPots++;
            s.events.add(GameEvent('burnt', x: x, y: y));
          }
        }
      }
      if (t.type == TileType.conveyor && item != null) {
        t.conveyor += dt / Rules.conveyorSeconds;
        if (t.conveyor >= 1) {
          final d = t.conveyorDir!;
          final dest = s.tileAt(x + d.dx, y + d.dy);
          if (dest != null && _acceptFromConveyor(dest, item)) {
            t.item = null;
            t.conveyor = 0;
          } else {
            t.conveyor = 1;
          }
        }
      }
      if (t.onFire) {
        t.spreadTimer -= dt;
        if (t.spreadTimer <= 0) {
          t.spreadTimer = Rules.fireSpreadSeconds;
          _spreadFire(x, y);
        }
      }
    }
    for (var i = s.plateReturns.length - 1; i >= 0; i--) {
      s.plateReturns[i] -= dt;
      if (s.plateReturns[i] <= 0) {
        s.plateReturns.removeAt(i);
        _returnPlate();
      }
    }
  }

  bool _acceptFromConveyor(Tile dest, Item item) {
    if (dest.type == TileType.sink) {
      if (item is PlateStack && item.dirty) {
        final existing = dest.item;
        if (existing == null) {
          dest.item = item;
          return true;
        }
        if (existing is PlateStack && existing.dirty) {
          dest.item = PlateStack(count: existing.count + item.count, dirty: true);
          return true;
        }
      }
      return false;
    }
    if (!dest.type.holdsItems || dest.type == TileType.floor || dest.type == TileType.platform) return false;
    if (dest.item != null) return false;
    if (dest.type == TileType.stove && item is! Pot) return false;
    dest.item = item;
    dest.conveyor = 0;
    dest.progress = 0;
    return true;
  }

  void _spreadFire(int x, int y) {
    final candidates = <Tile>[];
    for (final d in Dir.values) {
      final t = state.tileAt(x + d.dx, y + d.dy);
      if (t == null || t.onFire) continue;
      if (!t.type.holdsItems || t.type == TileType.floor || t.type == TileType.platform) continue;
      candidates.add(t);
    }
    if (candidates.isEmpty) return;
    final t = candidates[rng.nextInt(candidates.length)];
    t.fire = 1;
    t.spreadTimer = Rules.fireSpreadSeconds;
    state.events.add(const GameEvent('fire'));
  }

  void _returnPlate() {
    for (final (_, _, t) in state.allTiles()) {
      if (t.type != TileType.plateReturn) continue;
      final existing = t.item;
      if (existing == null) {
        t.item = const PlateStack(count: 1, dirty: true);
      } else if (existing is PlateStack && existing.dirty) {
        t.item = PlateStack(count: existing.count + 1, dirty: true);
      } else {
        continue;
      }
      state.events.add(const GameEvent('plateReturn'));
      return;
    }
  }
}
