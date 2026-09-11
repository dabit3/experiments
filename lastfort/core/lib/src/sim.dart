import 'dart:math' as math;

import 'constants.dart';
import 'cosmetics.dart';
import 'input.dart';
import 'items.dart';
import 'player.dart';
import 'rng.dart';
import 'world.dart';

/// Something notable that happened during a tick. Broadcast to clients for
/// feed entries, sound and VFX.
class SimEvent {
  const SimEvent(this.type, this.data);
  final String type;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {'e': type, ...data};
}

/// The shrinking storm. Each phase waits, then shrinks toward a target circle
/// chosen inside the current one.
class Storm {
  Storm(this.rules, this.cx, this.cy)
      : radius = rules.stormPhases.first.radius,
        targetX = cx,
        targetY = cy,
        targetRadius = rules.stormPhases.first.radius;

  final Rules rules;
  double cx;
  double cy;
  double radius;
  double targetX;
  double targetY;
  double targetRadius;
  int phase = 0;
  double phaseTime = 0;
  bool shrinking = false;
  double _startX = 0;
  double _startY = 0;
  double _startRadius = 0;
  bool _targetPicked = false;

  StormPhase get current =>
      rules.stormPhases[phase.clamp(0, rules.stormPhases.length - 1)];
  StormPhase get next =>
      rules.stormPhases[(phase + 1).clamp(0, rules.stormPhases.length - 1)];
  bool get finished => phase >= rules.stormPhases.length - 1;
  double get damagePerSecond => current.dps;

  /// Seconds until the current wait or shrink stage ends.
  double get remaining => shrinking
      ? math.max(0, current.shrink - phaseTime)
      : math.max(0, current.wait - phaseTime);

  bool contains(double x, double y) {
    final dx = x - cx;
    final dy = y - cy;
    return dx * dx + dy * dy <= radius * radius;
  }

  void _pickTarget(Rng rng) {
    targetRadius = next.radius;
    final maxShift = math.max(0.0, radius - targetRadius) * 0.8;
    final ang = rng.nextDouble() * math.pi * 2;
    final dist = rng.nextDouble() * maxShift;
    targetX = cx + math.cos(ang) * dist;
    targetY = cy + math.sin(ang) * dist;
    _targetPicked = true;
  }

  void step(double dt, Rng rng) {
    if (finished) return;
    if (!_targetPicked) _pickTarget(rng);
    phaseTime += dt;
    if (!shrinking) {
      if (phaseTime >= current.wait) {
        shrinking = true;
        phaseTime = 0;
        _startX = cx;
        _startY = cy;
        _startRadius = radius;
        if (next.shrink <= 0) _advance(rng);
      }
      return;
    }
    final total = next.shrink;
    final t = total <= 0 ? 1.0 : (phaseTime / total).clamp(0.0, 1.0);
    radius = _startRadius + (targetRadius - _startRadius) * t;
    cx = _startX + (targetX - _startX) * t;
    cy = _startY + (targetY - _startY) * t;
    if (t >= 1) _advance(rng);
  }

  void _advance(Rng rng) {
    phase++;
    shrinking = false;
    phaseTime = 0;
    cx = targetX;
    cy = targetY;
    radius = targetRadius;
    _targetPicked = false;
    if (!finished) _pickTarget(rng);
  }

  Map<String, Object?> toJson() => {
        'cx': _r2(cx),
        'cy': _r2(cy),
        'r': _r2(radius),
        'tx': _r2(targetX),
        'ty': _r2(targetY),
        'tr': _r2(targetRadius),
        'ph': phase,
        'sh': shrinking,
        'rem': _r2(remaining),
        'dps': damagePerSecond,
        'done': finished,
      };

  /// Seconds reported by the last applied snapshot (replicas only).
  double replicatedRemaining = 0;

  void applyJson(Map<String, Object?> j) {
    cx = (j['cx'] as num).toDouble();
    cy = (j['cy'] as num).toDouble();
    radius = (j['r'] as num).toDouble();
    targetX = (j['tx'] as num).toDouble();
    targetY = (j['ty'] as num).toDouble();
    targetRadius = (j['tr'] as num).toDouble();
    phase = (j['ph'] as num).toInt();
    shrinking = j['sh'] as bool;
    replicatedRemaining = (j['rem'] as num).toDouble();
    phaseTime =
        (shrinking ? current.shrink : current.wait) - replicatedRemaining;
  }
}

double _r2(double v) => double.parse(v.toStringAsFixed(2));

class MoveResult {
  const MoveResult(this.x, this.y);
  final double x;
  final double y;
}

/// Per-connection memory of which world deltas a viewer already received.
class ViewerCache {
  final Map<int, int> structures = {};
  final Map<int, int> nodes = {};
  final Map<int, int> chests = {};

  /// When set the next snapshot ignores interest culling for structures so a
  /// (re)connecting client receives the whole built world.
  bool full = true;
}

/// Authoritative match simulation. Clients also instantiate it (from the
/// same seed) so the local player's movement can be predicted with
/// [movePlayer] and the world can be rendered without downloading it.
class Sim {
  Sim({
    required this.rules,
    required this.seed,
    required this.mode,
    World? world,
  })  : rng = Rng(seed ^ 0x5EED),
        world = world ?? World.generate(rules, seed) {
    final path = this.world.busPath(Rng(seed ^ 0xB05));
    busX0 = path.x0;
    busY0 = path.y0;
    busX1 = path.x1;
    busY1 = path.y1;
    storm = Storm(rules, this.world.centerX, this.world.centerY);
    for (final s in this.world.buildings) {
      structures[this.world.tileKey(s.gx, s.gy)] = s;
      if (s.id >= nextStructureId) nextStructureId = s.id + 1;
    }
  }

  final Rules rules;
  final int seed;
  final SquadMode mode;
  final Rng rng;
  final World world;
  late final Storm storm;

  final Map<int, Player> players = {};
  final Map<int, Structure> structures = {};
  final List<Structure> _growing = [];
  final Map<int, LootDrop> drops = {};
  final List<SimEvent> events = [];

  MatchPhase phase = MatchPhase.lobby;
  int tick = 0;
  double busX0 = 0, busY0 = 0, busX1 = 0, busY1 = 0;
  int teamsAtStart = 0;
  int teamsAlive = 0;
  int? winnerTeam;
  int endedAtTick = -1;
  int nextDropId = 1;
  int nextStructureId = 1;
  int _phaseStartTick = 0;
  final List<int> _eliminationOrder = [];
  Map<String, Object?>? summary;

  double get dt => rules.dt;
  double get elapsed => tick * dt;
  int get alivePlayers => players.values.where((p) => !p.eliminated).length;
  int get ticksSincePhaseStart => tick - _phaseStartTick;
  double get busProgress => switch (phase) {
        MatchPhase.lobby => 0,
        MatchPhase.bus =>
          (ticksSincePhaseStart * dt / rules.busDuration).clamp(0.0, 1.0),
        _ => 1,
      };

  ({double x, double y}) busPosition() {
    final t = busProgress;
    return (x: busX0 + (busX1 - busX0) * t, y: busY0 + (busY1 - busY0) * t);
  }

  Player addPlayer({
    required int id,
    required String name,
    required int team,
    required bool isBot,
    required Loadout loadout,
    String platform = 'server',
  }) {
    final p = Player(
      id: id,
      name: name,
      team: team,
      isBot: isBot,
      loadout: loadout,
      platform: platform,
    );
    p.maxHealth = rules.maxHealth;
    final bus = busPosition();
    p.x = bus.x;
    p.y = bus.y;
    players[id] = p;
    return p;
  }

  void start() {
    if (phase != MatchPhase.lobby) return;
    phase = MatchPhase.bus;
    _phaseStartTick = tick;
    final teams = players.values.map((p) => p.team).toSet();
    teamsAtStart = teams.length;
    teamsAlive = teams.length;
    for (final p in players.values) {
      p.state = PlayerState.inBus;
      p.altitude = 1;
    }
    _emit('matchStart', {'seed': seed, 'players': players.length});
  }

  void _emit(String type, Map<String, Object?> data) =>
      events.add(SimEvent(type, {'tick': tick, ...data}));

  // ---------------------------------------------------------------- input

  void applyInput(Player p, InputFrame f) {
    if (f.seq != 0 && f.seq <= p.lastInputSeq) return;
    p.lastInputSeq = f.seq;
    p.aim = f.aim;
    final len = math.sqrt(f.moveX * f.moveX + f.moveY * f.moveY);
    if (len > 1) {
      p.moveX = f.moveX / len;
      p.moveY = f.moveY / len;
    } else {
      p.moveX = f.moveX;
      p.moveY = f.moveY;
    }
    p.sprint = f.sprint;
    p.fireHeld = f.fire;
    for (final a in f.actions) {
      applyAction(p, a);
    }
  }

  void applyAction(Player p, GameAction a) {
    switch (a.type) {
      case ActionType.jump:
        if (p.state == PlayerState.inBus && phase == MatchPhase.bus) {
          _leaveBus(p);
        }
      case ActionType.select:
        if (a.slot >= 0 && a.slot < p.inventory.length) {
          p.selectedSlot = a.slot;
          p.buildMode = false;
          p.reloadRemaining = 0;
        }
      case ActionType.buildMode:
        p.buildMode = a.value != 'off';
        if (p.buildMode) p.reloadRemaining = 0;
      case ActionType.setPiece:
        final piece = a.piece;
        if (piece != null) {
          p.buildPiece = piece;
          p.buildMode = true;
        }
      case ActionType.setMaterial:
        final m = a.material;
        if (m != null) p.buildMaterial = m;
      case ActionType.place:
        if (p.alive) place(p, a.gx, a.gy);
      case ActionType.edit:
        if (p.alive) _edit(p, a.pieceEdit, a.gx, a.gy);
      case ActionType.interact:
        if (p.alive) interact(p);
      case ActionType.use:
        if (p.alive) _startUse(p, a.slot == 0 ? p.selectedSlot : a.slot);
      case ActionType.drop:
        if (p.alive) _dropItem(p, a.slot);
      case ActionType.reload:
        if (p.alive) _startReload(p);
      case ActionType.emote:
        if (p.alive) {
          p.emoteRemaining = 2.5;
          _emit('emote', {'p': p.id});
        }
      case ActionType.spectateNext:
        if (p.eliminated) _spectateNext(p);
      case ActionType.thank:
        if (!p.thankedDriver && phase == MatchPhase.bus) {
          p.thankedDriver = true;
          _emit('thanked', {'p': p.id});
        }
    }
  }

  void _leaveBus(Player p) {
    final bus = busPosition();
    p.x = bus.x;
    p.y = bus.y;
    p.state = PlayerState.dropping;
    p.altitude = 1;
    _emit('jumped', {'p': p.id});
  }

  // -------------------------------------------------------------- building

  ({int gx, int gy}) targetTile(Player p, int? gx, int? gy) {
    if (gx != null && gy != null) return (gx: gx, gy: gy);
    final tx = p.x + math.cos(p.aim) * rules.tileSize * 1.1;
    final ty = p.y + math.sin(p.aim) * rules.tileSize * 1.1;
    return (gx: world.toTile(tx), gy: world.toTile(ty));
  }

  bool _withinBuildRange(Player p, int gx, int gy) {
    final dx = world.tileCenter(gx) - p.x;
    final dy = world.tileCenter(gy) - p.y;
    final maxDist = rules.tileSize * (rules.buildRange + 0.6);
    return dx * dx + dy * dy <= maxDist * maxDist;
  }

  /// Whether [p] could place its current piece on the tile.
  bool canPlaceAt(Player p, int gx, int gy) {
    if (!world.inBounds(gx, gy)) return false;
    if (structures.containsKey(world.tileKey(gx, gy))) return false;
    if (!_withinBuildRange(p, gx, gy)) return false;
    if (p.buildPiece == Piece.wall) {
      for (final o in players.values) {
        if (!o.alive) continue;
        if (world.toTile(o.x) == gx && world.toTile(o.y) == gy) return false;
      }
    }
    return true;
  }

  Structure? place(Player p, int? gxIn, int? gyIn) {
    final t = targetTile(p, gxIn, gyIn);
    if (!canPlaceAt(p, t.gx, t.gy)) return null;
    final m = p.buildMaterial;
    if (p.materials[m.index] < rules.pieceCost) {
      _emit('buildFailed', {'p': p.id, 'r': 'materials'});
      return null;
    }
    p.materials[m.index] -= rules.pieceCost;
    final s = Structure(
      id: nextStructureId++,
      gx: t.gx,
      gy: t.gy,
      piece: p.buildPiece,
      material: m,
      team: p.team,
      hp: math.max(1, m.maxHp ~/ 4),
      maxHp: m.maxHp,
      direction: ((p.aim / (math.pi / 2)).round() % 4 + 4) % 4,
      builtAtTick: tick,
    );
    structures[world.tileKey(t.gx, t.gy)] = s;
    _growing.add(s);
    p.stats.built++;
    p.buildMode = true;
    _emit('placed', {'p': p.id, 's': s.toJson()});
    return s;
  }

  void _edit(Player p, PieceEdit? edit, int? gxIn, int? gyIn) {
    final t = targetTile(p, gxIn, gyIn);
    final s = structures[world.tileKey(t.gx, t.gy)];
    if (s == null || s.team != p.team || edit == null) return;
    if (!_withinBuildRange(p, t.gx, t.gy)) return;
    if (s.piece == Piece.wall) {
      s.edit = edit;
    } else if (s.piece == Piece.ramp) {
      s.direction = (s.direction + 1) % 4;
    } else {
      return;
    }
    s.version++;
    _emit('edited', {'p': p.id, 's': s.toJson()});
  }

  void _growStructures() {
    if (_growing.isEmpty) return;
    _growing.removeWhere((s) {
      if (structures[world.tileKey(s.gx, s.gy)] != s) return true;
      final perTick = (s.maxHp * 0.75 / s.material.buildTime * dt).ceil();
      s.hp = math.min(s.maxHp, s.hp + perTick);
      if (s.hp >= s.maxHp || tick % 5 == 0) s.version++;
      return s.hp >= s.maxHp;
    });
  }

  // -------------------------------------------------------------- inventory

  int _freeSlot(Player p) {
    for (var i = 1; i < p.inventory.length; i++) {
      if (p.inventory[i] == null) return i;
    }
    return -1;
  }

  /// Returns false when nothing could be taken.
  bool giveItem(Player p, Item item) {
    switch (item.type) {
      case ItemType.material:
        final m = item.material!;
        final room = rules.materialCap - p.materials[m.index];
        if (room <= 0) return false;
        p.materials[m.index] += math.min(room, item.count);
        return true;
      case ItemType.ammo:
        p.ammo[item.ammoType!] = (p.ammo[item.ammoType!] ?? 0) + item.count;
        return true;
      case ItemType.consumable:
        for (var i = 1; i < p.inventory.length; i++) {
          final it = p.inventory[i];
          if (it != null &&
              it.isConsumable &&
              it.consumable == item.consumable &&
              it.count < maxStackFor(item)) {
            it.count = math.min(maxStackFor(item), it.count + item.count);
            return true;
          }
        }
        final slot = _freeSlot(p);
        if (slot < 0) return false;
        p.inventory[slot] = item.copy();
        return true;
      case ItemType.weapon:
        final slot = _freeSlot(p);
        if (slot < 0) return false;
        p.inventory[slot] = item.copy();
        if (p.selectedSlot == 0) p.selectedSlot = slot;
        return true;
    }
  }

  void _spawnDrop(double x, double y, Item item) {
    final id = nextDropId++;
    drops[id] = LootDrop(id, x, y, item);
  }

  void _dropItem(Player p, int slot) {
    if (slot <= 0 || slot >= p.inventory.length) return;
    final it = p.inventory[slot];
    if (it == null) return;
    p.inventory[slot] = null;
    _spawnDrop(p.x + math.cos(p.aim) * 1.5, p.y + math.sin(p.aim) * 1.5, it);
    if (p.selectedSlot == slot) p.selectedSlot = 0;
    _emit('dropped', {'p': p.id, 'slot': slot});
  }

  Chest? nearestChest(double x, double y, double range) {
    Chest? best;
    var bestD = range * range;
    for (final c in world.chests) {
      if (c.opened) continue;
      final dx = c.x - x;
      final dy = c.y - y;
      final d = dx * dx + dy * dy;
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  LootDrop? nearestLoot(double x, double y, double range) {
    LootDrop? best;
    var bestD = range * range;
    for (final d in world.floorLoot.followedBy(drops.values)) {
      final dx = d.x - x;
      final dy = d.y - y;
      final dd = dx * dx + dy * dy;
      if (dd < bestD) {
        bestD = dd;
        best = d;
      }
    }
    return best;
  }

  /// Open the nearest chest or pick up the nearest loot in range.
  void interact(Player p) {
    final chest = nearestChest(p.x, p.y, rules.interactRange);
    if (chest != null) {
      chest.opened = true;
      chest.version++;
      p.stats.chests++;
      final contents = World.rollChest(Rng(seed ^ (chest.id * 7919)));
      for (final it in contents) {
        if (!giveItem(p, it)) {
          _spawnDrop(chest.x + (rng.nextDouble() - 0.5) * 2,
              chest.y + (rng.nextDouble() - 0.5) * 2, it);
        }
      }
      _emit('chest', {'p': p.id, 'c': chest.id});
      return;
    }
    final loot = nearestLoot(p.x, p.y, rules.interactRange);
    if (loot != null && giveItem(p, loot.item)) {
      if (drops.remove(loot.id) == null) world.floorLoot.remove(loot);
      _emit('pickup', {'p': p.id, 'l': loot.id, 'item': loot.item.toJson()});
    }
  }

  void _startUse(Player p, int slot) {
    if (p.busy || slot <= 0 || slot >= p.inventory.length) return;
    final it = p.inventory[slot];
    if (it == null || !it.isConsumable) return;
    final def = it.consumable!;
    if (def.heal > 0 && p.health >= def.healCap) return;
    if (def.shield > 0 && p.shield >= def.shieldCap) return;
    p.usingSlot = slot;
    p.useRemaining = def.useTime;
    p.selectedSlot = slot;
    p.buildMode = false;
    _emit('useStart', {'p': p.id, 'k': def.name});
  }

  void _finishUse(Player p) {
    final slot = p.usingSlot;
    p.usingSlot = -1;
    if (slot <= 0 || slot >= p.inventory.length) return;
    final it = p.inventory[slot];
    if (it == null || !it.isConsumable) return;
    final def = it.consumable!;
    if (def.heal > 0) {
      final target = math.min(def.healCap, p.health + def.heal);
      p.health = math.min(p.maxHealth, math.max(p.health, target));
    }
    if (def.shield > 0) {
      final target = math.min(def.shieldCap, p.shield + def.shield);
      p.shield = math.min(rules.maxShield, math.max(p.shield, target));
    }
    it.count--;
    if (it.count <= 0) {
      p.inventory[slot] = null;
      if (p.selectedSlot == slot) p.selectedSlot = 0;
    }
    _emit('used', {'p': p.id, 'k': def.name});
  }

  void _startReload(Player p) {
    final it = p.selectedItem;
    if (it == null || !it.isWeapon || p.busy) return;
    final def = it.weapon!.def;
    if (it.loaded >= def.magazine) return;
    if ((p.ammo[def.ammo] ?? 0) <= 0) return;
    p.reloadRemaining = def.reload;
  }

  void _finishReload(Player p) {
    final it = p.selectedItem;
    if (it == null || !it.isWeapon) return;
    final def = it.weapon!.def;
    final have = p.ammo[def.ammo] ?? 0;
    final take = math.min(have, def.magazine - it.loaded);
    p.ammo[def.ammo] = have - take;
    it.loaded += take;
    _emit('reloaded', {'p': p.id});
  }

  // -------------------------------------------------------------- combat

  void _fireWeapon(Player p, Item it) {
    final def = it.weapon!.def;
    if (it.loaded <= 0) {
      _startReload(p);
      return;
    }
    p.fireCooldown = def.fireInterval;
    it.loaded--;
    p.stats.shotsFired++;
    final shots = <Map<String, Object?>>[];
    var hitAny = false;
    final damage = def.damageFor(it.rarity);
    for (var i = 0; i < def.pellets; i++) {
      final spread =
          (rng.nextDouble() - 0.5) * 2 * def.spread * (p.sprint ? 1.6 : 1);
      final r = _hitscan(
          p, p.aim + spread, def.range, damage, def.structureDamage, def.name);
      if (r.hitPlayer) hitAny = true;
      shots.add({
        'x': _r2(r.x),
        'y': _r2(r.y),
        'h': r.hitPlayer ? 1 : (r.hitStructure ? 2 : 0),
      });
    }
    if (hitAny) p.stats.shotsHit++;
    _emit('shot', {'p': p.id, 'w': def.kind.name, 's': shots});
    if (it.loaded <= 0) _startReload(p);
  }

  ({double x, double y, bool hitPlayer, bool hitStructure}) _hitscan(
    Player shooter,
    double ang,
    double range,
    int damage,
    int structureDamage,
    String weaponName,
  ) {
    final dx = math.cos(ang);
    final dy = math.sin(ang);
    final shooterKey =
        world.tileKey(world.toTile(shooter.x), world.toTile(shooter.y));

    Player? hit;
    var hitDist = range;
    for (final o in players.values) {
      if (o.id == shooter.id || !o.alive || o.team == shooter.team) continue;
      final rx = o.x - shooter.x;
      final ry = o.y - shooter.y;
      final t = rx * dx + ry * dy;
      if (t < 0 || t > hitDist) continue;
      final px = rx - dx * t;
      final py = ry - dy * t;
      final r = rules.playerRadius * 1.15;
      if (px * px + py * py <= r * r) {
        hitDist = t;
        hit = o;
      }
    }

    final step = rules.tileSize / 4;
    var d = 0.0;
    var lastKey = shooterKey;
    while (d < hitDist) {
      d += step;
      final x = shooter.x + dx * d;
      final y = shooter.y + dy * d;
      final gx = world.toTile(x);
      final gy = world.toTile(y);
      if (!world.inBounds(gx, gy)) {
        return (x: x, y: y, hitPlayer: false, hitStructure: false);
      }
      final key = world.tileKey(gx, gy);
      if (key == lastKey) continue;
      lastKey = key;
      final s = structures[key];
      if (s == null) continue;
      final blocks = s.blocksBullets ||
          (s.piece == Piece.wall &&
              s.edit == PieceEdit.window &&
              rng.chance(0.5)) ||
          (s.piece == Piece.roof &&
              hit != null &&
              key == world.tileKey(world.toTile(hit.x), world.toTile(hit.y)) &&
              rng.chance(0.5));
      if (blocks) {
        damageStructure(s, structureDamage, shooter);
        return (x: x, y: y, hitPlayer: false, hitStructure: true);
      }
    }
    if (hit != null) {
      var dmg = damage;
      if (shooter.elevated && !hit.elevated) dmg = (dmg * 1.1).round();
      _damagePlayer(hit, dmg, shooter, weaponName);
      return (x: hit.x, y: hit.y, hitPlayer: true, hitStructure: false);
    }
    return (
      x: shooter.x + dx * hitDist,
      y: shooter.y + dy * hitDist,
      hitPlayer: false,
      hitStructure: false
    );
  }

  bool damageStructure(Structure s, int amount, Player? by) {
    s.hp -= amount;
    s.version++;
    if (s.hp <= 0) {
      structures.remove(world.tileKey(s.gx, s.gy));
      _emit(
          'destroyed', {'id': s.id, 'gx': s.gx, 'gy': s.gy, 'p': by?.id ?? 0});
      return true;
    }
    _emit('structHit', {'id': s.id, 'hp': s.hp});
    return false;
  }

  void _damagePlayer(Player target, int dmg, Player? by, String weaponName) {
    if (!target.alive || dmg <= 0) return;
    var remaining = dmg;
    final absorbed = math.min(target.shield, remaining);
    target.shield -= absorbed;
    remaining -= absorbed;
    target.health -= remaining;
    if (by != null) {
      by.stats.damage += dmg;
      target.lastDamageFrom = by.id;
      target.lastDamageTick = tick;
    }
    _emit('hit', {
      'p': target.id,
      'by': by?.id ?? 0,
      'd': dmg,
      'sh': absorbed > 0,
      'x': _r2(target.x),
      'y': _r2(target.y),
    });
    if (target.health <= 0) {
      target.health = 0;
      _eliminate(target, by, weaponName);
    }
  }

  /// Removes a player from the match (disconnect timeout / leaving). Their
  /// loot drops where they stood and the team may be eliminated as a result.
  void eliminate(Player target, {int byId = 0, String cause = 'left'}) {
    if (target.eliminated) return;
    if (phase == MatchPhase.lobby) {
      players.remove(target.id);
      return;
    }
    _eliminate(target, players[byId], cause);
  }

  void _eliminate(Player target, Player? by, String cause) {
    if (target.eliminated) return;
    target.state = PlayerState.eliminated;
    target.stats.survivedTicks = tick;
    final killer = by ??
        (target.recentlyDamagedBy(tick, rules.tickRate * 8)
            ? players[target.lastDamageFrom]
            : null);
    if (killer != null &&
        killer.id != target.id &&
        killer.team != target.team) {
      killer.stats.kills++;
      target.eliminatedBy = killer.id;
    }
    target.eliminatedWith = cause;
    for (var i = 1; i < target.inventory.length; i++) {
      final it = target.inventory[i];
      if (it != null) {
        _spawnDrop(target.x + (rng.nextDouble() - 0.5) * 2,
            target.y + (rng.nextDouble() - 0.5) * 2, it);
        target.inventory[i] = null;
      }
    }
    for (var m = 0; m < 3; m++) {
      if (target.materials[m] > 0) {
        _spawnDrop(
            target.x + (rng.nextDouble() - 0.5) * 2,
            target.y + (rng.nextDouble() - 0.5) * 2,
            Item.material(Material.values[m], target.materials[m]));
        target.materials[m] = 0;
      }
    }
    for (final a in AmmoType.values) {
      final n = target.ammo[a] ?? 0;
      if (n > 0) {
        _spawnDrop(target.x + (rng.nextDouble() - 0.5) * 2,
            target.y + (rng.nextDouble() - 0.5) * 2, Item.ammo(a, n));
        target.ammo[a] = 0;
      }
    }
    _emit('eliminated', {
      'p': target.id,
      'by': target.eliminatedBy,
      'w': cause,
      'k': killer?.stats.kills ?? 0,
      'alive': alivePlayers,
    });
    _spectateNext(target);
    _checkTeamElimination(target.team);
  }

  Set<int> get _teamsRemaining =>
      players.values.where((p) => !p.eliminated).map((p) => p.team).toSet();

  void _checkTeamElimination(int team) {
    if (players.values.any((p) => p.team == team && !p.eliminated)) return;
    if (_eliminationOrder.contains(team)) return;
    _eliminationOrder.add(team);
    final placement = teamsAlive;
    teamsAlive--;
    for (final p in players.values) {
      if (p.team == team) p.stats.placement = placement;
    }
    _emit('teamOut', {'team': team, 'place': placement});
    if (teamsAlive <= 1 && phase == MatchPhase.playing) _endMatch();
  }

  void _endMatch() {
    phase = MatchPhase.ended;
    endedAtTick = tick;
    final aliveTeams = _teamsRemaining;
    if (aliveTeams.isNotEmpty) {
      winnerTeam = aliveTeams.first;
    } else if (_eliminationOrder.isNotEmpty) {
      winnerTeam = _eliminationOrder.last;
    }
    for (final p in players.values) {
      if (p.team == winnerTeam) p.stats.placement = 1;
      if (p.alive) p.stats.survivedTicks = tick;
      p.stats.xp = matchXp(
        placement: p.stats.placement,
        teams: teamsAtStart,
        kills: p.stats.kills,
        damage: p.stats.damage,
        survivedSeconds: (p.stats.survivedTicks * dt).round(),
      );
    }
    summary = buildSummary();
    _emit('matchEnd', {'winner': winnerTeam});
  }

  /// A stable, platform-independent description of the final result. Every
  /// client receives exactly this object; the e2e test compares them.
  Map<String, Object?> buildSummary() {
    final list = players.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return {
      'seed': seed,
      'mode': mode.name,
      'endTick': endedAtTick,
      'stormPhase': storm.phase,
      'winnerTeam': winnerTeam,
      'teams': teamsAtStart,
      'players': [
        for (final p in list)
          {
            'id': p.id,
            'name': p.name,
            'team': p.team,
            'bot': p.isBot,
            'platform': p.platform,
            'placement': p.stats.placement,
            'kills': p.stats.kills,
            'damage': p.stats.damage,
            'harvested': p.stats.harvested,
            'built': p.stats.built,
            'chests': p.stats.chests,
            'survived': (p.stats.survivedTicks * dt).round(),
            'xp': p.stats.xp,
          },
      ],
    };
  }

  void _spectateNext(Player p) {
    final alive = players.values.where((o) => o.alive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (alive.isEmpty) {
      p.spectating = 0;
      return;
    }
    final mates = alive.where((o) => o.team == p.team).toList();
    final pool = mates.isNotEmpty ? mates : alive;
    final idx = pool.indexWhere((o) => o.id == p.spectating);
    p.spectating = pool[(idx + 1) % pool.length].id;
  }

  // -------------------------------------------------------------- harvest

  ResourceNode? nearestNode(double x, double y, double range) {
    ResourceNode? best;
    var bestD = range * range;
    final g0x = world.toTile(x - range);
    final g1x = world.toTile(x + range);
    final g0y = world.toTile(y - range);
    final g1y = world.toTile(y + range);
    for (var gy = g0y; gy <= g1y; gy++) {
      for (var gx = g0x; gx <= g1x; gx++) {
        for (final n in world.nodesByTile[world.tileKey(gx, gy)] ??
            const <ResourceNode>[]) {
          if (!n.alive) continue;
          final dx = n.x - x;
          final dy = n.y - y;
          final d = dx * dx + dy * dy;
          if (d < bestD) {
            bestD = d;
            best = n;
          }
        }
      }
    }
    return best;
  }

  void _swingPickaxe(Player p) {
    p.fireCooldown = pickaxeCooldown;
    final tx = p.x + math.cos(p.aim) * rules.tileSize;
    final ty = p.y + math.sin(p.aim) * rules.tileSize;

    final gx = world.toTile(tx);
    final gy = world.toTile(ty);
    final s = structures[world.tileKey(gx, gy)];
    final ownTile = gx == world.toTile(p.x) && gy == world.toTile(p.y);
    if (s != null && !(ownTile && s.piece != Piece.wall)) {
      final destroyed = damageStructure(s, pickaxeDamage * 2, p);
      final give = math.min(
          rules.materialCap - p.materials[s.material.index], destroyed ? 6 : 3);
      if (give > 0) {
        p.materials[s.material.index] += give;
        p.stats.harvested += give;
      }
      _emit('swing', {
        'p': p.id,
        'x': _r2(tx),
        'y': _r2(ty),
        'm': s.material.name,
        'g': give
      });
      return;
    }

    final node = nearestNode(tx, ty, rules.harvestRange);
    if (node == null) {
      _emit('swing', {'p': p.id, 'x': _r2(tx), 'y': _r2(ty), 'm': '', 'g': 0});
      return;
    }
    node.hp -= pickaxeDamage;
    node.version++;
    final mat = node.kind.material;
    final room = rules.materialCap - p.materials[mat.index];
    final give = math.min(room, node.kind.yield);
    p.materials[mat.index] += give;
    p.stats.harvested += give;
    if (node.hp <= 0) {
      node.hp = 0;
      _emit('nodeGone', {'n': node.id});
    }
    _emit('swing', {
      'p': p.id,
      'x': _r2(node.x),
      'y': _r2(node.y),
      'm': mat.name,
      'g': give,
      'n': node.id
    });
  }

  // -------------------------------------------------------------- movement

  bool _circleHitsTile(double x, double y, int gx, int gy, double r) {
    final cx = world.tileCenter(gx);
    final cy = world.tileCenter(gy);
    final half = rules.tileSize / 2;
    final ddx = math.max((x - cx).abs() - half, 0.0);
    final ddy = math.max((y - cy).abs() - half, 0.0);
    return ddx * ddx + ddy * ddy < r * r;
  }

  bool blocked(double x, double y) {
    final r = rules.playerRadius;
    final minGx = world.toTile(x - r);
    final maxGx = world.toTile(x + r);
    final minGy = world.toTile(y - r);
    final maxGy = world.toTile(y + r);
    for (var gy = minGy; gy <= maxGy; gy++) {
      for (var gx = minGx; gx <= maxGx; gx++) {
        if (!world.inBounds(gx, gy)) return true;
        final s = structures[world.tileKey(gx, gy)];
        if (s != null && s.blocksMovement && _circleHitsTile(x, y, gx, gy, r)) {
          return true;
        }
        if (s == null &&
            world.terrainAt(gx, gy) == Terrain.water &&
            _circleHitsTile(x, y, gx, gy, r * 0.5)) {
          return true;
        }
        for (final n in world.nodesByTile[world.tileKey(gx, gy)] ??
            const <ResourceNode>[]) {
          // Only large rocks/cars block; trees can be walked past.
          if (!n.alive || n.kind == ResourceKind.tree) continue;
          final dx = n.x - x;
          final dy = n.y - y;
          final rr = n.kind.radius * 0.6 + r;
          if (dx * dx + dy * dy < rr * rr) return true;
        }
      }
    }
    return false;
  }

  /// Pure movement step used by both the server and client prediction.
  MoveResult movePlayer(
      Player p, double mx, double my, bool sprint, double dt) {
    if (mx == 0 && my == 0) return MoveResult(p.x, p.y);
    var speed = rules.moveSpeed * (sprint ? rules.sprintMultiplier : 1);
    if (p.busy) speed *= 0.6;
    final nx = p.x + mx * speed * dt;
    final ny = p.y + my * speed * dt;
    var rx = p.x;
    var ry = p.y;
    if (!blocked(nx, ry)) rx = nx;
    if (!blocked(rx, ny)) ry = ny;
    return MoveResult(rx, ry);
  }

  void _stepDropping(Player p) {
    final freefall = p.altitude > 0.35;
    final speed = freefall ? rules.dropSpeed : rules.glideSpeed;
    final fall =
        (freefall ? 1 / rules.dropDuration : 1 / (rules.dropDuration * 1.6)) *
            dt;
    p.altitude = math.max(0, p.altitude - fall);
    final steer = freefall ? 0.55 : 1.0;
    p.x = (p.x + p.moveX * speed * steer * dt)
        .clamp(rules.tileSize, rules.mapSize - rules.tileSize);
    p.y = (p.y + p.moveY * speed * steer * dt)
        .clamp(rules.tileSize, rules.mapSize - rules.tileSize);
    if (p.altitude <= 0) _land(p);
  }

  void _land(Player p) {
    p.altitude = 0;
    if (blocked(p.x, p.y)) {
      final spot = nearestOpenSpot(p.x, p.y);
      p.x = spot.x;
      p.y = spot.y;
    }
    p.state = PlayerState.alive;
    _emit('landed', {'p': p.id});
  }

  /// Nearest tile centre that a player can stand on, searching outward in
  /// rings. Falls back to the island centre.
  ({double x, double y}) nearestOpenSpot(double x, double y) {
    final gx0 = world.toTile(x);
    final gy0 = world.toTile(y);
    for (var ring = 0; ring < world.n; ring++) {
      for (var gy = gy0 - ring; gy <= gy0 + ring; gy++) {
        for (var gx = gx0 - ring; gx <= gx0 + ring; gx++) {
          if ((gy - gy0).abs() != ring && (gx - gx0).abs() != ring) continue;
          if (!world.inBounds(gx, gy)) continue;
          final cx = world.tileCenter(gx);
          final cy = world.tileCenter(gy);
          if (!blocked(cx, cy)) return (x: cx, y: cy);
        }
      }
    }
    return (x: world.centerX, y: world.centerY);
  }

  // -------------------------------------------------------------- tick

  /// Returns and clears the events accumulated since the last drain
  /// (both from [applyInput] and [step]).
  List<SimEvent> drainEvents() {
    final out = List<SimEvent>.of(events);
    events.clear();
    return out;
  }

  void step() {
    tick++;
    if (phase == MatchPhase.lobby || phase == MatchPhase.ended) return;

    if (phase == MatchPhase.bus) {
      if (ticksSincePhaseStart * dt >= rules.busDuration) {
        for (final p in players.values) {
          if (p.state == PlayerState.inBus) _leaveBus(p);
        }
        phase = MatchPhase.playing;
        _phaseStartTick = tick;
        _emit('busGone', {});
      } else {
        final bus = busPosition();
        for (final p in players.values) {
          if (p.state == PlayerState.inBus) {
            p.x = bus.x;
            p.y = bus.y;
          }
        }
      }
    }
    if (phase == MatchPhase.playing) {
      storm.step(dt, rng);
      _growStructures();
    }

    final ordered = players.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final p in ordered) {
      switch (p.state) {
        case PlayerState.inBus:
          break;
        case PlayerState.dropping:
          _stepDropping(p);
        case PlayerState.alive:
          _stepAlive(p);
        case PlayerState.eliminated:
          if (p.spectating != 0 && !(players[p.spectating]?.alive ?? false)) {
            _spectateNext(p);
          }
      }
    }

    if (phase == MatchPhase.playing) {
      for (final p in ordered) {
        if (!p.alive) continue;
        final inside = storm.contains(p.x, p.y);
        p.inStorm = !inside;
        if (!inside && storm.damagePerSecond > 0) {
          p.stormAccumulator += storm.damagePerSecond * dt;
          if (p.stormAccumulator >= 1) {
            final d = p.stormAccumulator.floor();
            p.stormAccumulator -= d;
            p.health -= d;
            _emit('stormHit', {'p': p.id, 'd': d});
            if (p.health <= 0) {
              p.health = 0;
              _eliminate(p, null, 'the storm');
            }
          }
        } else {
          p.stormAccumulator = 0;
        }
      }
      if (phase == MatchPhase.playing &&
          teamsAtStart > 1 &&
          _teamsRemaining.length <= 1) {
        _endMatch();
      }
    }
  }

  void _stepAlive(Player p) {
    if (phase != MatchPhase.playing && phase != MatchPhase.bus) return;
    p.stats.survivedTicks = tick;
    if (p.fireCooldown > 0) p.fireCooldown = math.max(0, p.fireCooldown - dt);
    if (p.emoteRemaining > 0) {
      p.emoteRemaining = math.max(0, p.emoteRemaining - dt);
    }
    if (p.reloadRemaining > 0) {
      p.reloadRemaining -= dt;
      if (p.reloadRemaining <= 0) {
        p.reloadRemaining = 0;
        _finishReload(p);
      }
    }
    if (p.useRemaining > 0) {
      p.useRemaining -= dt;
      if (p.useRemaining <= 0) {
        p.useRemaining = 0;
        _finishUse(p);
      }
    }

    final moved = movePlayer(p, p.moveX, p.moveY, p.sprint && !p.fireHeld, dt);
    p.x = moved.x;
    p.y = moved.y;

    final here =
        structures[world.tileKey(world.toTile(p.x), world.toTile(p.y))];
    p.elevated = here != null && here.piece == Piece.ramp;
    p.sheltered = here != null && here.piece == Piece.roof;

    if (p.fireHeld && p.fireCooldown <= 0 && !p.busy) {
      if (p.buildMode) {
        place(p, null, null);
        p.fireCooldown = 0.15;
      } else {
        final it = p.selectedItem;
        if (it == null) {
          _swingPickaxe(p);
        } else if (it.isWeapon) {
          _fireWeapon(p, it);
        } else if (it.isConsumable) {
          _startUse(p, p.selectedSlot);
        }
      }
    }
  }

  // -------------------------------------------------------------- snapshot

  /// The player whose surroundings [viewer] receives: themselves while in
  /// play, otherwise the player they are spectating.
  Player interestFocus(Player viewer) {
    final inPlay = viewer.alive ||
        viewer.state == PlayerState.dropping ||
        viewer.state == PlayerState.inBus;
    return inPlay ? viewer : players[viewer.spectating] ?? viewer;
  }

  bool inInterest(Player viewer, double x, double y) {
    final focus = interestFocus(viewer);
    final dx = x - focus.x;
    final dy = y - focus.y;
    final r = rules.interestRadius;
    return dx * dx + dy * dy <= r * r;
  }

  // -------------------------------------------------------------- replica

  /// Applies a server snapshot to this client-side replica. [localId] is the
  /// player whose position is owned by client prediction.
  void applySnapshot(Map<String, Object?> snap, {int localId = 0}) {
    tick = (snap['tick'] as num).toInt();
    final m = snap['match'] as Map<String, Object?>;
    phase = MatchPhase.values.byName(m['phase'] as String);
    teamsAlive = (m['teamsAlive'] as num).toInt();
    winnerTeam = (m['winner'] as num?)?.toInt();
    final bus = m['bus'];
    if (bus is Map<String, Object?>) {
      busX0 = (bus['x0'] as num).toDouble();
      busY0 = (bus['y0'] as num).toDouble();
      busX1 = (bus['x1'] as num).toDouble();
      busY1 = (bus['y1'] as num).toDouble();
      replicatedBusProgress = (bus['t'] as num).toDouble();
      replicatedBusRemaining = (bus['rem'] as num).toDouble();
    }
    storm.applyJson(m['storm'] as Map<String, Object?>);

    final seen = <int>{};
    for (final pj in snap['players'] as List<Object?>) {
      final j = pj as Map<String, Object?>;
      final id = (j['id'] as num).toInt();
      seen.add(id);
      var p = players[id];
      if (p == null) {
        p = Player(
          id: id,
          name: j['n'] as String,
          team: (j['t'] as num).toInt(),
          isBot: j['b'] as bool,
          loadout: Loadout.fromJson(j['ld'] as Map<String, Object?>?),
          platform: j['p'] as String,
        );
        p.maxHealth = rules.maxHealth;
        players[id] = p;
      }
      p.applySnapshotJson(j, keepPosition: id == localId);
      p.lastSeenTick = tick;
    }
    for (final s in snap['structs'] as List<Object?>) {
      final j = s as Map<String, Object?>;
      final gx = (j['gx'] as num).toInt();
      final gy = (j['gy'] as num).toInt();
      final key = world.tileKey(gx, gy);
      final existing = structures[key];
      final id = (j['id'] as num).toInt();
      if (existing == null || existing.id != id) {
        final st = Structure(
          id: id,
          gx: gx,
          gy: gy,
          piece: Piece.values.byName(j['p'] as String),
          material: Material.values.byName(j['m'] as String),
          team: (j['t'] as num).toInt(),
          hp: (j['hp'] as num).toInt(),
          maxHp: (j['max'] as num).toInt(),
          edit: PieceEdit.values.byName(j['e'] as String),
          direction: (j['d'] as num).toInt(),
          builtAtTick: (j['b'] as num).toInt(),
        );
        structures[key] = st;
        if (id >= nextStructureId) nextStructureId = id + 1;
      } else {
        existing.hp = (j['hp'] as num).toInt();
        existing.maxHp = (j['max'] as num).toInt();
        existing.edit = PieceEdit.values.byName(j['e'] as String);
        existing.direction = (j['d'] as num).toInt();
      }
    }
    for (final r in snap['gone'] as List<Object?>) {
      final id = (r as num).toInt();
      structures.removeWhere((_, s) => s.id == id);
    }
    for (final nj in snap['nodes'] as List<Object?>) {
      final j = nj as Map<String, Object?>;
      final id = (j['id'] as num).toInt();
      final node = nodeById(id);
      if (node != null) node.hp = (j['hp'] as num).toInt();
    }
    for (final cj in snap['chests'] as List<Object?>) {
      final j = cj as Map<String, Object?>;
      final id = (j['id'] as num).toInt();
      for (final c in world.chests) {
        if (c.id == id) c.opened = j['o'] as bool;
      }
    }
    final lootList = snap['loot'];
    if (lootList is List<Object?>) {
      final ids = <int>{};
      for (final lj in lootList) {
        final j = lj as Map<String, Object?>;
        final id = (j['id'] as num).toInt();
        ids.add(id);
        if (!drops.containsKey(id)) {
          drops[id] = LootDrop(
            id,
            (j['x'] as num).toDouble(),
            (j['y'] as num).toDouble(),
            Item.fromJson(j['i'] as Map<String, Object?>),
          );
        }
      }
      // Loot in interest range that the server no longer reports is gone.
      final me = players[localId];
      if (me != null) {
        drops.removeWhere(
            (id, d) => !ids.contains(id) && inInterest(me, d.x, d.y));
      }
    }
  }

  double replicatedBusProgress = 0;
  double replicatedBusRemaining = 0;

  Map<int, ResourceNode>? _nodeIndex;
  ResourceNode? nodeById(int id) {
    _nodeIndex ??= {for (final n in world.nodes) n.id: n};
    return _nodeIndex![id];
  }

  /// Builds the snapshot for one viewer. [known] tracks the structure/node/
  /// chest versions this viewer already has so only deltas are sent; it is
  /// mutated in place. Floor loot within interest is sent every time.
  Map<String, Object?> snapshotFor(
    Player viewer,
    ViewerCache known, {
    required List<SimEvent> events,
  }) {
    final focus = interestFocus(viewer);
    final r = rules.interestRadius;
    bool near(double x, double y) {
      final dx = x - focus.x;
      final dy = y - focus.y;
      return dx * dx + dy * dy <= r * r;
    }

    final playerList = <Map<String, Object?>>[];
    for (final p in players.values) {
      final mate = p.team == viewer.team;
      if (p.id == viewer.id ||
          mate ||
          near(p.x, p.y) ||
          p.id == viewer.spectating ||
          p.state == PlayerState.inBus) {
        playerList
            .add(p.toSnapshotJson(full: p.id == viewer.id || p.id == focus.id));
      }
    }
    final structs = <Map<String, Object?>>[];
    for (final s in structures.values) {
      if (s.team == -1 && s.version == 0) continue;
      if (!near(world.tileCenter(s.gx), world.tileCenter(s.gy)) &&
          !known.full) {
        continue;
      }
      final v = known.structures[s.id];
      if (v == null || v != s.version) {
        structs.add(s.toJson());
        known.structures[s.id] = s.version;
      }
    }
    final gone = <int>[];
    for (final id in known.structures.keys.toList()) {
      if (!_structureIds.contains(id)) {
        gone.add(id);
        known.structures.remove(id);
      }
    }
    final nodes = <Map<String, Object?>>[];
    for (final n in world.nodes) {
      if (n.version == 0) continue;
      final v = known.nodes[n.id];
      if (v != n.version) {
        nodes.add({'id': n.id, 'hp': n.hp});
        known.nodes[n.id] = n.version;
      }
    }
    final chests = <Map<String, Object?>>[];
    for (final c in world.chests) {
      if (c.version == 0) continue;
      final v = known.chests[c.id];
      if (v != c.version) {
        chests.add({'id': c.id, 'o': c.opened});
        known.chests[c.id] = c.version;
      }
    }
    final loot = <Map<String, Object?>>[];
    for (final l in world.floorLoot) {
      if (near(l.x, l.y)) loot.add(l.toJson());
    }
    for (final l in drops.values) {
      if (near(l.x, l.y)) loot.add(l.toJson());
    }
    known.full = false;
    return {
      'tick': tick,
      'match': matchStateJson(),
      'players': playerList,
      'structs': structs,
      'gone': gone,
      'nodes': nodes,
      'chests': chests,
      'loot': loot,
      'ev': [for (final e in events) e.toJson()],
    };
  }

  Set<int> get _structureIds => {for (final s in structures.values) s.id};

  Map<String, Object?> matchStateJson() {
    final bus = busPosition();
    return {
      'phase': phase.name,
      'tick': tick,
      'alive': alivePlayers,
      'teamsAlive': teamsAlive,
      'bus': phase == MatchPhase.bus
          ? {
              'x': _r2(bus.x),
              'y': _r2(bus.y),
              'x0': busX0,
              'y0': busY0,
              'x1': busX1,
              'y1': busY1,
              't': double.parse(busProgress.toStringAsFixed(3)),
              'rem': _r2((rules.busDuration - ticksSincePhaseStart * dt)
                  .clamp(0, 999)),
            }
          : null,
      'storm': storm.toJson(),
      'winner': winnerTeam,
    };
  }
}
