import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitro_core/nitro_core.dart';

import '../game/kart_art.dart';
import '../theme/tokens.dart';

enum NtButtonKind { primary, secondary, ghost, danger }

/// Chunky pill button with a pressed "sink" animation and keyboard focus ring.
class NtButton extends StatefulWidget {
  const NtButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = NtButtonKind.primary,
    this.color,
    this.expand = false,
    this.compact = false,
    this.autofocus = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NtButtonKind kind;
  final Color? color;
  final bool expand;
  final bool compact;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<NtButton> createState() => _NtButtonState();
}

class _NtButtonState extends State<NtButton> {
  bool _down = false;
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final enabled = widget.onPressed != null;
    final base = widget.color ?? (widget.kind == NtButtonKind.danger ? nt.danger : NtColors.nitro);
    final Color bg;
    final Color fg;
    final Color shadow;
    switch (widget.kind) {
      case NtButtonKind.primary:
      case NtButtonKind.danger:
        bg = base;
        fg = Colors.white;
        shadow = HSLColor.fromColor(base).withLightness((HSLColor.fromColor(base).lightness - 0.18).clamp(0, 1)).toColor();
      case NtButtonKind.secondary:
        bg = nt.surfaceRaised;
        fg = nt.ink;
        shadow = nt.outline;
      case NtButtonKind.ghost:
        bg = Colors.transparent;
        fg = widget.color ?? nt.inkSoft;
        shadow = Colors.transparent;
    }
    final lift = widget.kind == NtButtonKind.ghost ? 0.0 : (_down ? 0.0 : 4.0);
    final pad = widget.compact ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10) : const EdgeInsets.symmetric(horizontal: 26, vertical: 16);
    final style = (widget.compact ? NtType.label(fg) : NtType.h3(fg)).copyWith(fontSize: widget.compact ? 15 : 18);

    Widget child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: widget.compact ? 18 : 22), const SizedBox(width: NtSpace.x2)],
        Text(widget.label, style: style, textAlign: TextAlign.center),
      ],
    );

    child = AnimatedContainer(
      duration: NtMotion.fast,
      curve: Curves.easeOut,
      padding: pad,
      transform: Matrix4.translationValues(0, 4 - lift, 0),
      decoration: BoxDecoration(
        color: enabled ? (_hover && widget.kind != NtButtonKind.ghost ? Color.lerp(bg, Colors.white, 0.08) : bg) : bg.withValues(alpha: 0.45),
        gradient: enabled && widget.kind == NtButtonKind.primary
            ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(bg, Colors.white, 0.15)!, bg])
            : null,
        borderRadius: BorderRadius.circular(NtRadius.md),
        border: widget.kind == NtButtonKind.secondary ? Border.all(color: nt.outline, width: 2) : null,
        boxShadow: [
          if (widget.kind != NtButtonKind.ghost) BoxShadow(color: enabled ? shadow : shadow.withValues(alpha: 0.4), offset: Offset(0, lift), blurRadius: 0),
          if (_focus) BoxShadow(color: NtColors.sky.withValues(alpha: 0.7), spreadRadius: 3),
        ],
      ),
      child: child,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        shortcuts: const {SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(), SingleActivator(LogicalKeyboardKey.space): ActivateIntent()},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onPressed?.call();
                }
              : null,
          onTapCancel: () => setState(() => _down = false),
          child: Padding(padding: const EdgeInsets.only(bottom: 4), child: child),
        ),
      ),
    );
  }
}

/// Racing panel with keyboard, pointer and touch activation.
class NtCard extends StatelessWidget {
  const NtCard({super.key, required this.child, this.padding = const EdgeInsets.all(NtSpace.x5), this.accent, this.onTap, this.selected = false, this.color});

  final Widget child;
  final EdgeInsets padding;
  final Color? accent;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final base = color ?? nt.surface;
    final border = selected ? (accent ?? NtColors.nitro) : (color != null ? Colors.white.withValues(alpha: 0.18) : nt.outline);
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NtRadius.lg),
          boxShadow: selected ? NtElevation.glow((accent ?? NtColors.nitro).withValues(alpha: 0.4)) : NtElevation.soft(nt.shadow),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(NtRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(base, Colors.white, nt.isDark || color != null ? 0.04 : 0)!, base],
              ),
              borderRadius: BorderRadius.circular(NtRadius.lg),
              border: Border.all(color: border, width: selected ? 2.5 : 1),
            ),
            child: InkWell(
              onTap: onTap,
              hoverColor: (accent ?? NtColors.sky).withValues(alpha: 0.14),
              focusColor: (accent ?? NtColors.sky).withValues(alpha: 0.26),
              splashColor: (accent ?? NtColors.sky).withValues(alpha: 0.24),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded label chip.
class NtChip extends StatelessWidget {
  const NtChip(this.text, {super.key, this.color, this.icon, this.textColor});
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final c = color ?? nt.bgAlt;
    final fg = textColor ?? (color == null ? nt.inkSoft : Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(NtRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Text(text.toUpperCase(), style: NtType.caption(fg)),
        ],
      ),
    );
  }
}

/// Platform tag (web / iOS / Android / macOS / bot).
class PlatformBadge extends StatelessWidget {
  const PlatformBadge(this.platform, {super.key, this.compact = false});
  final String platform;
  final bool compact;

  static String labelFor(String p) => switch (p) {
    'web' => 'Web',
    'ios' => 'iOS',
    'android' => 'Android',
    'macos' => 'macOS',
    'bot' => 'Bot',
    _ => p,
  };

  static IconData iconFor(String p) => switch (p) {
    'web' => Icons.language_rounded,
    'ios' => Icons.phone_iphone_rounded,
    'android' => Icons.android_rounded,
    'macos' => Icons.laptop_mac_rounded,
    'bot' => Icons.smart_toy_rounded,
    _ => Icons.devices_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = NtColors.platformColors[platform] ?? NtColors.inkSoft;
    if (compact) {
      return Tooltip(
        message: labelFor(platform),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          child: Icon(iconFor(platform), size: 13, color: Colors.white),
        ),
      );
    }
    return NtChip(labelFor(platform), color: c, icon: iconFor(platform));
  }
}

/// Original racer portrait, with a vector fallback for unavailable assets.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.characterId, this.size = 44, this.bot = false, this.ring});
  final String characterId;
  final double size;
  final bool bot;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: characterById(characterId).name,
      child: Container(
        width: size + (ring != null ? 6 : 0),
        height: size + (ring != null ? 6 : 0),
        decoration: ring != null
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring!, width: 3),
              )
            : null,
        child: Center(
          child: ClipOval(
            child: Image.asset(
              'assets/art/${characterById(characterId).id}.jpg',
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => CustomPaint(size: Size.square(size), painter: _FacePainter(NtColors.forCharacter(characterId), bot)),
            ),
          ),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.color, this.bot);
  final Color color;
  final bool bot;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    KartArt.drawFace(canvas, color, size.width, bot: bot);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.color != color || old.bot != bot;
}

/// Kart preview (top-down) with optional idle wobble.
class KartPreview extends StatelessWidget {
  const KartPreview({super.key, required this.kart, required this.characterId, this.size = 120, this.angle = -math.pi / 2 + 0.35});
  final Kart kart;
  final String characterId;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _KartPainter(kart, NtColors.forCharacter(characterId), angle));
  }
}

class _KartPainter extends CustomPainter {
  _KartPainter(this.kart, this.color, this.angle);
  final Kart kart;
  final Color color;
  final double angle;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    KartArt.drawKart(canvas, body: color, kart: kart, scale: size.width / 34);
  }

  @override
  bool shouldRepaint(_KartPainter old) => old.kart != kart || old.color != color || old.angle != angle;
}

/// 1..5 stat bar row.
class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.label, required this.value, this.max = 5, this.color});
  final String label;
  final double value;
  final double max;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Semantics(
      label: '$label ${value.toStringAsFixed(1)} of ${max.toInt()}',
      child: Row(
        children: [
          SizedBox(width: 74, child: Text(label, style: NtType.caption(nt.inkSoft))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NtRadius.pill),
              child: Stack(
                children: [
                  Container(height: 10, color: nt.bgAlt),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (value / max).clamp(0.0, 1.0)),
                    duration: NtMotion.slow,
                    curve: NtMotion.emphasized,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color ?? NtColors.nitro, Color.lerp(color ?? NtColors.nitro, NtColors.sunny, 0.5)!]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed screen background: soft gradient + drifting confetti shapes.
class NtBackdrop extends StatefulWidget {
  const NtBackdrop({super.key, required this.child, this.animate = true, this.confetti = false});
  final Widget child;
  final bool animate;

  /// Celebration mode: brighter, faster, denser confetti.
  final bool confetti;

  @override
  State<NtBackdrop> createState() => _NtBackdropState();
}

class _NtBackdropState extends State<NtBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.confetti ? 7 : 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final reduce = MediaQuery.of(context).disableAnimations || !widget.animate;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: nt.isDark ? [const Color(0xFF16384D), NtColors.night] : [const Color(0xFFE9F6F6), const Color(0xFFF7F4EA)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) =>
                  CustomPaint(painter: widget.confetti ? _ConfettiPainter(reduce ? 0 : _c.value, nt.isDark, celebrate: true) : _CircuitPainter(nt.isDark)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = (dark ? NtColors.mint : NtColors.ink).withValues(alpha: dark ? 0.055 : 0.045)
      ..strokeWidth = 1;
    for (var i = -10; i < 30; i++) {
      final x = i * 90.0;
      canvas.drawLine(Offset(x, 0), Offset(x - size.height * 0.6, size.height), stroke);
    }
    final rect = Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.2), radius: size.width * 0.55);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            NtColors.sky.withValues(alpha: dark ? 0.14 : 0.1),
            NtColors.sky.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    for (var i = 0; i < 7; i++) {
      canvas.drawLine(Offset(size.width - 220 + i * 30, size.height), Offset(size.width + i * 30, size.height - 300), stroke..strokeWidth = 12);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.dark != dark;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.dark, {this.celebrate = false});
  final double t;
  final bool dark;
  final bool celebrate;

  static final _shapes = List.generate(26, (i) {
    final r = math.Random(i * 31 + 7);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      s: 10 + r.nextDouble() * 26,
      kind: i % 4,
      c: [NtColors.nitro, NtColors.bubblegum, NtColors.sky, NtColors.lime, NtColors.sunny, NtColors.grape, NtColors.mint][i % 7],
      sp: 0.4 + r.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _shapes) {
      final yy = (s.y + t * s.sp) % 1.2 - 0.1;
      final xx = s.x + math.sin((t * 6.28 + s.y * 10) * s.sp) * 0.02;
      final p = Offset(xx * size.width, yy * size.height);
      final paint = Paint()..color = s.c.withValues(alpha: celebrate ? 0.75 : (dark ? 0.16 : 0.22));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(t * 6.28 * s.sp + s.x * 6);
      switch (s.kind) {
        case 0:
          canvas.drawCircle(Offset.zero, s.s / 2, paint);
        case 1:
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s.s, height: s.s * 0.4), const Radius.circular(4)), paint);
        case 2:
          final path = Path()
            ..moveTo(0, -s.s / 2)
            ..lineTo(s.s / 2, s.s / 2)
            ..lineTo(-s.s / 2, s.s / 2)
            ..close();
          canvas.drawPath(path, paint);
        default:
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s.s * 0.7, height: s.s * 0.7), const Radius.circular(5)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.dark != dark || old.celebrate != celebrate;
}

/// Standard screen frame: backdrop, safe area, header with back button,
/// content constrained to a readable width, responsive paddings.
class NtScreen extends StatelessWidget {
  const NtScreen({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.maxWidth = 1100,
    this.scroll = true,
    this.footer,
    this.backdrop = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double maxWidth;
  final bool scroll;
  final Widget? footer;
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final w = MediaQuery.sizeOf(context).width;
    final pad = w < 480 ? NtSpace.x4 : (w < 900 ? NtSpace.x6 : NtSpace.x10);
    final header = Padding(
      padding: EdgeInsets.fromLTRB(pad, NtSpace.x3, pad, NtSpace.x2),
      child: Row(
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: NtSpace.x3),
              child: NtIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack!, tooltip: 'Back'),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: w < 480 ? NtType.h2(nt.ink) : NtType.h1(nt.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) Text(subtitle!, style: NtType.small(nt.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: EdgeInsets.fromLTRB(pad, NtSpace.x2, pad, NtSpace.x6), child: child),
      ),
    );
    final content = SafeArea(
      child: Column(
        children: [
          header,
          Expanded(child: scroll ? SingleChildScrollView(child: body) : body),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, NtSpace.x4),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: footer,
              ),
            ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: backdrop ? NtBackdrop(child: content) : content,
    );
  }
}

class NtIconButton extends StatelessWidget {
  const NtIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.color, this.size = 44, this.filled = true});
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: filled ? nt.surface : Colors.transparent,
          shape: CircleBorder(side: filled ? BorderSide(color: nt.outline, width: 2) : BorderSide.none),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: color ?? nt.ink, size: size * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section heading with a coloured dash.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.color, this.trailing});
  final String text;
  final Color? color;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Padding(
      padding: const EdgeInsets.only(bottom: NtSpace.x3, top: NtSpace.x2),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 6,
            decoration: BoxDecoration(color: color ?? NtColors.nitro, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: NtSpace.x2),
          Expanded(child: Text(text, style: NtType.h3(nt.ink))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Loading / empty / error state panel.
class StatePanel extends StatelessWidget {
  const StatePanel({super.key, required this.title, this.message, this.icon, this.loading = false, this.action, this.color});
  final String title;
  final String? message;
  final IconData? icon;
  final bool loading;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Center(
      child: NtCard(
        padding: const EdgeInsets.all(NtSpace.x8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(width: 56, height: 56, child: NtSpinner())
              else if (icon != null)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: (color ?? NtColors.nitro).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color ?? NtColors.nitro, size: 32),
                ),
              const SizedBox(height: NtSpace.x4),
              Text(title, style: NtType.h3(nt.ink), textAlign: TextAlign.center),
              if (message != null) ...[const SizedBox(height: NtSpace.x2), Text(message!, style: NtType.body(nt.inkSoft), textAlign: TextAlign.center)],
              if (action != null) ...[const SizedBox(height: NtSpace.x5), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Spinning tyre loader.
class NtSpinner extends StatefulWidget {
  const NtSpinner({super.key, this.color});
  final Color? color;
  @override
  State<NtSpinner> createState() => _NtSpinnerState();
}

class _NtSpinnerState extends State<NtSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _TyrePainter(_c.value, widget.color ?? NtColors.nitro)),
      ),
    );
  }
}

class _TyrePainter extends CustomPainter {
  _TyrePainter(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r - 4,
      Paint()
        ..color = KartArt.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 4),
      t * math.pi * 2,
      math.pi * 0.9,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );
    canvas.drawCircle(c, r * 0.32, Paint()..color = const Color(0xFF8E86A8));
  }

  @override
  bool shouldRepaint(_TyrePainter old) => old.t != t;
}

/// Place ordinal, e.g. 1st, 2nd.
String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

String formatTicks(int ticks) {
  if (ticks <= 0) return '--:--.--';
  final ms = (ticks * 1000 / ticksPerSecond).round();
  final m = ms ~/ 60000;
  final s = (ms % 60000) ~/ 1000;
  final h = (ms % 1000) ~/ 10;
  return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}.${h.toString().padLeft(2, '0')}';
}

Color placeColor(int place) => switch (place) {
  1 => NtColors.gold,
  2 => NtColors.silver,
  3 => NtColors.bronze,
  4 => NtColors.lime,
  5 => NtColors.mint,
  6 => NtColors.sky,
  7 => NtColors.grape,
  _ => NtColors.bubblegum,
};
