import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:nitro_core/nitro_core.dart';

/// Where a racer should be drawn this frame (smoothed between sim ticks or
/// server snapshots).
class RenderPose {
  RenderPose(this.pos, this.heading);
  V2 pos;
  double heading;
}

/// Describes a match to the race screen (both offline and online).
class MatchInfo {
  const MatchInfo({
    required this.trackId,
    required this.laps,
    required this.mode,
    required this.raceIndex,
    required this.totalRaces,
    this.battleSeconds = 120,
    this.online = false,
    this.timeTrial = false,
  });

  final String trackId;
  final int laps;
  final GameMode mode;
  final int raceIndex;
  final int totalRaces;
  final int battleSeconds;
  final bool online;
  final bool timeTrial;
}

/// A running race, either simulated locally or mirrored from the server.
abstract class RaceSession extends ChangeNotifier {
  RaceSim get sim;
  MatchInfo get info;
  int get localSlot;
  Racer? get local => sim.racerBySlot(localSlot);
  bool get finished => sim.phase == RacePhase.finished;

  /// Latest input from the controller; consumed each simulation tick.
  KartInput input = KartInput.idle;

  /// Fired once per race when results are final.
  final ValueNotifier<List<RaceResult>?> results = ValueNotifier(null);

  /// Events produced since the last frame (for sound/particles).
  final List<SimEvent> frameEvents = [];

  /// Called by the game loop every rendered frame.
  void advance(double dt);

  RenderPose poseOf(Racer r);

  /// Wall-clock seconds since the session started (for HUD timers).
  double get elapsed;

  /// Position of the ghost kart in time trials, if any.
  RenderPose? get ghostPose => null;

  /// Cached previous-tick poses used for interpolation.
  final Map<int, RenderPose> prevPoses = {};
  final Map<int, RenderPose> currPoses = {};
  double _alpha = 1;

  @protected
  void capturePoses() {
    for (final r in sim.racers) {
      final c = currPoses[r.slot];
      if (c == null) {
        prevPoses[r.slot] = RenderPose(r.pos, r.heading);
        currPoses[r.slot] = RenderPose(r.pos, r.heading);
      } else {
        prevPoses[r.slot] = RenderPose(c.pos, c.heading);
        c.pos = r.pos;
        c.heading = r.heading;
      }
    }
  }

  @protected
  set alpha(double a) => _alpha = a.clamp(0.0, 1.0);

  @protected
  RenderPose interpolated(Racer r) {
    final p = prevPoses[r.slot];
    final c = currPoses[r.slot];
    if (p == null || c == null) return RenderPose(r.pos, r.heading);
    // Teleports (respawn) should snap rather than slide.
    if (p.pos.distanceTo(c.pos) > 60) return RenderPose(c.pos, c.heading);
    return RenderPose(V2(lerpD(p.pos.x, c.pos.x, _alpha), lerpD(p.pos.y, c.pos.y, _alpha)), p.heading + wrapAngle(c.heading - p.heading) * _alpha);
  }
}

/// Offline race against deterministic bots (quick race, GP, time trial,
/// battle practice).
class LocalSession extends RaceSession {
  LocalSession({required this.sim, required this.info, required this.localSlot, required int seed, double botSkill = 0.7, this.ghost, Rng? rng}) {
    final r = rng ?? Rng(seed + 99);
    for (final racer in sim.racers) {
      if (racer.slot != localSlot) {
        _bots[racer.slot] = BotDriver(slot: racer.slot, seed: seed, skill: (botSkill - 0.15 + 0.3 * r.nextDouble()).clamp(0.2, 1.0));
      }
    }
    capturePoses();
  }

  @override
  final RaceSim sim;
  @override
  final MatchInfo info;
  @override
  final int localSlot;

  /// Recorded ghost run for time trials: list of [x, y, heading] per tick.
  final List<List<double>>? ghost;
  final List<List<double>> recording = [];
  final Map<int, BotDriver> _bots = {};
  double _acc = 0;
  double _elapsed = 0;

  @override
  double get elapsed => _elapsed;

  @override
  void advance(double dt) {
    if (finished) {
      alpha = 1;
      return;
    }
    _elapsed += dt;
    _acc += math.min(dt, 0.25);
    while (_acc >= tickDt) {
      _acc -= tickDt;
      capturePoses();
      sim.step({localSlot: input}, (s, r) => _bots[r.slot]!.drive(s, r));
      frameEvents.addAll(sim.events);
      if (info.timeTrial && sim.phase == RacePhase.racing) {
        final me = local!;
        recording.add([me.pos.x, me.pos.y, me.heading]);
      }
      if (sim.phase == RacePhase.finished && results.value == null) {
        results.value = sim.results;
        notifyListeners();
      }
    }
    alpha = _acc / tickDt;
  }

  @override
  RenderPose poseOf(Racer r) => interpolated(r);

  @override
  RenderPose? get ghostPose {
    final g = ghost;
    if (g == null || g.isEmpty) return null;
    final idx = (sim.tick - countdownTicks).clamp(0, g.length - 1);
    final f = g[idx];
    return RenderPose(V2(f[0], f[1]), f[2]);
  }
}
