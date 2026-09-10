import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../net/game_client.dart';
import '../theme/tokens.dart';
import '../widgets/chat_panel.dart';
import '../widgets/common.dart';
import '../widgets/piece_painter.dart';

const timeControls = [
  TimeControl(initialMs: 60000, incrementMs: 0),
  TimeControl(initialMs: 120000, incrementMs: 1000),
  TimeControl(initialMs: 180000, incrementMs: 0),
  TimeControl(initialMs: 300000, incrementMs: 0),
  TimeControl(initialMs: 300000, incrementMs: 3000),
];

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.client,
    required this.onToggleTheme,
  });

  final GameClient client;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final room = client.room!;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final me = client.me;
    final seatedCount = Seat.values.where((s) => room.seated(s) != null).length;
    final canStart = client.isHost;
    final ready = me?.ready ?? false;

    final header = Row(
      children: [
        IconButton(
          key: const Key('lobby-leave'),
          tooltip: 'Leave room',
          onPressed: client.leaveRoom,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: Space.xs),
        const SwapmateMark(size: 28),
        const SizedBox(width: Space.sm),
        Text('Lobby', style: context.type.headlineSmall),
        const Spacer(),
        StatusPill(client),
        const SizedBox(width: Space.xs),
        IconButton(
          tooltip: c.isDark ? 'Light theme' : 'Dark theme',
          onPressed: onToggleTheme,
          icon: Icon(
            c.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
      ],
    );

    final codeCard = Panel(
      raised: true,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ROOM CODE', style: context.type.labelSmall),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Text(
                room.code,
                key: const Key('lobby-code'),
                style: context.type.displayMedium?.copyWith(
                  letterSpacing: 8,
                  color: c.accent,
                ),
              ),
              const SizedBox(width: Space.md),
              IconButton(
                tooltip: 'Copy code',
                onPressed: () =>
                    copyToClipboard(context, room.code, 'Room code copied'),
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            seatedCount == 4
                ? (room.allReady
                      ? 'Everyone is ready.'
                      : 'Waiting for players to ready up.')
                : 'Share the code. ${4 - seatedCount} more ${4 - seatedCount == 1 ? 'player' : 'players'} needed — the host can fill empty seats with bots.',
            style: context.type.bodySmall,
          ),
          const SizedBox(height: Space.lg),
          Text('TIME CONTROL', style: context.type.labelSmall),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final tc in timeControls)
                _TimeChip(
                  tc: tc,
                  selected: tc == room.timeControl,
                  enabled: client.isHost,
                  onTap: () => client.setTimeControl(tc),
                ),
              if (!timeControls.contains(room.timeControl))
                _TimeChip(
                  tc: room.timeControl,
                  selected: true,
                  enabled: false,
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              if (me != null && me.seat != null)
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('lobby-ready'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      client.setReady(!ready);
                    },
                    style: ready
                        ? FilledButton.styleFrom(
                            backgroundColor: c.success.withValues(alpha: 0.18),
                            foregroundColor: c.success,
                          )
                        : null,
                    icon: Icon(
                      ready ? Icons.check_circle : Icons.check_circle_outline,
                    ),
                    label: Text(ready ? 'Ready' : 'I\'m ready'),
                  ),
                ),
              if (me != null && me.seat == null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Spectating'),
                  ),
                ),
              if (canStart) ...[
                const SizedBox(width: Space.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('lobby-start'),
                    onPressed: client.startMatch,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(seatedCount == 4 ? 'Start' : 'Start with bots'),
                  ),
                ),
              ],
            ],
          ),
          if (canStart)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(
                'Starting fills empty seats with bots and begins the match for everyone.',
                style: context.type.bodySmall?.copyWith(color: c.textFaint),
              ),
            ),
        ],
      ),
    );

    final teams = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TeamCard(team: Team.one, client: client),
        const SizedBox(height: Space.md),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.xs,
            ),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              'VS',
              style: context.type.labelMedium?.copyWith(color: c.textMuted),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        _TeamCard(team: Team.two, client: client),
        const SizedBox(height: Space.lg),
        _Spectators(room: room, client: client),
      ],
    );

    final chat = SizedBox(
      height: wide ? 320 : 260,
      child: ChatPanel(client: client, scopeSelectable: false),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
          child: Column(
            children: [
              header,
              const SizedBox(height: Space.sm),
              Expanded(
                child: wide
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                    bottom: Space.xl,
                                  ),
                                  child: teams,
                                ),
                              ),
                              const SizedBox(width: Space.xl),
                              Expanded(
                                flex: 4,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                    bottom: Space.xl,
                                  ),
                                  child: Column(
                                    children: [
                                      codeCard,
                                      const SizedBox(height: Space.lg),
                                      chat,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: Space.xl),
                        child: Column(
                          children: [
                            codeCard,
                            const SizedBox(height: Space.lg),
                            teams,
                            const SizedBox(height: Space.lg),
                            chat,
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.tc,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final TimeControl tc;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Time control ${tc.label}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.surfaceSunken,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: selected ? c.accent : c.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: selected ? c.accent : c.textMuted,
              ),
              const SizedBox(width: Space.xs),
              Text(
                tc.label,
                style: context.type.labelMedium?.copyWith(
                  color: selected ? c.text : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.client});
  final Team team;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final seats = Seat.values.where((s) => s.team == team).toList();
    final color = c.team(team);
    final mine = client.mySeat?.team == team;
    return Panel(
      borderColor: mine ? color.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.sm),
              Text('Team ${team.id}', style: context.type.titleMedium),
              if (mine) ...[
                const SizedBox(width: Space.sm),
                Chip2(
                  'Your team',
                  color: color,
                  background: c.teamSoft(team),
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 520;
              final cards = [
                for (final s in seats) _SeatCard(seat: s, client: client),
              ];
              if (stack) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: Space.sm),
                    cards[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: Space.sm),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({required this.seat, required this.client});
  final Seat seat;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final room = client.room!;
    final p = room.seated(seat);
    final isMe = p != null && p.id == client.playerId;
    final empty = p == null;
    final canSit = empty || (p.isBot && client.isHost);
    final ready = p != null && (p.ready || p.isBot);

    Widget body;
    if (empty) {
      body = Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: c.outlineStrong,
                style: BorderStyle.solid,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_add_alt_1_outlined,
              size: 16,
              color: c.textFaint,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open seat',
                  style: context.type.titleMedium?.copyWith(color: c.textMuted),
                ),
                Text(
                  client.mySeat == seat ? '' : 'Tap to sit',
                  style: context.type.bodySmall?.copyWith(color: c.textFaint),
                ),
              ],
            ),
          ),
          if (client.isHost)
            IconButton(
              tooltip: 'Add bot',
              key: Key('seat-bot-${seat.id}'),
              onPressed: () => client.setBot(seat, add: true),
              icon: const Icon(Icons.smart_toy_outlined, size: 18),
            ),
        ],
      );
    } else {
      body = Row(
        children: [
          Avatar(name: p.name, team: seat.team, size: 36, isBot: p.isBot),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.titleMedium,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: Space.xs),
                      Chip2(
                        'You',
                        dense: true,
                        color: c.accent,
                        background: c.accentSoft,
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      platformIcon(p.platform),
                      size: 12,
                      color: c.textFaint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.isBot
                          ? 'Bot'
                          : (p.connected
                                ? platformLabel(p.platform)
                                : 'Reconnecting…'),
                      style: context.type.bodySmall?.copyWith(
                        color: p.connected ? c.textFaint : c.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (p.isBot && client.isHost)
            IconButton(
              tooltip: 'Remove bot',
              onPressed: () => client.setBot(seat, add: false),
              icon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            )
          else
            AnimatedSwitcher(
              duration: Motion.base,
              child: ready
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey(1),
                      color: c.success,
                      size: 20,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      key: const ValueKey(0),
                      color: c.textFaint,
                      size: 20,
                    ),
            ),
        ],
      );
    }

    return Semantics(
      button: canSit,
      label: '${seat.label}: ${p?.name ?? 'open seat'}',
      child: InkWell(
        key: Key('seat-${seat.id}'),
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: canSit
            ? () {
                HapticFeedback.selectionClick();
                client.takeSeat(seat);
              }
            : null,
        child: AnimatedContainer(
          duration: Motion.base,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: isMe
                ? c.accentSoft.withValues(alpha: 0.12)
                : c.surfaceSunken,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
              color: isMe ? c.accent.withValues(alpha: 0.5) : c.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: seat.color == PieceColor.white
                          ? c.pieceWhite
                          : c.pieceBlack,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.outlineStrong),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Text(seat.label, style: context.type.labelSmall),
                ],
              ),
              const SizedBox(height: Space.sm),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _Spectators extends StatelessWidget {
  const _Spectators({required this.room, required this.client});
  final RoomState room;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final specs = room.spectators;
    return Panel(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: c.textMuted),
          const SizedBox(width: Space.sm),
          Expanded(
            child: specs.isEmpty
                ? Text('No spectators yet', style: context.type.bodySmall)
                : Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final s in specs)
                        Chip2(
                          s.name,
                          icon: platformIcon(s.platform),
                          dense: true,
                        ),
                    ],
                  ),
          ),
          if (client.mySeat != null)
            TextButton(
              onPressed: () => client.takeSeat(null),
              child: const Text('Spectate'),
            )
          else if (!room.allSeated)
            TextButton(
              onPressed: () {
                final free = Seat.values.firstWhere(
                  (s) => room.seated(s) == null,
                );
                client.takeSeat(free);
              },
              child: const Text('Take a seat'),
            ),
        ],
      ),
    );
  }
}
