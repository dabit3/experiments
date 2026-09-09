import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';

import '../state/audio.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';
import '../widgets/results_panel.dart';

/// Final standings after a cup or match: animated podium + full table.
class PodiumScreen extends StatefulWidget {
  const PodiumScreen({
    super.key,
    required this.title,
    required this.standings,
    required this.localSlot,
    required this.feedback,
    required this.onHome,
    this.onAgain,
    this.againLabel = 'Race again',
    this.hash,
    this.races = const [],
  });

  final String title;
  final List<Standing> standings;
  final int localSlot;
  final NtFeedback feedback;
  final VoidCallback onHome;
  final VoidCallback? onAgain;
  final String againLabel;
  final String? hash;
  final List<({String trackId, List<RaceResult> results})> races;

  @override
  State<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends State<PodiumScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void initState() {
    super.initState();
    widget.feedback.music('music_menu');
    final me = widget.standings.indexWhere((s) => s.slot == widget.localSlot);
    if (me >= 0 && me < 3) widget.feedback.haptic(HapticsKind.heavy);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final top = widget.standings.take(3).toList();
    final myRank = widget.standings.indexWhere((s) => s.slot == widget.localSlot) + 1;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final podium = _Podium(top: top, anim: _c, localSlot: widget.localSlot);
    final table = NtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandingsTable(standings: widget.standings, localSlot: widget.localSlot, title: 'Final standings'),
          if (widget.races.length > 1) ...[
            const SizedBox(height: NtSpace.x3),
            const SectionTitle('Races'),
            const SizedBox(height: NtSpace.x2),
            for (final r in widget.races)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(trackDefById(r.trackId).name, style: NtType.small(nt.inkSoft))),
                    Text('${r.results.first.name} won', style: NtType.small(nt.ink)),
                  ],
                ),
              ),
          ],
          if (widget.hash != null) ...[
            const SizedBox(height: NtSpace.x3),
            Semantics(
              label: 'Result hash ${widget.hash}',
              child: Text('Result hash ${widget.hash}', key: const Key('resultHash'), style: NtType.caption(nt.inkSoft)),
            ),
          ],
        ],
      ),
    );

    return Scaffold(
      body: NtBackdrop(
        confetti: myRank > 0 && myRank <= 3,
        child: NtScreen(
          backdrop: false,
          title: widget.title,
          subtitle: myRank > 0 ? 'You finished ${ordinal(myRank)} overall.' : null,
          footer: Row(
            children: [
              NtButton(label: 'Home', icon: Icons.home_rounded, kind: NtButtonKind.secondary, onPressed: widget.onHome),
              const Spacer(),
              if (widget.onAgain != null) NtButton(label: widget.againLabel, icon: Icons.replay_rounded, onPressed: widget.onAgain, autofocus: true),
            ],
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: podium),
                    const SizedBox(width: NtSpace.x8),
                    Expanded(flex: 4, child: table),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    podium,
                    const SizedBox(height: NtSpace.x6),
                    table,
                  ],
                ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.anim, required this.localSlot});
  final List<Standing> top;
  final Animation<double> anim;
  final int localSlot;

  @override
  Widget build(BuildContext context) {
    // Layout order: 2nd, 1st, 3rd.
    final order = [if (top.length > 1) (top[1], 2), if (top.isNotEmpty) (top[0], 1), if (top.length > 2) (top[2], 3)];
    return SizedBox(
      height: 360,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (s, place) in order)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedBuilder(
                  animation: anim,
                  builder: (_, _) {
                    final delay = switch (place) {
                      3 => 0.0,
                      2 => 0.25,
                      _ => 0.5,
                    };
                    final t = Curves.elasticOut.transform(((anim.value - delay) / 0.5).clamp(0.0, 1.0));
                    final fade = ((anim.value - delay) / 0.2).clamp(0.0, 1.0);
                    final h = switch (place) {
                      1 => 190.0,
                      2 => 140.0,
                      _ => 105.0,
                    };
                    final color = switch (place) {
                      1 => NtColors.sunny,
                      2 => const Color(0xFFC9D1DA),
                      _ => const Color(0xFFD9A066),
                    };
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Opacity(
                          opacity: fade,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 40),
                            child: Column(
                              children: [
                                if (place == 1)
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    color: NtColors.sunny,
                                    size: 36,
                                    shadows: const [Shadow(color: Colors.black26, blurRadius: 6)],
                                  ),
                                Avatar(
                                  characterId: s.characterId,
                                  size: place == 1 ? 84 : 68,
                                  bot: s.isBot,
                                  ring: s.slot == localSlot ? NtColors.nitro : Colors.white,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.name,
                                  style: NtType.h3(Colors.white).copyWith(shadows: const [Shadow(color: Colors.black45, blurRadius: 4)]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                PlatformBadge(s.isBot ? 'bot' : s.platform, compact: true),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          height: math.max(0, h * t),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(NtRadius.md)),
                            border: Border.all(color: NtColors.inkDark, width: 3),
                            boxShadow: const [BoxShadow(color: Color(0x44000000), offset: Offset(0, 6), blurRadius: 10)],
                          ),
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: 10),
                          child: FittedBox(
                            child: Column(
                              children: [
                                Text(ordinal(place), style: NtType.h1(NtColors.inkDark)),
                                Text('${s.points} pts', style: NtType.caption(NtColors.inkDark)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
