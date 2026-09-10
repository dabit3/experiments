import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/level_preview.dart';
import '../widgets/platform_mark.dart';
import '../widgets/ui.dart';
import 'how_to_play.dart';

IconData platformIcon(String p) => switch (p) {
  'web' => Icons.language_rounded,
  'ios' => Icons.phone_iphone_rounded,
  'android' => Icons.phone_android_rounded,
  'macos' => Icons.laptop_mac_rounded,
  'server' => Icons.smart_toy_rounded,
  _ => Icons.devices_other_rounded,
};

/// Room lobby: code, seats, level select (world map), ready/start.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key, required this.client, required this.room, required this.onToggleTheme});
  final GameClient client;
  final RoomInfo room;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final me = room.players.where((p) => p['id'] == client.playerId).firstOrNull;
    final ready = me?['ready'] == true;
    final humans = room.players.where((p) => p['bot'] != true).toList();
    final allReady = humans.every((p) => p['ready'] == true);
    final wide = MediaQuery.sizeOf(context).width > 900;
    final level = levelById(room.levelId);

    final seats = PPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            'Chefs · ${room.players.length}/${room.maxPlayers}',
            trailing: client.isHost
                ? Row(
                    children: [
                      _MiniIconButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Remove bot',
                        onTap: room.players.any((p) => p['bot'] == true) ? client.removeBot : null,
                      ),
                      const SizedBox(width: 4),
                      _MiniIconButton(
                        icon: Icons.smart_toy_rounded,
                        tooltip: 'Add bot',
                        onTap: room.players.length < room.maxPlayers ? client.addBot : null,
                      ),
                    ],
                  )
                : null,
          ),
          for (var i = 0; i < room.maxPlayers; i++)
            Enter(
              index: i,
              child: _Seat(
                slot: i,
                player: room.players.where((p) => p['slot'] == i).firstOrNull,
                isMe: room.players.where((p) => p['slot'] == i).firstOrNull?['id'] == client.playerId,
                isHost: room.players.where((p) => p['slot'] == i).firstOrNull?['id'] == room.hostId,
              ),
            ),
        ],
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PPButton(
                label: ready ? 'Ready!' : 'Ready up',
                icon: ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                kind: ready ? PPButtonKind.secondary : PPButtonKind.primary,
                expand: true,
                onPressed: () => client.setReady(!ready),
              ),
            ),
            if (client.isHost) ...[
              const SizedBox(width: PPSpace.x3),
              Expanded(
                child: PPButton(
                  label: 'Start cooking',
                  icon: Icons.play_arrow_rounded,
                  expand: true,
                  tooltip: allReady ? null : 'Waiting for everyone to ready up',
                  onPressed: allReady && humans.isNotEmpty ? client.start : null,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: PPSpace.x3),
        Row(
          children: [
            PPButton(
              label: 'Leave',
              icon: Icons.logout_rounded,
              kind: PPButtonKind.ghost,
              compact: true,
              onPressed: client.leaveRoom,
            ),
            const Spacer(),
            if (!client.isHost)
              Text(
                allReady ? 'Waiting for the host to start…' : 'Waiting for chefs to ready up…',
                style: PPType.small(s.text3),
              ),
          ],
        ),
      ],
    );

    final levels = PPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            'Kitchen',
            trailing: client.isHost
                ? Text('You pick the kitchen', style: PPType.small(s.text3))
                : Text('Host picks the kitchen', style: PPType.small(s.text3)),
          ),
          _LevelMap(selected: room.levelId, isDark: s.isDark, onSelect: client.isHost ? client.setLevel : null),
          const SizedBox(height: PPSpace.x4),
          _LevelDetails(level: level, players: room.players.length),
        ],
      ),
    );

    final header = Row(
      children: [
        const Wordmark(size: 18),
        const SizedBox(width: PPSpace.x5),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: PPSpace.x2,
            children: [
              Text('Join code', style: PPType.caption(s.text3)),
              _CodeBadge(code: room.code),
              PPChip(
                label: '${client.rttMs} ms',
                icon: Icons.network_check_rounded,
                color: client.rttMs < 80 ? PPColor.basil : PPColor.butter,
              ),
              if (room.match > 0)
                PPChip(label: 'Rematch ${room.match + 1}', icon: Icons.replay_rounded, color: PPColor.plum),
            ],
          ),
        ),
        IconButton(
          tooltip: 'How to play',
          onPressed: () => showHowToPlay(context),
          icon: Icon(Icons.help_outline_rounded, color: s.text2),
        ),
        IconButton(
          tooltip: 'Toggle theme',
          onPressed: onToggleTheme,
          icon: Icon(s.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: s.text2),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PPSpace.x5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Enter(child: header),
                  const SizedBox(height: PPSpace.x5),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: Enter(index: 1, child: levels)),
                        const SizedBox(width: PPSpace.x5),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              Enter(index: 2, child: seats),
                              const SizedBox(height: PPSpace.x5),
                              Enter(index: 3, child: actions),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Enter(index: 1, child: seats),
                    const SizedBox(height: PPSpace.x5),
                    Enter(index: 2, child: levels),
                    const SizedBox(height: PPSpace.x5),
                    Enter(index: 3, child: actions),
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

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.tooltip, this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: s.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: s.outline),
            ),
            child: Icon(icon, size: 17, color: s.text),
          ),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Tooltip(
      message: 'Copy code',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Clipboard.setData(ClipboardData(text: code));
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Code $code copied'), behavior: SnackBarBehavior.floating, width: 240));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PPSpace.x3, vertical: 6),
          decoration: BoxDecoration(color: s.text, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(code, style: PPType.mono(s.bg).copyWith(fontSize: 18, letterSpacing: 4)),
              const SizedBox(width: 6),
              Icon(Icons.copy_rounded, size: 14, color: s.bg.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.slot, required this.player, required this.isMe, required this.isHost});
  final int slot;
  final Map<String, dynamic>? player;
  final bool isMe;
  final bool isHost;

  Widget _maybeMark(Widget child) => isMe ? PlatformMark(id: 'lobby-device', child: child) : child;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final col = PPColor.chefs[slot];
    final p = player;
    final empty = p == null;
    final connected = p?['connected'] != false;
    return AnimatedContainer(
      duration: PPMotion.base,
      curve: PPMotion.emphasized,
      margin: const EdgeInsets.only(bottom: PPSpace.x2),
      padding: const EdgeInsets.symmetric(horizontal: PPSpace.x3, vertical: PPSpace.x3),
      decoration: BoxDecoration(
        color: empty ? Colors.transparent : (isMe ? col.withValues(alpha: 0.10) : s.surface2),
        borderRadius: PPRadius.button,
        border: Border.all(
          color: empty ? s.outline : (isMe ? col.withValues(alpha: 0.6) : s.outline),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: empty ? s.outline.withValues(alpha: 0.5) : col,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: empty ? 0 : 0.7), width: 2),
            ),
            child: Icon(
              empty
                  ? Icons.person_add_alt_1_rounded
                  : (p['bot'] == true ? Icons.smart_toy_rounded : Icons.restaurant_rounded),
              size: 18,
              color: empty ? s.text3 : Colors.white,
            ),
          ),
          const SizedBox(width: PPSpace.x3),
          Expanded(
            child: empty
                ? Text('Open seat', style: PPType.body(s.text3))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(p['name'] as String, style: PPType.h3(s.text), overflow: TextOverflow.ellipsis),
                          ),
                          if (isMe) ...[const SizedBox(width: 6), Text('(you)', style: PPType.small(s.text3))],
                          if (isHost) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, size: 16, color: PPColor.butter),
                          ],
                        ],
                      ),
                      _maybeMark(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(platformIcon(p['platform'] as String), size: 13, color: s.text3),
                            const SizedBox(width: 4),
                            Text(
                              p['bot'] == true
                                  ? 'Server bot'
                                  : (connected ? (p['platform'] as String) : 'reconnecting…'),
                              style: PPType.small(connected ? s.text3 : PPColor.paprika),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          if (!empty)
            AnimatedSwitcher(
              duration: PPMotion.base,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: p['ready'] == true
                  ? const PPChip(
                      key: ValueKey('r'),
                      label: 'Ready',
                      icon: Icons.check_rounded,
                      color: PPColor.basil,
                      filled: true,
                    )
                  : PPChip(key: const ValueKey('n'), label: 'Not ready', color: s.text3),
            ),
        ],
      ),
    );
  }
}

/// Horizontal "world map": a path with one stop per kitchen.
class _LevelMap extends StatelessWidget {
  const _LevelMap({required this.selected, required this.isDark, this.onSelect});
  final String selected;
  final bool isDark;
  final void Function(String id)? onSelect;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return SizedBox(
      height: 172,
      child: Stack(
        children: [
          Positioned.fill(
            top: 64,
            bottom: 64,
            child: CustomPaint(painter: _PathPainter(color: s.outline)),
          ),
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: PPSpace.x1),
            itemCount: kLevels.length,
            separatorBuilder: (_, _) => const SizedBox(width: PPSpace.x3),
            itemBuilder: (context, i) {
              final l = kLevels[i];
              final sel = l.id == selected;
              final accent = Color(l.accent);
              return Enter(
                index: i,
                child: MouseRegion(
                  cursor: onSelect == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onSelect == null ? null : () => onSelect!(l.id),
                    child: AnimatedContainer(
                      duration: PPMotion.base,
                      curve: PPMotion.emphasized,
                      width: 168,
                      transform: Matrix4.translationValues(0, sel ? -4 : 0, 0),
                      decoration: BoxDecoration(
                        color: s.surface,
                        borderRadius: PPRadius.card,
                        border: Border.all(color: sel ? accent : s.outline, width: sel ? 2.5 : 1),
                        boxShadow: sel ? PPElevation.mid(s.brightness) : PPElevation.low(s.brightness),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 96,
                            color: accent.withValues(alpha: 0.12),
                            padding: const EdgeInsets.all(PPSpace.x2),
                            alignment: Alignment.center,
                            child: LevelPreview(level: l, isDark: isDark),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(PPSpace.x3, PPSpace.x2, PPSpace.x3, PPSpace.x3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                      child: Text(
                                        '${i + 1}',
                                        style: PPType.caption(Colors.white).copyWith(fontSize: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        l.name,
                                        style: PPType.h3(s.text).copyWith(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (l.tutorial)
                                      const Icon(Icons.school_rounded, size: 14, color: PPColor.blueberry),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.tagline,
                                  style: PPType.small(s.text3).copyWith(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 8, y), p);
      x += 16;
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.color != color;
}

class _LevelDetails extends StatelessWidget {
  const _LevelDetails({required this.level, required this.players});
  final LevelDef level;
  final int players;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final th = level.thresholdsFor(players.clamp(1, 4));
    return AnimatedSwitcher(
      duration: PPMotion.base,
      child: Column(
        key: ValueKey(level.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(level.name, style: PPType.h2(s.text))),
              PPChip(
                label: '${level.roundSeconds ~/ 60}:${(level.roundSeconds % 60).toString().padLeft(2, '0')}',
                icon: Icons.timer_rounded,
                color: Color(level.accent),
              ),
            ],
          ),
          const SizedBox(height: PPSpace.x1),
          Text(level.gimmick, style: PPType.body(s.text2)),
          const SizedBox(height: PPSpace.x3),
          Wrap(
            spacing: PPSpace.x2,
            runSpacing: PPSpace.x2,
            children: [
              for (final d in level.menu)
                PPChip(label: d.label, icon: d.cooked ? Icons.soup_kitchen_rounded : Icons.eco_rounded, color: s.text2),
              for (var i = 0; i < th.length; i++)
                PPChip(label: '${th[i]}', icon: Icons.star_rounded, iconCount: i + 1, color: PPColor.butter),
            ],
          ),
        ],
      ),
    );
  }
}
