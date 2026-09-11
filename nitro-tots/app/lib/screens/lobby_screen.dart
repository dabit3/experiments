import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitro_core/nitro_core.dart';

import '../game/track_art.dart';
import '../net/client.dart';
import '../state/app_state.dart';
import '../state/audio.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';

/// Room lobby: join code, player seats, ready state and host controls.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.app, required this.client, required this.feedback, required this.onLeave, required this.onGarage});
  final AppState app;
  final NetClient client;
  final NtFeedback feedback;
  final VoidCallback onLeave;
  final VoidCallback onGarage;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _copied = false;
  int _lastCount = 0;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final client = widget.client;
    return AnimatedBuilder(
      animation: client,
      builder: (context, _) {
        final room = client.room;
        if (room == null) {
          return NtScreen(
            title: 'Lobby',
            onBack: widget.onLeave,
            child: const StatePanel(loading: true, title: 'Joining room…'),
          );
        }
        if (room.players.length > _lastCount && _lastCount > 0) {
          widget.feedback.sfx('select', volume: 0.6);
        }
        _lastCount = room.players.length;

        final me = room.players.where((p) => p.id == client.playerId).firstOrNull;
        final ready = me?.ready ?? false;
        final humans = room.players.length;
        final allReady = room.players.every((p) => p.ready);
        final isHost = client.isHost;
        final settings = room.settings;
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final trackIds = settings.grandPrix && settings.mode == GameMode.race ? cupById(settings.cupId).trackIds : [settings.trackId];

        final seats = _Seats(room: room, myId: client.playerId, maxPlayers: settings.maxPlayers);
        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CodeCard(
              code: room.code,
              copied: _copied,
              onCopy: () async {
                await Clipboard.setData(ClipboardData(text: room.code));
                widget.feedback.tap();
                setState(() => _copied = true);
                Future.delayed(const Duration(seconds: 2), () => mounted ? setState(() => _copied = false) : null);
              },
            ),
            const SizedBox(height: NtSpace.x4),
            NtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Match',
                    trailing: NtChip(
                      settings.mode == GameMode.battle ? 'Battle' : (settings.grandPrix ? 'Grand Prix' : 'Single race'),
                      color: settings.mode == GameMode.battle ? NtColors.grape : NtColors.nitro,
                    ),
                  ),
                  for (final (i, tid) in trackIds.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: Color(trackDefById(tid).theme.ground), borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: CustomPaint(painter: TrackThumbPainter(trackById(tid))),
                              ),
                            ),
                          ),
                          const SizedBox(width: NtSpace.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${trackIds.length > 1 ? '${i + 1}. ' : ''}${trackDefById(tid).name}', style: NtType.label(nt.ink)),
                                Text(
                                  settings.mode == GameMode.battle
                                      ? '${settings.battleSeconds ~/ 60} min · balloons'
                                      : '${settings.laps} lap${settings.laps == 1 ? '' : 's'}',
                                  style: NtType.caption(nt.inkSoft),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isHost && settings.mode == GameMode.race) ...[
                    const Divider(),
                    Row(
                      children: [
                        Text('Laps', style: NtType.label(nt.inkSoft)),
                        const SizedBox(width: NtSpace.x2),
                        for (final l in [1, 2, 3, 5])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(label: Text('$l'), selected: settings.laps == l, onSelected: (_) => client.updateSettings({'laps': l})),
                          ),
                      ],
                    ),
                  ],
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded, size: 16, color: nt.inkSoft),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          settings.fillBots
                              ? '${settings.maxPlayers - humans} bot seat${settings.maxPlayers - humans == 1 ? '' : 's'} will fill in'
                              : 'No bots',
                          style: NtType.small(nt.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        return NtScreen(
          title: 'Room ${room.code}',
          subtitle: '$humans of ${settings.maxPlayers} seats taken · ${room.players.where((p) => p.ready).length} ready',
          onBack: () {
            widget.feedback.tap();
            widget.onLeave();
          },
          trailing: NtChip('${client.rttMs} ms', icon: Icons.wifi_rounded, color: client.rttMs < 120 ? NtColors.lime : NtColors.sunny),
          footer: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: NtSpace.x3,
            runSpacing: NtSpace.x2,
            children: [
              NtButton(label: 'Garage', icon: Icons.garage_rounded, kind: NtButtonKind.ghost, onPressed: widget.onGarage),
              Wrap(
                spacing: NtSpace.x3,
                runSpacing: NtSpace.x2,
                children: [
                  NtButton(
                    label: ready ? 'Ready!' : 'Ready up',
                    icon: ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    kind: ready ? NtButtonKind.secondary : NtButtonKind.primary,
                    color: ready ? NtColors.lime : null,
                    onPressed: () {
                      widget.feedback.tap();
                      widget.feedback.haptic(HapticsKind.select);
                      client.setReady(!ready);
                    },
                  ),
                  if (isHost)
                    Tooltip(
                      message: humans < 2 ? 'Start now — bots fill the empty seats' : (allReady ? 'Everyone is ready' : 'Waiting for players to ready up'),
                      child: NtButton(
                        label: 'Start race',
                        icon: Icons.play_arrow_rounded,
                        color: NtColors.nitro,
                        onPressed: () {
                          widget.feedback.tap();
                          client.startMatch();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: seats),
                    const SizedBox(width: NtSpace.x6),
                    SizedBox(width: 340, child: side),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    side,
                    const SizedBox(height: NtSpace.x4),
                    seats,
                  ],
                ),
        );
      },
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.copied, required this.onCopy});
  final String code;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return NtCard(
      accent: NtColors.sky,
      onTap: onCopy,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOIN CODE', style: NtType.caption(nt.inkSoft)),
                Semantics(
                  label: 'Join code ${code.split('').join(' ')}',
                  child: Text(code, style: NtType.hero(nt.ink).copyWith(fontSize: 48, letterSpacing: 10)),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: NtMotion.fast,
            child: copied
                ? const NtChip('Copied', key: ValueKey('c'), icon: Icons.check_rounded, color: NtColors.lime)
                : NtChip('Copy', key: const ValueKey('n'), icon: Icons.copy_rounded, color: nt.bgAlt, textColor: nt.ink),
          ),
        ],
      ),
    );
  }
}

class _Seats extends StatelessWidget {
  const _Seats({required this.room, required this.myId, required this.maxPlayers});
  final RoomView room;
  final String? myId;
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / 260).floor().clamp(1, 4);
        final w = (c.maxWidth - (cols - 1) * NtSpace.x3) / cols;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Racers'),
            const SizedBox(height: NtSpace.x3),
            Wrap(
              spacing: NtSpace.x3,
              runSpacing: NtSpace.x3,
              children: [
                for (var i = 0; i < maxPlayers; i++)
                  SizedBox(
                    width: w,
                    child: i < room.players.length ? _SeatCard(p: room.players[i], me: room.players[i].id == myId) : _EmptySeat(nt: nt),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({required this.p, required this.me});
  final PlayerInfo p;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final color = NtColors.platform(p.platform);
    return Semantics(
      label:
          '${p.name}, ${PlatformBadge.labelFor(p.platform)}, ${p.ready ? 'ready' : 'not ready'}${p.isHost ? ', host' : ''}${p.connected ? '' : ', disconnected'}',
      child: AnimatedContainer(
        duration: NtMotion.normal,
        child: NtCard(
          accent: p.ready ? NtColors.lime : color,
          selected: me,
          padding: const EdgeInsets.all(NtSpace.x3),
          child: Opacity(
            opacity: p.connected ? 1 : 0.5,
            child: Row(
              children: [
                Stack(
                  children: [
                    Avatar(characterId: p.characterId, size: 48, ring: color),
                    if (p.ready)
                      const Positioned(
                        right: -2,
                        bottom: -2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Icon(Icons.check_circle_rounded, color: NtColors.lime, size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: NtSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(p.name, style: NtType.h3(nt.ink), overflow: TextOverflow.ellipsis),
                          ),
                          if (me)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text('(you)', style: NtType.caption(nt.inkSoft)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          PlatformBadge(p.platform, compact: true),
                          if (p.isHost) const NtChip('Host', color: NtColors.sunny, textColor: NtColors.inkDark, icon: Icons.star_rounded),
                          if (!p.connected) const NtChip('Away', color: NtColors.inkSoft, icon: Icons.wifi_off_rounded),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${characterById(p.characterId).name} · ${kartById(p.kartId).name}',
                        style: NtType.caption(nt.inkSoft),
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
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat({required this.nt});
  final NtScheme nt;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NtRadius.lg),
        border: Border.all(color: nt.outline, width: 2, strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, color: nt.outline),
          const SizedBox(width: 8),
          Text('Open seat · bot', style: NtType.small(nt.outline)),
        ],
      ),
    );
  }
}
