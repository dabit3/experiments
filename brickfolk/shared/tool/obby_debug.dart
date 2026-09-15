import 'package:brickfolk_shared/brickfolk_shared.dart';

void main(List<String> args) {
  final course = ObbyCourse.instance;
  final from = args.isNotEmpty ? double.parse(args[0]) : 0;
  final to = args.length > 1 ? double.parse(args[1]) : 1e9;
  for (final p in course.platforms) {
    if (p.right >= from && p.x <= to) {
      print(
        '${p.kind.name.padRight(10)} x=${p.x.toStringAsFixed(2)} '
        'right=${p.right.toStringAsFixed(2)} top=${p.top.toStringAsFixed(2)} w=${p.w}',
      );
    }
  }
  final state = ObbySim.spawn(course);
  final pilot = ObbyAutopilot();
  var tick = 0;
  var lastDeaths = 0;
  while (!state.finished && tick < ticksPerSecond * 120) {
    final input = pilot.decide(course, state, tick);
    final before = state.clone();
    final events = ObbySim.step(course, 'p', state, input, tick);
    if (state.deaths != lastDeaths) {
      lastDeaths = state.deaths;
      print(
        'death at tick $tick from x=${before.x.toStringAsFixed(2)} '
        'y=${before.y.toStringAsFixed(2)} vy=${before.vy.toStringAsFixed(2)} '
        'grounded=${before.grounded} events=${events.map((e) => e.kind.name)}',
      );
      if (state.deaths > 3) break;
    }
    tick++;
  }
  print('finished=${state.finished} tick=$tick checkpoint=${state.checkpoint}');
}
