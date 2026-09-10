import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import 'hub_screen.dart';

/// Post-match results: victory/placement banner, personal stats, XP gained,
/// and the full scoreboard shared by every client.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.summary,
    required this.myId,
    required this.xpGained,
    required this.onContinue,
  });

  final Map<String, Object?> summary;
  final int myId;
  final int xpGained;
  final VoidCallback onContinue;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = LfLayout.of(context);
    final c = context.lf;
    final profile = AppScope.of(context).profile;
    final rows = (widget.summary['players'] as List)
        .cast<Map<String, Object?>>();
    final me = rows.where((r) => r['id'] == widget.myId).firstOrNull;
    final winnerTeam = widget.summary['winnerTeam'] as int?;
    final teams = (widget.summary['teams'] as num? ?? 0).toInt();
    final myTeam = me?['team'] as int?;
    final won = myTeam != null && myTeam == winnerTeam;
    final placement = (me?['placement'] as num? ?? 0).toInt();
    final sorted = rows.toList()
      ..sort((a, b) {
        final pa = (a['placement'] as num).toInt();
        final pb = (b['placement'] as num).toInt();
        if (pa != pb) return pa.compareTo(pb);
        return (b['kills'] as num).compareTo(a['kills'] as num);
      });
    final reduced = profile.reducedMotion;
    final pad = layout.isPhone ? LfTokens.s4 : LfTokens.s6;
    final accent = won ? LfTokens.warning : LfTokens.teal;

    return Stack(
      fit: StackFit.expand,
      children: [
        StormBackdrop(intensity: won ? 1.4 : 0.8),
        SafeArea(
          child: LfPage(
            maxWidth: 980,
            child: ListView(
              padding: EdgeInsets.fromLTRB(pad, LfTokens.s6, pad, LfTokens.s6),
              children: [
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    final t = reduced
                        ? 1.0
                        : CurvedAnimation(
                            parent: _ctrl,
                            curve: LfTokens.spring,
                          ).value;
                    return Transform.scale(
                      scale: 0.9 + 0.1 * t,
                      child: Opacity(opacity: t.clamp(0, 1), child: child),
                    );
                  },
                  child: Semantics(
                    header: true,
                    label: won
                        ? 'Victory. Placed number 1.'
                        : 'Placed number $placement of $teams.',
                    child: Column(
                      children: [
                        _Ribbon(
                          eyebrow: won ? 'LAST FORT STANDING' : 'MATCH OVER',
                          title: won ? 'VICTORY' : 'PLACED #$placement',
                          accent: accent,
                          phone: layout.isPhone,
                        ),
                        const SizedBox(height: LfTokens.s3),
                        Text(
                          won
                              ? 'Your squad outlasted $teams teams.'
                              : 'of $teams teams · winner: ${_teamLabel(rows, winnerTeam)}',
                          style: context.text.titleMedium?.copyWith(
                            color: c.muted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: LfTokens.s5),
                if (me != null)
                  LfPanel(
                    strong: true,
                    accent: accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const LfEyebrow('YOUR MATCH'),
                            const Spacer(),
                            PlatformBadge('${me['platform']}'),
                          ],
                        ),
                        const SizedBox(height: LfTokens.s3),
                        GridView.count(
                          crossAxisCount: layout.isPhone ? 3 : 6,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: LfTokens.s2,
                          crossAxisSpacing: LfTokens.s2,
                          childAspectRatio: layout.isPhone ? 1.35 : 1.5,
                          children: [
                            StatTile(
                              label: 'ELIMS',
                              value: '${me['kills']}',
                              color: LfTokens.ember,
                            ),
                            StatTile(label: 'DAMAGE', value: '${me['damage']}'),
                            StatTile(
                              label: 'HARVESTED',
                              value: '${me['harvested']}',
                              color: LfTokens.wood,
                            ),
                            StatTile(
                              label: 'BUILT',
                              value: '${me['built']}',
                              color: LfTokens.stone,
                            ),
                            StatTile(
                              label: 'CHESTS',
                              value: '${me['chests']}',
                              color: LfTokens.warning,
                            ),
                            StatTile(
                              label: 'SURVIVED',
                              value: _fmtTime((me['survived'] as num).toInt()),
                              color: LfTokens.teal,
                            ),
                          ],
                        ),
                        const SizedBox(height: LfTokens.s4),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '+${widget.xpGained} XP',
                                        style: context.text.titleLarge
                                            ?.copyWith(
                                              color: c.isDark
                                                  ? LfTokens.teal
                                                  : LfTokens.tealDeep,
                                            ),
                                      ),
                                      const SizedBox(width: LfTokens.s2),
                                      Text(
                                        'TIER ${profile.level}',
                                        style: context.text.labelSmall
                                            ?.copyWith(
                                              color: c.muted,
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: LfTokens.s1),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: reduced ? profile.tierProgress : 0,
                                      end: profile.tierProgress,
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1100,
                                    ),
                                    curve: LfTokens.ease,
                                    builder: (context, v, _) => LfBar(
                                      value: v,
                                      color: LfTokens.teal,
                                      height: 10,
                                      segments: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: LfTokens.s4),
                LfPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LfEyebrow('SCOREBOARD'),
                      const SizedBox(height: LfTokens.s2),
                      _Header(compact: layout.isPhone),
                      for (final r in sorted)
                        _Row(
                          r: r,
                          me: r['id'] == widget.myId,
                          winner: r['team'] == winnerTeam,
                          compact: layout.isPhone,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: LfTokens.s5),
                Center(
                  child: LfButton(
                    label: 'Back to lobby',
                    icon: Icons.arrow_forward_rounded,
                    size: LfButtonSize.lg,
                    onPressed: widget.onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _teamLabel(List<Map<String, Object?>> rows, int? team) {
    if (team == null) return '—';
    final names = rows
        .where((r) => r['team'] == team)
        .map((r) => '${r['name']}')
        .toList();
    if (names.isEmpty) return 'Team ${team + 1}';
    if (names.length == 1) return names.first;
    return '${names.first} +${names.length - 1}';
  }

  static String _fmtTime(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Wide leaning banner behind the headline, the way BR results announce the
/// outcome before any numbers.
class _Ribbon extends StatelessWidget {
  const _Ribbon({
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.phone,
  });
  final String eyebrow;
  final String title;
  final Color accent;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF0B0F17);
    return Column(
      children: [
        Text(
          eyebrow,
          style: context.text.labelLarge?.copyWith(
            color: accent,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: LfTokens.s2),
        Transform(
          transform: Matrix4.skewX(-0.18),
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: phone ? LfTokens.s5 : LfTokens.s7,
              vertical: phone ? LfTokens.s2 : LfTokens.s3,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(accent, Colors.white, 0.15)!,
                  accent,
                  Color.lerp(accent, Colors.black, 0.2)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.5),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Transform(
              transform: Matrix4.skewX(0.18),
              alignment: Alignment.center,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style:
                    (phone
                            ? context.text.displaySmall
                            : context.text.displayLarge)
                        ?.copyWith(color: fg, height: 1, letterSpacing: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final st = context.text.labelSmall?.copyWith(
      color: context.lf.muted,
      letterSpacing: 1.2,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s3,
        vertical: LfTokens.s1,
      ),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('#', style: st)),
          Expanded(child: Text('PLAYER', style: st)),
          SizedBox(
            width: 48,
            child: Text('ELIMS', style: st, textAlign: TextAlign.right),
          ),
          if (!compact)
            SizedBox(
              width: 64,
              child: Text('DMG', style: st, textAlign: TextAlign.right),
            ),
          if (!compact)
            SizedBox(
              width: 64,
              child: Text('BUILT', style: st, textAlign: TextAlign.right),
            ),
          SizedBox(
            width: 56,
            child: Text('XP', style: st, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.r,
    required this.me,
    required this.winner,
    required this.compact,
  });
  final Map<String, Object?> r;
  final bool me;
  final bool winner;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final bot = r['bot'] == true;
    final fg = bot ? c.muted : c.text;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s3,
        vertical: LfTokens.s2,
      ),
      decoration: BoxDecoration(
        color: me
            ? LfTokens.ember.withValues(alpha: 0.12)
            : (winner
                  ? LfTokens.warning.withValues(alpha: 0.06)
                  : Colors.transparent),
        borderRadius: BorderRadius.circular(LfTokens.rSm),
        border: me
            ? Border.all(color: LfTokens.ember.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${r['placement']}',
              style: context.text.titleMedium?.copyWith(
                color: winner ? LfTokens.warning : fg,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${r['name']}',
                    style: context.text.titleMedium?.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                PlatformBadge('${r['platform']}', compact: true),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    'T${(r['team'] as int) + 1}',
                    style: context.text.labelSmall?.copyWith(color: c.muted),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${r['kills']}',
              style: context.text.titleMedium?.copyWith(color: fg),
              textAlign: TextAlign.right,
            ),
          ),
          if (!compact)
            SizedBox(
              width: 64,
              child: Text(
                '${r['damage']}',
                style: context.text.bodyMedium?.copyWith(color: fg),
                textAlign: TextAlign.right,
              ),
            ),
          if (!compact)
            SizedBox(
              width: 64,
              child: Text(
                '${r['built']}',
                style: context.text.bodyMedium?.copyWith(color: fg),
                textAlign: TextAlign.right,
              ),
            ),
          SizedBox(
            width: 56,
            child: Text(
              '${r['xp']}',
              style: context.text.bodyMedium?.copyWith(color: LfTokens.teal),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
