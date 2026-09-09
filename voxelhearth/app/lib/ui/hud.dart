import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/game_controller.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'chat_panel.dart';
import 'game_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Non-interactive HUD: vitals, clock, score, target label, chat feed, roster.
class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.game,
    required this.assets,
    required this.frame,
    required this.settings,
    required this.formFactor,
  });
  final GameController game;
  final RenderAssets assets;
  final FrameNotifier frame;
  final Settings settings;
  final FormFactor formFactor;

  @override
  Widget build(BuildContext context) {
    final compact = formFactor == FormFactor.phone;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? VhSpace.sm : VhSpace.md),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: _TopLeft(game: game, frame: frame, compact: compact),
            ),
            if (settings.showFps)
              Align(
                alignment: Alignment.topCenter,
                child: _Fps(game: game, frame: frame),
              ),
            Align(
              alignment: Alignment.center,
              child: _TargetLabel(game: game, frame: frame),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: compact ? 66 : 84),
                child: _Vitals(game: game, frame: frame, compact: compact),
              ),
            ),
            if (!game.chatOpen)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: compact ? 60 : 96),
                  child: _ChatFeed(game: game, frame: frame, compact: compact),
                ),
              ),
            if (game.showRoster)
              Align(
                alignment: Alignment.topCenter,
                child: _Roster(game: game),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopLeft extends StatelessWidget {
  const _TopLeft({required this.game, required this.frame, required this.compact});
  final GameController game;
  final FrameNotifier frame;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: frame,
    builder: (context, _) {
      final s = game.session;
      final remaining = s.durationTicks > 0 ? math.max(0, s.matchEndTick - s.tick) : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DayDial(dayFraction: game.dayFraction, size: compact ? 34 : 42),
              const SizedBox(width: VhSpace.sm),
              GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                radius: VhRadius.md,
                tint: Colors.black.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.roomName.isEmpty ? s.code : s.roomName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 13 : 14,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.code,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Outfit',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_clock(s.time)} · ${s.mode == GameMode.creative ? 'Creative' : 'Survival'} · ${s.players.length} online'
                      '${remaining != null ? ' · ${_mmss(remaining)}' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontFamily: 'Outfit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VhSpace.xs),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            radius: 999,
            tint: Colors.black.withValues(alpha: 0.35),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: VhColors.gold),
                const SizedBox(width: 6),
                Text(
                  '${s.score} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Outfit',
                  ),
                ),
                if (game.flying) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.flight_rounded, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );

  static String _clock(int time) {
    final t = (time % 24000);
    final hour = ((t / 1000) + 6) % 24;
    final h = hour.floor();
    final m = ((hour - h) * 60).floor();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String _mmss(int ticks) {
    final s = ticks ~/ 20;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _DayDial extends StatelessWidget {
  const _DayDial({required this.dayFraction, required this.size});
  final double dayFraction;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _DialPainter(dayFraction)),
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.f);
  final double f;

  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    final center = Offset(r, r);
    final night = 1 - (math.sin(f * math.pi * 2 - math.pi / 2) * 0.5 + 0.5);
    final sky = Color.lerp(const Color(0xff77b7ff), const Color(0xff0a1230), night)!;
    c.drawCircle(center, r, Paint()..color = sky.withValues(alpha: 0.9));
    c.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // sun & moon on opposite sides of a wheel
    final a = f * math.pi * 2 - math.pi / 2;
    final sun = center + Offset(math.cos(a), math.sin(a)) * (r * 0.58);
    final moon = center - Offset(math.cos(a), math.sin(a)) * (r * 0.58);
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r - 1)));
    c.drawCircle(sun, r * 0.2, Paint()..color = const Color(0xffffd36b));
    c.drawCircle(moon, r * 0.17, Paint()..color = const Color(0xffe6ecff));
    c.drawCircle(moon + Offset(r * 0.06, -r * 0.05), r * 0.13, Paint()..color = sky.withValues(alpha: 0.95));
    c.restore();
    // horizon line
    c.drawLine(
      Offset(2, r),
      Offset(s.width - 2, r),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.f != f;
}

class _Fps extends StatelessWidget {
  const _Fps({required this.game, required this.frame});
  final GameController game;
  final FrameNotifier frame;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: frame,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '${game.fps.round()} fps · ${game.client.pingMs} ms',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontFamily: 'Outfit',
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

class _TargetLabel extends StatelessWidget {
  const _TargetLabel({required this.game, required this.frame});
  final GameController game;
  final FrameNotifier frame;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: frame,
    builder: (context, _) {
      String? label;
      final te = game.targetEntity;
      final t = game.target;
      if (te != null) {
        final mob = game.session.mobs[te];
        final pl = game.session.players.values.where((p) => p.id == te.toString()).firstOrNull;
        label = mob != null ? _mobName(mob.kind) : pl?.name;
      } else if (t != null && t.id != Ids.air) {
        label = Registry.block(t.id).name;
      }
      return AnimatedOpacity(
        opacity: label == null ? 0 : 1,
        duration: const Duration(milliseconds: 150),
        child: Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Text(
            label ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ),
      );
    },
  );

  static String _mobName(String kind) => switch (kind) {
    'mossling' => 'Mossling',
    'glimmerhen' => 'Glimmerhen',
    'hollowgast' => 'Hollowgast',
    'bramblecreep' => 'Bramblecreep',
    _ => kind,
  };
}

/// Health, hunger and air, drawn as original glyph rows.
class _Vitals extends StatelessWidget {
  const _Vitals({required this.game, required this.frame, required this.compact});
  final GameController game;
  final FrameNotifier frame;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: frame,
    builder: (context, _) {
      final s = game.session;
      if (s.mode == GameMode.creative) return const SizedBox.shrink();
      final w = compact ? 15.0 : 18.0;
      final width = w * 10 + 9 * 2;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.air < 300)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                width: width,
                height: w,
                child: CustomPaint(
                  painter: _GlyphRowPainter(value: s.air / 30, kind: _Glyph.air, size: w, flash: 0),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                height: w,
                child: CustomPaint(
                  painter: _GlyphRowPainter(
                    value: s.hp / 2,
                    kind: _Glyph.heart,
                    size: w,
                    flash: game.damageFlash,
                    pulse: s.hp <= 4 ? game.anim : null,
                  ),
                ),
              ),
              SizedBox(width: compact ? 18 : 28),
              SizedBox(
                width: width,
                height: w,
                child: CustomPaint(
                  painter: _GlyphRowPainter(value: s.food / 2, kind: _Glyph.food, size: w, flash: 0, mirrored: true),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

enum _Glyph { heart, food, air }

class _GlyphRowPainter extends CustomPainter {
  _GlyphRowPainter({
    required this.value,
    required this.kind,
    required this.size,
    required this.flash,
    this.pulse,
    this.mirrored = false,
  });
  final double value; // 0..10
  final _Glyph kind;
  final double size;
  final double flash;
  final double? pulse;
  final bool mirrored;

  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < 10; i++) {
      final idx = mirrored ? 9 - i : i;
      final x = idx * (size + 2);
      final fill = (value - i).clamp(0.0, 1.0);
      var dy = 0.0;
      if (pulse != null && fill > 0) dy = math.sin(pulse! * 12 + i) * 1.2;
      final rect = Rect.fromLTWH(x, dy, size, size);
      _glyph(c, rect, fill);
    }
  }

  void _glyph(Canvas c, Rect r, double fill) {
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final path = switch (kind) {
      _Glyph.heart => _heart(r),
      _Glyph.food => _drumstick(r),
      _Glyph.air => Path()..addOval(r.deflate(r.width * 0.12)),
    };
    c.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(path, bg);
    if (fill <= 0) return;
    final color = switch (kind) {
      _Glyph.heart => Color.lerp(const Color(0xffe8455a), Colors.white, flash.clamp(0, 1))!,
      _Glyph.food => const Color(0xffd98a3a),
      _Glyph.air => const Color(0xff7fd0ff),
    };
    c.save();
    c.clipPath(path);
    c.drawRect(Rect.fromLTWH(r.left, r.top, r.width * fill, r.height), Paint()..color = color);
    // highlight
    c.drawRect(
      Rect.fromLTWH(r.left + r.width * 0.2, r.top + r.height * 0.15, r.width * 0.25 * fill, r.height * 0.18),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    c.restore();
  }

  static Path _heart(Rect r) {
    final w = r.width, h = r.height;
    final p = Path();
    p.moveTo(r.left + w * 0.5, r.top + h * 0.92);
    p.cubicTo(
      r.left + w * 0.05,
      r.top + h * 0.6,
      r.left - w * 0.02,
      r.top + h * 0.12,
      r.left + w * 0.3,
      r.top + h * 0.1,
    );
    p.cubicTo(
      r.left + w * 0.42,
      r.top + h * 0.1,
      r.left + w * 0.5,
      r.top + h * 0.22,
      r.left + w * 0.5,
      r.top + h * 0.3,
    );
    p.cubicTo(
      r.left + w * 0.5,
      r.top + h * 0.22,
      r.left + w * 0.58,
      r.top + h * 0.1,
      r.left + w * 0.7,
      r.top + h * 0.1,
    );
    p.cubicTo(
      r.left + w * 1.02,
      r.top + h * 0.12,
      r.left + w * 0.95,
      r.top + h * 0.6,
      r.left + w * 0.5,
      r.top + h * 0.92,
    );
    p.close();
    return p;
  }

  static Path _drumstick(Rect r) {
    final w = r.width, h = r.height;
    final p = Path();
    p.addOval(Rect.fromLTWH(r.left + w * 0.28, r.top + h * 0.08, w * 0.66, h * 0.62));
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + w * 0.1, r.top + h * 0.55, w * 0.42, h * 0.2),
        Radius.circular(w * 0.1),
      ),
    );
    p.addOval(Rect.fromLTWH(r.left + w * 0.02, r.top + h * 0.62, w * 0.24, h * 0.26));
    return p;
  }

  @override
  bool shouldRepaint(covariant _GlyphRowPainter old) => old.value != value || old.flash != flash || old.pulse != pulse;
}

class _ChatFeed extends StatelessWidget {
  const _ChatFeed({required this.game, required this.frame, required this.compact});
  final GameController game;
  final FrameNotifier frame;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: frame,
    builder: (context, _) {
      final now = DateTime.now();
      final recent = game.session.chat.where((c) => now.difference(c.receivedAt).inSeconds < 9).toList();
      final shown = recent.length > 6 ? recent.sublist(recent.length - 6) : recent;
      if (shown.isEmpty) return const SizedBox.shrink();
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 260 : 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in shown)
              Opacity(
                opacity: (1 - (now.difference(c.receivedAt).inMilliseconds - 7000) / 2000).clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (!c.system)
                          TextSpan(
                            text: '${c.from}  ',
                            style: TextStyle(color: chatColorFor(c.from), fontWeight: FontWeight.w700),
                          ),
                        TextSpan(
                          text: c.text,
                          style: TextStyle(
                            color: c.system ? Colors.white70 : Colors.white,
                            fontStyle: c.system ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 12.5, fontFamily: 'Outfit'),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _Roster extends StatelessWidget {
  const _Roster({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final s = game.session;
    final list = s.roster.toList()..sort((a, b) => b.score.compareTo(a.score));
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: GlassPanel(
        tint: Colors.black.withValues(alpha: 0.5),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Players',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VhSpace.sm),
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      PlatformBadge(p.platform, compact: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: p.id == s.youId ? FontWeight.w800 : FontWeight.w500,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                      Text(
                        '${p.score}',
                        style: const TextStyle(color: VhColors.gold, fontWeight: FontWeight.w700, fontFamily: 'Outfit'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom hotbar; also used (non-interactive) in the results screen.
class Hotbar extends StatelessWidget {
  const Hotbar({
    super.key,
    required this.game,
    required this.assets,
    required this.frame,
    required this.formFactor,
    required this.interactive,
  });
  final GameController game;
  final RenderAssets assets;
  final FrameNotifier frame;
  final FormFactor formFactor;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final slot = formFactor == FormFactor.phone ? 40.0 : 52.0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: VhSpace.sm),
        child: Center(
          child: ListenableBuilder(
            listenable: frame,
            builder: (context, _) {
              final s = game.session;
              final held = s.inventory[s.selected];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: game.heldLabelAge < 2.2 && held.isNotEmpty ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        held.isEmpty ? '' : held.def.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Outfit',
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                        ),
                      ),
                    ),
                  ),
                  GlassPanel(
                    padding: const EdgeInsets.all(4),
                    radius: VhRadius.md,
                    tint: Colors.black.withValues(alpha: 0.4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < Inventory.hotbarSize; i++)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: interactive ? () => game.selectSlot(i) : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOut,
                              width: slot,
                              height: slot,
                              margin: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: i == s.selected
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(VhRadius.sm),
                                border: Border.all(
                                  color: i == s.selected ? VhColors.gold : Colors.white.withValues(alpha: 0.12),
                                  width: i == s.selected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(child: StackIcon(assets.atlasImage, s.inventory[i], size: slot - 10)),
                                  if (formFactor != FormFactor.phone)
                                    Positioned(
                                      left: 4,
                                      top: 2,
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          fontSize: 9,
                                          fontFamily: 'Outfit',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tappable icon buttons at the top right: chat, inventory, pause.
class HudButtons extends StatelessWidget {
  const HudButtons({
    super.key,
    required this.game,
    required this.client,
    required this.settings,
    required this.touch,
    required this.onSettings,
  });
  final GameController game;
  final GameClient client;
  final Settings settings;
  final bool touch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    if (game.inputBlocked && !game.paused) return const SizedBox.shrink();
    Widget btn(IconData icon, String tip, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tip,
        child: Material(
          color: Colors.black.withValues(alpha: 0.4),
          shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: touch ? 44 : 38,
              height: touch ? 44 : 38,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VhSpace.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(Icons.chat_bubble_outline_rounded, 'Chat (T)', () => game.setChatOpen(true)),
              btn(Icons.backpack_outlined, 'Inventory (E)', game.openInventory),
              if (game.isCreative)
                btn(
                  game.flying ? Icons.flight_land_rounded : Icons.flight_takeoff_rounded,
                  'Toggle flight (F)',
                  game.toggleFly,
                ),
              btn(Icons.pause_rounded, 'Pause (Esc)', () => game.setPaused(true)),
            ],
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.game,
    required this.client,
    required this.settings,
    required this.onSettings,
  });
  final GameController game;
  final GameClient client;
  final Settings settings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final s = game.session;
    final isHost = s.hostId == s.youId;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => game.setPaused(false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Reveal(
              child: GlassPanel(
                tint: Colors.black.withValues(alpha: 0.4),
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Wordmark(size: 26, subtitle: 'Paused'),
                      const SizedBox(height: VhSpace.lg),
                      FilledButton.icon(
                        onPressed: () => game.setPaused(false),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Resume'),
                      ),
                      const SizedBox(height: VhSpace.sm),
                      OutlinedButton.icon(
                        onPressed: onSettings,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Settings'),
                      ),
                      if (isHost) ...[
                        const SizedBox(height: VhSpace.sm),
                        OutlinedButton.icon(
                          onPressed: () => client.send({'t': Msg.endMatch}),
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('End match for everyone'),
                        ),
                      ],
                      const SizedBox(height: VhSpace.sm),
                      TextButton.icon(
                        onPressed: client.leaveRoom,
                        style: TextButton.styleFrom(foregroundColor: VhColors.danger),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Leave world'),
                      ),
                      const SizedBox(height: VhSpace.md),
                      Text(
                        isDesktopLike
                            ? 'WASD move · Space jump · Shift sprint · Ctrl sneak · E inventory · T chat · Tab players · Drag to look · Left hold: break · Right: place'
                            : 'Left stick moves · drag the world to look · hold to break · buttons place, jump and sneak',
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontFamily: 'Outfit'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeathOverlay extends StatelessWidget {
  const DeathOverlay({super.key, required this.game, required this.client});
  final GameController game;
  final GameClient client;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [const Color(0xff5a0a12).withValues(alpha: 0.75), const Color(0xff1a0306).withValues(alpha: 0.92)],
          radius: 1.1,
        ),
      ),
      alignment: Alignment.center,
      child: Reveal(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You fell',
              style: TextStyle(color: Colors.white, fontFamily: 'Fraunces', fontSize: 40, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: VhSpace.xs),
            Text(
              game.deathCause.isEmpty ? 'The hearth will bring you back.' : game.deathCause,
              style: const TextStyle(color: Colors.white70, fontFamily: 'Outfit', fontSize: 15),
            ),
            const SizedBox(height: VhSpace.xl),
            FilledButton.icon(
              onPressed: game.respawn,
              icon: const Icon(Icons.local_fire_department_rounded),
              label: const Text('Respawn at the hearth'),
            ),
            const SizedBox(height: VhSpace.sm),
            TextButton(
              onPressed: client.leaveRoom,
              child: const Text('Leave world', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    ),
  );
}
