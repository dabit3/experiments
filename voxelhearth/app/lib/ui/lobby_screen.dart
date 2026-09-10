import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'chat_panel.dart';
import 'settings_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final ff = formFactorOf(context);
    final t = Theme.of(context);
    final desktop = ff == FormFactor.desktop;
    // Desktop with enough height: chat fills the remaining column and nothing
    // scrolls. Otherwise the whole page scrolls with fixed-height chat.
    Widget desktopBody(bool fill) => Row(
      crossAxisAlignment: fill ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: fill ? SingleChildScrollView(child: _rosterCard(context)) : _rosterCard(context)),
        const SizedBox(width: VhSpace.xl),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _settingsCard(context),
              const SizedBox(height: VhSpace.xl),
              if (fill) Expanded(child: _chatCard(context)) else SizedBox(height: 300, child: _chatCard(context)),
            ],
          ),
        ),
      ],
    );
    final body = desktop
        ? desktopBody(false)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _rosterCard(context),
              const SizedBox(height: VhSpace.lg),
              _settingsCard(context),
              const SizedBox(height: VhSpace.lg),
              SizedBox(height: 260, child: _chatCard(context)),
            ],
          );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final pad = EdgeInsets.symmetric(
                    horizontal: ff == FormFactor.phone ? VhSpace.lg : VhSpace.xxxl,
                    vertical: VhSpace.md,
                  );
                  if (desktop && c.maxHeight >= 560) {
                    return Padding(
                      padding: pad,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: desktopBody(true),
                        ),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: pad,
                    child: Center(
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: body),
                    ),
                  );
                },
              ),
            ),
            _footer(context, t),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = Theme.of(context);
    final ff = formFactorOf(context);
    final phone = ff == FormFactor.phone;
    final modeLabel = s.mode == GameMode.creative ? 'Creative' : 'Survival';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ff == FormFactor.phone ? VhSpace.md : VhSpace.xxl,
        VhSpace.md,
        ff == FormFactor.phone ? VhSpace.md : VhSpace.xxl,
        VhSpace.sm,
      ),
      child: Row(
        children: [
          IconButton(tooltip: 'Leave world', onPressed: _leave, icon: const Icon(Icons.arrow_back_rounded)),
          const SizedBox(width: VhSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.roomName,
                  style: ff == FormFactor.phone ? t.textTheme.headlineSmall : t.textTheme.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  phone
                      ? '$modeLabel · ${s.roster.length} in lobby'
                      : '$modeLabel · seed ${s.seed} · ${s.roster.length} in lobby',
                  style: t.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          RoomCodeChip(s.code, onCopy: () => _copy(context), compact: phone),
          const SizedBox(width: VhSpace.xs),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => showSettingsSheet(context, widget.settings, null),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: s.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room code ${s.code} copied'), behavior: SnackBarBehavior.floating, width: 280),
    );
  }

  Widget _footer(BuildContext context, ThemeData t) {
    final me = you;
    final ready = me?.ready ?? false;
    final humans = s.roster.where((p) => !p.bot).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(VhSpace.lg, VhSpace.md, VhSpace.lg, VhSpace.lg),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        border: Border(top: BorderSide(color: t.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isHost ? 'You are the host' : 'Waiting for the host to start', style: t.textTheme.titleSmall),
                  Text(
                    '$readyCount / ${s.roster.length} ready · $humans ${humans == 1 ? 'human' : 'humans'}',
                    style: t.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!isHost)
              FilledButton.tonalIcon(
                onPressed: () => widget.client.send({'t': 'ready', 'ready': !ready}),
                icon: Icon(ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
                label: Text(ready ? 'Ready' : 'Ready up'),
              ),
            if (isHost)
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.client.send({'t': Msg.startMatch});
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start match'),
              ),
          ],
        ),
      ),
    );
  }

  void _leave() {
    widget.client.leaveRoom();
  }

  Widget _rosterCard(BuildContext context) {
    final t = Theme.of(context);
    final list = roster;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VhSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Players', style: t.textTheme.headlineSmall)),
                if (isHost) ...[
                  IconButton.filledTonal(
                    tooltip: 'Remove bot',
                    onPressed: s.roster.any((p) => p.bot) ? () => widget.client.send({'t': Msg.removeBot}) : null,
                    icon: const Icon(Icons.smart_toy_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    tooltip: 'Add bot',
                    onPressed: s.roster.length < 12 ? () => widget.client.send({'t': Msg.addBot}) : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ],
            ),
            const SizedBox(height: VhSpace.md),
            if (list.isEmpty)
              const StateBlock(
                icon: Icons.group_outlined,
                title: 'Nobody here yet',
                message: 'Share the room code to invite friends.',
                loading: true,
              ),
            for (var i = 0; i < list.length; i++)
              Reveal(
                key: ValueKey(list[i].id),
                delay: Duration(milliseconds: 30 * i),
                child: _PlayerRow(player: list[i], isHost: list[i].id == s.hostId, isYou: list[i].id == s.youId),
              ),
            const SizedBox(height: VhSpace.sm),
            Text(
              'Everyone shares one persistent world. Blocks you place stay for everyone, on every device.',
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context) {
    final t = Theme.of(context);
    final c = widget.client;
    final durationMin = (s.durationTicks / 1200).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VhSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('World rules', style: t.textTheme.headlineSmall),
            const SizedBox(height: VhSpace.md),
            const SectionLabel('Mode'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: GameMode.survival, label: Text('Survival'), icon: Icon(Icons.shield_moon_rounded)),
                ButtonSegment(value: GameMode.creative, label: Text('Creative'), icon: Icon(Icons.brush_rounded)),
              ],
              selected: {s.mode},
              onSelectionChanged: isHost ? (v) => c.send({'t': Msg.roomSettings, 'mode': v.first}) : null,
              showSelectedIcon: false,
            ),
            const SizedBox(height: VhSpace.lg),
            const SectionLabel('Match length'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Open')),
                ButtonSegment(value: 5, label: Text('5 min')),
                ButtonSegment(value: 10, label: Text('10 min')),
                ButtonSegment(value: 20, label: Text('20 min')),
              ],
              selected: {
                [0, 5, 10, 20].contains(durationMin) ? durationMin : 0,
              },
              onSelectionChanged: isHost
                  ? (v) => c.send({'t': Msg.roomSettings, 'durationTicks': v.first * 1200})
                  : null,
              showSelectedIcon: false,
            ),
            const SizedBox(height: VhSpace.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Creatures'),
              subtitle: const Text('Mossbacks by day, Hollows and Cinderlings at night'),
              value: s.spawnMobs,
              onChanged: isHost ? (v) => c.send({'t': Msg.roomSettings, 'spawnMobs': v}) : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Freeze time of day'),
              value: s.freezeTime,
              onChanged: isHost ? (v) => c.send({'t': Msg.roomSettings, 'freezeTime': v}) : null,
            ),
            if (!isHost)
              Padding(
                padding: const EdgeInsets.only(top: VhSpace.xs),
                child: Text('Only the host can change world rules.', style: t.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chatCard(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ChatPanel(client: widget.client, session: s, dense: false),
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isHost, required this.isYou});
  final PlayerInfo player;
  final bool isHost;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ready = player.ready || isHost;
    return Padding(
      padding: const EdgeInsets.only(bottom: VhSpace.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: VhSpace.md, vertical: VhSpace.sm),
        decoration: BoxDecoration(
          color: isYou ? t.colorScheme.primaryContainer.withValues(alpha: 0.35) : t.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(VhRadius.md),
          border: isYou ? Border.all(color: t.colorScheme.primary.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: platformColor(player.platform).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(VhRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(
                player.bot ? Icons.smart_toy_outlined : platformIcon(player.platform),
                color: platformColor(player.platform),
              ),
            ),
            const SizedBox(width: VhSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          style: t.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isYou)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('you', style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.primary)),
                        ),
                      if (isHost)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.local_fire_department_rounded, size: 16, color: VhColors.ember),
                        ),
                    ],
                  ),
                  Text(
                    player.bot
                        ? 'Bot · always ready'
                        : (player.connected ? platformLabel(player.platform) : 'Reconnecting…'),
                    style: t.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: VhMotion.base,
              child: Icon(
                key: ValueKey(ready),
                ready ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                color: ready ? VhColors.moss : t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
