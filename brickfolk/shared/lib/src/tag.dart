import 'dart:math' as math;

import 'protocol.dart';
import 'rng.dart';

/// Freeze Tag Arena: a top-down round-based tag game.
class TagArena {
  const TagArena._(this.width, this.height, this.walls);

  final double width;
  final double height;
  final List<TagWall> walls;

  static const TagArena instance = TagArena._(24, 16, [
    TagWall(5, 3, 3, 1),
    TagWall(16, 3, 3, 1),
    TagWall(5, 12, 3, 1),
    TagWall(16, 12, 3, 1),
    TagWall(11, 6.5, 2, 3),
    TagWall(3, 7.5, 1, 1),
    TagWall(20, 7.5, 1, 1),
    TagWall(9, 1, 1, 2),
    TagWall(14, 13, 1, 2),
  ]);

  /// Spawn positions around the arena for up to eight players.
  List<({double x, double y})> spawns() => const [
    (x: 2.0, y: 2.0),
    (x: 22.0, y: 14.0),
    (x: 22.0, y: 2.0),
    (x: 2.0, y: 14.0),
    (x: 12.0, y: 1.5),
    (x: 12.0, y: 14.5),
    (x: 1.5, y: 8.0),
    (x: 22.5, y: 8.0),
  ];
}

class TagWall {
  const TagWall(this.x, this.y, this.w, this.h);

  final double x;
  final double y;
  final double w;
  final double h;

  Map<String, Object?> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

class TagInput {
  const TagInput(this.dx, this.dy);

  /// Movement direction components in [-1, 1].
  final double dx;
  final double dy;

  static const none = TagInput(0, 0);

  Map<String, Object?> toJson() => {'dx': _r(dx), 'dy': _r(dy)};

  static TagInput fromJson(Map<String, Object?> json) => TagInput(
    ((json['dx'] as num?)?.toDouble() ?? 0).clamp(-1.0, 1.0),
    ((json['dy'] as num?)?.toDouble() ?? 0).clamp(-1.0, 1.0),
  );

  static double _r(double v) => (v * 100).roundToDouble() / 100;
}

class TagPlayerState {
  TagPlayerState({
    required this.x,
    required this.y,
    this.isTagger = false,
    this.frozen = false,
    this.thawProgress = 0,
    this.freezes = 0,
    this.thaws = 0,
    this.timesFrozen = 0,
    this.roundScore = 0,
    this.totalScore = 0,
    this.facing = 0,
  });

  double x;
  double y;
  bool isTagger;
  bool frozen;

  /// Ticks a teammate has spent touching this frozen player.
  int thawProgress;
  int freezes;
  int thaws;
  int timesFrozen;
  int roundScore;
  int totalScore;

  /// Facing angle in radians.
  double facing;

  List<Object?> toPacked() => [
    _r(x),
    _r(y),
    (isTagger ? 1 : 0) | (frozen ? 2 : 0),
    thawProgress,
    freezes,
    thaws,
    timesFrozen,
    roundScore,
    totalScore,
    _r(facing),
  ];

  static TagPlayerState fromPacked(List<Object?> p) {
    final flags = (p[2] as num).toInt();
    return TagPlayerState(
      x: (p[0] as num).toDouble(),
      y: (p[1] as num).toDouble(),
      isTagger: flags & 1 != 0,
      frozen: flags & 2 != 0,
      thawProgress: (p[3] as num).toInt(),
      freezes: (p[4] as num).toInt(),
      thaws: (p[5] as num).toInt(),
      timesFrozen: (p[6] as num).toInt(),
      roundScore: (p[7] as num).toInt(),
      totalScore: (p[8] as num).toInt(),
      facing: (p[9] as num).toDouble(),
    );
  }

  static double _r(double v) => (v * 1000).roundToDouble() / 1000;
}

enum TagEventKind { freeze, thaw, roundStart, roundEnd }

class TagEvent {
  const TagEvent(this.kind, {this.playerId, this.byId, this.value = 0});

  final TagEventKind kind;
  final String? playerId;
  final String? byId;
  final int value;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'player': playerId,
    'by': byId,
    'value': value,
  };
}

abstract final class TagSim {
  static const runnerSpeed = 5.0;
  static const taggerSpeed = 5.8;
  static const radius = 0.45;
  static const thawTicks = ticksPerSecond;
  static const roundsPerMatch = 3;
  static const roundSeconds = 60;

  static const surviveScore = 10;
  static const thawScore = 3;
  static const freezeScore = 4;
  static const sweepBonus = 10;

  /// Moves every player and resolves tags. Returns the events produced.
  static List<TagEvent> step(
    TagArena arena,
    Map<String, TagPlayerState> players,
    Map<String, TagInput> inputs,
  ) {
    final events = <TagEvent>[];
    final ids = players.keys.toList()..sort();
    for (final id in ids) {
      final s = players[id]!;
      if (s.frozen) continue;
      final input = inputs[id] ?? TagInput.none;
      var dx = input.dx;
      var dy = input.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len > 1e-6) {
        dx /= len;
        dy /= len;
        s.facing = math.atan2(dy, dx);
        final speed = s.isTagger ? taggerSpeed : runnerSpeed;
        s.x += dx * speed * tickDt;
        _resolveWalls(arena, s);
        s.y += dy * speed * tickDt;
        _resolveWalls(arena, s);
      }
      s.x = s.x.clamp(radius, arena.width - radius);
      s.y = s.y.clamp(radius, arena.height - radius);
    }

    // Player/player interactions.
    for (final id in ids) {
      final a = players[id]!;
      for (final other in ids) {
        if (other == id) continue;
        final b = players[other]!;
        if (!_touching(a, b)) continue;
        if (a.isTagger && !b.isTagger && !b.frozen) {
          b.frozen = true;
          b.thawProgress = 0;
          b.timesFrozen += 1;
          a.freezes += 1;
          a.roundScore += freezeScore;
          events.add(TagEvent(TagEventKind.freeze, playerId: other, byId: id));
        } else if (!a.isTagger && !a.frozen && !b.isTagger && b.frozen) {
          b.thawProgress += 1;
          if (b.thawProgress >= thawTicks) {
            b.frozen = false;
            b.thawProgress = 0;
            a.thaws += 1;
            a.roundScore += thawScore;
            events.add(TagEvent(TagEventKind.thaw, playerId: other, byId: id));
          }
        }
      }
    }
    // Thaw progress decays when nobody is helping.
    for (final id in ids) {
      final s = players[id]!;
      if (s.frozen && s.thawProgress > 0) {
        final helped = ids.any(
          (o) =>
              o != id &&
              !players[o]!.isTagger &&
              !players[o]!.frozen &&
              _touching(players[o]!, s),
        );
        if (!helped) s.thawProgress = math.max(0, s.thawProgress - 1);
      }
    }
    return events;
  }

  static bool allRunnersFrozen(Map<String, TagPlayerState> players) {
    final runners = players.values.where((p) => !p.isTagger);
    return runners.isNotEmpty && runners.every((p) => p.frozen);
  }

  /// Awards end-of-round points. Returns true if the tagger swept everyone.
  static bool endRound(Map<String, TagPlayerState> players) {
    final swept = allRunnersFrozen(players);
    for (final s in players.values) {
      if (s.isTagger) {
        if (swept) s.roundScore += sweepBonus;
      } else if (!s.frozen) {
        s.roundScore += surviveScore;
      }
      s.totalScore += s.roundScore;
    }
    return swept;
  }

  /// Resets positions and picks the tagger for [round] (0-based).
  static void startRound(
    TagArena arena,
    Map<String, TagPlayerState> players,
    int round,
    SeededRng rng,
  ) {
    final ids = players.keys.toList()..sort();
    final spawns = arena.spawns();
    final taggerIndex = (round + rng.nextInt(ids.length)) % ids.length;
    for (var i = 0; i < ids.length; i++) {
      final s = players[ids[i]]!;
      final spawn = spawns[i % spawns.length];
      s.x = spawn.x;
      s.y = spawn.y;
      s.frozen = false;
      s.thawProgress = 0;
      s.roundScore = 0;
      s.freezes = 0;
      s.thaws = 0;
      s.isTagger = i == taggerIndex;
    }
  }

  static bool _touching(TagPlayerState a, TagPlayerState b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    final d = 2 * radius;
    return dx * dx + dy * dy <= d * d;
  }

  static void _resolveWalls(TagArena arena, TagPlayerState s) {
    for (final w in arena.walls) {
      final cx = s.x.clamp(w.x, w.x + w.w);
      final cy = s.y.clamp(w.y, w.y + w.h);
      final dx = s.x - cx;
      final dy = s.y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 >= radius * radius) continue;
      if (d2 < 1e-9) {
        // Centre is inside the wall; push out along the smaller axis.
        final left = s.x - w.x;
        final right = w.x + w.w - s.x;
        final up = s.y - w.y;
        final down = w.y + w.h - s.y;
        final m = [left, right, up, down].reduce(math.min);
        if (m == left) {
          s.x = w.x - radius;
        } else if (m == right) {
          s.x = w.x + w.w + radius;
        } else if (m == up) {
          s.y = w.y - radius;
        } else {
          s.y = w.y + w.h + radius;
        }
      } else {
        final d = math.sqrt(d2);
        s.x = cx + dx / d * radius;
        s.y = cy + dy / d * radius;
      }
    }
  }
}

/// Deterministic tag bot: taggers chase the nearest runner, runners flee the
/// tagger and thaw frozen teammates when the tagger is far away.
class TagAutopilot {
  TagAutopilot(int seed) : _rng = SeededRng(seed);

  final SeededRng _rng;
  int _wanderTicks = 0;
  double _wx = 0;
  double _wy = 0;

  TagInput decide(
    TagArena arena,
    String id,
    Map<String, TagPlayerState> players,
  ) {
    final me = players[id]!;
    if (me.frozen) return TagInput.none;
    TagPlayerState? tagger;
    for (final p in players.values) {
      if (p.isTagger) tagger = p;
    }
    if (me.isTagger) {
      TagPlayerState? target;
      var best = double.infinity;
      for (final p in players.values) {
        if (p.isTagger || p.frozen) continue;
        final d = _dist(me, p);
        if (d < best) {
          best = d;
          target = p;
        }
      }
      if (target == null) return TagInput.none;
      return _toward(me, target.x, target.y);
    }
    if (tagger == null) return TagInput.none;
    final danger = _dist(me, tagger);
    if (danger > 7) {
      TagPlayerState? frozenMate;
      var best = double.infinity;
      for (final p in players.values) {
        if (p.isTagger || !p.frozen || p == me) continue;
        final d = _dist(me, p);
        if (d < best) {
          best = d;
          frozenMate = p;
        }
      }
      if (frozenMate != null) return _toward(me, frozenMate.x, frozenMate.y);
      if (_wanderTicks <= 0) {
        _wanderTicks = 20 + _rng.nextInt(40);
        _wx = _rng.nextRange(-1, 1);
        _wy = _rng.nextRange(-1, 1);
      }
      _wanderTicks--;
      return TagInput(_wx, _wy);
    }
    // Flee: away from tagger, biased toward the arena centre when near edges.
    var dx = me.x - tagger.x;
    var dy = me.y - tagger.y;
    final cx = arena.width / 2 - me.x;
    final cy = arena.height / 2 - me.y;
    dx += cx * 0.15;
    dy += cy * 0.15;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) return TagInput.none;
    return TagInput(dx / len, dy / len);
  }

  static double _dist(TagPlayerState a, TagPlayerState b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static TagInput _toward(TagPlayerState me, double x, double y) {
    final dx = x - me.x;
    final dy = y - me.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) return TagInput.none;
    return TagInput(dx / len, dy / len);
  }
}
