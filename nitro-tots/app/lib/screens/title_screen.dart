import 'dart:math' as math;

import 'package:flutter/material.dart';

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

class _TitleScreenState extends State<TitleScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..forward();
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final wide = size.width >= 900;
        final short = size.height < 650;
        final reduce = app.reduceMotion || MediaQuery.of(context).disableAnimations;
        final menu = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (app.resumeRoom != null) ...[
              NtCard(
                onTap: () => widget.onPlay(PlayMode.online),
                color: NtColors.nightRaised,
                accent: NtColors.lime,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.replay_rounded, color: NtColors.lime),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rejoin your match', style: NtType.label(Colors.white)),
                          Text('You are still in room ${app.resumeRoom}', style: NtType.small(const Color(0xFFB7CED5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (final (i, mode) in _modes.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _intro,
                    curve: Interval(i * 0.08, 0.6 + i * 0.08, curve: Curves.easeOut),
                  ),
                  child: _ModeRow(
                    number: i + 1,
                    title: mode.title,
                    detail: mode.detail,
                    icon: mode.icon,
                    color: mode.color,
                    featured: i == 0,
                    compact: short,
                    onTap: () => widget.onPlay(mode.mode),
                  ),
                ),
              ),
          ],
        );
        final profile = NtCard(
          color: const Color(0xEB102B3B),
          onTap: widget.onGarage,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Avatar(characterId: app.characterId, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: NtType.label(Colors.white)),
                    Text('${app.character.name} / ${app.kart.name}', style: NtType.small(const Color(0xFFB7CED5)), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('GARAGE', style: NtType.caption(NtColors.mint)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: NtColors.mint, size: 18),
            ],
          ),
        );
        return Scaffold(
          backgroundColor: NtColors.night,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: wide ? size.height : 360,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    child: Image.asset('assets/art/arcade-keyart.jpg', fit: BoxFit.cover, alignment: wide ? Alignment.centerRight : const Alignment(0.75, 0)),
                    builder: (_, child) => Transform.scale(scale: reduce ? 1 : 1.025 + _ambient.value * 0.025, child: child),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: wide
                      ? const LinearGradient(colors: [Color(0xFF071722), Color(0xEE071722), Color(0x55071722), Color(0x00071722)], stops: [0, 0.24, 0.53, 0.8])
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x22071722), NtColors.night],
                          stops: [0, 0.4],
                        ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: NtColors.mint, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'NITRO TOTS  /  RACING CLUB',
                              style: NtType.caption(Colors.white).copyWith(letterSpacing: 2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          NtIconButton(
                            icon: context.nt.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            tooltip: context.nt.isDark ? 'Light theme' : 'Dark theme',
                            color: Colors.white,
                            filled: false,
                            onPressed: () => app.update((s) => s.themeMode = context.nt.isDark ? ThemeMode.light : ThemeMode.dark),
                          ),
                          NtIconButton(icon: Icons.settings_rounded, tooltip: 'Settings', color: Colors.white, filled: false, onPressed: widget.onSettings),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(wide ? 56 : 20, wide ? 8 : 20, wide ? 56 : 20, 20),
                        child: Align(
                          alignment: wide ? Alignment.centerLeft : Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: wide ? 400 : 600),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ArcadeLogo(compact: short || !wide),
                                const SizedBox(height: 12),
                                Text('SMALL RACERS. BIG TROUBLE.', style: NtType.caption(NtColors.mint).copyWith(letterSpacing: 2.5)),
                                SizedBox(height: short ? 14 : 26),
                                menu,
                                const SizedBox(height: 8),
                                profile,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xDD071722),
                        border: Border(top: BorderSide(color: Color(0xFF254652))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: NtColors.mint, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text('READY TO RACE', style: NtType.caption(NtColors.mint)),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              wide ? '8 RACERS  /  4 WORLDS  /  ONE FINISH LINE' : 'CROSS-PLATFORM',
                              style: NtType.caption(const Color(0xFFAAC2CD)),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (wide)
                Positioned(
                  right: 40,
                  bottom: 82,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FULL THROTTLE.',
                          style: NtType.h1(Colors.white).copyWith(fontStyle: FontStyle.italic, shadows: const [Shadow(blurRadius: 10)]),
                        ),
                        Text('ZERO GROWN-UPS.', style: NtType.label(NtColors.mint).copyWith(letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

const _modes = [
  (mode: PlayMode.grandPrix, title: 'Grand Prix', detail: 'CHASE THE CUP', icon: Icons.emoji_events_rounded, color: NtColors.nitro),
  (mode: PlayMode.quickRace, title: 'Quick Race', detail: 'STRAIGHT TO THE GRID', icon: Icons.flag_rounded, color: NtColors.sky),
  (mode: PlayMode.timeTrial, title: 'Time Trial', detail: 'BEAT YOUR GHOST', icon: Icons.timer_rounded, color: NtColors.mint),
  (mode: PlayMode.battle, title: 'Battle', detail: 'MAKE SOME TROUBLE', icon: Icons.flash_on_rounded, color: NtColors.grape),
  (mode: PlayMode.online, title: 'Play Online', detail: 'RACE TOGETHER. ANYWHERE.', icon: Icons.public_rounded, color: NtColors.bubblegum),
];

class _ArcadeLogo extends StatelessWidget {
  const _ArcadeLogo({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 56.0 : 80.0;
    return Semantics(
      header: true,
      label: 'Nitro Tots',
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: -0.035,
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                Transform.translate(
                  offset: const Offset(3, 6),
                  child: Text('NITRO\nTOTS', style: NtType.hero(NtColors.nitroDeep).copyWith(fontSize: fontSize, height: 0.84, letterSpacing: 3)),
                ),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFFFDAA4)],
                  ).createShader(rect),
                  child: Text('NITRO\nTOTS', style: NtType.hero(Colors.white).copyWith(fontSize: fontSize, height: 0.84, letterSpacing: 3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.number,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.featured,
    required this.compact,
    required this.onTap,
  });
  final int number;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final bool featured;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NtCard(
      onTap: onTap,
      color: featured ? NtColors.nitro : const Color(0xED102B3B),
      accent: color,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 8 : 11),
      child: Row(
        children: [
          Icon(icon, color: featured ? Colors.white : color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NtType.h3(Colors.white).copyWith(fontSize: 21)),
                Text(detail, style: NtType.caption(featured ? Colors.white : const Color(0xFFB7CED5)).copyWith(fontSize: 9, letterSpacing: 1.4)),
              ],
            ),
          ),
          Text(number.toString().padLeft(2, '0'), style: NtType.mono(featured ? const Color(0xCCFFFFFF) : const Color(0xFF7298AA), size: 13)),
          const SizedBox(width: 12),
          Transform.rotate(
            angle: -math.pi / 4,
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
