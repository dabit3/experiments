import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme/tokens.dart';
import '../widgets/avatar_painter.dart';
import '../widgets/common.dart';

/// Avatar editor: body colours per part, faces, hats and accessories.
/// Unowned catalog items can be bought with Pips inline.
class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key});

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

enum _Part { head, torso, arms, legs }

class _AvatarScreenState extends State<AvatarScreen> {
  late Avatar _draft;
  _Part _part = _Part.torso;
  ItemSlot _slot = ItemSlot.hat;
  bool _facingRight = true;

  @override
  void initState() {
    super.initState();
    _draft = AppScope.read(context).client.me!.summary.avatar;
  }

  bool get _dirty => _draft != AppScope.read(context).client.me!.summary.avatar;

  void _setColor(int color) {
    setState(() {
      _draft = switch (_part) {
        _Part.head => _draft.copyWith(headColor: color),
        _Part.torso => _draft.copyWith(torsoColor: color),
        _Part.arms => _draft.copyWith(armColor: color),
        _Part.legs => _draft.copyWith(legColor: color),
      };
    });
  }

  int get _currentColor => switch (_part) {
    _Part.head => _draft.headColor,
    _Part.torso => _draft.torsoColor,
    _Part.arms => _draft.armColor,
    _Part.legs => _draft.legColor,
  };

  void _equip(CatalogItem item) {
    if (AppScope.read(context).hapticsEnabled) HapticFeedback.selectionClick();
    setState(() {
      _draft = switch (item.slot) {
        ItemSlot.face => _draft.copyWith(face: item.id),
        ItemSlot.hat => _draft.copyWith(hat: item.id),
        ItemSlot.accessory => _draft.copyWith(accessory: item.id),
      };
    });
  }

  void _save() {
    AppScope.read(context).client.updateAvatar(_draft);
    if (AppScope.read(context).hapticsEnabled) HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Avatar saved')));
  }

  @override
  Widget build(BuildContext context) {
    final client = ClientScope.of(context);
    final me = client.me!;
    final p = context.palette;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    final preview = Panel(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Preview', style: context.text.titleMedium)),
              IconButton(
                tooltip: 'Turn around',
                onPressed: () => setState(() => _facingRight = !_facingRight),
                icon: const Icon(Icons.threesixty_rounded),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Container(
            height: wide ? 320 : 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.surface2, p.surface3],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 26,
                  child: Container(
                    width: wide ? 150 : 110,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  child: AnimatedSwitcher(
                    duration: Motion.fast,
                    child: AvatarView(
                      _draft,
                      key: ValueKey('${_draft.hashCode}-$_facingRight'),
                      size: wide ? 260 : 170,
                      facingRight: _facingRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dirty
                      ? () => setState(() => _draft = me.summary.avatar)
                      : null,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _dirty ? _save : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save look'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final colors = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Body colours', style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          SegmentedButton<_Part>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Part.head, label: Text('Head')),
              ButtonSegment(value: _Part.torso, label: Text('Torso')),
              ButtonSegment(value: _Part.arms, label: Text('Arms')),
              ButtonSegment(value: _Part.legs, label: Text('Legs')),
            ],
            selected: {_part},
            onSelectionChanged: (s) => setState(() => _part = s.first),
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (var i = 0; i < bodyColors.length; i++)
                Semantics(
                  label: bodyColorNames[i],
                  button: true,
                  selected: bodyColors[i] == _currentColor,
                  child: Tooltip(
                    message: bodyColorNames[i],
                    child: GestureDetector(
                      onTap: () => _setColor(bodyColors[i]),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(bodyColors[i]),
                          borderRadius: BorderRadius.circular(Radii.sm + 2),
                          border: Border.all(
                            color: bodyColors[i] == _currentColor
                                ? p.textPrimary
                                : p.outline,
                            width: bodyColors[i] == _currentColor ? 3 : 1,
                          ),
                          boxShadow: bodyColors[i] == _currentColor
                              ? [
                                  BoxShadow(
                                    color: Color(bodyColors[i])
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: bodyColors[i] == _currentColor
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: _contrastOn(Color(bodyColors[i])),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final items = catalog.where((c) => c.slot == _slot).toList();
    final wardrobe = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Wardrobe', style: context.text.titleMedium),
              ),
              PipChip(me.pips, compact: true),
            ],
          ),
          const SizedBox(height: Space.md),
          SegmentedButton<ItemSlot>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ItemSlot.hat,
                label: Text('Hats'),
                icon: Icon(Icons.checkroom_rounded, size: 16),
              ),
              ButtonSegment(
                value: ItemSlot.face,
                label: Text('Faces'),
                icon: Icon(Icons.face_retouching_natural_rounded, size: 16),
              ),
              ButtonSegment(
                value: ItemSlot.accessory,
                label: Text('Extras'),
                icon: Icon(Icons.auto_awesome_rounded, size: 16),
              ),
            ],
            selected: {_slot},
            onSelectionChanged: (s) => setState(() => _slot = s.first),
          ),
          const SizedBox(height: Space.lg),
          LayoutBuilder(
            builder: (context, c) {
              final cols = (c.maxWidth / 150).floor().clamp(2, 5);
              final w = (c.maxWidth - Space.sm * (cols - 1)) / cols;
              return Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: w,
                      child: _ItemCard(
                        item: item,
                        equipped: switch (item.slot) {
                          ItemSlot.face => _draft.face == item.id,
                          ItemSlot.hat => _draft.hat == item.id,
                          ItemSlot.accessory => _draft.accessory == item.id,
                        },
                        owned: me.owned.contains(item.id) || item.price == 0,
                        affordable: me.pips >= item.price,
                        previewAvatar: switch (item.slot) {
                          ItemSlot.face => _draft.copyWith(face: item.id),
                          ItemSlot.hat => _draft.copyWith(hat: item.id),
                          ItemSlot.accessory => _draft.copyWith(
                            accessory: item.id,
                          ),
                        },
                        onEquip: () => _equip(item),
                        onBuy: () => client.buy(item.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xxl,
        ),
        children: [
          SectionHeader(
            'Avatar',
            subtitle:
                'Every part is original Brickfolk art. Mix colours, then save.',
          ),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: Entrance(child: preview)),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    children: [
                      Entrance(
                        delay: const Duration(milliseconds: 60),
                        child: colors,
                      ),
                      const SizedBox(height: Space.lg),
                      Entrance(
                        delay: const Duration(milliseconds: 120),
                        child: wardrobe,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            Entrance(child: preview),
            const SizedBox(height: Space.lg),
            Entrance(delay: const Duration(milliseconds: 60), child: colors),
            const SizedBox(height: Space.lg),
            Entrance(delay: const Duration(milliseconds: 120), child: wardrobe),
          ],
        ],
      ),
    );
  }
}

Color _contrastOn(Color c) =>
    c.computeLuminance() > 0.5 ? BrickColors.ink : Colors.white;

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.equipped,
    required this.owned,
    required this.affordable,
    required this.previewAvatar,
    required this.onEquip,
    required this.onBuy,
  });

  final CatalogItem item;
  final bool equipped;
  final bool owned;
  final bool affordable;
  final Avatar previewAvatar;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return Panel(
      padding: const EdgeInsets.all(Space.sm),
      borderColor: equipped ? BrickColors.sky : null,
      color: equipped
          ? scheme.primaryContainer.withValues(alpha: 0.3)
          : p.surface2,
      onTap: owned ? onEquip : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              height: 72,
              child: ClipRect(
                child: Align(
                  alignment: item.slot == ItemSlot.hat
                      ? const Alignment(0, -0.6)
                      : const Alignment(0, -0.9),
                  heightFactor: item.slot == ItemSlot.accessory ? 0.7 : 0.45,
                  child: AvatarView(previewAvatar, size: 140),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            item.name,
            style: context.text.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            item.blurb,
            style: context.text.bodySmall?.copyWith(color: p.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Space.sm),
          if (equipped)
            const Tag(
              'Equipped',
              icon: Icons.check_rounded,
              color: BrickColors.sky,
              onColor: Colors.white,
            )
          else if (owned)
            Tag('Owned', color: p.surface3)
          else
            SizedBox(
              height: 30,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  minimumSize: const Size(0, 30),
                  textStyle: context.text.labelSmall,
                ),
                onPressed: affordable ? onBuy : null,
                icon: const PipIcon(size: 12),
                label: Text(formatNumber(item.price)),
              ),
            ),
        ],
      ),
    );
  }
}
