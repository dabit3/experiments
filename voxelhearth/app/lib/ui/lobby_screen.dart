import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../audio.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'chat_panel.dart';
import 'pixel.dart';
import 'settings_sheet.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.client, required this.session, required this.settings, this.assets});
  final GameClient client;
  final RoomSession session;
  final Settings settings;
  final RenderAssets? assets;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.client.removeListener(_refresh);
    super.dispose();
  }

  RoomSession get s => widget.session;
  bool get isHost => s.hostId == s.youId;
  PlayerInfo? get you => s.roster.where((p) => p.id == s.youId).firstOrNull;
  List<PlayerInfo> get roster {
    final list = s.roster.toList()
      ..sort((a, b) {
        if (a.id == s.hostId) return -1;
        if (b.id == s.hostId) return 1;
        if (a.bot != b.bot) return a.bot ? 1 : -1;
        return a.name.compareTo(b.name);
      });
    return list;
  }

  int get readyCount => s.roster.where((p) => p.ready || p.id == s.hostId).length;

  void _copy() {
    Clipboard.setData(ClipboardData(text: s.code));
    Sfx.play('ui_tap');
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = Gui.of(context);
    final gui = Gui.guiSize(context);
    final wide = gui.width >= 400;
    final modeLabel = s.mode == GameMode.creative ? 'Creative' : 'Survival';
    final humans = s.roster.where((p) => !p.bot).length;
    final header = Column(
      children: [
        SizedBox(height: 6.0 * gs),
        PxText(s.roomName, align: TextAlign.center, maxLines: 1),
        SizedBox(height: 1.0 * gs),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _copy,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PxText('Code: ', color: Px.gray),
                PxText(_copied ? 'Copied!' : s.code, color: _copied ? Px.green : Px.yellow),
                Flexible(
                  child: PxText(
                    '  ·  $modeLabel  ·  seed ${s.seed}  ·  ${s.roster.length} in lobby',
                    color: Px.gray,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 6.0 * gs),
      ],
    );
    final players = PxListBox(
      dirt: widget.assets?.dirt,
      child: roster.isEmpty
          ? const Center(child: PxText('Nobody here yet', color: Px.gray))
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 3.0 * gs),
              itemCount: roster.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0 * gs),
                child: PxListEntry(
                  height: 24,
                  selected: roster[i].id == s.youId,
                  child: _PlayerRow(
                    player: roster[i],
                    isHost: roster[i].id == s.hostId,
                    isYou: roster[i].id == s.youId,
                  ),
                ),
              ),
            ),
    );
    final rules = _rules(context);
    final chat = Padding(
      padding: EdgeInsets.all(2.0 * gs),
      child: ChatPanel(client: widget.client, session: s, dense: false),
    );
    final body = wide
        ? Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 4.0 * gs),
                      child: const PxText('Players', color: Px.gray),
                    ),
                    SizedBox(height: 2.0 * gs),
                    Expanded(child: players),
                  ],
                ),
              ),
              SizedBox(width: 6.0 * gs),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PxText('World Rules', color: Px.gray),
                    SizedBox(height: 2.0 * gs),
                    rules,
                    SizedBox(height: 6.0 * gs),
                    const PxText('Chat', color: Px.gray),
                    SizedBox(height: 2.0 * gs),
                    Expanded(
                      child: PxListBox(dirt: widget.assets?.dirt, child: chat),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PxText('Players', color: Px.gray),
              SizedBox(height: 2.0 * gs),
              SizedBox(height: 78.0 * gs, child: players),
              SizedBox(height: 4.0 * gs),
              const PxText('World Rules', color: Px.gray),
              SizedBox(height: 2.0 * gs),
              rules,
              SizedBox(height: 4.0 * gs),
              const PxText('Chat', color: Px.gray),
              SizedBox(height: 2.0 * gs),
              Expanded(
                child: PxListBox(dirt: widget.assets?.dirt, child: chat),
              ),
            ],
          );
    final me = you;
    final ready = me?.ready ?? false;
    // Phone landscape: keep the host's five buttons on one row so the chat
    // box above keeps its height.
    final compact = gui.width < 480;
    final primaryW = compact ? 100.0 : 120.0, sideW = compact ? 60.0 : 70.0, leaveW = compact ? 50.0 : 60.0;
    final primary = isHost
        ? PxButton(
            'Start Match',
            width: primaryW,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Sfx.play('ui_confirm');
              widget.client.send({'t': Msg.startMatch});
            },
          )
        : PxButton(
            ready ? 'Ready!' : 'Ready Up',
            width: primaryW,
            textColor: ready ? Px.green : null,
            sound: ready ? 'ui_back' : 'ready',
            onPressed: () => widget.client.send({'t': 'ready', 'ready': !ready}),
          );
    final footer = Padding(
      padding: EdgeInsets.fromLTRB(0, 4.0 * gs, 0, 6.0 * gs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PxText(
            isHost
                ? 'You are the host  ·  $readyCount / ${s.roster.length} ready  ·  $humans ${humans == 1 ? 'human' : 'humans'}'
                : 'Waiting for the host to start  ·  $readyCount / ${s.roster.length} ready',
            color: Px.gray,
            maxLines: 1,
          ),
          SizedBox(height: 3.0 * gs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4.0 * gs,
            runSpacing: 4.0 * gs,
            children: [
              primary,
              if (isHost) ...[
                PxButton(
                  'Add Bot',
                  width: sideW,
                  onPressed: s.roster.length < 12 ? () => widget.client.send({'t': Msg.addBot}) : null,
                ),
                PxButton(
                  'Remove Bot',
                  width: sideW,
                  onPressed: s.roster.any((p) => p.bot) ? () => widget.client.send({'t': Msg.removeBot}) : null,
                ),
              ],
              PxButton(
                'Options...',
                width: sideW,
                onPressed: () =>
                    showOptionsScreen(context, widget.settings, background: DirtBackground(dirt: widget.assets?.dirt)),
              ),
              PxButton('Leave', width: leaveW, sound: 'ui_back', onPressed: widget.client.leaveRoom),
            ],
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: PxScreen(
        background: DirtBackground(dirt: widget.assets?.dirt),
        footer: footer,
        child: Column(
          children: [
            header,
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 20.0 * gs : 6.0 * gs),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 460.0 * gs),
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rules(BuildContext context) {
    final gs = Gui.of(context);
    final c = widget.client;
    final durationMin = (s.durationTicks / 1200).round();
    final modeLabel = s.mode == GameMode.creative ? 'Creative' : 'Survival';
    final lengthLabel = durationMin == 0 ? 'Open' : '$durationMin min';
    if (!isHost) {
      Widget row(String k, String v) => Row(
        children: [
          Expanded(child: PxText(k, color: Px.gray)),
          PxText(v),
        ],
      );
      return Container(
        padding: EdgeInsets.all(3.0 * gs),
        color: const Color(0x80000000),
        child: Column(
          children: [
            row('Game Mode', modeLabel),
            row('Match Length', lengthLabel),
            row('Creatures', s.spawnMobs ? 'On' : 'Off'),
            row('Time of Day', s.freezeTime ? 'Frozen' : 'Cycles'),
            SizedBox(height: 2.0 * gs),
            const PxText('Only the host can change world rules.', color: Px.darkGray, maxLines: 1),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final short = Gui.guiSize(context).height < 260;
        final two = box.maxWidth >= 208.0 * gs || short;
        final w = two
            ? ((box.maxWidth / gs - 4) / 2).floorToDouble().clamp(60.0, 150.0)
            : (box.maxWidth / gs).floorToDouble();
        final terse = w < 120;
        final buttons = [
          PxButton(
            terse ? 'Mode: $modeLabel' : 'Game Mode: $modeLabel',
            width: w,
            onPressed: () => c.send({
              't': Msg.roomSettings,
              'mode': s.mode == GameMode.creative ? GameMode.survival : GameMode.creative,
            }),
          ),
          PxButton(
            terse ? 'Length: $lengthLabel' : 'Match Length: $lengthLabel',
            width: w,
            onPressed: () {
              const steps = [0, 5, 10, 20];
              final i = steps.indexOf(durationMin);
              final next = steps[(i + 1) % steps.length];
              c.send({'t': Msg.roomSettings, 'durationTicks': next * 1200});
            },
          ),
          PxButton(
            'Creatures: ${s.spawnMobs ? 'ON' : 'OFF'}',
            width: w,
            onPressed: () => c.send({'t': Msg.roomSettings, 'spawnMobs': !s.spawnMobs}),
          ),
          PxButton(
            terse
                ? 'Time: ${s.freezeTime ? 'Frozen' : 'Cycles'}'
                : 'Time of Day: ${s.freezeTime ? 'Frozen' : 'Cycles'}',
            width: w,
            onPressed: () => c.send({'t': Msg.roomSettings, 'freezeTime': !s.freezeTime}),
          ),
        ];
        if (!two) {
          return Column(
            children: [
              for (final b in buttons)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.0 * gs),
                  child: b,
                ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                buttons[0],
                SizedBox(width: 4.0 * gs),
                buttons[1],
              ],
            ),
            SizedBox(height: 4.0 * gs),
            Row(
              children: [
                buttons[2],
                SizedBox(width: 4.0 * gs),
                buttons[3],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isHost, required this.isYou});
  final PlayerInfo player;
  final bool isHost;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final gs = Gui.of(context);
    final ready = player.ready || isHost;
    return Row(
      children: [
        Container(
          width: 16.0 * gs,
          height: 16.0 * gs,
          color: platformColor(player.platform).withValues(alpha: 0.85),
          alignment: Alignment.center,
          child: PxText(
            player.bot ? 'B' : platformLabel(player.platform).substring(0, 1),
            color: Colors.black,
            shadow: false,
          ),
        ),
        SizedBox(width: 3.0 * gs),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: PxText(player.name, maxLines: 1)),
                  if (isYou) PxText(' (you)', color: Px.aqua),
                  if (isHost) PxText(' host', color: Px.gold),
                ],
              ),
              PxText(
                player.bot ? 'Bot' : (player.connected ? platformLabel(player.platform) : 'Reconnecting...'),
                color: Px.gray,
              ),
            ],
          ),
        ),
        PxText(ready ? 'Ready' : '...', color: ready ? Px.green : Px.gray),
      ],
    );
  }
}
