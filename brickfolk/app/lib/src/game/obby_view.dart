import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import 'controls.dart';
import 'interp.dart';

/// Side-scrolling obby renderer. The server owns physics; this view blends
/// frames, follows the local player and forwards input.
class ObbyView extends StatefulWidget {
  const ObbyView({super.key});

  @override
  State<ObbyView> createState() => _ObbyViewState();
}

class _ObbyViewState extends State<ObbyView> {
  ObbyFlameGame? _game;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final app = AppScope.read(context);
    _game ??= ObbyFlameGame(
      client: app.client,
      dark: dark,
      haptics: app.hapticsEnabled,
      autopilot: app.config.testMode,
    );
    _game!.dark = dark;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final touch = wantsTouchControls(context);
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget(game: _game!, focusNode: _focus, autofocus: true),
        if (touch) ...[
          Positioned(
            left: Space.lg + pad.left,
            bottom: Space.lg + pad.bottom,
            child: Row(
              children: [
                TouchButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Move left',
                  onChanged: (v) => _game!.setTouch(left: v),
                ),
                const SizedBox(width: Space.md),
                TouchButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Move right',
                  onChanged: (v) => _game!.setTouch(right: v),
                ),
              ],
            ),
          ),
          Positioned(
            right: Space.lg + pad.right,
            bottom: Space.lg + pad.bottom,
            child: TouchButton(
              icon: Icons.keyboard_double_arrow_up_rounded,
              label: 'Jump',
              size: 84,
              color: BrickColors.brick,
              onChanged: (v) => _game!.setTouch(jump: v),
            ),
          ),
        ] else
          Positioned(
            left: 0,
            right: 0,
            bottom: Space.md + pad.bottom,
            child: IgnorePointer(child: Center(child: _KeyHint())),
          ),
      ],
    );
  }
}

class _KeyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '← →  or  A D  to move   ·   Space / W / ↑ to jump',
        style: context.text.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class ObbyFlameGame extends FlameGame with KeyboardEvents {
  ObbyFlameGame({
    required this.client,
    required this.dark,
    required this.haptics,
    this.autopilot = false,
  });

  final BrickfolkClient client;
  bool dark;
  final bool haptics;

  /// The test driver owns the input stream, so the view's periodic held-state
  /// keepalive must not overwrite it.
  final bool autopilot;

  final course = ObbyCourse.instance;
  final _keys = <String>{};
  bool _tLeft = false, _tRight = false, _tJump = false;
  ObbyInput _lastSent = ObbyInput.none;
  double _sinceSent = 0;
  double _camX = 0;
  double _camY = 0;
  double _time = 0;
  final _particles = <_Particle>[];
  final _rng = math.Random(7);
  int _lastEventTick = -1;
  final Map<String, ObbyPlayerState> _lastStates = {};

  static const double _ppu = 48; // pixels per world unit at reference height

  double get _scale => (size.y / 14).clamp(_ppu * 0.55, _ppu * 1.3);

  /// World units the camera leads the player by, so they sit left of centre
  /// with room to see ahead; shrinks on narrow viewports so the local player
  /// always stays on screen.
  double get _camLead =>
      hasLayout ? (size.x / _scale * 0.2).clamp(0.0, 4.0) : 4;

  @override
  Color backgroundColor() =>
      dark ? const Color(0xFF0E1428) : const Color(0xFF9CC9FF);

  @override
  Future<void> onLoad() async {
    add(_SceneComponent(this));
    client.gameEvents.listen(_onEvent);
  }

  void _onEvent(Map<String, Object?> e) {
    final kind = e['kind'];
    final who = e['player'];
    final mine = who == client.myId;
    final s = _lastStates[who];
    if (s == null) return;
    switch (kind) {
      case 'checkpoint':
        _burst(s.x, s.y + 0.8, BrickColors.mint, 18);
        if (mine && haptics) HapticFeedback.mediumImpact();
      case 'death':
        _burst(s.x, s.y + 0.8, BrickColors.cherry, 26);
        if (mine && haptics) HapticFeedback.heavyImpact();
      case 'finish':
        _burst(s.x, s.y + 1, BrickColors.sun, 40);
        if (mine && haptics) HapticFeedback.heavyImpact();
      case 'land':
        _burst(s.x, s.y, Colors.white70, 5, speed: 2, up: false);
    }
  }

  void _burst(
    double x,
    double y,
    Color color,
    int n, {
    double speed = 6,
    bool up = true,
  }) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = speed * (0.4 + _rng.nextDouble());
      _particles.add(
        _Particle(
          x: x,
          y: y,
          vx: math.cos(a) * sp,
          vy: up ? math.sin(a).abs() * sp + 2 : math.sin(a) * sp * 0.3,
          life: 0.5 + _rng.nextDouble() * 0.4,
          color: color,
          size: 0.1 + _rng.nextDouble() * 0.15,
        ),
      );
    }
  }

  void setTouch({bool? left, bool? right, bool? jump}) {
    _tLeft = left ?? _tLeft;
    _tRight = right ?? _tRight;
    _tJump = jump ?? _tJump;
    _pushInput(force: true);
  }

  ObbyInput get _input => ObbyInput(
    left: _tLeft || _keys.contains('left'),
    right: _tRight || _keys.contains('right'),
    jump: _tJump || _keys.contains('jump'),
  );

  void _pushInput({bool force = false}) {
    final i = _input;
    if (!force &&
        i.left == _lastSent.left &&
        i.right == _lastSent.right &&
        i.jump == _lastSent.jump) {
      return;
    }
    _lastSent = i;
    _sinceSent = 0;
    client.sendInput(i.toJson());
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    String? name(LogicalKeyboardKey k) {
      if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
        return 'left';
      }
      if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
        return 'right';
      }
      if (k == LogicalKeyboardKey.space ||
          k == LogicalKeyboardKey.arrowUp ||
          k == LogicalKeyboardKey.keyW) {
        return 'jump';
      }
      return null;
    }

    _keys
      ..clear()
      ..addAll(keysPressed.map(name).whereType<String>());
    _pushInput();
    return name(event.logicalKey) == null
        ? KeyEventResult.ignored
        : KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _sinceSent += dt;
    if (!autopilot && _sinceSent > 0.5) _pushInput(force: true);
    for (final p in _particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy -= 14 * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);

    final frame = client.frame;
    if (frame != null && frame.tick != _lastEventTick) {
      _lastEventTick = frame.tick;
      final blend = FrameBlend(
        frame,
        client.previousFrame,
        DateTime.now().millisecondsSinceEpoch,
      );
      blend.players.forEach(
        (id, packed) => _lastStates[id] = ObbyPlayerState.fromPacked(packed),
      );
    }
    final me = _lastStates[client.myId];
    if (me != null) {
      final targetX = me.x + _camLead;
      final targetY = math.max(me.y, 0) + 3;
      final k = 1 - math.exp(-dt * 8);
      _camX += (targetX - _camX) * k;
      _camY += (targetY - _camY) * k;
    }
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  });
  double x, y, vx, vy, life, size;
  final Color color;
}

class _SceneComponent extends Component {
  _SceneComponent(this.game);

  final ObbyFlameGame game;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final w = size.x;
    final h = size.y;
    final scale = game._scale;
    final camX = game._camX;
    final camY = game._camY;

    double sx(double x) => w / 2 + (x - camX) * scale;
    double sy(double y) => h / 2 - (y - camY) * scale;

    _paintBackdrop(canvas, w, h, camX, scale);

    // Platforms
    for (final p in game.course.platforms) {
      final r = Rect.fromLTRB(sx(p.x), sy(p.y + p.h), sx(p.x + p.w), sy(p.y));
      if (r.right < -40 || r.left > w + 40) continue;
      _paintPlatform(canvas, r, p.kind, scale);
    }
    // Checkpoints flags
    for (var i = 0; i < game.course.checkpoints.length; i++) {
      final c = game.course.checkpoints[i];
      _paintFlag(
        canvas,
        Offset(sx(c.x), sy(c.y)),
        scale,
        BrickColors.mint,
        '${i + 1}',
      );
    }
    _paintFlag(
      canvas,
      Offset(sx(game.course.finishX), sy(_groundYAt(game.course.finishX))),
      scale,
      BrickColors.sun,
      null,
      finish: true,
    );

    // Players
    final frame = game.client.frame;
    if (frame != null) {
      final blend = FrameBlend(
        frame,
        game.client.previousFrame,
        DateTime.now().millisecondsSinceEpoch,
      );
      final members = {
        for (final m in game.client.room?.members ?? const <RoomMember>[])
          m.player.id: m.player,
      };
      final ids = blend.players.keys.toList()..sort();
      // Draw remote players first, local last (on top).
      ids.sort(
        (a, b) => a == game.client.myId
            ? 1
            : (b == game.client.myId ? -1 : a.compareTo(b)),
      );
      for (final id in ids) {
        final s = ObbyPlayerState.fromPacked(blend.players[id]!);
        final pos = blend.obbyPos(id, s);
        final member = members[id];
        final avatar = member?.avatar ?? const Avatar();
        final mine = id == game.client.myId;
        final dying = s.respawnUntilTick > frame.tick;
        final ph = ObbySim.height * scale;
        final pw = ph * 0.62;
        final feet = Offset(sx(pos.x), sy(pos.y));
        final rect = Rect.fromLTWH(feet.dx - pw / 2, feet.dy - ph, pw, ph);
        // Shadow
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(feet.dx, feet.dy + 2),
            width: pw * 0.9,
            height: ph * 0.12,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.22),
        );
        final walk = s.grounded && s.vx.abs() > 0.5
            ? math.sin(game._time * 14)
            : (s.grounded ? 0.0 : 0.6);
        canvas.save();
        if (dying) {
          final t = ((s.respawnUntilTick - frame.tick) / ObbySim.respawnTicks)
              .clamp(0.0, 1.0);
          canvas.translate(feet.dx, feet.dy - ph / 2);
          canvas.rotate((1 - t) * math.pi * 0.5 * (s.facingRight ? 1 : -1));
          canvas.translate(-feet.dx, -(feet.dy - ph / 2));
        }
        paintAvatar(
          canvas,
          rect,
          avatar,
          facingRight: s.facingRight,
          walk: walk,
          alpha: dying ? 0.6 : (mine ? 1 : 0.92),
        );
        canvas.restore();
        _paintNameTag(
          canvas,
          Offset(feet.dx, rect.top - 6 * scale / 48),
          member?.name ?? '…',
          mine,
          member?.isBot ?? false,
          scale,
        );
        if (s.finished) {
          _paintCrown(
            canvas,
            Offset(feet.dx, rect.top - 22 * scale / 48),
            scale,
          );
        }
      }
    }

    // Particles
    for (final p in game._particles) {
      final a = (p.life / 0.9).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(sx(p.x), sy(p.y)),
            width: p.size * scale,
            height: p.size * scale,
          ),
          Radius.circular(p.size * scale * 0.3),
        ),
        Paint()..color = p.color.withValues(alpha: a),
      );
    }

    // Void fog at the bottom
    final fogTop = sy(ObbySim.killY + 2);
    if (fogTop < h) {
      canvas.drawRect(
        Rect.fromLTRB(0, math.max(fogTop, 0), w, h),
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, fogTop), Offset(0, h), [
            Colors.transparent,
            (game.dark ? const Color(0xFF05070F) : const Color(0xFF6C7FB0))
                .withValues(alpha: 0.9),
          ]),
      );
    }
  }

  double _groundYAt(double x) {
    double best = 0;
    for (final p in game.course.platforms) {
      if (x >= p.x && x <= p.x + p.w) best = math.max(best, p.y + p.h);
    }
    return best;
  }

  void _paintBackdrop(
    Canvas canvas,
    double w,
    double h,
    double camX,
    double scale,
  ) {
    final dark = game.dark;
    final sky = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, h),
        dark
            ? [
                const Color(0xFF101A54),
                const Color(0xFF244D8E),
                const Color(0xFF348BAD),
              ]
            : [
                const Color(0xFF3479E2),
                const Color(0xFF76CBED),
                const Color(0xFFD4F4F4),
              ],
        [0, 0.55, 1],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    final sunCenter = Offset(w * 0.78, h * 0.2);
    canvas.drawCircle(
      sunCenter,
      h * 0.11,
      Paint()
        ..shader = ui.Gradient.radial(sunCenter, h * 0.11, [
          const Color(0xFFFFEFBD),
          const Color(0x00FFE6A0),
        ]),
    );
    canvas.drawCircle(
      sunCenter,
      h * 0.055,
      Paint()..color = const Color(0xFFFFE5A0),
    );
    final portalOffset = (camX * scale * 0.1) % (w + 600);
    for (var i = 0; i < 3; i++) {
      final center = Offset(i * 600 - portalOffset + 280, h * 0.48);
      final ring = Rect.fromCenter(center: center, width: 170, height: 230);
      canvas.drawOval(
        ring.shift(const Offset(5, 8)),
        Paint()
          ..color = const Color(0xFF945274).withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 21,
      );
      canvas.drawOval(
        ring,
        Paint()
          ..color = BrickColors.brick.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 17,
      );
    }

    // Distant skyline (original silhouette), parallax 0.2
    final skyline = Paint()
      ..color = (dark ? const Color(0xFF225B83) : const Color(0xFF309CB7))
          .withValues(alpha: 0.7);
    final base = h * 0.78;
    final off = (camX * scale * 0.2) % (w + 200);
    for (var i = -1; i < 8; i++) {
      final bx = i * 180.0 - off + 60;
      final bh = 60.0 + ((i * 37) % 90);
      final bw = 70.0 + ((i * 53) % 60);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, base - bh, bw, bh + 200),
          const Radius.circular(6),
        ),
        skyline,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, base - bh, bw, 6),
          const Radius.circular(3),
        ),
        Paint()..color = BrickColors.mint.withValues(alpha: 0.3),
      );
      final windows = Paint()
        ..color = (dark ? BrickColors.sun : Colors.white).withValues(
          alpha: dark ? 0.35 : 0.5,
        );
      for (var r = 0; r < (bh / 16).floor(); r++) {
        for (var c = 0; c < (bw / 18).floor(); c++) {
          if ((r * 7 + c * 3 + i) % 4 == 0) continue;
          canvas.drawRect(
            Rect.fromLTWH(bx + 8 + c * 18, base - bh + 10 + r * 16, 8, 8),
            windows,
          );
        }
      }
    }
    // Clouds, parallax 0.4
    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: dark ? 0.08 : 0.55);
    final coff = (camX * scale * 0.4) % (w + 300);
    for (var i = -1; i < 6; i++) {
      final cx = i * 260.0 - coff + 100;
      final cy = h * (0.12 + ((i * 29) % 30) / 100);
      canvas.drawCircle(Offset(cx, cy), 26, cloud);
      canvas.drawCircle(Offset(cx + 28, cy - 10), 32, cloud);
      canvas.drawCircle(Offset(cx + 60, cy), 24, cloud);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 20, cy, 100, 22),
          const Radius.circular(12),
        ),
        cloud,
      );
    }
  }

  void _paintPlatform(Canvas canvas, Rect r, PlatformKind kind, double scale) {
    final (Color top, Color side) = switch (kind) {
      PlatformKind.normal => (const Color(0xFF73F0DC), const Color(0xFF168799)),
      PlatformKind.checkpoint => (BrickColors.mint, const Color(0xFF1F8A62)),
      PlatformKind.kill => (BrickColors.cherry, const Color(0xFF9E1F31)),
      PlatformKind.finish => (BrickColors.sun, const Color(0xFFB98A17)),
    };
    final radius = Radius.circular(4 * scale / 48);
    if (kind == PlatformKind.kill) {
      // Glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(6 * scale / 48), radius),
        Paint()
          ..color = BrickColors.cherry.withValues(
            alpha: 0.25 + 0.15 * math.sin(game._time * 6),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawRRect(RRect.fromRectAndRadius(r, radius), Paint()..color = side);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.shift(Offset(0, 5 * scale / 48)), radius),
      Paint()..color = const Color(0xFF0B3555).withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, radius),
      Paint()
        ..shader = ui.Gradient.linear(r.topLeft, r.bottomRight, [
          side,
          Color.lerp(side, Colors.black, 0.2)!,
        ]),
    );
    final topH = math.min(r.height * 0.6, 10 * scale / 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left, r.top, r.width, topH),
        radius,
      ),
      Paint()..color = top,
    );
    // Studs
    final stud = 8 * scale / 48;
    final n = (r.width / (stud * 2.2)).floor();
    if (n > 0 && r.height > stud * 1.2) {
      final gap = r.width / n;
      for (var i = 0; i < n; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              r.left + gap * i + gap / 2 - stud / 2,
              r.top - stud * 0.45,
              stud,
              stud * 0.5,
            ),
            Radius.circular(stud * 0.2),
          ),
          Paint()..color = Color.lerp(top, Colors.white, 0.3)!,
        );
      }
    }
    if (kind == PlatformKind.kill) {
      // Spikes
      final spikeW = 6 * scale / 48;
      final count = (r.width / spikeW).floor();
      final path = Path();
      for (var i = 0; i < count; i++) {
        final x = r.left + i * spikeW;
        path
          ..moveTo(x, r.top)
          ..lineTo(x + spikeW / 2, r.top - spikeW * 1.4)
          ..lineTo(x + spikeW, r.top)
          ..close();
      }
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFD9DE));
    }
  }

  void _paintFlag(
    Canvas canvas,
    Offset base,
    double scale,
    Color color,
    String? label, {
    bool finish = false,
  }) {
    final u = scale / 48;
    final poleH = (finish ? 64 : 48) * u;
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 1.5 * u, base.dy - poleH, 3 * u, poleH),
      Paint()..color = const Color(0xFFE9EDF5),
    );
    final wave = math.sin(game._time * 4 + base.dx * 0.01) * 3 * u;
    final flag = Path()
      ..moveTo(base.dx, base.dy - poleH)
      ..lineTo(base.dx + 28 * u, base.dy - poleH + 8 * u + wave)
      ..lineTo(base.dx, base.dy - poleH + 18 * u)
      ..close();
    canvas.drawPath(flag, Paint()..color = color);
    if (finish) {
      // Checker pattern
      final clip = Path()..addPath(flag, Offset.zero);
      canvas.save();
      canvas.clipPath(clip);
      final dark = Paint()..color = Colors.black.withValues(alpha: 0.5);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 5; c++) {
          if ((r + c) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(
                base.dx + c * 6 * u,
                base.dy - poleH + r * 6 * u,
                6 * u,
                6 * u,
              ),
              dark,
            );
          }
        }
      }
      canvas.restore();
    }
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9 * u,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(base.dx + 6 * u, base.dy - poleH + 4 * u));
    }
  }

  void _paintNameTag(
    Canvas canvas,
    Offset above,
    String name,
    bool mine,
    bool bot,
    double scale,
  ) {
    final u = scale / 48;
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10 * u,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromCenter(
      center: Offset(above.dx, above.dy - tp.height / 2 - 4 * u),
      width: tp.width + 12 * u,
      height: tp.height + 6 * u,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(r.height / 2)),
      Paint()
        ..color =
            (mine
                    ? BrickColors.sky
                    : (bot ? const Color(0xFF6B7280) : Colors.black))
                .withValues(alpha: mine ? 0.95 : 0.6),
    );
    tp.paint(canvas, Offset(r.left + 6 * u, r.top + 3 * u));
    if (mine) {
      final tri = Path()
        ..moveTo(r.center.dx - 4 * u, r.bottom)
        ..lineTo(r.center.dx + 4 * u, r.bottom)
        ..lineTo(r.center.dx, r.bottom + 4 * u)
        ..close();
      canvas.drawPath(
        tri,
        Paint()..color = BrickColors.sky.withValues(alpha: 0.95),
      );
    }
  }

  void _paintCrown(Canvas canvas, Offset c, double scale) {
    final u = scale / 48;
    final path = Path()
      ..moveTo(c.dx - 9 * u, c.dy + 4 * u)
      ..lineTo(c.dx - 9 * u, c.dy - 4 * u)
      ..lineTo(c.dx - 4 * u, c.dy)
      ..lineTo(c.dx, c.dy - 7 * u)
      ..lineTo(c.dx + 4 * u, c.dy)
      ..lineTo(c.dx + 9 * u, c.dy - 4 * u)
      ..lineTo(c.dx + 9 * u, c.dy + 4 * u)
      ..close();
    canvas.drawPath(path, Paint()..color = BrickColors.sun);
  }
}
