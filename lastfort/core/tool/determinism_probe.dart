import 'package:lastfort_core/lastfort_core.dart';

void main() {
  final r = Rng(4242);
  final xs = [for (var i = 0; i < 8; i++) r.nextInt32()];
  print('rng $xs');
  final w = World.generate(const Rules.fast(), 4242);
  var th = 0;
  for (final t in w.terrain) {
    th = (th * 31 + t) & 0xFFFFFF;
  }
  print(
      'terrain $th nodes=${w.nodes.length} chests=${w.chests.length} pois=${w.pois.length} loot=${w.floorLoot.length}');
  final s = Sim(rules: const Rules.fast(), seed: 4242, mode: SquadMode.squads);
  for (var i = 0; i < 6; i++) {
    s.addPlayer(
        id: i + 1,
        name: 'p$i',
        team: i ~/ 4,
        isBot: true,
        loadout: const Loadout(),
        platform: 'bot');
  }
  s.start();
  final bots = [
    for (final p in s.players.values) BotBrain(p, 4242 ^ (p.id * 7919), s)
  ];
  for (var t = 0; t < 4000 && s.phase != MatchPhase.ended; t++) {
    for (final b in bots) {
      s.applyInput(b.player, b.think());
    }
    s.step();
  }
  print('sim tick=${s.tick} phase=${s.phase} summary=${s.summary}');
}
