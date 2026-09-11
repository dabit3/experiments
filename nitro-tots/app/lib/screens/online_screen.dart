import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitro_core/nitro_core.dart';

import '../net/client.dart';
import '../state/app_state.dart';
import '../state/audio.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';

/// Connect to a server, then create or join a room.
class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key, required this.app, required this.client, required this.feedback, required this.onBack});
  final AppState app;
  final NetClient client;
  final NtFeedback feedback;
  final VoidCallback onBack;

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  late final TextEditingController _code = TextEditingController(text: widget.app.lastRoomCode);
  late final TextEditingController _server = TextEditingController(text: widget.app.serverUrl);
  String? _localError;
  bool _editServer = false;

  @override
  void initState() {
    super.initState();
    if (widget.client.state == ConnState.offline) _connect();
    widget.client.errors.listen((e) {
      if (!mounted) return;
      setState(() => _localError = _describe(e['code'] as String?, e['message'] as String?));
    });
  }

  String _describe(String? code, String? fallback) => switch (code) {
    'no_such_room' => 'No room with that code. Check the four letters and try again.',
    'room_full' => 'That room is full (8 racers max).',
    'match_in_progress' => 'That room is mid-race. Try again after the results.',
    'not_host' => 'Only the host can do that.',
    _ => fallback ?? 'Something went wrong.',
  };

  Future<void> _connect() async {
    setState(() => _localError = null);
    final app = widget.app;
    await widget.client.connect(
      app.serverUrl,
      name: app.name,
      character: app.characterId,
      kart: app.kartId,
      resumeId: app.resumePlayerId,
      resumeToken: app.resumeToken,
    );
  }

  @override
  void dispose() {
    _code.dispose();
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final client = widget.client;
    return AnimatedBuilder(
      animation: client,
      builder: (context, _) {
        final connected = client.state == ConnState.online;
        return NtScreen(
          title: 'Play online',
          subtitle: 'Race friends on any platform. Rooms hold up to 8; bots fill the rest.',
          onBack: () {
            widget.feedback.tap();
            widget.onBack();
          },
          maxWidth: 760,
          trailing: _ConnPill(client: client, showLatency: !widget.app.testConfig.still),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (client.state == ConnState.failed)
                StatePanel(
                  icon: Icons.cloud_off_rounded,
                  title: 'Can’t reach the server',
                  message: '${client.lastError ?? ''}\n${widget.app.serverUrl}',
                  color: NtColors.bubblegum,
                  action: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NtButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: _connect),
                      const SizedBox(height: NtSpace.x2),
                      NtButton(label: 'Change server', kind: NtButtonKind.ghost, onPressed: () => setState(() => _editServer = true)),
                    ],
                  ),
                )
              else if (!connected)
                StatePanel(loading: true, title: client.state == ConnState.reconnecting ? 'Reconnecting…' : 'Connecting…', message: widget.app.serverUrl)
              else ...[
                if (client.room != null && client.room!.status != 'lobby' && client.room!.status != 'matchOver')
                  NtCard(
                    accent: NtColors.nitro,
                    child: Row(
                      children: [
                        const Icon(Icons.replay_rounded, color: NtColors.nitro),
                        const SizedBox(width: NtSpace.x3),
                        Expanded(child: Text('You have a race in progress in room ${client.room!.code}.', style: NtType.body(nt.ink))),
                      ],
                    ),
                  ),
                _JoinCard(
                  controller: _code,
                  error: _localError,
                  autofocus: !widget.app.isMobile && !widget.app.testConfig.active,
                  onJoin: (code) {
                    widget.feedback.tap();
                    setState(() => _localError = null);
                    widget.app.update((s) => s.lastRoomCode = code);
                    client.joinRoom(code);
                  },
                ),
                const SizedBox(height: NtSpace.x4),
                _CreateCard(
                  onCreate: (settings) {
                    widget.feedback.tap();
                    client.createRoom(settings);
                  },
                ),
              ],
              const SizedBox(height: NtSpace.x6),
              _ServerRow(
                app: widget.app,
                editing: _editServer,
                controller: _server,
                onToggle: () => setState(() => _editServer = !_editServer),
                onSave: (url) async {
                  widget.app.update((s) => s.serverUrl = url);
                  setState(() => _editServer = false);
                  await client.disconnect();
                  await _connect();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConnPill extends StatelessWidget {
  const _ConnPill({required this.client, this.showLatency = true});
  final NetClient client;
  final bool showLatency;
  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (client.state) {
      ConnState.online => (showLatency ? 'Online · ${client.rttMs} ms' : 'Online', NtColors.lime, Icons.wifi_rounded),
      ConnState.connecting => ('Connecting', NtColors.sunny, Icons.wifi_find_rounded),
      ConnState.reconnecting => ('Reconnecting', NtColors.sunny, Icons.wifi_find_rounded),
      ConnState.failed => ('Offline', NtColors.bubblegum, Icons.wifi_off_rounded),
      ConnState.offline => ('Offline', NtColors.inkSoft, Icons.wifi_off_rounded),
    };
    return Semantics(
      liveRegion: true,
      label: 'Connection: $label',
      child: NtChip(label, color: color, icon: icon),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.controller, required this.onJoin, this.error, this.autofocus = true});
  final TextEditingController controller;
  final void Function(String code) onJoin;
  final String? error;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return NtCard(
      accent: NtColors.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Join a room'),
          const SizedBox(height: NtSpace.x2),
          Text('Ask the host for their four-letter code.', style: NtType.body(nt.inkSoft)),
          const SizedBox(height: NtSpace.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  maxLength: 4,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')), _Upper()],
                  style: NtType.h1(nt.ink).copyWith(letterSpacing: 8),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: 'ABCD', counterText: '', errorText: error, hintStyle: NtType.h1(nt.outline).copyWith(letterSpacing: 8)),
                  onSubmitted: (v) => v.length == 4 ? onJoin(v) : null,
                ),
              ),
              const SizedBox(width: NtSpace.x3),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (_, v, _) =>
                      NtButton(label: 'Join', icon: Icons.login_rounded, color: NtColors.sky, onPressed: v.text.length == 4 ? () => onJoin(v.text) : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Upper extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) => n.copyWith(text: n.text.toUpperCase());
}

class _CreateCard extends StatefulWidget {
  const _CreateCard({required this.onCreate});
  final void Function(RoomSettings settings) onCreate;
  @override
  State<_CreateCard> createState() => _CreateCardState();
}

class _CreateCardState extends State<_CreateCard> {
  bool _gp = true;
  String _cup = cups.first.id;
  String _track = raceTrackDefs.first.id;
  GameMode _mode = GameMode.race;
  int _laps = 3;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return NtCard(
      accent: NtColors.nitro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Host a room'),
          const SizedBox(height: NtSpace.x3),
          SegmentedButton<(GameMode, bool)>(
            segments: const [
              ButtonSegment(value: (GameMode.race, true), label: Text('Grand Prix'), icon: Icon(Icons.emoji_events_rounded)),
              ButtonSegment(value: (GameMode.race, false), label: Text('Single race'), icon: Icon(Icons.flag_rounded)),
              ButtonSegment(value: (GameMode.battle, false), label: Text('Battle'), icon: Icon(Icons.sports_kabaddi_rounded)),
            ],
            selected: {(_mode, _gp)},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() {
              _mode = s.first.$1;
              _gp = s.first.$2;
            }),
          ),
          const SizedBox(height: NtSpace.x3),
          Wrap(
            spacing: NtSpace.x2,
            runSpacing: NtSpace.x2,
            children: [
              if (_mode == GameMode.race && _gp)
                for (final c in cups) ChoiceChip(label: Text(c.name), selected: _cup == c.id, onSelected: (_) => setState(() => _cup = c.id)),
              if (_mode == GameMode.race && !_gp)
                for (final t in raceTrackDefs) ChoiceChip(label: Text(t.name), selected: _track == t.id, onSelected: (_) => setState(() => _track = t.id)),
              if (_mode == GameMode.battle)
                for (final t in arenaDefs) ChoiceChip(label: Text(t.name), selected: true, onSelected: (_) {}),
            ],
          ),
          if (_mode == GameMode.race) ...[
            const SizedBox(height: NtSpace.x3),
            Row(
              children: [
                Text('Laps', style: NtType.label(nt.inkSoft)),
                const SizedBox(width: NtSpace.x3),
                for (final l in [1, 2, 3, 5])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(label: Text('$l'), selected: _laps == l, onSelected: (_) => setState(() => _laps = l)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: NtSpace.x4),
          Row(
            children: [
              Expanded(child: Text('Empty seats are filled with bots when the race starts.', style: NtType.small(nt.inkSoft))),
              NtButton(
                label: 'Create room',
                icon: Icons.add_rounded,
                onPressed: () => widget.onCreate(
                  RoomSettings(
                    mode: _mode,
                    grandPrix: _mode == GameMode.race && _gp,
                    cupId: _cup,
                    trackId: _mode == GameMode.battle ? arenaDefs.first.id : _track,
                    laps: _laps,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.app, required this.editing, required this.controller, required this.onToggle, required this.onSave});
  final AppState app;
  final bool editing;
  final TextEditingController controller;
  final VoidCallback onToggle;
  final void Function(String url) onSave;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    if (!editing) {
      return Row(
        children: [
          Icon(Icons.dns_rounded, size: 16, color: nt.inkSoft),
          const SizedBox(width: 6),
          Expanded(
            child: Text(app.serverUrl, style: NtType.small(nt.inkSoft), overflow: TextOverflow.ellipsis),
          ),
          NtButton(label: 'Change', kind: NtButtonKind.ghost, compact: true, onPressed: onToggle),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Server URL', hintText: 'ws://host:8787/ws'),
            keyboardType: TextInputType.url,
            onSubmitted: onSave,
          ),
        ),
        const SizedBox(width: NtSpace.x2),
        NtButton(label: 'Save', compact: true, onPressed: () => onSave(controller.text.trim())),
        NtButton(label: 'Cancel', compact: true, kind: NtButtonKind.ghost, onPressed: onToggle),
      ],
    );
  }
}
