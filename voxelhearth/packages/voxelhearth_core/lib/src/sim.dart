import 'dart:math' as math;

import 'blocks.dart';
import 'chunk.dart';
import 'hash.dart';
import 'items.dart';
import 'physics.dart';
import 'protocol.dart';
import 'recipes.dart';
import 'rng.dart';
import 'world.dart';

/// Server -> client event sink. `target` is a player id or null for the room.
typedef Emit = void Function(String? target, Map<String, Object?> msg);

class ChatLine {
  ChatLine(this.tick, this.from, this.text, {this.system = false});
  final int tick;
  final String from;
  final String text;
  final bool system;

  Map<String, Object?> toJson() => {'tick': tick, 'from': from, 'text': text, 'system': system};
}

class PlayerState {
  PlayerState({required this.id, required this.name, required this.platform, this.isBot = false})
    : body = Body(width: Move.playerWidth, height: Move.playerHeight);

  final String id;
  String name;
  final String platform;
  final bool isBot;
  final Body body;
  double yaw = 0, pitch = 0;
  int health = 20, hunger = 20, air = 300;
  int hungerTimer = 0, regenTimer = 0, hurtCooldown = 0;
  double exhaustion = 0;
  double fallStart = double.nan;
  SlotList inv = SlotList(Inventory.size);
  int selected = 0;
  bool sleeping = false;
  List<int>? bedPos;
  bool connected = true;
  bool ready = false;
  int lastSeenTick = 0;
  int placed = 0, broken = 0, crafted = 0, kills = 0, deaths = 0;
  final Set<int> sentChunks = <int>{};
  String? openKind;
  int? openPos;
  bool sneaking = false, sprinting = false;

  // bot state
  int botTimer = 0;
  double botTx = 0, botTz = 0;
  int botTask = 0;

  int get score => placed + broken + crafted * 3 + kills * 5;

  ItemStack get held => inv[selected];

  Map<String, Object?> toSnapshot() => {
    'id': id,
    'x': _r(body.x),
    'y': _r(body.y),
    'z': _r(body.z),
    'yaw': _r(yaw),
    'pitch': _r(pitch),
    'held': held.id,
    'sneak': sneaking,
    'sleep': sleeping,
    'hp': health,
  };

  Map<String, Object?> toInfo() => {
    'id': id,
    'name': name,
    'platform': platform,
    'bot': isBot,
    'connected': connected,
    'ready': ready,
    'score': score,
    'placed': placed,
    'broken': broken,
    'crafted': crafted,
    'kills': kills,
    'deaths': deaths,
  };

  Map<String, Object?> toSave() => {
    'id': id,
    'name': name,
    'platform': platform,
    'x': body.x,
    'y': body.y,
    'z': body.z,
    'yaw': yaw,
    'pitch': pitch,
    'health': health,
    'hunger': hunger,
    'inv': inv.toJson(),
    'selected': selected,
    'bed': bedPos,
    'placed': placed,
    'broken': broken,
    'crafted': crafted,
    'kills': kills,
    'deaths': deaths,
  };

  void loadSave(Map<String, Object?> j) {
    body.setPos(jdouble(j, 'x'), jdouble(j, 'y'), jdouble(j, 'z'));
    yaw = jdouble(j, 'yaw');
    pitch = jdouble(j, 'pitch');
    health = jint(j, 'health', 20);
    hunger = jint(j, 'hunger', 20);
    inv = SlotList.fromJson(j['inv'], Inventory.size);
    selected = jint(j, 'selected');
    final b = j['bed'];
    bedPos = b is List ? b.map((e) => (e as num).toInt()).toList() : null;
    placed = jint(j, 'placed');
    broken = jint(j, 'broken');
    crafted = jint(j, 'crafted');
    kills = jint(j, 'kills');
    deaths = jint(j, 'deaths');
  }
}

double _r(double v) => (v * 1000).roundToDouble() / 1000;

enum MobKind { mossback, hollow, cinderling }

class Mob {
  Mob(this.id, this.kind)
    : body = Body(
        width: kind == MobKind.mossback ? 0.9 : (kind == MobKind.cinderling ? 0.5 : 0.6),
        height: kind == MobKind.mossback ? 1.0 : (kind == MobKind.cinderling ? 0.7 : 1.9),
      );

  final int id;
  final MobKind kind;
  final Body body;
  double yaw = 0;
  int health = 10;
  int timer = 0;
  double tx = 0, tz = 0;
  int attackCooldown = 0;
  int hurtFlash = 0;

  bool get hostile => kind != MobKind.mossback;

  int get maxHealth => switch (kind) {
    MobKind.mossback => 10,
    MobKind.hollow => 16,
    MobKind.cinderling => 8,
  };

  Map<String, Object?> toSnapshot() => {
    'id': id,
    'kind': kind.name,
    'x': _r(body.x),
    'y': _r(body.y),
    'z': _r(body.z),
    'yaw': _r(yaw),
    'hp': health,
    'hurt': hurtFlash > 0,
  };
}

class KilnState {
  ItemStack input = ItemStack.empty;
  ItemStack fuel = ItemStack.empty;
  ItemStack output = ItemStack.empty;
  int burnLeft = 0, burnTotal = 0, cook = 0;

  Map<String, Object?> toJson() => {
    'input': input.toJson(),
    'fuel': fuel.toJson(),
    'output': output.toJson(),
    'burnLeft': burnLeft,
    'burnTotal': burnTotal,
    'cook': cook,
    'cookTotal': Recipes.smeltTicks,
  };

  static KilnState fromJson(Map<String, Object?> j) {
    final k = KilnState();
    k.input = ItemStack.fromJson(j['input']);
    k.fuel = ItemStack.fromJson(j['fuel']);
    k.output = ItemStack.fromJson(j['output']);
    k.burnLeft = jint(j, 'burnLeft');
    k.burnTotal = jint(j, 'burnTotal');
    k.cook = jint(j, 'cook');
    return k;
  }
}

/// One room = one persistent world plus the players inside it. Pure logic:
/// no sockets, no timers. The host process calls [tick] 20 times a second
/// and [handle] for each client message.
class Room {
  Room({
    required this.code,
    required this.name,
    required this.seed,
    required this.emit,
    this.mode = GameMode.survival,
    this.durationTicks = 0,
    this.freezeTime = false,
    int startTime = 1000,
    this.spawnMobs = true,
    this.viewChunks = 4,
    this.cheats = false,
  }) : world = World(seed),
       rng = Rng(seed ^ 0x5eed),
       timeOfDay = startTime {
    physics = Physics(world);
    spawn = world.gen.findSpawn();
    _fixSpawn();
  }

  final String code;
  String name;
  final int seed;
  final Emit emit;
  String mode;
  int durationTicks;
  bool freezeTime;
  bool spawnMobs;
  int viewChunks;

  /// Allows `give` in survival; enabled by the server's test mode.
  final bool cheats;

  final World world;
  late final Physics physics;
  final Rng rng;
  final Map<String, PlayerState> players = <String, PlayerState>{};
  final Map<int, Mob> mobs = <int, Mob>{};
  final Map<int, SlotList> chests = <int, SlotList>{};
  final Map<int, KilnState> kilns = <int, KilnState>{};
  final List<ChatLine> chat = <ChatLine>[];
  String phase = Phase.lobby;
  String? hostId;
  int tick = 0;
  int timeOfDay;
  int matchEndTick = 0;
  int matchStartTick = 0;
  late List<int> spawn;
  int _nextMobId = 1;
  int _botCounter = 0;
  bool dirty = false;

  static const botNames = ['Ashwick', 'Bramble', 'Cinder', 'Dunmore', 'Ember', 'Fennel', 'Gorse', 'Hollis'];

  void _fixSpawn() {
    var y = spawn[1];
    bool solid(int yy) => Registry.block(world.get(spawn[0], yy, spawn[2])).solid;
    while (y < WorldConst.height - 2 && (solid(y) || solid(y + 1))) {
      y++;
    }
    spawn = [spawn[0], y, spawn[2]];
  }

  bool get isDay => timeOfDay < 12500 || timeOfDay > 23500;
  bool get isNight => timeOfDay >= 13000 && timeOfDay <= 23000;
  int get humanCount => players.values.where((p) => !p.isBot && p.connected).length;

  // ---------------------------------------------------------------- players

  PlayerState join(String id, String name, String platform, {Map<String, Object?>? saved}) {
    var p = players[id];
    if (p == null) {
      p = PlayerState(id: id, name: name, platform: platform);
      if (saved != null) {
        p.loadSave(saved);
      } else {
        _placeAtSpawn(p);
        if (mode == GameMode.survival) _starterKit(p);
      }
      players[id] = p;
      hostId ??= id;
    }
    p.connected = true;
    p.lastSeenTick = tick;
    p.sentChunks.clear();
    emit(id, {
      't': Msg.roomJoined,
      'code': code,
      'name': name,
      'roomName': this.name,
      'seed': seed,
      'mode': mode,
      'phase': phase,
      'time': timeOfDay,
      'freezeTime': freezeTime,
      'durationTicks': durationTicks,
      'tick': tick,
      'you': id,
      'host': hostId,
      'spawn': spawn,
      'x': p.body.x,
      'y': p.body.y,
      'z': p.body.z,
      'yaw': p.yaw,
      'pitch': p.pitch,
      'players': players.values.map((q) => q.toInfo()).toList(),
      'chat': chat.map((c) => c.toJson()).toList(),
      'matchEndTick': matchEndTick,
    });
    _sendInventory(p);
    _sendStats(p);
    _streamChunks(p);
    emit(null, {'t': Msg.playerJoined, 'player': p.toInfo()});
    _system('${p.name} joined from ${p.platform}');
    dirty = true;
    return p;
  }

  void disconnect(String id) {
    final p = players[id];
    if (p == null) return;
    p.connected = false;
    p.openKind = null;
    _system('${p.name} disconnected');
    _broadcastRoomState();
    if (hostId == id) _pickHost();
  }

  void leave(String id) {
    final p = players.remove(id);
    if (p == null) return;
    emit(null, {'t': Msg.playerLeft, 'id': id});
    _system('${p.name} left');
    if (hostId == id) _pickHost();
    _broadcastRoomState();
    dirty = true;
  }

  void _pickHost() {
    final h = players.values.where((p) => !p.isBot && p.connected).firstOrNull;
    hostId = h?.id ?? players.values.where((p) => !p.isBot).firstOrNull?.id;
    _broadcastRoomState();
  }

  void _placeAtSpawn(PlayerState p) {
    final bed = p.bedPos;
    if (bed != null && world.peek(bed[0], bed[1], bed[2]) == Ids.bed) {
      p.body.setPos(bed[0] + 0.5, bed[1] + 0.6, bed[2] + 0.5);
      return;
    }
    p.body.setPos(spawn[0] + 0.5, spawn[1].toDouble(), spawn[2] + 0.5);
    p.body.vx = p.body.vy = p.body.vz = 0;
  }

  void _starterKit(PlayerState p) {
    p.inv.add(const ItemStack(Ids.woodAxe, 1));
    p.inv.add(const ItemStack(Ids.torch, 8));
    p.inv.add(const ItemStack(Ids.apple, 3));
  }

  PlayerState addBot() {
    final name = 'Bot ${botNames[_botCounter % botNames.length]}';
    _botCounter++;
    final id = 'bot-$code-$_botCounter';
    final p = PlayerState(id: id, name: name, platform: Platform.bot, isBot: true);
    _placeAtSpawn(p);
    p.body.x += (rng.nextInt(5) - 2);
    p.body.z += (rng.nextInt(5) - 2);
    _unstick(p.body);
    p.inv.add(const ItemStack(Ids.planks, 64));
    p.inv.add(const ItemStack(Ids.torch, 16));
    p.inv.add(const ItemStack(Ids.stonePick, 1));
    p.ready = true;
    players[id] = p;
    emit(null, {'t': Msg.playerJoined, 'player': p.toInfo()});
    _system('$name joined the room');
    _broadcastRoomState();
    return p;
  }

  void removeBot() {
    final bot = players.values.where((p) => p.isBot).lastOrNull;
    if (bot != null) leave(bot.id);
  }

  void _unstick(Body b) {
    var guard = 0;
    while (physics.blocked(b, b.x, b.y, b.z) && guard++ < 60) {
      b.y += 1;
    }
  }

  // ---------------------------------------------------------------- messages

  void handle(String pid, Map<String, Object?> m) {
    final p = players[pid];
    if (p == null) return;
    p.lastSeenTick = tick;
    final t = jstr(m, 't');
    switch (t) {
      case Msg.move:
        _onMove(p, m);
      case Msg.breakBlock:
        _onBreak(p, jint(m, 'x'), jint(m, 'y'), jint(m, 'z'));
      case Msg.placeBlock:
        _onPlace(p, jint(m, 'x'), jint(m, 'y'), jint(m, 'z'), jint(m, 'nx'), jint(m, 'ny'), jint(m, 'nz'));
      case Msg.interact:
        _onInteract(p, jint(m, 'x'), jint(m, 'y'), jint(m, 'z'));
      case Msg.selectSlot:
        p.selected = jint(m, 'slot').clamp(0, Inventory.hotbarSize - 1);
      case Msg.moveItem:
        _onMoveItem(p, m);
      case Msg.craft:
        _onCraft(p, jints(m, 'grid'), jint(m, 'n', 2), jint(m, 'count', 1));
      case Msg.eat:
        _onEat(p);
      case Msg.attack:
        _onAttack(p, jint(m, 'id'));
      case Msg.sleep:
        _onSleep(p, jint(m, 'x'), jint(m, 'y'), jint(m, 'z'));
      case Msg.chat:
        _onChat(p, jstr(m, 'text'));
      case Msg.requestChunks:
        _streamChunks(p);
      case Msg.startMatch:
        if (pid == hostId) startMatch();
      case Msg.endMatch:
        if (pid == hostId) endMatch();
      case Msg.backToLobby:
        if (pid == hostId) backToLobby();
      case Msg.roomSettings:
        if (pid == hostId) _onSettings(m);
      case Msg.setMode:
        if (pid == hostId) setMode(jstr(m, 'mode', mode));
      case Msg.addBot:
        if (pid == hostId) addBot();
      case Msg.removeBot:
        if (pid == hostId) removeBot();
      case 'ready':
        p.ready = jbool(m, 'ready', true);
        _broadcastRoomState();
      case 'close_ui':
        p.openKind = null;
        p.openPos = null;
      case 'kiln_put':
        _onKilnPut(p, m);
      case 'chest_put':
        _onChestPut(p, m);
      case 'drop_item':
        _onDrop(p, jint(m, 'slot'), jint(m, 'count', 1));
      case 'give':
        if (mode == GameMode.creative || cheats) _give(p, jint(m, 'id'), jint(m, 'count', 1), jint(m, 'slot', -1));
      case 'respawn':
        if (p.health <= 0) _respawn(p);
      case 'set_time':
        if (pid == hostId) setTime(jint(m, 'time'));
      case 'rename_room':
        if (pid == hostId) {
          name = jstr(m, 'name', name).trim();
          _broadcastRoomState();
        }
      default:
        emit(pid, {'t': Msg.error, 'code': 'unknown', 'msg': 'unknown message $t'});
    }
  }

  void _onSettings(Map<String, Object?> m) {
    if (m.containsKey('mode')) setMode(jstr(m, 'mode', mode));
    if (m.containsKey('durationTicks')) durationTicks = jint(m, 'durationTicks', durationTicks).clamp(0, 24000 * 10);
    if (m.containsKey('freezeTime')) freezeTime = jbool(m, 'freezeTime', freezeTime);
    if (m.containsKey('spawnMobs')) spawnMobs = jbool(m, 'spawnMobs', spawnMobs);
    if (m.containsKey('name')) name = jstr(m, 'name', name);
    _broadcastRoomState();
    dirty = true;
  }

  void setMode(String newMode) {
    if (newMode != GameMode.creative && newMode != GameMode.survival) return;
    mode = newMode;
    for (final p in players.values) {
      p.body.flying = false;
      if (mode == GameMode.creative) {
        p.health = 20;
        p.hunger = 20;
        _sendStats(p);
      }
    }
    _system('Game mode set to $mode');
    _broadcastRoomState();
    dirty = true;
  }

  void setTime(int t) {
    timeOfDay = t % WorldConst.dayTicks;
    emit(null, {'t': Msg.timeSet, 'time': timeOfDay, 'tick': tick});
  }

  void _onMove(PlayerState p, Map<String, Object?> m) {
    if (p.health <= 0) return;
    final nx = jdouble(m, 'x'), ny = jdouble(m, 'y'), nz = jdouble(m, 'z');
    final dx = nx - p.body.x, dz = nz - p.body.z, dy = ny - p.body.y;
    final d2 = dx * dx + dz * dz + dy * dy;
    // Reject teleports (allow generous slack for lag bursts and flying).
    if (d2 > 30 * 30) {
      emit(p.id, {'t': Msg.teleport, 'x': p.body.x, 'y': p.body.y, 'z': p.body.z});
      return;
    }
    if (mode != GameMode.creative && !p.body.inWater) {
      final onGround = jbool(m, 'ground', true);
      if (!onGround && p.fallStart.isNaN) {
        p.fallStart = p.body.y;
      } else if (!onGround && ny > p.fallStart) {
        p.fallStart = ny;
      }
      if (onGround && !p.fallStart.isNaN) {
        final fall = p.fallStart - ny;
        p.fallStart = double.nan;
        final inWater = physics.bodyInFluid(p.body);
        if (fall > 3.5 && !inWater) _damage(p, (fall - 3).floor(), 'fell from a high place');
      }
    }
    p.body.setPos(nx, ny, nz);
    p.body.vx = jdouble(m, 'vx');
    p.body.vy = jdouble(m, 'vy');
    p.body.vz = jdouble(m, 'vz');
    p.yaw = jdouble(m, 'yaw');
    p.pitch = jdouble(m, 'pitch');
    p.sneaking = jbool(m, 'sneak');
    p.sprinting = jbool(m, 'sprint');
    p.body.flying = jbool(m, 'fly') && mode == GameMode.creative;
    if (p.sprinting) p.exhaustion += 0.02;
    if (p.sleeping && d2 > 0.01) p.sleeping = false;
    _streamChunks(p);
  }

  bool _inReach(PlayerState p, int x, int y, int z) {
    final ex = p.body.x, ey = p.body.y + Move.eyeHeight, ez = p.body.z;
    final dx = x + 0.5 - ex, dy = y + 0.5 - ey, dz = z + 0.5 - ez;
    return dx * dx + dy * dy + dz * dz <= (Move.reach + 1.5) * (Move.reach + 1.5);
  }

  void _onBreak(PlayerState p, int x, int y, int z) {
    if (phase != Phase.playing || p.health <= 0) return;
    if (!_inReach(p, x, y, z)) return;
    final id = world.peek(x, y, z);
    if (id == Ids.air) return;
    final def = Registry.block(id);
    if (def.hardness < 0 && mode != GameMode.creative) return;
    if (def.fluid) return;
    if (mode == GameMode.survival) {
      if (def.tool != ToolClass.none && Registry.canHarvest(id, p.held.id)) {
        _giveDrop(p, def);
      } else if (def.tool == ToolClass.none || def.minTier == ToolTier.none) {
        _giveDrop(p, def);
      }
      p.exhaustion += 0.005;
    }
    _setBlock(x, y, z, Ids.air, p.id);
    _onBlockRemoved(x, y, z, id);
    p.broken++;
    _sendStats(p);
    emit(null, {'t': Msg.effect, 'kind': 'break', 'x': x, 'y': y, 'z': z, 'id': id});
    // Gravity for sand/gravel above.
    _settleAbove(x, y + 1, z);
    _dropDecorations(x, y + 1, z);
    _sendInventory(p);
    dirty = true;
  }

  void _giveDrop(PlayerState p, BlockDef def) {
    var count = def.dropCount;
    if (def.id == Ids.leaves || def.id == Ids.frostLeaves) {
      count = rng.chance(0.08) ? 1 : 0;
    } else if (def.id == Ids.tallGrass) {
      count = rng.chance(0.25) ? 1 : 0;
    }
    if (count <= 0) return;
    final rest = p.inv.add(ItemStack(def.dropId, count), order: Inventory.preferredFillOrder);
    if (rest.isNotEmpty) {
      emit(p.id, {'t': Msg.effect, 'kind': 'inventory_full'});
    }
  }

  void _onBlockRemoved(int x, int y, int z, int id) {
    final key = BlockPos.key(x, y, z);
    if (id == Ids.chest) {
      final c = chests.remove(key);
      if (c != null) {
        // Spill the contents into the nearest breaker: contents lost is harsh;
        // instead hand them to whoever is closest.
        final near = _nearestPlayer(x + 0.5, z + 0.5);
        if (near != null) {
          for (final s in c.slots) {
            if (s.isNotEmpty) near.inv.add(s);
          }
          _sendInventory(near);
        }
      }
    } else if (id == Ids.kiln) {
      final k = kilns.remove(key);
      if (k != null) {
        final near = _nearestPlayer(x + 0.5, z + 0.5);
        if (near != null) {
          for (final s in [k.input, k.fuel, k.output]) {
            if (s.isNotEmpty) near.inv.add(s);
          }
          _sendInventory(near);
        }
      }
    } else if (id == Ids.bed) {
      for (final p in players.values) {
        final b = p.bedPos;
        if (b != null && b[0] == x && b[1] == y && b[2] == z) p.bedPos = null;
      }
    }
    for (final p in players.values) {
      if (p.openPos == key) {
        p.openKind = null;
        p.openPos = null;
        emit(p.id, {'t': Msg.openUi, 'kind': ContainerKind.inventory});
      }
    }
  }

  void _settleAbove(int x, int y, int z) {
    var yy = y;
    while (yy < WorldConst.height) {
      final id = world.peek(x, yy, z);
      if (id != Ids.sand && id != Ids.gravel) break;
      var ty = yy;
      while (ty - 1 >= 0 && !world.isSolid(x, ty - 1, z) && !Registry.block(world.peek(x, ty - 1, z)).fluid) {
        ty--;
      }
      if (ty != yy) {
        _setBlock(x, yy, z, Ids.air, null);
        _setBlock(x, ty, z, id, null);
      }
      yy++;
    }
  }

  void _dropDecorations(int x, int y, int z) {
    final id = world.peek(x, y, z);
    final def = Registry.block(id);
    if (def.decoration && id != Ids.torch && id != Ids.lantern) {
      _setBlock(x, y, z, Ids.air, null);
    } else if (id == Ids.cactus) {
      _setBlock(x, y, z, Ids.air, null);
      _dropDecorations(x, y + 1, z);
    }
  }

  void _onPlace(PlayerState p, int x, int y, int z, int nx, int ny, int nz) {
    if (phase != Phase.playing || p.health <= 0) return;
    if (!_inReach(p, x, y, z)) return;
    if (y < 1 || y >= WorldConst.height) return;
    final held = p.held;
    if (held.isEmpty || !Registry.isBlock(held.id)) return;
    final target = world.peek(x, y, z);
    if (!Registry.block(target).replaceable) return;
    final def = Registry.block(held.id);
    if (def.solid) {
      for (final q in players.values) {
        if (q.connected && q.health > 0 && physics.blockOverlaps(q.body, x, y, z)) return;
      }
      for (final mob in mobs.values) {
        if (physics.blockOverlaps(mob.body, x, y, z)) return;
      }
    }
    if (def.decoration && def.id != Ids.lantern) {
      // Decorations need support below (torches also allow wall mounting).
      final below = world.isSolid(x, y - 1, z);
      if (!below && !(def.id == Ids.torch && (nx != 0 || nz != 0))) return;
    }
    if (mode == GameMode.survival) {
      p.inv[p.selected] = held.withCount(held.count - 1);
    }
    _setBlock(x, y, z, held.id, p.id);
    if (held.id == Ids.chest) chests[BlockPos.key(x, y, z)] = SlotList(27);
    if (held.id == Ids.kiln) kilns[BlockPos.key(x, y, z)] = KilnState();
    if (held.id == Ids.sand || held.id == Ids.gravel) _settleAbove(x, y, z);
    p.placed++;
    _sendStats(p);
    emit(null, {'t': Msg.effect, 'kind': 'place', 'x': x, 'y': y, 'z': z, 'id': held.id});
    _sendInventory(p);
    dirty = true;
  }

  void _setBlock(int x, int y, int z, int id, String? by) {
    if (!world.set(x, y, z, id)) return;
    emit(null, {'t': Msg.blockSet, 'x': x, 'y': y, 'z': z, 'id': id, 'by': by, 'tick': tick});
    dirty = true;
  }

  void _onInteract(PlayerState p, int x, int y, int z) {
    if (phase != Phase.playing || p.health <= 0) return;
    if (!_inReach(p, x, y, z)) return;
    final id = world.peek(x, y, z);
    final key = BlockPos.key(x, y, z);
    switch (id) {
      case Ids.workbench:
        p.openKind = ContainerKind.workbench;
        p.openPos = key;
        emit(p.id, {'t': Msg.openUi, 'kind': ContainerKind.workbench, 'x': x, 'y': y, 'z': z});
      case Ids.chest:
        final c = chests.putIfAbsent(key, () => SlotList(27));
        p.openKind = ContainerKind.chest;
        p.openPos = key;
        emit(p.id, {'t': Msg.openUi, 'kind': ContainerKind.chest, 'x': x, 'y': y, 'z': z});
        emit(p.id, {'t': Msg.container, 'kind': ContainerKind.chest, 'pos': key, 'slots': c.toJson()});
      case Ids.kiln:
        final k = kilns.putIfAbsent(key, KilnState.new);
        p.openKind = ContainerKind.kiln;
        p.openPos = key;
        emit(p.id, {'t': Msg.openUi, 'kind': ContainerKind.kiln, 'x': x, 'y': y, 'z': z});
        emit(p.id, {'t': Msg.container, 'kind': ContainerKind.kiln, 'pos': key, 'kiln': k.toJson()});
      case Ids.bed:
        _onSleep(p, x, y, z);
      default:
        break;
    }
  }

  void _onSleep(PlayerState p, int x, int y, int z) {
    if (world.peek(x, y, z) != Ids.bed) return;
    p.bedPos = [x, y, z];
    if (!isNight) {
      emit(p.id, {'t': Msg.effect, 'kind': 'toast', 'text': 'Spawn point set. You can only sleep at night.'});
      return;
    }
    final hostileNear = mobs.values.any((m) => m.hostile && _dist2(m.body, p.body) < 8 * 8);
    if (hostileNear) {
      emit(p.id, {'t': Msg.effect, 'kind': 'toast', 'text': 'You may not rest now; there are creatures nearby.'});
      return;
    }
    p.sleeping = true;
    emit(p.id, {'t': Msg.effect, 'kind': 'toast', 'text': 'Spawn point set. Sleeping...'});
    _checkSleep();
  }

  void _checkSleep() {
    final humans = players.values.where((p) => !p.isBot && p.connected && p.health > 0).toList();
    if (humans.isEmpty) return;
    if (humans.every((p) => p.sleeping)) {
      timeOfDay = 1000;
      for (final p in humans) {
        p.sleeping = false;
      }
      for (final m in mobs.values.where((m) => m.hostile).toList()) {
        mobs.remove(m.id);
      }
      emit(null, {'t': Msg.timeSet, 'time': timeOfDay, 'tick': tick});
      _system('Everyone slept through the night. A new day dawns.');
    }
  }

  void _onMoveItem(PlayerState p, Map<String, Object?> m) {
    // Generic slot move inside the player's own inventory (a==b swap/merge).
    final from = jint(m, 'from'), to = jint(m, 'to');
    final count = jint(m, 'count', -1);
    if (from < 0 || from >= Inventory.size || to < 0 || to >= Inventory.size || from == to) return;
    final a = p.inv[from], b = p.inv[to];
    if (a.isEmpty) return;
    final moving = count > 0 && count < a.count ? a.withCount(count) : a;
    if (b.isEmpty) {
      p.inv[to] = moving;
      p.inv[from] = a.withCount(a.count - moving.count);
    } else if (a.sameKind(b) && b.count < b.maxStack) {
      final take = math.min(moving.count, b.maxStack - b.count);
      p.inv[to] = b.withCount(b.count + take);
      p.inv[from] = a.withCount(a.count - take);
    } else if (moving.count == a.count) {
      p.inv[to] = a;
      p.inv[from] = b;
    }
    _sendInventory(p);
    dirty = true;
  }

  void _onCraft(PlayerState p, List<int> grid, int n, int count) {
    if (phase != Phase.playing || p.health <= 0) return;
    if (n != 2 && n != 3) return;
    if (grid.length != n * n) return;
    if (n == 3 && p.openKind != ContainerKind.workbench) return;
    final recipe = Recipes.match(grid, n);
    if (recipe == null) {
      emit(p.id, {'t': Msg.error, 'code': 'no_recipe', 'msg': 'No recipe matches that grid'});
      return;
    }
    final times = count.clamp(1, 64);
    var made = 0;
    for (var i = 0; i < times; i++) {
      final need = <int, int>{};
      for (final id in grid) {
        if (id != 0) need[id] = (need[id] ?? 0) + 1;
      }
      if (mode == GameMode.survival) {
        if (need.entries.any((e) => p.inv.countOf(e.key) < e.value)) break;
        for (final e in need.entries) {
          p.inv.remove(e.key, e.value);
        }
      }
      final rest = p.inv.add(recipe.result, order: Inventory.preferredFillOrder);
      if (rest.isNotEmpty) {
        // give back what we could not fit
        break;
      }
      made++;
    }
    if (made > 0) {
      p.crafted += made;
      emit(p.id, {'t': Msg.effect, 'kind': 'craft', 'id': recipe.result.id, 'count': recipe.result.count * made});
      emit(null, {'t': Msg.roomState, ...roomStateJson()});
    }
    _sendInventory(p);
    dirty = true;
  }

  void _onEat(PlayerState p) {
    if (p.health <= 0) return;
    final held = p.held;
    final def = held.def;
    if (held.isEmpty || def.food <= 0) return;
    if (p.hunger >= 20 && mode == GameMode.survival) return;
    if (mode == GameMode.survival) {
      p.inv[p.selected] = held.withCount(held.count - 1);
      p.hunger = math.min(20, p.hunger + def.food);
    }
    emit(p.id, {'t': Msg.effect, 'kind': 'eat', 'id': held.id});
    _sendInventory(p);
    _sendStats(p);
  }

  void _onAttack(PlayerState p, int mobId) {
    if (phase != Phase.playing || p.health <= 0) return;
    final mob = mobs[mobId];
    if (mob == null) return;
    if (_dist2(mob.body, p.body) > (Move.reach + 1) * (Move.reach + 1)) return;
    final dmg = p.held.def.attack;
    mob.health -= dmg;
    mob.hurtFlash = 6;
    final dx = mob.body.x - p.body.x, dz = mob.body.z - p.body.z;
    final len = math.sqrt(dx * dx + dz * dz) + 1e-6;
    mob.body.vx += dx / len * 6;
    mob.body.vz += dz / len * 6;
    mob.body.vy = 4;
    emit(null, {
      't': Msg.effect,
      'kind': 'hit',
      'id': mobId,
      'x': mob.body.x,
      'y': mob.body.y + mob.body.height / 2,
      'z': mob.body.z,
    });
    p.exhaustion += 0.1;
    if (mob.health <= 0) {
      mobs.remove(mobId);
      p.kills++;
      switch (mob.kind) {
        case MobKind.mossback:
          p.inv.add(ItemStack(Ids.rawChop, 1 + rng.nextInt(2)));
          p.inv.add(ItemStack(Ids.woolTuft, 2 + rng.nextInt(3)));
        case MobKind.hollow:
          if (rng.chance(0.5)) p.inv.add(const ItemStack(Ids.coal, 1));
          if (rng.chance(0.15)) p.inv.add(const ItemStack(Ids.emberGem, 1));
        case MobKind.cinderling:
          p.inv.add(ItemStack(Ids.coal, 1 + rng.nextInt(2)));
      }
      emit(null, {
        't': Msg.effect,
        'kind': 'mob_died',
        'id': mobId,
        'kind_name': mob.kind.name,
        'x': mob.body.x,
        'y': mob.body.y,
        'z': mob.body.z,
      });
      _sendInventory(p);
      emit(null, {'t': Msg.roomState, ...roomStateJson()});
    }
  }

  void _onChat(PlayerState p, String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final line = ChatLine(tick, p.name, clean.length > 200 ? clean.substring(0, 200) : clean);
    chat.add(line);
    if (chat.length > 300) chat.removeAt(0);
    emit(null, {'t': Msg.chatMsg, ...line.toJson()});
  }

  void _system(String text) {
    final line = ChatLine(tick, '', text, system: true);
    chat.add(line);
    if (chat.length > 300) chat.removeAt(0);
    emit(null, {'t': Msg.chatMsg, ...line.toJson()});
  }

  void _onKilnPut(PlayerState p, Map<String, Object?> m) {
    final key = p.openPos;
    if (p.openKind != ContainerKind.kiln || key == null) return;
    final k = kilns[key];
    if (k == null) return;
    final slot = jstr(m, 'kslot'); // input | fuel | output
    final invSlot = jint(m, 'slot', -1);
    if (slot == 'output') {
      if (k.output.isNotEmpty) {
        final rest = p.inv.add(k.output, order: Inventory.preferredFillOrder);
        k.output = rest;
      }
    } else if (slot == 'input' || slot == 'fuel') {
      final cur = slot == 'input' ? k.input : k.fuel;
      if (invSlot < 0) {
        // take back
        if (cur.isNotEmpty) {
          final rest = p.inv.add(cur, order: Inventory.preferredFillOrder);
          if (slot == 'input') {
            k.input = rest;
          } else {
            k.fuel = rest;
          }
        }
      } else if (invSlot < Inventory.size) {
        final s = p.inv[invSlot];
        if (s.isEmpty) return;
        if (slot == 'fuel' && s.def.fuelTicks == 0) return;
        if (slot == 'input' && !Recipes.smelting.containsKey(s.id)) return;
        if (cur.isEmpty) {
          if (slot == 'input') {
            k.input = s;
          } else {
            k.fuel = s;
          }
          p.inv[invSlot] = ItemStack.empty;
        } else if (cur.sameKind(s)) {
          final take = math.min(s.count, cur.maxStack - cur.count);
          if (slot == 'input') {
            k.input = cur.withCount(cur.count + take);
          } else {
            k.fuel = cur.withCount(cur.count + take);
          }
          p.inv[invSlot] = s.withCount(s.count - take);
        }
      }
    }
    _sendInventory(p);
    _broadcastKiln(key, k);
    dirty = true;
  }

  void _onChestPut(PlayerState p, Map<String, Object?> m) {
    final key = p.openPos;
    if (p.openKind != ContainerKind.chest || key == null) return;
    final c = chests[key];
    if (c == null) return;
    final invSlot = jint(m, 'slot', -1);
    final chestSlot = jint(m, 'cslot', -1);
    final toChest = jbool(m, 'toChest', true);
    if (toChest) {
      if (invSlot < 0 || invSlot >= Inventory.size) return;
      final s = p.inv[invSlot];
      if (s.isEmpty) return;
      if (chestSlot >= 0 && chestSlot < c.length) {
        final target = c[chestSlot];
        if (target.isEmpty) {
          c[chestSlot] = s;
          p.inv[invSlot] = ItemStack.empty;
        } else if (target.sameKind(s)) {
          final take = math.min(s.count, target.maxStack - target.count);
          c[chestSlot] = target.withCount(target.count + take);
          p.inv[invSlot] = s.withCount(s.count - take);
        } else {
          c[chestSlot] = s;
          p.inv[invSlot] = target;
        }
      } else {
        p.inv[invSlot] = c.add(s);
      }
    } else {
      if (chestSlot < 0 || chestSlot >= c.length) return;
      final s = c[chestSlot];
      if (s.isEmpty) return;
      if (invSlot >= 0 && invSlot < Inventory.size) {
        final target = p.inv[invSlot];
        if (target.isEmpty) {
          p.inv[invSlot] = s;
          c[chestSlot] = ItemStack.empty;
        } else if (target.sameKind(s)) {
          final take = math.min(s.count, target.maxStack - target.count);
          p.inv[invSlot] = target.withCount(target.count + take);
          c[chestSlot] = s.withCount(s.count - take);
        } else {
          p.inv[invSlot] = s;
          c[chestSlot] = target;
        }
      } else {
        c[chestSlot] = p.inv.add(s, order: Inventory.preferredFillOrder);
      }
    }
    _sendInventory(p);
    for (final q in players.values) {
      if (q.openPos == key && q.openKind == ContainerKind.chest) {
        emit(q.id, {'t': Msg.container, 'kind': ContainerKind.chest, 'pos': key, 'slots': c.toJson()});
      }
    }
    dirty = true;
  }

  void _onDrop(PlayerState p, int slot, int count) {
    if (slot < 0 || slot >= Inventory.size) return;
    final s = p.inv[slot];
    if (s.isEmpty) return;
    p.inv[slot] = s.withCount(s.count - count.clamp(1, s.count));
    _sendInventory(p);
  }

  void _give(PlayerState p, int id, int count, int slot) {
    if (Registry.item(id).id == 0 && id != 0) return;
    if (id == 0) return;
    final stack = ItemStack(id, count.clamp(1, Registry.item(id).maxStack));
    if (slot >= 0 && slot < Inventory.size) {
      p.inv[slot] = stack;
    } else {
      p.inv.add(stack, order: Inventory.preferredFillOrder);
    }
    _sendInventory(p);
  }

  void _sendInventory(PlayerState p) {
    if (p.isBot) return;
    emit(p.id, {'t': Msg.inventory, 'slots': p.inv.toJson(), 'selected': p.selected});
  }

  void _sendStats(PlayerState p) {
    if (p.isBot) return;
    emit(p.id, {'t': Msg.stats, 'hp': p.health, 'food': p.hunger, 'air': p.air, 'score': p.score});
  }

  void _broadcastKiln(int key, KilnState k) {
    for (final q in players.values) {
      if (q.openPos == key && q.openKind == ContainerKind.kiln) {
        emit(q.id, {'t': Msg.container, 'kind': ContainerKind.kiln, 'pos': key, 'kiln': k.toJson()});
      }
    }
  }

  // ---------------------------------------------------------------- chunks

  void _streamChunks(PlayerState p) {
    if (p.isBot) return;
    final pcx = floorDiv(p.body.x.floor(), 16), pcz = floorDiv(p.body.z.floor(), 16);
    final r = viewChunks;
    final pending = <List<int>>[];
    for (var dz = -r; dz <= r; dz++) {
      for (var dx = -r; dx <= r; dx++) {
        final cx = pcx + dx, cz = pcz + dz;
        final key = ChunkKey.of(cx, cz);
        if (p.sentChunks.contains(key)) continue;
        pending.add([dx * dx + dz * dz, cx, cz, key]);
      }
    }
    pending.sort((a, b) => a[0].compareTo(b[0]));
    var sent = 0;
    for (final e in pending) {
      if (sent >= 12) break;
      world.ensureChunk(e[1], e[2]);
      emit(p.id, {'t': Msg.chunk, 'cx': e[1], 'cz': e[2], 'edits': world.editsOf(e[1], e[2])});
      p.sentChunks.add(e[3]);
      sent++;
    }
    // Forget far chunks so they are re-sent (with edits) when revisited.
    p.sentChunks.removeWhere((k) {
      final cx = ChunkKey.cxOf(k), cz = ChunkKey.czOf(k);
      return (cx - pcx).abs() > r + 2 || (cz - pcz).abs() > r + 2;
    });
  }

  // ---------------------------------------------------------------- match flow

  void startMatch() {
    if (phase == Phase.playing) return;
    phase = Phase.playing;
    matchStartTick = tick;
    matchEndTick = durationTicks > 0 ? tick + durationTicks : 0;
    for (final p in players.values) {
      p.placed = 0;
      p.broken = 0;
      p.crafted = 0;
      p.kills = 0;
      p.deaths = 0;
      p.health = 20;
      p.hunger = 20;
      p.sleeping = false;
      _sendStats(p);
    }
    emit(null, {'t': Msg.phase, 'phase': phase, 'tick': tick, 'matchEndTick': matchEndTick, 'time': timeOfDay});
    _system(
      durationTicks > 0
          ? 'The match has begun! ${(durationTicks / 20).round()} seconds on the clock.'
          : 'Free play has begun. The host can end the session at any time.',
    );
    _broadcastRoomState();
    dirty = true;
  }

  void endMatch() {
    if (phase != Phase.playing) return;
    phase = Phase.results;
    final results = players.values.map((p) => p.toInfo()).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    emit(null, {
      't': Msg.phase,
      'phase': phase,
      'tick': tick,
      'results': results,
      'worldHash': world.editsHash(),
      'chatHash': chatHash(),
    });
    _system('Match over. ${results.isNotEmpty ? '${results.first['name']} takes the crown!' : ''}');
    dirty = true;
  }

  void backToLobby() {
    if (phase == Phase.lobby) return;
    phase = Phase.lobby;
    for (final p in players.values) {
      p.ready = p.isBot;
    }
    emit(null, {'t': Msg.phase, 'phase': phase, 'tick': tick});
    _broadcastRoomState();
  }

  Map<String, Object?> roomStateJson() => {
    'code': code,
    'name': name,
    'seed': seed,
    'mode': mode,
    'phase': phase,
    'host': hostId,
    'durationTicks': durationTicks,
    'freezeTime': freezeTime,
    'spawnMobs': spawnMobs,
    'matchEndTick': matchEndTick,
    'tick': tick,
    'time': timeOfDay,
    'players': players.values.map((q) => q.toInfo()).toList(),
  };

  void _broadcastRoomState() => emit(null, {'t': Msg.roomState, ...roomStateJson()});

  String chatHash() {
    final h = Fnv32();
    for (final c in chat) {
      h.addString(c.from);
      h.addString(c.text);
    }
    return h.hex;
  }

  // ---------------------------------------------------------------- tick

  void tickOnce() {
    tick++;
    if (!freezeTime && phase == Phase.playing) {
      timeOfDay = (timeOfDay + 1) % WorldConst.dayTicks;
    }
    if (phase == Phase.playing) {
      for (final p in players.values) {
        if (p.isBot) {
          _tickBot(p);
        } else if (p.connected) {
          _tickPlayer(p);
        }
      }
      _tickMobs();
      _tickKilns();
      if (matchEndTick > 0 && tick >= matchEndTick) endMatch();
    }
    if (tick % 1 == 0) {
      emit(null, {
        't': Msg.snapshot,
        'tick': tick,
        'time': timeOfDay,
        'players': players.values.where((p) => p.connected || p.isBot).map((p) => p.toSnapshot()).toList(),
        'mobs': mobs.values.map((m) => m.toSnapshot()).toList(),
      });
    }
    if (tick % 100 == 0) _broadcastRoomState();
  }

  void _tickPlayer(PlayerState p) {
    if (p.health <= 0) return;
    if (mode == GameMode.creative) return;
    var changed = false;
    // Drowning.
    p.body.inWater = physics.bodyInFluid(p.body);
    if (physics.headInFluid(p.body)) {
      p.air = math.max(0, p.air - 1);
      if (p.air == 0 && tick % 20 == 0) {
        _damage(p, 2, 'drowned');
        changed = true;
      }
      if (tick % 5 == 0) changed = true;
    } else if (p.air < 300) {
      p.air = math.min(300, p.air + 4);
      if (tick % 5 == 0) changed = true;
    }
    // Hunger.
    p.hungerTimer++;
    p.exhaustion += 0.0005;
    if (p.exhaustion >= 4.0) {
      p.exhaustion -= 4.0;
      if (p.hunger > 0) {
        p.hunger--;
        changed = true;
      }
    }
    if (p.hunger >= 18 && p.health < 20) {
      p.regenTimer++;
      if (p.regenTimer >= 80) {
        p.regenTimer = 0;
        p.health = math.min(20, p.health + 1);
        p.exhaustion += 0.3;
        changed = true;
      }
    } else if (p.hunger == 0) {
      p.regenTimer++;
      if (p.regenTimer >= 80) {
        p.regenTimer = 0;
        if (p.health > 1) {
          _damage(p, 1, 'starved');
          changed = true;
        }
      }
    }
    if (p.hurtCooldown > 0) p.hurtCooldown--;
    // Cactus contact.
    final bx = p.body.x.floor(), by = p.body.y.floor(), bz = p.body.z.floor();
    for (final d in const [
      [1, 0, 0],
      [-1, 0, 0],
      [0, 0, 1],
      [0, 0, -1],
      [0, -1, 0],
    ]) {
      if (world.peek(bx + d[0], by + d[1], bz + d[2]) == Ids.cactus && tick % 10 == 0) {
        final ex = (p.body.x - (bx + d[0] + 0.5)).abs();
        final ez = (p.body.z - (bz + d[2] + 0.5)).abs();
        if (ex < 0.85 && ez < 0.85) {
          _damage(p, 1, 'was pricked to death');
          changed = true;
        }
      }
    }
    if (changed) _sendStats(p);
  }

  void _damage(PlayerState p, int amount, String cause) {
    if (mode == GameMode.creative || amount <= 0 || p.health <= 0) return;
    if (p.hurtCooldown > 0 && cause != 'fell from a high place') return;
    p.health = math.max(0, p.health - amount);
    p.hurtCooldown = 10;
    emit(p.id, {'t': Msg.effect, 'kind': 'hurt', 'amount': amount});
    _sendStats(p);
    if (p.health <= 0) {
      p.deaths++;
      p.sleeping = false;
      _system('${p.name} $cause');
      emit(p.id, {'t': Msg.effect, 'kind': 'died', 'cause': cause});
      emit(null, {'t': Msg.roomState, ...roomStateJson()});
    }
  }

  void _respawn(PlayerState p) {
    p.health = 20;
    p.hunger = 20;
    p.air = 300;
    p.exhaustion = 0;
    p.fallStart = double.nan;
    _placeAtSpawn(p);
    _unstick(p.body);
    emit(p.id, {'t': Msg.teleport, 'x': p.body.x, 'y': p.body.y, 'z': p.body.z});
    _sendStats(p);
  }

  // ---------------------------------------------------------------- mobs

  PlayerState? _nearestPlayer(double x, double z, {bool alive = true}) {
    PlayerState? best;
    var bestD = double.infinity;
    for (final p in players.values) {
      if (!p.connected && !p.isBot) continue;
      if (alive && p.health <= 0) continue;
      final dx = p.body.x - x, dz = p.body.z - z;
      final d = dx * dx + dz * dz;
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  double _dist2(Body a, Body b) {
    final dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return dx * dx + dy * dy + dz * dz;
  }

  void _tickMobs() {
    if (spawnMobs && tick % 40 == 0) _trySpawnMob();
    final toRemove = <int>[];
    for (final m in mobs.values) {
      final b = m.body;
      if (m.hurtFlash > 0) m.hurtFlash--;
      if (m.attackCooldown > 0) m.attackCooldown--;
      final near = _nearestPlayer(b.x, b.z);
      if (near == null) continue;
      final d2 = _dist2(b, near.body);
      if (d2 > 56 * 56) {
        toRemove.add(m.id);
        continue;
      }
      if (m.hostile && isDay && world.skyVisible(b.x.floor(), b.y.floor(), b.z.floor()) && tick % 20 == 0) {
        m.health -= 2;
        m.hurtFlash = 6;
        if (m.health <= 0) {
          toRemove.add(m.id);
          emit(null, {
            't': Msg.effect,
            'kind': 'mob_died',
            'id': m.id,
            'kind_name': m.kind.name,
            'x': b.x,
            'y': b.y,
            'z': b.z,
          });
          continue;
        }
      }
      var wishX = 0.0, wishZ = 0.0, jump = false;
      final speed = switch (m.kind) {
        MobKind.mossback => 1.4,
        MobKind.hollow => 2.6,
        MobKind.cinderling => 3.6,
      };
      if (m.hostile && d2 < 20 * 20) {
        final dx = near.body.x - b.x, dz = near.body.z - b.z;
        final len = math.sqrt(dx * dx + dz * dz) + 1e-6;
        if (len > 1.2) {
          wishX = dx / len * speed;
          wishZ = dz / len * speed;
        }
        m.yaw = math.atan2(-dx, dz);
        if (len < 1.9 && (near.body.y - b.y).abs() < 2 && m.attackCooldown == 0) {
          m.attackCooldown = 25;
          _damage(near, m.kind == MobKind.hollow ? 3 : 2, 'was slain by a ${m.kind.name}');
          emit(null, {'t': Msg.effect, 'kind': 'mob_attack', 'id': m.id});
        }
      } else {
        m.timer--;
        if (m.timer <= 0) {
          m.timer = 40 + rng.nextInt(100);
          if (rng.chance(0.6)) {
            m.tx = b.x + rng.nextInt(13) - 6;
            m.tz = b.z + rng.nextInt(13) - 6;
          } else {
            m.tx = b.x;
            m.tz = b.z;
          }
        }
        final dx = m.tx - b.x, dz = m.tz - b.z;
        final len = math.sqrt(dx * dx + dz * dz);
        if (len > 0.5) {
          wishX = dx / len * speed * 0.6;
          wishZ = dz / len * speed * 0.6;
          m.yaw = math.atan2(-dx, dz);
        }
      }
      if ((wishX != 0 || wishZ != 0) && b.onGround) {
        final len = math.sqrt(wishX * wishX + wishZ * wishZ);
        if (physics.tryStepUp(b, wishX / len, wishZ / len)) jump = true;
      }
      if (b.inWater) jump = true;
      physics.step(b, 0.05, wishX, wishZ, jump: jump);
      if (b.y < -5) toRemove.add(m.id);
    }
    for (final id in toRemove) {
      mobs.remove(id);
    }
  }

  void _trySpawnMob() {
    final humans = players.values.where((p) => p.connected && !p.isBot).toList();
    if (humans.isEmpty) return;
    final hostiles = mobs.values.where((m) => m.hostile).length;
    final passives = mobs.length - hostiles;
    final p = humans[rng.nextInt(humans.length)];
    final ang = rng.nextDouble() * math.pi * 2;
    final dist = 14 + rng.nextInt(16);
    final x = (p.body.x + math.cos(ang) * dist).floor();
    final z = (p.body.z + math.sin(ang) * dist).floor();
    if (!world.isLoaded(x, z)) return;
    final h = world.heightAt(x, z);
    if (h < 0 || h >= WorldConst.height - 3) return;
    final ground = world.peek(x, h, z);
    if (Registry.block(ground).fluid || !Registry.block(ground).solid) return;
    final y = h + 1;
    if (world.isSolid(x, y, z) || world.isSolid(x, y + 1, z)) return;
    MobKind kind;
    if (isNight) {
      if (hostiles >= 8) return;
      kind = rng.chance(0.7) ? MobKind.hollow : MobKind.cinderling;
    } else {
      if (passives >= 6) return;
      if (ground != Ids.grass && ground != Ids.snow) return;
      kind = MobKind.mossback;
    }
    final m = Mob(_nextMobId++, kind);
    m.health = m.maxHealth;
    m.body.setPos(x + 0.5, y.toDouble(), z + 0.5);
    m.tx = m.body.x;
    m.tz = m.body.z;
    mobs[m.id] = m;
  }

  // ---------------------------------------------------------------- kilns

  void _tickKilns() {
    for (final e in kilns.entries) {
      final k = e.value;
      var changed = false;
      final canSmelt = k.input.isNotEmpty && Recipes.smelting.containsKey(k.input.id);
      final out = canSmelt ? Recipes.smelting[k.input.id]! : null;
      final outFits =
          out != null &&
          (k.output.isEmpty || (k.output.id == out.id && k.output.count + out.count <= k.output.maxStack));
      if (k.burnLeft > 0) {
        k.burnLeft--;
        changed = tick % 10 == 0;
      }
      if (k.burnLeft == 0 && canSmelt && outFits && k.fuel.isNotEmpty && k.fuel.def.fuelTicks > 0) {
        k.burnTotal = k.fuel.def.fuelTicks;
        k.burnLeft = k.burnTotal;
        k.fuel = k.fuel.withCount(k.fuel.count - 1);
        changed = true;
      }
      if (k.burnLeft > 0 && canSmelt && outFits) {
        k.cook++;
        if (k.cook >= Recipes.smeltTicks) {
          k.cook = 0;
          k.output = k.output.isEmpty ? out : k.output.withCount(k.output.count + out.count);
          k.input = k.input.withCount(k.input.count - 1);
          changed = true;
          dirty = true;
        }
      } else if (k.cook > 0) {
        k.cook = math.max(0, k.cook - 2);
        changed = tick % 10 == 0;
      }
      if (changed) _broadcastKiln(e.key, k);
    }
  }

  // ---------------------------------------------------------------- bots

  void _tickBot(PlayerState p) {
    final b = p.body;
    p.botTimer--;
    if (p.botTimer <= 0) {
      p.botTimer = 60 + rng.nextInt(80);
      p.botTask = rng.nextInt(10);
      final anchor = _nearestPlayer(b.x, b.z);
      final ax = anchor != null && !anchor.isBot ? anchor.body.x : spawn[0] + 0.5;
      final az = anchor != null && !anchor.isBot ? anchor.body.z : spawn[2] + 0.5;
      p.botTx = ax + rng.nextInt(17) - 8;
      p.botTz = az + rng.nextInt(17) - 8;
      if (p.botTask == 0) {
        _onChat(p, _botLines[rng.nextInt(_botLines.length)]);
      } else if (p.botTask <= 3) {
        // place a plank block in front
        final fx = b.x.floor() + (rng.nextInt(3) - 1), fz = b.z.floor() + (rng.nextInt(3) - 1);
        final h = world.heightAt(fx, fz);
        if (h >= 0 && (fx != b.x.floor() || fz != b.z.floor())) {
          p.selected = _slotOf(p, Ids.planks) ?? 0;
          _onPlace(p, fx, h + 1, fz, 0, 1, 0);
        }
      } else if (p.botTask <= 5) {
        final fx = b.x.floor() + (rng.nextInt(3) - 1), fz = b.z.floor() + (rng.nextInt(3) - 1);
        final h = world.heightAt(fx, fz);
        if (h >= 1) {
          final id = world.peek(fx, h, fz);
          if (id != Ids.bedrock && !Registry.block(id).fluid) {
            p.selected = _slotOf(p, Ids.stonePick) ?? 0;
            _onBreak(p, fx, h, fz);
          }
        }
      } else if (p.botTask == 6 && isNight) {
        p.selected = _slotOf(p, Ids.torch) ?? 0;
        final fx = b.x.floor(), fz = b.z.floor();
        final h = world.heightAt(fx, fz);
        if (h >= 0 && world.peek(fx, h + 1, fz) == Ids.air) _onPlace(p, fx, h + 1, fz, 0, 1, 0);
      }
    }
    final dx = p.botTx - b.x, dz = p.botTz - b.z;
    final len = math.sqrt(dx * dx + dz * dz);
    var wishX = 0.0, wishZ = 0.0, jump = false;
    if (len > 0.6 && p.botTask >= 6) {
      wishX = dx / len * Move.walkSpeed * 0.8;
      wishZ = dz / len * Move.walkSpeed * 0.8;
      p.yaw = math.atan2(-dx, dz);
      if (b.onGround && physics.tryStepUp(b, dx / len, dz / len)) jump = true;
    }
    if (b.inWater) jump = true;
    physics.step(b, 0.05, wishX, wishZ, jump: jump);
    if (b.y < 0) _placeAtSpawn(p);
  }

  int? _slotOf(PlayerState p, int id) {
    for (var i = 0; i < Inventory.hotbarSize; i++) {
      if (p.inv[i].id == id && p.inv[i].isNotEmpty) return i;
    }
    return null;
  }

  static const _botLines = [
    'Anyone found ember ore yet?',
    'Building a little hut over here.',
    'Watch out, the Hollows come out at dusk.',
    'Nice view from this hill!',
    'Need more planks...',
    'gg so far',
  ];

  // ---------------------------------------------------------------- save

  Map<String, Object?> toSave() => {
    'version': 1,
    'code': code,
    'name': name,
    'seed': seed,
    'mode': mode,
    'durationTicks': durationTicks,
    'freezeTime': freezeTime,
    'spawnMobs': spawnMobs,
    'time': timeOfDay,
    'tick': tick,
    'spawn': spawn,
    'edits': world.editsToJson(),
    'chests': {for (final e in chests.entries) '${e.key}': e.value.toJson()},
    'kilns': {for (final e in kilns.entries) '${e.key}': e.value.toJson()},
    'players': {for (final p in players.values.where((p) => !p.isBot)) p.id: p.toSave()},
    'chat': chat.map((c) => c.toJson()).toList(),
  };

  /// Restores persistent world data. Players are restored lazily on join via
  /// [savedPlayers].
  final Map<String, Map<String, Object?>> savedPlayers = <String, Map<String, Object?>>{};

  void loadSave(Map<String, Object?> j) {
    name = jstr(j, 'name', name);
    mode = jstr(j, 'mode', mode);
    durationTicks = jint(j, 'durationTicks', durationTicks);
    freezeTime = jbool(j, 'freezeTime', freezeTime);
    spawnMobs = jbool(j, 'spawnMobs', spawnMobs);
    timeOfDay = jint(j, 'time', timeOfDay);
    tick = jint(j, 'tick', tick);
    final sp = j['spawn'];
    if (sp is List && sp.length == 3) spawn = sp.map((e) => (e as num).toInt()).toList();
    final edits = j['edits'];
    if (edits is Map) world.editsFromJson(edits.cast<String, Object?>());
    final ch = j['chests'];
    if (ch is Map) {
      for (final e in ch.entries) {
        chests[int.parse(e.key as String)] = SlotList.fromJson(e.value, 27);
      }
    }
    final ks = j['kilns'];
    if (ks is Map) {
      for (final e in ks.entries) {
        kilns[int.parse(e.key as String)] = KilnState.fromJson((e.value as Map).cast<String, Object?>());
      }
    }
    final ps = j['players'];
    if (ps is Map) {
      for (final e in ps.entries) {
        savedPlayers[e.key as String] = (e.value as Map).cast<String, Object?>();
      }
    }
    final c = j['chat'];
    if (c is List) {
      chat.clear();
      for (final l in c) {
        final m = (l as Map).cast<String, Object?>();
        chat.add(ChatLine(jint(m, 'tick'), jstr(m, 'from'), jstr(m, 'text'), system: jbool(m, 'system')));
      }
    }
  }
}
