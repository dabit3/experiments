import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/profile.dart';
import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import '../net/session.dart';
import 'hub_screen.dart';

/// Play tab laid out like a BR front-end: the equipped outfit stands centre
/// stage on an island vista, party slots sit bottom-left, the mode selector and
/// the big PLAY button sit bottom-right.
class PlayTab extends StatefulWidget {
  const PlayTab({super.key});

  @override
  State<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<PlayTab> {
  SquadMode mode = SquadMode.squads;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    return ListenableBuilder(
      listenable: Listenable.merge([
        session,
        session.connection,
        scope.profile,
      ]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 760;
          final room = session.room;
          final effectiveMode = room?.mode ?? mode;
          final pad = wide ? LfTokens.s6 : LfTokens.s4;
          final party = _PartyRow(
            room: room,
            mode: effectiveMode,
            compact: !wide,
            onAdd: room == null ? () => showJoinDialog(context) : null,
          );
          final actions = _ActionCluster(
            room: room,
            mode: effectiveMode,
            wide: wide,
            onPickMode:
                (room == null || session.isHost) && room?.phase != 'countdown'
                ? () => _pickMode(context, session, effectiveMode)
                : null,
          );
          final showcase = _Showcase(
            profile: scope.profile,
            wide: wide,
            height: wide
                ? math.min(box.maxHeight * 0.62, 460)
                : math.min(box.maxHeight * 0.42, 320),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              const IgnorePointer(child: _Vista()),
              if (session.notice != null && room == null)
                Positioned(
                  top: LfTokens.s3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: LobbyNotice(
                        text: session.notice!,
                        onDismiss: session.clearNotice,
                      ),
                    ),
                  ),
                ),
              if (wide) ...[
                Positioned(
                  left: pad,
                  right: pad,
                  top: 0,
                  bottom: 150,
                  child: Align(
                    alignment: const Alignment(-0.35, 0.2),
                    child: showcase,
                  ),
                ),
                Positioned(left: pad, bottom: pad, child: party),
                Positioned(right: pad, bottom: pad, child: actions),
              ] else
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, LfTokens.s2, pad, pad),
                  child: Column(
                    children: [
                      Expanded(child: Center(child: showcase)),
                      const SizedBox(height: LfTokens.s3),
                      SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: party,
                        ),
                      ),
                      const SizedBox(height: LfTokens.s3),
                      actions,
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickMode(
    BuildContext context,
    Session session,
    SquadMode current,
  ) async {
    final picked = await showModalBottomSheet<SquadMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LfTokens.s4),
          child: LfPanel(
            strong: true,
            blur: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LfEyebrow('BATTLE ROYALE · CHOOSE A MODE'),
                const SizedBox(height: LfTokens.s3),
                for (final m in SquadMode.values)
                  _ModeOption(
                    mode: m,
                    selected: m == current,
                    onTap: () => Navigator.pop(ctx, m),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    HapticFeedback.selectionClick();
    if (session.room != null) {
      session.setMode(picked);
    } else {
      setState(() => mode = picked);
    }
  }
}

/// Room-code entry as a dialog (the party "+" and the JOIN link open it).
Future<void> showJoinDialog(BuildContext context) async {
  final session = AppScope.read(context).session;
  final ctl = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Join with a code'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Codes work across web, iOS, Android and macOS.',
              style: ctx.text.bodySmall?.copyWith(color: ctx.lf.muted),
            ),
            const SizedBox(height: LfTokens.s3),
            TextField(
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              style: ctx.text.headlineSmall?.copyWith(
                letterSpacing: 6,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'ROOM CODE'),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder(
          valueListenable: ctl,
          builder: (context, v, _) => FilledButton(
            onPressed: v.text.trim().length >= 4
                ? () => Navigator.pop(ctx, v.text)
                : null,
            child: const Text('Join'),
          ),
        ),
      ],
    ),
  );
  final trimmed = code?.trim().toUpperCase() ?? '';
  if (trimmed.isNotEmpty) session.joinRoom(trimmed);
}

// ------------------------------------------------------------------ vista

/// Layered island silhouettes and a lit stage behind the outfit.
class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _VistaPainter(context.lf.isDark));
}

class _VistaPainter extends CustomPainter {
  _VistaPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.62;
    // Sun / moon glow on the horizon.
    canvas.drawCircle(
      Offset(w * 0.5, horizon),
      w * 0.36,
      Paint()
        ..shader = ui.Gradient.radial(Offset(w * 0.5, horizon), w * 0.36, [
          (dark ? LfTokens.storm : LfTokens.ember).withValues(
            alpha: dark ? 0.35 : 0.22,
          ),
          Colors.transparent,
        ]),
    );
    // Three ridge layers.
    final layers = dark
        ? [
            const Color(0xFF243052),
            const Color(0xFF1A2441),
            const Color(0xFF121A30),
          ]
        : [
            const Color(0xFFC9D6EA),
            const Color(0xFFB4C4DE),
            const Color(0xFF9DB0CF),
          ];
    for (var i = 0; i < 3; i++) {
      final base = horizon + i * h * 0.07;
      final amp = h * (0.06 - i * 0.012);
      final path = Path()..moveTo(0, h);
      path.lineTo(0, base);
      for (var x = 0.0; x <= w; x += 8) {
        final y =
            base -
            amp *
                (0.6 +
                    0.4 *
                        math.sin(x / w * (6 + i * 3) + i * 1.7) *
                        math.cos(x / w * (2.3 + i)));
        path.lineTo(x, y);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = layers[i]);
    }
    // Ground plane with a receding grid so the stage reads as a floor.
    final ground = Rect.fromLTWH(0, horizon + h * 0.14, w, h);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = ui.Gradient.linear(ground.topCenter, ground.bottomCenter, [
          dark ? const Color(0xFF0C1222) : const Color(0xFF8FA4C6),
          dark ? const Color(0xFF080C16) : const Color(0xFFDEE6F3),
        ]),
    );
    final grid = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final vanish = Offset(w * 0.5, horizon - h * 0.2);
    for (var i = -8; i <= 8; i++) {
      final x = w * 0.5 + i * w * 0.14;
      canvas.drawLine(Offset(x, h), vanish, grid);
    }
    var y = ground.top;
    var gap = 6.0;
    while (y < h) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
      y += gap;
      gap *= 1.28;
    }
  }

  @override
  bool shouldRepaint(covariant _VistaPainter old) => old.dark != dark;
}

// ------------------------------------------------------------------ showcase

class _Showcase extends StatelessWidget {
  const _Showcase({
    required this.profile,
    required this.wide,
    required this.height,
  });
  final Profile profile;
  final bool wide;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final outfit = profile.equipped(CosmeticSlot.outfit);
    final stats = profile.career;
    final avatar = (height * 0.66).clamp(120.0, 300.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Stage light.
            Container(
              width: avatar * 1.4,
              height: avatar * 0.32,
              margin: EdgeInsets.only(top: avatar * 0.85),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(outfit.accent).withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1),
              duration: LfTokens.slow,
              curve: LfTokens.spring,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: OutfitAvatar(outfit, size: avatar),
            ),
          ],
        ),
        const SizedBox(height: LfTokens.s2),
        Container(
          padding: const EdgeInsets.fromLTRB(
            LfTokens.s4,
            LfTokens.s1,
            LfTokens.s4,
            LfTokens.s3,
          ),
          decoration: BoxDecoration(
            color: c.glassStrong,
            borderRadius: BorderRadius.circular(LfTokens.rSm),
            border: Border.all(color: c.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.name.toUpperCase(),
                    style:
                        (wide
                                ? context.text.headlineMedium
                                : context.text.headlineSmall)
                            ?.copyWith(letterSpacing: 1),
                  ),
                  IconButton(
                    tooltip: 'Change name',
                    onPressed: () => _editName(context, profile),
                    icon: Icon(Icons.edit_rounded, size: 16, color: c.muted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                outfit.name.toUpperCase(),
                style: context.text.labelSmall?.copyWith(
                  color: outfit.rarity == Rarity.common
                      ? c.muted
                      : LfTokens.rarity(outfit.rarity),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: LfTokens.s2),
              Wrap(
                spacing: LfTokens.s4,
                children: [
                  _MiniStat('Wins', '${stats.wins}', LfTokens.warning),
                  _MiniStat('Matches', '${stats.matches}', c.text),
                  _MiniStat('Elims', '${stats.kills}', LfTokens.ember),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context, Profile profile) async {
    final ctl = TextEditingController(text: profile.name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Display name'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 16,
          decoration: const InputDecoration(hintText: 'Your name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (v != null && v.trim().isNotEmpty) await profile.setName(v.trim());
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(value, style: context.text.titleLarge?.copyWith(color: color)),
      const SizedBox(width: 4),
      Text(
        label.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: context.lf.muted,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

// ------------------------------------------------------------------ party

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.room,
    required this.mode,
    required this.compact,
    this.onAdd,
  });
  final RoomState? room;
  final SquadMode mode;
  final bool compact;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final members = room?.members ?? const <RoomMember>[];
    final slots = math.max(mode.size, members.length);
    final cards = <Widget>[];
    if (room == null) {
      cards.add(
        _PartyCard.self(
          name: scope.profile.name,
          outfit: scope.profile.equipped(CosmeticSlot.outfit),
          platform: scope.config.platformName,
          compact: compact,
        ),
      );
    } else {
      for (final m in members) {
        cards.add(
          _PartyCard.member(m, me: m.id == session.myId, compact: compact),
        );
      }
    }
    while (cards.length < slots) {
      cards.add(
        _PartyCard.empty(onTap: onAdd, bot: room != null, compact: compact),
      );
    }
    return Semantics(
      label: room == null
          ? 'Party: you, ${slots - 1} open'
          : 'Party: ${members.length} of $slots',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(width: LfTokens.s2),
          ],
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard._({
    this.name,
    this.outfit,
    this.platform,
    this.me = false,
    this.host = false,
    this.ready = false,
    this.bot = false,
    this.inRoom = true,
    this.compact = false,
    this.onTap,
  });

  factory _PartyCard.self({
    required String name,
    required Cosmetic outfit,
    required String platform,
    required bool compact,
  }) => _PartyCard._(
    name: name,
    outfit: outfit,
    platform: platform,
    me: true,
    inRoom: false,
    compact: compact,
  );

  factory _PartyCard.member(
    RoomMember m, {
    required bool me,
    required bool compact,
  }) => _PartyCard._(
    name: m.name,
    outfit: cosmeticById(m.loadout.outfit),
    platform: m.platform,
    me: me,
    host: m.host,
    ready: m.ready,
    compact: compact,
  );

  factory _PartyCard.empty({
    VoidCallback? onTap,
    required bool bot,
    required bool compact,
  }) => _PartyCard._(onTap: onTap, bot: bot, compact: compact);

  final String? name;
  final Cosmetic? outfit;
  final String? platform;
  final bool me;
  final bool host;
  final bool ready;
  final bool bot;
  final bool inRoom;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final empty = outfit == null;
    final border = me
        ? LfTokens.ember
        : (empty ? c.line : c.line.withValues(alpha: 0.9));
    final status = !inRoom
        ? 'YOU'
        : host
        ? 'HOST'
        : ready
        ? 'READY'
        : 'NOT READY';
    final statusColor = !inRoom
        ? LfTokens.ember
        : host
        ? LfTokens.warning
        : ready
        ? LfTokens.health
        : c.muted;
    final body = Container(
      width: compact ? 80 : 96,
      height: compact ? 104 : 116,
      decoration: BoxDecoration(
        color: empty ? c.glass.withValues(alpha: 0.35) : c.glassStrong,
        borderRadius: BorderRadius.circular(LfTokens.rSm),
        border: Border.all(color: border, width: me ? 2 : 1),
        boxShadow: empty
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: c.isDark ? 0.4 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: empty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  onTap != null ? Icons.add_rounded : Icons.smart_toy_outlined,
                  size: 28,
                  color: c.muted,
                ),
                const SizedBox(height: 6),
                Text(
                  onTap != null ? 'JOIN CODE' : (bot ? 'BOT FILLS' : 'OPEN'),
                  style: context.text.labelSmall?.copyWith(color: c.muted),
                ),
              ],
            )
          : Column(
              children: [
                const SizedBox(height: 8),
                OutfitAvatar(outfit!, size: compact ? 48 : 56),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    name!.toUpperCase(),
                    style: context.text.labelMedium?.copyWith(
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: statusColor == c.muted ? 0.25 : 0.18,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(LfTokens.rSm - 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PlatformBadge.describe(platform!).$2,
                        size: 11,
                        color: PlatformBadge.describe(platform!).$3,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: context.text.labelSmall?.copyWith(
                          fontSize: 9,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
    final label = empty
        ? (onTap != null ? 'Join with a code' : 'Open slot, bot fills on start')
        : '$name${me ? ' (you)' : ''}, ${status.toLowerCase()}';
    return Semantics(
      label: label,
      button: onTap != null,
      child: onTap == null
          ? body
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onTap, child: body),
            ),
    );
  }
}

// ------------------------------------------------------------------ actions

class _ActionCluster extends StatelessWidget {
  const _ActionCluster({
    required this.room,
    required this.mode,
    required this.wide,
    required this.onPickMode,
  });
  final RoomState? room;
  final SquadMode mode;
  final bool wide;
  final VoidCallback? onPickMode;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    final c = context.lf;
    final connected = session.connection.isConnected;
    final r = room;
    final counting = r?.phase == 'countdown';
    final isHost = session.isHost;
    final ready = session.isReady;

    final String label;
    final IconData icon;
    final VoidCallback? onPressed;
    final Color bg;
    if (r == null) {
      label = 'PLAY';
      icon = Icons.play_arrow_rounded;
      bg = LfTokens.warning;
      onPressed = connected ? () => session.createRoom(mode: mode) : null;
    } else if (counting) {
      label = 'STARTING';
      icon = Icons.hourglass_top_rounded;
      bg = LfTokens.warning;
      onPressed = null;
    } else if (isHost) {
      label = 'START';
      icon = Icons.rocket_launch_rounded;
      bg = LfTokens.warning;
      onPressed = () => session.startMatch(fill: r.maxPlayers);
    } else {
      label = ready ? 'READY' : 'READY UP';
      icon = ready
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded;
      bg = ready ? LfTokens.health : LfTokens.warning;
      onPressed = () => session.setReady(!ready);
    }

    final width = wide ? 300.0 : double.infinity;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeCard(mode: mode, room: r, onTap: onPickMode),
          const SizedBox(height: LfTokens.s2),
          _PlayButton(
            label: label,
            icon: icon,
            color: bg,
            onPressed: onPressed,
            progress: counting,
          ),
          const SizedBox(height: LfTokens.s2),
          if (r == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LinkButton(
                  label: 'JOIN WITH A CODE',
                  icon: Icons.login_rounded,
                  onPressed: connected ? () => showJoinDialog(context) : null,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Room code ${r.code}',
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: c.glassStrong,
                        borderRadius: BorderRadius.circular(LfTokens.rSm),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'CODE',
                            style: context.text.labelSmall?.copyWith(
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              r.code,
                              style: context.text.titleMedium?.copyWith(
                                letterSpacing: 4,
                                color: LfTokens.ember,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: r.code));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Room code copied'),
                                  behavior: SnackBarBehavior.floating,
                                  width: 240,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.copy_rounded,
                              color: c.muted,
                              size: 16,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: LfTokens.s2),
                _LinkButton(
                  label: 'LEAVE',
                  icon: Icons.logout_rounded,
                  onPressed: session.leaveRoom,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.room, this.onTap});
  final SquadMode mode;
  final RoomState? room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final r = room;
    final humans = r?.members.length ?? 1;
    final max = r?.maxPlayers ?? 16;
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: c.glassStrong,
        borderRadius: BorderRadius.circular(LfTokens.rSm),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LfTokens.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(LfTokens.rSm),
            ),
            child: Icon(switch (mode) {
              SquadMode.solo => Icons.person_rounded,
              SquadMode.duos => Icons.people_rounded,
              SquadMode.squads => Icons.groups_rounded,
            }, color: LfTokens.teal),
          ),
          const SizedBox(width: LfTokens.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const LfEyebrow('BATTLE ROYALE'),
                Text(
                  mode.label.toUpperCase(),
                  style: context.text.titleLarge?.copyWith(letterSpacing: 1),
                ),
                Text(
                  r == null
                      ? '${mode.size}-player teams · $max in a match'
                      : '$humans / $max players${r.fast ? ' · fast rules' : ''} · bots fill the rest',
                  style: context.text.bodySmall?.copyWith(color: c.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.unfold_more_rounded, color: c.muted, size: 20),
        ],
      ),
    );
    return Semantics(
      label: 'Mode: ${mode.label}',
      button: onTap != null,
      child: onTap == null
          ? card
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onTap, child: card),
            ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final SquadMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    return Padding(
      padding: const EdgeInsets.only(bottom: LfTokens.s2),
      child: Semantics(
        button: true,
        selected: selected,
        label: mode.label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(LfTokens.s3),
            decoration: BoxDecoration(
              color: selected
                  ? LfTokens.teal.withValues(alpha: 0.14)
                  : c.surface2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(LfTokens.rSm),
              border: Border.all(
                color: selected ? LfTokens.teal : c.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(switch (mode) {
                  SquadMode.solo => Icons.person_rounded,
                  SquadMode.duos => Icons.people_rounded,
                  SquadMode.squads => Icons.groups_rounded,
                }, color: selected ? LfTokens.teal : c.muted),
                const SizedBox(width: LfTokens.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label.toUpperCase(),
                        style: context.text.titleMedium,
                      ),
                      Text(
                        '${mode.size}-player teams. Empty slots fill with bots.',
                        style: context.text.bodySmall?.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: LfTokens.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The big high-contrast primary action with a leaned front edge.
class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.progress,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool progress;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fg = const Color(0xFF1A1400);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: enabled
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _down ? 0.98 : (_hover && enabled ? 1.02 : 1),
            duration: LfTokens.fast,
            child: AnimatedOpacity(
              duration: LfTokens.fast,
              opacity: enabled || widget.progress ? 1 : 0.5,
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LfTokens.rSm),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(widget.color, Colors.white, 0.18)!,
                      widget.color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: _hover && enabled ? 0.55 : 0.32,
                      ),
                      blurRadius: _hover ? 26 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 30, color: fg),
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: context.text.displaySmall?.copyWith(
                              fontSize: 32,
                              color: fg,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.progress)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          color: Color(0xFF1A1400),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => LfButton(
    label: label,
    icon: icon,
    variant: LfButtonVariant.ghost,
    size: LfButtonSize.sm,
    onPressed: onPressed,
  );
}
