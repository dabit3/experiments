import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../game/game_controller.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'pixel.dart';

/// Inventory / workbench / chest / kiln GUI laid out on the classic
/// 176x166 GUI-pixel container panel, with a 147-wide recipe book beside it
/// on crafting screens. Tap a slot to pick it up, tap another to move; the
/// server owns all inventory state.
class InventoryOverlay extends StatefulWidget {
  const InventoryOverlay({
    super.key,
    required this.game,
    required this.client,
    required this.assets,
    required this.kind,
    required this.onClose,
  });
  final GameController game;
  final GameClient client;
  final RenderAssets assets;
  final String kind;
  final VoidCallback onClose;

  @override
  State<InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<InventoryOverlay> {
  int? _pickInv;
  int? _pickChest;
  Recipe? _recipe;
  bool _creativeTab = false;
  bool _bookOpen = true;
  List<String>? _tip;
  Offset? _tipPos;

  RoomSession get s => widget.game.session;
  bool get crafting => widget.kind == ContainerKind.inventory || widget.kind == ContainerKind.workbench;
  int get gridN => widget.kind == ContainerKind.workbench ? 3 : 2;

  @override
  void didUpdateWidget(covariant InventoryOverlay old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) {
      _pickInv = null;
      _pickChest = null;
      _recipe = null;
    }
  }

  // ---------------------------------------------------------------- slot taps

  void _tapInv(int i) {
    HapticFeedback.selectionClick();
    if (_pickChest != null) {
      widget.client.send({'t': 'chest_put', 'toChest': false, 'cslot': _pickChest, 'slot': i});
      setState(() => _pickChest = null);
      return;
    }
    if (_pickInv == null) {
      if (s.inventory[i].isEmpty) return;
      setState(() => _pickInv = i);
      return;
    }
    if (_pickInv == i) {
      setState(() => _pickInv = null);
      return;
    }
    widget.client.send({'t': Msg.moveItem, 'from': _pickInv, 'to': i});
    setState(() => _pickInv = null);
  }

  void _tapChest(int c) {
    HapticFeedback.selectionClick();
    if (_pickInv != null) {
      widget.client.send({'t': 'chest_put', 'toChest': true, 'slot': _pickInv, 'cslot': c});
      setState(() => _pickInv = null);
      return;
    }
    if (_pickChest == null) {
      if ((s.chestSlots?[c] ?? ItemStack.empty).isEmpty) return;
      setState(() => _pickChest = c);
      return;
    }
    if (_pickChest == c) {
      setState(() => _pickChest = null);
      return;
    }
    widget.client.send({'t': 'chest_put', 'toChest': false, 'cslot': _pickChest, 'slot': -1});
    setState(() => _pickChest = null);
  }

  void _tapKiln(String kslot) {
    HapticFeedback.selectionClick();
    if (_pickInv != null && kslot != 'output') {
      widget.client.send({'t': 'kiln_put', 'kslot': kslot, 'slot': _pickInv});
      setState(() => _pickInv = null);
    } else {
      widget.client.send({'t': 'kiln_put', 'kslot': kslot, 'slot': -1});
    }
  }

  void _drop(int i) {
    if (s.inventory[i].isEmpty) return;
    widget.client.send({'t': 'drop_item', 'slot': i, 'count': s.inventory[i].count});
    setState(() => _pickInv = null);
  }

  void _craft(Recipe r, int count) {
    final grid = _gridFor(r, gridN);
    if (grid == null) return;
    widget.client.send({'t': Msg.craft, 'grid': grid, 'n': gridN, 'count': count});
    HapticFeedback.lightImpact();
  }

  static List<int>? _gridFor(Recipe r, int n) {
    if (r.gridNeeded > n) return null;
    final g = List<int>.filled(n * n, 0);
    if (r.isShapeless) {
      for (var i = 0; i < r.shapeless!.length; i++) {
        g[i] = r.shapeless![i];
      }
      return g;
    }
    for (var y = 0; y < r.height; y++) {
      for (var x = 0; x < r.width; x++) {
        g[y * n + x] = r.pattern[y * r.width + x];
      }
    }
    return g;
  }

  int _craftable(Recipe r) {
    if (s.mode == GameMode.creative) return 64;
    final need = <int, int>{};
    for (final id in r.isShapeless ? r.shapeless! : r.pattern) {
      if (id != 0) need[id] = (need[id] ?? 0) + 1;
    }
    var times = 64;
    for (final e in need.entries) {
      final have = s.inventory.countOf(e.key) ~/ e.value;
      if (have < times) times = have;
    }
    return times;
  }

  void _hover(List<String>? tip, Offset? pos) {
    if (tip == _tip && pos == _tipPos) return;
    setState(() {
      _tip = pos == null ? null : tip;
      _tipPos = pos;
    });
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final gs = Gui.of(context);
    final gui = Gui.guiSize(context);
    final panelH = _panelHeight;
    final bookFits = gui.width >= 176 + 147 + 12;
    final book = crafting && _bookOpen && bookFits;
    final totalW = book ? 176.0 + 4 + 147 : 176.0;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DimBackground(),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: SizedBox(
                  width: totalW * gs,
                  height: panelH * gs,
                  child: Row(
                    children: [
                      if (book) ...[_recipeBook(context), SizedBox(width: 4.0 * gs)],
                      _mainPanel(context, panelH, bookFits),
                    ],
                  ),
                ),
              ),
            ),
            if (_tip != null && _tipPos != null)
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _TipPainter(gs, _tip!, _tipPos!))),
              ),
          ],
        ),
      ),
    );
  }

  double get _panelHeight {
    if (widget.kind == ContainerKind.chest) {
      final rows = ((s.chestSlots?.length ?? 27) / 9).ceil();
      return 114 + rows * 18.0;
    }
    return 166;
  }

  Widget _mainPanel(BuildContext context, double h, bool bookFits) {
    final gs = Gui.of(context);
    final atlas = widget.assets.atlasImage;
    final invY = h - 166 + 84;
    final children = <Widget>[
      // Main inventory 9x3 + hotbar, at classic offsets.
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 9; c++) _at(7 + c * 18, invY - 1 + r * 18, _invSlot(9 + r * 9 + c, atlas)),
      for (var c = 0; c < 9; c++) _at(7 + c * 18, invY + 57, _invSlot(c, atlas, hotbar: true)),
    ];
    switch (widget.kind) {
      case ContainerKind.chest:
        final rows = ((s.chestSlots?.length ?? 27) / 9).ceil();
        children.add(_at(8, 6, const PxText('Chest', color: Px.darkGray, shadow: false)));
        children.add(_at(8, invY - 12, const PxText('Inventory', color: Px.darkGray, shadow: false)));
        final c = s.chestSlots;
        for (var i = 0; i < rows * 9; i++) {
          final stack = c == null || i >= c.length ? ItemStack.empty : c[i];
          children.add(
            _at(
              7 + (i % 9) * 18,
              17 + (i ~/ 9) * 18,
              PxSlotWidget(
                stack: stack,
                atlas: atlas,
                picked: _pickChest == i,
                onTap: c == null ? null : () => _tapChest(i),
                onHover: (p) => _hover(stack.isEmpty ? null : [stack.def.name], p),
              ),
            ),
          );
        }
        if (c == null) children.add(_at(60, 40, const PxText('Opening...', color: Px.darkGray, shadow: false)));
      case ContainerKind.kiln:
        children.add(
          _at(
            0,
            6,
            SizedBox(
              width: 176.0 * gs,
              child: const PxText('Kiln', color: Px.darkGray, shadow: false, align: TextAlign.center),
            ),
          ),
        );
        children.add(_at(8, 72, const PxText('Inventory', color: Px.darkGray, shadow: false)));
        final k = s.kiln;
        final input = k == null ? ItemStack.empty : ItemStack.fromJson(k['input']);
        final fuel = k == null ? ItemStack.empty : ItemStack.fromJson(k['fuel']);
        final output = k == null ? ItemStack.empty : ItemStack.fromJson(k['output']);
        final burnLeft = k == null ? 0 : jint(k, 'burnLeft'), burnTotal = k == null ? 0 : jint(k, 'burnTotal');
        final cook = k == null ? 0 : jint(k, 'cook'),
            cookTotal = k == null ? 1 : jint(k, 'cookTotal', Recipes.smeltTicks);
        final burnF = burnTotal == 0 ? 0.0 : burnLeft / burnTotal;
        final cookF = cookTotal == 0 ? 0.0 : cook / cookTotal;
        children.addAll([
          _at(
            55,
            16,
            PxSlotWidget(
              stack: input,
              atlas: atlas,
              onTap: () => _tapKiln('input'),
              onHover: (p) => _hover(input.isEmpty ? ['Input: ore, sand, clay, meat'] : [input.def.name], p),
            ),
          ),
          _at(56, 36, CustomPaint(size: Size(14.0 * gs, 14.0 * gs), painter: _FlamePainter(gs, burnF))),
          _at(
            55,
            52,
            PxSlotWidget(
              stack: fuel,
              atlas: atlas,
              onTap: () => _tapKiln('fuel'),
              onHover: (p) => _hover(fuel.isEmpty ? ['Fuel: wood, planks, coal'] : [fuel.def.name], p),
            ),
          ),
          _at(79, 34, CustomPaint(size: Size(24.0 * gs, 17.0 * gs), painter: _ArrowPainter(gs, cookF))),
          _at(
            111,
            30,
            PxSlotWidget(
              stack: output,
              atlas: atlas,
              size: 26,
              onTap: () => _tapKiln('output'),
              onHover: (p) => _hover(output.isEmpty ? null : [output.def.name], p),
            ),
          ),
        ]);
      default:
        final n = gridN;
        final sel = _selectedRecipe;
        final canMake = sel == null ? 0 : _craftable(sel);
        final grid = sel == null ? List<int>.filled(n * n, 0) : (_gridFor(sel, n) ?? List<int>.filled(n * n, 0));
        final gx = n == 3 ? 29.0 : 97.0, gy = n == 3 ? 16.0 : 17.0;
        final ox = n == 3 ? 119.0 : 149.0, oy = n == 3 ? 26.0 : 23.0;
        final ax = n == 3 ? 89.0 : 133.0, ay = n == 3 ? 34.0 : 29.0;
        children.add(_at(n == 3 ? 28 : 97, 6, const PxText('Crafting', color: Px.darkGray, shadow: false)));
        if (n == 3) children.add(_at(8, 72, const PxText('Inventory', color: Px.darkGray, shadow: false)));
        if (n == 2) {
          children.add(
            _at(
              25,
              7,
              CustomPaint(
                size: Size(51.0 * gs, 72.0 * gs),
                painter: _AvatarPainter(gs, platformColor(widget.client.platform)),
              ),
            ),
          );
        }
        for (var i = 0; i < n * n; i++) {
          final id = grid[i];
          final ghost = id != 0 && s.mode == GameMode.survival && s.inventory.countOf(id) == 0;
          children.add(
            _at(
              gx + (i % n) * 18,
              gy + (i ~/ n) * 18,
              PxSlotWidget(
                stack: id == 0 ? ItemStack.empty : ItemStack(id, 1),
                atlas: atlas,
                hideCount: true,
                ghost: ghost,
                onHover: (p) => _hover(id == 0 ? null : [Registry.nameOf(id)], p),
              ),
            ),
          );
        }
        children.add(
          _at(ax, ay, CustomPaint(size: Size(22.0 * gs, 15.0 * gs), painter: _ArrowPainter(gs, canMake > 0 ? 1 : 0))),
        );
        children.add(
          _at(
            ox,
            oy,
            PxSlotWidget(
              stack: sel == null ? ItemStack.empty : ItemStack(sel.result.id, sel.result.count),
              atlas: atlas,
              size: 26,
              ghost: canMake == 0,
              onTap: canMake > 0 ? () => _craft(sel!, 1) : null,
              onSecondaryTap: canMake > 1 ? () => _craft(sel!, canMake) : null,
              onHover: (p) => _hover(
                sel == null
                    ? null
                    : [
                        sel.name ?? sel.result.def.name,
                        canMake == 0 ? 'Missing ingredients' : 'Click: craft 1 · Hold: craft $canMake',
                      ],
                p,
              ),
            ),
          ),
        );
        if (!bookFits || !_bookOpen) {
          children.add(
            _at(
              n == 3 ? 5 : 104,
              n == 3 ? 49 : 60,
              PxButton(
                _bookOpen && bookFits ? 'Book' : 'Recipes',
                width: 40,
                height: 14,
                onPressed: () => setState(() => _bookOpen = !_bookOpen),
              ),
            ),
          );
        } else if (n == 3) {
          children.add(
            _at(5, 49, PxButton('<', width: 20, height: 18, onPressed: () => setState(() => _bookOpen = false))),
          );
        }
        if (_pickInv != null) {
          children.add(
            _at(
              7,
              invY - 12,
              const PxText('Tap a slot to move · long-press to drop', color: Px.darkGray, shadow: false),
            ),
          );
        }
    }
    return PxPanel(
      width: 176,
      height: h,
      child: Stack(children: children),
    );
  }

  Recipe? get _selectedRecipe {
    if (!crafting) return null;
    final recipes = Recipes.all.where((r) => r.gridNeeded <= gridN).toList();
    if (recipes.isEmpty) return null;
    final r = _recipe;
    if (r != null && recipes.contains(r)) return r;
    return recipes.first;
  }

  Widget _invSlot(int i, ui.Image atlas, {bool hotbar = false}) {
    final stack = s.inventory[i];
    return PxSlotWidget(
      stack: stack,
      atlas: atlas,
      picked: _pickInv == i,
      selected: hotbar && s.selected == i && _pickInv != i,
      onTap: () => _tapInv(i),
      onSecondaryTap: () => _drop(i),
      onHover: (p) => _hover(stack.isEmpty ? null : [stack.def.name, if (stack.count > 1) 'x${stack.count}'], p),
    );
  }

  Widget _at(double x, double y, Widget child) {
    final gs = Gui.of(context);
    return Positioned(left: x * gs, top: y * gs, child: child);
  }

  // ---------------------------------------------------------------- recipe book

  Widget _recipeBook(BuildContext context) {
    final gs = Gui.of(context);
    final atlas = widget.assets.atlasImage;
    final creative = s.mode == GameMode.creative;
    final showBlocks = creative && _creativeTab;
    final recipes = Recipes.all.where((r) => r.gridNeeded <= gridN).toList();
    final sel = _selectedRecipe;
    final cells = showBlocks
        ? [
            for (final id in Registry.creativePalette)
              _BookCell(
                stack: ItemStack(id, 1),
                tip: [Registry.nameOf(id), 'Click to add a stack'],
                onTap: () {
                  widget.client.send({
                    't': 'give',
                    'id': id,
                    'count': Registry.item(id).maxStack,
                    'slot': _pickInv ?? -1,
                  });
                  HapticFeedback.selectionClick();
                  setState(() => _pickInv = null);
                },
              ),
          ]
        : [
            for (final r in recipes)
              _BookCell(
                stack: r.result,
                ghost: _craftable(r) == 0,
                selected: r == sel,
                tip: [
                  r.name ?? r.result.def.name,
                  _craftable(r) == 0 ? 'Missing ingredients' : 'Can craft ${_craftable(r)}',
                ],
                onTap: () => setState(() => _recipe = r),
              ),
          ];
    return PxPanel(
      width: 147,
      height: _panelHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(9.0 * gs, 6.0 * gs, 9.0 * gs, 8.0 * gs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: PxText('Recipes', color: Px.darkGray, shadow: false)),
                if (creative)
                  PxButton(
                    showBlocks ? 'Recipes' : 'Blocks',
                    width: 44,
                    height: 12,
                    onPressed: () => setState(() => _creativeTab = !_creativeTab),
                  ),
              ],
            ),
            SizedBox(height: 4.0 * gs),
            Expanded(
              child: Container(
                color: Px.slot,
                child: GridView.builder(
                  padding: EdgeInsets.all(2.0 * gs),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 0,
                    childAspectRatio: 1,
                  ),
                  itemCount: cells.length,
                  itemBuilder: (context, i) => Center(
                    child: PxSlotWidget(
                      stack: cells[i].stack,
                      atlas: atlas,
                      size: 24,
                      hideCount: true,
                      ghost: cells[i].ghost,
                      picked: cells[i].selected,
                      onTap: cells[i].onTap,
                      onHover: (p) => _hover(cells[i].tip, p),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 3.0 * gs),
            PxText(
              showBlocks ? 'Creative palette' : (gridN == 3 ? 'Workbench: 3x3 recipes' : 'By hand: 2x2 recipes'),
              color: Px.darkGray,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCell {
  const _BookCell({required this.stack, required this.tip, this.onTap, this.ghost = false, this.selected = false});
  final ItemStack stack;
  final List<String> tip;
  final VoidCallback? onTap;
  final bool ghost, selected;
}

class _TipPainter extends CustomPainter {
  _TipPainter(this.s, this.lines, this.pos);
  final int s;
  final List<String> lines;
  final Offset pos;

  @override
  void paint(Canvas c, Size size) =>
      pxTooltip(c, s, lines, pos.dx / s + 8, pos.dy / s - 12, Size(size.width / s, size.height / s));

  @override
  bool shouldRepaint(covariant _TipPainter old) => old.lines != lines || old.pos != pos || old.s != s;
}

/// 14x14 kiln flame: grey outline, lit from the bottom by burn fraction.
class _FlamePainter extends CustomPainter {
  _FlamePainter(this.s, this.f);
  final int s;
  final double f;

  static const _shape = [
    '......XX......',
    '.....XXXX.....',
    '.....XXXX.....',
    '....XXXXXX....',
    '....XXXXXX....',
    '...XXXXXXXX...',
    '..XXXXXXXXXX..',
    '..XXXXXXXXXX..',
    '.XXXXXXXXXXXX.',
    '.XXXXXXXXXXXX.',
    '.XXXXXXXXXXXX.',
    '..XXXXXXXXXX..',
    '...XXXXXXXX...',
    '....XXXXXX....',
  ];

  @override
  void paint(Canvas c, Size size) {
    final litFrom = (14 * (1 - f)).round();
    for (var y = 0; y < 14; y++) {
      for (var x = 0; x < 14; x++) {
        if (_shape[y][x] != 'X') continue;
        final lit = y >= litFrom;
        final inner = x > 3 && x < 10 && y > 6;
        final color = !lit ? Px.panelDark : (inner ? const Color(0xffffd83d) : const Color(0xffff7a1a));
        pxRect(c, s, x.toDouble(), y.toDouble(), 1, 1, color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) => old.f != f || old.s != s;
}

/// Progress arrow: grey outline filled left-to-right by [f].
class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.s, this.f);
  final int s;
  final double f;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width / s, h = size.height / s;
    final mid = (h / 2).floorToDouble();
    final headW = (h / 2).floorToDouble();
    void arrow(Color color, double clipW) {
      c.save();
      c.clipRect(Rect.fromLTWH(0, 0, clipW * s, h * s));
      pxRect(c, s, 0, mid - 2, w - headW, 5, color);
      for (var i = 0; i < headW; i++) {
        pxRect(c, s, w - headW + i, i.toDouble(), 1, h - 2 * i, color);
      }
      c.restore();
    }

    arrow(Px.panelDark, w);
    if (f > 0) arrow(Px.white, w * f.clamp(0, 1));
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.f != f || old.s != s;
}

/// Blocky Hearthling portrait in the inventory's preview window.
class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.s, this.accent);
  final int s;
  final Color accent;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width / s, h = size.height / s;
    pxRect(c, s, 0, 0, w, h, Px.slotDark);
    pxRect(c, s, 1, 1, w - 2, h - 2, Px.slot);
    pxRect(c, s, 1, 1, w - 2, h - 2, const Color(0xff2b2b2b));
    final cx = (w / 2).floorToDouble();
    const skin = Color(0xffe0ac8c), hair = Color(0xff4a2f1c), eye = Color(0xff3a5f8f);
    final shirt = accent, pants = const Color(0xff3b4a8a), boots = const Color(0xff3a3a3a);
    // head 16x16
    pxRect(c, s, cx - 8, 6, 16, 16, skin);
    pxRect(c, s, cx - 8, 6, 16, 5, hair);
    pxRect(c, s, cx - 8, 11, 2, 3, hair);
    pxRect(c, s, cx + 6, 11, 2, 3, hair);
    pxRect(c, s, cx - 5, 14, 2, 2, eye);
    pxRect(c, s, cx + 3, 14, 2, 2, eye);
    pxRect(c, s, cx - 2, 18, 4, 1, const Color(0xffa06a50));
    // body 16x24, arms 8x24
    pxRect(c, s, cx - 8, 22, 16, 24, shirt);
    pxRect(c, s, cx - 16, 22, 8, 24, shirt);
    pxRect(c, s, cx + 8, 22, 8, 24, shirt);
    pxRect(c, s, cx - 16, 40, 8, 6, skin);
    pxRect(c, s, cx + 8, 40, 8, 6, skin);
    // legs 8x24 each
    pxRect(c, s, cx - 8, 46, 8, 20, pants);
    pxRect(c, s, cx, 46, 8, 20, pants);
    pxRect(c, s, cx - 8, 62, 16, 4, boots);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) => old.accent != accent || old.s != s;
}
