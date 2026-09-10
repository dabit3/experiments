import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'settings_sheet.dart';
import 'theme.dart';
import 'widgets.dart';

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
  late final AnimationController _bg = AnimationController(vsync: this, duration: const Duration(seconds: 40))
    ..repeat();
  bool _advanced = false;

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

  Future<void> _create() async {
    await _commitIdentity();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => _CreateDialog(client: widget.client),
    );
  }

  Future<void> _join() async {
    await _commitIdentity();
    if (!mounted) return;
    final code = _code.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 5-letter room code')));
      return;
    }
    widget.client.joinRoom(code);
  }

  @override
  Widget build(BuildContext context) {
    final ff = formFactorOf(context);
    final t = Theme.of(context);
    final content = ff == FormFactor.desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _left(context)),
              const SizedBox(width: VhSpace.xxl),
              Expanded(flex: 6, child: _right(context)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _left(context),
              const SizedBox(height: VhSpace.xl),
              _right(context),
            ],
          );
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _Backdrop(animation: _bg)),
          SafeArea(
            child: Column(
              children: [
                _TopBar(client: widget.client, settings: widget.settings),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ff == FormFactor.phone ? VhSpace.lg : VhSpace.xxxl,
                      vertical: VhSpace.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: content),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: VhSpace.sm),
                  child: Text(
                    'An original voxel sandbox. Not affiliated with any other game.',
                    style: t.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _left(BuildContext context) {
    final t = Theme.of(context);
    final ff = formFactorOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Wordmark(
            size: ff == FormFactor.phone ? 34 : 48,
            subtitle: 'Gather. Build. Keep the hearth lit through the night — together, on any device.',
          ),
        ),
        const SizedBox(height: VhSpace.xl),
        Reveal(
          delay: const Duration(milliseconds: 80),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(VhSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('Your name'),
                  TextField(
                    controller: _name,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      hintText: 'Wanderer',
                      counterText: '',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _commitIdentity(),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 _\-]'))],
                  ),
                  const SizedBox(height: VhSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add_home_work_outlined),
                          label: const Text('Create a world'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VhSpace.lg),
                  const SectionLabel('Join with a code'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 5,
                          style: t.textTheme.titleMedium?.copyWith(letterSpacing: 3, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            hintText: 'ABCDE',
                            counterText: '',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          onSubmitted: (_) => _join(),
                        ),
                      ),
                      const SizedBox(width: VhSpace.sm),
                      OutlinedButton(onPressed: widget.client.joiningRoom ? null : _join, child: const Text('Join')),
                    ],
                  ),
                  const SizedBox(height: VhSpace.md),
                  InkWell(
                    borderRadius: BorderRadius.circular(VhRadius.sm),
                    onTap: () => setState(() => _advanced = !_advanced),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _advanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                            color: t.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text('Server', style: t.textTheme.labelMedium),
                          const Spacer(),
                          _ConnDot(client: widget.client),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: VhMotion.base,
                    curve: VhMotion.curve,
                    alignment: Alignment.topCenter,
                    child: _advanced
                        ? Padding(
                            padding: const EdgeInsets.only(top: VhSpace.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _server,
                                    decoration: const InputDecoration(
                                      hintText: 'ws://host:8787/ws',
                                      prefixIcon: Icon(Icons.dns_outlined),
                                    ),
                                    onSubmitted: (_) => _commitIdentity(),
                                  ),
                                ),
                                const SizedBox(width: VhSpace.sm),
                                IconButton.filledTonal(
                                  onPressed: _commitIdentity,
                                  icon: const Icon(Icons.refresh_rounded),
                                  tooltip: 'Reconnect',
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: VhSpace.lg),
        Reveal(delay: const Duration(milliseconds: 160), child: _HowToPlay()),
      ],
    );
  }

  Widget _right(BuildContext context) {
    final c = widget.client;
    final t = Theme.of(context);
    return Reveal(
      delay: const Duration(milliseconds: 120),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(VhSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Open worlds', style: t.textTheme.headlineSmall)),
                  IconButton(
                    onPressed: c.state == ConnState.connected ? c.refreshRooms : null,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: VhSpace.sm),
              _roomsBody(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomsBody(BuildContext context) {
    final c = widget.client;
    switch (c.state) {
      case ConnState.idle:
      case ConnState.connecting:
        return const StateBlock(
          icon: Icons.wifi_tethering,
          title: 'Connecting to the hearth…',
          message: 'Looking for the Voxelhearth server.',
          loading: true,
        );
      case ConnState.reconnecting:
        return StateBlock(
          icon: Icons.wifi_off_rounded,
          title: 'Connection lost',
          message: 'Reconnecting (attempt ${c.reconnectAttempt})…',
          loading: true,
          action: OutlinedButton(onPressed: c.retryNow, child: const Text('Retry now')),
        );
      case ConnState.failed:
        return StateBlock(
          icon: Icons.cloud_off_rounded,
          title: 'Server unreachable',
          message:
              c.lastError ??
              'Could not reach ${c.serverUrl}. Start the server with `dart run bin/server.dart` and retry.',
          action: FilledButton.tonal(onPressed: c.connect, child: const Text('Try again')),
        );
      case ConnState.connected:
        if (c.rooms.isEmpty) {
          return StateBlock(
            icon: Icons.landscape_outlined,
            title: 'No worlds yet',
            message: 'Be the first to light a hearth. Create a world and share its code.',
            action: FilledButton.tonal(onPressed: _create, child: const Text('Create a world')),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < c.rooms.length; i++)
              Reveal(
                delay: Duration(milliseconds: 40 * i),
                child: _RoomTile(
                  room: c.rooms[i],
                  onJoin: () {
                    _commitIdentity();
                    c.joinRoom(c.rooms[i].code);
                  },
                ),
              ),
          ],
        );
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.client, required this.settings});
  final GameClient client;
  final Settings settings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(VhSpace.lg, VhSpace.sm, VhSpace.sm, 0),
    child: Row(
      children: [
        PlatformBadge(client.platform),
        const Spacer(),
        IconButton(
          tooltip: 'Theme',
          onPressed: () {
            final m = settings.themeMode;
            settings.themeMode = m == ThemeMode.dark
                ? ThemeMode.light
                : (m == ThemeMode.light ? ThemeMode.system : ThemeMode.dark);
          },
          icon: Icon(switch (settings.themeMode) {
            ThemeMode.dark => Icons.dark_mode_rounded,
            ThemeMode.light => Icons.light_mode_rounded,
            ThemeMode.system => Icons.brightness_auto_rounded,
          }),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => showSettingsSheet(context, settings, null),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );
}

class _ConnDot extends StatelessWidget {
  const _ConnDot({required this.client});
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (color, label) = switch (client.state) {
      ConnState.connected => (VhColors.moss, 'Connected · ${client.pingMs} ms'),
      ConnState.connecting || ConnState.idle => (VhColors.gold, 'Connecting'),
      ConnState.reconnecting => (VhColors.gold, 'Reconnecting'),
      ConnState.failed => (VhColors.danger, 'Offline'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: VhMotion.base,
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: t.textTheme.labelSmall),
      ],
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.onJoin});
  final RoomSummary room;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final playing = room.phase == Phase.playing;
    return Padding(
      padding: const EdgeInsets.only(bottom: VhSpace.sm),
      child: Material(
        color: t.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(VhRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(VhRadius.md),
          onTap: onJoin,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: VhSpace.lg, vertical: VhSpace.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [VhColors.ember.withValues(alpha: 0.9), VhColors.gold.withValues(alpha: 0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(VhRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    room.mode == GameMode.creative ? Icons.brush_rounded : Icons.shield_moon_rounded,
                    color: const Color(0xff1a0c04),
                  ),
                ),
                const SizedBox(width: VhSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: t.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${room.code} · ${room.mode == GameMode.creative ? 'Creative' : 'Survival'} · ${room.players} ${room.players == 1 ? 'player' : 'players'}',
                        style: t.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (playing ? VhColors.moss : VhColors.sky).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    playing ? 'In match' : (room.phase == Phase.results ? 'Results' : 'Lobby'),
                    style: t.textTheme.labelSmall?.copyWith(color: playing ? VhColors.moss : VhColors.sky),
                  ),
                ),
                const SizedBox(width: VhSpace.sm),
                Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowToPlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tips = [
      (Icons.mouse_outlined, 'Look around', 'Drag or move the mouse · touch-drag on phones'),
      (Icons.keyboard_alt_outlined, 'Move', 'WASD / arrows · joystick on touch · Space to jump · Shift to sneak'),
      (Icons.handyman_outlined, 'Build', 'Hold left click / tap to break · right click / long-press to place'),
      (Icons.inventory_2_outlined, 'Craft', 'E opens your pack · build a Workbench for bigger recipes'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VhSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('How to play'),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip.$1, size: 20, color: t.colorScheme.primary),
                    const SizedBox(width: VhSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.$2, style: t.textTheme.titleSmall),
                          Text(tip.$3, style: t.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.client});
  final GameClient client;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  late final TextEditingController _name = TextEditingController(text: '${widget.client.playerName}\'s world');
  final TextEditingController _seed = TextEditingController();
  String _mode = GameMode.survival;
  bool _mobs = true;
  int _bots = 0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(VhSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(VhSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create a world', style: t.textTheme.headlineSmall),
              const SizedBox(height: VhSpace.xs),
              Text(
                'You will be the host. Share the room code with friends on any device.',
                style: t.textTheme.bodySmall,
              ),
              const SizedBox(height: VhSpace.xl),
              TextField(
                controller: _name,
                maxLength: 24,
                decoration: const InputDecoration(labelText: 'World name', counterText: ''),
              ),
              const SizedBox(height: VhSpace.lg),
              const SectionLabel('Mode'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: GameMode.survival,
                    label: Text('Survival'),
                    icon: Icon(Icons.shield_moon_rounded),
                  ),
                  ButtonSegment(value: GameMode.creative, label: Text('Creative'), icon: Icon(Icons.brush_rounded)),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: VhSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _seed,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Seed (optional)', hintText: 'random'),
                    ),
                  ),
                  const SizedBox(width: VhSpace.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bots', style: t.textTheme.labelMedium),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _bots > 0 ? () => setState(() => _bots--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_bots', style: t.textTheme.titleMedium),
                          IconButton(
                            onPressed: _bots < 6 ? () => setState(() => _bots++) : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Creatures roam the world'),
                subtitle: const Text('Mossbacks by day, Hollows and Cinderlings at night'),
                value: _mobs,
                onChanged: (v) => setState(() => _mobs = v),
              ),
              const SizedBox(height: VhSpace.lg),
              Row(
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      final seedText = _seed.text.trim();
                      widget.client.createRoom(
                        name: _name.text.trim().isEmpty ? 'Untitled world' : _name.text.trim(),
                        mode: _mode,
                        seed: seedText.isEmpty ? null : int.tryParse(seedText),
                        spawnMobs: _mobs,
                        bots: _bots,
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.local_fire_department_rounded),
                    label: const Text('Light the hearth'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slow drifting voxel silhouettes behind the home screen.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(painter: _BackdropPainter(animation.value, dark)),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.t, this.dark);
  final double t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xff0b0f17), Color(0xff141b2b), Color(0xff1a1410)]
            : const [Color(0xfffdf8f0), Color(0xfff3ebdc), Color(0xffe9dcc6)],
        stops: const [0, 0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);
    // Ember glow at the bottom
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          VhColors.ember.withValues(alpha: dark ? 0.28 : 0.22),
          VhColors.ember.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 1.05), radius: size.width * 0.6));
    canvas.drawRect(Offset.zero & size, glow);
    // Drifting cubes
    final rnd = math.Random(3);
    for (var i = 0; i < 26; i++) {
      final bx = rnd.nextDouble(), by = rnd.nextDouble(), s = 14 + rnd.nextDouble() * 34, sp = 0.3 + rnd.nextDouble();
      final x = ((bx + t * sp * 0.15) % 1.2 - 0.1) * size.width;
      final y = ((by + math.sin(t * math.pi * 2 * sp + i) * 0.01) % 1) * size.height;
      final a = (dark ? 0.06 : 0.08) + rnd.nextDouble() * 0.05;
      _cube(canvas, Offset(x, y), s, a);
    }
  }

  void _cube(Canvas c, Offset o, double s, double alpha) {
    final top = Paint()..color = (dark ? Colors.white : VhColors.bark).withValues(alpha: alpha * 1.4);
    final left = Paint()..color = (dark ? Colors.white : VhColors.bark).withValues(alpha: alpha * 0.8);
    final right = Paint()..color = (dark ? Colors.white : VhColors.bark).withValues(alpha: alpha);
    final h = s * 0.5;
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + s, o.dy - h)
        ..lineTo(o.dx + 2 * s, o.dy)
        ..lineTo(o.dx + s, o.dy + h)
        ..close(),
      top,
    );
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + s, o.dy + h)
        ..lineTo(o.dx + s, o.dy + h + s)
        ..lineTo(o.dx, o.dy + s)
        ..close(),
      left,
    );
    c.drawPath(
      Path()
        ..moveTo(o.dx + 2 * s, o.dy)
        ..lineTo(o.dx + s, o.dy + h)
        ..lineTo(o.dx + s, o.dy + h + s)
        ..lineTo(o.dx + 2 * s, o.dy + s)
        ..close(),
      right,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.t != t || old.dark != dark;
}
