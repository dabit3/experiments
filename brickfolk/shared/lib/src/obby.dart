import 'dart:collection';

import 'protocol.dart';
import 'rng.dart';

/// Skyline Obby: a deterministic side-view platformer.
///
/// World units are bricks: x grows to the right, y grows upward. The player is
/// an axis-aligned box whose position is the centre of its feet.
class ObbyPlatform {
  const ObbyPlatform(
    this.x,
    this.y,
    this.w,
    this.h, {
    this.kind = PlatformKind.normal,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final PlatformKind kind;

  double get right => x + w;
  double get top => y + h;

  Map<String, Object?> toJson() => {
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'kind': kind.name,
  };
}

enum PlatformKind { normal, checkpoint, kill, finish }

class ObbyCourse {
  ObbyCourse._(this.platforms, this.checkpoints, this.finishX);

  final List<ObbyPlatform> platforms;

  /// Spawn points (feet position) for each checkpoint, index 0 is the start.
  final List<({double x, double y})> checkpoints;
  final double finishX;

  static const stageCount = 12;
  static const courseSeed = 20260909;

  /// Builds the fixed course. The layout is generated from a constant seed so
  /// every server and client agrees on it without shipping level data.
  static ObbyCourse build() {
    final rng = SeededRng(courseSeed);
    final platforms = <ObbyPlatform>[];
    final checkpoints = <({double x, double y})>[];
    var x = 0.0;
    var y = 0.0;
    for (var stage = 0; stage < stageCount; stage++) {
      // Checkpoint pad.
      const padW = 4.0;
      platforms.add(
        ObbyPlatform(x, y - 1, padW, 1, kind: PlatformKind.checkpoint),
      );
      checkpoints.add((x: x + padW / 2, y: y));
      x += padW;
      final pieces = 2 + rng.nextInt(2) + (stage >= 6 ? 1 : 0);
      for (var i = 0; i < pieces; i++) {
        final dy = (rng.nextInt(7) - 3) * 0.5; // -1.5 .. 1.5
        final maxGap = 3.0 - (dy > 0 ? dy * 0.6 : 0) - (stage >= 8 ? 0.2 : 0);
        final gap = 1.5 + rng.nextDouble() * (maxGap - 1.5);
        x += gap;
        y = (y + dy).clamp(-2.0, 8.0);
        final wantsKill = stage >= 2 && rng.nextInt(3) == 0;
        final w = wantsKill ? 10.0 + rng.nextInt(2) : 2.0 + rng.nextInt(3);
        platforms.add(ObbyPlatform(x, y - 1, w, 1));
        if (wantsKill) {
          platforms.add(
            ObbyPlatform(x + 5, y, 1, 0.5, kind: PlatformKind.kill),
          );
        }
        x += w;
      }
      final gap = 1.5 + rng.nextDouble() * 1.2;
      x += gap;
    }
    platforms.add(ObbyPlatform(x, y - 1, 6, 1, kind: PlatformKind.finish));
    final finishX = x + 1.0;
    return ObbyCourse._(platforms, checkpoints, finishX);
  }

  static final ObbyCourse instance = build();

  double get length => platforms.last.right;
}

class ObbyInput {
  const ObbyInput({
    this.left = false,
    this.right = false,
    this.jump = false,
    this.forTick,
  });

  final bool left;
  final bool right;
  final bool jump;

  /// Tick of the frame this input reacts to. The server measures the
  /// player's input lag from it (see [ObbyPlayerState.inputLag]).
  final int? forTick;

  static const none = ObbyInput();

  ObbyInput at(int tick) =>
      ObbyInput(left: left, right: right, jump: jump, forTick: tick);

  /// Same keys held, ignoring [forTick].
  bool sameAs(ObbyInput o) =>
      left == o.left && right == o.right && jump == o.jump;

  int get flags => (left ? 1 : 0) | (right ? 2 : 0) | (jump ? 4 : 0);

  static ObbyInput fromFlags(int f) =>
      ObbyInput(left: f & 1 != 0, right: f & 2 != 0, jump: f & 4 != 0);

  Map<String, Object?> toJson() => {
    'l': left,
    'r': right,
    'j': jump,
    if (forTick != null) 't': forTick,
  };

  static ObbyInput fromJson(Map<String, Object?> json) => ObbyInput(
    left: json['l'] == true,
    right: json['r'] == true,
    jump: json['j'] == true,
    forTick: (json['t'] as num?)?.toInt(),
  );
}

/// Inputs scheduled ahead of time: each entry takes effect at its server tick
/// and stays held until the next one. Remote pilots send a plan instead of a
/// single input so a client that stalls for a moment keeps steering; the last
/// entry is always [ObbyInput.none] so a plan that is not renewed stops the
/// avatar.
///
/// Wire form: `{"t": <frame tick>, "plan": [[<tick>, <flags>], ...]}` with
/// flags bit 0 = left, bit 1 = right, bit 2 = jump.
class ObbyPlan {
  const ObbyPlan(this.forTick, this.entries);

  /// Tick of the frame the plan reacts to (see [ObbyInput.forTick]).
  final int forTick;

  /// `(tick, input)` in ascending tick order.
  final List<(int, ObbyInput)> entries;

  Map<String, Object?> toJson() => {
    't': forTick,
    'plan': [
      for (final (t, i) in entries) [t, i.flags],
    ],
  };

  static ObbyPlan? fromJson(Map<String, Object?> json) {
    final raw = json['plan'];
    final forTick = (json['t'] as num?)?.toInt();
    if (raw is! List || forTick == null) return null;
    final entries = <(int, ObbyInput)>[];
    for (final e in raw) {
      if (e is! List || e.length != 2) return null;
      final t = e[0];
      final f = e[1];
      if (t is! num || f is! num) return null;
      entries.add((t.toInt(), ObbyInput.fromFlags(f.toInt())));
    }
    if (entries.isEmpty) return null;
    for (var i = 1; i < entries.length; i++) {
      if (entries[i].$1 <= entries[i - 1].$1) return null;
    }
    return ObbyPlan(forTick, entries);
  }
}

class ObbyPlayerState {
  ObbyPlayerState({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.grounded = true,
    this.facingRight = true,
    this.checkpoint = 0,
    this.deaths = 0,
    this.finishTick,
    this.respawnUntilTick = 0,
    this.inputLag = -1,
    this.lastInput = ObbyInput.none,
  });

  double x;
  double y;
  double vx;
  double vy;
  bool grounded;
  bool facingRight;
  int checkpoint;
  int deaths;
  int? finishTick;

  /// Player is frozen (death animation) until this tick.
  int respawnUntilTick;

  /// Ticks the world advanced between the frame the player's latest tagged
  /// input reacted to and the tick it was applied; 0 for an untagged input,
  /// -1 until any input has been applied.
  int inputLag;
  ObbyInput lastInput;

  bool get finished => finishTick != null;

  ObbyPlayerState clone() => ObbyPlayerState(
    x: x,
    y: y,
    vx: vx,
    vy: vy,
    grounded: grounded,
    facingRight: facingRight,
    checkpoint: checkpoint,
    deaths: deaths,
    finishTick: finishTick,
    respawnUntilTick: respawnUntilTick,
    inputLag: inputLag,
    lastInput: lastInput,
  );

  List<Object?> toPacked() => [
    _r(x),
    _r(y),
    _r(vx),
    _r(vy),
    (grounded ? 1 : 0) | (facingRight ? 2 : 0),
    checkpoint,
    deaths,
    finishTick,
    respawnUntilTick,
    inputLag,
  ];

  static ObbyPlayerState fromPacked(List<Object?> p) {
    final flags = (p[4] as num).toInt();
    return ObbyPlayerState(
      x: (p[0] as num).toDouble(),
      y: (p[1] as num).toDouble(),
      vx: (p[2] as num).toDouble(),
      vy: (p[3] as num).toDouble(),
      grounded: flags & 1 != 0,
      facingRight: flags & 2 != 0,
      checkpoint: (p[5] as num).toInt(),
      deaths: (p[6] as num).toInt(),
      finishTick: (p[7] as num?)?.toInt(),
      respawnUntilTick: (p[8] as num?)?.toInt() ?? 0,
      inputLag: p.length > 9 ? (p[9] as num?)?.toInt() ?? -1 : -1,
    );
  }

  static double _r(double v) => (v * 1000).roundToDouble() / 1000;
}

/// Events emitted by [ObbySim.step] for feedback (sound, particles, badges).
enum ObbyEventKind { checkpoint, death, finish, jump, land }

class ObbyEvent {
  const ObbyEvent(this.kind, this.playerId, {this.value = 0});

  final ObbyEventKind kind;
  final String playerId;
  final int value;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'player': playerId,
    'value': value,
  };
}

/// Pure physics for the obby. Server-authoritative; clients reuse it for
/// local prediction of their own avatar.
abstract final class ObbySim {
  static const gravity = 30.0;
  static const moveSpeed = 6.0;
  static const jumpVelocity = 11.0;
  static const halfWidth = 0.4;
  static const height = 1.6;
  static const killY = -6.0;
  static const respawnTicks = 18;

  static ObbyPlayerState spawn(ObbyCourse course, [int checkpoint = 0]) {
    final cp = course.checkpoints[checkpoint];
    return ObbyPlayerState(x: cp.x, y: cp.y, checkpoint: checkpoint);
  }

  /// Upper bound on the lag recorded from a tagged input.
  static const maxInputLag = 3 * ticksPerSecond;

  /// Records the lag of [input] received at [tick] on [s].
  static void noteInput(ObbyPlayerState s, ObbyInput input, int tick) {
    final forTick = input.forTick;
    s.inputLag = forTick == null ? 0 : (tick - forTick).clamp(0, maxInputLag);
  }

  /// Advances [s] by one tick. Returns the events produced.
  static List<ObbyEvent> step(
    ObbyCourse course,
    String playerId,
    ObbyPlayerState s,
    ObbyInput input,
    int tick,
  ) {
    final events = <ObbyEvent>[];
    s.lastInput = input;
    if (s.finished) {
      s.vx = 0;
      return events;
    }
    if (tick < s.respawnUntilTick) {
      return events;
    }

    // Horizontal.
    var dir = 0.0;
    if (input.left) dir -= 1;
    if (input.right) dir += 1;
    s.vx = dir * moveSpeed;
    if (dir != 0) s.facingRight = dir > 0;
    if (input.jump && s.grounded) {
      s.vy = jumpVelocity;
      s.grounded = false;
      events.add(ObbyEvent(ObbyEventKind.jump, playerId));
    }

    // Integrate X and resolve against walls.
    s.x += s.vx * tickDt;
    for (final p in course.platforms) {
      if (p.kind == PlatformKind.kill) continue;
      if (_overlaps(s, p)) {
        if (s.vx > 0) {
          s.x = p.x - halfWidth - 0.001;
        } else if (s.vx < 0) {
          s.x = p.right + halfWidth + 0.001;
        }
        s.vx = 0;
      }
    }
    s.x = s.x.clamp(-2.0, course.length + 4);

    // Integrate Y and resolve against floors/ceilings.
    s.vy -= gravity * tickDt;
    if (s.vy < -25) s.vy = -25;
    final wasGrounded = s.grounded;
    s.y += s.vy * tickDt;
    s.grounded = false;
    for (final p in course.platforms) {
      if (p.kind == PlatformKind.kill) continue;
      if (_overlaps(s, p)) {
        if (s.vy <= 0 && s.y - s.vy * tickDt >= p.top - 0.05) {
          s.y = p.top;
          s.vy = 0;
          s.grounded = true;
          if (!wasGrounded) {
            events.add(ObbyEvent(ObbyEventKind.land, playerId));
          }
          if (p.kind == PlatformKind.finish) {
            s.finishTick = tick;
            s.vx = 0;
            events.add(ObbyEvent(ObbyEventKind.finish, playerId, value: tick));
            return events;
          }
          if (p.kind == PlatformKind.checkpoint) {
            final index = course.platforms
                .where((q) => q.kind == PlatformKind.checkpoint)
                .toList()
                .indexOf(p);
            if (index > s.checkpoint) {
              s.checkpoint = index;
              events.add(
                ObbyEvent(ObbyEventKind.checkpoint, playerId, value: index),
              );
            }
          }
        } else if (s.vy > 0) {
          s.y = p.y - height - 0.001;
          s.vy = 0;
        }
      }
    }

    // Hazards.
    var died = s.y < killY;
    if (!died) {
      for (final p in course.platforms) {
        if (p.kind == PlatformKind.kill && _overlaps(s, p)) {
          died = true;
          break;
        }
      }
    }
    if (died) {
      final cp = course.checkpoints[s.checkpoint];
      s.x = cp.x;
      s.y = cp.y;
      s.vx = 0;
      s.vy = 0;
      s.grounded = true;
      s.deaths += 1;
      s.respawnUntilTick = tick + respawnTicks;
      events.add(ObbyEvent(ObbyEventKind.death, playerId, value: s.deaths));
    }
    return events;
  }

  static bool _overlaps(ObbyPlayerState s, ObbyPlatform p) {
    return s.x + halfWidth > p.x &&
        s.x - halfWidth < p.right &&
        s.y + height > p.y &&
        s.y < p.top;
  }

  /// Score used for ranking: finished players first (lower time is better),
  /// then by checkpoint, then by progress.
  static int score(ObbyPlayerState s) {
    if (s.finished) return 100000 - s.finishTick!;
    return s.checkpoint * 1000 + (s.x * 10).round().clamp(0, 999);
  }
}

class _PilotMemory {
  const _PilotMemory(this.lastCheckpoint, this.pauseUntil);

  final int lastCheckpoint;
  final int pauseUntil;
}

/// Simple deterministic controller that completes the course by running right
/// and jumping over gaps, hazards and walls. Used by server bots and by the
/// automated cross-platform test.
///
/// A remote pilot's frame is [ObbyPlayerState.inputLag] ticks old by the time
/// its input applies, so it first replays the decisions still in flight on a
/// copy of the state (client-side prediction) and steers the predicted
/// position instead. Decisions are tagged with their frame tick so the
/// server can measure that lag. [plan] goes further and pre-computes the
/// next [planHorizon] ticks of input on the predicted state, so a client that
/// misses frames keeps steering correctly.
class ObbyAutopilot {
  ObbyAutopilot({
    this.hesitationTicks = 0,
    this.lead = 0.35,
    this.remote = false,
  });

  /// Ticks to pause on every checkpoint pad, giving different finish times.
  final int hesitationTicks;
  final double lead;

  /// Pilot drives over the network: stand still until the server has measured
  /// the input lag from the first tagged decision, so the run starts with a
  /// correct prediction horizon.
  final bool remote;

  int _pauseUntil = -1;
  int _lastCheckpoint = -1;

  /// Recent decisions by frame tick, oldest first, for lag replay.
  final _history = <(int, ObbyInput)>[];

  /// Ticks of input a [plan] covers.
  static const planHorizon = 2 * ticksPerSecond;

  /// What the server applies per tick according to the plans sent so far,
  /// with the pilot memory after deciding that tick.
  final _schedule = SplayTreeMap<int, (ObbyInput, _PilotMemory)>();

  /// Plans the next [planHorizon] ticks for a remote pilot that observed
  /// [observed] at frame [tick]. Returns null once the run is finished.
  ///
  /// The plan lands `inputLag` ticks after [tick]; the ticks in between are
  /// replayed from the inputs already scheduled so the new entries start from
  /// the state the server will actually be in.
  ObbyPlan? plan(ObbyCourse course, ObbyPlayerState observed, int tick) {
    if (observed.finished) return null;
    final lag = observed.inputLag;
    if (lag < 0) return ObbyPlan(tick, [(tick, ObbyInput.none)]);
    final p = observed.clone();
    for (var t = tick; t < tick + lag && !p.finished; t++) {
      ObbySim.step(course, '', p, _scheduledAt(t), t);
    }
    final start = tick + lag;
    final before = _schedule.lastKeyBefore(start);
    var mem = before == null
        ? _PilotMemory(_lastCheckpoint, _pauseUntil)
        : _schedule[before]!.$2;
    final entries = <(int, ObbyInput)>[];
    var t = start;
    for (; t < start + planHorizon && !p.finished; t++) {
      final (input, next) = _steer(course, p, t, mem);
      mem = next;
      _schedule[t] = (input, mem);
      if (entries.isEmpty || !entries.last.$2.sameAs(input)) {
        entries.add((t, input));
      }
      ObbySim.step(course, '', p, input, t);
    }
    entries.add((t, ObbyInput.none));
    _schedule[t] = (ObbyInput.none, mem);
    _schedule.removeWhere((k, _) => k < tick - ObbySim.maxInputLag || k > t);
    return ObbyPlan(tick, entries);
  }

  ObbyInput _scheduledAt(int t) {
    final k = _schedule.lastKeyBefore(t + 1);
    return k == null ? ObbyInput.none : _schedule[k]!.$1;
  }

  ObbyInput decide(ObbyCourse course, ObbyPlayerState s, int tick) {
    final d = _decide(course, s, tick);
    if (_history.isNotEmpty && _history.last.$1 >= tick) {
      _history.removeLast();
    }
    _history.add((tick, d));
    while (_history.length > 1 &&
        _history[1].$1 <= tick - ObbySim.maxInputLag) {
      _history.removeAt(0);
    }
    return d;
  }

  ObbyInput _decide(ObbyCourse course, ObbyPlayerState observed, int tick) {
    if (observed.finished) return ObbyInput.none;
    if (remote && observed.inputLag < 0) return ObbyInput.none;
    final s = observed.inputLag > 0
        ? _predict(course, observed, tick)
        : observed;
    final (input, mem) = _steer(
      course,
      s,
      tick,
      _PilotMemory(_lastCheckpoint, _pauseUntil),
      checkpoint: observed.checkpoint,
    );
    _lastCheckpoint = mem.lastCheckpoint;
    _pauseUntil = mem.pauseUntil;
    return input;
  }

  /// Pure steering step: the input for [s] at [tick] and the updated memory.
  (ObbyInput, _PilotMemory) _steer(
    ObbyCourse course,
    ObbyPlayerState s,
    int tick,
    _PilotMemory mem, {
    int? checkpoint,
  }) {
    if (s.finished) return (ObbyInput.none, mem);
    final cp = checkpoint ?? s.checkpoint;
    if (cp != mem.lastCheckpoint) {
      mem = _PilotMemory(cp, tick + hesitationTicks);
    }
    if (tick < mem.pauseUntil) return (ObbyInput.none, mem);
    if (!s.grounded) return (const ObbyInput(right: true), mem);

    final front = s.x + ObbySim.halfWidth;
    ObbyPlatform? standing;
    for (final p in course.platforms) {
      if (p.kind == PlatformKind.kill) continue;
      if (front > p.x &&
          s.x - ObbySim.halfWidth < p.right &&
          (s.y - p.top).abs() < 0.05) {
        if (standing == null || p.right > standing.right) standing = p;
      }
    }
    var jump = false;
    if (standing != null && standing.right - front <= lead) {
      // At the edge: jump unless another platform continues the floor.
      final continues = course.platforms.any(
        (p) =>
            p.kind != PlatformKind.kill &&
            p != standing &&
            p.x <= standing!.right + 0.05 &&
            p.right > standing.right &&
            (p.top - standing.top).abs() < 0.05,
      );
      jump = !continues;
    }
    for (final p in course.platforms) {
      final ahead = p.x - front;
      if (p.kind == PlatformKind.kill) {
        if (ahead >= -0.2 && ahead <= 1.1 && (p.y - s.y).abs() < 1.0) {
          jump = true;
        }
      } else if (p.top > s.y + 0.1 && p.top <= s.y + 1.6) {
        if (ahead >= 0 && ahead <= 1.4) jump = true;
      }
    }
    return (ObbyInput(right: true, jump: jump), mem);
  }

  /// State at the tick a decision made on frame [tick] will apply, given the
  /// decisions already in flight (the server holds each input until the next
  /// one arrives).
  ObbyPlayerState _predict(ObbyCourse course, ObbyPlayerState s, int tick) {
    final lag = s.inputLag;
    final p = s.clone();
    var held = ObbyInput.none;
    var i = 0;
    for (var t = tick; t < tick + lag && !p.finished; t++) {
      while (i < _history.length && _history[i].$1 <= t - lag) {
        held = _history[i].$2;
        i++;
      }
      ObbySim.step(course, '', p, held, t);
    }
    return p;
  }
}
