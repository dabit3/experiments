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
import 'settings_sheet.dart';
import 'theme.dart';
import 'touch_controls.dart';
import 'widgets.dart';

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
  DateTime _downAt = DateTime.now();

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
    if (e.kind == PointerDeviceKind.mouse) {
      _holdBreak = true;
      g.startBreak();
    } else if (!_touchUi) {
      _holdBreak = true;
      g.startBreak();
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if (e.pointer != _lookPointer) return;
    final d = e.localPosition - _lookStart;
    if (!_lookMoved && d.distance > 6) _lookMoved = true;
    final scale = e.kind == PointerDeviceKind.mouse ? 1.0 : 1.6;
    if (!(PointerLock.locked && e.kind == PointerDeviceKind.mouse)) g.look(e.delta.dx * scale, e.delta.dy * scale);
    if (_touchUi && e.kind != PointerDeviceKind.mouse && !_holdBreak && !_lookMoved) {
      // long-press without movement starts breaking
      if (DateTime.now().difference(_downAt).inMilliseconds > 220) {
        _holdBreak = true;
        g.startBreak();
      }
    }
  }

  void _pointerUp(PointerEvent e) {
    if (e.pointer != _lookPointer) return;
    _lookPointer = null;
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
    final ff = formFactorOf(context);
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
              child: RepaintBoundary(
                child: CustomPaint(painter: OverlayPainter(g, frame, Theme.of(context)), isComplex: false),
              ),
            ),
            if (_showCaptureHint)
              IgnorePointer(
                child: Align(
                  alignment: const Alignment(0, 0.35),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: VhSpace.md, vertical: VhSpace.sm),
                    tint: Colors.black.withValues(alpha: 0.45),
                    child: Text(
                      'Click to look around  ·  Esc to pause',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            // HUD
            if (s.phase == Phase.playing) ...[
              IgnorePointer(
                child: Hud(game: g, assets: widget.assets, frame: frame, settings: widget.settings, formFactor: ff),
              ),
              if (showTouch) TouchControls(game: g, frame: frame),
              HudButtons(
                game: g,
                client: widget.client,
                settings: widget.settings,
                touch: _touchUi,
                onSettings: () => _openSettings(context),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Hotbar(game: g, assets: widget.assets, frame: frame, formFactor: ff, interactive: true),
              ),
            ],
            // Chat overlay (bottom-left) or full chat when open
            if (g.chatOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => g.setChatOpen(false),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SafeArea(
                      child: Container(
                        width: math.min(520, MediaQuery.sizeOf(context).width - 24),
                        height: math.min(320, MediaQuery.sizeOf(context).height * 0.5),
                        margin: const EdgeInsets.all(VhSpace.md),
                        child: GestureDetector(
                          onTap: () {},
                          child: GlassPanel(
                            padding: const EdgeInsets.all(VhSpace.sm),
                            tint: Colors.black.withValues(alpha: 0.35),
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
            if (g.paused)
              PauseOverlay(
                game: g,
                client: widget.client,
                settings: widget.settings,
                onSettings: () => _openSettings(context),
              ),
            if (widget.client.state != ConnState.connected) ReconnectOverlay(client: widget.client),
            if (!g.loaded) LoadingOverlay(game: g, frame: frame),
            ToastLayer(client: widget.client),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final wasPaused = g.paused;
    g.setPaused(true);
    await showSettingsSheet(context, widget.settings, g);
    g.setPaused(wasPaused);
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
  OverlayPainter(this.g, this.frame, this.theme) : super(repaint: frame);
  final GameController g;
  final FrameNotifier frame;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (!g.view.ready) return;
    _particles(canvas, size);
    _nameTags(canvas, size);
    if (!g.inputBlocked) _crosshair(canvas, size);
  }

  void _crosshair(Canvas c, Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.difference;
    const r = 7.0, gap = 2.5;
    c.drawLine(Offset(cx - r, cy), Offset(cx - gap, cy), p);
    c.drawLine(Offset(cx + gap, cy), Offset(cx + r, cy), p);
    c.drawLine(Offset(cx, cy - r), Offset(cx, cy - gap), p);
    c.drawLine(Offset(cx, cy + gap), Offset(cx, cy + r), p);
    if (g.breaking && g.breakProgress > 0) {
      final ring = Paint()
        ..color = VhColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      c.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 16),
        -math.pi / 2,
        math.pi * 2 * g.breakProgress,
        false,
        ring,
      );
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

  void _nameTags(Canvas c, Size s) {
    for (final p in g.session.players.values) {
      if (p.id == g.session.youId) continue;
      final o = g.project(p.rx, p.ry + 2.15, p.rz, s);
      if (o == null) continue;
      final d = g.camera.distanceTo(p.rx, p.ry, p.rz);
      if (d > 48) continue;
      final scale = (1.1 - d / 60).clamp(0.6, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: p.name,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rect = Rect.fromCenter(center: o, width: tp.width + 14, height: tp.height + 8);
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
      final hpW = (rect.width - 8) * (p.hp / 20).clamp(0, 1);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 4, rect.bottom - 3, hpW, 2), const Radius.circular(1)),
        Paint()..color = VhColors.danger,
      );
      tp.paint(c, Offset(rect.left + 7, rect.top + 3));
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
    final failed = client.state == ConnState.failed;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: GlassPanel(
          child: SizedBox(
            width: 360,
            child: StateBlock(
              icon: failed ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
              title: failed ? 'Lost the server' : 'Reconnecting…',
              message: failed
                  ? (client.lastError ?? 'The server is unreachable.')
                  : 'Your place in the world is saved. Attempt ${client.reconnectAttempt}.',
              loading: !failed,
              action: failed
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(onPressed: client.leaveRoomLocal, child: const Text('Back to menu')),
                        const SizedBox(width: VhSpace.sm),
                        FilledButton(onPressed: client.retryNow, child: const Text('Retry')),
                      ],
                    )
                  : OutlinedButton(onPressed: client.retryNow, child: const Text('Retry now')),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.game, required this.frame});
  final GameController game;
  final FrameNotifier frame;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ListenableBuilder(
      listenable: frame,
      builder: (context, _) {
        final n = game.session.chunksReceived.length;
        final p = (n / 25).clamp(0.0, 1.0);
        return Container(
          color: const Color(0xff0b0f17),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmberGlyph(size: 56),
              const SizedBox(height: VhSpace.lg),
              Text(
                'Kindling the world…',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: VhSpace.xs),
              Text('$n chunks received', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
              const SizedBox(height: VhSpace.lg),
              SizedBox(
                width: 220,
                child: LinearProgressIndicator(value: p, minHeight: 4, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key, required this.client});
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    if (client.toasts.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: IgnorePointer(
          child: Column(
            children: [
              const SizedBox(height: 56),
              for (final t in client.toasts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Reveal(
                    key: ValueKey(t.at),
                    offset: -10,
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      radius: 999,
                      tint: (t.kind == 'error' ? VhColors.danger : Colors.black).withValues(alpha: 0.5),
                      child: Text(
                        t.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
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

/// Keyboard hint pill for desktop platforms.
bool get isDesktopLike =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;
