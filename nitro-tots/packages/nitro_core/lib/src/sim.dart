import 'dart:math' as math;

import 'items.dart';
import 'math.dart';
import 'roster.dart';
import 'track.dart';

/// Simulation runs at a fixed 30 Hz.
const ticksPerSecond = 30;
const tickDt = 1 / ticksPerSecond;

/// Countdown length before the lights go green (3, 2, 1, GO).
const countdownTicks = 4 * ticksPerSecond;

/// Angle (radians) between the kart's facing and its travel direction while
/// drifting.
const driftSlide = 0.2;

/// Ticks after a hit during which static hazards cannot re-trigger.
const hitImmunityTicks = 90;

enum RacePhase { countdown, racing, finished }

/// Mini-turbo tier for an accumulated drift charge (ticks).
int driftTierFor(int charge) => charge >= 110 ? 3 : (charge >= 60 ? 2 : (charge >= 24 ? 1 : 0));

enum GameMode { race, timeTrial, battle }

class KartInput {
  const KartInput({this.throttle = 0, this.steer = 0, this.drift = false, this.item = false, this.lookBack = false});

  static const idle = KartInput();

  /// -1 (brake/reverse) .. 1 (accelerate).
  final double throttle;

  /// -1 (left) .. 1 (right).
  final double steer;
  final bool drift;

  /// Edge-triggered: true on the tick the item button was pressed.
  final bool item;

  /// Throw dropped items forward instead of backward (or fire rockets back).
  final bool lookBack;

  Map<String, dynamic> toJson() => {'t': round2(throttle), 's': round2(steer), if (drift) 'd': 1, if (item) 'i': 1, if (lookBack) 'b': 1};

  static KartInput fromJson(Map<String, dynamic> j) => KartInput(
    throttle: (j['t'] as num? ?? 0).toDouble(),
    steer: (j['s'] as num? ?? 0).toDouble(),
    drift: j['d'] == 1,
    item: j['i'] == 1,
    lookBack: j['b'] == 1,
  );

  KartInput copyWith({double? throttle, double? steer, bool? drift, bool? item, bool? lookBack}) => KartInput(
    throttle: throttle ?? this.throttle,
    steer: steer ?? this.steer,
    drift: drift ?? this.drift,
    item: item ?? this.item,
    lookBack: lookBack ?? this.lookBack,
  );
}

/// Full mutable state for one kart.
class Racer {
  Racer({
    required this.slot,
    required this.playerId,
    required this.name,
    required this.characterId,
    required this.kartId,
    required this.isBot,
    this.platform = '',
    this.botSkill = 0.7,
  }) : stats = RacerStats(characterById(characterId), kartById(kartId));

  final int slot;
  String playerId;
  String name;
  String characterId;
  String kartId;
  bool isBot;
  String platform;
  double botSkill;
  RacerStats stats;

  V2 pos = V2.zero;
  double heading = 0;
  double speed = 0;
  int driftDir = 0;
  int driftCharge = 0;
  int hopTicks = 0;
  int boostTicks = 0;
  double boostMult = 1;
  int boostTier = 0;
  int airTicks = 0;
  bool trickReady = false;
  bool trickDone = false;
  int spinTicks = 0;
  int shieldTicks = 0;
  int zapTicks = 0;
  int cometTicks = 0;
  int stallTicks = 0;
  int slipTicks = 0;
  int throttleHeldTicks = 0;
  int lap = 0;
  int checkpoint = 0;
  int nearest = 0;
  Surface surface = Surface.road;
  int position = 1;
  bool finished = false;
  int finishTick = 0;

  /// Race time excluding the start countdown, matching the HUD clock.
  int get raceTicks => math.max(0, finishTick - countdownTicks);
  List<int> lapTicks = [];
  int lapStartTick = 0;
  ItemKind? item;
  int itemCharges = 0;
  int rouletteTicks = 0;
  int wrongWayTicks = 0;
  int balloons = 3;
  int score = 0;
  int respawnTicks = 0;
  bool prevItemButton = false;
  bool prevDrift = false;
  int lastHitTick = -1000;
  int bumpCooldown = 0;

  bool get isDrifting => driftDir != 0;

  /// Mini-turbo tier the current drift would release (0 = none yet).
  int get driftTierPreview => isDrifting ? driftTierFor(driftCharge) : 0;
  bool get isAirborne => airTicks > 0;
  bool get isSpinning => spinTicks > 0;
  bool get hasShield => shieldTicks > 0;
  bool get isComet => cometTicks > 0;
  bool get isRolling => rouletteTicks > 0;
  bool get controllable => !finished && spinTicks == 0 && stallTicks == 0 && cometTicks == 0 && respawnTicks == 0;

  /// Laps plus fractional distance around the track, used for ordering. A
  /// racer whose sector is far ahead of its last checkpoint is behind the
  /// start line (grid or wrong way), so it counts against the previous lap.
  double progress(Track track) {
    final behindLine = track.checkpointOf(nearest) > checkpoint + 2;
    return (behindLine ? lap - 1 : lap) + track.progressOf(nearest);
  }

  double get maxSpeed => 74 + 38 * stats.speed;
}

class Projectile {
  Projectile({
    required this.id,
    required this.kind,
    required this.ownerSlot,
    required this.pos,
    required this.heading,
    required this.speed,
    this.targetSlot,
    this.bounces = 0,
    this.life = 0,
  });

  final int id;
  final ItemKind kind;
  final int ownerSlot;
  V2 pos;
  double heading;
  double speed;
  int? targetSlot;
  int bounces;
  int life;
  int nearest = 0;
}

class DroppedHazard {
  DroppedHazard({required this.id, required this.pos, required this.ownerSlot, this.life = 0});
  final int id;
  V2 pos;
  final int ownerSlot;
  int life;
}

class MovingHazard {
  MovingHazard(this.def, this.pos);
  final PlacedHazard def;
  V2 pos;
  double phase = 0;
}

/// A discrete gameplay event emitted during a tick, for client feedback.
class SimEvent {
  const SimEvent(this.type, {this.slot = -1, this.other = -1, this.value = 0, this.item});
  final String type;
  final int slot;
  final int other;
  final int value;
  final ItemKind? item;

  Map<String, dynamic> toJson() => {
    'e': type,
    if (slot >= 0) 'r': slot,
    if (other >= 0) 'o': other,
    if (value != 0) 'v': value,
    if (item != null) 'k': item!.wire,
  };

  static SimEvent fromJson(Map<String, dynamic> j) => SimEvent(
    j['e'] as String,
    slot: (j['r'] as int?) ?? -1,
    other: (j['o'] as int?) ?? -1,
    value: (j['v'] as int?) ?? 0,
    item: ItemKindInfo.fromWire(j['k'] as String?),
  );
}

class RaceResult {
  const RaceResult({
    required this.slot,
    required this.name,
    required this.characterId,
    required this.kartId,
    required this.isBot,
    required this.platform,
    required this.place,
    required this.finishTick,
    required this.lapTicks,
    required this.points,
    required this.score,
  });

  final int slot;
  final String name;
  final String characterId;
  final String kartId;
  final bool isBot;
  final String platform;
  final int place;
  final int finishTick;

  /// Race time excluding the start countdown, matching the HUD clock.
  int get raceTicks => math.max(0, finishTick - countdownTicks);
  final List<int> lapTicks;
  final int points;
  final int score;

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'name': name,
    'character': characterId,
    'kart': kartId,
    'bot': isBot,
    'platform': platform,
    'place': place,
    'finishTick': finishTick,
    'lapTicks': lapTicks,
    'points': points,
    'score': score,
  };

  static RaceResult fromJson(Map<String, dynamic> j) => RaceResult(
    slot: j['slot'] as int,
    name: j['name'] as String,
    characterId: j['character'] as String,
    kartId: j['kart'] as String,
    isBot: j['bot'] as bool,
    platform: (j['platform'] as String?) ?? '',
    place: j['place'] as int,
    finishTick: j['finishTick'] as int,
    lapTicks: (j['lapTicks'] as List).cast<int>(),
    points: j['points'] as int,
    score: (j['score'] as int?) ?? 0,
  );
}

/// Points awarded by finishing place (index 0 = first).
const pointsTable = <int>[15, 12, 10, 9, 8, 7, 6, 5];

int pointsForPlace(int place) => place >= 1 && place <= pointsTable.length ? pointsTable[place - 1] : 0;

/// Deterministic race simulation shared by the server (authority), the
/// offline modes and client-side prediction.
class RaceSim {
  RaceSim({required this.track, required this.racers, required int seed, this.laps = 3, this.mode = GameMode.race, this.battleSeconds = 120})
    : rng = Rng(seed) {
    for (final r in racers) {
      final gridIndex = r.slot % track.startGrid.length;
      r.pos = track.startGrid[gridIndex];
      r.nearest = track.nearestIndex(r.pos);
      r.heading = track.samples[r.nearest].tangent.angle;
      if (track.isArena) {
        // Spread battle racers around the ring.
        final s = track.sampleAt(r.slot / racers.length);
        r.pos = s.pos;
        r.heading = s.tangent.angle;
        r.nearest = track.nearestIndex(r.pos);
      }
    }
    itemBoxRespawn = List.filled(track.itemBoxes.length, 0);
    movingHazards = [
      for (final h in track.hazards)
        if (h.kind == HazardKind.roller) MovingHazard(h, h.pos),
    ];
  }

  final Track track;
  final List<Racer> racers;
  final Rng rng;
  final int laps;
  final GameMode mode;
  final int battleSeconds;

  int tick = 0;
  RacePhase phase = RacePhase.countdown;
  final List<Projectile> projectiles = [];
  final List<DroppedHazard> dropped = [];
  late List<int> itemBoxRespawn;
  late List<MovingHazard> movingHazards;
  final List<SimEvent> events = [];
  int _nextId = 1;
  int firstFinishTick = -1;
  List<RaceResult>? results;

  bool get isBattle => mode == GameMode.battle;
  int get raceStartTick => countdownTicks;

  /// Ticks left in battle mode.
  int get battleTicksLeft => math.max(0, raceStartTick + battleSeconds * ticksPerSecond - tick);

  Racer? racerBySlot(int slot) {
    for (final r in racers) {
      if (r.slot == slot) return r;
    }
    return null;
  }

  /// Advances the simulation by one tick. [inputs] maps slot -> input for
  /// human-controlled racers; bots are driven by [botInput].
  void step(Map<int, KartInput> inputs, KartInput Function(RaceSim, Racer) botInput) {
    events.clear();
    if (phase == RacePhase.finished) {
      tick++;
      return;
    }
    if (phase == RacePhase.countdown && tick >= raceStartTick) {
      phase = RacePhase.racing;
      events.add(const SimEvent('go'));
      for (final r in racers) {
        r.lapStartTick = tick;
        // Rocket start: throttle pressed within the last 0.5s, but not held
        // for more than 1.5s before the lights.
        if (r.throttleHeldTicks > 0 && r.throttleHeldTicks <= 45) {
          _applyBoost(r, 30, 1.3, 1);
          events.add(SimEvent('rocketStart', slot: r.slot));
        } else if (r.throttleHeldTicks > 45) {
          r.stallTicks = 24;
          events.add(SimEvent('stall', slot: r.slot));
        }
      }
    }

    for (final r in racers) {
      final input = r.isBot || r.playerId.isEmpty ? botInput(this, r) : (inputs[r.slot] ?? KartInput.idle);
      _stepRacer(r, input);
    }
    _resolveKartCollisions();
    _stepProjectiles();
    _stepHazards();
    _updatePositions();
    _checkFinish();
    tick++;
  }

  /// Client-side prediction: advances only [slot]'s kart by one tick while
  /// every other racer stays where the last snapshot put them.
  void predictStep(int slot, KartInput input) {
    final r = racerBySlot(slot);
    events.clear();
    if (r == null || phase == RacePhase.finished) {
      tick++;
      return;
    }
    if (phase == RacePhase.countdown && tick >= raceStartTick) {
      phase = RacePhase.racing;
      r.lapStartTick = tick;
    }
    _stepRacer(r, input);
    _resolveKartCollisions();
    tick++;
  }

  // ---------------------------------------------------------------------------
  // Kart physics

  void _stepRacer(Racer r, KartInput input) {
    final dt = tickDt;
    final t = track;

    if (phase == RacePhase.countdown) {
      if (input.throttle > 0.5) {
        r.throttleHeldTicks++;
      } else {
        r.throttleHeldTicks = 0;
      }
      r.speed = 0;
      return;
    }

    // Timers.
    if (r.boostTicks > 0) r.boostTicks--;
    if (r.boostTicks == 0) {
      r.boostMult = 1;
      r.boostTier = 0;
    }
    if (r.shieldTicks > 0) r.shieldTicks--;
    if (r.zapTicks > 0) r.zapTicks--;
    if (r.spinTicks > 0) r.spinTicks--;
    if (r.stallTicks > 0) r.stallTicks--;
    if (r.hopTicks > 0) r.hopTicks--;
    if (r.bumpCooldown > 0) r.bumpCooldown--;
    if (r.rouletteTicks > 0) {
      r.rouletteTicks--;
      if (r.rouletteTicks == 0) {
        _awardItem(r);
      }
    }
    if (r.respawnTicks > 0) {
      r.respawnTicks--;
      r.speed = 0;
      if (r.respawnTicks == 0) {
        r.balloons = 3;
        events.add(SimEvent('respawn', slot: r.slot));
      }
      return;
    }
    if (r.finished) {
      // Coast to a stop and roll along the racing line.
      final s = t.samples[r.nearest];
      r.heading = turnToward(r.heading, s.tangent.angle, 2.5 * dt);
      r.speed = math.max(0, r.speed - 40 * dt);
      r.pos = r.pos + V2.fromAngle(r.heading, r.speed * dt);
      r.nearest = t.nearestIndex(r.pos, r.nearest);
      return;
    }

    var effInput = input;
    if (r.cometTicks > 0) {
      r.cometTicks--;
      effInput = _racingLineInput(r, aggressive: true);
      r.boostTicks = 2;
      r.boostMult = 1.75;
      r.boostTier = 4;
      if (r.cometTicks == 0) {
        r.boostTicks = 20;
        r.boostMult = 1.3;
        r.boostTier = 2;
        events.add(SimEvent('cometEnd', slot: r.slot));
      }
    }

    // Item usage (edge triggered).
    if (input.item && !r.prevItemButton) {
      _useItem(r, input.lookBack);
    }
    r.prevItemButton = input.item;

    final controllable = r.spinTicks == 0 && r.stallTicks == 0;
    final surfaceMult = switch (r.surface) {
      Surface.offroad => r.boostTicks > 0 || r.cometTicks > 0 ? 1.0 : 0.55,
      _ => 1.0,
    };
    final zapMult = r.zapTicks > 0 ? 0.7 : 1.0;
    final maxSpeed = r.maxSpeed * surfaceMult * zapMult * (r.boostTicks > 0 ? r.boostMult : 1.0);
    final accel = 34 + 46 * r.stats.accel;

    // Speed.
    if (!controllable) {
      r.speed = r.spinTicks > 0 ? math.max(math.min(r.speed, 22), r.speed - 80 * dt) : math.max(0, r.speed - 80 * dt);
      if (r.spinTicks > 0) {
        r.heading += 10 * dt;
      }
    } else {
      final throttle = effInput.throttle.clamp(-1.0, 1.0);
      if (throttle > 0) {
        if (r.speed < maxSpeed) {
          r.speed = math.min(maxSpeed, r.speed + accel * throttle * dt * (r.boostTicks > 0 ? 3 : 1));
        } else {
          r.speed = math.max(maxSpeed, r.speed - 60 * dt);
        }
      } else if (throttle < 0) {
        if (r.speed > 0) {
          r.speed = math.max(0, r.speed - 95 * dt);
        } else {
          r.speed = math.max(-24, r.speed - 30 * dt);
        }
      } else {
        if (r.speed > 0) {
          r.speed = math.max(0, r.speed - 28 * dt);
        } else {
          r.speed = math.min(0, r.speed + 28 * dt);
        }
      }
      if (r.surface == Surface.offroad && r.speed > maxSpeed) {
        r.speed = math.max(maxSpeed, r.speed - 120 * dt);
      }
    }

    // Steering + drift.
    if (controllable && r.airTicks == 0) {
      final steer = effInput.steer.clamp(-1.0, 1.0);
      final baseRate = 2.0 + 1.6 * r.stats.handling;
      final speedRatio = (r.speed.abs() / r.maxSpeed).clamp(0.0, 1.4);
      final grip = math.min(1.0, r.speed.abs() / 18) * (1 - 0.3 * math.min(1.0, speedRatio));
      final dir = r.speed >= 0 ? 1.0 : -1.0;

      final wantsDrift = effInput.drift && r.speed > r.maxSpeed * 0.45;
      if (effInput.drift && !r.prevDrift && r.speed > 10) {
        r.hopTicks = 8;
      }
      if (r.driftDir == 0 && wantsDrift && steer.abs() > 0.25 && effInput.drift && (!r.prevDrift || r.hopTicks > 0)) {
        r.driftDir = steer > 0 ? 1 : -1;
        r.driftCharge = 0;
        events.add(SimEvent('driftStart', slot: r.slot));
      }
      if (r.driftDir != 0) {
        if (!wantsDrift) {
          _releaseDrift(r);
        } else {
          // Tight turn in the drift direction, modulated by steering input.
          final into = steer * r.driftDir; // 1 = steering into the drift
          final turn = r.driftDir * baseRate * grip * (0.55 + 0.95 * math.max(0.0, into) + 0.25 * into.clamp(-1.0, 0.0)) * dt;
          r.heading += turn;
          r.driftCharge += into > 0.3 ? 2 : 1;
          if (r.driftCharge == 24 || r.driftCharge == 60 || r.driftCharge == 110) {
            events.add(SimEvent('driftTier', slot: r.slot, value: _tierFor(r.driftCharge)));
          }
        }
      } else {
        r.heading += steer * baseRate * grip * dir * dt;
      }
      r.prevDrift = effInput.drift;
    } else if (r.airTicks > 0) {
      if (effInput.drift && !r.prevDrift) {
        r.trickReady = true;
        events.add(SimEvent('trick', slot: r.slot));
      }
      r.prevDrift = effInput.drift;
    }

    // Motion. While drifting the kart slides slightly outward.
    final slide = r.driftDir != 0 ? -r.driftDir * driftSlide : 0.0;
    final moveDir = r.heading + slide;
    r.pos = r.pos + V2.fromAngle(moveDir, r.speed * dt);

    // Airborne.
    if (r.airTicks > 0) {
      r.airTicks--;
      if (r.airTicks == 0) {
        if (r.trickReady) {
          _applyBoost(r, 24, 1.28, 2);
          events.add(SimEvent('trickLand', slot: r.slot));
        }
        r.trickReady = false;
        events.add(SimEvent('land', slot: r.slot));
      }
    }

    // Track interaction.
    r.nearest = t.nearestIndex(r.pos, r.nearest);
    r.surface = t.surfaceAt(r.pos, r.nearest);
    if (r.surface == Surface.wall) {
      _hitWall(r);
    }
    if (r.airTicks == 0) {
      for (final pad in t.boostPads) {
        if (pad.contains(r.pos)) {
          if (r.boostTier < 2 || r.boostTicks < 10) {
            _applyBoost(r, 30, 1.35, 2);
            events.add(SimEvent('pad', slot: r.slot));
          }
          break;
        }
      }
      for (final jump in t.jumps) {
        if (jump.contains(r.pos) && r.speed > 30) {
          r.airTicks = 18;
          r.trickReady = false;
          r.driftDir = 0;
          r.driftCharge = 0;
          events.add(SimEvent('jump', slot: r.slot));
          break;
        }
      }
      for (var i = 0; i < t.itemBoxes.length; i++) {
        if (itemBoxRespawn[i] > 0) continue;
        if (t.itemBoxes[i].pos.distanceTo(r.pos) < 6.5 && r.item == null && r.rouletteTicks == 0) {
          itemBoxRespawn[i] = 3 * ticksPerSecond;
          r.rouletteTicks = 40;
          events.add(SimEvent('pickup', slot: r.slot, value: i));
        }
      }
      final vulnerable = r.spinTicks == 0 && r.cometTicks == 0 && tick - r.lastHitTick > hitImmunityTicks;
      for (final h in t.hazards) {
        if (h.kind == HazardKind.oilSlick && h.pos.distanceTo(r.pos) < 6 && vulnerable) {
          _spinOut(r, -1, 'slick');
        } else if (h.kind == HazardKind.pillar) {
          final d = r.pos - h.pos;
          if (d.length < 9) {
            r.pos = h.pos + d.normalized() * 9.2;
            // Glance off: rotate away from the pillar centre.
            final side = V2.fromAngle(r.heading).cross(d);
            r.heading += (side >= 0 ? 1 : -1) * 0.25;
            r.speed *= 0.6;
            r.driftDir = 0;
            events.add(SimEvent('bump', slot: r.slot));
          }
        }
      }
      for (final m in movingHazards) {
        if (m.pos.distanceTo(r.pos) < 8 && vulnerable) {
          _spinOut(r, -1, 'roller');
        }
      }
      for (final d in dropped) {
        if (d.pos.distanceTo(r.pos) < 6 && vulnerable && (d.ownerSlot != r.slot || d.life > 20)) {
          if (r.hasShield) {
            r.shieldTicks = 0;
            events.add(SimEvent('shieldPop', slot: r.slot));
          } else if (r.spinTicks == 0) {
            _spinOut(r, d.ownerSlot, 'slick');
          }
          d.life = -1;
        }
      }
    }
    dropped.removeWhere((d) => d.life < 0);

    // Slipstream.
    var slip = false;
    for (final o in racers) {
      if (o.slot == r.slot) continue;
      final d = o.pos - r.pos;
      final fwd = V2.fromAngle(r.heading);
      final lon = d.dot(fwd);
      final lat = d.cross(fwd).abs();
      if (lon > 4 && lon < 38 && lat < 6 && r.speed > r.maxSpeed * 0.7) {
        slip = true;
        break;
      }
    }
    if (slip) {
      r.slipTicks++;
      if (r.slipTicks == 36) {
        _applyBoost(r, 24, 1.18, 1);
        events.add(SimEvent('slipstream', slot: r.slot));
        r.slipTicks = 0;
      }
    } else {
      r.slipTicks = 0;
    }

    _updateLapProgress(r);
  }

  int _tierFor(int charge) => driftTierFor(charge);

  void _releaseDrift(Racer r) {
    final tier = _tierFor(r.driftCharge);
    if (tier > 0) {
      final ticks = [0, 16, 30, 46][tier];
      final mult = [1.0, 1.24, 1.3, 1.38][tier];
      _applyBoost(r, ticks, mult, tier);
      events.add(SimEvent('miniTurbo', slot: r.slot, value: tier));
    }
    r.driftDir = 0;
    r.driftCharge = 0;
  }

  void _applyBoost(Racer r, int ticks, double mult, int tier) {
    if (r.boostTicks > 0 && r.boostMult > mult) {
      r.boostTicks = math.max(r.boostTicks, ticks);
      return;
    }
    r.boostTicks = math.max(r.boostTicks, ticks);
    r.boostMult = mult;
    r.boostTier = tier;
  }

  void _hitWall(Racer r) {
    final s = track.samples[r.nearest];
    final lat = track.lateral(r.pos, r.nearest);
    final limit = s.width / 2 + (track.isArena ? 0 : track.def.grassMargin) - 0.5;
    final side = lat > 0 ? 1.0 : -1.0;
    r.pos = r.pos + s.normal * ((limit - 1.5) * side - lat);
    // How directly the kart is driving into the wall: 0 = sliding along it,
    // 1 = head on. Glancing contact only straightens the heading so that
    // steering away from the wall on the next tick is not fought.
    final outward = s.normal * side;
    final into = V2.fromAngle(r.heading, 1).dot(outward).clamp(0.0, 1.0);
    if (into > 0) {
      final dir = V2.fromAngle(r.heading, 1);
      final along = dir.dot(s.tangent) >= 0 ? s.tangent : s.tangent * -1;
      r.heading = turnToward(r.heading, along.angle, math.asin(into) + 0.02);
    }
    if (into > 0.3 && r.speed > 20) {
      events.add(SimEvent('wall', slot: r.slot));
    }
    r.speed *= 1 - 0.6 * into;
    r.driftDir = 0;
    r.driftCharge = 0;
  }

  void _spinOut(Racer r, int bySlot, String cause) {
    if (r.hasShield) {
      r.shieldTicks = 0;
      events.add(SimEvent('shieldPop', slot: r.slot));
      return;
    }
    r.spinTicks = 36;
    r.driftDir = 0;
    r.driftCharge = 0;
    r.boostTicks = 0;
    r.boostMult = 1;
    r.speed *= 0.4;
    r.lastHitTick = tick;
    if (r.rouletteTicks > 0) r.rouletteTicks = 0;
    events.add(
      SimEvent(
        'hit',
        slot: r.slot,
        other: bySlot,
        item: cause == 'rocket'
            ? ItemKind.rocket
            : cause == 'orb'
            ? ItemKind.orb
            : cause == 'zap'
            ? ItemKind.zap
            : ItemKind.slick,
      ),
    );
    if (isBattle && r.balloons > 0) {
      r.balloons--;
      final attacker = bySlot >= 0 ? racerBySlot(bySlot) : null;
      if (attacker != null && attacker.slot != r.slot) {
        attacker.score++;
        events.add(SimEvent('score', slot: attacker.slot, other: r.slot, value: attacker.score));
      }
      if (r.balloons == 0) {
        r.respawnTicks = 3 * ticksPerSecond;
        r.item = null;
        r.itemCharges = 0;
        events.add(SimEvent('knockout', slot: r.slot, other: bySlot));
      }
    }
  }

  void _updateLapProgress(Racer r) {
    final t = track;
    if (t.isArena) return;
    final sector = t.checkpointOf(r.nearest);
    final n = Track.checkpointCount;
    // Wrong way detection via heading vs tangent.
    final tangent = t.samples[r.nearest].tangent;
    final facing = V2.fromAngle(r.heading).dot(tangent);
    if (facing < -0.3 && r.speed > 5) {
      r.wrongWayTicks++;
    } else {
      r.wrongWayTicks = 0;
    }
    // Lap completion: crossing from the last sector into sector 0 with the
    // second-to-last-or-later checkpoint reached.
    final crossedLine = sector == 0 && (r.checkpoint == n - 1 || r.checkpoint == n - 2) && r.nearest < Track.sampleCount ~/ 8;
    if (!crossedLine && (sector == (r.checkpoint + 1) % n || sector == (r.checkpoint + 2) % n) && sector != 0) {
      // Advance the checkpoint when we reach the next sector (a designed
      // shortcut may skip at most one sector).
      r.checkpoint = sector;
    }
    if (crossedLine) {
      r.checkpoint = 0;
      r.lap++;
      r.lapTicks.add(tick - r.lapStartTick);
      r.lapStartTick = tick;
      if (r.lap >= laps && !r.finished) {
        r.finished = true;
        r.finishTick = tick;
        if (firstFinishTick < 0) firstFinishTick = tick;
        events.add(SimEvent('finish', slot: r.slot, value: tick));
      } else if (!r.finished) {
        events.add(SimEvent('lap', slot: r.slot, value: r.lap));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Items

  void _awardItem(Racer r) {
    final odds = oddsForPosition(r.position, racers.length, battle: isBattle);
    final idx = rng.weighted(odds);
    r.item = ItemKind.values[idx];
    r.itemCharges = r.item == ItemKind.tripleTurbo ? 3 : 1;
    events.add(SimEvent('item', slot: r.slot, item: r.item));
  }

  void _useItem(Racer r, bool lookBack) {
    final kind = r.item;
    if (kind == null || r.spinTicks > 0 || r.respawnTicks > 0) return;
    events.add(SimEvent('use', slot: r.slot, item: kind));
    switch (kind) {
      case ItemKind.turbo:
        _applyBoost(r, 40, 1.4, 3);
        r.item = null;
      case ItemKind.tripleTurbo:
        _applyBoost(r, 40, 1.4, 3);
        r.itemCharges--;
        if (r.itemCharges <= 0) r.item = null;
      case ItemKind.rocket:
        final target = lookBack ? _racerBehind(r) : _racerAhead(r);
        final dir = lookBack ? r.heading + math.pi : r.heading;
        projectiles.add(
          Projectile(
            id: _nextId++,
            kind: kind,
            ownerSlot: r.slot,
            pos: r.pos + V2.fromAngle(dir, 8),
            heading: dir,
            speed: r.maxSpeed * 1.55,
            targetSlot: target?.slot,
          )..nearest = r.nearest,
        );
        r.item = null;
      case ItemKind.orb:
        final dir = lookBack ? r.heading + math.pi : r.heading;
        projectiles.add(
          Projectile(id: _nextId++, kind: kind, ownerSlot: r.slot, pos: r.pos + V2.fromAngle(dir, 8), heading: dir, speed: r.maxSpeed * 1.4)
            ..nearest = r.nearest,
        );
        r.item = null;
      case ItemKind.slick:
        final dir = lookBack ? r.heading : r.heading + math.pi;
        final dist = lookBack ? 60.0 : 9.0;
        dropped.add(DroppedHazard(id: _nextId++, pos: r.pos + V2.fromAngle(dir, dist), ownerSlot: r.slot));
        r.item = null;
      case ItemKind.shield:
        r.shieldTicks = 8 * ticksPerSecond;
        r.item = null;
      case ItemKind.zap:
        for (final o in racers) {
          if (o.slot == r.slot || o.finished || o.cometTicks > 0) continue;
          if (o.hasShield) {
            o.shieldTicks = 0;
            events.add(SimEvent('shieldPop', slot: o.slot));
            continue;
          }
          _spinOut(o, r.slot, 'zap');
          o.zapTicks = 4 * ticksPerSecond;
          if (o.item != null && rng.nextInt(2) == 0) {
            o.item = null;
          }
        }
        r.item = null;
      case ItemKind.comet:
        r.cometTicks = (3.5 * ticksPerSecond).round();
        r.spinTicks = 0;
        r.driftDir = 0;
        r.item = null;
    }
  }

  Racer? _racerAhead(Racer r) {
    Racer? best;
    for (final o in racers) {
      if (o.slot == r.slot || o.finished) continue;
      if (o.position < r.position && (best == null || o.position > best.position)) best = o;
    }
    return best;
  }

  Racer? _racerBehind(Racer r) {
    Racer? best;
    for (final o in racers) {
      if (o.slot == r.slot || o.finished) continue;
      if (o.position > r.position && (best == null || o.position < best.position)) best = o;
    }
    return best;
  }

  void _stepProjectiles() {
    final dt = tickDt;
    for (final p in projectiles) {
      p.life++;
      if (p.kind == ItemKind.rocket) {
        final target = p.targetSlot == null ? null : racerBySlot(p.targetSlot!);
        if (target != null && !target.finished) {
          final want = (target.pos - p.pos).angle;
          p.heading = turnToward(p.heading, want, 3.2 * dt);
        } else {
          // Follow the racing line until something is in range.
          p.nearest = track.nearestIndex(p.pos, p.nearest);
          final ahead = track.samples[(p.nearest + 10) % Track.sampleCount].pos;
          p.heading = turnToward(p.heading, (ahead - p.pos).angle, 3.0 * dt);
        }
        if (p.life > 9 * ticksPerSecond) p.life = -1;
      } else {
        if (p.life > 10 * ticksPerSecond) p.life = -1;
      }
      if (p.life < 0) continue;
      p.pos = p.pos + V2.fromAngle(p.heading, p.speed * dt);
      p.nearest = track.nearestIndex(p.pos, p.nearest);
      final surface = track.surfaceAt(p.pos, p.nearest);
      if (surface == Surface.wall) {
        if (p.kind == ItemKind.orb && p.bounces < 6) {
          final s = track.samples[p.nearest];
          final lat = track.lateral(p.pos, p.nearest);
          final limit = s.width / 2 + (track.isArena ? 0 : track.def.grassMargin) - 1;
          p.pos = s.pos + s.normal * (limit * (lat > 0 ? 1 : -1));
          // Reflect across the track normal.
          final n = s.normal;
          final v = V2.fromAngle(p.heading);
          final reflected = v - n * (2 * v.dot(n));
          p.heading = reflected.angle;
          p.bounces++;
          events.add(SimEvent('orbBounce', slot: p.ownerSlot));
        } else {
          p.life = -1;
          events.add(SimEvent('projectileGone', slot: p.ownerSlot, item: p.kind));
          continue;
        }
      }
      for (final r in racers) {
        if (r.finished || r.respawnTicks > 0) continue;
        if (r.slot == p.ownerSlot && p.life < 12) continue;
        if (tick - r.lastHitTick < 30) continue;
        if (r.cometTicks > 0) continue;
        if (r.pos.distanceTo(p.pos) < 7) {
          _spinOut(r, p.ownerSlot, p.kind == ItemKind.rocket ? 'rocket' : 'orb');
          p.life = -1;
          break;
        }
      }
    }
    projectiles.removeWhere((p) => p.life < 0);
    for (var i = 0; i < itemBoxRespawn.length; i++) {
      if (itemBoxRespawn[i] > 0) itemBoxRespawn[i]--;
    }
    for (final d in dropped) {
      d.life++;
    }
  }

  void _stepHazards() {
    for (final m in movingHazards) {
      m.phase += tickDt * 1.1;
      final s = track.sampleAt(0); // angle from def
      final normal = V2.fromAngle(m.def.angle).perp();
      m.pos = m.def.pos + normal * (math.sin(m.phase) * m.def.range);
      // s unused except for keeping the calculation explicit.
      assert(s.width > 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Collisions and ordering

  void _resolveKartCollisions() {
    const radius = 4.2;
    for (var i = 0; i < racers.length; i++) {
      final a = racers[i];
      if (a.respawnTicks > 0 || a.airTicks > 0) continue;
      for (var j = i + 1; j < racers.length; j++) {
        final b = racers[j];
        if (b.respawnTicks > 0 || b.airTicks > 0) continue;
        final d = b.pos - a.pos;
        final dist = d.length;
        if (dist < radius * 2 && dist > 0.001) {
          final overlap = radius * 2 - dist;
          final n = d * (1 / dist);
          final ma = a.stats.mass + (a.cometTicks > 0 ? 3 : 0);
          final mb = b.stats.mass + (b.cometTicks > 0 ? 3 : 0);
          final total = ma + mb;
          a.pos = a.pos - n * (overlap * (mb / total));
          b.pos = b.pos + n * (overlap * (ma / total));
          // Heavier kart keeps more speed.
          final avg = (a.speed + b.speed) / 2;
          a.speed = lerpD(a.speed, avg, 0.35 * (mb / total) * 2);
          b.speed = lerpD(b.speed, avg, 0.35 * (ma / total) * 2);
          if (a.cometTicks > 0 && b.cometTicks == 0) _spinOut(b, a.slot, 'orb');
          if (b.cometTicks > 0 && a.cometTicks == 0) _spinOut(a, b.slot, 'orb');
          if (a.bumpCooldown == 0 && b.bumpCooldown == 0) {
            events.add(SimEvent('bump', slot: a.slot, other: b.slot));
            a.bumpCooldown = 10;
            b.bumpCooldown = 10;
          }
        }
      }
    }
  }

  void _updatePositions() {
    final order = [...racers];
    if (isBattle) {
      order.sort((a, b) {
        if (a.score != b.score) return b.score.compareTo(a.score);
        if (a.balloons != b.balloons) return b.balloons.compareTo(a.balloons);
        return a.slot.compareTo(b.slot);
      });
    } else {
      order.sort((a, b) {
        if (a.finished && b.finished) return a.finishTick.compareTo(b.finishTick);
        if (a.finished) return -1;
        if (b.finished) return 1;
        final pa = a.progress(track);
        final pb = b.progress(track);
        if (pa != pb) return pb.compareTo(pa);
        return a.slot.compareTo(b.slot);
      });
    }
    for (var i = 0; i < order.length; i++) {
      order[i].position = i + 1;
    }
  }

  void _checkFinish() {
    if (phase != RacePhase.racing) return;
    if (isBattle) {
      if (battleTicksLeft == 0) _finish();
      return;
    }
    final humans = racers.where((r) => !r.isBot && r.playerId.isNotEmpty);
    final allHumansDone = humans.isEmpty ? racers.every((r) => r.finished) : humans.every((r) => r.finished);
    final timeUp = firstFinishTick >= 0 && tick - firstFinishTick > 30 * ticksPerSecond;
    if (racers.every((r) => r.finished) || (allHumansDone && (timeUp || _botsClose())) || timeUp) {
      _finish();
    }
  }

  bool _botsClose() {
    // End quickly once humans are done and every bot is within its last lap.
    return racers.where((r) => !r.finished).every((r) => r.lap >= laps - 1);
  }

  void _finish() {
    phase = RacePhase.finished;
    final order = [...racers];
    if (isBattle) {
      order.sort((a, b) {
        if (a.score != b.score) return b.score.compareTo(a.score);
        if (a.balloons != b.balloons) return b.balloons.compareTo(a.balloons);
        return a.slot.compareTo(b.slot);
      });
    } else {
      // Unfinished racers are projected by progress; they finish after the
      // last real finisher.
      order.sort((a, b) {
        if (a.finished && b.finished) return a.finishTick.compareTo(b.finishTick);
        if (a.finished) return -1;
        if (b.finished) return 1;
        final pa = a.progress(track);
        final pb = b.progress(track);
        if (pa != pb) return pb.compareTo(pa);
        return a.slot.compareTo(b.slot);
      });
    }
    var place = 1;
    var lastFinish = order.where((r) => r.finished).fold<int>(tick, (m, r) => math.max(m, r.finishTick));
    results = [
      for (final r in order)
        RaceResult(
          slot: r.slot,
          name: r.name,
          characterId: r.characterId,
          kartId: r.kartId,
          isBot: r.isBot,
          platform: r.platform,
          place: place,
          finishTick: r.finished ? r.finishTick : (lastFinish += 30),
          lapTicks: List.of(r.lapTicks),
          points: isBattle ? r.score : pointsForPlace(place++),
          score: r.score,
        ),
    ];
    if (isBattle) {
      // points were assigned as score above; place still needs incrementing.
      results = [
        for (var i = 0; i < results!.length; i++)
          RaceResult(
            slot: results![i].slot,
            name: results![i].name,
            characterId: results![i].characterId,
            kartId: results![i].kartId,
            isBot: results![i].isBot,
            platform: results![i].platform,
            place: i + 1,
            finishTick: results![i].finishTick,
            lapTicks: results![i].lapTicks,
            points: pointsForPlace(i + 1),
            score: results![i].score,
          ),
      ];
    }
    events.add(const SimEvent('raceOver'));
  }

  // ---------------------------------------------------------------------------
  // Racing-line driver shared by bots, the comet item and test autopilots.

  /// Produces an input that follows the centerline. [aggressive] uses a
  /// longer look-ahead and full throttle.
  KartInput _racingLineInput(Racer r, {bool aggressive = false, double lateralBias = 0}) =>
      racingLineInput(r, lateralBias: lateralBias, lookAhead: lookAheadFor(r) + (aggressive ? 4 : 0));

  /// Number of centerline samples covering roughly [distance] world units.
  int samplesFor(double distance) => math.max(3, (distance / (track.length / Track.sampleCount)).round());

  /// Look-ahead distance that scales with speed (about 0.8 s of travel).
  int lookAheadFor(Racer r) => samplesFor(clamp(0.8 * r.speed.abs() + 30, 50, 120));

  /// Signed angle from the kart's travel direction to the racing-line target.
  double lineError(Racer r, {double lateralBias = 0, int lookAhead = 16}) {
    final i = (r.nearest + lookAhead) % Track.sampleCount;
    final s = track.samples[i];
    final target = s.pos + s.normal * lateralBias;
    final want = (target - r.pos).angle;
    final travel = r.heading - r.driftDir * driftSlide;
    return wrapAngle(want - travel);
  }

  /// Input that follows the centerline; used by bots and autopilots.
  KartInput racingLineInput(Racer r, {double lateralBias = 0, int lookAhead = 16, bool drift = false}) {
    final d = lineError(r, lateralBias: lateralBias, lookAhead: lookAhead);
    return KartInput(throttle: 1, steer: (d * 2.2).clamp(-1.0, 1.0), drift: drift);
  }
}
