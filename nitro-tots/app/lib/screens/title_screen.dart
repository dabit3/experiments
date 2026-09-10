import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';

import '../game/kart_art.dart';
import '../state/app_state.dart';
import '../state/flow.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key, required this.app, required this.onPlay, required this.onSettings, required this.onGarage});
  final AppState app;
  final void Function(PlayMode mode) onPlay;
  final VoidCallback onSettings;
  final VoidCallback onGarage;

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 820;
    final short = size.height < 520;
    final app = widget.app;

    final menu = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MenuButton(
          label: 'Grand Prix',
          hint: 'Two cups · four tracks each',
          icon: Icons.emoji_events_rounded,
          color: NtColors.nitro,
          onTap: () => widget.onPlay(PlayMode.grandPrix),
          delay: 0,
          intro: _intro,
          autofocus: true,
        ),
        _MenuButton(
          label: 'Quick Race',
          hint: 'One track, up to 8 racers',
          icon: Icons.flag_rounded,
          color: NtColors.sky,
          onTap: () => widget.onPlay(PlayMode.quickRace),
          delay: 1,
          intro: _intro,
        ),
        _MenuButton(
          label: 'Time Trial',
          hint: 'Beat your ghost',
          icon: Icons.timer_rounded,
          color: NtColors.lime,
          onTap: () => widget.onPlay(PlayMode.timeTrial),
          delay: 2,
          intro: _intro,
        ),
        _MenuButton(
          label: 'Battle',
          hint: 'Balloon arena free-for-all',
          icon: Icons.sports_kabaddi_rounded,
          color: NtColors.grape,
          onTap: () => widget.onPlay(PlayMode.battle),
          delay: 3,
          intro: _intro,
        ),
        _MenuButton(
          label: 'Play Online',
          hint: 'Rooms, join codes, cross-platform',
          icon: Icons.public_rounded,
          color: NtColors.bubblegum,
          onTap: () => widget.onPlay(PlayMode.online),
          delay: 4,
          intro: _intro,
        ),
      ],
    );

    final profile = _ProfileCard(app: app, onTap: widget.onGarage);

    return Scaffold(
      body: NtBackdrop(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: NtSpace.x3,
                right: NtSpace.x3,
                child: Row(
                  children: [
                    NtIconButton(
                      icon: nt.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      tooltip: nt.isDark ? 'Light theme' : 'Dark theme',
                      onPressed: () => app.update((s) => s.themeMode = nt.isDark ? ThemeMode.light : ThemeMode.dark),
                    ),
                    const SizedBox(width: NtSpace.x2),
                    NtIconButton(icon: Icons.settings_rounded, tooltip: 'Settings', onPressed: widget.onSettings),
                  ],
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(NtSpace.x6, short ? NtSpace.x3 : NtSpace.x6, NtSpace.x6, NtSpace.x3),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _Logo(compact: short),
                                          if (!short) ...[const SizedBox(height: NtSpace.x6), _HeroKart(app: app)],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: NtSpace.x10),
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          profile,
                                          const SizedBox(height: NtSpace.x4),
                                          menu,
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _Logo(compact: true),
                                    const SizedBox(height: NtSpace.x4),
                                    profile,
                                    const SizedBox(height: NtSpace.x4),
                                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: menu),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: NtSpace.x2),
                    child: Text('An original arcade kart racer · play cross-platform', style: NtType.caption(nt.inkSoft)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = compact ? 0.62 : 1.0;
    return Semantics(
      header: true,
      label: 'Nitro Tots',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.06,
            child: Stack(
              children: [
                Text(
                  'NITRO',
                  style: NtType.hero(NtColors.inkDark).copyWith(
                    fontSize: 92 * scale,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 12 * scale
                      ..color = NtColors.inkDark,
                  ),
                ),
                Text('NITRO', style: NtType.hero(NtColors.sunny).copyWith(fontSize: 92 * scale)),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(0, -18 * scale),
            child: Transform.rotate(
              angle: 0.04,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 26 * scale, vertical: 6 * scale),
                decoration: BoxDecoration(
                  color: NtColors.nitro,
                  borderRadius: BorderRadius.circular(NtRadius.pill),
                  border: Border.all(color: NtColors.inkDark, width: 4 * scale),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 6), blurRadius: 10)],
                ),
                child: Text(
                  'TOTS',
                  style: NtType.hero(Colors.white).copyWith(fontSize: 54 * scale, letterSpacing: 6 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroKart extends StatefulWidget {
  const _HeroKart({required this.app});
  final AppState app;
  @override
  State<_HeroKart> createState() => _HeroKartState();
}

class _HeroKartState extends State<_HeroKart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return AnimatedBuilder(
      animation: Listenable.merge([_c, app]),
      builder: (_, _) {
        final bob = app.reduceMotion ? 0.0 : math.sin(_c.value * math.pi * 2) * 5;
        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 300,
                height: 60,
                margin: const EdgeInsets.only(top: 140),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
              ),
              Transform.translate(
                offset: Offset(0, bob),
                child: CustomPaint(size: const Size(260, 200), painter: _HeroPainter(app.kart, app.character, _c.value)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.kart, this.character, this.t);
  final Kart kart;
  final Character character;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 2 + 0.55);
    KartArt.drawKart(canvas, body: NtColors.forCharacter(character.id), kart: kart, scale: 5.2, time: t * 3);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) => old.t != t || old.kart != kart || old.character != character;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.app, required this.onTap});
  final AppState app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return AnimatedBuilder(
      animation: app,
      builder: (_, _) => NtCard(
        onTap: onTap,
        padding: const EdgeInsets.all(NtSpace.x3),
        child: Row(
          children: [
            Avatar(characterId: app.characterId, size: 52, ring: NtColors.forCharacter(app.characterId)),
            const SizedBox(width: NtSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: NtType.h3(nt.ink), overflow: TextOverflow.ellipsis),
                  Text('${app.character.name} · ${app.kart.name}', style: NtType.small(nt.inkSoft), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            NtChip('Garage', icon: Icons.garage_rounded, color: NtColors.sky),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
    required this.intro,
    this.autofocus = false,
  });
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  final Animation<double> intro;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final anim = CurvedAnimation(
      parent: intro,
      curve: Interval(0.1 * delay, math.min(1, 0.1 * delay + 0.6), curve: NtMotion.emphasized),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
        child: Padding(
          padding: const EdgeInsets.only(bottom: NtSpace.x3),
          child: NtCard(
            onTap: onTap,
            accent: color,
            padding: const EdgeInsets.symmetric(horizontal: NtSpace.x4, vertical: NtSpace.x3),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(NtRadius.md)),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: NtSpace.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: NtType.h3(nt.ink)),
                      Text(hint, style: NtType.small(nt.inkSoft)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: nt.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
