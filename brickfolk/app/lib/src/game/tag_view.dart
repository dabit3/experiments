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

/// Top-down freeze tag arena.
class TagView extends StatefulWidget {
  const TagView({super.key});

  @override
  State<TagView> createState() => _TagViewState();
}

class _TagViewState extends State<TagView> {
  TagFlameGame? _game;
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
    _game ??= TagFlameGame(
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
        if (touch)
          Positioned(
            left: Space.lg + pad.left,
            bottom: Space.lg + pad.bottom,
            child: VirtualJoystick(onChanged: _game!.setJoystick),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: Space.md + pad.bottom,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'WASD / arrow keys to move · touch a frozen friend to thaw them',
                    style: context.text.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class TagFlameGame extends FlameGame with KeyboardEvents {
  TagFlameGame({
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
  final arena = TagArena.instance;

  final _keys = <String>{};
  double _jx = 0, _jy = 0;
  TagInput _lastSent = TagInput.none;
  double _sinceSent = 0;
  double _time = 0;
  final _sparks = <_Spark>[];
  final _rng = math.Random(11);
  final Map<String, TagPlayerState> _states = {};
  int _lastTick = -1;

  @override
  Color backgroundColor() =>
      dark ? const Color(0xFF0B1B2B) : const Color(0xFFCFEFF8);

  @override
  Future<void> onLoad() async {
    add(_ArenaComponent(this));
    client.gameEvents.listen(_onEvent);
  }

  void _onEvent(Map<String, Object?> e) {
    final s = _states[e['player']];
    final mine = e['player'] == client.myId;
    switch (e['kind']) {
      case 'freeze':
        if (s != null) _spark(s.x, s.y, const Color(0xFFBDEBFF), 20);
        if (mine && haptics) HapticFeedback.heavyImpact();
      case 'thaw':
        if (s != null) _spark(s.x, s.y, BrickColors.sun, 16);
        if (mine && haptics) HapticFeedback.mediumImpact();
      case 'roundStart':
        if (haptics) HapticFeedback.selectionClick();
    }
  }

  void _spark(double x, double y, Color c, int n) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 2 + _rng.nextDouble() * 4;
      _sparks.add(
        _Spark(
          x,
          y,
          math.cos(a) * sp,
          math.sin(a) * sp,
          0.4 + _rng.nextDouble() * 0.4,
          c,
        ),
      );
    }
  }

  void setJoystick(double dx, double dy) {
    _jx = dx;
    _jy = dy;
    _push(force: true);
  }

  TagInput get _input {
    if (_jx != 0 || _jy != 0) return TagInput(_jx, _jy);
    final d = directionFromKeys(_keys);
    return TagInput(d.dx, d.dy);
  }

  void _push({bool force = false}) {
    final i = _input;
    if (!force &&
        (i.dx - _lastSent.dx).abs() < 0.01 &&
        (i.dy - _lastSent.dy).abs() < 0.01) {
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
      if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
        return 'up';
      }
      if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
        return 'down';
      }
      return null;
    }

    _keys
      ..clear()
      ..addAll(keysPressed.map(name).whereType<String>());
    _push();
    return name(event.logicalKey) == null
        ? KeyEventResult.ignored
        : KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _sinceSent += dt;
    if (!autopilot && _sinceSent > 0.5) _push(force: true);
    for (final s in _sparks) {
      s.life -= dt;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
    }
    _sparks.removeWhere((s) => s.life <= 0);
    final f = client.frame;
    if (f != null && f.tick != _lastTick) {
      _lastTick = f.tick;
      final blend = FrameBlend(
        f,
        client.previousFrame,
        DateTime.now().millisecondsSinceEpoch,
      );
      blend.players.forEach(
        (id, p) => _states[id] = TagPlayerState.fromPacked(p),
      );
    }
  }
}

class _Spark {
  _Spark(this.x, this.y, this.vx, this.vy, this.life, this.color);
  double x, y, vx, vy, life;
  final Color color;
}

class _ArenaComponent extends Component {
  _ArenaComponent(this.game);

  final TagFlameGame game;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final w = size.x;
    final h = size.y;
    final arena = game.arena;
    final margin = 24.0;
    final scale = math.min(
      (w - margin * 2) / arena.width,
      (h - margin * 2) / arena.height,
    );
    final ox = (w - arena.width * scale) / 2;
    final oy = (h - arena.height * scale) / 2;
    double sx(double x) => ox + x * scale;
    double sy(double y) => oy + y * scale;
    final u = scale / 40;

    // Backdrop
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h / 2),
          math.max(w, h) * 0.75,
          game.dark
              ? [const Color(0xFF14304A), const Color(0xFF0B1B2B)]
              : [const Color(0xFFE6F8FC), const Color(0xFFB7E3EF)],
        ),
    );

    // Floor
    final floor = RRect.fromRectAndRadius(
      Rect.fromLTWH(sx(0), sy(0), arena.width * scale, arena.height * scale),
      Radius.circular(12 * u),
    );
    canvas.drawRRect(
      floor.shift(Offset(0, 6 * u)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRRect(
      floor,
      Paint()
        ..color = game.dark ? const Color(0xFF1E3B57) : const Color(0xFFF4FBFD),
    );
    canvas.save();
    canvas.clipRRect(floor);
    final tile = Paint()
      ..color = (game.dark ? Colors.white : const Color(0xFF35B8D6)).withValues(
        alpha: game.dark ? 0.035 : 0.08,
      );
    for (var x = 0; x < arena.width; x++) {
      for (var y = 0; y < arena.height; y++) {
        if ((x + y) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(sx(x.toDouble()), sy(y.toDouble()), scale, scale),
            tile,
          );
        }
      }
    }
    // Center ring
    canvas.drawCircle(
      Offset(sx(arena.width / 2), sy(arena.height / 2)),
      3 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * u
        ..color = BrickColors.sky.withValues(alpha: 0.35),
    );
    canvas.restore();

    // Walls
    for (final wall in arena.walls) {
      final r = Rect.fromLTWH(
        sx(wall.x),
        sy(wall.y),
        wall.w * scale,
        wall.h * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.shift(Offset(0, 5 * u)),
          Radius.circular(5 * u),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(5 * u)),
        Paint()
          ..color = game.dark
              ? const Color(0xFF6C86A8)
              : const Color(0xFFB3C6DA),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.45),
          Radius.circular(5 * u),
        ),
        Paint()
          ..color = game.dark
              ? const Color(0xFF8CA6C8)
              : const Color(0xFFDCEAF5),
      );
    }

    // Border
    canvas.drawRRect(
      floor,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * u
        ..color = game.dark ? const Color(0xFF3C6A94) : const Color(0xFF7FC8DC),
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
      ids.sort(
        (a, b) => a == game.client.myId
            ? 1
            : (b == game.client.myId ? -1 : a.compareTo(b)),
      );
      for (final id in ids) {
        final s = TagPlayerState.fromPacked(blend.players[id]!);
        final pos = blend.tagPos(id, s);
        final member = members[id];
        final avatar = member?.avatar ?? const Avatar();
        final mine = id == game.client.myId;
        final c = Offset(sx(pos.x), sy(pos.y));
        final ph = TagSim.radius * 2 * scale * 1.5;
        final pw = ph * 0.62;
        // Tagger aura / frozen ring
        if (s.isTagger) {
          canvas.drawCircle(
            c,
            TagSim.radius * scale * (1.5 + 0.1 * math.sin(game._time * 8)),
            Paint()
              ..color = BrickColors.brick.withValues(alpha: 0.25)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * u),
          );
        }
        if (s.frozen) {
          canvas.drawCircle(
            c,
            TagSim.radius * scale * 1.35,
            Paint()..color = const Color(0xFF9EDCFF).withValues(alpha: 0.35),
          );
          if (s.thawProgress > 0) {
            canvas.drawArc(
              Rect.fromCircle(center: c, radius: TagSim.radius * scale * 1.5),
              -math.pi / 2,
              math.pi * 2 * s.thawProgress / TagSim.thawTicks,
              false,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4 * u
                ..strokeCap = StrokeCap.round
                ..color = BrickColors.sun,
            );
          }
        }
        // Shadow
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(0, ph * 0.42),
            width: pw * 1.1,
            height: ph * 0.22,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.22),
        );
        final moving =
            (s.x -
                        (blend.previousPacked(id) != null
                            ? TagPlayerState.fromPacked(
                                blend.previousPacked(id)!,
                              ).x
                            : s.x))
                    .abs() >
                0.01 ||
            (s.y -
                        (blend.previousPacked(id) != null
                            ? TagPlayerState.fromPacked(
                                blend.previousPacked(id)!,
                              ).y
                            : s.y))
                    .abs() >
                0.01;
        final rect = Rect.fromCenter(
          center: c - Offset(0, ph * 0.1),
          width: pw,
          height: ph,
        );
        paintAvatar(
          canvas,
          rect,
          avatar,
          facingRight: math.cos(s.facing) >= 0,
          walk: moving && !s.frozen ? math.sin(game._time * 14) : 0,
          frozen: s.frozen,
        );
        // Name tag
        final tp = TextPainter(
          text: TextSpan(
            text: member?.name ?? '…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10 * u,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final tagR = Rect.fromCenter(
          center: Offset(c.dx, rect.top - 9 * u),
          width: tp.width + 12 * u,
          height: tp.height + 5 * u,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(tagR, Radius.circular(tagR.height / 2)),
          Paint()
            ..color =
                (s.isTagger
                        ? BrickColors.brick
                        : (mine ? BrickColors.sky : Colors.black))
                    .withValues(alpha: mine || s.isTagger ? 0.95 : 0.6),
        );
        tp.paint(canvas, Offset(tagR.left + 6 * u, tagR.top + 2.5 * u));
        if (s.isTagger) {
          final tag = TextPainter(
            text: TextSpan(
              text: 'IT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9 * u,
                fontWeight: FontWeight.w800,
                color: BrickColors.brick,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final badge = Rect.fromCenter(
            center: Offset(c.dx, tagR.top - 8 * u),
            width: tag.width + 8 * u,
            height: tag.height + 3 * u,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(badge, Radius.circular(3 * u)),
            Paint()..color = Colors.white,
          );
          tag.paint(canvas, Offset(badge.left + 4 * u, badge.top + 1.5 * u));
        }
      }
    }

    for (final s in game._sparks) {
      canvas.drawCircle(
        Offset(sx(s.x), sy(s.y)),
        3 * u * (s.life / 0.8).clamp(0.2, 1.0),
        Paint()
          ..color = s.color.withValues(alpha: (s.life / 0.6).clamp(0.0, 1.0)),
      );
    }
  }
}
