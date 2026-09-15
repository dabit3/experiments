import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';

/// Locker: equip original Lastfort cosmetics per slot. Locked items show the
/// pass tier that unlocks them.
class LockerScreen extends StatefulWidget {
  const LockerScreen({super.key});

  @override
  State<LockerScreen> createState() => _LockerScreenState();
}

class _LockerScreenState extends State<LockerScreen> {
  CosmeticSlot slot = CosmeticSlot.outfit;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    final layout = LfLayout.of(context);
    final c = context.lf;
    final pad = layout.isPhone ? LfTokens.s4 : LfTokens.s6;

    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final items = cosmetics.where((k) => k.slot == slot).toList();
        final equipped = profile.equipped(slot);
        final preview = LfPanel(
          strong: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LfEyebrow('EQUIPPED'),
              const SizedBox(height: LfTokens.s3),
              Center(
                child: AnimatedSwitcher(
                  duration: LfTokens.base,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: LfTokens.spring),
                    ),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(equipped.id),
                    child: slot == CosmeticSlot.outfit
                        ? OutfitAvatar(
                            equipped,
                            size: layout.isPhone ? 120 : 168,
                          )
                        : CosmeticGlyph(
                            equipped,
                            size: layout.isPhone ? 120 : 168,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: LfTokens.s4),
              Text(equipped.name, style: context.text.headlineSmall),
              const SizedBox(height: LfTokens.s1),
              RarityBadge(equipped.rarity),
              const SizedBox(height: LfTokens.s3),
              Text(
                equipped.description,
                style: context.text.bodyMedium?.copyWith(color: c.muted),
              ),
              const SizedBox(height: LfTokens.s4),
              Divider(color: c.line, height: 1),
              const SizedBox(height: LfTokens.s3),
              const LfEyebrow('LOADOUT'),
              const SizedBox(height: LfTokens.s2),
              for (final s in CosmeticSlot.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: LfTokens.s1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          _slotLabel(s).toUpperCase(),
                          style: context.text.labelSmall?.copyWith(
                            color: c.muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          profile.equipped(s).name,
                          style: context.text.bodyMedium,
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: LfTokens.rarity(profile.equipped(s).rarity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );

        final grid = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: LfTokens.s2,
              runSpacing: LfTokens.s2,
              children: [
                for (final s in CosmeticSlot.values)
                  LfChip(
                    label: _slotLabel(s),
                    icon: _slotIcon(s),
                    selected: s == slot,
                    color: LfTokens.teal,
                    onTap: () => setState(() => slot = s),
                  ),
              ],
            ),
            const SizedBox(height: LfTokens.s4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: layout.isPhone ? 150 : 180,
                mainAxisSpacing: LfTokens.s3,
                crossAxisSpacing: LfTokens.s3,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final k = items[i];
                final owned = profile.owns(k.id);
                final isEquipped = k.id == equipped.id;
                final tier = passTiers
                    .where((t) => t.rewardId == k.id)
                    .map((t) => t.tier)
                    .firstOrNull;
                return _CosmeticCard(
                  cosmetic: k,
                  owned: owned,
                  equipped: isEquipped,
                  unlockTier: tier,
                  onTap: owned && !isEquipped
                      ? () {
                          HapticFeedback.lightImpact();
                          profile.equip(k);
                        }
                      : null,
                );
              },
            ),
          ],
        );

        return LfPage(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              pad,
              layout.isPhone ? LfTokens.s5 : LfTokens.s6,
              pad,
              LfTokens.s6,
            ),
            children: [
              Text('Locker', style: context.text.displaySmall),
              const SizedBox(height: LfTokens.s1),
              Text(
                'Original Lastfort cosmetics. Unlock more through the pass.',
                style: context.text.bodyLarge?.copyWith(color: c.muted),
              ),
              const SizedBox(height: LfTokens.s5),
              if (layout.isPhone) ...[
                preview,
                const SizedBox(height: LfTokens.s4),
                grid,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: layout.isDesktop ? 340 : 280,
                      child: preview,
                    ),
                    const SizedBox(width: LfTokens.s5),
                    Expanded(child: grid),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  static String _slotLabel(CosmeticSlot s) => switch (s) {
    CosmeticSlot.outfit => 'Outfit',
    CosmeticSlot.pickaxe => 'Tool',
    CosmeticSlot.glider => 'Glider',
    CosmeticSlot.banner => 'Banner',
  };

  static IconData _slotIcon(CosmeticSlot s) => switch (s) {
    CosmeticSlot.outfit => Icons.person_rounded,
    CosmeticSlot.pickaxe => Icons.hardware_rounded,
    CosmeticSlot.glider => Icons.paragliding_rounded,
    CosmeticSlot.banner => Icons.flag_rounded,
  };
}

class _CosmeticCard extends StatefulWidget {
  const _CosmeticCard({
    required this.cosmetic,
    required this.owned,
    required this.equipped,
    required this.unlockTier,
    required this.onTap,
  });
  final Cosmetic cosmetic;
  final bool owned;
  final bool equipped;
  final int? unlockTier;
  final VoidCallback? onTap;

  @override
  State<_CosmeticCard> createState() => _CosmeticCardState();
}

class _CosmeticCardState extends State<_CosmeticCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.lf;
    final k = widget.cosmetic;
    final rar = LfTokens.rarity(k.rarity);
    final border = widget.equipped
        ? LfTokens.ember
        : (hover && widget.onTap != null ? rar : c.line);
    return Semantics(
      button: widget.onTap != null,
      label:
          '${k.name}, ${k.rarity.label}${widget.owned ? (widget.equipped ? ', equipped' : '') : ', locked'}',
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: LfTokens.fast,
            transform: Matrix4.diagonal3Values(
              hover && widget.onTap != null ? 1.02 : 1.0,
              hover && widget.onTap != null ? 1.02 : 1.0,
              1,
            ),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(LfTokens.rMd),
              border: Border.all(color: border, width: widget.equipped ? 2 : 1),
              boxShadow: widget.equipped
                  ? [
                      BoxShadow(
                        color: LfTokens.ember.withValues(alpha: 0.25),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          rar.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(LfTokens.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: Opacity(
                            opacity: widget.owned ? 1 : 0.35,
                            child: k.slot == CosmeticSlot.outfit
                                ? OutfitAvatar(k, size: 64)
                                : CosmeticGlyph(k, size: 64),
                          ),
                        ),
                      ),
                      Text(
                        k.name,
                        style: context.text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      RarityBadge(k.rarity, compact: true),
                    ],
                  ),
                ),
                if (!widget.owned)
                  Positioned(
                    top: LfTokens.s2,
                    right: LfTokens.s2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.glassStrong,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 11, color: c.muted),
                          if (widget.unlockTier != null) ...[
                            const SizedBox(width: 3),
                            Text(
                              'TIER ${widget.unlockTier}',
                              style: context.text.labelSmall?.copyWith(
                                color: c.muted,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (widget.equipped)
                  Positioned(
                    top: LfTokens.s2,
                    right: LfTokens.s2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: LfTokens.ember,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'EQUIPPED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
