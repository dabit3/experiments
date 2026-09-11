import 'dart:convert';
import 'dart:math' as math;

import 'package:nitro_core/nitro_core.dart';

/// Names used for server-side bots (original to Nitro Tots).
const botNames = <String>['Zippy', 'Waffles', 'Dot', 'Biscuit', 'Nova', 'Pudding', 'Sprocket', 'Mo'];

enum RoomStatus { lobby, racing, results, matchOver }

/// A connected (or temporarily disconnected) human player.
class Player {
  Player({
    required this.id,
    required this.token,
    required this.name,
    required this.characterId,
    required this.kartId,
    required this.platform,
    required this.send,
  });

  final String id;
  final String token;
  String name;
  String characterId;
  String kartId;
  String platform;
  bool ready = false;
  bool connected = true;
  int lastInputTick = -1;
  final InputBuffer input = InputBuffer();
  Map<String, dynamic>? testReport;

  /// Transport callback; swapped on reconnection.
  void Function(Map<String, dynamic>) send;

  PlayerInfo info({required bool isHost, int slot = -1}) => PlayerInfo(
    id: id,
    name: name,
    characterId: characterId,
    kartId: kartId,
    platform: platform,
    ready: ready,
    connected: connected,
    isHost: isHost,
    slot: slot,
  );
}

/// Result of a completed race, retained for Grand Prix standings.
class RoomRace {
  RoomRace(this.trackId, this.results);
  final String trackId;
  final List<RaceResult> results;
}

/// One lobby + match. Owns the authoritative [RaceSim] while racing.
class Room {
  Room({required this.code, required this.seed, required this.settings, required this.now, this.onEmpty, this.resultsDelayMs = 9000});

  final String code;
  final int seed;
  RoomSettings settings;

  /// Millisecond clock, injectable for tests.
  final int Function() now;
  final void Function(Room)? onEmpty;

  /// How long the results screen stays up before the next race auto-starts.
  final int resultsDelayMs;

  final List<Player> players = [];
  String? hostId;
  RoomStatus status = RoomStatus.lobby;
  RaceSim? sim;
  final Map<int, BotDriver> bots = {};
  final Map<int, String> slotToPlayer = {};
  final Map<String, int> playerToSlot = {};
  final List<RoomRace> races = [];
  int raceIndex = 0;
  int resultsShownAt = 0;
  int createdAt = 0;
  int lastActivity = 0;
  int _snapshotCounter = 0;
  int _raceSeed = 0;
  final List<SimEvent> _pendingEvents = [];

  /// Track ids for this match (cup order or the single selected track).
  List<String> get trackList {
    if (settings.mode == GameMode.battle) return [settings.trackId.isEmpty ? 'bowl' : settings.trackId];
    if (settings.grandPrix) {
      final cup = cups.where((c) => c.id == settings.cupId).firstOrNull ?? cups.first;
      return cup.trackIds;
    }
    return [settings.trackId];
  }

  int get totalRaces => trackList.length;

  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool get isEmpty => players.isEmpty;

  int get connectedCount => players.where((p) => p.connected).length;

  // ---------------------------------------------------------------------------
  // Lobby management

  String? addPlayer(Player p) {
    if (players.length >= settings.maxPlayers) return 'room_full';
    if (status != RoomStatus.lobby && status != RoomStatus.matchOver) return 'match_in_progress';
    players.add(p);
    hostId ??= p.id;
    lastActivity = now();
    broadcastRoomState();
    return null;
  }

  void removePlayer(String id) {
    final p = playerById(id);
    if (p == null) return;
    players.remove(p);
    if (hostId == id) hostId = players.isEmpty ? null : players.first.id;
    broadcast({'type': Msg.playerLeft, 'playerId': id});
    if (status == RoomStatus.racing) {
      // The kart keeps racing under bot control until the race ends.
      final slot = playerToSlot[id];
      if (slot != null) {
        final r = sim?.racerBySlot(slot);
        if (r != null) r.isBot = true;
      }
    }
    if (players.isEmpty) {
      onEmpty?.call(this);
    } else {
      broadcastRoomState();
    }
  }

  void setReady(String id, bool ready) {
    final p = playerById(id);
    if (p == null) return;
    p.ready = ready;
    broadcastRoomState();
    _maybeAutoStart();
  }

  void updateSettings(String id, Map<String, dynamic> patch) {
    if (id != hostId) return;
    settings = RoomSettings.fromJson({...settings.toJson(), ...patch});
    broadcastRoomState();
  }

  void updateProfile(String id, Map<String, dynamic> patch) {
    final p = playerById(id);
    if (p == null) return;
    if (patch['name'] is String && (patch['name'] as String).trim().isNotEmpty) {
      p.name = (patch['name'] as String).trim().substring(0, math.min(14, (patch['name'] as String).trim().length));
    }
    if (patch['character'] is String && characters.any((c) => c.id == patch['character'])) {
      p.characterId = patch['character'] as String;
    }
    if (patch['kart'] is String && karts.any((k) => k.id == patch['kart'])) {
      p.kartId = patch['kart'] as String;
    }
    if (patch['platform'] is String) p.platform = patch['platform'] as String;
    broadcastRoomState();
  }

  void _maybeAutoStart() {
    if (status != RoomStatus.lobby && status != RoomStatus.matchOver) return;
    final needed = math.max(2, settings.minPlayers);
    if (players.length >= needed && players.every((p) => p.ready && p.connected)) {
      startMatch(hostId!);
    }
  }

  Map<String, dynamic> roomStateJson() => {
    'type': Msg.roomState,
    'code': code,
    'hostId': hostId,
    'status': status.name,
    'settings': settings.toJson(),
    'players': [for (final p in players) p.info(isHost: p.id == hostId, slot: playerToSlot[p.id] ?? -1).toJson()],
    'raceIndex': raceIndex,
    'totalRaces': totalRaces,
    'standings': [for (final s in standings()) s.toJson()],
  };

  void broadcastRoomState() => broadcast(roomStateJson());

  void broadcast(Map<String, dynamic> msg) {
    for (final p in players) {
      if (p.connected) p.send(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // Match flow

  String? startMatch(String byId) {
    if (byId != hostId) return 'not_host';
    if (status == RoomStatus.racing) return 'already_racing';
    races.clear();
    raceIndex = 0;
    for (final p in players) {
      p.testReport = null;
    }
    _startRace();
    return null;
  }

  void _startRace() {
    final trackId = trackList[raceIndex];
    final track = trackById(trackId);
    final raceSeed = seed * 31 + raceIndex * 7 + 1;
    _raceSeed = raceSeed;
    final rng = Rng(raceSeed);
    slotToPlayer.clear();
    playerToSlot.clear();
    bots.clear();

    // Humans take the first slots in join order; bots fill the rest.
    final racers = <Racer>[];
    var slot = 0;
    for (final p in players) {
      p.ready = false;
      p.lastInputTick = -1;
      p.input.clear();
      racers.add(Racer(slot: slot, playerId: p.id, name: p.name, characterId: p.characterId, kartId: p.kartId, isBot: !p.connected, platform: p.platform));
      slotToPlayer[slot] = p.id;
      playerToSlot[p.id] = slot;
      slot++;
    }
    final fieldSize = settings.fillBots ? settings.maxPlayers : players.length;
    final taken = players.map((p) => p.characterId).toSet();
    final pool = characters.where((c) => !taken.contains(c.id)).toList();
    var botIdx = 0;
    while (slot < fieldSize) {
      final c = pool.isEmpty ? characters[rng.nextInt(characters.length)] : pool.removeAt(rng.nextInt(pool.length));
      final k = karts[rng.nextInt(karts.length)];
      racers.add(Racer(slot: slot, playerId: '', name: botNames[botIdx % botNames.length], characterId: c.id, kartId: k.id, isBot: true, platform: 'bot'));
      bots[slot] = BotDriver(slot: slot, seed: raceSeed, skill: (settings.botSkill - 0.15 + 0.3 * rng.nextDouble()).clamp(0.2, 1.0));
      botIdx++;
      slot++;
    }
    // Disconnected humans and bots all use drivers.
    for (final r in racers) {
      bots.putIfAbsent(r.slot, () => BotDriver(slot: r.slot, seed: raceSeed, skill: settings.botSkill));
    }

    sim = RaceSim(track: track, racers: racers, seed: raceSeed, laps: settings.laps, mode: settings.mode, battleSeconds: settings.battleSeconds);
    status = RoomStatus.racing;
    _snapshotCounter = 0;
    _pendingEvents.clear();
    broadcastRoomState();
    broadcast(matchStartJson());
  }

  Map<String, dynamic> matchStartJson() => {
    'type': Msg.matchStart,
    'code': code,
    'raceIndex': raceIndex,
    'totalRaces': totalRaces,
    'trackId': trackList[raceIndex],
    'seed': _raceSeed,
    'laps': settings.laps,
    'mode': settings.mode.name,
    'battleSeconds': settings.battleSeconds,
    'tick': sim!.tick,
    'racers': [
      for (final r in sim!.racers)
        {'slot': r.slot, 'playerId': r.playerId, 'name': r.name, 'character': r.characterId, 'kart': r.kartId, 'bot': r.isBot, 'platform': r.platform},
    ],
  };

  void handleInput(String playerId, Map<String, dynamic> j) {
    final p = playerById(playerId);
    if (p == null || status != RoomStatus.racing) return;
    p.input.add(KartInput.fromJson(j));
    p.lastInputTick = (j['tick'] as num?)?.toInt() ?? p.lastInputTick;
    lastActivity = now();
  }

  /// Advances the authoritative simulation by one tick and broadcasts a
  /// snapshot every other tick.
  void tick() {
    final s = sim;
    if (s == null) return;
    if (status == RoomStatus.racing) {
      final inputs = <int, KartInput>{};
      for (final p in players) {
        final slot = playerToSlot[p.id];
        if (slot == null) continue;
        final racer = s.racerBySlot(slot);
        if (racer == null) continue;
        if (p.connected) {
          racer.isBot = false;
          inputs[slot] = p.input.consume();
        } else {
          racer.isBot = true;
        }
      }
      s.step(inputs, (sim, r) => bots[r.slot]!.drive(sim, r));
      _pendingEvents.addAll(s.events);
      _snapshotCounter++;
      if (_snapshotCounter % 2 == 0 || s.phase == RacePhase.finished) {
        final saved = List.of(s.events);
        s.events
          ..clear()
          ..addAll(_pendingEvents);
        final snap = snapshotToWire(
          s,
          acks: {
            for (final p in players)
              if (playerToSlot[p.id] != null) playerToSlot[p.id]!: p.lastInputTick,
          },
        );
        s.events
          ..clear()
          ..addAll(saved);
        _pendingEvents.clear();
        broadcast(snap);
      }
      if (s.phase == RacePhase.finished) {
        _finishRace();
      }
    } else if (status == RoomStatus.results) {
      if (now() - resultsShownAt >= resultsDelayMs) {
        _advance();
      }
    }
  }

  void _finishRace() {
    final s = sim!;
    races.add(RoomRace(trackList[raceIndex], s.results!));
    status = RoomStatus.results;
    resultsShownAt = now();
    broadcastRoomState();
    broadcast({
      'type': Msg.raceFinished,
      'raceIndex': raceIndex,
      'totalRaces': totalRaces,
      'trackId': trackList[raceIndex],
      'results': [for (final r in s.results!) r.toJson()],
      'standings': [for (final st in standings()) st.toJson()],
      'nextInMs': resultsDelayMs,
      'isLast': raceIndex + 1 >= totalRaces,
    });
  }

  /// Host-triggered skip of the results timer.
  String? nextRace(String byId) {
    if (byId != hostId) return 'not_host';
    if (status != RoomStatus.results) return 'not_in_results';
    _advance();
    return null;
  }

  void _advance() {
    if (raceIndex + 1 < totalRaces) {
      raceIndex++;
      _startRace();
    } else {
      status = RoomStatus.matchOver;
      broadcast({
        'type': Msg.matchOver,
        'standings': [for (final st in standings()) st.toJson()],
        'races': [
          for (final r in races)
            {
              'trackId': r.trackId,
              'results': [for (final x in r.results) x.toJson()],
            },
        ],
        'hash': resultHash(),
      });
      sim = null;
      raceIndex = 0;
      for (final p in players) {
        p.ready = false;
      }
      broadcastRoomState();
    }
  }

  List<Standing> standings() => races.isEmpty ? const [] : computeStandings([for (final r in races) r.results]);

  /// Stable digest of the complete match outcome, used by the cross-platform
  /// test to prove every client saw the same result.
  String resultHash() {
    final payload = jsonEncode([
      for (final r in races)
        {
          'track': r.trackId,
          'order': [for (final x in r.results) '${x.slot}:${x.place}:${x.points}'],
        },
      [for (final s in standings()) '${s.slot}:${s.points}'],
    ]);
    // FNV-1a 32-bit; stable across Dart VM and dart2js.
    var h = 0x811c9dc5;
    for (final c in utf8.encode(payload)) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  void recordTestReport(String playerId, Map<String, dynamic> report) {
    final p = playerById(playerId);
    if (p == null) return;
    // Merge so a later phase report does not drop the match hash.
    p.testReport = {...?p.testReport, ...report}..remove('type');
  }

  Map<String, dynamic> inspectJson() => {
    'code': code,
    'status': status.name,
    'seed': seed,
    'settings': settings.toJson(),
    'players': [
      for (final p in players)
        {...p.info(isHost: p.id == hostId, slot: playerToSlot[p.id] ?? -1).toJson(), 'lastInputTick': p.lastInputTick, 'testReport': p.testReport},
    ],
    'raceIndex': raceIndex,
    'totalRaces': totalRaces,
    'tick': sim?.tick,
    'phase': sim?.phase.name,
    'races': [
      for (final r in races)
        {
          'trackId': r.trackId,
          'results': [for (final x in r.results) x.toJson()],
        },
    ],
    'standings': [for (final s in standings()) s.toJson()],
    'hash': races.isEmpty ? null : resultHash(),
  };
}
