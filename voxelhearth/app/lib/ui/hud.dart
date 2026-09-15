import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../app_state.dart';
import '../game/game_controller.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'arcade.dart';
import 'chat_panel.dart';
import 'game_screen.dart';
import 'pixel.dart';

/// Classic bottom-centre HUD: 182x22 hotbar, heart and hunger rows above
/// it, a score bar between, held-item label, chat feed and the sidebar
/// scoreboard. Everything is drawn on the GUI-pixel grid.
class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.game,
    required this.assets,
    required this.frame,
    required this.settings,
    required this.client,
  });
  final GameController game;
  final RenderAssets assets;
  final FrameNotifier frame;
  final Settings settings;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: HudPainter(
              game,
              assets,
              frame,
              client,
              s,
              touch: settings.touchControls,
              showFps: settings.showFps,
              safe: EdgeInsets.only(left: pad.left, right: pad.right),
            ),
          ),
        ),
        if (game.showRoster)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 10.0 * s),
              child: PlayerList(game: game, client: client),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- glyph bitmaps

const _heartFull = [
  '.##...##.',
  '#hr#.#rr#',
  '#hrrrrrr#',
  '#rrrrrrr#',
  '.#rrrrr#.',
  '..#rrr#..',
  '...#r#...',
  '....#....',
  '.........',
];

const _heartHalf = [
  '.##...##.',
  '#hr#.#ee#',
  '#hrreeee#',
  '#rrrreee#',
  '.#rrree#.',
  '..#rre#..',
  '...#e#...',
  '....#....',
  '.........',
];

const _heartEmpty = [
  '.##...##.',
  '#ee#.#ee#',
  '#eeeeeee#',
  '#eeeeeee#',
  '.#eeeee#.',
  '..#eee#..',
  '...#e#...',
  '....#....',
  '.........',
];

const _foodFull = [
  '.....##..',
  '....#bb#.',
  '...#bhbb#',
  '..#bbbb#.',
  '.#hbbb#..',
  '#ww#b#...',
  '#ww##....',
  '.##......',
  '.........',
];

const _foodHalf = [
  '.....##..',
  '....#ee#.',
  '...#beee#',
  '..#bbee#.',
  '.#hbbe#..',
  '#ww#b#...',
  '#ww##....',
  '.##......',
  '.........',
];

const _foodEmpty = [
  '.....##..',
  '....#ee#.',
  '...#eeee#',
  '..#eeee#.',
  '.#eeee#..',
  '#ee#e#...',
  '#ee##....',
  '.##......',
  '.........',
];

const _bubble = [
  '..#####..',
  '.#wwwww#.',
  '#w#wwwww#',
  '#wwwwwww#',
  '#wwwwwww#',
  '#wwwwwww#',
  '#wwwwwww#',
  '.#wwwww#.',
  '..#####..',
];

const _glyphColors = <String, Color>{
  '#': Color(0xff000000),
  'r': Color(0xffff1313),
  'h': Color(0xffff7b7b),
  'e': Color(0xff3f3f3f),
  'b': Color(0xffb56b2b),
  'w': Color(0xffefefef),
};

void _glyph(Canvas c, int s, List<String> rows, double x, double y, {Color? tintE}) {
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    for (var i = 0; i < row.length; i++) {
      final ch = row[i];
      if (ch == '.') continue;
      var col = _glyphColors[ch]!;
      if (ch == 'e' && tintE != null) col = tintE;
      pxRect(c, s, x + i, y + r, 1, 1, col);
    }
  }
}

// ---------------------------------------------------------------- painter

class HudPainter extends CustomPainter {
  HudPainter(
    this.g,
    this.assets,
    this.frame,
    this.client,
    this.s, {
    required this.touch,
    required this.showFps,
    this.safe = EdgeInsets.zero,
  }) : super(repaint: frame);
  final GameController g;
  final RenderAssets assets;
  final FrameNotifier frame;
  final GameClient client;
  final int s;
  final bool touch, showFps;
  final EdgeInsets safe;

  @override
  void paint(Canvas c, Size size) {
    // Keep the whole HUD inside the horizontal safe area (notch / island).
    c.translate((safe.left / s).floorToDouble() * s, 0);
    final w = ((size.width - safe.horizontal) / s).floorToDouble(), h = size.height / s;
    final sess = g.session;
    final cx = (w / 2).floorToDouble();
    final survival = !g.isCreative;

    _hotbar(c, cx, h, sess);
    if (survival) {
      _hearts(c, cx, h, sess);
      _food(c, cx, h, sess);
      if (sess.air < 300) _air(c, cx, h, sess);
      _scoreBar(c, cx, h, sess);
    }
    _heldName(c, cx, h, sess, survival);
    _actionbar(c, cx, h, survival);
    _rosterRight = 0;
    if (w >= 300 && !(touch && g.chatOpen)) _sidebar(c, w, h, sess);
    _chatFeed(c, w, h, sess);
    if (showFps) _debug(c, sess);
    _targetLabel(c, cx, h);
  }

  void _hotbar(Canvas c, double cx, double h, RoomSession sess) {
    final x = cx - 91, y = h - 22;
    pxRect(c, s, x + 1, y + 1, 180, 20, const Color(0xee102e3b));
    pxFrame(c, s, x, y, 182, 22, const Color(0xff4e7986), notch: false);
    pxRect(c, s, x + sess.selected * 20 + 1, y + 1, 22, 20, const Color(0xff365953));
    for (var i = 1; i < Inventory.hotbarSize; i++) {
      pxRect(c, s, x + i * 20, y + 1, 1, 20, const Color(0x40000000));
    }
    for (var i = 0; i < Inventory.hotbarSize; i++) {
      pxItem(c, assets.atlasImage, s, sess.inventory[i], x + 3 + i * 20, y + 3);
    }
    final sx = x - 1 + sess.selected * 20, sy = y - 1;
    pxFrame(c, s, sx, sy, 24, 24, Hearth.gold, notch: false);
    pxFrame(c, s, sx + 1, sy + 1, 22, 22, const Color(0xff80663e), notch: false);
    pxRect(c, s, sx + 1, sy + 23, 22, 1, Hearth.gold);
  }

  void _hearts(Canvas c, double cx, double h, RoomSession sess) {
    final y = h - 39;
    final hp = sess.hp.clamp(0, 20);
    final flash = g.damageFlash > 0 && (g.anim * 10).floor().isEven;
    final shake = hp <= 4 ? ((g.anim * 9 + 0.5).floor() % 3 == 0 ? 1.0 : 0.0) : 0.0;
    for (var i = 0; i < 10; i++) {
      final x = cx - 91 + i * 8;
      final yy = y - (shake > 0 && (i + (g.anim * 9).floor()) % 3 == 0 ? 1 : 0);
      final v = hp - i * 2;
      _glyph(
        c,
        s,
        v >= 2 ? _heartFull : (v == 1 ? _heartHalf : _heartEmpty),
        x,
        yy,
        tintE: flash ? const Color(0xff7f7f7f) : null,
      );
    }
  }

  void _food(Canvas c, double cx, double h, RoomSession sess) {
    final y = h - 39;
    final food = sess.food.clamp(0, 20);
    for (var i = 0; i < 10; i++) {
      final x = cx + 91 - 9 - i * 8;
      final v = food - i * 2;
      _glyph(c, s, v >= 2 ? _foodFull : (v == 1 ? _foodHalf : _foodEmpty), x, y);
    }
  }

  void _air(Canvas c, double cx, double h, RoomSession sess) {
    final y = h - 49;
    final bubbles = (sess.air / 30).ceil().clamp(0, 10);
    for (var i = 0; i < bubbles; i++) {
      final x = cx + 91 - 9 - i * 8;
      _glyph(c, s, _bubble, x, y);
    }
  }

  void _scoreBar(Canvas c, double cx, double h, RoomSession sess) {
    final x = cx - 91, y = h - 32;
    pxRect(c, s, x, y, 182, 5, const Color(0xff2b2b2b));
    pxRect(c, s, x, y + 4, 182, 1, const Color(0xff3f3f3f));
    for (var i = 0; i <= 182; i += 13) {
      pxRect(c, s, x + i, y + 1, 1, 3, const Color(0xff3f3f3f));
    }
    double f;
    if (sess.durationTicks > 0) {
      f = 1 - ((sess.matchEndTick - sess.tick) / sess.durationTicks).clamp(0.0, 1.0);
    } else {
      f = ((sess.tick % (WorldConst.ticksPerSecond * 60)) / (WorldConst.ticksPerSecond * 60)).clamp(0.0, 1.0);
    }
    final fw = (182 * f).floorToDouble();
    if (fw > 0) {
      pxRect(c, s, x, y, fw, 5, Px.xp);
      pxRect(c, s, x, y + 4, fw, 1, const Color(0xff5ebf12));
      pxRect(c, s, x, y, fw, 1, const Color(0xffa8ff5a));
    }
    pxOutlinedText(c, s, '${sess.score}', cx, h - 31 - 5, Px.xp);
  }

  void _heldName(Canvas c, double cx, double h, RoomSession sess, bool survival) {
    final held = sess.inventory[sess.selected];
    if (held.isEmpty || g.heldLabelAge > 2.5) return;
    final a = ((2.5 - g.heldLabelAge) * 4).clamp(0.0, 1.0);
    final y = h - (survival ? 59 : 45);
    final tp = pxPainter(held.def.name, s, color: Px.white.withValues(alpha: a));
    tp.paint(c, Offset(cx * s - tp.width / 2, y * s));
  }

  void _actionbar(Canvas c, double cx, double h, bool survival) {
    String? text;
    var alpha = 1.0;
    Color color = Px.white;
    if (g.pickupText != null && g.pickupTimer > 0) {
      text = g.pickupText;
      alpha = (g.pickupTimer * 3).clamp(0.0, 1.0);
    } else if (client.toasts.isNotEmpty) {
      final t = client.toasts.last;
      final age = DateTime.now().difference(t.at).inMilliseconds;
      text = t.text;
      alpha = ((3500 - age) / 600).clamp(0.0, 1.0);
      color = t.kind == 'error' ? Px.red : Px.yellow;
    }
    if (text == null || alpha <= 0) return;
    final y = h - (survival ? 72 : 58);
    final tp = pxPainter(text, s, color: color.withValues(alpha: alpha));
    pxRect(c, s, cx - tp.width / s / 2 - 5, y - 3, tp.width / s + 10, 16, Hearth.ink.withValues(alpha: alpha * 0.9));
    pxRect(c, s, cx - tp.width / s / 2 - 5, y - 3, 1, 16, color.withValues(alpha: alpha));
    tp.paint(c, Offset(cx * s - tp.width / 2, y * s));
  }

  void _chatFeed(Canvas c, double w, double h, RoomSession sess) {
    if (g.chatOpen) return;
    final now = DateTime.now();
    final lines = sess.chat.where((e) => now.difference(e.receivedAt).inMilliseconds < 10000).toList();
    if (lines.isEmpty) return;
    final shown = lines.length > 10 ? lines.sublist(lines.length - 10) : lines;
    // Touch layouts anchor the feed to the top, beside the roster and clear of
    // the top-right menu buttons; desktop keeps it bottom-left above the hotbar.
    final x0 = touch ? _rosterRight : 0.0;
    final maxW = math.min(320.0, w - x0 - (touch ? 84 : 4));
    var y = touch ? 2.0 + shown.length * Px.lineHeight : h - 40;
    for (var i = shown.length - 1; i >= 0; i--) {
      final e = shown[i];
      final age = now.difference(e.receivedAt).inMilliseconds;
      final a = ((10000 - age) / 1000).clamp(0.0, 1.0);
      y -= Px.lineHeight;
      pxRect(c, s, x0, y, maxW + 4, Px.lineHeight, Color.fromRGBO(0, 0, 0, 0.5 * a));
      final name = e.system ? '' : '<${e.from}> ';
      final tp = TextPainter(
        text: TextSpan(
          style: pxStyle(s, color: (e.system ? Px.gray : Px.white).withValues(alpha: a)),
          children: [
            if (name.isNotEmpty)
              TextSpan(
                text: name,
                style: TextStyle(color: chatColorFor(e.from).withValues(alpha: a)),
              ),
            TextSpan(text: e.text),
          ],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxW * s);
      tp.paint(c, Offset((x0 + 2) * s, y * s));
    }
  }

  double _rosterRight = 0;

  void _sidebar(Canvas c, double w, double h, RoomSession sess) {
    final list = sess.roster.toList()..sort((a, b) => b.score.compareTo(a.score));
    final rows = list.length > 8 ? list.sublist(0, 8) : list;
    final title = sess.roomName.isEmpty ? 'Voxelhearth' : sess.roomName;
    final remaining = sess.durationTicks > 0 ? math.max(0, sess.matchEndTick - sess.tick) : null;
    final info = [
      'Code ${sess.code}',
      if (remaining != null) 'Time left ${fmtTicks(remaining)}' else 'Time ${fmtTicks(sess.tick)}',
    ];
    var width = pxPainter(title, s).width / s;
    for (final p in rows) {
      final tw = pxPainter(p.name, s).width / s + 6 + pxPainter('${p.score}', s).width / s;
      width = math.max(width, tw);
    }
    for (final l in info) {
      width = math.max(width, pxPainter(l, s).width / s);
    }
    width = (width + 4).ceilToDouble();
    final lh = Px.lineHeight;
    final total = (rows.length + info.length) * lh + lh;
    // Touch layouts keep the right edge for the action cluster and the
    // top-right for the menu buttons, so the roster sits top-left instead.
    final x = touch ? 2.0 : w - width - 2, y0 = touch ? 2.0 : (h / 2 - total / 2).floorToDouble();
    if (touch) _rosterRight = x + width + 2;
    pxRect(c, s, x - 2, y0 - 2, width + 4, total + 4, const Color(0xc9102e3b));
    pxFrame(c, s, x - 2, y0 - 2, width + 4, total + 4, const Color(0x904e7986));
    pxRect(c, s, x, y0, width, lh, const Color(0xff245153));
    final tt = pxPainter(title, s, color: Px.yellow);
    tt.paint(c, Offset((x + width / 2) * s - tt.width / 2, y0 * s));
    var y = y0 + lh;
    for (final l in info) {
      pxRect(c, s, x, y, width, lh, const Color(0x4c000000));
      pxPainter(l, s, color: Px.gray).paint(c, Offset((x + 2) * s, y * s));
      y += lh;
    }
    for (final p in rows) {
      pxRect(c, s, x, y, width, lh, const Color(0x4c000000));
      final me = p.id == sess.youId;
      final name = pxPainter(p.name, s, color: me ? Px.yellow : (p.bot ? Px.gray : Px.white));
      name.paint(c, Offset((x + 2) * s, y * s));
      final sc = pxPainter('${p.score}', s, color: Px.red);
      sc.paint(c, Offset((x + width - 2) * s - sc.width, y * s));
      y += lh;
    }
  }

  void _debug(Canvas c, RoomSession sess) {
    final lines = [
      'Voxelhearth ${g.fps} fps  scale ${g.pixelScale.toStringAsFixed(2)}',
      'XYZ: ${g.body.x.toStringAsFixed(1)} / ${g.body.y.toStringAsFixed(1)} / ${g.body.z.toStringAsFixed(1)}',
      'Tick ${sess.tick}  ping ${client.pingMs} ms  players ${sess.players.length}',
    ];
    final x0 = touch ? _rosterRight : 0.0;
    var y = 2.0;
    for (final l in lines) {
      final tp = pxPainter(l, s, shadow: false);
      pxRect(c, s, x0 + 1, y - 1, tp.width / s + 2, Px.lineHeight, const Color(0x90505050));
      tp.paint(c, Offset((x0 + 2) * s, y * s));
      y += Px.lineHeight;
    }
  }

  void _targetLabel(Canvas c, double cx, double h) {
    String? label;
    final te = g.targetEntity;
    final t = g.target;
    if (te != null) {
      final mob = g.session.mobs[te];
      final pl = g.session.players.values.where((p) => p.id == te.toString()).firstOrNull;
      label = mob != null ? mobName(mob.kind) : pl?.name;
    } else if (t != null && t.id != Ids.air) {
      label = Registry.block(t.id).name;
    }
    if (label == null || g.inputBlocked) return;
    final tp = pxPainter(label, s, color: Px.white.withValues(alpha: 0.85));
    tp.paint(c, Offset(cx * s - tp.width / 2, (h / 2 + 14) * s));
  }

  @override
  bool shouldRepaint(covariant HudPainter old) => true;
}

String mobName(String kind) => switch (kind) {
  'mossling' => 'Mossling',
  'glimmerhen' => 'Glimmerhen',
  'hollowgast' => 'Hollowgast',
  'bramblecreep' => 'Bramblecreep',
  _ => kind,
};

// ---------------------------------------------------------------- hotbar hit layer

/// Invisible tap target over the painted hotbar. Tapping a slot selects it;
/// tapping the selected slot again opens the inventory (touch convention).
class Hotbar extends StatelessWidget {
  const Hotbar({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 24.0 * s,
      child: Center(
        child: SizedBox(
          width: 184.0 * s,
          height: 24.0 * s,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) {
              final i = ((d.localPosition.dx / s - 1) / 20).floor().clamp(0, Inventory.hotbarSize - 1);
              if (game.session.selected == i && game.heldLabelAge < 2.5) {
                game.openInventory();
              } else {
                game.selectSlot(i);
              }
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- player list

/// Tab-list style roster: room header, one row per player, footer summary.
class PlayerList extends StatelessWidget {
  const PlayerList({super.key, required this.game, required this.client});
  final GameController game;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final sess = game.session;
    final list = sess.roster.toList()..sort((a, b) => b.score.compareTo(a.score));
    final title = '${sess.roomName.isEmpty ? 'Voxelhearth' : sess.roomName}  ·  Code ${sess.code}';
    final footer =
        '${list.length} players  ·  ${sess.mode == GameMode.creative ? 'Creative' : 'Survival'}  ·  ${fmtTicks(sess.tick)}';
    final rowW = math.max(160.0, math.min(260.0, Gui.guiSize(context).width - 40));
    return Container(
      color: const Color(0x80000000),
      padding: EdgeInsets.all(2.0 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PxText(title, color: Px.white),
          SizedBox(height: 2.0 * s),
          for (final p in list)
            Container(
              width: rowW * s,
              height: Px.lineHeight * s,
              margin: EdgeInsets.only(bottom: 1.0 * s),
              color: const Color(0x20ffffff),
              padding: EdgeInsets.symmetric(horizontal: 2.0 * s),
              child: Row(
                children: [
                  PxText(
                    '[${platformLabel(p.bot ? 'bot' : p.platform)}]',
                    color: p.bot ? Px.gray : platformColor(p.platform),
                  ),
                  SizedBox(width: 3.0 * s),
                  Expanded(
                    child: PxText(
                      p.name + (p.id == sess.hostId ? ' (host)' : ''),
                      color: p.id == sess.youId ? Px.yellow : (p.connected ? Px.white : Px.gray),
                    ),
                  ),
                  PxText('${p.score}', color: Px.yellow),
                  SizedBox(width: 3.0 * s),
                  CustomPaint(
                    size: Size(10.0 * s, 8.0 * s),
                    painter: _PingBars(s, p.id == sess.youId ? client.pingMs : (p.connected ? 60 : -1)),
                  ),
                ],
              ),
            ),
          SizedBox(height: 1.0 * s),
          PxText(footer, color: Px.gray),
        ],
      ),
    );
  }
}

class _PingBars extends CustomPainter {
  _PingBars(this.s, this.ping);
  final int s;
  final int ping;

  @override
  void paint(Canvas c, Size size) {
    final bars = ping < 0
        ? 0
        : ping < 150
        ? 5
        : ping < 300
        ? 4
        : ping < 600
        ? 3
        : ping < 1000
        ? 2
        : 1;
    for (var i = 0; i < 5; i++) {
      final h = 2.0 + i * 1.5;
      final lit = i < bars;
      pxRect(c, s, i * 2.0, 8 - h, 1, h, lit ? Px.green : const Color(0xff555555));
    }
  }

  @override
  bool shouldRepaint(covariant _PingBars old) => old.ping != ping;
}

// ---------------------------------------------------------------- touch buttons

/// Small bevelled buttons at the top right for touch platforms: chat,
/// inventory, flight (creative) and pause. Desktop players use the keys.
class HudButtons extends StatelessWidget {
  const HudButtons({super.key, required this.game, required this.touch});
  final GameController game;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    if (!touch || game.inputBlocked) return const SizedBox.shrink();
    final s = Gui.of(context);
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.0 * s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2.0 * s,
            children: [
              PxIconButton(Icons.chat_bubble_outline, label: 'Chat', onPressed: () => game.setChatOpen(true)),
              PxIconButton(Icons.grid_view, label: 'Inventory', onPressed: game.openInventory),
              if (game.isCreative)
                PxIconButton(
                  game.flying ? Icons.flight_land : Icons.flight_takeoff,
                  label: 'Toggle flight',
                  active: game.flying,
                  onPressed: game.toggleFly,
                ),
              PxIconButton(Icons.pause, label: 'Pause', onPressed: () => game.setPaused(true)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- pause menu

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
    final s = Gui.of(context);
    final sess = game.session;
    final isHost = sess.hostId == sess.youId;
    final gui = Gui.guiSize(context);
    final top = gui.height < 230 ? 12.0 : math.max(30.0, gui.height / 4 - 24);
    return Positioned.fill(
      child: DimBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: top * s),
              ArcadeHeading(
                'TAKE A BREATHER',
                eyebrow: gui.height < 230 ? null : 'YOUR WORLD KEEPS TURNING',
                compact: gui.height < 230,
              ),
              SizedBox(height: 12.0 * s),
              PxButton('Back to Game', primary: true, onPressed: () => game.setPaused(false), sound: 'ui_back'),
              SizedBox(height: 4.0 * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PxButton('Options...', width: 98, onPressed: onSettings),
                  SizedBox(width: 4.0 * s),
                  PxButton(
                    'Players',
                    width: 98,
                    onPressed: () {
                      game.showRoster = !game.showRoster;
                      game.setPaused(false);
                    },
                  ),
                ],
              ),
              SizedBox(height: 4.0 * s),
              if (isHost) ...[
                PxButton('End Match for Everyone', onPressed: () => client.send({'t': Msg.endMatch})),
                SizedBox(height: 4.0 * s),
              ],
              SizedBox(height: 4.0 * s),
              PxButton('Leave World', onPressed: client.leaveRoom, sound: 'ui_back'),
              const Spacer(),
              Padding(
                padding: EdgeInsets.all(4.0 * s),
                child: PxText(
                  isDesktopLike
                      ? 'WASD move · Space jump · Shift sprint · Ctrl sneak · E inventory · T chat · Tab players'
                      : 'D-pad moves · drag to look · hold to break · buttons place, jump and sneak',
                  color: Px.gray,
                  align: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- death screen

class DeathOverlay extends StatelessWidget {
  const DeathOverlay({super.key, required this.game, required this.client});
  final GameController game;
  final GameClient client;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final gui = Gui.guiSize(context);
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x60500000), Color(0xa0803030)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 30.0 * s),
              const PxText('You Died!', size: 2),
              SizedBox(height: 20.0 * s),
              PxText(game.deathCause.isEmpty ? 'The hearth will bring you back.' : game.deathCause),
              SizedBox(height: 5.0 * s),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PxText('Score: '),
                  PxText('${game.session.score}', color: Px.yellow),
                ],
              ),
              SizedBox(height: math.max(12.0, gui.height / 4 - 60) * s),
              PxButton('Respawn', onPressed: game.respawn, sound: 'ui_confirm'),
              SizedBox(height: 4.0 * s),
              PxButton('Leave World', onPressed: client.leaveRoom, sound: 'ui_back'),
            ],
          ),
        ),
      ),
    );
  }
}
