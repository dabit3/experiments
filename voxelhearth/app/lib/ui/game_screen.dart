import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/game_controller.dart';
import '../game/pointer_lock.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'chat_panel.dart';
import 'hud.dart';
import 'inventory_ui.dart';
import 'pixel.dart';
import 'settings_sheet.dart';
import 'touch_controls.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.client, required this.game, required this.settings, required this.assets});
  final GameClient client;
  final GameController game;
  final Settings settings;
  final RenderAssets assets;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final FrameNotifier frame = FrameNotifier();
  final FocusNode _focus = FocusNode(debugLabel: 'game');
  Duration _last = Duration.zero;

  // pointer bookkeeping
  int? _lookPointer;
  Offset _lookStart = Offset.zero;
  bool _lookMoved = false;
  bool _holdBreak = false;
  bool _optionsOpen = false;
  DateTime _downAt = DateTime.now();
  Timer? _holdTimer;

  GameController get g => widget.game;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    g.addListener(_onGame);
    widget.client.addListener(_onGame);
    PointerLock.onMove = _lockedLook;
    PointerLock.onChange = _onLockChange;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _onGame() {
    if (PointerLock.locked && g.inputBlocked) PointerLock.release();
    if (mounted) setState(() {});
  }

  void _lockedLook(double dx, double dy) {
    if (!g.inputBlocked) g.look(dx, dy);
  }

  /// Losing capture without the game asking for it (Esc in the browser,
  /// window losing focus) drops into the pause menu so the player sees why
  /// the mouse stopped steering.
  void _onLockChange() {
    if (!PointerLock.locked && !g.inputBlocked) g.setPaused(true);
    if (mounted) setState(() {});
  }

  /// Desktop mouse look: the first click captures the pointer; later clicks
  /// act on the world. Touch and unsupported hosts keep drag-to-look.
  bool get _usesCapture => !_touchUi && PointerLock.supported;
  bool get _showCaptureHint => _usesCapture && !PointerLock.locked && !g.inputBlocked && g.loaded;

  void _onTick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    g.update(dt);
    frame.bump();
  }

  @override
  void dispose() {
    PointerLock.release();
    PointerLock.onMove = null;
    PointerLock.onChange = null;
    _holdTimer?.cancel();
    _ticker.dispose();
    g.removeListener(_onGame);
    widget.client.removeListener(_onGame);
    _focus.dispose();
    frame.dispose();
    super.dispose();
  }

  bool get _touchUi => widget.settings.touchControls;

  // ---------------------------------------------------------------- pointer input

  void _pointerDown(PointerDownEvent e) {
    if (g.inputBlocked) return;
    _focus.requestFocus();
    if (e.kind == PointerDeviceKind.mouse) {
      if (_usesCapture && !PointerLock.locked) {
        PointerLock.request();
        return;
      }
      if (e.buttons & kSecondaryMouseButton != 0) {
        g.use();
        return;
      }
      if (e.buttons & kMiddleMouseButton != 0) return;
    }
    _lookPointer ??= e.pointer;
    if (_lookPointer != e.pointer) return;
    _lookStart = e.localPosition;
    _lookMoved = false;
    _downAt = DateTime.now();
    if (e.kind == PointerDeviceKind.mouse || !_touchUi) {
      _holdBreak = true;
      g.startBreak();
    } else {
      // A still finger held on the world starts breaking after a short delay;
      // moving it first turns the gesture into a look-drag instead.
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 220), () {
        if (_lookPointer == e.pointer && !_holdBreak && !_lookMoved && !g.inputBlocked) {
          _holdBreak = true;
          g.startBreak();
        }
      });
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if (e.pointer != _lookPointer) return;
    final d = e.localPosition - _lookStart;
    if (!_lookMoved && d.distance > 6) _lookMoved = true;
    final scale = e.kind == PointerDeviceKind.mouse ? 1.0 : 1.6;
    if (!(PointerLock.locked && e.kind == PointerDeviceKind.mouse)) g.look(e.delta.dx * scale, e.delta.dy * scale);
    if (_touchUi && e.kind != PointerDeviceKind.mouse && !_holdBreak && !_lookMoved) {
      if (DateTime.now().difference(_downAt).inMilliseconds > 220) {
        _holdBreak = true;
        g.startBreak();
      }
    }
  }

  void _pointerUp(PointerEvent e) {
    if (e.pointer != _lookPointer) return;
    _lookPointer = null;
    _holdTimer?.cancel();
    final short = DateTime.now().difference(_downAt).inMilliseconds < 220;
    if (_holdBreak) {
      g.stopBreak();
      _holdBreak = false;
    } else if (_touchUi && e.kind != PointerDeviceKind.mouse && short && !_lookMoved) {
      // quick tap on the world = hit / start a short break burst
      g.tapBreak();
    }
  }

  void _scroll(PointerSignalEvent e) {
    if (e is PointerScrollEvent && !g.inputBlocked) {
      if (e.scrollDelta.dy.abs() > 2) g.scrollSlot(e.scrollDelta.dy > 0 ? 1 : -1);
    }
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) => g.handleKey(e) ? KeyEventResult.handled : KeyEventResult.ignored;

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final s = g.session;
    final gs = Gui.of(context);
    final showTouch = _touchUi && !g.inputBlocked;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // World
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _pointerDown,
              onPointerMove: _pointerMove,
              onPointerUp: _pointerUp,
              onPointerCancel: _pointerUp,
              onPointerSignal: _scroll,
              child: MouseRegion(
                cursor: g.inputBlocked || _showCaptureHint ? SystemMouseCursors.basic : SystemMouseCursors.none,
                child: RepaintBoundary(
                  child: VoxelCanvas(game: g, assets: widget.assets, frame: frame),
                ),
              ),
            ),
            // Particles + name tags + crosshair
            IgnorePointer(
              child: RepaintBoundary(child: CustomPaint(painter: OverlayPainter(g, frame, gs), isComplex: false)),
            ),
            if (_showCaptureHint)
              Positioned(
                left: 0,
                right: 0,
                bottom: 46.0 * gs,
                child: IgnorePointer(
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      color: const Color(0x80000000),
                      padding: EdgeInsets.symmetric(horizontal: 4.0 * gs, vertical: 1.0 * gs),
                      child: const PxText('Click to look around  ·  Esc to pause'),
                    ),
                  ),
                ),
              ),
            // HUD
            if (s.phase == Phase.playing) ...[
              IgnorePointer(
                child: Hud(
                  game: g,
                  assets: widget.assets,
                  frame: frame,
                  settings: widget.settings,
                  client: widget.client,
                ),
              ),
              if (showTouch) TouchControls(game: g, frame: frame),
              HudButtons(game: g, touch: _touchUi),
              if (!g.inputBlocked) Hotbar(game: g),
            ],
            // Chat: history above a full-width input line along the bottom.
            if (g.chatOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => g.setChatOpen(false),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          width: math.min(324.0 * gs, MediaQuery.sizeOf(context).width),
                          height: math.min(180.0 * gs, MediaQuery.sizeOf(context).height * 0.6),
                          child: ChatPanel(
                            client: widget.client,
                            session: s,
                            autofocus: true,
                            transparent: true,
                            onClose: () => g.setChatOpen(false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Overlays
            if (g.overlay != null && !g.dead && !g.paused)
              InventoryOverlay(
                game: g,
                client: widget.client,
                assets: widget.assets,
                kind: g.overlay!,
                onClose: g.closeOverlay,
              ),
            if (g.dead) DeathOverlay(game: g, client: widget.client),
            if (g.paused && !_optionsOpen)
              PauseOverlay(
                game: g,
                client: widget.client,
                settings: widget.settings,
                onSettings: () => _openSettings(context),
              ),
            if (widget.client.state != ConnState.connected) ReconnectOverlay(client: widget.client),
            if (!g.loaded) LoadingOverlay(game: g, frame: frame, assets: widget.assets),
            if (s.phase != Phase.playing) ToastLayer(client: widget.client),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    g.setPaused(true);
    setState(() => _optionsOpen = true);
    await showOptionsScreen(context, widget.settings, game: g, background: const DimBackground());
    if (mounted) setState(() => _optionsOpen = false);
    _focus.requestFocus();
  }
}

/// Bumped once per rendered frame; cheap widgets listen to it instead of the
/// whole controller so the HUD updates at 60fps without rebuilding the tree.
class FrameNotifier extends ChangeNotifier {
  int frame = 0;
  void bump() {
    frame++;
    notifyListeners();
  }
}

class VoxelCanvas extends StatelessWidget {
  const VoxelCanvas({super.key, required this.game, required this.assets, required this.frame});
  final GameController game;
  final RenderAssets assets;
  final FrameNotifier frame;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: frame,
    builder: (context, _) =>
        CustomPaint(painter: VoxelPainter(assets, game.frame(), game.entityImage), isComplex: true, willChange: true),
  );
}

/// Draws crosshair, particles and remote name tags above the shader output.
class OverlayPainter extends CustomPainter {
  OverlayPainter(this.g, this.frame, this.s) : super(repaint: frame);
  final GameController g;
  final FrameNotifier frame;
  final int s;

  @override
  void paint(Canvas canvas, Size size) {
    if (!g.view.ready) return;
    _particles(canvas, size);
    _nameTags(canvas, size);
    if (!g.inputBlocked) _crosshair(canvas, size);
  }

  /// 9x9 inverted plus, plus a thin progress bar under it while breaking.
  void _crosshair(Canvas c, Size size) {
    final cx = (size.width / 2 / s).floorToDouble(), cy = (size.height / 2 / s).floorToDouble();
    final p = Paint()
      ..color = const Color(0xffe0e0e0)
      ..blendMode = BlendMode.difference;
    c.drawRect(Rect.fromLTWH((cx - 4) * s, cy * s, 9.0 * s, 1.0 * s), p);
    c.drawRect(Rect.fromLTWH(cx * s, (cy - 4) * s, 1.0 * s, 9.0 * s), p);
    if (g.breaking && g.breakProgress > 0) {
      pxRect(c, s, cx - 9, cy + 7, 19, 3, const Color(0x80000000));
      pxRect(c, s, cx - 8, cy + 8, (17 * g.breakProgress).clamp(0, 17), 1, Px.white);
    }
  }

  void _particles(Canvas c, Size s) {
    for (final p in g.particles) {
      final o = g.project(p.x, p.y, p.z, s);
      if (o == null) continue;
      final d = g.camera.distanceTo(p.x, p.y, p.z);
      final r = (26 / (d + 0.5)).clamp(1.0, 7.0) * (p.life.clamp(0.0, 0.6) / 0.6 * 0.6 + 0.4);
      c.drawRect(
        Rect.fromCenter(center: o, width: r, height: r),
        Paint()..color = Color(p.color).withValues(alpha: p.life.clamp(0.0, 1.0)),
      );
    }
  }

  void _nameTags(Canvas c, Size size) {
    for (final p in g.session.players.values) {
      if (p.id == g.session.youId) continue;
      final o = g.project(p.rx, p.ry + 2.15, p.rz, size);
      if (o == null) continue;
      final d = g.camera.distanceTo(p.rx, p.ry, p.rz);
      if (d > 48) continue;
      final scale = (1.1 - d / 60).clamp(0.6, 1.0);
      final tp = pxPainter(p.name, s, size: scale, shadow: false);
      final rect = Rect.fromCenter(center: o, width: tp.width + 4 * s, height: tp.height + 2 * s);
      c.drawRect(rect, Paint()..color = const Color(0x40000000));
      final hpW = (rect.width - 2 * s) * (p.hp / 20).clamp(0, 1);
      c.drawRect(Rect.fromLTWH(rect.left + s, rect.bottom - s, hpW, s * 1.0), Paint()..color = Px.red);
      tp.paint(c, Offset(rect.left + 2 * s, rect.top + s));
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter old) => true;
}

class ReconnectOverlay extends StatelessWidget {
  const ReconnectOverlay({super.key, required this.client});
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final failed = client.state == ConnState.failed;
    return Positioned.fill(
      child: DimBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 50.0 * s),
              PxText(failed ? 'Connection Lost' : 'Reconnecting...'),
              SizedBox(height: 10.0 * s),
              PxText(
                failed
                    ? (client.lastError ?? 'The server is unreachable.')
                    : 'Your place in the world is saved. Attempt ${client.reconnectAttempt}.',
                color: Px.gray,
                align: TextAlign.center,
                maxLines: 3,
              ),
              if (!failed) ...[SizedBox(height: 10.0 * s), _LoadingDots()],
              SizedBox(height: 20.0 * s),
              PxButton(failed ? 'Retry' : 'Retry Now', onPressed: client.retryNow),
              if (failed) ...[
                SizedBox(height: 4.0 * s),
                PxButton('Back to Title Screen', onPressed: client.leaveRoomLocal, sound: 'ui_back'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final n = (_c.value * 4).floor() % 4;
      return PxText('${'o' * n}${' ' * (3 - n)}', color: Px.gray);
    },
  );
}

/// Dirt-backed loading screen with a classic thin progress bar.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.game, required this.frame, required this.assets});
  final GameController game;
  final FrameNotifier frame;
  final RenderAssets assets;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return Positioned.fill(
      child: DirtBackground(
        dirt: assets.dirt,
        child: ListenableBuilder(
          listenable: frame,
          builder: (context, _) {
            final n = game.session.chunksReceived.length;
            final p = (n / 25).clamp(0.0, 1.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PxText('Loading world'),
                SizedBox(height: 4.0 * s),
                PxText('Building terrain · $n chunks', color: Px.gray),
                SizedBox(height: 12.0 * s),
                CustomPaint(size: Size(100.0 * s, 4.0 * s), painter: _BarPainter(s, p)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.s, this.p);
  final int s;
  final double p;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width / s;
    pxRect(c, s, 0, 0, w, 4, const Color(0xff808080));
    pxRect(c, s, 1, 1, (w - 2) * p, 2, Px.green);
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.p != p;
}

/// Transient messages shown along the top outside gameplay (in game they
/// go to the action bar above the hotbar).
class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key, required this.client});
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    if (client.toasts.isEmpty) return const SizedBox.shrink();
    final s = Gui.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: IgnorePointer(
          child: Column(
            children: [
              SizedBox(height: 4.0 * s),
              for (final t in client.toasts)
                Container(
                  key: ValueKey(t.at),
                  margin: EdgeInsets.only(bottom: 1.0 * s),
                  padding: EdgeInsets.symmetric(horizontal: 3.0 * s),
                  color: const Color(0x80000000),
                  child: PxText(t.text, color: t.kind == 'error' ? Px.red : Px.yellow),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keyboard hint pill for desktop platforms.
bool get isDesktopLike =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;
