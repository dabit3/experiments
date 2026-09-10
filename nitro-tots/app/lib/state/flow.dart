import 'package:flutter/foundation.dart';
import 'package:nitro_core/nitro_core.dart';

import '../game/session.dart';
import 'app_state.dart';

enum PlayMode { grandPrix, quickRace, timeTrial, battle, online }

/// Offline match setup + Grand Prix progression. Online matches are owned
/// by [NetClient]; this only carries the chosen play mode to the lobby.
class GameFlow extends ChangeNotifier {
  GameFlow(this.app);

  final AppState app;

  PlayMode mode = PlayMode.grandPrix;
  String cupId = cups.first.id;
  String trackId = raceTrackDefs.first.id;
  int laps = 3;
  int racerCount = 8;
  double botSkill = 0.7;
  int seed = DateTime.now().millisecondsSinceEpoch & 0xffff;

  int raceIndex = 0;

  /// Bot line-up for the current series, fixed so cup rivals keep their
  /// identity from race to race.
  List<({String name, String characterId, String kartId})> _roster = const [];
  final Map<int, Standing> standings = {};
  final List<({String trackId, List<RaceResult> results})> raceHistory = [];
  LocalSession? session;

  bool get isSeries => mode == PlayMode.grandPrix;
  List<String> get trackIds => isSeries ? cupById(cupId).trackIds : [trackId];
  int get totalRaces => trackIds.length;
  bool get isLastRace => raceIndex >= totalRaces - 1;

  void choose(PlayMode m) {
    mode = m;
    if (m == PlayMode.battle) trackId = arenaDefs.first.id;
    if (m != PlayMode.battle && trackDefById(trackId).isArena) trackId = raceTrackDefs.first.id;
    notifyListeners();
  }

  void setTrack(String id) {
    trackId = id;
    notifyListeners();
  }

  void setCup(String id) {
    cupId = id;
    notifyListeners();
  }

  void setOptions({int? laps, int? racers, double? skill}) {
    this.laps = laps ?? this.laps;
    racerCount = racers ?? racerCount;
    botSkill = skill ?? botSkill;
    notifyListeners();
  }

  /// Starts a fresh series (or single race) from the first track.
  void startSeries() {
    raceIndex = 0;
    standings.clear();
    raceHistory.clear();
    seed = DateTime.now().millisecondsSinceEpoch & 0xffff;
    _roster = _buildRoster();
    _buildSession();
  }

  List<({String name, String characterId, String kartId})> _buildRoster() {
    final isTT = mode == PlayMode.timeTrial;
    final count = isTT ? 1 : racerCount.clamp(2, 8);
    final rng = Rng(seed);
    final pool = characters.where((c) => c.id != app.characterId).toList();
    for (var i = pool.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final t = pool[i];
      pool[i] = pool[j];
      pool[j] = t;
    }
    return [
      for (var i = 1; i < count; i++)
        (name: pool[(i - 1) % pool.length].name, characterId: pool[(i - 1) % pool.length].id, kartId: karts[rng.nextInt(karts.length)].id),
    ];
  }

  void nextRace() {
    raceIndex++;
    _buildSession();
  }

  void retry() => _buildSession();

  void _buildSession() {
    session?.dispose();
    final tid = trackIds[raceIndex];
    final track = trackById(tid);
    final isTT = mode == PlayMode.timeTrial;
    final isBattle = mode == PlayMode.battle;
    if (_roster.isEmpty && !isTT) _roster = _buildRoster();
    final racers = <Racer>[
      Racer(slot: 0, playerId: 'local', name: app.name, characterId: app.characterId, kartId: app.kartId, isBot: false, platform: AppState.platformId),
      if (!isTT)
        for (final (i, b) in _roster.indexed)
          Racer(slot: i + 1, playerId: 'bot${i + 1}', name: b.name, characterId: b.characterId, kartId: b.kartId, isBot: true, platform: 'bot'),
    ];
    final raceSeed = seed * 31 + raceIndex * 7 + 1;
    final sim = RaceSim(
      track: track,
      racers: racers,
      seed: raceSeed,
      laps: isBattle ? 1 : laps,
      mode: isBattle ? GameMode.battle : GameMode.race,
      battleSeconds: 120,
    );
    final ghost = isTT ? app.ghosts[tid] : null;
    session = LocalSession(
      sim: sim,
      info: MatchInfo(
        trackId: tid,
        laps: isBattle ? 1 : laps,
        mode: isBattle ? GameMode.battle : GameMode.race,
        raceIndex: raceIndex,
        totalRaces: totalRaces,
        battleSeconds: 120,
        online: false,
        timeTrial: isTT,
      ),
      localSlot: 0,
      seed: raceSeed,
      botSkill: botSkill,
      ghost: ghost == null ? null : [for (final f in ghost['frames'] as List) (f as List).cast<num>().map((n) => n.toDouble()).toList()],
    );
    notifyListeners();
  }

  /// Records a finished race into the series standings and ghost store.
  void recordResults(List<RaceResult> results) {
    final s = session;
    if (s == null) return;
    raceHistory.add((trackId: s.info.trackId, results: results));
    final merged = _merged(results);
    standings
      ..clear()
      ..addAll(merged);
    if (s.info.timeTrial) {
      final me = results.firstWhere((r) => r.slot == 0);
      final best = app.ghosts[s.info.trackId];
      final bestTicks = best == null ? 1 << 30 : best['ticks'] as int;
      if (me.finishTick > 0 && me.raceTicks < bestTicks) {
        app.saveGhost(s.info.trackId, {'ticks': me.raceTicks, 'frames': s.recording});
      }
    }
    notifyListeners();
  }

  Map<int, Standing> _merged(List<RaceResult> results) => {
    ...standings,
    for (final r in results)
      r.slot: Standing(
        slot: r.slot,
        name: r.name,
        characterId: r.characterId,
        kartId: r.kartId,
        isBot: r.isBot,
        platform: r.platform,
        points: (standings[r.slot]?.points ?? 0) + r.points,
        places: [...?standings[r.slot]?.places, r.place],
      ),
  };

  static List<Standing> _sorted(Iterable<Standing> values) => values.toList()
    ..sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      return a.slot.compareTo(b.slot);
    });

  List<Standing> get sortedStandings => _sorted(standings.values);

  /// Cup standings as they will read once [results] are recorded; used by the
  /// between-race results panel before the player continues.
  List<Standing> standingsAfter(List<RaceResult> results) => _sorted(_merged(results).values);

  void endSeries() {
    session?.dispose();
    session = null;
    notifyListeners();
  }
}
