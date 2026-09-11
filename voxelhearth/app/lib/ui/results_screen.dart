import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/game_controller.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'arcade.dart';
import 'chat_panel.dart';
import 'game_screen.dart';
import 'pixel.dart';

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
    final gs = Gui.of(context);
    final gui = Gui.guiSize(context);
    final results = s.results.isEmpty ? s.roster : s.results;
    final sorted = results.toList()..sort((a, b) => b.score.compareTo(a.score));
    final you = sorted.where((p) => p.id == s.youId).firstOrNull;
    final rank = you == null ? 0 : sorted.indexOf(you) + 1;
    final isHost = s.hostId == s.youId;
    final wide = gui.width >= 420;
    final short = gui.height < 260;
    final worldHash = s.resultsWorldHash ?? s.world.editsHash();
    final chatHash = s.resultsChatHash ?? '-';

    final board = _Scoreboard(
      sorted: sorted,
      youId: s.youId,
      worldHash: worldHash,
      chatHash: chatHash,
      client: widget.client,
    );
    final chat = Container(
      color: const Color(0x60000000),
      padding: EdgeInsets.all(2.0 * gs),
      child: ChatPanel(client: widget.client, session: s, transparent: true),
    );
    final footer = Padding(
      padding: EdgeInsets.fromLTRB(0, 4.0 * gs, 0, 8.0 * gs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHost)
            PxButton(
              'Back to Lobby',
              primary: true,
              width: 120,
              onPressed: () => widget.client.send({'t': Msg.backToLobby}),
            )
          else
            const PxButton('Waiting for host...', width: 120),
          SizedBox(width: 4.0 * gs),
          PxButton('Leave World', width: 120, sound: 'ui_back', onPressed: widget.client.leaveRoom),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: VoxelCanvas(game: widget.game, assets: widget.assets, frame: frame),
          ),
          PxScreen(
            background: const Stack(fit: StackFit.expand, children: [DimBackground(), HearthBackdrop(celebrate: true)]),
            footer: footer,
            child: Column(
              children: [
                SizedBox(height: (short ? 4.0 : 10.0) * gs),
                ArcadeHeading(
                  rank == 1 ? 'A HEARTH TO REMEMBER' : 'ADVENTURE COMPLETE',
                  eyebrow: short ? null : 'THE WORLD IS BETTER BECAUSE YOU BUILT IT',
                  compact: short,
                ),
                SizedBox(height: 2.0 * gs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Hearth.gold, size: short ? 22 : 36),
                    const SizedBox(width: 8),
                    Text(
                      rank == 0 ? 'Thanks for playing' : 'RANK #$rank  ·  ${you?.score ?? 0} POINTS',
                      style: arcadeType(short ? 16 : 23, color: Hearth.gold),
                    ),
                  ],
                ),
                SizedBox(height: (short ? 4.0 : 8.0) * gs),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0 * gs),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 480.0 * gs),
                        child: short
                            ? SingleChildScrollView(child: board)
                            : wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 3, child: SingleChildScrollView(child: board)),
                                  SizedBox(width: 6.0 * gs),
                                  Expanded(flex: 1, child: chat),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(child: SingleChildScrollView(child: board)),
                                  SizedBox(height: 4.0 * gs),
                                  SizedBox(height: 60.0 * gs, child: chat),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.sorted,
    required this.youId,
    required this.worldHash,
    required this.chatHash,
    required this.client,
  });
  final List<PlayerInfo> sorted;
  final String youId;
  final String worldHash, chatHash;
  final GameClient client;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _build);

  Widget _build(BuildContext context, BoxConstraints box) {
    final gs = Gui.of(context);
    final narrow = box.maxWidth / gs < 260;
    final cw = narrow ? const [12.0, 26.0, 26.0, 30.0, 22.0, 32.0] : const [12.0, 38.0, 38.0, 44.0, 30.0, 34.0];
    final labels = narrow
        ? const ['Plc', 'Brk', 'Crf', 'Kil', 'Score']
        : const ['Placed', 'Broken', 'Crafted', 'Kills', 'Score'];
    Widget cell(String t, double w, {Color color = Px.white, TextAlign align = TextAlign.right}) => SizedBox(
      width: w * gs,
      child: PxText(t, color: color, align: align, maxLines: 1),
    );
    Widget row(List<Widget> cells, {Color? bg}) => Container(
      margin: EdgeInsets.only(bottom: 2.0 * gs),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xe0102e3b),
        borderRadius: BorderRadius.circular(3.0 * gs),
        border: Border.all(color: const Color(0x404e7986)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 3.0 * gs, vertical: 4.0 * gs),
      child: Row(children: cells),
    );
    final header = row([
      cell('#', cw[0], color: Px.gray, align: TextAlign.left),
      const Expanded(child: PxText('Player', color: Px.gray)),
      for (var i = 0; i < labels.length; i++) cell(labels[i], cw[i + 1], color: Px.gray),
    ], bg: const Color(0x90000000));
    String short(String h) => h.length > 12 ? h.substring(0, 12) : h;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0x90000000),
          padding: EdgeInsets.symmetric(horizontal: 3.0 * gs, vertical: 2.0 * gs),
          child: const PxText('THE BUILDERS CLUB', color: Px.yellow, align: TextAlign.center),
        ),
        header,
        for (var i = 0; i < sorted.length; i++)
          row([
            cell(
              '${i + 1}',
              cw[0],
              color: switch (i) {
                0 => Px.gold,
                1 => const Color(0xffc8ccd6),
                2 => const Color(0xffcd8a5a),
                _ => Px.gray,
              },
              align: TextAlign.left,
            ),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: PxText(sorted[i].name, color: sorted[i].id == youId ? Px.yellow : Px.white, maxLines: 1),
                  ),
                  if (!narrow)
                    PxText(
                      '  ${sorted[i].bot ? 'Bot' : platformLabel(sorted[i].platform)}',
                      color: platformColor(sorted[i].bot ? 'bot' : sorted[i].platform),
                    ),
                ],
              ),
            ),
            cell('${sorted[i].placed}', cw[1]),
            cell('${sorted[i].broken}', cw[2]),
            cell('${sorted[i].crafted}', cw[3]),
            cell('${sorted[i].kills}', cw[4]),
            cell('${sorted[i].score}', cw[5], color: Px.gold),
          ], bg: sorted[i].id == youId ? const Color(0xe0245153) : null),
        if (sorted.isEmpty) row([const Expanded(child: PxText('No players scored', color: Px.gray))]),
        SizedBox(height: 4.0 * gs),
        row([
          const Expanded(child: PxText('Score = placed + broken + crafted x3 + kills x5', color: Px.gray, maxLines: 1)),
        ], bg: const Color(0x40000000)),
        SizedBox(height: 4.0 * gs),
        _hashRow(context, 'World edits', worldHash, short(worldHash)),
        _hashRow(context, 'Chat history', chatHash, short(chatHash)),
        row([
          const Expanded(
            child: PxText(
              'Clients showing the same fingerprints saw the same world and chat.',
              color: Px.gray,
              maxLines: 2,
            ),
          ),
        ], bg: const Color(0x40000000)),
      ],
    );
  }

  Widget _hashRow(BuildContext context, String label, String full, String short) {
    final gs = Gui.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Clipboard.setData(ClipboardData(text: full));
        client.toast('Fingerprint copied');
      },
      child: Container(
        color: const Color(0x40000000),
        padding: EdgeInsets.symmetric(horizontal: 3.0 * gs, vertical: 2.0 * gs),
        child: Row(
          children: [
            Expanded(child: PxText(label, color: Px.gray)),
            PxText(short, color: Px.aqua),
          ],
        ),
      ),
    );
  }
}
