import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:test/test.dart';

void main() {
  final course = ObbyCourse.instance;

  test('course has 12 checkpoints and a finish pad', () {
    expect(course.checkpoints.length, ObbyCourse.stageCount);
    expect(course.platforms.last.kind, PlatformKind.finish);
  });

  test('course generation is deterministic', () {
    final a = ObbyCourse.build();
    final b = ObbyCourse.build();
    expect(
      a.platforms.map((p) => p.toJson()).toList(),
      b.platforms.map((p) => p.toJson()).toList(),
    );
  });

  for (final hesitation in [0, 5, 20]) {
    test('autopilot with hesitation $hesitation finishes the course', () {
      final state = ObbySim.spawn(course);
      final pilot = ObbyAutopilot(hesitationTicks: hesitation);
      var tick = 0;
      while (!state.finished && tick < ticksPerSecond * 120) {
        final input = pilot.decide(course, state, tick);
        ObbySim.step(course, 'p', state, input, tick);
        tick++;
      }
      expect(
        state.finished,
        isTrue,
        reason:
            'stuck at checkpoint ${state.checkpoint} x=${state.x} '
            'deaths=${state.deaths}',
      );
      expect(state.deaths, 0);
    });
  }

  // Models a remote pilot whose decisions reach the server [lag] ticks after
  // the frame they were made on, as tagged inputs (`forTick`).
  ObbyPlayerState runLagged(int lag, {required bool tagged}) {
    final state = ObbySim.spawn(course);
    final pilot = ObbyAutopilot(hesitationTicks: 3, remote: true);
    final inFlight = <(int, ObbyInput)>[];
    var applied = ObbyInput.none;
    var tick = 0;
    while (!state.finished && tick < ticksPerSecond * 240) {
      final decided = pilot.decide(course, state.clone(), tick);
      inFlight.add((tick + lag, tagged ? decided.at(tick) : decided));
      while (inFlight.isNotEmpty && inFlight.first.$1 <= tick) {
        applied = inFlight.removeAt(0).$2;
        ObbySim.noteInput(state, applied, tick);
      }
      ObbySim.step(course, 'p', state, applied, tick);
      tick++;
    }
    return state;
  }

  for (final lag in [6, 12, 20, 30]) {
    test('lag-compensated autopilot finishes with $lag ticks of input lag', () {
      final tagged = runLagged(lag, tagged: true);
      expect(
        tagged.finished,
        isTrue,
        reason: 'stuck at checkpoint ${tagged.checkpoint} x=${tagged.x}',
      );
      expect(tagged.deaths, 0);
      final blind = runLagged(lag, tagged: false);
      expect(blind.deaths, greaterThan(0));
    });
  }

  // Models a remote pilot that sends plans but only gets to look at a frame
  // every [stall] ticks (a client starved for CPU), with [lag] ticks of
  // transport delay. Mirrors the server's scheduling semantics.
  ObbyPlayerState runPlanned(int lag, int stall) {
    final state = ObbySim.spawn(course);
    final pilot = ObbyAutopilot(hesitationTicks: 3, remote: true);
    final inFlight = <(int, ObbyPlan)>[];
    final scheduled = <(int, ObbyInput)>[];
    var applied = ObbyInput.none;
    var tick = 0;
    while (!state.finished && tick < ticksPerSecond * 240) {
      if (tick % stall == 0) {
        final plan = pilot.plan(course, state.clone(), tick);
        if (plan != null) inFlight.add((tick + lag, plan));
      }
      while (inFlight.isNotEmpty && inFlight.first.$1 <= tick) {
        final plan = inFlight.removeAt(0).$2;
        final decoded = ObbyPlan.fromJson(plan.toJson())!;
        ObbySim.noteInput(state, ObbyInput(forTick: decoded.forTick), tick);
        final first = decoded.entries.first.$1;
        scheduled
          ..removeWhere((e) => e.$1 >= first)
          ..addAll(decoded.entries);
      }
      while (scheduled.isNotEmpty && scheduled.first.$1 <= tick) {
        applied = scheduled.removeAt(0).$2;
      }
      ObbySim.step(course, 'p', state, applied, tick);
      tick++;
    }
    return state;
  }

  for (final (lag, stall) in [(0, 1), (8, 1), (8, 15), (12, 45), (20, 58)]) {
    test('planned autopilot finishes with lag $lag seeing 1 in $stall '
        'frames', () {
      final s = runPlanned(lag, stall);
      expect(
        s.finished,
        isTrue,
        reason: 'stuck at checkpoint ${s.checkpoint} x=${s.x} d=${s.deaths}',
      );
      expect(s.deaths, 0);
    });
  }

  test('plans round-trip through json and end with a release', () {
    final pilot = ObbyAutopilot(remote: true);
    final s = ObbySim.spawn(course);
    expect(pilot.plan(course, s, 10)!.toJson(), {
      't': 10,
      'plan': [
        [10, 0],
      ],
    });
    ObbySim.noteInput(s, const ObbyInput(forTick: 10), 16);
    final plan = pilot.plan(course, s, 20)!;
    expect(plan.forTick, 20);
    expect(plan.entries.first.$1, 26);
    expect(plan.entries.first.$2.right, isTrue);
    expect(plan.entries.last.$1, 26 + ObbyAutopilot.planHorizon);
    expect(plan.entries.last.$2.sameAs(ObbyInput.none), isTrue);
    final back = ObbyPlan.fromJson(plan.toJson())!;
    expect(back.toJson(), plan.toJson());
    expect(ObbyPlan.fromJson({'l': false, 'r': true, 'j': false}), isNull);
    expect(
      ObbyPlan.fromJson({
        't': 1,
        'plan': [
          [5, 2],
          [4, 0],
        ],
      }),
      isNull,
    );
  });

  test('input lag is unknown, then measured from tagged inputs', () {
    final state = ObbySim.spawn(course);
    expect(state.inputLag, -1);
    ObbySim.noteInput(state, const ObbyInput(right: true), 40);
    expect(state.inputLag, 0);
    ObbySim.noteInput(state, const ObbyInput(right: true, forTick: 25), 40);
    expect(state.inputLag, 15);
    expect(ObbyPlayerState.fromPacked(state.toPacked()).inputLag, 15);
  });

  test('falling respawns at the last checkpoint', () {
    final state = ObbySim.spawn(course);
    var tick = 0;
    // Walk left off the start pad.
    while (state.deaths == 0 && tick < 300) {
      ObbySim.step(course, 'p', state, const ObbyInput(left: true), tick++);
    }
    expect(state.deaths, 1);
    expect(state.x, course.checkpoints[0].x);
  });

  test('packed state round-trips', () {
    final s = ObbyPlayerState(x: 1.5, y: 2, vx: 3, vy: -4, checkpoint: 2);
    final r = ObbyPlayerState.fromPacked(s.toPacked());
    expect(r.x, 1.5);
    expect(r.checkpoint, 2);
    expect(r.grounded, isTrue);
  });
}
