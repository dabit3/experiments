import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/game_controller.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'chat_panel.dart';
import 'game_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Post-match scoreboard. The frozen world keeps rendering behind it so the
/// shared structure everyone built is visible.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.client,
    required this.game,
    required this.settings,
    required this.assets,
  });
  final GameClient client;
  final GameController game;
  final Settings settings;
  final RenderAssets assets;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 40))
    ..repeat();
  final FrameNotifier frame = FrameNotifier();
  double _baseYaw = 0;

  @override
  void initState() {
    super.initState();
    _baseYaw = widget.game.camera.yaw;
    _orbit.addListener(() {
      final g = widget.game;
      g.camera.yaw = _baseYaw + _orbit.value * math.pi * 2;
      g.camera.pitch = -0.25;
      g.update(1 / 60);
      frame.bump();
    });
    widget.client.addListener(_onClient);
  }

  void _onClient() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _orbit.dispose();
    widget.client.removeListener(_onClient);
    frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.game.session;
    final t = Theme.of(context);
    final results = s.results.isEmpty ? s.roster : s.results;
    final sorted = results.toList()..sort((a, b) => b.score.compareTo(a.score));
    final you = sorted.where((p) => p.id == s.youId).firstOrNull;
    final rank = you == null ? 0 : sorted.indexOf(you) + 1;
    final isHost = s.hostId == s.youId;
    final ff = formFactorOf(context);
    final wide = MediaQuery.sizeOf(context).width > 820;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: VoxelCanvas(game: widget.game, assets: widget.assets, frame: frame),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.78)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ff == FormFactor.phone ? VhSpace.md : VhSpace.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Reveal(
                        child: Column(
                          children: [
                            const Wordmark(size: 24, subtitle: 'Match complete'),
                            const SizedBox(height: VhSpace.md),
                            Text(
                              rank == 1
                                  ? 'You lit the hearth brightest'
                                  : (rank == 0 ? 'Match complete' : 'You placed #$rank'),
                              textAlign: TextAlign.center,
                              style: t.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Fraunces',
                                fontSize: ff == FormFactor.phone ? 30 : 40,
                              ),
                            ),
                            const SizedBox(height: VhSpace.xs),
                            Text(
                              '${s.roomName.isEmpty ? s.code : s.roomName} · ${s.mode == GameMode.creative ? 'Creative' : 'Survival'} · seed ${s.seed}',
                              style: t.textTheme.bodyMedium?.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VhSpace.xl),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _Scoreboard(sorted: sorted, youId: s.youId),
                            ),
                            const SizedBox(width: VhSpace.lg),
                            Expanded(
                              flex: 2,
                              child: _Side(s: s, client: widget.client),
                            ),
                          ],
                        )
                      else ...[
                        _Scoreboard(sorted: sorted, youId: s.youId),
                        const SizedBox(height: VhSpace.lg),
                        _Side(s: s, client: widget.client),
                      ],
                      const SizedBox(height: VhSpace.xl),
                      Reveal(
                        delay: const Duration(milliseconds: 300),
                        child: Wrap(
                          spacing: VhSpace.sm,
                          runSpacing: VhSpace.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            if (isHost)
                              FilledButton.icon(
                                onPressed: () => widget.client.send({'t': Msg.backToLobby}),
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Back to lobby'),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.hourglass_top_rounded),
                                label: const Text('Waiting for host'),
                              ),
                            OutlinedButton.icon(
                              onPressed: widget.client.leaveRoom,
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Leave world'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.sorted, required this.youId});
  final List<PlayerInfo> sorted;
  final String youId;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final top = sorted.isEmpty ? 1 : math.max(1, sorted.first.score);
    return Reveal(
      delay: const Duration(milliseconds: 120),
      child: GlassPanel(
        tint: Colors.black.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Scoreboard',
                  style: t.textTheme.titleLarge?.copyWith(color: Colors.white, fontFamily: 'Fraunces'),
                ),
                const Spacer(),
                Text(
                  'placed + broken + crafted×3 + kills×5',
                  style: t.textTheme.labelSmall?.copyWith(color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: VhSpace.md),
            for (var i = 0; i < sorted.length; i++)
              Reveal(
                delay: Duration(milliseconds: 160 + i * 70),
                child: _Row(p: sorted[i], rank: i + 1, you: sorted[i].id == youId, fraction: sorted[i].score / top),
              ),
            if (sorted.isEmpty) const StateBlock(icon: Icons.people_outline_rounded, title: 'No players scored'),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.p, required this.rank, required this.you, required this.fraction});
  final PlayerInfo p;
  final int rank;
  final bool you;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final medal = switch (rank) {
      1 => VhColors.gold,
      2 => const Color(0xffc8ccd6),
      3 => const Color(0xffcd8a5a),
      _ => Colors.white24,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: VhSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: VhSpace.md, vertical: VhSpace.sm),
      decoration: BoxDecoration(
        color: you ? VhColors.gold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(VhRadius.md),
        border: Border.all(color: you ? VhColors.gold.withValues(alpha: 0.6) : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medal.withValues(alpha: rank <= 3 ? 0.95 : 0.2),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank <= 3 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
              const SizedBox(width: VhSpace.sm),
              PlatformBadge(p.platform, compact: true),
              const SizedBox(width: VhSpace.sm),
              Expanded(
                child: Text(
                  p.name + (you ? '  (you)' : '') + (p.bot ? '  · bot' : ''),
                  style: t.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: you ? FontWeight.w800 : FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${p.score}',
                style: t.textTheme.headlineSmall?.copyWith(
                  color: VhColors.gold,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                color: medal == Colors.white24 ? VhColors.sky : medal,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: VhSpace.md,
            children: [
              _stat(Icons.add_box_outlined, 'placed', p.placed),
              _stat(Icons.remove_circle_outline_rounded, 'broken', p.broken),
              _stat(Icons.handyman_outlined, 'crafted', p.crafted),
              _stat(Icons.bolt_rounded, 'kills', p.kills),
              _stat(Icons.heart_broken_outlined, 'deaths', p.deaths),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, int v) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.white38),
      const SizedBox(width: 4),
      Text(
        '$v $label',
        style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Outfit'),
      ),
    ],
  );
}

class _Side extends StatelessWidget {
  const _Side({required this.s, required this.client});
  final RoomSession s;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      children: [
        Reveal(
          delay: const Duration(milliseconds: 200),
          child: GlassPanel(
            tint: Colors.black.withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shared world',
                  style: t.textTheme.titleMedium?.copyWith(color: Colors.white, fontFamily: 'Fraunces'),
                ),
                const SizedBox(height: VhSpace.sm),
                _hash(context, 'World edits', s.resultsWorldHash ?? s.world.editsHash()),
                const SizedBox(height: 6),
                _hash(context, 'Chat history', s.resultsChatHash ?? '—'),
                const SizedBox(height: VhSpace.sm),
                Text(
                  'Every client that shows the same fingerprints saw the same world and the same chat.',
                  style: t.textTheme.bodySmall?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VhSpace.lg),
        Reveal(
          delay: const Duration(milliseconds: 260),
          child: GlassPanel(
            tint: Colors.black.withValues(alpha: 0.45),
            padding: const EdgeInsets.all(VhSpace.sm),
            child: SizedBox(
              height: 260,
              child: ChatPanel(client: client, session: s, transparent: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hash(BuildContext context, String label, String value) {
    final short = value.length > 16 ? value.substring(0, 16) : value;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            client.toast('Fingerprint copied');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              short,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
