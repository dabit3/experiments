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
import '../widgets/arcade.dart';
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
      } else if (_isActionKey(k)) {
        widget.client.setAction(true);
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
      if (_isActionKey(k) && !_keys.any(_isActionKey)) widget.client.setAction(false);
    }
    _updateMovementFromKeys();
    return KeyEventResult.handled;
  }

  static bool _isActionKey(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.keyE ||
      k == LogicalKeyboardKey.keyK ||
      k == LogicalKeyboardKey.shiftLeft ||
      k == LogicalKeyboardKey.shiftRight;

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
    final inset = MediaQuery.paddingOf(context);
    final landscapeTouch = _showTouch && size.width > size.height && size.height < 520;
    final compact = size.width < 700 || landscapeTouch;
    final me = c.me;
    final coaching = g.level.tutorial && g.running && me != null;
    final touchCoach = coaching
        ? _Coach(key: const ValueKey('touch-coach'), state: g, me: me, compact: landscapeTouch)
        : null;

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
              const ArcadeBackdrop(),
              // Kitchen.
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: inset.top + (landscapeTouch ? _Hud.landscapeHeight : _Hud.railHeight) + 8,
                    bottom:
                        inset.bottom +
                        (landscapeTouch ? 76 : (_showTouch ? (coaching ? 288 : 220) : (compact ? 76 : 64))),
                    left: inset.left + (landscapeTouch ? 112 : 8),
                    right: inset.right + (landscapeTouch ? 156 : 8),
                  ),
                  child: RepaintBoundary(child: GameWidget(game: _game)),
                ),
              ),
              // HUD: ticket rail hangs from the top edge; score and clock sit
              // in the bottom corners like a console kitchen game.
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: inset.left + PPSpace.x3,
                right: inset.right + 132,
                child: _Hud(game: g, client: c, compact: compact, dense: landscapeTouch),
              ),
              if (!_showTouch)
                Positioned(
                  left: inset.left + PPSpace.x4,
                  bottom: inset.bottom + 10,
                  child: _CoinScore(game: g, compact: compact),
                ),
              if (!_showTouch)
                Positioned(
                  right: inset.right + PPSpace.x4,
                  bottom: inset.bottom + 10,
                  child: _Stopwatch(game: g, compact: compact),
                ),
              // Bottom bar: hints / controls. Key hints sit between the coin
              // score and the stopwatch so neither corner is covered.
              if (_showTouch)
                Positioned(
                  left: inset.left,
                  right: inset.right,
                  bottom: inset.bottom + (landscapeTouch ? 92 : 0),
                  child: _TouchControls(
                    compact: landscapeTouch,
                    onMove: c.setMovement,
                    onInteract: _interact,
                    onAction: c.setAction,
                    onDash: () => c.press(dash: true),
                    onEmote: () => setState(() => _emoteOpen = !_emoteOpen),
                  ),
                )
              else
                // The tutorial coach stacks above the hints (which may wrap
                // to two rows on narrow windows) so the two never overlap.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (g.level.tutorial && g.running && me != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _Coach(state: g, me: me),
                        ),
                      Padding(
                        padding: EdgeInsets.only(left: compact ? 240 : 300, right: compact ? 96 : 116),
                        child: _KeyHints(compact: compact),
                      ),
                    ],
                  ),
                ),
              if (_showTouch)
                Positioned(
                  left: inset.left + 12,
                  right: inset.right + 12,
                  bottom: inset.bottom + (landscapeTouch ? 8 : 150),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!landscapeTouch && touchCoach != null) ...[touchCoach, const SizedBox(height: 8)],
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: FittedBox(
                              key: const ValueKey('score-hud'),
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: _CoinScore(game: g, compact: compact),
                            ),
                          ),
                          if (landscapeTouch && touchCoach != null)
                            Expanded(
                              flex: 5,
                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: touchCoach),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 8),
                          SizedBox(
                            key: const ValueKey('clock-hud'),
                            child: _Stopwatch(game: g, compact: compact),
                          ),
                        ],
                      ),
                    ],
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
                right: inset.right + PPSpace.x2,
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

/// Ticket rail: recipe cards clipped to the top edge of the screen, first
/// ticket flagged, each with an illustrated plate, ingredient pictograms and
/// a thick urgency bar along its bottom.
class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.client, required this.compact, this.dense = false});
  final GameState game;
  final GameClient client;
  final bool compact;
  final bool dense;

  static const double railHeight = 100;
  static const double landscapeHeight = 72;

  @override
  Widget build(BuildContext context) {
    final g = game;
    return SizedBox(
      height: dense ? landscapeHeight : railHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        itemCount: g.orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: PPSpace.x2),
        itemBuilder: (context, i) =>
            _Ticket(key: ValueKey(g.orders[i].id), order: g.orders[i], first: i == 0, compact: compact, dense: dense),
      ),
    );
  }
}

/// Score in a coin badge: "$ 426", with the combo multiplier riding on top.
class _CoinScore extends StatelessWidget {
  const _CoinScore({required this.game, required this.compact});
  final GameState game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final size = compact ? 30.0 : 38.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PPColor.ink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PPColor.butter.withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33102F35), offset: Offset(0, 3), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Coin(size: compact ? 34 : 44),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: PPMotion.fast,
            transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 1.25, end: 1.0).animate(a), child: c),
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
            child: KeyedSubtree(
              key: ValueKey(g.score),
              child: OutlinedText(
                '${g.score}',
                style: PPType.hud(size: size),
                fill: PPColor.butter,
                stroke: 3.5,
              ),
            ),
          ),
          if (g.combo > 1) ...[const SizedBox(width: PPSpace.x2), _ComboBadge(combo: g.combo)],
          const SizedBox(width: PPSpace.x3),
          StarRow(lit: g.stars, size: compact ? 16 : 18, dimColor: Colors.white.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo});
  final int combo;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(combo),
      tween: Tween(begin: 0, end: 1),
      duration: PPMotion.slow,
      curve: PPMotion.bounce,
      builder: (context, v, child) => Transform.scale(scale: 0.6 + 0.4 * v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: PPColor.plum,
          borderRadius: PPRadius.chip,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: PPElevation.low(Brightness.light),
        ),
        child: Text('x$combo TIP', style: PPType.caption(Colors.white).copyWith(fontSize: 12)),
      ),
    );
  }
}

/// Gold coin with a tomato-red band and a "$" — the tips currency.
class _Coin extends StatelessWidget {
  const _Coin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PPColor.coin,
        border: Border.all(color: PPColor.coinDark, width: size * 0.09),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 3), blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          '\$',
          style: PPType.hud(size: size * 0.6).copyWith(color: PPColor.coinDark),
        ),
      ),
    );
  }
}

/// Round stopwatch: blue rim, sweeping remaining-time arc, big numerals. Goes
/// red and pulses in the last 30 seconds and through overtime.
class _Stopwatch extends StatelessWidget {
  const _Stopwatch({required this.game, required this.compact});
  final GameState game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final overtime = g.phase == Phase.overtime;
    final total = overtime ? g.overtimeLeft : g.timeLeft;
    final frac = overtime
        ? total / Rules.overtimeSeconds
        : (g.level.roundSeconds == 0 ? 1.0 : total / g.level.roundSeconds);
    final mm = (total ~/ 60).toString();
    final ss = (total % 60).floor().toString().padLeft(2, '0');
    final urgent = overtime || (g.running && g.timeLeft < 30);
    final size = compact ? 56.0 : 72.0;
    final accent = urgent ? PPColor.paprika : PPColor.blueberry;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (overtime)
          Padding(
            padding: const EdgeInsets.only(right: PPSpace.x2),
            child: OutlinedText(
              'OVERTIME',
              style: PPType.hud(size: compact ? 14 : 18),
              fill: PPColor.butter,
              outline: PPColor.paprikaDark,
              stroke: 3,
            ),
          ),
        _Pulse(
          active: urgent,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _StopwatchPainter(fraction: frac.clamp(0, 1), accent: accent),
              child: Center(
                child: OutlinedText(
                  '$mm:$ss',
                  style: PPType.hud(size: size * 0.32),
                  fill: Colors.white,
                  outline: urgent ? PPColor.paprikaDark : PPColor.hudInk,
                  stroke: 2.5,
                  shadow: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StopwatchPainter extends CustomPainter {
  _StopwatchPainter({required this.fraction, required this.accent});
  final double fraction;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // Crown + button.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + Offset(0, -r * 0.92), width: r * 0.34, height: r * 0.3),
        Radius.circular(r * 0.08),
      ),
      Paint()..color = PPColor.hudInk,
    );
    canvas.drawCircle(c + Offset(0, r * 0.03), r, Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawCircle(c, r * 0.97, Paint()..color = PPColor.hudInk);
    canvas.drawCircle(c, r * 0.82, Paint()..color = Colors.white);
    // Remaining-time wedge.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.82),
      -math.pi / 2,
      -2 * math.pi * fraction,
      true,
      Paint()..color = accent.withValues(alpha: 0.85),
    );
    canvas.drawCircle(c, r * 0.6, Paint()..color = Colors.white);
    // Tick marks.
    final tick = Paint()
      ..color = PPColor.hudInk
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.66,
        c + Offset(math.cos(a), math.sin(a)) * r * 0.74,
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StopwatchPainter old) => old.fraction != fraction || old.accent != accent;
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Pulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.scale(
      scale: widget.active && !MediaQuery.disableAnimationsOf(context) ? 1 + 0.08 * _c.value : 1,
      child: child,
    ),
    child: widget.child,
  );
}

class _Ticket extends StatelessWidget {
  const _Ticket({super.key, required this.order, required this.first, required this.compact, this.dense = false});
  final Order order;
  final bool first;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final f = order.fraction;
    final col = f > 0.5 ? PPColor.basil : (f > 0.25 ? PPColor.butter : PPColor.paprika);
    final urgent = f <= 0.25;
    final width = compact ? 118.0 : 138.0;
    final barH = dense ? 6.0 : 10.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PPMotion.slow,
      curve: PPMotion.bounce,
      builder: (context, v, child) => Transform.translate(offset: Offset(0, -_Hud.railHeight * (1 - v)), child: child),
      child: Container(
        width: width,
        height: _Hud.railHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: first ? PPColor.paprika : PPColor.cream3, width: 2),
          boxShadow: PPElevation.mid(Brightness.light),
        ),
        child: Column(
          children: [
            // Header strip with the dish name (first ticket flagged).
            Container(
              height: 20,
              color: first ? PPColor.paprika : PPColor.ink,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      order.dish.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PPType.caption(Colors.white).copyWith(fontSize: 10, letterSpacing: 0.4),
                    ),
                  ),
                  if (first) const Icon(Icons.bolt_rounded, size: 12, color: PPColor.butter),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    _DishIcon(dish: order.dish, size: dense ? 28 : (compact ? 40 : 46)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        alignment: WrapAlignment.start,
                        children: [
                          for (final ing in order.dish.ingredients)
                            _IngPicto(ing, size: dense ? 12 : (compact ? 16 : 18)),
                        ],
                      ),
                    ),
                    Text(
                      '${order.remaining.ceil()}',
                      style: PPType.hud(size: compact ? 14 : 16)
                          .copyWith(color: urgent ? PPColor.paprika : PPColor.ink),
                    ),
                  ],
                ),
              ),
            ),
            // Thick urgency bar along the bottom.
            SizedBox(
              height: barH,
              child: Stack(
                children: [
                  Container(color: PPColor.cream3),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.centerLeft,
                    widthFactor: f.clamp(0, 1),
                    child: Container(color: col),
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

/// Ingredient pictogram drawn with the in-game sprite so tickets and crates match.
class _IngPicto extends StatelessWidget {
  const _IngPicto(this.ing, {required this.size});
  final Ingredient ing;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: PPColor.cream2,
      shape: BoxShape.circle,
      border: Border.all(color: PPColor.cream3),
    ),
    child: CustomPaint(painter: _IngPainter(ing)),
  );
}

class _IngPainter extends CustomPainter {
  _IngPainter(this.ing);
  final Ingredient ing;

  @override
  void paint(Canvas canvas, Size size) {
    final sp = Sprites(canvas, size.width * 1.9, 0, isDark: false);
    sp.ingredient(Offset(size.width / 2, size.height / 2), ing, chopped: false, scale: 0.75);
  }

  @override
  bool shouldRepaint(covariant _IngPainter old) => old.ing != ing;
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

/// Countdown / "COOK!" / "OVERTIME!" / "TIME'S UP!" as huge outlined text
/// that slams in and settles, no card behind it.
class _Banners extends StatelessWidget {
  const _Banners({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final g = game;
    String? text;
    Color fill = Colors.white;
    Color outline = PPColor.hudInk;
    if (g.phase == Phase.countdown) {
      final n = g.countdown.ceil();
      text = n <= 0 ? 'COOK!' : '$n';
      fill = PPColor.butter;
    } else if (g.phase == Phase.playing && g.time < 1.2) {
      text = 'COOK!';
      fill = PPColor.basil;
    } else if (g.phase == Phase.overtime && g.overtimeLeft > Rules.overtimeSeconds - 1.5) {
      text = 'OVERTIME!';
      fill = PPColor.butter;
      outline = PPColor.paprikaDark;
    } else if (g.phase == Phase.finished) {
      text = "TIME'S UP!";
      fill = PPColor.paprika;
    }
    if (text == null) return const SizedBox.shrink();
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(text),
        tween: Tween(begin: 0, end: 1),
        duration: PPMotion.slow,
        curve: PPMotion.bounce,
        builder: (context, v, child) => Transform.scale(
          scale: 0.4 + 0.6 * v,
          child: Opacity(opacity: v.clamp(0, 1), child: child),
        ),
        child: Transform.rotate(
          angle: -0.04,
          child: OutlinedText(
            text,
            style: PPType.hud(size: compact ? 64 : 96).copyWith(letterSpacing: -2),
            fill: fill,
            outline: outline,
            stroke: compact ? 5 : 7,
          ),
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
    this.compact = false,
  });
  final void Function(double dx, double dy) onMove;
  final VoidCallback onInteract;
  final void Function(bool down) onAction;
  final VoidCallback onDash;
  final VoidCallback onEmote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 6 : PPSpace.x5, 0, compact ? 6 : PPSpace.x5, PPSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: compact ? 100 : 128,
            height: compact ? 100 : 128,
            child: FittedBox(child: _Joystick(onMove: onMove)),
          ),
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
                    size: compact ? 44 : 52,
                    onTap: onEmote,
                  ),
                  const SizedBox(width: PPSpace.x3),
                  _ActionButton(
                    label: 'Dash',
                    icon: Icons.bolt_rounded,
                    color: PPColor.blueberry,
                    size: compact ? 48 : 60,
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
                    size: compact ? 52 : 64,
                    onTap: () => onAction(true),
                    onRelease: () => onAction(false),
                  ),
                  const SizedBox(width: PPSpace.x3),
                  _ActionButton(
                    label: 'Grab',
                    icon: Icons.back_hand_rounded,
                    color: PPColor.paprika,
                    size: compact ? 58 : 76,
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
    this.onRelease,
  });
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final VoidCallback? onRelease;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _down = false;

  void _release() {
    if (!_down) return;
    setState(() => _down = false);
    widget.onRelease?.call();
  }

  @override
  void dispose() {
    if (_down) widget.onRelease?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _down = true);
        widget.onTap();
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: PPMotion.fast,
        child: Semantics(
          button: true,
          label: widget.label,
          excludeSemantics: true,
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
                if (widget.size >= 48)
                  Text(
                    widget.label.toUpperCase(),
                    style: PPType.caption(Colors.white).copyWith(fontSize: widget.size < 60 ? 8 : 9),
                  ),
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
  const _Coach({super.key, required this.state, required this.me, this.compact = false});
  final GameState state;
  final Chef me;
  final bool compact;

  (IconData, String) _hint() {
    final held = me.held;
    if (held == null) {
      var cookedPot = false;
      var dirty = false;
      var rawOnBoard = false;
      var choppedOnBoard = false;
      for (final (_, _, t) in state.allTiles()) {
        final item = t.item;
        if (item is Pot && item.cook >= 1 && !item.burnt) cookedPot = true;
        if (item is PlateStack && item.dirty && t.type != TileType.sink) dirty = true;
        if (t.type == TileType.board && item is IngredientItem) {
          if (item.chopped) {
            choppedOnBoard = true;
          } else {
            rawOnBoard = true;
          }
        }
      }
      if (cookedPot) return (Icons.dinner_dining_rounded, 'Soup is ready! Grab a clean plate from the rack.');
      if (dirty) return (Icons.water_drop_rounded, 'Dirty plates are back — carry them to the sink and hold Action.');
      if (rawOnBoard) return (Icons.content_cut_rounded, 'Face the board and hold Action until the bar fills.');
      if (choppedOnBoard) return (Icons.soup_kitchen_rounded, 'Grab the chopped tomato and drop it in the pot.');
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
        margin: EdgeInsets.symmetric(horizontal: compact ? 0 : PPSpace.x4),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : PPSpace.x4, vertical: compact ? 8 : PPSpace.x3),
        decoration: BoxDecoration(
          color: s.text.withValues(alpha: 0.92),
          borderRadius: PPRadius.card,
          boxShadow: PPElevation.mid(s.brightness),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: PPColor.butter, size: compact ? 18 : 22),
            SizedBox(width: compact ? 8 : PPSpace.x3),
            Flexible(
              child: Text(text, style: PPType.small(s.bg).copyWith(fontSize: compact ? 12 : 14)),
            ),
          ],
        ),
      ),
    );
  }
}
