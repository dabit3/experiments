import 'dart:convert';

import 'package:lastfort_core/lastfort_core.dart';
import 'package:lastfort_server/lastfort_server.dart';

void main() {
  final room = Room(
      code: 'X',
      mode: SquadMode.squads,
      fast: true,
      seed: 42,
      hostToken: 'a',
      onEmpty: (_) {});
  final tokens = ['web', 'ios', 'android', 'macos'];
  for (final t in tokens) {
    final c = Client(null, t)
      ..name = t
      ..platform = t;
    room.join(c);
    room.autopilot[t] = true;
  }
  room.paused = true;
  final sw = Stopwatch()..start();
  room.startMatch(fill: 16);
  var ticks = 0;
  final goals = <String, Map<String, int>>{};
  while (!room.ended && ticks < 20000) {
    room.stepOnce();
    ticks++;
    for (final e in room.pilotsDebug.entries) {
      final g = goals.putIfAbsent(e.key, () => {});
      g[e.value.goal] = (g[e.value.goal] ?? 0) + 1;
    }
  }
  print(goals);
  print('ticks=$ticks ended=${room.ended} ms=${sw.elapsedMilliseconds}');
  final s = room.sim!;
  for (final p in s.players.values.where((p) => !p.isBot)) {
    print(
        '${p.name} place=${p.stats.placement} harv=${p.stats.harvested} built=${p.stats.built} k=${p.stats.kills} by=${p.eliminatedWith}');
  }
  print(jsonEncode(s.summary).length);
  room.dispose();
}
