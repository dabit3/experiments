import 'package:brickfolk_shared/brickfolk_shared.dart';

/// A participant in a match: a connected human or a server bot.
class Participant {
  Participant({required this.summary, required this.plot})
    : bricksAtStart = plot.bricksPlaced;

  final PlayerSummary summary;

  /// Tycoon plot (persisted for humans, fresh for bots).
  final TycoonPlot plot;

  /// Lifetime bricks placed on the plot when this match started.
  final int bricksAtStart;

  String get id => summary.id;
  bool get isBot => summary.isBot;
}

/// One row of a finished match, before pips/badges are attached.
class RawResult {
  const RawResult(
    this.playerId,
    this.score,
    this.detail,
    this.badges, {
    this.stat = 0,
  });

  final String playerId;
  final int score;
  final String detail;
  final List<String> badges;

  /// Experience-specific counter folded into profile stats (e.g. freezes).
  final int stat;
}

/// A held movement input the client stopped refreshing. Clients repeat a held
/// input at least twice a second, so a longer silence means the client stalled
/// or dropped and its avatar must stop rather than run on.
class HeldInput<T> {
  HeldInput(this.value, this.tick);

  final T value;
  final int tick;

  static const holdTicks = ticksPerSecond;

  bool expired(int now) => now - tick > holdTicks;
}

abstract class GameRunner {
  GameRunner(this.participants, this.seed, this.matchTicks);

  final List<Participant> participants;
  final int seed;
  final int matchTicks;
  int tick = 0;

  ExperienceKind get kind;
  bool get isOver;

  void handleInput(String playerId, Map<String, Object?> data);

  /// Advances the simulation one tick and returns the events to broadcast.
  List<Map<String, Object?>> step();

  /// Full state frame for this tick, or null if nothing should be sent.
  Map<String, Object?>? frame();

  /// Ordered results, best first.
  List<RawResult> results();

  /// One-line progress per player for the test-mode snapshot.
  Map<String, String> progress() => const {};

  int get ticksLeft => (matchTicks - tick).clamp(0, matchTicks);
}

// ---------------------------------------------------------------------------
// Skyline Obby
// ---------------------------------------------------------------------------

class ObbyGame extends GameRunner {
  ObbyGame(super.participants, super.seed, super.matchTicks) {
    for (var i = 0; i < participants.length; i++) {
      final p = participants[i];
      states[p.id] = ObbySim.spawn(course);
      if (p.isBot) {
        // Bots hesitate a deterministic amount so results vary but replay
        // identically for the same seed.
        final rng = SeededRng(seed + i * 7919);
        bots[p.id] = ObbyAutopilot(hesitationTicks: 4 + rng.nextInt(30));
      }
    }
  }

  final course = ObbyCourse.instance;
  final states = <String, ObbyPlayerState>{};
  final inputs = <String, HeldInput<ObbyInput>>{};

  /// Scheduled inputs per player (see [ObbyPlan]), ascending by tick.
  final plans = <String, List<(int, ObbyInput)>>{};
  final bots = <String, ObbyAutopilot>{};

  @override
  ExperienceKind get kind => ExperienceKind.obby;

  @override
  bool get isOver =>
      tick >= matchTicks || states.values.every((s) => s.finished);

  @override
  void handleInput(String playerId, Map<String, Object?> data) {
    final s = states[playerId];
    if (s == null) return;
    final plan = ObbyPlan.fromJson(data);
    if (plan != null) {
      ObbySim.noteInput(s, ObbyInput(forTick: plan.forTick), tick);
      // A new plan replaces the old one from its first tick on; entries the
      // old plan scheduled before that still apply.
      final first = plan.entries.first.$1;
      plans[playerId] = [
        ...?plans[playerId]?.where((e) => e.$1 < first),
        ...plan.entries,
      ];
      _applyDue(playerId);
      return;
    }
    final input = ObbyInput.fromJson(data);
    ObbySim.noteInput(s, input, tick);
    plans.remove(playerId);
    inputs[playerId] = HeldInput(input, tick);
  }

  /// Moves every scheduled entry whose tick has come into the held input.
  void _applyDue(String playerId) {
    final pending = plans[playerId];
    if (pending == null) return;
    while (pending.isNotEmpty && pending.first.$1 <= tick) {
      inputs[playerId] = HeldInput(pending.removeAt(0).$2, tick);
    }
  }

  @override
  List<Map<String, Object?>> step() {
    final events = <Map<String, Object?>>[];
    final ids = states.keys.toList()..sort();
    for (final id in ids) {
      final s = states[id]!;
      _applyDue(id);
      final held = inputs[id];
      // A plan ends with an explicit release, so its held entries do not
      // time out while later entries are still scheduled.
      final scheduled = plans[id]?.isNotEmpty ?? false;
      final stale = held == null || (!scheduled && held.expired(tick));
      final input = bots.containsKey(id)
          ? bots[id]!.decide(course, s, tick)
          : (stale ? ObbyInput.none : held.value);
      for (final e in ObbySim.step(course, id, s, input, tick)) {
        if (e.kind == ObbyEventKind.jump || e.kind == ObbyEventKind.land) {
          continue;
        }
        events.add(e.toJson());
      }
    }
    tick++;
    return events;
  }

  @override
  Map<String, Object?> frame() => {
    'tick': tick,
    'ticksLeft': ticksLeft,
    'players': {for (final e in states.entries) e.key: e.value.toPacked()},
  };

  @override
  Map<String, String> progress() => {
    for (final e in states.entries)
      e.key:
          '${e.value.finished ? 'done' : 'cp${e.value.checkpoint}'} '
          'x${e.value.x.toStringAsFixed(1)} d${e.value.deaths} '
          'lag${e.value.inputLag}',
  };

  @override
  List<RawResult> results() {
    final entries = states.entries.toList()
      ..sort((a, b) {
        final c = ObbySim.score(b.value).compareTo(ObbySim.score(a.value));
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    return [
      for (final e in entries)
        RawResult(
          e.key,
          ObbySim.score(e.value),
          e.value.finished
              ? 'Finished ${(e.value.finishTick! / ticksPerSecond).toStringAsFixed(1)}s'
              : 'Stage ${e.value.checkpoint + 1}',
          [
            if (e.value.checkpoint >= 1) 'first_steps',
            if (e.value.finished) 'summit',
            if (e.value.finished && e.value.finishTick! <= 75 * ticksPerSecond)
              'speedrunner',
          ],
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Brick Tycoon
// ---------------------------------------------------------------------------

class TycoonGame extends GameRunner {
  TycoonGame(super.participants, super.seed, super.matchTicks) {
    for (var i = 0; i < participants.length; i++) {
      final p = participants[i];
      plots[p.id] = p.plot;
      startEarned[p.id] = p.plot.earned;
      if (p.isBot) bots[p.id] = TycoonAutopilot(seed + i * 104729);
    }
  }

  final plots = <String, TycoonPlot>{};
  final startEarned = <String, int>{};
  final bots = <String, TycoonAutopilot>{};
  bool _dirty = true;

  @override
  ExperienceKind get kind => ExperienceKind.tycoon;

  @override
  bool get isOver => tick >= matchTicks;

  int earnedThisMatch(String id) =>
      (plots[id]?.earned ?? 0) - (startEarned[id] ?? 0);

  @override
  void handleInput(String playerId, Map<String, Object?> data) {
    final plot = plots[playerId];
    final action = TycoonAction.fromJson(data);
    if (plot == null || action == null) return;
    if (action.apply(plot) == null) _dirty = true;
  }

  @override
  List<Map<String, Object?>> step() {
    final events = <Map<String, Object?>>[];
    if (tick % ticksPerSecond == 0) {
      final secondsLeft = ticksLeft ~/ ticksPerSecond;
      final ids = plots.keys.toList()..sort();
      for (final id in ids) {
        final bot = bots[id];
        if (bot != null) {
          final action = bot.decide(plots[id]!, secondsLeft);
          if (action != null && action.apply(plots[id]!) == null) {
            events.add({'kind': 'place', 'player': id, 'value': action.cell});
          }
        }
        plots[id]!.collect();
      }
      _dirty = true;
    }
    tick++;
    return events;
  }

  @override
  Map<String, Object?>? frame() {
    if (!_dirty) return null;
    _dirty = false;
    return {
      'tick': tick,
      'ticksLeft': ticksLeft,
      'plots': {for (final e in plots.entries) e.key: e.value.toJson()},
      'earned': {for (final id in plots.keys) id: earnedThisMatch(id)},
    };
  }

  @override
  List<RawResult> results() {
    final ids = plots.keys.toList()
      ..sort((a, b) {
        final c = earnedThisMatch(b).compareTo(earnedThisMatch(a));
        return c != 0 ? c : a.compareTo(b);
      });
    return [
      for (final id in ids)
        RawResult(
          id,
          earnedThisMatch(id),
          '${plots[id]!.brickCount} bricks, ${plots[id]!.incomePerSecond()}/s',
          [
            if (plots[id]!.brickCount >= 1) 'founder',
            if (plots[id]!.incomePerSecond() >= 100) 'magnate',
          ],
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Freeze Tag Arena
// ---------------------------------------------------------------------------

class TagGame extends GameRunner {
  TagGame(super.participants, super.seed, super.matchTicks)
    : rng = SeededRng(seed) {
    for (var i = 0; i < participants.length; i++) {
      final p = participants[i];
      states[p.id] = TagPlayerState(x: 0, y: 0);
      if (p.isBot) bots[p.id] = TagAutopilot(seed + i * 15485863);
    }
    roundTicks = matchTicks ~/ TagSim.roundsPerMatch;
    _beginRound();
  }

  final arena = TagArena.instance;
  final SeededRng rng;
  final states = <String, TagPlayerState>{};
  final inputs = <String, HeldInput<TagInput>>{};
  final bots = <String, TagAutopilot>{};
  final everFrozen = <String>{};
  final totalFreezes = <String, int>{};
  int round = 0;
  late final int roundTicks;
  int roundTick = 0;
  int intermission = 0;
  bool over = false;

  static const intermissionTicks = 3 * ticksPerSecond;

  @override
  ExperienceKind get kind => ExperienceKind.tag;

  @override
  bool get isOver => over;

  void _beginRound() {
    TagSim.startRound(arena, states, round, rng);
    roundTick = 0;
    intermission = 0;
  }

  @override
  void handleInput(String playerId, Map<String, Object?> data) {
    if (!states.containsKey(playerId)) return;
    inputs[playerId] = HeldInput(TagInput.fromJson(data), tick);
  }

  @override
  List<Map<String, Object?>> step() {
    final events = <Map<String, Object?>>[];
    if (intermission > 0) {
      intermission--;
      if (intermission == 0) {
        round++;
        if (round >= TagSim.roundsPerMatch) {
          over = true;
        } else {
          _beginRound();
          events.add({'kind': 'roundStart', 'value': round});
        }
      }
      tick++;
      return events;
    }
    final frame = <String, TagInput>{};
    for (final id in states.keys) {
      final held = inputs[id];
      frame[id] = bots.containsKey(id)
          ? bots[id]!.decide(arena, id, states)
          : (held == null || held.expired(tick) ? TagInput.none : held.value);
    }
    for (final e in TagSim.step(arena, states, frame)) {
      if (e.kind == TagEventKind.freeze) {
        everFrozen.add(e.playerId!);
        totalFreezes[e.byId!] = (totalFreezes[e.byId!] ?? 0) + 1;
      }
      events.add(e.toJson());
    }
    roundTick++;
    tick++;
    if (roundTick >= roundTicks || TagSim.allRunnersFrozen(states)) {
      final swept = TagSim.endRound(states);
      events.add({'kind': 'roundEnd', 'value': round, 'swept': swept});
      intermission = intermissionTicks;
    }
    return events;
  }

  @override
  Map<String, Object?> frame() => {
    'tick': tick,
    'ticksLeft': ticksLeft,
    'round': round,
    'roundTicksLeft': (roundTicks - roundTick).clamp(0, roundTicks),
    'intermission': intermission,
    'players': {for (final e in states.entries) e.key: e.value.toPacked()},
  };

  @override
  List<RawResult> results() {
    final ids = states.keys.toList()
      ..sort((a, b) {
        final c = states[b]!.totalScore.compareTo(states[a]!.totalScore);
        return c != 0 ? c : a.compareTo(b);
      });
    return [
      for (final id in ids)
        RawResult(
          id,
          states[id]!.totalScore,
          '${states[id]!.timesFrozen} frozen',
          [
            if (!everFrozen.contains(id)) 'untouchable',
            if ((totalFreezes[id] ?? 0) >= 3) 'it_factor',
          ],
          stat: totalFreezes[id] ?? 0,
        ),
    ];
  }
}

GameRunner createGame(
  ExperienceKind kind,
  List<Participant> participants,
  int seed, {
  double lengthScale = 1.0,
}) {
  final ticks = (placeFor(kind).matchSeconds * ticksPerSecond * lengthScale)
      .round();
  switch (kind) {
    case ExperienceKind.obby:
      return ObbyGame(participants, seed, ticks);
    case ExperienceKind.tycoon:
      return TycoonGame(participants, seed, ticks);
    case ExperienceKind.tag:
      return TagGame(participants, seed, ticks);
  }
}
