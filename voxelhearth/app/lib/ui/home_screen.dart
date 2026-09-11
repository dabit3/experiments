import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'arcade.dart';
import 'pixel.dart';
import 'settings_sheet.dart';

enum _Page { title, play, create, name }

/// Title screen and its sub-screens (world list, create world, player name).
/// Sub-screens are local pages, not routes, so the shell can swap to the
/// lobby the moment the server puts us in a room.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client, required this.settings, required this.config, this.assets});
  final GameClient client;
  final Settings settings;
  final LaunchConfig config;
  final RenderAssets? assets;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.client.playerName);
  late final TextEditingController _server = TextEditingController(text: widget.client.serverUrl);
  final TextEditingController _code = TextEditingController();
  _Page _page = _Page.title;
  int? _selectedRoom;
  String? _notice;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_refresh);
    if (widget.client.state == ConnState.idle) widget.client.connect();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.client.removeListener(_refresh);
    _name.dispose();
    _server.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Applies the name/server fields; when either changed, the socket is
  /// re-opened with the new identity before any room action is sent.
  Future<void> _commitIdentity() async {
    final c = widget.client;
    final name = _name.text.trim().isEmpty ? 'Wanderer' : _name.text.trim();
    final server = _server.text.trim();
    widget.settings.playerName = name;
    widget.settings.serverUrl = server;
    final changed = c.playerName != name || c.serverUrl != server;
    if (c.serverUrl != server) c.token = widget.settings.tokenFor(server);
    c.playerName = name;
    c.serverUrl = server;
    if (changed || c.state == ConnState.failed) await c.connect();
  }

  void _go(_Page p) => setState(() {
    _page = p;
    _notice = null;
  });

  Future<void> _joinCode() async {
    await _commitIdentity();
    if (!mounted) return;
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _notice = 'Enter a 5-letter room code');
      return;
    }
    widget.client.joinRoom(code);
  }

  Future<void> _joinSelected() async {
    final i = _selectedRoom;
    final c = widget.client;
    if (i == null || i >= c.rooms.length) return;
    await _commitIdentity();
    if (!mounted) return;
    c.joinRoom(c.rooms[i].code);
  }

  @override
  Widget build(BuildContext context) {
    const bg = HearthBackdrop();
    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (_page) {
        _Page.title => _title(context, bg),
        _Page.play => _play(context),
        _Page.create => _CreateScreen(
          client: widget.client,
          dirt: widget.assets?.dirt,
          onBack: () => _go(_Page.title),
          beforeCreate: _commitIdentity,
        ),
        _Page.name => _namePage(context),
      },
    );
  }

  // ---------------------------------------------------------------- title

  Widget _title(BuildContext context, Widget bg) => Stack(
    fit: StackFit.expand,
    children: [
      bg,
      SafeArea(
        // Lay the menu out against the safe-area box, not the full screen, so
        // notch/home-indicator insets do not push the footer into the buttons.
        child: LayoutBuilder(builder: (context, bc) => _titleMenu(context, bc.biggest)),
      ),
    ],
  );

  Widget _titleMenu(BuildContext context, Size box) {
    final s = Gui.of(context);
    final c = widget.client;
    final compact = box.height < 560;
    final narrow = box.width < 600;
    final margin = compact ? 22.0 : (box.width * 0.045).clamp(24.0, 72.0);
    final menuWidth = math.min(box.width - margin * 2, compact ? 350.0 : 490.0);
    final buttonW = menuWidth / s;
    final titleSize = compact ? 49.0 : (box.width * 0.07).clamp(52.0, 100.0);
    final status = switch (c.state) {
      ConnState.connected => 'ONLINE · ${c.pingMs} ms',
      ConnState.connecting || ConnState.idle => 'Connecting...',
      ConnState.reconnecting => 'Reconnecting (${c.reconnectAttempt})...',
      ConnState.failed => 'Server offline',
    };
    final statusColor = switch (c.state) {
      ConnState.connected => Px.green,
      ConnState.failed => Px.red,
      _ => Px.yellow,
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin, vertical: compact ? 12 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Hearth.gold, size: 28),
              const SizedBox(width: 8),
              Text('HEARTHBOUND ADVENTURES', style: arcadeType(compact ? 10 : 13).copyWith(letterSpacing: 2)),
              const Spacer(),
              if (!narrow) ArcadeBadge(status, icon: Icons.wifi_rounded, color: statusColor),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset((1 - value) * -24, 0), child: child),
                  ),
                  child: SizedBox(
                    width: menuWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact) ...[
                          Text(
                            'BIG WORLDS. BETTER TOGETHER.',
                            style: arcadeType(13, color: Hearth.teal).copyWith(letterSpacing: 3),
                          ),
                          const SizedBox(height: 18),
                        ],
                        Semantics(
                          label: 'Voxelhearth',
                          child: ExcludeSemantics(
                            child: Text(
                              'VOXEL\nHEARTH',
                              style: arcadeType(titleSize, weight: FontWeight.w900).copyWith(
                                height: 0.84,
                                letterSpacing: -titleSize * 0.04,
                                shadows: const [
                                  Shadow(color: Color(0xffb88543), offset: Offset(0, 3)),
                                  Shadow(color: Hearth.ink, offset: Offset(0, 8), blurRadius: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 24),
                        Text(
                          compact
                              ? 'Gather. Build. Make it yours.'
                              : 'A spark. A block. An entire world of possibility.\nBring your friends. Leave your mark.',
                          style: arcadeType(
                            compact ? 14 : 19,
                            color: Hearth.muted,
                            weight: FontWeight.w400,
                          ).copyWith(height: 1.4),
                        ),
                        SizedBox(height: compact ? 12 : 28),
                        PxButton(
                          'Play Online',
                          primary: true,
                          width: buttonW,
                          height: compact ? 23 : 25,
                          onPressed: () => _go(_Page.play),
                        ),
                        SizedBox(height: compact ? 6 : 10),
                        Row(
                          children: [
                            PxButton('Create World', width: (buttonW - 4) / 2, onPressed: () => _go(_Page.create)),
                            SizedBox(width: 4.0 * s),
                            PxButton(
                              'Player Name: ${c.playerName}',
                              width: (buttonW - 4) / 2,
                              onPressed: () => _go(_Page.name),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 6 : 10),
                        Row(
                          children: [
                            PxButton(
                              'Options...',
                              width: (buttonW - 4) / 2,
                              onPressed: () => showOptionsScreen(
                                context,
                                widget.settings,
                                background: DirtBackground(dirt: widget.assets?.dirt),
                              ),
                            ),
                            SizedBox(width: 4.0 * s),
                            PxButton('How to Play', width: (buttonW - 4) / 2, onPressed: () => _showHowToPlay(context)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '01 / EXPLORE · BUILD · BELONG',
                  style: arcadeType(compact ? 10 : 12, color: Hearth.muted).copyWith(letterSpacing: 1),
                ),
              ),
              Text(
                platformLabel(c.platform).toUpperCase(),
                style: arcadeType(11, color: Hearth.teal).copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showHowToPlay(BuildContext context) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, _, _) {
        final s = Gui.of(context);
        const tips = [
          ('Look', 'Move the mouse / drag on touch'),
          ('Move', 'WASD or arrows · joystick on touch'),
          ('Jump / Sneak', 'Space · Shift'),
          ('Break', 'Hold left click / tap'),
          ('Place', 'Right click / long-press'),
          ('Inventory', 'E · build a Workbench for more recipes'),
          ('Chat', 'T · Tab shows everyone in the room'),
          ('Night', 'Hollows and Cinderlings hunt after dusk'),
        ];
        return PxScreen(
          background: DirtBackground(dirt: widget.assets?.dirt),
          title: 'How to Play',
          footer: Padding(
            padding: EdgeInsets.only(bottom: 8.0 * s),
            child: PxButton('Done', sound: 'ui_back', onPressed: () => Navigator.of(context).pop()),
          ),
          child: Center(
            child: SizedBox(
              width: 260.0 * s,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final t in tips)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.0 * s),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80.0 * s,
                            child: PxText(t.$1, color: Px.yellow),
                          ),
                          Expanded(child: PxText(t.$2, color: Px.gray)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  // ---------------------------------------------------------------- play online

  Widget _play(BuildContext context) {
    final s = Gui.of(context);
    final gui = Gui.guiSize(context);
    final c = widget.client;
    final wide = gui.width >= 320;
    final sel = _selectedRoom != null && _selectedRoom! < c.rooms.length;
    return PxScreen(
      background: DirtBackground(dirt: widget.assets?.dirt),
      title: 'Play Online',
      titleY: 8,
      footer: Padding(
        padding: EdgeInsets.fromLTRB(0, 4.0 * s, 0, 6.0 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PxField(
                  controller: _code,
                  hint: 'Room code',
                  width: wide ? 100 : 96,
                  maxLength: 5,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')), UpperCaseTextFormatter()],
                  onSubmitted: (_) => _joinCode(),
                ),
                SizedBox(width: 4.0 * s),
                PxButton('Join Code', width: 100, onPressed: c.joiningRoom ? null : _joinCode),
                if (wide) ...[
                  SizedBox(width: 4.0 * s),
                  PxButton('Refresh', width: 100, onPressed: c.state == ConnState.connected ? c.refreshRooms : null),
                ],
              ],
            ),
            SizedBox(height: 4.0 * s),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PxButton('Join World', width: 100, onPressed: sel && !c.joiningRoom ? _joinSelected : null),
                SizedBox(width: 4.0 * s),
                PxButton('Create World', width: 100, onPressed: () => _go(_Page.create)),
                SizedBox(width: 4.0 * s),
                PxButton('Cancel', width: wide ? 100 : 96, sound: 'ui_back', onPressed: () => _go(_Page.title)),
              ],
            ),
            if (_notice != null) ...[SizedBox(height: 3.0 * s), PxText(_notice!, color: Px.red)],
          ],
        ),
      ),
      child: PxListBox(dirt: widget.assets?.dirt, child: _roomsBody(context)),
    );
  }

  Widget _roomsBody(BuildContext context) {
    final s = Gui.of(context);
    final c = widget.client;
    Widget centered(String title, String msg, {Widget? action}) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PxText(title, align: TextAlign.center),
          SizedBox(height: 2.0 * s),
          PxText(msg, color: Px.gray, align: TextAlign.center, maxLines: 3),
          if (action != null) ...[SizedBox(height: 8.0 * s), action],
        ],
      ),
    );
    switch (c.state) {
      case ConnState.idle:
      case ConnState.connecting:
        return centered('Connecting to the hearth...', 'Looking for the Voxelhearth server.');
      case ConnState.reconnecting:
        return centered(
          'Connection lost',
          'Reconnecting (attempt ${c.reconnectAttempt})...',
          action: PxButton('Retry Now', width: 100, onPressed: c.retryNow),
        );
      case ConnState.failed:
        return centered(
          'Server unreachable',
          c.lastError ?? 'Could not reach ${c.serverUrl}.',
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PxField(
                controller: _server,
                hint: 'ws://host:8787/ws',
                width: 200,
                onSubmitted: (_) => _commitIdentity(),
              ),
              SizedBox(height: 4.0 * s),
              PxButton('Try Again', width: 100, onPressed: _commitIdentity),
            ],
          ),
        );
      case ConnState.connected:
        if (c.rooms.isEmpty) {
          return centered('No worlds yet', 'Be the first to light a hearth.');
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 4.0 * s),
          itemCount: c.rooms.length,
          itemBuilder: (context, i) => Center(
            child: PxListEntry(
              width: math.min(Gui.guiSize(context).width - 20, 300),
              selected: _selectedRoom == i,
              onTap: () => setState(() {
                if (_selectedRoom == i) {
                  _joinSelected();
                } else {
                  _selectedRoom = i;
                }
              }),
              child: _RoomRow(room: c.rooms[i]),
            ),
          ),
        );
    }
  }

  // ---------------------------------------------------------------- name

  Widget _namePage(BuildContext context) {
    final s = Gui.of(context);
    return PxScreen(
      background: DirtBackground(dirt: widget.assets?.dirt),
      title: 'Player Name',
      titleY: 20,
      footer: Padding(
        padding: EdgeInsets.only(bottom: 8.0 * s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PxButton(
              'Done',
              width: 98,
              onPressed: () async {
                await _commitIdentity();
                _go(_Page.title);
              },
            ),
            SizedBox(width: 4.0 * s),
            PxButton('Cancel', width: 98, sound: 'ui_back', onPressed: () => _go(_Page.title)),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200.0 * s,
              child: const PxText('Name', color: Px.gray),
            ),
            SizedBox(height: 2.0 * s),
            PxField(
              controller: _name,
              hint: 'Wanderer',
              autofocus: true,
              maxLength: 16,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 _\-]'))],
              onSubmitted: (_) async {
                await _commitIdentity();
                _go(_Page.title);
              },
            ),
            SizedBox(height: 10.0 * s),
            SizedBox(
              width: 200.0 * s,
              child: const PxText('Server Address', color: Px.gray),
            ),
            SizedBox(height: 2.0 * s),
            PxField(controller: _server, hint: 'ws://host:8787/ws', onSubmitted: (_) => _commitIdentity()),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room});
  final RoomSummary room;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final phase = switch (room.phase) {
      Phase.playing => ('In match', Px.green),
      Phase.results => ('Results', Px.gold),
      _ => ('Lobby', Px.aqua),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32.0 * s,
          height: 32.0 * s,
          color: room.mode == GameMode.creative ? const Color(0xff5b8ad6) : const Color(0xff6a9b3a),
          alignment: Alignment.center,
          child: PxText(room.mode == GameMode.creative ? 'C' : 'S', size: 2),
        ),
        SizedBox(width: 3.0 * s),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PxText(room.name, maxLines: 1),
              PxText(
                '${room.code} · ${room.mode == GameMode.creative ? 'Creative' : 'Survival'} · ${room.players} ${room.players == 1 ? 'player' : 'players'}',
                color: Px.gray,
                maxLines: 1,
              ),
              PxText(phase.$1, color: phase.$2),
            ],
          ),
        ),
      ],
    );
  }
}

/// Create World screen: name, mode, seed, bots, creatures.
class _CreateScreen extends StatefulWidget {
  const _CreateScreen({required this.client, required this.dirt, required this.onBack, required this.beforeCreate});
  final GameClient client;
  final ui.Image? dirt;
  final VoidCallback onBack;
  final Future<void> Function() beforeCreate;

  @override
  State<_CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<_CreateScreen> {
  late final TextEditingController _name = TextEditingController(text: '${widget.client.playerName}\'s world');
  final TextEditingController _seed = TextEditingController();
  String _mode = GameMode.survival;
  bool _mobs = true;
  int _bots = 0;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _seed.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    await widget.beforeCreate();
    if (!mounted) return;
    final seedText = _seed.text.trim();
    widget.client.createRoom(
      name: _name.text.trim().isEmpty ? 'Untitled world' : _name.text.trim(),
      mode: _mode,
      seed: seedText.isEmpty ? null : int.tryParse(seedText),
      spawnMobs: _mobs,
      bots: _bots,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final gui = Gui.guiSize(context);
    final twoCol = gui.width >= 320;
    Widget label(String t) => SizedBox(
      width: (twoCol ? 304.0 : 200.0) * s,
      child: PxText(t, color: Px.gray),
    );
    final modeBtn = PxButton(
      'Game Mode: ${_mode == GameMode.creative ? 'Creative' : 'Survival'}',
      width: twoCol ? 150 : 200,
      onPressed: () => setState(() => _mode = _mode == GameMode.creative ? GameMode.survival : GameMode.creative),
    );
    final mobsBtn = PxButton(
      'Creatures: ${_mobs ? 'ON' : 'OFF'}',
      width: twoCol ? 150 : 200,
      onPressed: () => setState(() => _mobs = !_mobs),
    );
    final botsBtn = PxButton(
      'Bots: $_bots',
      width: twoCol ? 150 : 200,
      onPressed: () => setState(() => _bots = (_bots + 1) % 7),
    );
    final connected = widget.client.state == ConnState.connected;
    return PxScreen(
      background: DirtBackground(dirt: widget.dirt),
      title: 'Create New World',
      titleY: 12,
      footer: Padding(
        padding: EdgeInsets.only(bottom: 8.0 * s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PxButton('Create New World', primary: true, width: 150, onPressed: connected && !_busy ? _create : null),
            SizedBox(width: 4.0 * s),
            PxButton('Cancel', width: 150, sound: 'ui_back', onPressed: widget.onBack),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 8.0 * s),
            label('World Name'),
            SizedBox(height: 2.0 * s),
            PxField(controller: _name, hint: 'Untitled world', maxLength: 24, width: twoCol ? 304 : 200),
            SizedBox(height: 4.0 * s),
            label('Seed for the world generator (leave blank for random)'),
            SizedBox(height: 2.0 * s),
            PxField(
              controller: _seed,
              hint: 'Random',
              width: twoCol ? 304 : 200,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 10.0 * s),
            if (twoCol) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  modeBtn,
                  SizedBox(width: 4.0 * s),
                  mobsBtn,
                ],
              ),
              SizedBox(height: 4.0 * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  botsBtn,
                  SizedBox(width: 4.0 * s),
                  SizedBox(width: 150.0 * s),
                ],
              ),
            ] else ...[
              modeBtn,
              SizedBox(height: 4.0 * s),
              mobsBtn,
              SizedBox(height: 4.0 * s),
              botsBtn,
            ],
            SizedBox(height: 6.0 * s),
            SizedBox(
              width: (twoCol ? 304.0 : 200.0) * s,
              child: PxText(
                _mode == GameMode.creative
                    ? 'Unlimited blocks, flight and no hunger. Build freely.'
                    : 'Gather resources, craft tools and survive the night. Mossbacks roam by day; Hollows and Cinderlings hunt after dusk.',
                color: Px.gray,
                maxLines: 3,
              ),
            ),
            if (!connected) ...[
              SizedBox(height: 6.0 * s),
              const PxText('Waiting for the server connection...', color: Px.yellow),
            ],
          ],
        ),
      ),
    );
  }
}
