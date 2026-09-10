import 'dart:async';
import 'dart:math' as math;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../game/obby_view.dart';
import '../game/tag_view.dart';
import '../game/tycoon_view.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';
import 'chat_panel.dart';
import 'profile_screen.dart';

/// Hosts the full room lifecycle: lobby → countdown → gameplay → results.
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  Timer? _clock;
  StreamSubscription<ServerError>? _errSub;
  RoomPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
    _errSub = AppScope.read(context).client.errors.listen((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _errSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final room = client.room!;
    final phase = room.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      if (AppScope.of(context).hapticsEnabled && phase == RoomPhase.playing) {
        HapticFeedback.heavyImpact();
      }
    }
    final showResults = phase == RoomPhase.results && client.results != null;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Motion.slow,
        switchInCurve: Motion.emphasized,
        switchOutCurve: Motion.standard,
        child: switch (phase) {
          RoomPhase.lobby || RoomPhase.countdown => _LobbyView(
            key: const ValueKey('lobby'),
            room: room,
          ),
          RoomPhase.playing => _GameplayView(
            key: ValueKey('play-${room.round}'),
            room: room,
          ),
          RoomPhase.results =>
            showResults
                ? _ResultsView(
                    key: ValueKey('results-${room.round}'),
                    room: room,
                    results: client.results!,
                  )
                : const Center(
                    key: ValueKey('results-loading'),
                    child: CircularProgressIndicator(),
                  ),
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Lobby & countdown
// -----------------------------------------------------------------------------

class _LobbyView extends StatelessWidget {
  const _LobbyView({super.key, required this.room});

  final RoomState room;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final place = placeFor(room.experience);
    final accent = Color(place.accent);
    final me = room.members
        .where((m) => m.player.id == client.myId)
        .firstOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= Breakpoints.tablet;
    final narrow = width < Breakpoints.compact;
    final humans = room.members.where((m) => !m.player.isBot).toList();
    final readyCount = humans.where((m) => m.ready).length;
    final countdown =
        room.phase == RoomPhase.countdown && room.countdownEndsAt != null
        ? ((room.countdownEndsAt! - client.serverNow()) / 1000).clamp(0.0, 9.0)
        : null;

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.lg,
        Space.md,
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Leave room',
            onPressed: client.roomLeave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: Space.md),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(experienceIcon(room.experience), color: accent),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: context.text.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  room.round == 0
                      ? 'Lobby · waiting for players'
                      : 'Lobby · match ${room.round} finished',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: p.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (!narrow) CodeBadge(room.code, label: 'Room code'),
        ],
      ),
    );

    final seats = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Players · ${humans.length}/$maxRoomPlayers',
                  style: context.text.titleMedium,
                ),
              ),
              Tag(
                '$readyCount/${humans.length} ready',
                icon: Icons.check_circle_outline_rounded,
                color: readyCount == humans.length
                    ? BrickColors.mint.withValues(alpha: 0.18)
                    : null,
                onColor: readyCount == humans.length ? BrickColors.mint : null,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 880
                  ? 4
                  : c.maxWidth >= 560
                  ? 3
                  : 2;
              final w = (c.maxWidth - Space.sm * (cols - 1)) / cols;
              final botSeats = math.min(
                client.roomBotCount,
                maxRoomPlayers - humans.length,
              );
              return Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (var i = 0; i < maxRoomPlayers; i++)
                    SizedBox(
                      width: w,
                      child: i < humans.length
                          ? _Seat(
                              member: humans[i],
                              mine: humans[i].player.id == client.myId,
                            )
                          : _Seat.empty(bot: i - humans.length < botSeats),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );

    final rules = Panel(
      color: accent.withValues(alpha: 0.08),
      borderColor: accent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to play', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          Text(
            place.description,
            style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              Tag(
                '${place.matchSeconds ~/ 60}:${(place.matchSeconds % 60).toString().padLeft(2, '0')} match',
                icon: Icons.timer_outlined,
              ),
              Tag('${place.minPlayers}+ to start', icon: Icons.group_outlined),
              Tag('Seed ${room.seed}', icon: Icons.casino_outlined),
              const Tag('Server-authoritative', icon: Icons.verified_outlined),
            ],
          ),
        ],
      ),
    );

    final readyBar = Panel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              countdown != null
                  ? 'Starting in ${countdown.ceil()}…'
                  : (me?.ready ?? false)
                  ? 'Waiting for everyone else to ready up.'
                  : 'Hit ready when you\'re set. Bots fill the empty seats.',
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          ),
          const SizedBox(width: Space.md),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: (me?.ready ?? false)
                    ? BrickColors.mint
                    : accent,
                padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              ),
              onPressed: me == null ? null : () => client.roomReady(!me.ready),
              icon: Icon(
                (me?.ready ?? false)
                    ? Icons.check_rounded
                    : Icons.sports_esports_rounded,
              ),
              label: Text((me?.ready ?? false) ? 'Ready!' : 'Ready up'),
            ),
          ),
        ],
      ),
    );

    final chat = SizedBox(
      height: wide ? double.infinity : 320,
      child: Panel(
        padding: EdgeInsets.zero,
        child: const ChatPanel(
          channels: [ChatChannel.room, ChatChannel.party, ChatChannel.global],
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Column(
            children: [
              header,
              if (narrow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CodeBadge(room.code, label: 'Room code'),
                  ),
                ),
              Expanded(
                child: ContentWidth(
                  max: 1200,
                  child: wide
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.lg,
                            0,
                            Space.lg,
                            Space.lg,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ListView(
                                  children: [
                                    Entrance(child: seats),
                                    const SizedBox(height: Space.lg),
                                    Entrance(
                                      delay: const Duration(milliseconds: 60),
                                      child: rules,
                                    ),
                                    const SizedBox(height: Space.lg),
                                    Entrance(
                                      delay: const Duration(milliseconds: 120),
                                      child: readyBar,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Space.lg),
                              Expanded(
                                flex: 2,
                                child: Entrance(
                                  delay: const Duration(milliseconds: 90),
                                  child: chat,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            Space.lg,
                            0,
                            Space.lg,
                            Space.lg,
                          ),
                          children: [
                            Entrance(child: seats),
                            const SizedBox(height: Space.lg),
                            Entrance(
                              delay: const Duration(milliseconds: 60),
                              child: readyBar,
                            ),
                            const SizedBox(height: Space.lg),
                            Entrance(
                              delay: const Duration(milliseconds: 120),
                              child: rules,
                            ),
                            const SizedBox(height: Space.lg),
                            Entrance(
                              delay: const Duration(milliseconds: 180),
                              child: chat,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        if (countdown != null)
          _CountdownOverlay(seconds: countdown, accent: accent),
      ],
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.member, required this.mine}) : bot = false;
  const _Seat.empty({required this.bot}) : member = null, mine = false;

  final RoomMember? member;
  final bool mine;
  final bool bot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final m = member;
    if (m == null) {
      return Container(
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: p.outline, style: BorderStyle.solid),
          color: bot ? p.surface2.withValues(alpha: 0.5) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              bot ? Icons.smart_toy_outlined : Icons.person_add_alt_outlined,
              color: p.textTertiary,
            ),
            const SizedBox(height: Space.xs),
            Text(
              bot ? 'Bot joins at start' : 'Open seat',
              style: context.text.labelSmall?.copyWith(color: p.textTertiary),
            ),
          ],
        ),
      );
    }
    return AnimatedContainer(
      duration: Motion.normal,
      height: 92,
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        color: m.ready ? BrickColors.mint.withValues(alpha: 0.12) : p.surface2,
        border: Border.all(
          color: mine
              ? BrickColors.sky
              : (m.ready ? BrickColors.mint.withValues(alpha: 0.5) : p.outline),
          width: mine ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarView(m.player.avatar, size: 52, background: p.surface3),
              Positioned(
                right: -4,
                bottom: -4,
                child: AnimatedSwitcher(
                  duration: Motion.fast,
                  child: m.ready
                      ? Container(
                          key: const ValueKey('ready'),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: BrickColors.mint,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.surface1, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('nr')),
                ),
              ),
            ],
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine ? '${m.player.name} (you)' : m.player.name,
                  style: context.text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.xxs),
                PlatformTag(m.player),
                if (!m.player.online)
                  Text(
                    'reconnecting…',
                    style: context.text.labelSmall?.copyWith(
                      color: BrickColors.sun,
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

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.seconds, required this.accent});

  final double seconds;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final n = seconds.ceil();
    final frac = seconds - seconds.floor();
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GET READY',
              style: context.text.labelLarge?.copyWith(
                color: Colors.white70,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: Space.md),
            Transform.scale(
              scale: 1 + (1 - frac) * 0.35,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  n == 0 ? 'GO' : '$n',
                  style: context.text.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: n == 0 ? 56 : 88,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Gameplay with HUD
// -----------------------------------------------------------------------------

class _GameplayView extends StatefulWidget {
  const _GameplayView({super.key, required this.room});

  final RoomState room;

  @override
  State<_GameplayView> createState() => _GameplayViewState();
}

class _GameplayViewState extends State<_GameplayView> {
  StreamSubscription<Map<String, Object?>>? _sub;
  final _toasts = <_Toast>[];
  bool _chatOpen = false;

  @override
  void initState() {
    super.initState();
    _sub = AppScope.read(context).client.gameEvents.listen(_onEvent);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(Map<String, Object?> e) {
    final client = AppScope.read(context).client;
    final members = {
      for (final m in client.room?.members ?? const <RoomMember>[])
        m.player.id: m.player.name,
    };
    final who = members[e['player']] ?? 'Someone';
    final mine = e['player'] == client.myId;
    final by = members[e['by']] ?? 'someone';
    String? text;
    Color color = BrickColors.sky;
    switch (e['kind']) {
      case 'checkpoint':
        text = mine
            ? 'Checkpoint ${e['value']}!'
            : '$who reached checkpoint ${e['value']}';
        color = BrickColors.mint;
      case 'finish':
        text = mine ? 'You finished!' : '$who finished!';
        color = BrickColors.sun;
      case 'death':
        if (mine) {
          text = 'Ouch! Back to the checkpoint.';
          color = BrickColors.cherry;
        }
      case 'freeze':
        text = mine ? 'Frozen by $by!' : '$who was frozen';
        color = const Color(0xFF35B8D6);
      case 'thaw':
        text = mine ? '$by thawed you!' : '$who was thawed';
        color = BrickColors.sun;
      case 'roundStart':
        text = 'Round ${(e['value'] as num).toInt() + 1} — run!';
        color = BrickColors.brick;
      case 'roundEnd':
        text = e['swept'] == true
            ? 'Everyone frozen — tagger sweep!'
            : 'Round over. Runners survive!';
        color = BrickColors.grape;
      case 'upgrade':
        if (!mine) text = '$who bought an upgrade';
        color = BrickColors.grape;
    }
    if (text == null || !mounted) return;
    final toast = _Toast(text, color);
    setState(() => _toasts.add(toast));
    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toasts.remove(toast));
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final room = widget.room;
    final pad = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= Breakpoints.tablet;
    final narrow = width < Breakpoints.compact;
    final game = switch (room.experience) {
      ExperienceKind.obby => const ObbyView(),
      ExperienceKind.tycoon => const TycoonView(),
      ExperienceKind.tag => const TagView(),
    };
    final left = room.matchEndsAt == null
        ? 0
        : ((room.matchEndsAt! - client.serverNow()) / 1000)
              .clamp(0, 9999)
              .ceil();
    final spectating = !room.members.any(
      (m) =>
          m.player.id == client.myId &&
          (client.frame?.json['players'] as Map?)?.containsKey(client.myId) !=
              false,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        game,
        // Top HUD
        Positioned(
          left: Space.md + pad.left,
          right: Space.md + pad.right,
          top: Space.sm + pad.top,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HudPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      experienceIcon(room.experience),
                      size: 16,
                      color: Color(placeFor(room.experience).accent),
                    ),
                    if (!narrow) ...[
                      const SizedBox(width: Space.xs),
                      Text(
                        placeFor(room.experience).name,
                        style: context.text.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              _Timer(seconds: left),
              const Spacer(),
              if (wide) _MiniBoard(room: room),
              if (wide) const SizedBox(width: Space.sm),
              const SizedBox(width: Space.sm),
              _HudPill(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Chat',
                      onPressed: () => setState(() => _chatOpen = !_chatOpen),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Leave match',
                      onPressed: () => _confirmLeave(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Per-experience status strip
        Positioned(
          left: Space.md + pad.left,
          top: 60 + pad.top,
          child: _StatusStrip(room: room),
        ),
        // Toasts
        Positioned(
          left: 0,
          right: 0,
          top: 110 + pad.top,
          child: IgnorePointer(
            child: Column(
              children: [
                for (final t in _toasts)
                  Entrance(
                    key: ValueKey(t),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: Space.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.lg,
                        vertical: Space.sm,
                      ),
                      decoration: BoxDecoration(
                        color: t.color.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        t.text,
                        style: context.text.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (spectating && client.frame != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100 + pad.bottom,
            child: Center(
              child: StatusBanner(
                text: 'Spectating — you\'ll join the next match',
                color: BrickColors.grape,
                icon: Icons.visibility_outlined,
              ),
            ),
          ),
        if (_chatOpen)
          Positioned(
            right: Space.md + pad.right,
            top: 60 + pad.top,
            bottom: 120 + pad.bottom,
            width: math.min(
              360,
              MediaQuery.sizeOf(context).width - Space.lg * 2,
            ),
            child: Panel(
              padding: EdgeInsets.zero,
              color: context.palette.surface1.withValues(alpha: 0.96),
              child: const ChatPanel(
                channels: [ChatChannel.room, ChatChannel.party],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave the match?'),
        content: const Text(
          'You can rejoin with the room code while the room is open.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).client.roomLeave();
    }
  }
}

class _Toast {
  _Toast(this.text, this.color);
  final String text;
  final Color color;
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Space.md,
      vertical: Space.sm,
    ),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 10;
    return _HudPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: urgent ? BrickColors.cherry : Colors.white70,
          ),
          const SizedBox(width: Space.xs),
          Text(
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: context.text.titleMedium?.copyWith(
              color: urgent ? BrickColors.cherry : Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small live leaderboard in the HUD.
class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.room});

  final RoomState room;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final rows = _liveRanking(client, room).take(4).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return _HudPill(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 16,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: Space.sm),
              ),
            Text(
              '${i + 1}',
              style: context.text.labelSmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(width: Space.xs),
            Text(
              rows[i].$1,
              style: context.text.labelMedium?.copyWith(
                color: rows[i].$3 ? BrickColors.sun : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: Space.xs),
            Text(
              rows[i].$2,
              style: context.text.labelSmall?.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

/// (name, detail, isMe) rows ordered best-first for the current frame.
List<(String, String, bool)> _liveRanking(
  BrickfolkClient client,
  RoomState room,
) {
  final f = client.frame;
  if (f == null) return const [];
  final names = {for (final m in room.members) m.player.id: m.player.name};
  switch (room.experience) {
    case ExperienceKind.obby:
      final players = (f.json['players'] as Map).cast<String, Object?>();
      final rows =
          players.entries
              .map(
                (e) => (
                  e.key,
                  ObbyPlayerState.fromPacked((e.value as List).cast()),
                ),
              )
              .toList()
            ..sort((a, b) {
              final c = ObbySim.score(b.$2).compareTo(ObbySim.score(a.$2));
              return c != 0 ? c : a.$1.compareTo(b.$1);
            });
      return [
        for (final (id, s) in rows)
          (
            names[id] ?? '?',
            s.finished ? 'done' : 'CP ${s.checkpoint}',
            id == client.myId,
          ),
      ];
    case ExperienceKind.tag:
      final players = (f.json['players'] as Map).cast<String, Object?>();
      final rows =
          players.entries
              .map(
                (e) => (
                  e.key,
                  TagPlayerState.fromPacked((e.value as List).cast()),
                ),
              )
              .toList()
            ..sort((a, b) {
              final c = b.$2.totalScore.compareTo(a.$2.totalScore);
              return c != 0 ? c : a.$1.compareTo(b.$1);
            });
      return [
        for (final (id, s) in rows)
          (names[id] ?? '?', '${s.totalScore}', id == client.myId),
      ];
    case ExperienceKind.tycoon:
      final earned = ((f.json['earned'] as Map?) ?? const {})
          .cast<String, Object?>();
      final rows =
          earned.entries.map((e) => (e.key, (e.value as num).toInt())).toList()
            ..sort((a, b) {
              final c = b.$2.compareTo(a.$2);
              return c != 0 ? c : a.$1.compareTo(b.$1);
            });
      return [
        for (final (id, v) in rows)
          (names[id] ?? '?', formatNumber(v), id == client.myId),
      ];
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.room});

  final RoomState room;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final f = client.frame;
    if (f == null) return const SizedBox.shrink();
    final children = <Widget>[];
    switch (room.experience) {
      case ExperienceKind.obby:
        final packed = (f.json['players'] as Map?)?[client.myId];
        if (packed is List) {
          final s = ObbyPlayerState.fromPacked(packed.cast());
          children.addAll([
            _stat(
              context,
              Icons.flag_rounded,
              'Stage ${s.checkpoint}/${ObbyCourse.instance.checkpoints.length}',
              BrickColors.mint,
            ),
            _stat(
              context,
              Icons.replay_rounded,
              '${s.deaths} falls',
              BrickColors.cherry,
            ),
            if (s.finished)
              _stat(
                context,
                Icons.emoji_events_rounded,
                'Finished',
                BrickColors.sun,
              ),
          ]);
        }
      case ExperienceKind.tag:
        final packed = (f.json['players'] as Map?)?[client.myId];
        final round = (f.json['round'] as num?)?.toInt() ?? 0;
        final roundLeft =
            ((f.json['roundTicksLeft'] as num?)?.toInt() ?? 0) ~/
            ticksPerSecond;
        final intermission = (f.json['intermission'] as num?)?.toInt() ?? 0;
        children.add(
          _stat(
            context,
            Icons.loop_rounded,
            'Round ${math.min(round + 1, TagSim.roundsPerMatch)}/${TagSim.roundsPerMatch} · ${intermission > 0 ? 'next in ${(intermission / ticksPerSecond).ceil()}' : '${roundLeft}s'}',
            BrickColors.grape,
          ),
        );
        if (packed is List) {
          final s = TagPlayerState.fromPacked(packed.cast());
          children.add(
            _stat(
              context,
              s.isTagger
                  ? Icons.local_fire_department_rounded
                  : (s.frozen
                        ? Icons.ac_unit_rounded
                        : Icons.directions_run_rounded),
              s.isTagger
                  ? 'You are IT'
                  : (s.frozen ? 'Frozen — wait for a thaw' : 'Runner'),
              s.isTagger
                  ? BrickColors.brick
                  : (s.frozen ? const Color(0xFF35B8D6) : BrickColors.mint),
            ),
          );
          children.add(
            _stat(
              context,
              Icons.star_rounded,
              '${s.totalScore} pts',
              BrickColors.sun,
            ),
          );
        }
      case ExperienceKind.tycoon:
        break;
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: Space.xs, runSpacing: Space.xs, children: children);
  }

  Widget _stat(BuildContext context, IconData icon, String text, Color color) =>
      _HudPill(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.sm + 2,
          vertical: Space.xs + 1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: Space.xs),
            Text(
              text,
              style: context.text.labelMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Results
// -----------------------------------------------------------------------------

class _ResultsView extends StatelessWidget {
  const _ResultsView({super.key, required this.room, required this.results});

  final RoomState room;
  final MatchResults results;

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final p = context.palette;
    final place = placeFor(room.experience);
    final accent = Color(place.accent);
    final mine = results.entries
        .where((e) => e.player.id == client.myId)
        .firstOrNull;
    final left = client.resultsEndsAt == null
        ? null
        : ((client.resultsEndsAt! - client.serverNow()) / 1000)
              .clamp(0, 99)
              .ceil();
    final podium = results.entries.take(3).toList();
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.25), p.surface0],
          stops: const [0, 0.45],
        ),
      ),
      child: SafeArea(
        child: ContentWidth(
          max: 900,
          child: ListView(
            padding: const EdgeInsets.all(Space.lg),
            children: [
              Entrance(
                child: Column(
                  children: [
                    const SizedBox(height: Space.md),
                    Text(
                      mine == null
                          ? 'MATCH OVER'
                          : (mine.rank == 1 ? 'VICTORY' : 'MATCH OVER'),
                      style: context.text.labelLarge?.copyWith(
                        color: p.textTertiary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      place.name,
                      style: context.text.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      mine == null
                          ? 'You spectated this one.'
                          : 'You placed #${mine.rank} of ${results.entries.length} · ${mine.detail}'
                                '${mine.pipsEarned > 0 ? ' · +${mine.pipsEarned} Pips' : ''}',
                      style: context.text.bodyLarge?.copyWith(
                        color: p.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              Entrance(
                delay: const Duration(milliseconds: 120),
                child: _Podium(entries: podium, accent: accent),
              ),
              const SizedBox(height: Space.xl),
              Entrance(
                delay: const Duration(milliseconds: 240),
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.lg,
                          Space.lg,
                          Space.lg,
                          Space.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Leaderboard',
                                style: context.text.titleMedium,
                              ),
                            ),
                            Tooltip(
                              message: 'Every client shows the same ranking; this digest proves it.',
                              child: Tag(
                                'Match ${results.checksum.substring(0, 8)}',
                                icon: Icons.fingerprint_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final e in results.entries)
                        _ResultRow(
                          entry: e,
                          mine: e.player.id == client.myId,
                          wide: wide,
                        ),
                      const SizedBox(height: Space.sm),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              Entrance(
                delay: const Duration(milliseconds: 320),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: client.roomLeave,
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to hub'),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        onPressed: null,
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(
                          left == null
                              ? 'Next lobby soon'
                              : 'Lobby opens in ${left}s',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                'Match lasted ${(results.durationMs / 1000).toStringAsFixed(1)}s · room ${results.roomCode} · seed ${room.seed}',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: p.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.accent});

  final List<LeaderboardEntry> entries;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Order 2 – 1 – 3 visually.
    final order = <LeaderboardEntry?>[
      entries.length > 1 ? entries[1] : null,
      entries.isNotEmpty ? entries[0] : null,
      entries.length > 2 ? entries[2] : null,
    ];
    final heights = [92.0, 128.0, 72.0];
    final colors = [
      const Color(0xFFB8C2D9),
      BrickColors.sun,
      const Color(0xFFD08A5A),
    ];
    return SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            if (order[i] != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 500 + i * 120),
                            curve: Motion.emphasized,
                            builder: (context, t, child) => Transform.translate(
                              offset: Offset(0, (1 - t) * 30),
                              child: Opacity(opacity: t, child: child),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i == 1)
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: BrickColors.sun,
                                    size: 32,
                                  ),
                                AvatarView(
                                  order[i]!.player.avatar,
                                  size: i == 1 ? 96 : 76,
                                ),
                                const SizedBox(height: Space.xs),
                                Text(
                                  order[i]!.player.name,
                                  style: context.text.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  order[i]!.detail,
                                  style: context.text.labelSmall?.copyWith(
                                    color: p.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: heights[i]),
                        duration: Duration(milliseconds: 600 + i * 100),
                        curve: Motion.emphasized,
                        builder: (context, h, _) => Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: colors[i],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(Radii.md),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.lerp(
                                  colors[i],
                                  Colors.black,
                                  0.4,
                                )!,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: Space.sm),
                          child: Text(
                            '${order[i]!.rank}',
                            style: context.text.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.entry,
    required this.mine,
    required this.wide,
  });

  final LeaderboardEntry entry;
  final bool mine;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: mine ? BrickColors.sky.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: entry.player.isBot
            ? null
            : () => showProfileDialog(context, entry.player.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.rank}',
                  style: context.text.titleMedium?.copyWith(
                    color: entry.rank <= 3 ? BrickColors.sun : p.textTertiary,
                  ),
                ),
              ),
              AvatarView(entry.player.avatar, size: 36, background: p.surface2),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mine
                                ? '${entry.player.name} (you)'
                                : entry.player.name,
                            style: context.text.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        PlatformTag(entry.player),
                      ],
                    ),
                    Text(
                      entry.detail,
                      style: context.text.bodySmall?.copyWith(
                        color: p.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.badgesEarned.isNotEmpty) ...[
                for (final b in entry.badgesEarned)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: BadgeChip(b, size: 26),
                  ),
                const SizedBox(width: Space.sm),
              ],
              if (entry.pipsEarned > 0 && wide) ...[
                Tag(
                  '+${entry.pipsEarned}',
                  icon: Icons.paid_rounded,
                  color: BrickColors.sun.withValues(alpha: 0.18),
                  onColor: Theme.of(context).brightness == Brightness.dark
                      ? BrickColors.sun
                      : const Color(0xFF8A6412),
                ),
                const SizedBox(width: Space.md),
              ],
              Text(
                formatNumber(entry.score),
                style: context.text.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
