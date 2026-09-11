import 'dart:math' as math;

import 'items.dart';
import 'math.dart';
import 'sim.dart';
import 'track.dart';

/// Deterministic AI driver. One instance per bot slot; all randomness comes
/// from a seeded [Rng] so identical seeds reproduce identical races.
class BotDriver {
  BotDriver({required this.slot, required int seed, this.skill = 0.7}) : _rng = Rng(seed * 7919 + slot * 104729 + 17);

  final int slot;
  final double skill;
  final Rng _rng;

  double _bias = 0;
  int _biasTicks = 0;
  int _itemHold = 0;
  int _lift = 0;
  bool _prevDrift = false;

  KartInput drive(RaceSim sim, Racer r) {
    if (sim.phase == RacePhase.countdown) {
      // Time the rocket start.
      final until = sim.raceStartTick - sim.tick;
      return KartInput(throttle: until <= 14 + (skill * 8).round() ? 1 : 0);
    }
    if (sim.isBattle) return _battle(sim, r);

    final track = sim.track;
    if (_biasTicks <= 0) {
      _biasTicks = 40 + _rng.nextInt(60);
      final width = track.samples[r.nearest].width;
      _bias = (_rng.nextDouble() * 2 - 1) * width * (0.12 + 0.2 * (1 - skill));
    }
    _biasTicks--;

    // Avoid hazards a little ahead.
    var avoid = 0.0;
    final fwd = V2.fromAngle(r.heading);
    void consider(V2 p, double radius) {
      final d = p - r.pos;
      final lon = d.dot(fwd);
      final lat = d.cross(fwd);
      if (lon > -4 && lon < 90 && lat.abs() < radius) {
        final weight = 1.0 + (1 - lon / 90);
        // Steer to whichever side has more room; default away from the hazard.
        avoid += (lat > 0 ? -1 : 1) * weight;
      }
    }

    for (final h in track.hazards) {
      if (h.kind != HazardKind.roller) consider(h.pos, h.kind == HazardKind.pillar ? 15 : 11);
    }
    for (final m in sim.movingHazards) {
      consider(m.pos, 12);
    }
    for (final d in sim.dropped) {
      consider(d.pos, 9);
    }
    for (final p in sim.projectiles) {
      if (p.kind == ItemKind.orb) consider(p.pos, 9);
    }

    final bias = _bias + avoid * 14;
    final curvature = _curvatureAhead(sim, r.nearest);
    final lookAhead = sim.lookAheadFor(r) + (skill * 3).round();
    final err = sim.lineError(r, lateralBias: bias, lookAhead: lookAhead);
    final wantsDrift = skill > 0.35 && curvature.abs() > 0.2 && r.speed > r.maxSpeed * 0.6 && err.sign == curvature.sign;
    var input = sim.racingLineInput(r, lateralBias: bias, lookAhead: lookAhead, drift: wantsDrift);
    if (wantsDrift && !r.isDrifting && !_prevDrift) {
      // Steer strongly into the corner on the tick the drift starts so the
      // hop registers a direction.
      input = input.copyWith(steer: curvature > 0 ? 1 : -1);
    }
    if (r.isDrifting) {
      // Release when the corner opens up or the line is now on the other side.
      if (curvature.abs() < 0.08 || err * r.driftDir < -0.12) {
        input = input.copyWith(drift: false);
      } else {
        input = input.copyWith(drift: true);
      }
    }
    _prevDrift = input.drift;

    // Occasional throttle lifts for lower skill.
    if (_lift > 0) {
      _lift--;
      input = input.copyWith(throttle: 0.2);
    } else if (_rng.nextInt(1000) < ((1 - skill) * 25).round()) {
      _lift = 8 + _rng.nextInt(10);
    }

    // Items.
    if (r.item != null) {
      _itemHold++;
      final useNow = switch (r.item!) {
        ItemKind.turbo || ItemKind.tripleTurbo => curvature.abs() < 0.12 && _itemHold > 10,
        ItemKind.rocket => _itemHold > 15 && r.position > 1,
        ItemKind.orb => _itemHold > 12 && r.position > 1 && _opponentInFront(sim, r),
        ItemKind.slick => _itemHold > 30 + _rng.nextInt(60),
        ItemKind.shield => _itemHold > 40 || _threatBehind(sim, r),
        ItemKind.zap => _itemHold > 20,
        ItemKind.comet => _itemHold > 5,
      };
      if (useNow) {
        _itemHold = 0;
        input = input.copyWith(item: true);
      }
    } else {
      _itemHold = 0;
    }
    return input;
  }

  KartInput _battle(RaceSim sim, Racer r) {
    Racer? target;
    var best = double.infinity;
    for (final o in sim.racers) {
      if (o.slot == r.slot || o.respawnTicks > 0) continue;
      final d = o.pos.distanceTo(r.pos);
      if (d < best) {
        best = d;
        target = o;
      }
    }
    final track = sim.track;
    V2 goal;
    if (r.item == null) {
      // Nearest live item box.
      goal = target?.pos ?? track.samples[0].pos;
      var bd = double.infinity;
      for (var i = 0; i < track.itemBoxes.length; i++) {
        if (sim.itemBoxRespawn[i] > 0) continue;
        final d = track.itemBoxes[i].pos.distanceTo(r.pos);
        if (d < bd) {
          bd = d;
          goal = track.itemBoxes[i].pos;
        }
      }
    } else {
      goal = target?.pos ?? r.pos + V2.fromAngle(r.heading, 50);
    }
    final want = (goal - r.pos).angle;
    final d = wrapAngle(want - r.heading);
    var input = KartInput(throttle: 1, steer: (d * 2.5).clamp(-1.0, 1.0));
    if (r.item != null && target != null) {
      final facing = d.abs() < 0.35 && best < 160;
      final useNow = switch (r.item!) {
        ItemKind.rocket || ItemKind.orb => facing,
        ItemKind.slick => best < 30,
        ItemKind.shield => _threatBehind(sim, r) || _rng.nextInt(100) < 2,
        _ => true,
      };
      if (useNow) input = input.copyWith(item: true);
    }
    return input;
  }

  bool _opponentInFront(RaceSim sim, Racer r) {
    final fwd = V2.fromAngle(r.heading);
    for (final o in sim.racers) {
      if (o.slot == r.slot) continue;
      final d = o.pos - r.pos;
      final lon = d.dot(fwd);
      if (lon > 0 && lon < 220 && d.cross(fwd).abs() < 14) return true;
    }
    return false;
  }

  bool _threatBehind(RaceSim sim, Racer r) {
    for (final p in sim.projectiles) {
      if (p.ownerSlot != r.slot && p.pos.distanceTo(r.pos) < 60) return true;
    }
    return false;
  }

  /// Heading change of the centerline over the next ~150 world units.
  static double _curvatureAhead(RaceSim sim, int nearest) {
    final track = sim.track;
    final a = track.samples[(nearest + sim.samplesFor(40)) % Track.sampleCount].tangent.angle;
    final b = track.samples[(nearest + sim.samplesFor(190)) % Track.sampleCount].tangent.angle;
    return wrapAngle(b - a);
  }
}

/// Scripted driver used by the automated cross-platform test. It follows the
/// racing line with a fixed lateral lane per client so each platform behaves
/// predictably, and fires items as soon as it gets them.
class Autopilot {
  Autopilot({required this.lane});

  /// Lateral bias in world units.
  final double lane;
  int _hold = 0;

  KartInput drive(RaceSim sim, Racer r) {
    if (sim.phase == RacePhase.countdown) {
      return KartInput(throttle: sim.raceStartTick - sim.tick <= 18 ? 1 : 0);
    }
    if (sim.isBattle) {
      return BotDriver(slot: r.slot, seed: 1, skill: 0.8).drive(sim, r);
    }
    var input = sim.racingLineInput(r, lateralBias: lane, lookAhead: sim.lookAheadFor(r));
    final curvature = BotDriver._curvatureAhead(sim, r.nearest);
    if (curvature.abs() > 0.25 && r.speed > r.maxSpeed * 0.6) {
      input = input.copyWith(drift: true, steer: r.isDrifting ? input.steer : (curvature > 0 ? 1.0 : -1.0));
    }
    if (r.item != null) {
      _hold++;
      if (_hold > 20) {
        _hold = 0;
        input = input.copyWith(item: true);
      }
    }
    return input;
  }
}

double signOf(double v) => v > 0 ? 1 : (v < 0 ? -1 : 0);

double clampAbs(double v, double max) => math.max(-max, math.min(max, v));
