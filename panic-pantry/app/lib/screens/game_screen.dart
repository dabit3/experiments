import 'dart:math' as math;

import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panic_pantry_core/panic_pantry_core.dart';

import '../config.dart';
import '../game/kitchen_game.dart';
import '../game/sprites.dart';
import '../net/client.dart';
import '../theme/tokens.dart';
import '../widgets/ui.dart';

/// Gameplay: Flame canvas + HUD overlay + platform input.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.client, required this.onToggleTheme});
  final GameClient client;
  final VoidCallback onToggleTheme;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final KitchenGame _game = KitchenGame(widget.client, isDark: false);
  final FocusNode _focus = FocusNode(debugLabel: 'kitchen');
  final Set<LogicalKeyboardKey> _keys = {};
  bool _showTouch = AppConfig.isTouch;
  bool _emoteOpen = false;
  bool _menuOpen = false;
  int _lastCountdown = -1;

  @override
  void initState() {
    super.initState();
    widget.client.addListener(_onClient);
  }

  @override
  void dispose() {
    widget.client.removeListener(_onClient);
    _focus.dispose();
    super.dispose();
  }

  void _onClient() {
    final g = widget.client.game;
    if (g == null) return;
    final cd = g.phase == Phase.countdown ? g.countdown.ceil() : -1;
    if (cd != _lastCountdown) {
      _lastCountdown = cd;
      if (cd > 0) HapticFeedback.selectionClick();
    }
    for (final e in widget.client.pendingEvents) {
      switch (e.kind) {
        case 'served':
          HapticFeedback.mediumImpact();
        case 'burnt' || 'fire' || 'expired':
          HapticFeedback.heavyImpact();
      }
    }
    setState(() {});
  }

  // ---- Keyboard ------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final k = e.logicalKey;
    if (e is KeyDownEvent) {
      if (_keys.contains(k)) return KeyEventResult.handled;
      _keys.add(k);
      if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.keyJ || k == LogicalKeyboardKey.enter) {
        _interact();
      } else if (k == LogicalKeyboardKey.keyE ||
          k == LogicalKeyboardKey.keyK ||
          k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight) {
        widget.client.press(action: true);
      } else if (k == LogicalKeyboardKey.keyF || k == LogicalKeyboardKey.keyL) {
        widget.client.press(dash: true);
      } else if (k == LogicalKeyboardKey.escape) {
        setState(() => _menuOpen = !_menuOpen);
      } else if (k == LogicalKeyboardKey.keyT) {
        setState(() => _emoteOpen = !_emoteOpen);
      } else {
        final n = int.tryParse(k.keyLabel);
        if (n != null && n >= 1 && n <= kEmotes.length) widget.client.press(emote: n - 1);
      }
    } else if (e is KeyUpEvent) {
      _keys.remove(k);
    }
    _updateMovementFromKeys();
    return KeyEventResult.handled;
  }

  void _updateMovementFromKeys() {
    double dx = 0, dy = 0;
    bool has(LogicalKeyboardKey a, LogicalKeyboardKey b) => _keys.contains(a) || _keys.contains(b);
    if (has(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA)) dx -= 1;
    if (has(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD)) dx += 1;
    if (has(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW)) dy -= 1;
    if (has(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)) dy += 1;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > 1) {
      dx /= len;
      dy /= len;
    }
    widget.client.setMovement(dx, dy);
  }

  void _interact() {
    _game.predictInteract();
    widget.client.press(interact: true);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    _game.isDark = s.isDark;
    final c = widget.client;
    final g = c.game;
    if (g == null) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;
    final me = c.me;

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _focus.requestFocus(),
        child: Scaffold(
          backgroundColor: s.bg2,
          body: Stack(
            children: [
              // Kitchen.
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + (compact ? 96 : 84),
                    bottom: MediaQuery.paddingOf(context).bottom + (_showTouch ? 150 : 44),
                    left: 8,
                    right: 8,
                  ),
                  child: RepaintBoundary(child: GameWidget(game: _game)),
                ),
              ),
              // HUD.
              Positioned(
                top: MediaQuery.paddingOf(context).top + PPSpace.x2,
                left: PPSpace.x3,
                right: PPSpace.x3,
                child: _Hud(game: g, client: c, compact: compact),
              ),
              // Bottom bar: hints / controls.
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.paddingOf(context).bottom,
                child: _showTouch
                    ? _TouchControls(
                        onMove: c.setMovement,
                        onInteract: _interact,
                        onAction: () => c.press(action: true),
                        onDash: () => c.press(dash: true),
                        onEmote: () => setState(() => _emoteOpen = !_emoteOpen),
                      )
                    : _KeyHints(compact: compact),
              ),
              // Tutorial coach marks.
              if (g.level.tutorial && g.running && me != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + (_showTouch ? 156 : 52),
                  child: Center(
                    child: _Coach(state: g, me: me),
                  ),
                ),
              // Countdown / overtime / go banners.
              Positioned.fill(
                child: IgnorePointer(child: _Banners(game: g)),
              ),
              // Emote wheel.
              if (_emoteOpen)
                Positioned.fill(
                  child: _EmoteWheel(
                    onPick: (i) {
                      c.press(emote: i);
                      setState(() => _emoteOpen = false);
                    },
                    onClose: () => setState(() => _emoteOpen = false),
                  ),
                ),
              // Top-right utility buttons.
              Positioned(
                top: MediaQuery.paddingOf(context).top + PPSpace.x2,
                right: PPSpace.x2,
                child: Row(
                  children: [
                    _RoundIcon(
                      icon: Icons.emoji_emotions_rounded,
                      tooltip: 'Emote (T)',
                      onTap: () => setState(() => _emoteOpen = !_emoteOpen),
                    ),
                    const SizedBox(width: 6),
                    _RoundIcon(
                      icon: _showTouch ? Icons.keyboard_rounded : Icons.gamepad_rounded,
                      tooltip: 'Toggle on-screen controls',
                      onTap: () => setState(() => _showTouch = !_showTouch),
                    ),
                    const SizedBox(width: 6),
                    _RoundIcon(
                      icon: Icons.menu_rounded,
                      tooltip: 'Menu (Esc)',
                      onTap: () => setState(() => _menuOpen = true),
                    ),
                  ],
                ),
              ),
              if (_menuOpen)
                Positioned.fill(
                  child: _Menu(
                    onResume: () => setState(() => _menuOpen = false),
                    onLeave: c.leaveRoom,
                    onToggleTheme: widget.onToggleTheme,
                    rtt: c.rttMs,
                    code: c.room?.code ?? '',
                  ),
                ),
              if (c.conn == ConnState.reconnecting)
                Positioned.fill(
                  child: Container(
                    color: s.bg.withValues(alpha: 0.75),
                    child: const StatePanel(
                      title: 'Reconnecting…',
                      message: 'Hold tight — your seat is saved and the kitchen keeps cooking.',
                      busy: true,
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

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: s.surface.withValues(alpha: 0.9),
        shape: CircleBorder(side: BorderSide(color: s.outline)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 18, color: s.text2)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------- HUD

class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.client, required this.compact});
  final GameState game;
  final GameClient client;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final total = g.phase == Phase.overtime ? g.overtimeLeft : g.timeLeft;
    final mm = (total ~/ 60).toString();
    final ss = (total % 60).floor().toString().padLeft(2, '0');
    final urgent = g.phase == Phase.overtime || (g.running && g.timeLeft < 30);
    final rail = SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: g.orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: PPSpace.x2),
        itemBuilder: (context, i) => _Ticket(order: g.orders[i], first: i == 0),
      ),
    );
    final stats = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Stat(label: 'Score', value: '${g.score}', accent: PPColor.butter, big: true),
        const SizedBox(width: PPSpace.x2),
        if (g.combo > 1)
          _Stat(label: 'Combo', value: 'x${g.combo}', accent: PPColor.plum)
        else
          _Stat(label: 'Stars', value: '★' * g.stars + '☆' * (3 - g.stars), accent: PPColor.butter),
        const SizedBox(width: PPSpace.x2),
        _Stat(
          label: g.phase == Phase.overtime ? 'Overtime' : 'Time',
          value: '$mm:$ss',
          accent: urgent ? PPColor.paprika : PPColor.blueberry,
          pulse: urgent,
          animate: false,
        ),
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: stats),
              const SizedBox(width: 120),
            ],
          ),
          const SizedBox(height: 6),
          rail,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: rail),
        const SizedBox(width: PPSpace.x3),
        stats,
        const SizedBox(width: 132),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.accent,
    this.big = false,
    this.pulse = false,
    this.animate = true,
  });
  final String label;
  final String value;
  final Color accent;
  final bool big;
  final bool pulse;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PPSpace.x3, vertical: 6),
      decoration: BoxDecoration(
        color: s.surface.withValues(alpha: 0.92),
        borderRadius: PPRadius.button,
        border: Border.all(color: pulse ? accent : s.outline, width: pulse ? 2 : 1),
        boxShadow: PPElevation.low(s.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: PPType.caption(s.text3).copyWith(fontSize: 10)),
          if (animate)
            AnimatedSwitcher(
              duration: PPMotion.fast,
              transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 1.25, end: 1.0).animate(a), child: c),
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
              child: Text(
                value,
                key: ValueKey(value),
                style: PPType.numeric(accent, size: big ? 24 : 20),
              ),
            )
          else
            Text(value, style: PPType.numeric(accent, size: big ? 24 : 20)),
        ],
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket({required this.order, required this.first});
  final Order order;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final f = order.fraction;
    final col = f > 0.5 ? PPColor.basil : (f > 0.25 ? PPColor.butter : PPColor.paprika);
    final urgent = f <= 0.25;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PPMotion.slow,
      curve: PPMotion.bounce,
      builder: (context, v, child) => Transform.scale(
        scale: 0.8 + 0.2 * v,
        alignment: Alignment.centerLeft,
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(PPSpace.x2, PPSpace.x2, PPSpace.x2, PPSpace.x2),
        decoration: BoxDecoration(
          color: s.surface.withValues(alpha: 0.95),
          borderRadius: PPRadius.button,
          border: Border.all(
            color: first ? PPColor.butter : (urgent ? PPColor.paprika : s.outline),
            width: first || urgent ? 2 : 1,
          ),
          boxShadow: PPElevation.low(s.brightness),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _DishIcon(dish: order.dish, size: 26),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.dish.label,
                    style: PPType.small(s.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (first) const Icon(Icons.bolt_rounded, size: 14, color: PPColor.butter),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final ing in order.dish.ingredients)
                  Padding(padding: const EdgeInsets.only(right: 3), child: _IngDot(ing)),
                const Spacer(),
                Text('${order.remaining.ceil()}s', style: PPType.caption(col)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: f, minHeight: 5, backgroundColor: s.outline, color: col),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngDot extends StatelessWidget {
  const _IngDot(this.ing);
  final Ingredient ing;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: ingredientColor(ing),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
    ),
  );
}

class _DishIcon extends StatelessWidget {
  const _DishIcon({required this.dish, required this.size});
  final Dish dish;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _DishPainter(dish)),
  );
}

class _DishPainter extends CustomPainter {
  _DishPainter(this.dish);
  final Dish dish;

  @override
  void paint(Canvas canvas, Size size) {
    final sp = Sprites(canvas, size.width * 1.35, 0, isDark: false);
    sp.plate(
      Offset(size.width / 2, size.height / 2 + size.height * 0.05),
      Plate(contents: [...dish.ingredients], cooked: dish.cooked),
      scale: 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DishPainter old) => old.dish != dish;
}

// -------------------------------------------------------------------- banners

class _Banners extends StatelessWidget {
  const _Banners({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final g = game;
    String? text;
    Color color = PPColor.paprika;
    if (g.phase == Phase.countdown) {
      final n = g.countdown.ceil();
      text = n <= 0 ? 'COOK!' : '$n';
    } else if (g.phase == Phase.playing && g.time < 1.2) {
      text = 'COOK!';
      color = PPColor.basil;
    } else if (g.phase == Phase.overtime && g.overtimeLeft > Rules.overtimeSeconds - 1.5) {
      text = 'OVERTIME!';
      color = PPColor.butter;
    } else if (g.phase == Phase.finished) {
      text = "TIME'S UP";
      color = PPColor.blueberry;
    }
    if (text == null) return const SizedBox.shrink();
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(text),
        tween: Tween(begin: 0, end: 1),
        duration: PPMotion.slow,
        curve: PPMotion.bounce,
        builder: (context, v, child) => Transform.scale(
          scale: 0.6 + 0.4 * v,
          child: Opacity(opacity: v.clamp(0, 1), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PPSpace.x8, vertical: PPSpace.x3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: PPRadius.card,
            boxShadow: PPElevation.high(Brightness.light),
          ),
          child: Text(text, style: PPType.display(Colors.white).copyWith(fontSize: 56)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- key hints

class _KeyHints extends StatelessWidget {
  const _KeyHints({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    Widget key(String k, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: s.outline),
            boxShadow: PPElevation.low(s.brightness),
          ),
          child: Text(k, style: PPType.mono(s.text).copyWith(fontSize: 11)),
        ),
        const SizedBox(width: 5),
        Text(label, style: PPType.small(s.text3)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(PPSpace.x4, 0, PPSpace.x4, PPSpace.x3),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: PPSpace.x4,
        runSpacing: 4,
        children: [
          key('WASD', 'Move'),
          key('Space', 'Grab / drop'),
          key('E', 'Chop · wash · spray'),
          key('F', 'Dash'),
          if (!compact) key('1–6', 'Emote'),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- touch input

class _TouchControls extends StatelessWidget {
  const _TouchControls({
    required this.onMove,
    required this.onInteract,
    required this.onAction,
    required this.onDash,
    required this.onEmote,
  });
  final void Function(double dx, double dy) onMove;
  final VoidCallback onInteract;
  final VoidCallback onAction;
  final VoidCallback onDash;
  final VoidCallback onEmote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(PPSpace.x5, 0, PPSpace.x5, PPSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Joystick(onMove: onMove),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _ActionButton(
                    label: 'Emote',
                    icon: Icons.emoji_emotions_rounded,
                    color: PPColor.plum,
                    size: 52,
                    onTap: onEmote,
                  ),
                  const SizedBox(width: PPSpace.x3),
                  _ActionButton(
                    label: 'Dash',
                    icon: Icons.bolt_rounded,
                    color: PPColor.blueberry,
                    size: 60,
                    onTap: onDash,
                  ),
                ],
              ),
              const SizedBox(height: PPSpace.x2),
              Row(
                children: [
                  _ActionButton(
                    label: 'Action',
                    icon: Icons.content_cut_rounded,
                    color: PPColor.basil,
                    size: 64,
                    onTap: onAction,
                  ),
                  const SizedBox(width: PPSpace.x3),
                  _ActionButton(
                    label: 'Grab',
                    icon: Icons.back_hand_rounded,
                    color: PPColor.paprika,
                    size: 76,
                    onTap: onInteract,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _down = true);
        widget.onTap();
      },
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: PPMotion.fast,
        child: Semantics(
          button: true,
          label: widget.label,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _down ? 1 : 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2.5),
              boxShadow: PPElevation.mid(Brightness.light),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: widget.size * 0.38),
                if (widget.size >= 60)
                  Text(widget.label.toUpperCase(), style: PPType.caption(Colors.white).copyWith(fontSize: 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Joystick extends StatefulWidget {
  const _Joystick({required this.onMove});
  final void Function(double dx, double dy) onMove;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _r = 64;
  Offset _knob = Offset.zero;

  void _update(Offset local) {
    var v = local - const Offset(_r, _r);
    final len = v.distance;
    if (len > _r * 0.7) v = v / len * _r * 0.7;
    setState(() => _knob = v);
    final n = v / (_r * 0.7);
    final dead = n.distance < 0.15 ? Offset.zero : n;
    widget.onMove(dead.dx.clamp(-1, 1), dead.dy.clamp(-1, 1));
  }

  void _release() {
    setState(() => _knob = Offset.zero);
    widget.onMove(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: Semantics(
        label: 'Move joystick',
        child: Container(
          width: _r * 2,
          height: _r * 2,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.open_with_rounded, color: Colors.white.withValues(alpha: 0.35), size: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 40),
                transform: Matrix4.translationValues(_knob.dx, _knob.dy, 0),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: PPElevation.mid(Brightness.light),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- emotes

class _EmoteWheel extends StatelessWidget {
  const _EmoteWheel({required this.onPick, required this.onClose});
  final void Function(int) onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: Enter(
          child: PPCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Quick ping', style: PPType.h2(s.text)),
                const SizedBox(height: PPSpace.x3),
                Wrap(
                  spacing: PPSpace.x2,
                  runSpacing: PPSpace.x2,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final (i, e) in kEmotes.indexed)
                      PPButton(
                        label: '${i + 1}  $e',
                        kind: PPButtonKind.secondary,
                        compact: true,
                        onPressed: () => onPick(i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- menu

class _Menu extends StatelessWidget {
  const _Menu({
    required this.onResume,
    required this.onLeave,
    required this.onToggleTheme,
    required this.rtt,
    required this.code,
  });
  final VoidCallback onResume;
  final VoidCallback onLeave;
  final VoidCallback onToggleTheme;
  final int rtt;
  final String code;

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Enter(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: PPCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kitchen $code', style: PPType.h2(s.text), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  'The match keeps running while this is open.',
                  style: PPType.small(s.text3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: PPSpace.x5),
                PPButton(
                  label: 'Back to the kitchen',
                  icon: Icons.play_arrow_rounded,
                  expand: true,
                  onPressed: onResume,
                ),
                const SizedBox(height: PPSpace.x2),
                PPButton(
                  label: 'Switch theme',
                  icon: s.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  kind: PPButtonKind.secondary,
                  expand: true,
                  onPressed: onToggleTheme,
                ),
                const SizedBox(height: PPSpace.x2),
                PPButton(
                  label: 'Leave match',
                  icon: Icons.logout_rounded,
                  kind: PPButtonKind.danger,
                  expand: true,
                  onPressed: onLeave,
                ),
                const SizedBox(height: PPSpace.x4),
                Text('Ping $rtt ms', style: PPType.caption(s.text3), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- tutorial

class _Coach extends StatelessWidget {
  const _Coach({required this.state, required this.me});
  final GameState state;
  final Chef me;

  (IconData, String) _hint() {
    final held = me.held;
    if (held == null) {
      var cookedPot = false;
      var dirty = false;
      for (final (_, _, t) in state.allTiles()) {
        if (t.item is Pot && (t.item as Pot).cook >= 1 && !(t.item as Pot).burnt) cookedPot = true;
        if (t.item is PlateStack && (t.item as PlateStack).dirty && t.type != TileType.sink) dirty = true;
      }
      if (cookedPot) return (Icons.dinner_dining_rounded, 'Soup is ready! Grab a clean plate from the rack.');
      if (dirty) return (Icons.water_drop_rounded, 'Dirty plates are back — carry them to the sink and hold Action.');
      return (Icons.inventory_2_rounded, 'Face a tomato crate and press Grab.');
    }
    switch (held) {
      case IngredientItem():
        return held.chopped
            ? (Icons.soup_kitchen_rounded, 'Drop the chopped tomato into the pot on the stove.')
            : (Icons.content_cut_rounded, 'Drop it on a cutting board, then hold Action to chop.');
      case Plate():
        return held.contents.isEmpty
            ? (Icons.soup_kitchen_rounded, 'Face the cooked pot and press Grab to pour the soup.')
            : (Icons.room_service_rounded, 'Serve it at the blue pass!');
      case Pot():
        return (Icons.local_fire_department_rounded, 'Put the pot back on a stove.');
      case PlateStack():
        return (Icons.water_drop_rounded, 'Hold Action at the sink to wash.');
      case Extinguisher():
        return (Icons.local_fire_department_rounded, 'Face the fire and hold Action to spray.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final (icon, text) = _hint();
    return AnimatedSwitcher(
      duration: PPMotion.base,
      child: Container(
        key: ValueKey(text),
        margin: const EdgeInsets.symmetric(horizontal: PPSpace.x4),
        padding: const EdgeInsets.symmetric(horizontal: PPSpace.x4, vertical: PPSpace.x3),
        decoration: BoxDecoration(
          color: s.text.withValues(alpha: 0.92),
          borderRadius: PPRadius.card,
          boxShadow: PPElevation.mid(s.brightness),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: PPColor.butter, size: 22),
            const SizedBox(width: PPSpace.x3),
            Flexible(child: Text(text, style: PPType.small(s.bg).copyWith(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
