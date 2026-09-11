import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxelhearth_core/voxelhearth_core.dart';

import '../audio.dart';
import '../game/atlas.dart';
import '../game/game_controller.dart' show itemTileFor;
import 'arcade.dart';

/// Voxelhearth's pixel GUI system. Every widget here is laid out on a
/// "GUI pixel" grid: one GUI pixel is [Gui.of] logical pixels, so panels,
/// slots and buttons keep the same proportions on every platform.
class Gui {
  static int scaleFor(Size size) {
    final s = math.min(size.width ~/ 320, size.height ~/ 240);
    return s.clamp(2, 4);
  }

  static int of(BuildContext context) => scaleFor(MediaQuery.sizeOf(context));

  /// Size of the screen in GUI pixels.
  static Size guiSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = scaleFor(size);
    return Size(size.width / s, size.height / s);
  }
}

/// Palette shared by every pixel widget.
class Px {
  static const white = Color(0xffffffff);
  static const gray = Color(0xffb4ccd3);
  static const darkGray = Color(0xff404040);
  static const yellow = Hearth.gold;
  static const hoverText = Hearth.cream;
  static const red = Color(0xffff887d);
  static const green = Hearth.teal;
  static const aqua = Color(0xff8adcf0);
  static const gold = Hearth.gold;
  static const xp = Hearth.teal;

  static const panel = Color(0xffe6dfc9);
  static const panelLight = Hearth.cream;
  static const panelDark = Color(0xff8a9f9c);
  static const slot = Color(0xffafbeba);
  static const slotDark = Color(0xff5c7a7d);

  static const btn = Color(0xff214452);
  static const btnLight = Color(0xff4e7986);
  static const btnDark = Color(0xff102e3b);
  static const btnHover = Color(0xff326758);
  static const btnHoverLight = Hearth.teal;
  static const btnHoverDark = Color(0xff183e3b);
  static const btnDisabled = Color(0xff353535);
  static const btnDisabledLight = Color(0xff4d4d4d);
  static const btnDisabledDark = Color(0xff262626);

  static const dirtTint = Color(0xff404040);
  static const dirtTintLight = Color(0xff8a8a8a);
  static const listTint = Color(0xff202020);

  static const dim = Color(0xd0071e2b);
  static const dimDeep = Color(0xed071e2b);

  /// Font size in GUI pixels; one text line is [lineHeight] GUI pixels.
  static const font = 9.0;
  static const lineHeight = 10.0;

  /// Text shadow colour: the source colour at a quarter of its brightness.
  static Color shadowOf(Color c) {
    final v = c.toARGB32();
    return Color.fromARGB(v >> 24 & 0xff, (v >> 16 & 0xff) >> 2, (v >> 8 & 0xff) >> 2, (v & 0xff) >> 2);
  }
}

TextStyle pxStyle(int s, {Color color = Px.white, bool shadow = true, double size = 1}) => TextStyle(
  fontFamily: 'Pixelify',
  fontSize: Px.font * s * size,
  height: Px.lineHeight / Px.font,
  color: color,
  fontWeight: FontWeight.w400,
  decoration: TextDecoration.none,
  leadingDistribution: TextLeadingDistribution.even,
  shadows: shadow ? [Shadow(color: Px.shadowOf(color), offset: Offset(s * size, s * size))] : null,
);

/// Lays out [text] in the pixel font and returns the painter, ready to paint.
TextPainter pxPainter(
  String text,
  int s, {
  Color color = Px.white,
  bool shadow = true,
  double size = 1,
  double? maxWidth,
  TextAlign align = TextAlign.left,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: pxStyle(s, color: color, shadow: shadow, size: size),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? double.infinity);
  return tp;
}

class PxText extends StatelessWidget {
  const PxText(
    this.text, {
    super.key,
    this.color = Px.white,
    this.shadow = true,
    this.size = 1,
    this.align,
    this.maxLines,
    this.scale,
    this.overflow = TextOverflow.ellipsis,
  });
  final String text;
  final Color color;
  final bool shadow;
  final double size;
  final TextAlign? align;
  final int? maxLines;
  final int? scale;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    maxLines: maxLines,
    overflow: overflow,
    style: pxStyle(scale ?? Gui.of(context), color: color, shadow: shadow, size: size),
  );
}

/// Fills one GUI-pixel rectangle.
void pxRect(Canvas c, int s, double x, double y, double w, double h, Color color) {
  c.drawRect(Rect.fromLTWH(x * s, y * s, w * s, h * s), Paint()..color = color);
}

/// A 1-GUI-pixel frame with notched corners, like a classic bevelled widget.
void pxFrame(Canvas c, int s, double x, double y, double w, double h, Color color, {bool notch = true}) {
  final n = notch ? 1.0 : 0.0;
  pxRect(c, s, x + n, y, w - 2 * n, 1, color);
  pxRect(c, s, x + n, y + h - 1, w - 2 * n, 1, color);
  pxRect(c, s, x, y + n, 1, h - 2 * n, color);
  pxRect(c, s, x + w - 1, y + n, 1, h - 2 * n, color);
}

/// Draws a 16x16 atlas tile at GUI position (x, y) with crisp scaling.
void pxTile(Canvas c, ui.Image atlas, int s, int tile, double x, double y, {double size = 16, double opacity = 1}) {
  final tx = (tile % Tiles.columns) * Tiles.size, ty = (tile ~/ Tiles.columns) * Tiles.size;
  c.drawImageRect(
    atlas,
    Rect.fromLTWH(tx.toDouble(), ty.toDouble(), Tiles.size.toDouble(), Tiles.size.toDouble()),
    Rect.fromLTWH(x * s, y * s, size * s, size * s),
    Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..color = Color.fromRGBO(255, 255, 255, opacity),
  );
}

/// Paints an item stack into a 16x16 GUI cell at (x, y), count bottom-right.
void pxItem(Canvas c, ui.Image atlas, int s, ItemStack stack, double x, double y, {double opacity = 1}) {
  if (stack.isEmpty) return;
  pxTile(c, atlas, s, itemTileFor(stack.id), x, y, opacity: opacity);
  if (stack.count > 1) {
    final tp = pxPainter('${stack.count}', s, color: Px.white.withValues(alpha: opacity));
    final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(c, Offset((x + 17) * s - tp.width, (y + 14) * s - base));
  }
}

/// Classic 18x18 inset item slot.
void pxSlot(Canvas c, int s, double x, double y, {double size = 18}) {
  pxRect(c, s, x, y, size, size, Px.slot);
  pxRect(c, s, x, y, size - 1, 1, Px.slotDark);
  pxRect(c, s, x, y, 1, size - 1, Px.slotDark);
  pxRect(c, s, x + 1, y + size - 1, size - 1, 1, Px.panelLight);
  pxRect(c, s, x + size - 1, y + 1, 1, size - 1, Px.panelLight);
}

/// Bevelled container panel (light face, white top-left, dark bottom-right).
void pxPanel(Canvas c, int s, double x, double y, double w, double h) {
  pxRect(c, s, x + 1, y + 1, w - 2, h - 2, Px.panel);
  pxFrame(c, s, x, y, w, h, const Color(0xff000000));
  pxRect(c, s, x + 1, y + 1, w - 3, 2, Px.panelLight);
  pxRect(c, s, x + 1, y + 1, 2, h - 3, Px.panelLight);
  pxRect(c, s, x + 2, y + h - 3, w - 3, 2, Px.panelDark);
  pxRect(c, s, x + w - 3, y + 2, 2, h - 3, Px.panelDark);
  pxRect(c, s, x + w - 3, y + 1, 2, 2, Px.panel);
  pxRect(c, s, x + 1, y + h - 3, 2, 2, Px.panel);
}

/// Bevelled button face in one of three states.
void pxButtonFace(Canvas c, int s, double x, double y, double w, double h, {bool hover = false, bool enabled = true}) {
  final fill = !enabled
      ? Px.btnDisabled
      : hover
      ? Px.btnHover
      : Px.btn;
  final light = !enabled
      ? Px.btnDisabledLight
      : hover
      ? Px.btnHoverLight
      : Px.btnLight;
  final dark = !enabled
      ? Px.btnDisabledDark
      : hover
      ? Px.btnHoverDark
      : Px.btnDark;
  pxRect(c, s, x + 1, y + 1, w - 2, h - 2, fill);
  pxFrame(c, s, x, y, w, h, const Color(0xff000000));
  pxRect(c, s, x + 1, y + 1, w - 3, 1, light);
  pxRect(c, s, x + 1, y + 1, 1, h - 3, light);
  pxRect(c, s, x + 1, y + h - 3, w - 2, 2, dark);
  pxRect(c, s, x + w - 3, y + 1, 2, h - 3, dark);
}

/// Text with a 1-GUI-pixel outline on all four sides (used for level numbers).
void pxOutlinedText(Canvas c, int s, String text, double cx, double y, Color color, {Color outline = Colors.black}) {
  final o = pxPainter(text, s, color: outline, shadow: false);
  final x = cx * s - o.width / 2;
  for (final d in const [Offset(-1, 0), Offset(1, 0), Offset(0, -1), Offset(0, 1)]) {
    o.paint(c, Offset(x + d.dx * s, y * s + d.dy * s));
  }
  pxPainter(text, s, color: color, shadow: false).paint(c, Offset(x, y * s));
}

/// Tooltip box: near-black fill with a violet gradient border.
void pxTooltip(Canvas c, int s, List<String> lines, double x, double y, Size bounds) {
  final painters = [for (final l in lines) pxPainter(l, s)];
  var w = 0.0;
  for (final p in painters) {
    w = math.max(w, p.width / s);
  }
  final h = lines.length * Px.lineHeight + (lines.length > 1 ? 2 : 0);
  var bx = x + 12, by = y - 12;
  if ((bx + w + 8) * s > bounds.width) bx = x - 16 - w;
  if ((by + h + 8) * s > bounds.height) by = bounds.height / s - h - 8;
  if (by < 0) by = 0;
  pxRect(c, s, bx - 3, by - 4, w + 6, h + 8, const Color(0xf0100010));
  final border = Paint()
    ..shader = ui.Gradient.linear(Offset(0, (by - 3) * s), Offset(0, (by + h + 3) * s), [
      const Color(0x505000ff),
      const Color(0x5028007f),
    ])
    ..style = PaintingStyle.stroke
    ..strokeWidth = s.toDouble();
  c.drawRect(Rect.fromLTWH((bx - 2.5) * s, (by - 3.5) * s, (w + 5) * s, (h + 7) * s), border);
  var ty = by;
  for (final p in painters) {
    p.paint(c, Offset(bx * s, ty * s));
    ty += Px.lineHeight + (lines.length > 1 && p == painters.first ? 2 : 0);
  }
}

// ---------------------------------------------------------------- widgets

/// Repeating, tinted dirt texture used behind every menu.
class DirtBackground extends StatelessWidget {
  const DirtBackground({super.key, required this.dirt, this.tint, this.child});
  final ui.Image? dirt;

  /// Multiply tint; defaults to dark, or lighter under a light theme.
  final Color? tint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = tint ?? (Theme.of(context).brightness == Brightness.light ? Px.dirtTintLight : Px.dirtTint);
    return CustomPaint(painter: _DirtPainter(dirt, t, Gui.of(context)), child: child ?? const SizedBox.expand());
  }
}

class _DirtPainter extends CustomPainter {
  _DirtPainter(this.dirt, this.tint, this.s);
  final ui.Image? dirt;
  final Color tint;
  final int s;

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff193f4b), Hearth.ink, Color(0xff102b34)],
        ).createShader(Offset.zero & size),
    );
    final grid = Paint()
      ..color = const Color(0x0c70e2c4)
      ..strokeWidth = 1;
    final step = 24.0 * s;
    for (double x = -size.height; x < size.width; x += step) {
      c.drawLine(Offset(x, 0), Offset(x + size.height, size.height), grid);
      c.drawLine(Offset(x + size.height, 0), Offset(x, size.height), grid);
    }
    c.drawRect(Rect.fromLTWH(0, 0, size.width, s.toDouble()), Paint()..color = const Color(0x5070e2c4));
  }

  @override
  bool shouldRepaint(covariant _DirtPainter old) => old.dirt != dirt || old.tint != tint || old.s != s;
}

/// Translucent gradient drawn over the world behind in-game menus.
class DimBackground extends StatelessWidget {
  const DimBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Px.dim, Px.dimDeep]),
    ),
    child: child ?? const SizedBox.expand(),
  );
}

/// Standard 200x20 bevelled button. [width]/[height] are GUI pixels.
class PxButton extends StatefulWidget {
  const PxButton(
    this.label, {
    super.key,
    this.onPressed,
    this.width = 200,
    this.height = 20,
    this.sound = 'ui_tap',
    this.semanticsLabel,
    this.textColor,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final double width, height;
  final String sound;
  final String? semanticsLabel;
  final Color? textColor;
  final bool primary;

  @override
  State<PxButton> createState() => _PxButtonState();
}

class _PxButtonState extends State<PxButton> {
  bool _hover = false;
  bool _focus = false;
  bool _pressed = false;

  void _activate() {
    if (widget.onPressed == null) return;
    Sfx.play(widget.sound);
    HapticFeedback.selectionClick();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final enabled = widget.onPressed != null;
    final hover = (_hover || _focus) && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticsLabel ?? widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => setState(() => _focus = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: enabled ? _activate : null,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 140),
              transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: !enabled
                      ? const [Color(0xff203640), Color(0xff192e38)]
                      : widget.primary
                      ? [hover ? const Color(0xffffdfa2) : Hearth.gold, const Color(0xffe9a950)]
                      : [hover ? const Color(0xff2d5c63) : const Color(0xff214452), Hearth.navy],
                ),
                borderRadius: BorderRadius.circular(4.0 * s),
                border: Border.all(
                  color: hover
                      ? Hearth.teal
                      : widget.primary
                      ? Hearth.gold
                      : const Color(0xff476470),
                  width: hover ? 2 : 1,
                ),
                boxShadow: [
                  if (enabled)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: Offset(0, _pressed ? 1 : 3),
                      blurRadius: 0,
                    ),
                  if (hover) BoxShadow(color: Hearth.teal.withValues(alpha: 0.14), blurRadius: 16),
                ],
              ),
              child: SizedBox(
                width: widget.width * s,
                height: widget.height * s,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0 * s),
                    child: Text(
                      widget.label,
                      style: arcadeType(
                        Px.font * s,
                        color: !enabled
                            ? const Color(0xff82999f)
                            : widget.primary
                            ? Hearth.ink
                            : widget.textColor ?? Hearth.cream,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _ButtonPainter extends CustomPainter {
  _ButtonPainter(this.s, {required this.hover, required this.enabled});
  final int s;
  final bool hover, enabled;

  @override
  void paint(Canvas c, Size size) =>
      pxButtonFace(c, s, 0, 0, size.width / s, size.height / s, hover: hover, enabled: enabled);

  @override
  bool shouldRepaint(covariant _ButtonPainter old) => old.hover != hover || old.enabled != enabled || old.s != s;
}

/// A small square button showing a single glyph (used for touch HUD buttons).
class PxIconButton extends StatelessWidget {
  const PxIconButton(this.icon, {super.key, required this.label, this.onPressed, this.size = 20, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed == null
            ? null
            : () {
                Sfx.play('ui_tap');
                onPressed!();
              },
        child: CustomPaint(
          size: Size(size * s, size * s),
          painter: _ButtonPainter(s, hover: active, enabled: onPressed != null),
          child: SizedBox(
            width: size * s,
            height: size * s,
            child: Center(
              child: Icon(
                icon,
                size: size * s * 0.6,
                color: Px.white,
                shadows: [Shadow(offset: Offset(s * 1.0, s * 1.0), color: Px.shadowOf(Px.white))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Classic slider: a dark bevelled track with an 8-wide bevelled knob.
class PxSlider extends StatefulWidget {
  const PxSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.width = 200,
    this.height = 20,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double width, height;

  @override
  State<PxSlider> createState() => _PxSliderState();
}

class _PxSliderState extends State<PxSlider> {
  bool _hover = false;

  void _set(Offset local, int s) {
    final knob = 8 * s;
    final v = ((local.dx - knob / 2) / (widget.width * s - knob)).clamp(0.0, 1.0);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return Semantics(
      slider: true,
      label: widget.label,
      value: '${(widget.value * 100).round()}%',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _set(d.localPosition, s),
          onHorizontalDragUpdate: (d) => _set(d.localPosition, s),
          onHorizontalDragEnd: (_) => Sfx.play('ui_tap'),
          child: CustomPaint(
            size: Size(widget.width * s, widget.height * s),
            painter: _SliderPainter(s, widget.value, _hover),
            child: SizedBox(
              width: widget.width * s,
              height: widget.height * s,
              child: Center(child: PxText(widget.label, color: _hover ? Px.hoverText : Px.white, maxLines: 1)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter(this.s, this.value, this.hover);
  final int s;
  final double value;
  final bool hover;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width / s, h = size.height / s;
    pxButtonFace(c, s, 0, 0, w, h, enabled: false);
    final kx = (value * (w - 8)).roundToDouble();
    pxButtonFace(c, s, kx, 0, 8, h, hover: hover);
  }

  @override
  bool shouldRepaint(covariant _SliderPainter old) => old.value != value || old.hover != hover || old.s != s;
}

/// Single-line text field: black box, grey (white when focused) border.
class PxField extends StatefulWidget {
  const PxField({
    super.key,
    required this.controller,
    this.hint = '',
    this.label,
    this.width = 200,
    this.height = 20,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.focusNode,
    this.textColor = Px.white,
  });
  final TextEditingController controller;
  final String hint;
  final String? label;
  final double width, height;
  final ValueChanged<String>? onSubmitted, onChanged;
  final bool autofocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Color textColor;

  @override
  State<PxField> createState() => _PxFieldState();
}

class _PxFieldState extends State<PxField> {
  late FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant PxField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      _focus.removeListener(_onFocus);
      if (old.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final style = pxStyle(s, color: widget.textColor);
    final field = Container(
      width: widget.width * s,
      height: widget.height * s,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: _focus.hasFocus ? Px.white : Px.gray, width: s.toDouble()),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.0 * s),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        style: style,
        cursorColor: Px.white,
        cursorWidth: s.toDouble(),
        cursorRadius: Radius.zero,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: pxStyle(s, color: Px.gray),
          isCollapsed: true,
          isDense: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      ),
    );
    final label = widget.label;
    if (label == null) return field;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PxText(label, color: Px.gray),
        SizedBox(height: 2.0 * s),
        field,
      ],
    );
  }
}

/// Bevelled container panel widget; [width]/[height] are GUI pixels.
class PxPanel extends StatelessWidget {
  const PxPanel({super.key, required this.width, required this.height, this.child});
  final double width, height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return CustomPaint(
      painter: _PanelPainter(s),
      child: SizedBox(width: width * s, height: height * s, child: child),
    );
  }
}

class _PanelPainter extends CustomPainter {
  _PanelPainter(this.s);
  final int s;
  @override
  void paint(Canvas c, Size size) => pxPanel(c, s, 0, 0, size.width / s, size.height / s);
  @override
  bool shouldRepaint(covariant _PanelPainter old) => old.s != s;
}

/// Darker inset region used behind scrolling lists.
class PxListBox extends StatelessWidget {
  const PxListBox({super.key, required this.dirt, this.child});
  final ui.Image? dirt;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: DirtBackground(dirt: dirt, tint: Px.listTint),
          ),
          ?child,
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 4.0 * s,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 4.0 * s,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable list row: grey outline with an inner black line when selected.
class PxListEntry extends StatelessWidget {
  const PxListEntry({super.key, required this.child, this.selected = false, this.onTap, this.height = 36, this.width});
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              Sfx.play('ui_tap');
              onTap!();
            },
      child: Container(
        width: width == null ? null : width! * s,
        height: height * s,
        padding: EdgeInsets.all((selected ? 1.0 : 2.0) * s),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff245153) : const Color(0x80102e3b),
          border: Border.all(color: selected ? Hearth.teal : const Color(0xff2d4c58)),
          borderRadius: BorderRadius.circular(3.0 * s),
        ),
        child: child,
      ),
    );
  }
}

/// A single 18x18 item slot widget with hover highlight and tooltips.
class PxSlotWidget extends StatefulWidget {
  const PxSlotWidget({
    super.key,
    required this.stack,
    required this.atlas,
    this.onTap,
    this.onSecondaryTap,
    this.picked = false,
    this.selected = false,
    this.ghost = false,
    this.size = 18,
    this.hideCount = false,
    this.onHover,
  });
  final ItemStack stack;
  final ui.Image atlas;
  final VoidCallback? onTap, onSecondaryTap;
  final bool picked, selected, ghost, hideCount;
  final double size;
  final void Function(Offset? global)? onHover;

  @override
  State<PxSlotWidget> createState() => _PxSlotWidgetState();
}

class _PxSlotWidgetState extends State<PxSlotWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final label = widget.stack.isEmpty ? 'Empty slot' : '${widget.stack.def.name} x${widget.stack.count}';
    return Semantics(
      button: widget.onTap != null,
      label: label,
      child: MouseRegion(
        onEnter: (e) {
          setState(() => _hover = true);
          widget.onHover?.call(e.position);
        },
        onHover: (e) => widget.onHover?.call(e.position),
        onExit: (_) {
          setState(() => _hover = false);
          widget.onHover?.call(null);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onSecondaryTap: widget.onSecondaryTap,
          onLongPress: widget.onSecondaryTap,
          child: CustomPaint(
            size: Size(widget.size * s, widget.size * s),
            painter: _SlotPainter(
              s,
              widget.stack,
              widget.atlas,
              hover: _hover && (widget.onTap != null),
              picked: widget.picked,
              selected: widget.selected,
              ghost: widget.ghost,
              hideCount: widget.hideCount,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotPainter extends CustomPainter {
  _SlotPainter(
    this.s,
    this.stack,
    this.atlas, {
    required this.hover,
    required this.picked,
    required this.selected,
    required this.ghost,
    required this.hideCount,
    required this.size,
  });
  final int s;
  final ItemStack stack;
  final ui.Image atlas;
  final bool hover, picked, selected, ghost, hideCount;
  final double size;

  @override
  void paint(Canvas c, Size sz) {
    pxSlot(c, s, 0, 0, size: size);
    final inset = (size - 16) / 2;
    if (stack.isNotEmpty) {
      if (hideCount) {
        pxTile(c, atlas, s, itemTileFor(stack.id), inset, inset, opacity: ghost ? 0.4 : 1);
      } else {
        pxItem(c, atlas, s, stack, inset, inset, opacity: ghost ? 0.4 : (picked ? 0.5 : 1));
      }
    }
    if (hover) pxRect(c, s, 1, 1, size - 2, size - 2, const Color(0x80ffffff));
    if (picked) pxFrame(c, s, 0, 0, size, size, Px.yellow, notch: false);
    if (selected) pxFrame(c, s, -1, -1, size + 2, size + 2, Px.white, notch: false);
  }

  @override
  bool shouldRepaint(covariant _SlotPainter old) =>
      old.stack.id != stack.id ||
      old.stack.count != stack.count ||
      old.hover != hover ||
      old.picked != picked ||
      old.selected != selected ||
      old.ghost != ghost ||
      old.s != s;
}

/// Bare item icon (no slot) at 16 GUI pixels, count included.
class PxItemIcon extends StatelessWidget {
  const PxItemIcon(this.stack, this.atlas, {super.key, this.size = 16, this.hideCount = false});
  final ItemStack stack;
  final ui.Image atlas;
  final double size;
  final bool hideCount;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    return CustomPaint(size: Size(size * s, size * s), painter: _ItemPainter(s, stack, atlas, size, hideCount));
  }
}

class _ItemPainter extends CustomPainter {
  _ItemPainter(this.s, this.stack, this.atlas, this.size, this.hideCount);
  final int s;
  final ItemStack stack;
  final ui.Image atlas;
  final double size;
  final bool hideCount;

  @override
  void paint(Canvas c, Size sz) {
    if (stack.isEmpty) return;
    if (hideCount || size != 16) {
      pxTile(c, atlas, s, itemTileFor(stack.id), 0, 0, size: size);
    } else {
      pxItem(c, atlas, s, stack, 0, 0);
    }
  }

  @override
  bool shouldRepaint(covariant _ItemPainter old) =>
      old.stack.id != stack.id || old.stack.count != stack.count || old.s != s;
}

/// Screen scaffold: title at GUI y=15 (or [titleY]) on top of a background.
class PxScreen extends StatelessWidget {
  const PxScreen({super.key, required this.background, required this.child, this.title, this.titleY = 15, this.footer});
  final Widget background;
  final Widget child;
  final String? title;
  final double titleY;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final column = Column(
      children: [
        if (title != null) ...[
          SizedBox(height: titleY * s),
          ArcadeHeading(title!, compact: Gui.guiSize(context).height < 230),
          SizedBox(height: 10.0 * s),
        ],
        Expanded(child: child),
        ?footer,
      ],
    );
    // When the on-screen keyboard shrinks the viewport below the screen's
    // natural height, scroll instead of overflowing.
    final minHeight = 170.0 * s;
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        SafeArea(
          child: LayoutBuilder(
            builder: (context, bc) => bc.maxHeight >= minHeight
                ? column
                : SingleChildScrollView(
                    child: SizedBox(height: minHeight, child: column),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Blocky extruded wordmark used on the title screen.
class PxWordmark extends StatelessWidget {
  const PxWordmark({super.key, this.size = 3});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = Gui.of(context);
    final depth = (size * 1.4).round();
    return Text(
      'VOXELHEARTH',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Pixelify',
        fontSize: Px.font * s * size,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: const Color(0xffe6e6e6),
        letterSpacing: s * 0.5,
        decoration: TextDecoration.none,
        shadows: [
          for (var i = 1; i <= depth; i++)
            Shadow(
              color: i == depth ? const Color(0xff1e1e1e) : const Color(0xff4b4b4b),
              offset: Offset(i * s * 1.0, i * s * 1.0),
            ),
        ],
      ),
    );
  }
}

/// Text label describing a platform, using the classic chat colour codes.
Color platformColor(String platform) => switch (platform) {
  'web' => Px.aqua,
  'ios' => Px.white,
  'android' => Px.green,
  'macos' => const Color(0xffff55ff),
  _ => Px.gray,
};

String platformLabel(String platform) => switch (platform) {
  'web' => 'Web',
  'ios' => 'iOS',
  'android' => 'Android',
  'macos' => 'macOS',
  'bot' => 'Bot',
  _ => platform,
};

/// Formats a tick count as m:ss.
String fmtTicks(int ticks) {
  final secs = (ticks / WorldConst.ticksPerSecond).round();
  return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
}
