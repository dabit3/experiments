import 'dart:math' as math;

import 'constants.dart';
import 'input.dart';
import 'player.dart';
import 'rng.dart';
import 'sim.dart';
import 'world.dart';

/// Deterministic server-side bot. Every decision derives from the bot's own
/// RNG stream and the simulation state, so the same seed always produces the
/// same match.
class BotBrain {
  BotBrain(this.player, int seed, this.sim, {double? landX, double? landY})
      : rng = Rng(seed) {
    _pickLanding();
    if (landX != null && landY != null) {
      _landX = landX;
      _landY = landY;
    }
  }

  double get landX => _landX;
  double get landY => _landY;

  /// A landing spot on the bus path side of the island that is farthest from
  /// every point in [others]; used to give the human squad a quiet drop.
  static ({double x, double y}) quietLanding(
      Sim sim, Iterable<({double x, double y})> others) {
    Poi? best;
    var bestScore = -1.0;
    for (final poi in sim.world.pois) {
      var minD = double.infinity;
      for (final o in others) {
        final d =
            math.sqrt(math.pow(o.x - poi.x, 2) + math.pow(o.y - poi.y, 2));
        if (d < minD) minD = d;
      }
      if (minD > bestScore) {
        bestScore = minD;
        best = poi;
      }
    }
    if (best == null) return (x: sim.world.centerX, y: sim.world.centerY);
    return (x: best.x, y: best.y);
  }

  final Player player;
  final Rng rng;
  final Sim sim;

  double targetX = 0;
  double targetY = 0;
  double _landX = 0;
  double _landY = 0;
  int _stuckTicks = 0;
  int _landedTick = -1;

  /// Bots loot and harvest for a while after landing and only engage early
  /// when an enemy is close or has already hit them; this keeps the opening
  /// minutes of a match about looting rather than instant eliminations.
  static const int _peacefulTicks = 20 * 40;
  double _lastX = 0;
  double _lastY = 0;
  int _seq = 1;
  int _retargetTick = 0;
  int _lastBuildTick = -1000;
  String _goal = 'idle';
  String get goal => _goal;

  int get pathLength => _path.length;
  int get stuckTicks => _stuckTicks;

  void _pickLanding() {
    final world = sim.world;
    // Land near a point of interest that is reasonably close to the bus path.
    final pois = world.pois;
    if (pois.isEmpty) {
      _landX = world.centerX;
      _landY = world.centerY;
      return;
    }
    final poi = rng.pick(pois);
    final ang = rng.nextDouble() * math.pi * 2;
    final dist = rng.nextDouble() * poi.radius;
    _landX = poi.x + math.cos(ang) * dist;
    _landY = poi.y + math.sin(ang) * dist;
  }

  InputFrame think() {
    final p = player;
    final actions = <GameAction>[];
    var mx = 0.0;
    var my = 0.0;
    var fire = false;
    var sprint = false;
    var aim = p.aim;

    switch (p.state) {
      case PlayerState.inBus:
        final bus = sim.busPosition();
        final dx = _landX - bus.x;
        final dy = _landY - bus.y;
        final along =
            (sim.busX1 - sim.busX0) * dx + (sim.busY1 - sim.busY0) * dy;
        if (along < 0 ||
            sim.busProgress > 0.85 ||
            math.sqrt(dx * dx + dy * dy) < 120) {
          actions.add(const GameAction(ActionType.jump));
        }
      case PlayerState.dropping:
        final dx = _landX - p.x;
        final dy = _landY - p.y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d > 2) {
          mx = dx / d;
          my = dy / d;
        }
        aim = math.atan2(dy, dx);
      case PlayerState.alive:
        final r = _thinkAlive(actions);
        mx = r.mx;
        my = r.my;
        fire = r.fire;
        sprint = r.sprint;
        aim = r.aim;
      case PlayerState.eliminated:
        break;
    }
    return InputFrame(
      seq: _seq++,
      moveX: mx,
      moveY: my,
      aim: aim,
      fire: fire,
      sprint: sprint,
      actions: actions,
    );
  }

  Player? _nearestEnemy(double range) {
    Player? best;
    var bestD = range * range;
    for (final o in sim.players.values) {
      if (!o.alive || o.team == player.team) continue;
      final dx = o.x - player.x;
      final dy = o.y - player.y;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = o;
      }
    }
    return best;
  }

  int _weaponSlot() {
    var best = -1;
    var bestScore = -1;
    for (var i = 1; i < player.inventory.length; i++) {
      final it = player.inventory[i];
      if (it == null || !it.isWeapon) continue;
      final def = it.weapon!.def;
      final ammo = it.loaded + (player.ammo[def.ammo] ?? 0);
      if (ammo <= 0) continue;
      final score =
          def.damageFor(it.rarity) * def.pellets * 10 + it.rarity.index;
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  int _consumableSlot({required bool shield}) {
    for (var i = 1; i < player.inventory.length; i++) {
      final it = player.inventory[i];
      if (it == null || !it.isConsumable) continue;
      final def = it.consumable!;
      if (shield && def.shield > 0 && player.shield < def.shieldCap) return i;
      if (!shield && def.heal > 0 && player.health < def.healCap) return i;
    }
    return -1;
  }

  ({double mx, double my, bool fire, bool sprint, double aim}) _thinkAlive(
      List<GameAction> actions) {
    final p = player;
    final storm = sim.storm;
    var aim = p.aim;
    var fire = false;
    var sprint = false;

    // Stuck detection.
    final moved = (p.x - _lastX).abs() + (p.y - _lastY).abs();
    _lastX = p.x;
    _lastY = p.y;
    if (moved < 0.02 && (p.moveX != 0 || p.moveY != 0)) {
      _stuckTicks++;
    } else {
      _stuckTicks = 0;
    }

    if (_landedTick < 0) _landedTick = sim.tick;
    final settled = sim.tick - _landedTick > _peacefulTicks;
    final provoked = sim.tick - p.lastDamageTick < 20 * 6;
    final enemy = _nearestEnemy(settled ? 40 : (provoked ? 32 : 7));
    final weaponSlot = _weaponSlot();

    // 1. Emergency heal / shield when safe.
    if (enemy == null && !p.busy) {
      if (p.health < 55) {
        final s = _consumableSlot(shield: false);
        if (s > 0) {
          actions.add(GameAction(ActionType.use, slot: s));
          _goal = 'heal';
          return (mx: 0, my: 0, fire: false, sprint: false, aim: aim);
        }
      }
      if (p.shield < 50) {
        final s = _consumableSlot(shield: true);
        if (s > 0) {
          actions.add(GameAction(ActionType.use, slot: s));
          _goal = 'shield';
          return (mx: 0, my: 0, fire: false, sprint: false, aim: aim);
        }
      }
    }
    if (p.busy) {
      return (mx: 0, my: 0, fire: false, sprint: false, aim: aim);
    }

    // 2. Storm avoidance dominates.
    final toCenter = math.sqrt(
        math.pow(storm.targetX - p.x, 2) + math.pow(storm.targetY - p.y, 2));
    final outsideNext = toCenter > storm.targetRadius * 0.75;
    final travelSeconds = math.max(0, toCenter - storm.targetRadius * 0.6) /
        (sim.rules.moveSpeed * sim.rules.sprintMultiplier);
    final urgent =
        p.inStorm || (outsideNext && storm.remaining < travelSeconds * 1.4 + 4);
    final nearChest = p.inStorm ? null : sim.nearestChest(p.x, p.y, 9);
    if (urgent && nearChest == null) {
      _goal = 'storm';
      final ang = rng.nextDouble() * math.pi * 2;
      final r = rng.nextDouble() * storm.targetRadius * 0.5;
      if (sim.tick - _retargetTick > 60 ||
          !_insideCircle(storm.targetX, storm.targetY, storm.targetRadius * 0.7,
              targetX, targetY)) {
        targetX = storm.targetX + math.cos(ang) * r;
        targetY = storm.targetY + math.sin(ang) * r;
        _retargetTick = sim.tick;
      }
      final m = _steer();
      if (enemy != null && weaponSlot > 0) {
        aim = math.atan2(enemy.y - p.y, enemy.x - p.x) +
            (rng.nextDouble() - 0.5) * 0.25;
        if (p.selectedSlot != weaponSlot) {
          actions.add(GameAction(ActionType.select, slot: weaponSlot));
        }
        fire = true;
      } else {
        aim = math.atan2(m.my, m.mx);
      }
      return (mx: m.mx, my: m.my, fire: fire, sprint: true, aim: aim);
    }

    // 3. Fight.
    if (enemy != null && weaponSlot > 0) {
      _goal = 'fight';
      final dx = enemy.x - p.x;
      final dy = enemy.y - p.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      aim =
          math.atan2(dy, dx) + (rng.nextDouble() - 0.5) * (0.06 + dist * 0.004);
      // Defensive wall when hurt and under fire.
      if (p.health + p.shield < 70 &&
          p.materials.any((m) => m >= sim.rules.pieceCost) &&
          sim.tick - _lastBuildTick > 30) {
        final matIndex = _bestMaterial();
        final g = sim.targetTile(p, null, null);
        actions.add(GameAction(ActionType.setMaterial,
            value: Material.values[matIndex].name));
        actions.add(const GameAction(ActionType.setPiece, value: 'wall'));
        actions.add(GameAction(ActionType.place, gx: g.gx, gy: g.gy));
        actions.add(const GameAction(ActionType.buildMode, value: 'off'));
        _lastBuildTick = sim.tick;
      }
      if (p.selectedSlot != weaponSlot || p.buildMode) {
        actions.add(GameAction(ActionType.select, slot: weaponSlot));
      }
      final it = p.inventory[weaponSlot]!;
      // Human-like trigger discipline: bursts with pauses, not every tick.
      fire = it.loaded > 0 &&
          dist < it.weapon!.def.range * 0.9 &&
          (sim.tick ~/ 10) % 3 != 2;
      // Strafe.
      final perp = (rng.nextInt(2) == 0 ? 1 : -1).toDouble();
      var mx = -dy / dist * perp;
      var my = dx / dist * perp;
      if (dist > 22) {
        mx = dx / dist;
        my = dy / dist;
      } else if (dist < 6) {
        mx = -dx / dist;
        my = -dy / dist;
      }
      return (mx: mx, my: my, fire: fire, sprint: false, aim: aim);
    }

    // 4a. Every player harvests a starter stack right after landing.
    final totalMats = p.materials.fold(0, (a, b) => a + b);
    if (totalMats < 60 &&
        nearChest == null &&
        (enemy == null || _distTo(enemy) > 30)) {
      final node = sim.nearestNode(p.x, p.y, 30);
      if (node != null) return _harvest(node, actions);
    }

    // 4b. Fortify: drop a quick wall or ramp once a stack has been gathered.
    if (totalMats >= 30 && sim.tick - _lastBuildTick > 200 && !p.buildMode) {
      final g = sim.targetTile(p, null, null);
      if (sim.canPlaceAt(p, g.gx, g.gy)) {
        _goal = 'build';
        final matIndex = _bestMaterial();
        actions.add(GameAction(ActionType.setMaterial,
            value: Material.values[matIndex].name));
        actions.add(GameAction(ActionType.setPiece,
            value: rng.chance(0.5) ? 'ramp' : 'wall'));
        actions.add(GameAction(ActionType.place, gx: g.gx, gy: g.gy));
        actions.add(const GameAction(ActionType.buildMode, value: 'off'));
        _lastBuildTick = sim.tick;
        return (mx: 0, my: 0, fire: false, sprint: false, aim: aim);
      }
    }

    // 4. Grab loot / chests.
    if (weaponSlot < 0 || _needsLoot() || nearChest != null) {
      var chest = nearChest ?? sim.nearestChest(p.x, p.y, 70);
      if (chest != null && _ignored(chest.x, chest.y)) chest = null;
      var loot = sim.nearestLoot(p.x, p.y, 40);
      if (loot != null && _ignored(loot.x, loot.y)) loot = null;
      final t = _closer(chest?.x, chest?.y, loot?.x, loot?.y);
      if (t != null) {
        _goal = 'loot';
        final key = _lootKey(t.x, t.y);
        if (key == _lootTargetKey) {
          _lootTicks++;
        } else {
          _lootTargetKey = key;
          _lootTicks = 0;
        }
        // Give up on loot that cannot be reached or picked up.
        if (_lootTicks > 160) _ignoredLoot[key] = sim.tick;
        targetX = t.x;
        targetY = t.y;
        final dx = targetX - p.x;
        final dy = targetY - p.y;
        if (dx * dx + dy * dy <
            sim.rules.interactRange * sim.rules.interactRange * 0.6) {
          actions.add(const GameAction(ActionType.interact));
          return (
            mx: 0,
            my: 0,
            fire: false,
            sprint: false,
            aim: math.atan2(dy, dx)
          );
        }
        final m = _steer();
        return (
          mx: m.mx,
          my: m.my,
          fire: false,
          sprint: true,
          aim: math.atan2(m.my, m.mx)
        );
      }
    }

    // 5. Harvest.
    if (totalMats < 240) {
      final node = sim.nearestNode(p.x, p.y, 60);
      if (node != null) return _harvest(node, actions);
    }

    // 6. Occasionally build a practice ramp/wall when holding materials.
    if (totalMats >= 30 &&
        sim.tick - _lastBuildTick > 100 &&
        rng.chance(0.05)) {
      final g = sim.targetTile(p, null, null);
      final matIndex = _bestMaterial();
      actions.add(GameAction(ActionType.setMaterial,
          value: Material.values[matIndex].name));
      actions.add(GameAction(ActionType.setPiece,
          value: rng.chance(0.5) ? 'ramp' : 'wall'));
      actions.add(GameAction(ActionType.place, gx: g.gx, gy: g.gy));
      actions.add(const GameAction(ActionType.buildMode, value: 'off'));
      _lastBuildTick = sim.tick;
    }

    // 7. Wander toward the safe zone / a point of interest.
    _goal = 'roam';
    if (sim.tick - _retargetTick > 160 ||
        _stuckTicks > 20 ||
        (targetX - p.x).abs() + (targetY - p.y).abs() < 4) {
      final ang = rng.nextDouble() * math.pi * 2;
      final r = rng.nextDouble() * math.min(storm.targetRadius * 0.7, 120);
      targetX = storm.targetX + math.cos(ang) * r;
      targetY = storm.targetY + math.sin(ang) * r;
      _retargetTick = sim.tick;
      _stuckTicks = 0;
    }
    final m = _steer();
    sprint = true;
    if (m.mx != 0 || m.my != 0) aim = math.atan2(m.my, m.mx);
    return (mx: m.mx, my: m.my, fire: false, sprint: sprint, aim: aim);
  }

  int _lootTargetKey = 0;
  int _lootTicks = 0;
  final Map<int, int> _ignoredLoot = {};

  int _lootKey(double x, double y) =>
      (x * 10).round() * 100003 + (y * 10).round();

  bool _ignored(double x, double y) {
    final at = _ignoredLoot[_lootKey(x, y)];
    if (at == null) return false;
    if (sim.tick - at > 600) {
      _ignoredLoot.remove(_lootKey(x, y));
      return false;
    }
    return true;
  }

  double _distTo(Player o) =>
      math.sqrt(math.pow(o.x - player.x, 2) + math.pow(o.y - player.y, 2));

  ({double mx, double my, bool fire, bool sprint, double aim}) _harvest(
      ResourceNode node, List<GameAction> actions) {
    final p = player;
    _goal = 'harvest';
    final dx = node.x - p.x;
    final dy = node.y - p.y;
    final d = math.sqrt(dx * dx + dy * dy);
    final aim = math.atan2(dy, dx);
    if (p.selectedSlot != 0 || p.buildMode) {
      actions.add(const GameAction(ActionType.select, slot: 0));
    }
    if (d < sim.rules.harvestRange * 0.9 + node.kind.radius * 0.5) {
      return (mx: 0, my: 0, fire: true, sprint: false, aim: aim);
    }
    targetX = node.x;
    targetY = node.y;
    final m = _steer();
    return (mx: m.mx, my: m.my, fire: false, sprint: true, aim: aim);
  }

  int _bestMaterial() {
    var best = 0;
    for (var i = 2; i >= 0; i--) {
      if (player.materials[i] >= sim.rules.pieceCost) return i;
    }
    return best;
  }

  bool _needsLoot() {
    var weapons = 0;
    var heals = 0;
    for (final it in player.inventory) {
      if (it == null) continue;
      if (it.isWeapon) weapons++;
      if (it.isConsumable) heals++;
    }
    return weapons < 2 || heals < 1;
  }

  bool _insideCircle(double cx, double cy, double r, [double? x, double? y]) {
    final dx = (x ?? player.x) - cx;
    final dy = (y ?? player.y) - cy;
    return dx * dx + dy * dy <= r * r;
  }

  ({double x, double y})? _closer(
      double? ax, double? ay, double? bx, double? by) {
    double d(double? x, double? y) => x == null || y == null
        ? double.infinity
        : (x - player.x) * (x - player.x) + (y - player.y) * (y - player.y);
    final da = d(ax, ay);
    final db = d(bx, by);
    if (da == double.infinity && db == double.infinity) return null;
    return da <= db ? (x: ax!, y: ay!) : (x: bx!, y: by!);
  }

  final List<({double x, double y})> _path = [];
  int _pathTargetKey = -1;
  int _pathTick = -1000;

  /// Breadth-first search over walkable tile centres. Cheap enough to run
  /// whenever the target changes; bounded so a hopeless search stays fast.
  void _ensurePath() {
    final world = sim.world;
    final tgx = world.toTile(targetX);
    final tgy = world.toTile(targetY);
    final key = world.tileKey(tgx, tgy);
    if (key == _pathTargetKey &&
        _path.isNotEmpty &&
        sim.tick - _pathTick < 200) {
      return;
    }
    _pathTargetKey = key;
    _pathTick = sim.tick;
    _path.clear();
    final sgx = world.toTile(player.x);
    final sgy = world.toTile(player.y);
    if (sgx == tgx && sgy == tgy) return;
    final start = world.tileKey(sgx, sgy);
    final prev = <int, int>{start: start};
    final queue = <int>[start];
    var head = 0;
    var found = false;
    while (head < queue.length && queue.length < 3000) {
      final cur = queue[head++];
      if (cur == key) {
        found = true;
        break;
      }
      final cx = cur % world.n;
      final cy = cur ~/ world.n;
      for (final (ox, oy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = cx + ox;
        final ny = cy + oy;
        if (!world.inBounds(nx, ny)) continue;
        final nk = world.tileKey(nx, ny);
        if (prev.containsKey(nk)) continue;
        if (nk != key &&
            sim.blocked(world.tileCenter(nx), world.tileCenter(ny))) {
          continue;
        }
        prev[nk] = cur;
        queue.add(nk);
      }
    }
    if (!found) return;
    var cur = key;
    while (cur != start) {
      _path.insert(0, (
        x: world.tileCenter(cur % world.n),
        y: world.tileCenter(cur ~/ world.n)
      ));
      cur = prev[cur]!;
    }
    if (_path.isNotEmpty) _path[_path.length - 1] = (x: targetX, y: targetY);
  }

  ({double mx, double my}) _steer() {
    final p = player;
    _ensurePath();
    while (_path.length > 1) {
      final w = _path.first;
      if ((w.x - p.x).abs() < 1.2 && (w.y - p.y).abs() < 1.2) {
        _path.removeAt(0);
      } else {
        break;
      }
    }
    final wp = _path.isNotEmpty ? _path.first : (x: targetX, y: targetY);
    var dx = wp.x - p.x;
    var dy = wp.y - p.y;
    final d = math.sqrt(dx * dx + dy * dy);
    if (d < 0.5) return (mx: 0, my: 0);
    dx /= d;
    dy /= d;
    if (_stuckTicks > 6) {
      if (_stuckTicks == 7) _pathTargetKey = -1;
      // Slide sideways around the obstacle; alternate direction over time.
      final side = ((_stuckTicks ~/ 20) % 2 == 0) ? 1 : -1;
      final sx = -dy * side;
      final sy = dx * side;
      return (
        mx: (dx * 0.3 + sx).clamp(-1, 1),
        my: (dy * 0.3 + sy).clamp(-1, 1)
      );
    }
    // Avoid water directly ahead by probing.
    final probeX = p.x + dx * 3;
    final probeY = p.y + dy * 3;
    if (sim.world.terrainAtWorld(probeX, probeY) == Terrain.water) {
      final sx = -dy;
      final sy = dx;
      return (mx: sx, my: sy);
    }
    return (mx: dx, my: dy);
  }
}
