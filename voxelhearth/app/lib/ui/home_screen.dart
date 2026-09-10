import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _name = TextEditingController(text: widget.client.playerName);
  late final TextEditingController _server = TextEditingController(text: widget.client.serverUrl);
  final TextEditingController _code = TextEditingController();
  late final AnimationController _bg = AnimationController(vsync: this, duration: const Duration(seconds: 60))
    ..repeat();
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
    _bg.dispose();
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
    final bg = _Panorama(animation: _bg);
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
    final gui = Size(box.width / s, box.height / s);
    final c = widget.client;
    final short = gui.height < 230;
    final logoScale = gui.width < 330 || short ? 2.2 : 3.0;
    final logoTop = short ? 14.0 : 28.0;
    final menuGap = short ? 8.0 : 16.0;
    // Footer text sits on one line when the screen is wide enough for both
    // strings, otherwise the legal line stacks above the status line.
    final footerRows = gui.width >= 600 ? 1 : 2;
    final menuHeight = 3 * 20 + 2 * 4 + menuGap + 20;
    final taglineBottom = logoTop + Px.lineHeight * logoScale * 1.1 + 2 + Px.lineHeight;
    final btnY = math.max(
      taglineBottom + 6,
      math.min((gui.height / 4 + 40).floorToDouble(), gui.height - menuHeight - footerRows * Px.lineHeight - 6),
    );
    final status = switch (c.state) {
      ConnState.connected => 'Connected · ${c.pingMs} ms',
      ConnState.connecting || ConnState.idle => 'Connecting...',
      ConnState.reconnecting => 'Reconnecting (${c.reconnectAttempt})...',
      ConnState.failed => 'Server offline',
    };
    final statusColor = switch (c.state) {
      ConnState.connected => Px.green,
      ConnState.failed => Px.red,
      _ => Px.yellow,
    };
    return Stack(
      children: [
        Positioned(
          top: logoTop * s,
          left: 0,
          right: 0,
          child: Column(
            children: [
              PxWordmark(size: logoScale),
              SizedBox(height: 2.0 * s),
              const PxText('An original voxel sandbox', color: Px.gray, align: TextAlign.center),
            ],
          ),
        ),
        Positioned(
          top: logoTop * s + Px.lineHeight * s * logoScale * 1.1 - 6.0 * s,
          left: gui.width / 2 * s + (gui.width < 330 ? 44.0 : 62.0) * s * logoScale / 3,
          child: Transform.rotate(
            angle: -math.pi / 9,
            child: _Splash(animation: _bg),
          ),
        ),
        Positioned(
          top: btnY * s,
          left: 0,
          right: 0,
          child: Column(
            children: [
              PxButton('Play Online', onPressed: () => _go(_Page.play)),
              SizedBox(height: 4.0 * s),
              PxButton('Create World', onPressed: () => _go(_Page.create)),
              SizedBox(height: 4.0 * s),
              PxButton('Player Name: ${c.playerName}', onPressed: () => _go(_Page.name)),
              SizedBox(height: menuGap * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PxButton(
                    'Options...',
                    width: 98,
                    onPressed: () => showOptionsScreen(
                      context,
                      widget.settings,
                      background: DirtBackground(dirt: widget.assets?.dirt),
                    ),
                  ),
                  SizedBox(width: 4.0 * s),
                  PxButton('How to Play', width: 98, onPressed: () => _showHowToPlay(context)),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 2.0 * s,
          bottom: 2.0 * s,
          child: Row(
            children: [
              PxText('Voxelhearth 1.0 · ${platformLabel(c.platform)}'),
              SizedBox(width: 6.0 * s),
              PxText(status, color: statusColor),
            ],
          ),
        ),
        Positioned(
          right: 2.0 * s,
          bottom: (footerRows == 1 ? 2.0 : 2.0 + Px.lineHeight) * s,
          child: const PxText('Original game & art. Not affiliated with any other title.'),
        ),
      ],
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
            PxButton('Create New World', width: 150, onPressed: connected && !_busy ? _create : null),
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

/// Rotating yellow splash line beside the wordmark.
class _Splash extends StatelessWidget {
  const _Splash({required this.animation});
  final Animation<double> animation;

  static const _lines = [
    'Keep the hearth lit!',
    'Also on iOS, Android, macOS & web!',
    'Now with Mossbacks!',
    'Multiplayer across every device!',
    'Bots welcome!',
    'Deterministic!',
    'Hollows hunt at night!',
    'Craft a Workbench first!',
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value;
      final i = (t * _lines.length).floor() % _lines.length;
      final pulse = 1 + 0.06 * math.sin(t * 2 * math.pi * 60);
      return Transform.scale(
        scale: pulse,
        child: PxText(_lines[i], color: Px.yellow),
      );
    },
  );
}

/// Slowly drifting voxel skyline behind the title screen.
class _Panorama extends StatelessWidget {
  const _Panorama({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) => CustomPaint(painter: _PanoramaPainter(animation.value, Gui.of(context))),
  );
}

class _PanoramaPainter extends CustomPainter {
  _PanoramaPainter(this.t, this.s);
  final double t;
  final int s;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff0a1a3a), Color(0xff284d8f), Color(0xff6f9fd8)],
        stops: [0, 0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);
    final rnd = math.Random(11);
    final cell = 6.0 * s;
    final cols = (size.width / cell).ceil() + 2;
    final scroll = t * cols * cell;
    // Distant ridge
    for (var i = -1; i < cols + 1; i++) {
      final x = ((i * cell - scroll) % (cols * cell) + cols * cell) % (cols * cell) - cell;
      final h = (0.30 + 0.12 * math.sin(i * 0.6) + 0.06 * math.sin(i * 1.7)) * size.height;
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, cell, h), Paint()..color = const Color(0xff2f4d6f));
    }
    // Near hills with grass tops and dirt
    for (var i = -1; i < cols + 1; i++) {
      final x = ((i * cell - scroll * 1.6) % (cols * cell) + cols * cell) % (cols * cell) - cell;
      final h = (0.16 + 0.07 * math.sin(i * 0.9 + 2) + 0.03 * math.sin(i * 2.3)) * size.height;
      final top = size.height - h;
      canvas.drawRect(Rect.fromLTWH(x, top, cell, cell), Paint()..color = const Color(0xff5f9a34));
      canvas.drawRect(Rect.fromLTWH(x, top + cell, cell, h), Paint()..color = const Color(0xff6b4a2c));
      if (rnd.nextInt(7) == 0) {
        canvas.drawRect(Rect.fromLTWH(x, top - cell * 3, cell, cell * 3), Paint()..color = const Color(0xff4b3320));
        canvas.drawRect(
          Rect.fromLTWH(x - cell, top - cell * 5, cell * 3, cell * 3),
          Paint()..color = const Color(0xff3f7a2a),
        );
      }
    }
    // Stars
    final star = Paint()..color = const Color(0x90ffffff);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * size.width, y = rnd.nextDouble() * size.height * 0.4;
      canvas.drawRect(Rect.fromLTWH(x, y, s.toDouble(), s.toDouble()), star);
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x30000000));
  }

  @override
  bool shouldRepaint(covariant _PanoramaPainter old) => old.t != t || old.s != s;
}
