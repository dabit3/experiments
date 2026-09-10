import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:nitro_core/nitro_core.dart';

import '../game/controls.dart';
import '../game/hud.dart';
import '../game/race_game.dart';
import '../game/session.dart';
import '../net/client.dart';
import '../state/app_state.dart';
import '../state/audio.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';
import '../widgets/results_panel.dart';

/// Hosts the Flame canvas, HUD, input and the in-race overlays (pause,
/// race results). Works for both offline and online sessions.
class RaceScreen extends StatefulWidget {
  const RaceScreen({
    super.key,
    required this.session,
    required this.app,
    required this.feedback,
    required this.onQuit,
    required this.onContinue,
    this.client,
    this.scriptedDriver,
    this.cupStandings,
  });

  final RaceSession session;
  final AppState app;
  final NtFeedback feedback;
  final NetClient? client;

  /// Called when the player leaves mid-race or after results.
  final VoidCallback onQuit;

  /// Called when the player confirms the results panel (offline) or the
  /// server reports the next race / match end (online).
  final VoidCallback onContinue;

  /// Offline cup standings including the given race results, shown next to
  /// the per-race table between races.
  final List<Standing> Function(List<RaceResult> results)? cupStandings;

  /// Deterministic bot that drives the local kart in automated tests.
  final Autopilot? scriptedDriver;

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with SingleTickerProviderStateMixin {
  late final InputController _input = InputController(autoAccelerate: widget.app.autoAccelerate);
  late RaceGame _game;
  late final Ticker _ticker;
  final FocusNode _focus = FocusNode(debugLabel: 'race');
  bool _paused = false;
  bool _showResults = false;
  int _lastRacePhaseTick = -1;
  Timer? _resultsTimer;
  int _frame = 0;

  RaceSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _game = RaceGame(session: session, chaseCamera: widget.app.camera == CameraMode.chase, reduceMotion: widget.app.reduceMotion, onEvent: _onSimEvent);
    _ticker = createTicker(_tick)..start();
    session.results.addListener(_onResults);
    widget.client?.raceOutcome.addListener(_onNetOutcome);
    widget.client?.matchOutcome.addListener(_onNetOutcome);
    widget.feedback.music('music_race');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void didUpdateWidget(covariant RaceScreen old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.results.removeListener(_onResults);
      widget.session.results.addListener(_onResults);
      _game.swapSession(widget.session);
      _showResults = false;
      _paused = false;
      _resultsTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _resultsTimer?.cancel();
    session.results.removeListener(_onResults);
    widget.client?.raceOutcome.removeListener(_onNetOutcome);
    widget.client?.matchOutcome.removeListener(_onNetOutcome);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _focus.dispose();
    super.dispose();
  }

  void _onResults() {
    if (session.results.value == null || !mounted) return;
    widget.feedback.sfx('finish');
    widget.feedback.haptic(HapticsKind.heavy);
    if (!session.info.online) {
      _resultsTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showResults = true);
      });
    }
  }

  void _onNetOutcome() {
    if (!mounted) return;
    final c = widget.client!;
    if (c.matchOutcome.value != null) {
      widget.onContinue();
      return;
    }
    if (c.raceOutcome.value != null) {
      setState(() => _showResults = true);
    }
  }

  void _onSimEvent(SimEvent e) {
    final isMe = e.slot == session.localSlot;
    final fb = widget.feedback;
    switch (e.type) {
      case 'countdown':
        fb.sfx('countdown', volume: 0.7);
      case 'go':
        fb.sfx('go');
        fb.haptic(HapticsKind.medium);
      case 'miniTurbo':
        if (isMe) {
          fb.sfx('turbo');
          fb.haptic(HapticsKind.medium);
        }
      case 'pad':
      case 'rocketStart':
      case 'slipstream':
        if (isMe) fb.sfx('boost', volume: 0.8);
      case 'pickup':
        if (isMe) {
          fb.sfx('pickup');
          fb.haptic(HapticsKind.select);
        }
      case 'use':
        if (isMe) fb.sfx('use');
      case 'hit':
      case 'knockout':
        if (isMe) {
          fb.sfx('hit');
          fb.haptic(HapticsKind.heavy);
        } else {
          fb.sfx('hit', volume: 0.35, throttleMs: 200);
        }
      case 'wall':
      case 'bump':
        if (isMe) {
          fb.sfx('bump', volume: 0.7, throttleMs: 150);
          fb.haptic(HapticsKind.light);
        }
      case 'shieldPop':
        if (isMe) fb.sfx('shield');
      case 'jump':
        if (isMe) fb.sfx('jump', volume: 0.6);
      case 'trickLand':
      case 'land':
        if (isMe) fb.sfx('land', volume: 0.6);
      case 'lap':
        if (isMe) fb.sfx('lap');
      case 'wrongWay':
        if (isMe) fb.sfx('wrongway', volume: 0.6, throttleMs: 1500);
      case 'driftStart':
        if (isMe) fb.sfx('drift', volume: 0.5, throttleMs: 300);
    }
  }

  void _tick(Duration _) {
    if (!mounted) return;
    if (_input.consumePause()) _togglePause();
    if (!_paused) {
      if (widget.scriptedDriver != null) {
        final me = session.local;
        if (me != null) session.input = widget.scriptedDriver!.drive(session.sim, me);
      } else {
        session.input = _input.poll();
      }
    }
    // Countdown beeps come from the tick counter (the sim doesn't emit them).
    final sim = session.sim;
    if (sim.phase == RacePhase.countdown) {
      final left = countdownTicks - sim.tick;
      final sec = left ~/ ticksPerSecond;
      if (sec != _lastRacePhaseTick && sec <= 2) {
        _lastRacePhaseTick = sec;
        _onSimEvent(const SimEvent('countdown'));
      }
    }
    _frame++;
    setState(() {});
  }

  void _togglePause() {
    if (session.info.online) {
      setState(() => _paused = !_paused);
      return;
    }
    setState(() {
      _paused = !_paused;
      _paused ? _game.pauseEngine() : _game.resumeEngine();
    });
    widget.feedback.tap();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final touch = app.showTouchControls(context) && widget.scriptedDriver == null;
    final compact = MediaQuery.sizeOf(context).shortestSide < 480;
    _game.chaseCamera = app.camera == CameraMode.chase;
    _game.reduceMotion = app.reduceMotion;
    _input.autoAccelerate = app.autoAccelerate || touch && !app.isMobile;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (_, e) => _input.handleKey(e) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: _game),
            SafeArea(
              child: RaceHud(
                session: session,
                art: _game.art,
                compact: compact,
                rttMs: widget.client?.rttMs,
                bottomInset: touch ? TouchControls.heightFor(context) : 0,
              ),
            ),
            if (touch && !_showResults)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: TouchControls(input: _input, showGas: !app.autoAccelerate),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(top: compact ? 84 : 116, right: compact ? 10 : 16),
                  child: _showResults
                      ? const SizedBox.shrink()
                      : NtIconButton(icon: Icons.pause_rounded, tooltip: 'Pause', onPressed: _togglePause, color: Colors.white, filled: false, size: 40),
                ),
              ),
            ),
            if (_paused) _PauseMenu(online: session.info.online, onResume: _togglePause, onQuit: widget.onQuit, onRetry: null),
            if (_showResults)
              _ResultsOverlay(
                session: session,
                client: widget.client,
                cupStandings: widget.cupStandings,
                onContinue: () {
                  widget.feedback.tap();
                  widget.onContinue();
                },
                onQuit: widget.onQuit,
              ),
            if (widget.client != null && widget.client!.state == ConnState.reconnecting) const _ReconnectBanner(),
            // Frame counter used by the automation harness to confirm the render loop runs.
            if (app.testConfig.active)
              Positioned(
                left: 4,
                bottom: 4,
                child: Text('f$_frame', style: const TextStyle(fontSize: 8, color: Color(0x40FFFFFF))),
              ),
          ],
        ),
      ),
    );
  }
}

class _PauseMenu extends StatelessWidget {
  const _PauseMenu({required this.online, required this.onResume, required this.onQuit, required this.onRetry});
  final bool online;
  final VoidCallback onResume;
  final VoidCallback onQuit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: NtCard(
          padding: const EdgeInsets.all(NtSpace.x8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(online ? 'Race continues' : 'Paused', style: NtType.h1(context.nt.ink), textAlign: TextAlign.center),
                const SizedBox(height: NtSpace.x2),
                Text(
                  online ? 'Online races keep running while you are away.' : 'Take a breather, tot.',
                  style: NtType.body(context.nt.inkSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NtSpace.x6),
                NtButton(label: 'Resume', icon: Icons.play_arrow_rounded, onPressed: onResume, expand: true, autofocus: true),
                const SizedBox(height: NtSpace.x3),
                NtButton(
                  label: online ? 'Leave room' : 'Quit race',
                  icon: Icons.exit_to_app_rounded,
                  kind: NtButtonKind.secondary,
                  onPressed: onQuit,
                  expand: true,
                ),
                const SizedBox(height: NtSpace.x5),
                const _ControlsHelp(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlsHelp extends StatelessWidget {
  const _ControlsHelp();
  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    Widget key(String k, String what) => Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: nt.bgAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: nt.outline),
          ),
          child: Text(k, style: NtType.caption(nt.ink)),
        ),
        const SizedBox(width: 8),
        Text(what, style: NtType.small(nt.inkSoft)),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [key('↑ / W', 'Gas'), key('← →', 'Steer'), key('Space', 'Drift'), key('Z / Enter', 'Item'), key('Q', 'Look back'), key('Esc', 'Pause')],
    );
  }
}

class _ResultsOverlay extends StatelessWidget {
  const _ResultsOverlay({required this.session, required this.client, required this.onContinue, required this.onQuit, this.cupStandings});
  final RaceSession session;
  final NetClient? client;
  final List<Standing> Function(List<RaceResult> results)? cupStandings;
  final VoidCallback onContinue;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final outcome = client?.raceOutcome.value;
    final results = outcome?.results ?? session.results.value ?? const <RaceResult>[];
    final info = session.info;
    final isLast = outcome?.isLast ?? (info.raceIndex >= info.totalRaces - 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: NtMotion.slow,
      curve: NtMotion.emphasized,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 30), child: child),
      ),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(NtSpace.x4),
        child: ResultsPanel(
          title: info.mode == GameMode.battle ? 'Battle over!' : (info.timeTrial ? 'Time trial complete' : 'Race ${info.raceIndex + 1} of ${info.totalRaces}'),
          trackName: trackDefById(info.trackId).name,
          results: results,
          localSlot: session.localSlot,
          standings: outcome?.standings ?? cupStandings?.call(results),
          battle: info.mode == GameMode.battle,
          footer: client != null
              ? _NetFooter(client: client!, isLast: isLast, onQuit: onQuit)
              : Row(
                  children: [
                    Expanded(
                      child: NtButton(label: 'Quit', kind: NtButtonKind.secondary, onPressed: onQuit, expand: true),
                    ),
                    const SizedBox(width: NtSpace.x3),
                    Expanded(
                      flex: 2,
                      child: NtButton(
                        label: isLast ? 'See standings' : 'Next race',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: onContinue,
                        expand: true,
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _NetFooter extends StatelessWidget {
  const _NetFooter({required this.client, required this.isLast, required this.onQuit});
  final NetClient client;
  final bool isLast;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 18, height: 18, child: NtSpinner()),
              const SizedBox(width: NtSpace.x3),
              Expanded(child: Text(isLast ? 'Final standings coming up…' : 'Next race starting soon…', style: NtType.small(nt.inkSoft))),
            ],
          ),
        ),
        if (client.isHost) NtButton(label: isLast ? 'Finish' : 'Skip', compact: true, kind: NtButtonKind.secondary, onPressed: client.nextRace),
        const SizedBox(width: NtSpace.x2),
        NtButton(label: 'Leave', compact: true, kind: NtButtonKind.ghost, onPressed: onQuit),
      ],
    );
  }
}

class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: NtColors.nitro, borderRadius: BorderRadius.circular(NtRadius.pill)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 14, height: 14, child: NtSpinner(color: Colors.white)),
                const SizedBox(width: 8),
                Text('Reconnecting…', style: NtType.small(Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
