import 'dart:async';
import 'dart:math' as math;

import 'package:panic_pantry_core/panic_pantry_core.dart';

/// A connected (or temporarily disconnected) participant in a room.
class Player {
  Player({required this.id, required this.token, required this.name, required this.slot, required this.platform});

  final String id;
  final String token;
  String name;
  final int slot;
  final String platform;
  bool ready = false;
  bool connected = true;

  /// Last `test.report` sent by this client, for the automated harness.
  Map<String, dynamic>? lastReport;

  /// Outbound sink; null while disconnected.
  void Function(Map<String, dynamic>)? send;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slot': slot,
    'platform': platform,
    'ready': ready,
    'connected': connected,
    'bot': false,
  };
}

/// One lobby + match. Owns the authoritative [Simulation] and the tick loop.
class Room {
  Room({required this.code, required this.seed, required LevelDef level, required this.onChange, this.speed = 1})
    : _level = level; // ignore: prefer_initializing_formals

  final String code;
  final int seed;

  /// Wall-clock multiplier for the tick loop (test harness only). The
  /// simulation itself always advances by exactly [Rules.tickSeconds] per tick.
  final double speed;
  final void Function(Room room) onChange;

  LevelDef _level;
  LevelDef get level => _level;

  final Map<String, Player> players = {};
  final List<String> botIds = [];
  String? hostId;

  GameState? _state;
  Simulation? _sim;
  final Map<String, Bot> _bots = {};
  final BotCoordinator _coordinator = BotCoordinator();
  Timer? _timer;

  /// Simulated (fixed-step) clock; every tick is exactly [Rules.tickSeconds].
  int get tick => _state?.tick ?? 0;
  Map<String, dynamic>? lastResults;
  int matchNumber = 0;

  /// Scripted inputs queued by the test harness, applied server-side.
  final Map<String, List<ChefInput>> _scripted = {};

  static const int maxPlayers = 4;

  bool get inLobby => _state == null || _state!.phase == Phase.lobby || _state!.phase == Phase.finished;
  bool get isEmpty => players.values.every((p) => !p.connected);
  int get occupancy => players.length + botIds.length;
  GameState? get state => _state;

  int _freeSlot() {
    final used = {...players.values.map((p) => p.slot), ...botIds.map((b) => int.parse(b.substring(3)))};
    for (var i = 0; i < maxPlayers; i++) {
      if (!used.contains(i)) return i;
    }
    return -1;
  }

  Player? addPlayer({required String id, required String token, required String name, required String platform}) {
    if (occupancy >= maxPlayers || !inLobby) return null;
    final slot = _freeSlot();
    if (slot < 0) return null;
    final p = Player(id: id, token: token, name: name, slot: slot, platform: platform);
    players[id] = p;
    hostId ??= id;
    return p;
  }

  void removePlayer(String id) {
    players.remove(id);
    if (hostId == id) hostId = players.values.where((p) => p.connected).map((p) => p.id).firstOrNull;
    if (_state != null && _state!.phase != Phase.lobby) {
      // Mid-match: the chef stays as an idle body so the match can continue.
      _scripted.remove(id);
    }
  }

  bool addBot() {
    if (occupancy >= maxPlayers || !inLobby) return false;
    final slot = _freeSlot();
    if (slot < 0) return false;
    botIds.add('bot$slot');
    return true;
  }

  bool removeBot([String? id]) {
    final target = id ?? botIds.lastOrNull;
    if (target == null || !inLobby) return false;
    return botIds.remove(target);
  }

  void setLevel(String id) {
    if (!inLobby) return;
    _level = levelById(id);
  }

  bool get everyoneReady => players.values.where((p) => p.connected).every((p) => p.ready);

  void start() {
    if (_state != null && _state!.phase != Phase.lobby && _state!.phase != Phase.finished) return;
    matchNumber++;
    lastResults = null;
    final s = GameState(_level, playerCount: occupancy);
    // Chefs are created in slot order so every client sees the same roster.
    final roster = <(int, String, String, bool)>[
      for (final p in players.values) (p.slot, p.id, p.name, false),
      for (final b in botIds) (int.parse(b.substring(3)), b, 'Bot ${int.parse(b.substring(3)) + 1}', true),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final r in roster) {
      s.chefs.add(Chef(id: r.$2, slot: r.$1, name: r.$3, x: 0, y: 0, bot: r.$4)..connected = true);
    }
    final matchSeed = seed + matchNumber * 7919;
    _sim = Simulation(s, seed: matchSeed);
    _bots.clear();
    _coordinator.claims.clear();
    for (final b in botIds) {
      _bots[b] = Bot(b, seed: matchSeed + int.parse(b.substring(3)), coordinator: _coordinator);
    }
    for (final p in players.values) {
      s.chefById(p.id)?.connected = p.connected;
    }
    _state = s;
    _sim!.startRound();
    for (final p in players.values) {
      p.ready = false;
    }
    _timer?.cancel();
    _timer = Timer.periodic(Duration(microseconds: (Rules.tickSeconds * 1e6 / speed).round()), (_) => _tick());
    onChange(this);
    _broadcastSnapshot();
  }

  void rematch() {
    if (_state == null || _state!.phase != Phase.finished) return;
    _timer?.cancel();
    _timer = null;
    _state = null;
    _sim = null;
    onChange(this);
  }

  void input(String playerId, ChefInput input) {
    final sim = _sim;
    if (sim == null) return;
    if (_state!.chefById(playerId) == null) return;
    // Edge-triggered flags accumulate until the next tick consumes them.
    final prev = sim.pending[playerId];
    sim.pending[playerId] = prev == null
        ? input
        : ChefInput(
            dx: input.dx,
            dy: input.dy,
            interact: input.interact || prev.interact,
            action: input.action,
            dash: input.dash || prev.dash,
            emote: input.emote ?? prev.emote,
            targetX: input.targetX ?? prev.targetX,
            targetY: input.targetY ?? prev.targetY,
          );
  }

  /// Queue [inputs] to be applied on consecutive ticks for [chefId]
  /// (test harness; deterministic regardless of network timing).
  void script(String chefId, List<ChefInput> inputs) {
    _scripted.putIfAbsent(chefId, () => []).addAll(inputs);
  }

  int scriptedRemaining(String chefId) => _scripted[chefId]?.length ?? 0;

  void _tick() {
    final sim = _sim;
    final s = _state;
    if (sim == null || s == null) return;
    for (final b in _bots.values) {
      sim.pending[b.chefId] = b.think(s, Rules.tickSeconds);
    }
    for (final e in _scripted.entries) {
      if (e.value.isNotEmpty) sim.pending[e.key] = e.value.removeAt(0);
    }
    sim.step();
    // Held inputs (movement/action) persist; edge-triggered ones do not.
    for (final k in sim.pending.keys.toList()) {
      final p = sim.pending[k]!;
      if (_bots.containsKey(k) || _scripted[k]?.isNotEmpty == true) {
        sim.pending.remove(k);
      } else if (p.interact || p.dash || p.emote != null) {
        sim.pending[k] = ChefInput(dx: p.dx, dy: p.dy, action: p.action);
      }
    }
    _broadcastSnapshot();
    s.events.clear();
    if (s.phase == Phase.finished) {
      _timer?.cancel();
      _timer = null;
      lastResults = s.results();
      broadcast({'type': Msg.results, 'code': code, 'results': lastResults, 'seed': seed, 'match': matchNumber});
      onChange(this);
    }
  }

  void _broadcastSnapshot() {
    final s = _state;
    if (s == null) return;
    broadcast({'type': Msg.snapshot, 'code': code, 'state': s.toSnapshot()});
  }

  void broadcast(Map<String, dynamic> msg) {
    for (final p in players.values) {
      p.send?.call(msg);
    }
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'seed': seed,
    'speed': speed,
    'level': _level.id,
    'hostId': hostId,
    'phase': _state?.phase.name ?? 'lobby',
    'match': matchNumber,
    'tick': tick,
    'players': [
      ...players.values.map((p) => p.toJson()),
      ...botIds.map(
        (b) => {
          'id': b,
          'name': 'Bot ${int.parse(b.substring(3)) + 1}',
          'slot': int.parse(b.substring(3)),
          'platform': 'server',
          'ready': true,
          'connected': true,
          'bot': true,
        },
      ),
    ]..sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int)),
    'maxPlayers': maxPlayers,
    if (lastResults != null) 'results': lastResults,
  };

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Room codes: 4 letters, no ambiguous glyphs.
String makeRoomCode(math.Random rng) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  return String.fromCharCodes(List.generate(4, (_) => alphabet.codeUnitAt(rng.nextInt(alphabet.length))));
}
