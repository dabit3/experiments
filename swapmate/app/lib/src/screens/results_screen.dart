import 'package:flutter/material.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../net/game_client.dart';
import '../theme/tokens.dart';
import '../widgets/board_view.dart';
import '../widgets/common.dart';
import '../widgets/move_list.dart';
import '../widgets/piece_painter.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.client,
    required this.onToggleTheme,
  });

  final GameClient client;
  final VoidCallback onToggleTheme;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: Motion.slow,
  )..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  String reasonText(MatchResult r, RoomState room) {
    final loser = r.loser == null ? null : room.seated(r.loser!)?.name;
    final board = r.board == null
        ? ''
        : ' on board ${r.board!.id.toUpperCase()}';
    return switch (r.reason) {
      ResultReason.checkmate => '${loser ?? 'A king'} was checkmated$board',
      ResultReason.timeout => '${loser ?? 'A player'} ran out of time$board',
      ResultReason.resignation => '${loser ?? 'A player'} resigned',
      ResultReason.stalemate => 'Stalemate$board',
      ResultReason.repetition => 'Threefold repetition$board',
      ResultReason.agreement => 'Draw by agreement',
      ResultReason.abandonment => '${loser ?? 'A player'} left the match',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final client = widget.client;
    final room = client.room!;
    final game = client.game!;
    final result = game.result!;
    final myTeam = client.mySeat?.team;
    final won = myTeam != null && result.winner == myTeam;
    final lost =
        myTeam != null && result.winner != null && result.winner != myTeam;
    final headline = result.isDraw
        ? 'Draw'
        : myTeam == null
        ? 'Team ${result.winner!.id} wins'
        : won
        ? 'Victory'
        : 'Defeat';
    final accent = result.isDraw
        ? c.textMuted
        : (lost ? c.danger : c.team(result.winner!));
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final narrow = width < 480;
    final votes = room.rematchVotes.length;
    final iVoted =
        client.playerId != null && room.rematchVotes.contains(client.playerId);
    final humans = room.players.where((p) => !p.isBot).length;

    final summary = Panel(
      raised: true,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  result.isDraw
                      ? Icons.handshake_outlined
                      : (lost
                            ? Icons.sentiment_dissatisfied_outlined
                            : Icons.emoji_events_outlined),
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      key: const Key('result-headline'),
                      style: context.type.displayMedium?.copyWith(
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reasonText(result, room),
                      key: const Key('result-reason'),
                      style: context.type.bodyMedium?.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          if (narrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TeamResult(
                  team: Team.one,
                  room: room,
                  result: result,
                  mine: myTeam == Team.one,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.sm),
                  child: Center(
                    child: Text(
                      result.pgn,
                      key: const Key('result-score'),
                      style: context.type.headlineMedium?.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
                _TeamResult(
                  team: Team.two,
                  room: room,
                  result: result,
                  mine: myTeam == Team.two,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _TeamResult(
                    team: Team.one,
                    room: room,
                    result: result,
                    mine: myTeam == Team.one,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Text(
                    result.pgn,
                    key: const Key('result-score'),
                    style: context.type.headlineMedium?.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamResult(
                    team: Team.two,
                    room: room,
                    result: result,
                    mine: myTeam == Team.two,
                  ),
                ),
              ],
            ),
          const SizedBox(height: Space.xl),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (client.mySeat != null)
                FilledButton.icon(
                  key: const Key('result-rematch'),
                  onPressed: iVoted ? null : client.rematch,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    iVoted
                        ? 'Waiting ($votes/$humans)'
                        : 'Rematch${votes > 0 ? ' ($votes/$humans)' : ''}',
                  ),
                ),
              OutlinedButton.icon(
                key: const Key('result-copy-bpgn'),
                onPressed: game.bpgn == null
                    ? null
                    : () => copyToClipboard(
                        context,
                        game.bpgn!,
                        'BPGN copied to clipboard',
                      ),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Copy BPGN'),
              ),
              TextButton.icon(
                key: const Key('result-leave'),
                onPressed: client.leaveRoom,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Leave room'),
              ),
            ],
          ),
          if (client.isHost &&
              votes > 0 &&
              !room.rematchVotes.every((v) => v == client.playerId))
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(
                'Players want a rematch — vote to start the next match.',
                style: context.type.bodySmall,
              ),
            ),
        ],
      ),
    );

    final boards = Row(
      children: [
        for (final b in BoardId.values) ...[
          Expanded(
            child: _FinalBoard(
              snapshot: game.boards[b]!,
              room: room,
              decided: result.board == b,
            ),
          ),
          if (b == BoardId.a) const SizedBox(width: Space.md),
        ],
      ],
    );

    final bpgn = Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.md,
              Space.md,
              Space.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 16, color: c.textMuted),
                const SizedBox(width: Space.sm),
                Text('BPGN', style: context.type.titleSmall),
                const Spacer(),
                Text(
                  '${game.moves.length} moves',
                  style: context.type.labelSmall,
                ),
              ],
            ),
          ),
          Divider(color: c.outline),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(Space.md),
            child: SingleChildScrollView(
              child: SelectableText(
                game.bpgn ?? '',
                key: const Key('result-bpgn'),
                style: context.type.bodySmall?.copyWith(
                  fontFamily: 'Inter',
                  color: c.textMuted,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _in, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _in, curve: Motion.curve)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.md,
                    Space.sm,
                    Space.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: Space.xs),
                      const SwapmateMark(size: 28),
                      const SizedBox(width: Space.sm),
                      Text('Results', style: context.type.headlineSmall),
                      const SizedBox(width: Space.md),
                      Chip2(room.code, icon: Icons.tag, dense: true),
                      const Spacer(),
                      StatusPill(client),
                      IconButton(
                        tooltip: c.isDark ? 'Light theme' : 'Dark theme',
                        onPressed: widget.onToggleTheme,
                        icon: Icon(
                          c.isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Space.lg),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        summary,
                                        const SizedBox(height: Space.lg),
                                        boards,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Space.lg),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 360,
                                          child: MoveList(moves: game.moves),
                                        ),
                                        const SizedBox(height: Space.lg),
                                        bpgn,
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  summary,
                                  const SizedBox(height: Space.lg),
                                  boards,
                                  const SizedBox(height: Space.lg),
                                  SizedBox(
                                    height: 280,
                                    child: MoveList(
                                      moves: game.moves,
                                      dense: true,
                                    ),
                                  ),
                                  const SizedBox(height: Space.lg),
                                  bpgn,
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamResult extends StatelessWidget {
  const _TeamResult({
    required this.team,
    required this.room,
    required this.result,
    required this.mine,
  });
  final Team team;
  final RoomState room;
  final MatchResult result;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = c.team(team);
    final won = result.winner == team;
    final seats = Seat.values.where((s) => s.team == team);
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: won ? c.teamSoft(team) : c.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: won ? color : c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.xs),
              Text(
                'Team ${team.id}',
                style: context.type.labelMedium?.copyWith(color: color),
              ),
              if (won) ...[
                const SizedBox(width: Space.xs),
                Icon(Icons.emoji_events, size: 14, color: color),
              ],
              if (mine) ...[const Spacer(), Chip2('You', dense: true)],
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final s in seats)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    platformIcon(room.seated(s)?.platform),
                    size: 12,
                    color: c.textFaint,
                  ),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text(
                      room.seated(s)?.name ?? 'Empty',
                      overflow: TextOverflow.ellipsis,
                      style: context.type.bodySmall?.copyWith(color: c.text),
                    ),
                  ),
                  Text(
                    s.label.split('·').last.trim(),
                    style: context.type.labelSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FinalBoard extends StatelessWidget {
  const _FinalBoard({
    required this.snapshot,
    required this.room,
    required this.decided,
  });
  final BoardSnapshot snapshot;
  final RoomState room;
  final bool decided;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = snapshot.id;
    final white = room.seated(Seat.at(b, PieceColor.white));
    final black = room.seated(Seat.at(b, PieceColor.black));
    return Panel(
      padding: const EdgeInsets.all(Space.md),
      borderColor: decided ? c.accent.withValues(alpha: 0.7) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Board ${b.id.toUpperCase()}',
                style: context.type.titleSmall,
              ),
              if (decided) ...[
                const SizedBox(width: Space.sm),
                Chip2(
                  'Decisive',
                  dense: true,
                  color: c.accent,
                  background: c.accentSoft,
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.sm),
          _name(context, black, PieceColor.black, snapshot.blackMs),
          const SizedBox(height: Space.xs),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: c.boardFrame,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 1,
                child: BoardView(
                  position: snapshot.position,
                  orientation: PieceColor.white,
                  boardId: b,
                  lastMove: snapshot.lastMove,
                  inCheck: snapshot.inCheck,
                  showCoordinates: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          _name(context, white, PieceColor.white, snapshot.whiteMs),
        ],
      ),
    );
  }

  Widget _name(
    BuildContext context,
    PlayerInfo? p,
    PieceColor color,
    int clockMs,
  ) {
    final c = context.colors;
    return Row(
      children: [
        PieceGlyph(Piece(color, PieceType.pawn), size: 16, shadow: false),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            p?.name ?? 'Empty',
            overflow: TextOverflow.ellipsis,
            style: context.type.bodySmall?.copyWith(color: c.text),
          ),
        ),
        Icon(platformIcon(p?.platform), size: 12, color: c.textFaint),
        const SizedBox(width: Space.sm),
        Text(
          ClockView.format(clockMs),
          style: context.type.labelSmall?.copyWith(
            color: c.textMuted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
