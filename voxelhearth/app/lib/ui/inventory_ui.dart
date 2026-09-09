import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../game/game_controller.dart';
import '../game/renderer.dart';
import '../net/game_client.dart';
import 'theme.dart';
import 'widgets.dart';

/// Inventory / workbench / chest / kiln overlay. Tap a slot to pick it up,
/// tap another to move; the server owns all inventory state.
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

  RoomSession get s => widget.game.session;

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
    // move inside chest: via inventory round-trip is not supported; swap by pulling then pushing.
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
    widget.client.send({'t': 'drop_item', 'slot': i, 'count': s.inventory[i].count});
    setState(() => _pickInv = null);
  }

  void _craft(Recipe r, int count) {
    final n = widget.kind == ContainerKind.workbench ? 3 : 2;
    final grid = _gridFor(r, n);
    if (grid == null) return;
    widget.client.send({'t': Msg.craft, 'grid': grid, 'n': n, 'count': count});
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
      times = times < s.inventory.countOf(e.key) ~/ e.value ? times : s.inventory.countOf(e.key) ~/ e.value;
    }
    return times;
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ff = formFactorOf(context);
    final slot = ff == FormFactor.phone ? 38.0 : 46.0;
    final title = switch (widget.kind) {
      ContainerKind.workbench => 'Workbench',
      ContainerKind.chest => 'Chest',
      ContainerKind.kiln => 'Kiln',
      _ => 'Inventory',
    };
    final wide = MediaQuery.sizeOf(context).width > 720;
    final left = _leftPanel(t, slot, wide);
    final right = _inventoryPanel(t, slot);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(VhSpace.md),
          child: GestureDetector(
            onTap: () {},
            child: Reveal(
              child: GlassPanel(
                tint: Colors.black.withValues(alpha: 0.55),
                padding: const EdgeInsets.all(VhSpace.md),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 900 : 560,
                    maxHeight: MediaQuery.sizeOf(context).height - 48,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(_iconFor(widget.kind), color: VhColors.gold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: t.textTheme.titleLarge?.copyWith(color: Colors.white, fontFamily: 'Fraunces'),
                          ),
                          const Spacer(),
                          if (_pickInv != null || _pickChest != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                'Tap a slot to move',
                                style: t.textTheme.bodySmall?.copyWith(color: VhColors.gold),
                              ),
                            ),
                          if (_pickInv != null)
                            IconButton(
                              tooltip: 'Drop stack (Q)',
                              onPressed: () => _drop(_pickInv!),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                            ),
                          IconButton(
                            tooltip: 'Close (Esc)',
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: VhSpace.sm),
                      Flexible(
                        child: SingleChildScrollView(
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: left),
                                    const SizedBox(width: VhSpace.lg),
                                    right,
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    left,
                                    const SizedBox(height: VhSpace.md),
                                    right,
                                  ],
                                ),
                        ),
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

  static IconData _iconFor(String kind) => switch (kind) {
    ContainerKind.workbench => Icons.handyman_rounded,
    ContainerKind.chest => Icons.inventory_2_rounded,
    ContainerKind.kiln => Icons.local_fire_department_rounded,
    _ => Icons.backpack_rounded,
  };

  Widget _leftPanel(ThemeData t, double slot, bool wide) => switch (widget.kind) {
    ContainerKind.chest => _chestPanel(t, slot),
    ContainerKind.kiln => _kilnPanel(t, slot),
    _ => _craftPanel(t, slot, widget.kind == ContainerKind.workbench ? 3 : 2),
  };

  // ---------------------------------------------------------------- inventory

  Widget _inventoryPanel(ThemeData t, double slot) {
    final inv = s.inventory;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Backpack'),
        const SizedBox(height: 6),
        _grid(9, 27, (i) => inv[9 + i], (i) => _tapInv(9 + i), slot, picked: _pickInv == null ? null : _pickInv! - 9),
        const SizedBox(height: VhSpace.sm),
        _label('Hotbar'),
        const SizedBox(height: 6),
        _grid(9, 9, (i) => inv[i], (i) => _tapInv(i), slot, picked: _pickInv, selected: s.selected),
      ],
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Colors.white54,
      fontSize: 10.5,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w700,
      fontFamily: 'Outfit',
    ),
  );

  Widget _grid(
    int cols,
    int count,
    ItemStack Function(int) at,
    void Function(int) onTap,
    double slot, {
    int? picked,
    int? selected,
  }) => SizedBox(
    width: cols * (slot + 4),
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < count; i++)
          _Slot(
            stack: at(i),
            size: slot,
            atlas: widget.assets.atlasImage,
            picked: picked == i,
            highlighted: selected == i,
            onTap: () => onTap(i),
          ),
      ],
    ),
  );

  // ---------------------------------------------------------------- crafting

  Widget _craftPanel(ThemeData t, double slot, int n) {
    if (s.mode == GameMode.creative && _creativeTab) return _creativePanel(t, slot);
    final recipes = Recipes.all.where((r) => r.gridNeeded <= n).toList();
    final sel = _recipe ?? recipes.first;
    final canMake = _craftable(sel);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label(n == 3 ? 'Recipes · 3×3 workbench' : 'Recipes · 2×2 hand crafting'),
            const Spacer(),
            if (s.mode == GameMode.creative)
              TextButton(onPressed: () => setState(() => _creativeTab = true), child: const Text('Creative palette')),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final r in recipes)
              Tooltip(
                message: r.name ?? r.result.def.name,
                child: _Slot(
                  stack: r.result,
                  size: slot,
                  atlas: widget.assets.atlasImage,
                  dim: _craftable(r) == 0,
                  highlighted: r == sel,
                  onTap: () => setState(() => _recipe = r),
                ),
              ),
          ],
        ),
        const SizedBox(height: VhSpace.md),
        Container(
          padding: const EdgeInsets.all(VhSpace.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(VhRadius.md),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              _patternGrid(sel, n, slot * 0.85),
              const SizedBox(width: VhSpace.sm),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white38),
              const SizedBox(width: VhSpace.sm),
              _Slot(
                stack: sel.result,
                size: slot * 1.2,
                atlas: widget.assets.atlasImage,
                onTap: canMake > 0 ? () => _craft(sel, 1) : null,
                dim: canMake == 0,
              ),
              const SizedBox(width: VhSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sel.name ?? sel.result.def.name,
                      style: t.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      canMake == 0 ? 'Missing ingredients' : 'Makes ${sel.result.count} · you can craft $canMake',
                      style: t.textTheme.bodySmall?.copyWith(color: canMake == 0 ? VhColors.danger : Colors.white60),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        FilledButton(onPressed: canMake > 0 ? () => _craft(sel, 1) : null, child: const Text('Craft')),
                        OutlinedButton(
                          onPressed: canMake > 1 ? () => _craft(sel, canMake) : null,
                          child: Text('Craft all${canMake > 1 ? ' ($canMake)' : ''}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _patternGrid(Recipe r, int n, double cell) {
    final grid = _gridFor(r, n) ?? List<int>.filled(n * n, 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var y = 0; y < n; y++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var x = 0; x < n; x++)
                Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: _Slot(
                    stack: grid[y * n + x] == 0 ? ItemStack.empty : ItemStack(grid[y * n + x], 1),
                    size: cell,
                    atlas: widget.assets.atlasImage,
                    hideCount: true,
                    dim:
                        grid[y * n + x] != 0 &&
                        s.mode == GameMode.survival &&
                        s.inventory.countOf(grid[y * n + x]) == 0,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _creativePanel(ThemeData t, double slot) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _label('Creative palette · tap to add a stack'),
          const Spacer(),
          TextButton(onPressed: () => setState(() => _creativeTab = false), child: const Text('Recipes')),
        ],
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final id in Registry.creativePalette)
            Tooltip(
              message: Registry.nameOf(id),
              child: _Slot(
                stack: ItemStack(id, 1),
                size: slot,
                atlas: widget.assets.atlasImage,
                hideCount: true,
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
            ),
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------- chest

  Widget _chestPanel(ThemeData t, double slot) {
    final c = s.chestSlots;
    if (c == null) {
      return const Padding(
        padding: EdgeInsets.all(VhSpace.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Chest · shared with everyone in this world'),
        const SizedBox(height: 6),
        _grid(9, c.length, (i) => c[i], _tapChest, slot, picked: _pickChest),
        const SizedBox(height: VhSpace.sm),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickInv == null ? null : () => _tapChest(-1),
              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
              label: const Text('Store picked stack'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- kiln

  Widget _kilnPanel(ThemeData t, double slot) {
    final k = s.kiln;
    if (k == null) {
      return const Padding(
        padding: EdgeInsets.all(VhSpace.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final input = ItemStack.fromJson(k['input']);
    final fuel = ItemStack.fromJson(k['fuel']);
    final output = ItemStack.fromJson(k['output']);
    final burnLeft = jint(k, 'burnLeft'), burnTotal = jint(k, 'burnTotal');
    final cook = jint(k, 'cook'), cookTotal = jint(k, 'cookTotal', Recipes.smeltTicks);
    final burnF = burnTotal == 0 ? 0.0 : burnLeft / burnTotal;
    final cookF = cookTotal == 0 ? 0.0 : cook / cookTotal;
    final big = slot * 1.3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Kiln · smelts ore, sand, clay and meat'),
        const SizedBox(height: VhSpace.sm),
        Container(
          padding: const EdgeInsets.all(VhSpace.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(VhRadius.md),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _captioned(
                    'Input',
                    _Slot(
                      stack: input,
                      size: big,
                      atlas: widget.assets.atlasImage,
                      onTap: () => _tapKiln('input'),
                      picked: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: big,
                    height: 26,
                    child: CustomPaint(painter: _FlamePainter(burnF)),
                  ),
                  const SizedBox(height: 6),
                  _captioned(
                    'Fuel',
                    _Slot(stack: fuel, size: big, atlas: widget.assets.atlasImage, onTap: () => _tapKiln('fuel')),
                  ),
                ],
              ),
              const SizedBox(width: VhSpace.md),
              SizedBox(
                width: 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: cookF,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                      color: VhColors.ember,
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cook > 0 ? '${(cookF * 100).round()}%' : (burnLeft > 0 ? 'Lit' : 'Cold'),
                      style: t.textTheme.labelSmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VhSpace.md),
              _captioned(
                'Output',
                _Slot(
                  stack: output,
                  size: big * 1.1,
                  atlas: widget.assets.atlasImage,
                  onTap: () => _tapKiln('output'),
                  highlighted: output.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VhSpace.xs),
        Text(
          'Pick a stack from your inventory, then tap Input or Fuel. Tap a kiln slot again to take it back.',
          style: t.textTheme.bodySmall?.copyWith(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _captioned(String text, Widget child) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      child,
      const SizedBox(height: 3),
      Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Outfit'),
      ),
    ],
  );
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.stack,
    required this.size,
    required this.atlas,
    this.onTap,
    this.picked = false,
    this.highlighted = false,
    this.dim = false,
    this.hideCount = false,
  });
  final ItemStack stack;
  final double size;
  final ui.Image atlas;
  final VoidCallback? onTap;
  final bool picked, highlighted, dim, hideCount;

  @override
  Widget build(BuildContext context) {
    final border = picked
        ? VhColors.gold
        : highlighted
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.12);
    return Semantics(
      button: onTap != null,
      label: stack.isEmpty ? 'Empty slot' : '${stack.def.name} x${stack.count}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: picked ? VhColors.gold.withValues(alpha: 0.18) : Colors.white.withValues(alpha: dim ? 0.02 : 0.06),
            borderRadius: BorderRadius.circular(VhRadius.sm),
            border: Border.all(color: border, width: picked || highlighted ? 2 : 1),
          ),
          child: stack.isEmpty
              ? null
              : Center(
                  child: hideCount
                      ? TileIcon(atlas, itemTileFor(stack.id), size: size - 12, opacity: dim ? 0.35 : 1)
                      : StackIcon(atlas, stack, size: size - 8, dim: dim),
                ),
        ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.f);
  final double f;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final base = Path()
      ..moveTo(cx - w * 0.28, h)
      ..quadraticBezierTo(cx - w * 0.34, h * 0.4, cx, 0)
      ..quadraticBezierTo(cx + w * 0.34, h * 0.4, cx + w * 0.28, h)
      ..close();
    c.drawPath(base, Paint()..color = Colors.white.withValues(alpha: 0.12));
    if (f <= 0) return;
    c.save();
    c.clipRect(Rect.fromLTWH(0, h * (1 - f), w, h * f));
    c.drawPath(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xffff9a3c), Color(0xffffd36b)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) => old.f != f;
}
