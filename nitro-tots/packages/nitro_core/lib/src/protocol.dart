import 'items.dart';
import 'math.dart';
import 'sim.dart';
import 'track.dart';

/// Wire protocol version. Clients and server must agree.
const protocolVersion = 1;

/// Message type names. See PROTOCOL.md for the full contract.
abstract final class Msg {
  // Client -> server
  static const hello = 'hello';
  static const resume = 'resume';
  static const createRoom = 'create_room';
  static const joinRoom = 'join_room';
  static const leaveRoom = 'leave_room';
  static const setReady = 'set_ready';
  static const updateProfile = 'update_profile';
  static const updateSettings = 'update_settings';
  static const startMatch = 'start_match';
  static const input = 'input';
  static const ping = 'ping';
  static const testReport = 'test_report';
  static const nextRace = 'next_race';

  // Server -> client
  static const welcome = 'welcome';
  static const error = 'error';
  static const roomState = 'room_state';
  static const matchStart = 'match_start';
  static const snapshot = 'snapshot';
  static const raceFinished = 'race_finished';
  static const gpStandings = 'gp_standings';
  static const matchOver = 'match_over';
  static const pong = 'pong';
  static const playerLeft = 'player_left';
}

class RoomSettings {
  const RoomSettings({
    this.mode = GameMode.race,
    this.cupId = 'sugar',
    this.trackId = 'sprinkle',
    this.laps = 3,
    this.maxPlayers = 8,
    this.fillBots = true,
    this.botSkill = 0.7,
    this.grandPrix = true,
    this.battleSeconds = 120,
  });

  final GameMode mode;
  final String cupId;
  final String trackId;
  final int laps;
  final int maxPlayers;
  final bool fillBots;
  final double botSkill;
  final bool grandPrix;
  final int battleSeconds;

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'cupId': cupId,
    'trackId': trackId,
    'laps': laps,
    'maxPlayers': maxPlayers,
    'fillBots': fillBots,
    'botSkill': botSkill,
    'grandPrix': grandPrix,
    'battleSeconds': battleSeconds,
  };

  static RoomSettings fromJson(Map<String, dynamic> j) => RoomSettings(
    mode: GameMode.values.firstWhere((m) => m.name == j['mode'], orElse: () => GameMode.race),
    cupId: (j['cupId'] as String?) ?? 'sugar',
    trackId: (j['trackId'] as String?) ?? 'sprinkle',
    laps: ((j['laps'] as num?) ?? 3).toInt().clamp(1, 5),
    maxPlayers: ((j['maxPlayers'] as num?) ?? 8).toInt().clamp(2, 8),
    fillBots: (j['fillBots'] as bool?) ?? true,
    botSkill: ((j['botSkill'] as num?) ?? 0.7).toDouble().clamp(0.0, 1.0),
    grandPrix: (j['grandPrix'] as bool?) ?? true,
    battleSeconds: ((j['battleSeconds'] as num?) ?? 120).toInt().clamp(30, 300),
  );

  RoomSettings copyWith({
    GameMode? mode,
    String? cupId,
    String? trackId,
    int? laps,
    int? maxPlayers,
    bool? fillBots,
    double? botSkill,
    bool? grandPrix,
    int? battleSeconds,
  }) => RoomSettings(
    mode: mode ?? this.mode,
    cupId: cupId ?? this.cupId,
    trackId: trackId ?? this.trackId,
    laps: laps ?? this.laps,
    maxPlayers: maxPlayers ?? this.maxPlayers,
    fillBots: fillBots ?? this.fillBots,
    botSkill: botSkill ?? this.botSkill,
    grandPrix: grandPrix ?? this.grandPrix,
    battleSeconds: battleSeconds ?? this.battleSeconds,
  );
}

class PlayerInfo {
  const PlayerInfo({
    required this.id,
    required this.name,
    required this.characterId,
    required this.kartId,
    required this.platform,
    required this.ready,
    required this.connected,
    required this.isHost,
    this.slot = -1,
    this.isBot = false,
  });

  final String id;
  final String name;
  final String characterId;
  final String kartId;
  final String platform;
  final bool ready;
  final bool connected;
  final bool isHost;
  final int slot;
  final bool isBot;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'character': characterId,
    'kart': kartId,
    'platform': platform,
    'ready': ready,
    'connected': connected,
    'host': isHost,
    'slot': slot,
    'bot': isBot,
  };

  static PlayerInfo fromJson(Map<String, dynamic> j) => PlayerInfo(
    id: j['id'] as String,
    name: j['name'] as String,
    characterId: j['character'] as String,
    kartId: j['kart'] as String,
    platform: (j['platform'] as String?) ?? '',
    ready: (j['ready'] as bool?) ?? false,
    connected: (j['connected'] as bool?) ?? true,
    isHost: (j['host'] as bool?) ?? false,
    slot: (j['slot'] as int?) ?? -1,
    isBot: (j['bot'] as bool?) ?? false,
  );
}

/// Compact per-racer snapshot record.
Map<String, dynamic> racerToWire(Racer r) => {
  's': r.slot,
  'x': round2(r.pos.x),
  'y': round2(r.pos.y),
  'h': round2(r.heading),
  'v': round2(r.speed),
  'l': r.lap,
  'c': r.checkpoint,
  'n': r.nearest,
  'p': r.position,
  'd': r.driftDir,
  'dc': r.driftCharge,
  'b': r.boostTicks,
  'bt': r.boostTier,
  'a': r.airTicks,
  'sp': r.spinTicks,
  'sh': r.shieldTicks,
  'z': r.zapTicks,
  'cm': r.cometTicks,
  'st': r.stallTicks,
  'hp': r.hopTicks,
  if (r.item != null) 'i': r.item!.wire,
  'ic': r.itemCharges,
  'ro': r.rouletteTicks,
  'f': r.finished ? 1 : 0,
  'ft': r.finishTick,
  'lt': r.lapTicks,
  'ls': r.lapStartTick,
  'ww': r.wrongWayTicks,
  'bl': r.balloons,
  'sc': r.score,
  'rs': r.respawnTicks,
  'su': r.surface.index,
  'pi': r.prevItemButton ? 1 : 0,
  'pd': r.prevDrift ? 1 : 0,
  'th': r.throttleHeldTicks,
};

void applyRacerWire(Racer r, Map<String, dynamic> j) {
  r.pos = V2((j['x'] as num).toDouble(), (j['y'] as num).toDouble());
  r.heading = (j['h'] as num).toDouble();
  r.speed = (j['v'] as num).toDouble();
  r.lap = j['l'] as int;
  r.checkpoint = j['c'] as int;
  r.nearest = j['n'] as int;
  r.position = j['p'] as int;
  r.driftDir = j['d'] as int;
  r.driftCharge = j['dc'] as int;
  r.boostTicks = j['b'] as int;
  r.boostTier = j['bt'] as int;
  r.boostMult = switch (r.boostTier) {
    0 => 1.0,
    1 => 1.24,
    2 => 1.3,
    3 => 1.38,
    _ => 1.75,
  };
  r.airTicks = j['a'] as int;
  r.spinTicks = j['sp'] as int;
  r.shieldTicks = j['sh'] as int;
  r.zapTicks = j['z'] as int;
  r.cometTicks = j['cm'] as int;
  r.stallTicks = (j['st'] as int?) ?? 0;
  r.hopTicks = (j['hp'] as int?) ?? 0;
  r.item = ItemKindInfo.fromWire(j['i'] as String?);
  r.itemCharges = j['ic'] as int;
  r.rouletteTicks = j['ro'] as int;
  r.finished = j['f'] == 1;
  r.finishTick = j['ft'] as int;
  r.lapTicks = (j['lt'] as List).cast<int>();
  r.lapStartTick = (j['ls'] as int?) ?? 0;
  r.wrongWayTicks = j['ww'] as int;
  r.balloons = j['bl'] as int;
  r.score = j['sc'] as int;
  r.respawnTicks = j['rs'] as int;
  r.surface = Surface.values[j['su'] as int];
  r.prevItemButton = j['pi'] == 1;
  r.prevDrift = j['pd'] == 1;
  r.throttleHeldTicks = (j['th'] as int?) ?? 0;
}

Map<String, dynamic> snapshotToWire(RaceSim sim, {Map<int, int> acks = const {}}) => {
  'type': Msg.snapshot,
  'tick': sim.tick,
  'phase': sim.phase.name,
  'racers': [for (final r in sim.racers) racerToWire(r)],
  'proj': [
    for (final p in sim.projectiles) {'id': p.id, 'k': p.kind.wire, 'o': p.ownerSlot, 'x': round2(p.pos.x), 'y': round2(p.pos.y), 'h': round2(p.heading)},
  ],
  'drop': [
    for (final d in sim.dropped) {'id': d.id, 'x': round2(d.pos.x), 'y': round2(d.pos.y), 'o': d.ownerSlot},
  ],
  'boxes': [
    for (var i = 0; i < sim.itemBoxRespawn.length; i++)
      if (sim.itemBoxRespawn[i] > 0) i,
  ],
  'mov': [
    for (final m in sim.movingHazards) {'x': round2(m.pos.x), 'y': round2(m.pos.y)},
  ],
  'events': [for (final e in sim.events) e.toJson()],
  'ack': {for (final e in acks.entries) '${e.key}': e.value},
  'left': sim.battleTicksLeft,
};

/// Applies a snapshot onto an existing sim (whose racers/track match).
void applySnapshot(RaceSim sim, Map<String, dynamic> j) {
  sim.tick = j['tick'] as int;
  sim.phase = RacePhase.values.firstWhere((p) => p.name == j['phase']);
  for (final rj in (j['racers'] as List).cast<Map<String, dynamic>>()) {
    final r = sim.racerBySlot(rj['s'] as int);
    if (r != null) applyRacerWire(r, rj);
  }
  sim.projectiles
    ..clear()
    ..addAll([
      for (final pj in (j['proj'] as List).cast<Map<String, dynamic>>())
        Projectile(
          id: pj['id'] as int,
          kind: ItemKindInfo.fromWire(pj['k'] as String)!,
          ownerSlot: pj['o'] as int,
          pos: V2((pj['x'] as num).toDouble(), (pj['y'] as num).toDouble()),
          heading: (pj['h'] as num).toDouble(),
          speed: 0,
        ),
    ]);
  sim.dropped
    ..clear()
    ..addAll([
      for (final dj in (j['drop'] as List).cast<Map<String, dynamic>>())
        DroppedHazard(id: dj['id'] as int, pos: V2((dj['x'] as num).toDouble(), (dj['y'] as num).toDouble()), ownerSlot: dj['o'] as int),
    ]);
  final gone = ((j['boxes'] as List?) ?? const []).cast<int>().toSet();
  for (var i = 0; i < sim.itemBoxRespawn.length; i++) {
    sim.itemBoxRespawn[i] = gone.contains(i) ? 1 : 0;
  }
  final mov = ((j['mov'] as List?) ?? const []).cast<Map<String, dynamic>>();
  for (var i = 0; i < mov.length && i < sim.movingHazards.length; i++) {
    sim.movingHazards[i].pos = V2((mov[i]['x'] as num).toDouble(), (mov[i]['y'] as num).toDouble());
  }
  sim.events
    ..clear()
    ..addAll([for (final ej in (j['events'] as List).cast<Map<String, dynamic>>()) SimEvent.fromJson(ej)]);
}

/// Grand Prix standing for one racer.
class Standing {
  const Standing({
    required this.slot,
    required this.name,
    required this.characterId,
    required this.kartId,
    required this.isBot,
    required this.platform,
    required this.points,
    required this.places,
  });

  final int slot;
  final String name;
  final String characterId;
  final String kartId;
  final bool isBot;
  final String platform;
  final int points;
  final List<int> places;

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'name': name,
    'character': characterId,
    'kart': kartId,
    'bot': isBot,
    'platform': platform,
    'points': points,
    'places': places,
  };

  static Standing fromJson(Map<String, dynamic> j) => Standing(
    slot: j['slot'] as int,
    name: j['name'] as String,
    characterId: j['character'] as String,
    kartId: j['kart'] as String,
    isBot: j['bot'] as bool,
    platform: (j['platform'] as String?) ?? '',
    points: j['points'] as int,
    places: (j['places'] as List).cast<int>(),
  );
}

/// Accumulates Grand Prix points over a cup. Ties are broken by best place,
/// then by slot so the ordering is total and deterministic.
List<Standing> computeStandings(List<List<RaceResult>> races) {
  final bySlot = <int, Standing>{};
  for (final race in races) {
    for (final r in race) {
      final prev = bySlot[r.slot];
      bySlot[r.slot] = Standing(
        slot: r.slot,
        name: r.name,
        characterId: r.characterId,
        kartId: r.kartId,
        isBot: r.isBot,
        platform: r.platform,
        points: (prev?.points ?? 0) + r.points,
        places: [...?prev?.places, r.place],
      );
    }
  }
  final list = bySlot.values.toList();
  list.sort((a, b) {
    if (a.points != b.points) return b.points.compareTo(a.points);
    final ba = a.places.reduce((x, y) => x < y ? x : y);
    final bb = b.places.reduce((x, y) => x < y ? x : y);
    if (ba != bb) return ba.compareTo(bb);
    return a.slot.compareTo(b.slot);
  });
  return list;
}
