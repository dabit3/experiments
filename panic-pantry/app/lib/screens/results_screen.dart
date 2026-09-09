import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/ui.dart';

/// Post-match results: stars, score count-up, stats, rematch.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.client});
  final GameClient client;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward();
  int _lastStar = 0;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() {
      final stars = (widget.client.results?['stars'] as num?)?.toInt() ?? 0;
      final shown = _starsShown(stars);
      if (shown > _lastStar) {
        _lastStar = shown;
        HapticFeedback.mediumImpact();
      }
    });
  }

  int _starsShown(int stars) {
    var n = 0;
    for (var i = 0; i < stars; i++) {
      if (_ctl.value >= 0.55 + i * 0.15) n++;
    }
    return n;
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final c = widget.client;
    final r = c.results!;
    final score = (r['score'] as num).toInt();
    final stars = (r['stars'] as num).toInt();
    final th = (r['thresholds'] as List).cast<num>().map((e) => e.toInt()).toList();
    final level = levelById(r['levelId'] as String);
    final byDish = (r['servedByDish'] as Map).cast<String, dynamic>();
    final room = c.room;
    final wide = MediaQuery.sizeOf(context).width > 820;

    final verdict = switch (stars) {
      3 => 'Michelin material!',
      2 => 'Great service!',
      1 => 'Kitchen survived.',
      _ => 'Well… nobody got hurt.',
    };

    final headline = AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctl.value.clamp(0, 1));
        final shownScore = (score * (t / 0.55).clamp(0.0, 1.0)).round();
        return Column(
          children: [
            Text(level.name.toUpperCase(), style: PPType.caption(s.text3)),
            const SizedBox(height: PPSpace.x2),
            Text("TIME'S UP", style: PPType.display(s.text).copyWith(fontSize: wide ? 52 : 40)),
            const SizedBox(height: PPSpace.x4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  _Star(lit: i < stars && _ctl.value >= 0.55 + i * 0.15, size: wide ? 84 : 64, delayed: i),
              ],
            ),
            const SizedBox(height: PPSpace.x3),
            Text('$shownScore', style: PPType.numeric(PPColor.butter, size: wide ? 72 : 56)),
            Text('points', style: PPType.caption(s.text3)),
            const SizedBox(height: PPSpace.x2),
            AnimatedOpacity(
              opacity: _ctl.value > 0.9 ? 1 : 0,
              duration: PPMotion.base,
              child: Text(verdict, style: PPType.h2(s.text2)),
            ),
          ],
        );
      },
    );

    final ladder = PPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Star thresholds'),
          for (var i = 0; i < th.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: PPSpace.x2),
              child: Row(
                children: [
                  Text('★' * (i + 1), style: PPType.h3(i < stars ? PPColor.butter : s.text3)),
                  const SizedBox(width: PPSpace.x3),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (score / th[i]).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: s.outline,
                        color: i < stars ? PPColor.butter : s.text3,
                      ),
                    ),
                  ),
                  const SizedBox(width: PPSpace.x3),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${th[i]}',
                      style: PPType.mono(s.text2).copyWith(fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final stats = PPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Service report'),
          Wrap(
            spacing: PPSpace.x3,
            runSpacing: PPSpace.x3,
            children: [
              _Tile(label: 'Served', value: '${r['served']}', icon: Icons.room_service_rounded, color: PPColor.basil),
              _Tile(label: 'Tips', value: '+${r['tips']}', icon: Icons.paid_rounded, color: PPColor.butter),
              _Tile(
                label: 'Best combo',
                value: 'x${r['bestCombo']}',
                icon: Icons.local_fire_department_rounded,
                color: PPColor.plum,
              ),
              _Tile(label: 'Expired', value: '${r['expired']}', icon: Icons.timer_off_rounded, color: PPColor.paprika),
              _Tile(
                label: 'Burnt',
                value: '${r['burntPots']}',
                icon: Icons.whatshot_rounded,
                color: PPColor.paprikaDark,
              ),
              _Tile(label: 'Wrong', value: '${r['wrongServes']}', icon: Icons.block_rounded, color: s.text3),
            ],
          ),
          if (byDish.isNotEmpty) ...[
            const SizedBox(height: PPSpace.x4),
            Wrap(
              spacing: PPSpace.x2,
              runSpacing: PPSpace.x2,
              children: [
                for (final e in byDish.entries)
                  PPChip(label: '${Dish.parse(e.key).label} × ${e.value}', color: s.text2),
              ],
            ),
          ],
        ],
      ),
    );

    final crew = PPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Crew'),
          if (room != null)
            for (final p in room.players)
              Padding(
                padding: const EdgeInsets.only(bottom: PPSpace.x2),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: PPColor.chefs[(p['slot'] as int) % 4], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: PPSpace.x2),
                    Expanded(child: Text(p['name'] as String, style: PPType.body(s.text))),
                    Text(p['bot'] == true ? 'bot' : (p['platform'] as String), style: PPType.small(s.text3)),
                  ],
                ),
              ),
        ],
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.isHost)
          PPButton(label: 'Rematch', icon: Icons.replay_rounded, expand: true, onPressed: c.rematch)
        else
          Container(
            padding: const EdgeInsets.all(PPSpace.x4),
            decoration: BoxDecoration(color: s.surface2, borderRadius: PPRadius.button),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: PPColor.paprika),
                ),
                const SizedBox(width: PPSpace.x3),
                Expanded(child: Text('Waiting for the host to call a rematch…', style: PPType.small(s.text2))),
              ],
            ),
          ),
        const SizedBox(height: PPSpace.x2),
        PPButton(
          label: 'Leave kitchen',
          icon: Icons.logout_rounded,
          kind: PPButtonKind.ghost,
          expand: true,
          onPressed: c.leaveRoom,
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PPSpace.x6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Enter(child: headline),
                  const SizedBox(height: PPSpace.x8),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Enter(index: 2, child: stats),
                              const SizedBox(height: PPSpace.x4),
                              Enter(index: 3, child: ladder),
                            ],
                          ),
                        ),
                        const SizedBox(width: PPSpace.x4),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Enter(index: 3, child: crew),
                              const SizedBox(height: PPSpace.x4),
                              Enter(index: 4, child: actions),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Enter(index: 2, child: stats),
                    const SizedBox(height: PPSpace.x4),
                    Enter(index: 3, child: ladder),
                    const SizedBox(height: PPSpace.x4),
                    Enter(index: 4, child: crew),
                    const SizedBox(height: PPSpace.x4),
                    Enter(index: 5, child: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.lit, required this.size, required this.delayed});
  final bool lit;
  final double size;
  final int delayed;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedScale(
        scale: lit ? 1 : 0.85,
        duration: PPMotion.slow,
        curve: PPMotion.bounce,
        child: Icon(
          Icons.star_rounded,
          size: size,
          color: lit ? PPColor.butter : s.outline,
          shadows: lit ? [const Shadow(color: Color(0x66E8A000), blurRadius: 18)] : null,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Container(
      width: 132,
      padding: const EdgeInsets.all(PPSpace.x3),
      decoration: BoxDecoration(color: s.surface2, borderRadius: PPRadius.button),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: PPSpace.x2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: PPType.numeric(s.text, size: 20)),
              Text(label.toUpperCase(), style: PPType.caption(s.text3).copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
