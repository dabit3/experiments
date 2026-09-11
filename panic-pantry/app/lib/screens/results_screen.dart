import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/arcade.dart';
import '../widgets/platform_mark.dart';
import '../widgets/ui.dart';

/// Post-match results: stars, score count-up, stats, rematch.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.client, required this.results});
  final GameClient client;
  final Map<String, dynamic> results;

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
    final r = widget.results;
    final score = (r['score'] as num).toInt();
    final stars = (r['stars'] as num).toInt();
    final th = (r['thresholds'] as List).cast<num>().map((e) => e.toInt()).toList();
    final level = levelById(r['levelId'] as String);
    final byDish = (r['servedByDish'] as Map).cast<String, dynamic>();
    final room = c.room;
    final wide = MediaQuery.sizeOf(context).width > 820;

    final verdict = switch (stars) {
      3 => 'Pantry legends!',
      2 => 'That’s a hot streak!',
      1 => 'A delicious start.',
      _ => 'Well… nobody got hurt.',
    };
    final served = (r['served'] as num).toInt();
    final tips = (r['tips'] as num).toInt();
    final expired = (r['expired'] as num).toInt();
    final orders = served * Scoring.basePoints;
    final penalty = expired * Scoring.expiredPenalty;

    // Report card: ink header with the verdict, stars hanging over its edge.
    final header = Container(
      padding: EdgeInsets.fromLTRB(PPSpace.x6, PPSpace.x5, PPSpace.x6, wide ? 56 : 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B6A64), PPColor.hudInk],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          Text(level.name.toUpperCase(), style: PPType.caption(Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: PPSpace.x2),
          Transform.rotate(
            angle: -0.03,
            child: OutlinedText(
              'RUSH COMPLETE!',
              style: PPType.hud(size: wide ? 54 : 32).copyWith(letterSpacing: -1.5),
              fill: PPColor.butter,
              outline: PPColor.ink,
              stroke: wide ? 5 : 4,
            ),
          ),
        ],
      ),
    );

    final starBand = AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(0, i == 1 ? -10 : 0),
              child: _Star(lit: i < stars && _ctl.value >= 0.55 + i * 0.15, size: wide ? 96 : 72, delayed: i),
            ),
        ],
      ),
    );

    Widget tallyRow(String label, String value, {Color? color, bool total = false, IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: color ?? s.text2), const SizedBox(width: PPSpace.x2)],
          Text(label, style: total ? PPType.h3(s.text) : PPType.body(s.text2)),
          const SizedBox(width: PPSpace.x2),
          Expanded(
            child: CustomPaint(painter: _DotsPainter(s.outline), child: const SizedBox(height: 2)),
          ),
          const SizedBox(width: PPSpace.x2),
          Text(value, style: PPType.numeric(color ?? s.text, size: total ? 30 : 20)),
        ],
      ),
    );

    final tally = AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctl.value.clamp(0, 1));
        final k = (t / 0.55).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tallyRow('Orders served', '$served', icon: Icons.room_service_rounded, color: PPColor.basil),
            tallyRow('Order points', '${(orders * k).round()}', icon: Icons.restaurant_menu_rounded),
            tallyRow('Tips', '+${(tips * k).round()}', icon: Icons.paid_rounded, color: PPColor.coinDark),
            if (penalty > 0)
              tallyRow(
                'Expired orders',
                '-${(penalty * k).round()}',
                icon: Icons.timer_off_rounded,
                color: PPColor.paprika,
              ),
            Divider(color: s.outline, height: PPSpace.x5),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PPColor.ink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: PPColor.butter, width: 2),
              ),
              child: Column(
                children: [
                  Text('TEAM SCORE', style: PPType.caption(PPColor.cream).copyWith(letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('${(score * k).round()}', style: PPType.numeric(PPColor.butter, size: 64)),
                ],
              ),
            ),
            const SizedBox(height: PPSpace.x2),
            AnimatedOpacity(
              opacity: _ctl.value > 0.9 ? 1 : 0,
              duration: PPMotion.base,
              child: Text(verdict, style: PPType.h2(s.text2), textAlign: TextAlign.center),
            ),
          ],
        );
      },
    );

    final ladder = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Star thresholds'),
        for (var i = 0; i < th.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: PPSpace.x2),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: StarRow(lit: i < stars ? i + 1 : 0, count: i + 1, size: 18, dimColor: s.text3),
                ),
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
    );

    final extras = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Service report'),
        Wrap(
          spacing: PPSpace.x2,
          runSpacing: PPSpace.x2,
          children: [
            _Tile(
              label: 'Best combo',
              value: 'x${r['bestCombo']}',
              icon: Icons.local_fire_department_rounded,
              color: PPColor.plum,
            ),
            _Tile(label: 'Burnt', value: '${r['burntPots']}', icon: Icons.whatshot_rounded, color: PPColor.paprikaDark),
            _Tile(label: 'Wrong', value: '${r['wrongServes']}', icon: Icons.block_rounded, color: s.text3),
          ],
        ),
        if (byDish.isNotEmpty) ...[
          const SizedBox(height: PPSpace.x3),
          Wrap(
            spacing: PPSpace.x2,
            runSpacing: PPSpace.x2,
            children: [
              for (final e in byDish.entries) PPChip(label: '${Dish.parse(e.key).label} × ${e.value}', color: s.text2),
            ],
          ),
        ],
      ],
    );

    final crew = Column(
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
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: PPColor.chefs[(p['slot'] as int) % 4],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: PPSpace.x2),
                  Expanded(child: Text(p['name'] as String, style: PPType.body(s.text))),
                  if (p['id'] == c.playerId)
                    PlatformMark(
                      id: 'results-device',
                      child: Text(p['platform'] as String, style: PPType.small(s.text3)),
                    )
                  else
                    Text(p['bot'] == true ? 'bot' : (p['platform'] as String), style: PPType.small(s.text3)),
                ],
              ),
            ),
      ],
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

    final body = Padding(
      padding: EdgeInsets.fromLTRB(PPSpace.x6, wide ? 56 : 44, PPSpace.x6, PPSpace.x6),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Enter(index: 2, child: tally),
                      const SizedBox(height: PPSpace.x6),
                      Enter(index: 3, child: ladder),
                    ],
                  ),
                ),
                const SizedBox(width: PPSpace.x8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Enter(index: 3, child: crew),
                      const SizedBox(height: PPSpace.x4),
                      Enter(index: 4, child: extras),
                      const SizedBox(height: PPSpace.x6),
                      Enter(index: 5, child: actions),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Enter(index: 2, child: tally),
                const SizedBox(height: PPSpace.x6),
                Enter(index: 3, child: ladder),
                const SizedBox(height: PPSpace.x4),
                Enter(index: 4, child: crew),
                const SizedBox(height: PPSpace.x4),
                Enter(index: 5, child: extras),
                const SizedBox(height: PPSpace.x6),
                Enter(index: 6, child: actions),
              ],
            ),
    );

    final card = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: PPColor.hudInk, width: 4),
            boxShadow: PPElevation.high(s.brightness),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, body]),
        ),
        // Stars straddle the header / body seam.
        Positioned(left: 0, right: 0, top: wide ? 108 : 86, child: starBand),
      ],
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ArcadeBackdrop(celebrate: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PPSpace.x6),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Enter(child: card),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted leader between a tally label and its value.
class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x, size.height / 2), 1.2, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.star_rounded, size: size * 1.16, color: lit ? PPColor.coinDark : s.outline),
            Icon(
              Icons.star_rounded,
              size: size,
              color: lit ? PPColor.butter : s.surface2,
              shadows: lit ? [const Shadow(color: Color(0x66E8A000), blurRadius: 18)] : null,
            ),
          ],
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
