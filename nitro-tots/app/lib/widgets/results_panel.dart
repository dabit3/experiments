import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';

import '../theme/tokens.dart';
import 'nt_widgets.dart';

/// Race results table with the local racer highlighted, staggered row
/// reveal, optional cup standings and a caller-supplied footer.
class ResultsPanel extends StatelessWidget {
  const ResultsPanel({
    super.key,
    required this.title,
    required this.trackName,
    required this.results,
    required this.localSlot,
    required this.footer,
    this.standings,
    this.battle = false,
  });

  final String title;
  final String trackName;
  final List<RaceResult> results;
  final int localSlot;
  final Widget footer;
  final List<Standing>? standings;
  final bool battle;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final wide = MediaQuery.sizeOf(context).width >= 900 && standings != null && standings!.isNotEmpty;
    final me = results.where((r) => r.slot == localSlot).firstOrNull;
    return NtCard(
      padding: const EdgeInsets.all(NtSpace.x6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 980 : 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: NtType.h1(nt.ink)),
                      Text(trackName, style: NtType.body(nt.inkSoft)),
                    ],
                  ),
                ),
                if (me != null) _PlaceBadge(place: me.place, big: true),
              ],
            ),
            const SizedBox(height: NtSpace.x4),
            Flexible(
              child: SingleChildScrollView(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ResultsTable(results: results, localSlot: localSlot, battle: battle),
                          ),
                          const SizedBox(width: NtSpace.x6),
                          Expanded(
                            child: StandingsTable(standings: standings!, localSlot: localSlot),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _ResultsTable(results: results, localSlot: localSlot, battle: battle),
                          if (standings != null && standings!.isNotEmpty) ...[
                            const SizedBox(height: NtSpace.x5),
                            StandingsTable(standings: standings!, localSlot: localSlot),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: NtSpace.x5),
            footer,
          ],
        ),
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.results, required this.localSlot, required this.battle});
  final List<RaceResult> results;
  final int localSlot;
  final bool battle;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(battle ? 'Arena results' : 'Finishing order'),
        const SizedBox(height: NtSpace.x2),
        for (var i = 0; i < results.length; i++)
          _Reveal(
            delay: Duration(milliseconds: 60 * i),
            child: _ResultRow(r: results[i], me: results[i].slot == localSlot, battle: battle, nt: nt),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.r, required this.me, required this.battle, required this.nt});
  final RaceResult r;
  final bool me;
  final bool battle;
  final NtScheme nt;

  @override
  Widget build(BuildContext context) {
    final platformColor = NtColors.platform(r.isBot ? 'bot' : r.platform);
    return Semantics(
      label: '${ordinal(r.place)}: ${r.name}, ${r.points} points${me ? ', you' : ''}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: me ? NtColors.sunny.withValues(alpha: nt.isDark ? 0.22 : 0.35) : nt.bgAlt,
          borderRadius: BorderRadius.circular(NtRadius.md),
          border: Border.all(color: me ? NtColors.nitro : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            _PlaceBadge(place: r.place),
            const SizedBox(width: 10),
            Avatar(characterId: r.characterId, size: 36, bot: r.isBot, ring: platformColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: NtType.h3(nt.ink), overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      PlatformBadge(r.isBot ? 'bot' : r.platform, compact: true),
                      const SizedBox(width: 6),
                      Text(kartById(r.kartId).name, style: NtType.caption(nt.inkSoft)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(battle ? '${r.score} pts' : formatTicks(r.raceTicks), style: NtType.mono(nt.ink)),
                Text('+${r.points}', style: NtType.caption(NtColors.nitro)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StandingsTable extends StatelessWidget {
  const StandingsTable({super.key, required this.standings, required this.localSlot, this.title = 'Cup standings'});
  final List<Standing> standings;
  final int localSlot;
  final String title;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        const SizedBox(height: NtSpace.x2),
        for (var i = 0; i < standings.length; i++)
          _Reveal(
            delay: Duration(milliseconds: 40 * i + 200),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: standings[i].slot == localSlot ? NtColors.sky.withValues(alpha: nt.isDark ? 0.25 : 0.3) : nt.bgAlt,
                borderRadius: BorderRadius.circular(NtRadius.md),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}', style: NtType.h3(nt.ink), textAlign: TextAlign.center),
                  ),
                  Avatar(
                    characterId: standings[i].characterId,
                    size: 30,
                    bot: standings[i].isBot,
                    ring: NtColors.platform(standings[i].isBot ? 'bot' : standings[i].platform),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(standings[i].name, style: NtType.body(nt.ink), overflow: TextOverflow.ellipsis),
                  ),
                  Flexible(
                    child: Text(standings[i].places.map(ordinal).join(' · '), style: NtType.caption(nt.inkSoft), softWrap: false, overflow: TextOverflow.fade),
                  ),
                  const SizedBox(width: 12),
                  Text('${standings[i].points}', style: NtType.mono(nt.ink)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaceBadge extends StatelessWidget {
  const _PlaceBadge({required this.place, this.big = false});
  final int place;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final color = switch (place) {
      1 => NtColors.sunny,
      2 => const Color(0xFFC9D1DA),
      3 => const Color(0xFFD9A066),
      _ => context.nt.outline,
    };
    final size = big ? 64.0 : 36.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: place <= 3 ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)] : null,
      ),
      child: Text(ordinal(place), style: (big ? NtType.h2(NtColors.inkDark) : NtType.caption(NtColors.inkDark)).copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: NtMotion.normal + delay,
      curve: Interval(delay.inMilliseconds / (NtMotion.normal + delay).inMilliseconds, 1, curve: NtMotion.emphasized),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset((1 - t) * 24, 0), child: c),
      ),
      child: child,
    );
  }
}
