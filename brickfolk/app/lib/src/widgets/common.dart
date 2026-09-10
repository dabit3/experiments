import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'avatar_painter.dart';

/// Elevated panel with the Brickfolk card treatment.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.color,
    this.borderColor,
    this.radius = Radii.lg,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final decoration = BoxDecoration(
      color: color ?? p.surface1,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? p.outline),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: p.shadow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
    );
    final body = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: body);
    }
    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: body),
      ),
    );
  }
}

/// Small pill label.
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color, this.icon, this.onColor});

  final String label;
  final Color? color;
  final Color? onColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = color ?? p.surface2;
    final fg = onColor ?? p.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm + 2,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: context.text.labelSmall?.copyWith(color: fg),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Currency chip showing the player's Pips.
class PipChip extends StatelessWidget {
  const PipChip(this.pips, {super.key, this.compact = false});

  final int pips;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.sm : Space.md,
        vertical: compact ? Space.xs : Space.sm - 2,
      ),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: p.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PipIcon(size: 16),
          const SizedBox(width: Space.xs + 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: pips, end: pips),
            duration: Motion.slow,
            builder: (_, v, _) => Text(
              _formatNumber(v),
              style:
                  (compact ? context.text.labelMedium : context.text.labelLarge)
                      ?.copyWith(
                        color: p.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatNumber(int v) => _formatNumber(v);

/// The Pip coin glyph (original art).
class PipIcon extends StatelessWidget {
  const PipIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _PipPainter());
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFCB9A1C));
    canvas.drawCircle(
      c.translate(0, -r * 0.08),
      r * 0.88,
      Paint()..color = BrickColors.sun,
    );
    final stud = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c.translate(0, -r * 0.05),
        width: r * 0.9,
        height: r * 0.9,
      ),
      Radius.circular(r * 0.2),
    );
    canvas.drawRRect(stud, Paint()..color = const Color(0xFFFFE08A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c.translate(0, r * 0.1),
          width: r * 0.9,
          height: r * 0.35,
        ),
        Radius.circular(r * 0.1),
      ),
      Paint()..color = const Color(0xFFE0B23A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Row showing a player: avatar, name, platform tag.
class PlayerTile extends StatelessWidget {
  const PlayerTile(
    this.player, {
    super.key,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.dense = false,
    this.highlight = false,
  });

  final PlayerSummary player;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool dense;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: dense ? Space.sm : Space.md,
          ),
          decoration: highlight
              ? BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(Radii.md),
                )
              : null,
          child: Row(
            children: [
              AvatarView(
                player.avatar,
                size: dense ? 34 : 44,
                background: p.surface2,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: context.text.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        PlatformTag(player),
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.text.bodySmall?.copyWith(
                          color: p.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Space.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PlatformTag extends StatelessWidget {
  const PlatformTag(this.player, {super.key});

  final PlayerSummary player;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (player.isBot) {
      return Tag(
        'BOT',
        icon: Icons.smart_toy_outlined,
        color: p.surface3,
        onColor: p.textSecondary,
      );
    }
    final (label, icon) = switch (player.platform) {
      'web' => ('Web', Icons.language),
      'ios' => ('iOS', Icons.phone_iphone),
      'android' => ('Android', Icons.android),
      'macos' => ('macOS', Icons.laptop_mac),
      _ => (player.platform, Icons.devices_other),
    };
    return Tag(
      label,
      icon: icon,
      color: player.online
          ? BrickColors.sky.withValues(alpha: 0.16)
          : p.surface2,
      onColor: player.online
          ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9DBBFF)
                : BrickColors.skyDark)
          : p.textTertiary,
    );
  }
}

/// Section title with optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineSmall),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xxs),
                    child: Text(
                      subtitle!,
                      style: context.text.bodySmall?.copyWith(
                        color: p.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Friendly empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: Icon(icon, size: 30, color: p.textTertiary),
            ),
            const SizedBox(height: Space.lg),
            Text(
              title,
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (action != null) ...[const SizedBox(height: Space.lg), action!],
          ],
        ),
      ),
    );
  }
}

/// Copyable join code display.
class CodeBadge extends StatelessWidget {
  const CodeBadge(this.code, {super.key, this.label = 'Code'});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: 'Copy code',
      child: Material(
        color: p.surface2,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text('Copied $code')));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.text.labelSmall?.copyWith(
                    color: p.textTertiary,
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  code,
                  style: context.text.titleMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: Space.xs),
                Icon(Icons.copy_rounded, size: 14, color: p.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge medallion.
class BadgeChip extends StatelessWidget {
  const BadgeChip(
    this.badgeId, {
    super.key,
    this.size = 40,
    this.showLabel = false,
    this.locked = false,
  });

  final String badgeId;
  final double size;
  final bool showLabel;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final def = badgeById[badgeId];
    final p = context.palette;
    final color = locked ? p.surface3 : Color(def?.color ?? 0xFF888888);
    final medal = Tooltip(
      message: def == null ? badgeId : '${def.name}\n${def.description}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.25)!, color],
          ),
          boxShadow: locked
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(
          locked ? Icons.lock_outline_rounded : _badgeIcon(badgeId),
          size: size * 0.5,
          color: locked ? p.textTertiary : Colors.white,
        ),
      ),
    );
    if (!showLabel) return medal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        medal,
        const SizedBox(height: Space.xs),
        Text(
          def?.name ?? badgeId,
          style: context.text.labelSmall?.copyWith(color: p.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

IconData _badgeIcon(String id) => switch (id) {
  'first_steps' => Icons.directions_walk_rounded,
  'summit' => Icons.flag_rounded,
  'speedrunner' => Icons.bolt_rounded,
  'founder' => Icons.foundation_rounded,
  'magnate' => Icons.account_balance_rounded,
  'untouchable' => Icons.shield_rounded,
  'it_factor' => Icons.ac_unit_rounded,
  'social' => Icons.favorite_rounded,
  'streak_3' => Icons.local_fire_department_rounded,
  'welcome' => Icons.waving_hand_rounded,
  _ => Icons.star_rounded,
};

/// Sticky status banner used for reconnecting/offline states.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.trailing,
  });

  final String text;
  final Color color;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.sm,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: Space.sm),
              ],
              Expanded(
                child: Text(
                  text,
                  style: context.text.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple staggered fade+slide entrance.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.slow + delay,
      curve: Interval(
        delay.inMilliseconds / (Motion.slow + delay).inMilliseconds,
        1,
        curve: Motion.standard,
      ),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Constrains content width on large screens and centres it.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.max = 1100});

  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}

Color experienceColor(ExperienceKind kind) => Color(placeFor(kind).accent);

IconData experienceIcon(ExperienceKind kind) => switch (kind) {
  ExperienceKind.obby => Icons.terrain_rounded,
  ExperienceKind.tycoon => Icons.factory_rounded,
  ExperienceKind.tag => Icons.ac_unit_rounded,
};
