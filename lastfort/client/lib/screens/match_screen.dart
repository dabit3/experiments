import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:flutter/services.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/scope.dart';
import '../app/theme.dart';
import '../app/widgets.dart';
import '../game/controls.dart';
import '../game/lastfort_game.dart';
import '../game/match_client.dart';
import '../net/connection.dart' as net;
import 'hud.dart';
import 'hud_panels.dart';
import 'touch_controls.dart';

/// Live match: Flame renderer underneath, HUD + touch controls on top.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.match});
  final MatchClient match;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late final Controls controls = Controls();
  late final LastfortGame game;
  final focus = FocusNode(debugLabel: 'match');
  bool touchSeen = false;
  late final AnimationController hudTick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  )..repeat();

  @override
  void initState() {
    super.initState();
    final scope = AppScope.read(context);
    final platform = scope.config.platformName;
    touchSeen = platform == 'ios' || platform == 'android';
    game = LastfortGame(
      client: widget.match,
      controls: controls,
      onInput: scope.session.sendInput,
      reducedMotion: scope.profile.reducedMotion,
      compact: touchSeen,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  @override
  void dispose() {
    hudTick.dispose();
    focus.dispose();
    controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final session = scope.session;
    final client = widget.match;
    final layout = LfLayout.of(context);
    final compact = layout.isPhone || touchSeen;
    final pad = MediaQuery.paddingOf(context);
    final inset = compact ? LfTokens.s3 : LfTokens.s4;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      body: Focus(
        focusNode: focus,
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            _MenuButton.open(context, onLeave: session.leaveMatch);
            return KeyEventResult.handled;
          }
          return controls.handleKey(e)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: (e) => controls.pointer = e.localPosition,
          onPointerMove: (e) {
            if (e.kind != PointerDeviceKind.touch)
              controls.pointer = e.localPosition;
          },
          onPointerDown: (e) {
            if (e.kind == PointerDeviceKind.touch) {
              if (!touchSeen) setState(() => touchSeen = true);
              return;
            }
            controls.pointer = e.localPosition;
            if (e.buttons & kSecondaryMouseButton != 0) {
              controls.queue(const GameAction(ActionType.interact));
            } else {
              controls.mouseFire = true;
            }
            focus.requestFocus();
          },
          onPointerUp: (e) {
            if (e.kind != PointerDeviceKind.touch) controls.mouseFire = false;
          },
          onPointerCancel: (_) => controls.mouseFire = false,
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              final me = client.me;
              if (me == null) return;
              final dir = e.scrollDelta.dy > 0 ? 1 : -1;
              controls.selectSlot(
                (me.selectedSlot + dir) % me.inventory.length,
              );
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.none,
            onExit: (_) => controls.pointer = null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: game),
                AnimatedBuilder(
                  animation: Listenable.merge([hudTick, client]),
                  builder: (context, _) => _Hud(
                    client: client,
                    controls: controls,
                    compact: compact,
                    inset: inset,
                    pad: pad,
                    layout: layout,
                  ),
                ),
                if (touchSeen)
                  ListenableBuilder(
                    listenable: Listenable.merge([hudTick, controls]),
                    builder: (context, _) => TouchControls(
                      controls: controls,
                      client: client,
                      haptics: scope.profile.haptics,
                    ),
                  ),
                _ReconnectOverlay(connection: session.connection),
                Positioned(
                  top: pad.top + inset,
                  left: pad.left + inset,
                  child: _MenuButton(onLeave: session.leaveMatch),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.client,
    required this.controls,
    required this.compact,
    required this.inset,
    required this.pad,
    required this.layout,
  });
  final MatchClient client;
  final Controls controls;
  final bool compact;
  final double inset;
  final EdgeInsets pad;
  final LfLayout layout;

  @override
  Widget build(BuildContext context) {
    final me = client.me;
    final sim = client.sim;
    final spectating = me != null && me.eliminated;
    final target = client.viewTarget;
    final mapSize = compact ? 112.0 : 168.0;
    final busPhase = sim.phase == MatchPhase.bus;
    final inBus = me?.state == PlayerState.inBus;
    final dropping = me?.state == PlayerState.dropping;

    return LayoutBuilder(
      builder: (context, box) {
        final compassWidth = compact ? 220.0 : 380.0;
        // The minimap cluster owns the top-right; when the compass cannot sit
        // between the menu button and that cluster it joins the left column.
        final sideWidth = pad.left + inset + mapSize + 16;
        final compassFits = box.maxWidth - 2 * sideWidth >= compassWidth;
        // Vitals and the hotbar share the bottom edge only when both fit;
        // otherwise the vitals stack above the hotbar column.
        final vitalsWidth = VitalsPanel.widthFor(compact);
        final hotbarWidth = HotbarPanel.widthFor(compact);
        final bottomFits =
            box.maxWidth - pad.horizontal - 3 * inset >=
            vitalsWidth + hotbarWidth;
        final showSquad = bottomFits || layout != LfLayout.phone;
        // On narrow screens the minimap and feed own the upper-right, so the
        // prompt drops toward the middle instead of overlapping them.
        final promptTop = compassFits
            ? pad.top + (compact ? 96 : 120)
            : math.max(pad.top + 132, box.maxHeight * 0.4);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Damage vignette.
            if (client.damageFlash > 0)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.1,
                      colors: [
                        Colors.transparent,
                        LfTokens.danger.withValues(
                          alpha: 0.45 * client.damageFlash,
                        ),
                      ],
                      stops: const [0.55, 1],
                    ),
                  ),
                ),
              ),
            if (target != null &&
                target.alive &&
                !sim.storm.contains(target.x, target.y))
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        LfTokens.storm.withValues(alpha: 0.35),
                      ],
                      stops: const [0.5, 1],
                    ),
                  ),
                ),
              ),

            // Top-left column under the menu button: compass (when it does
            // not fit centred) and the event feed.
            Positioned(
              top: pad.top + inset + 44,
              left: pad.left + inset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!busPhase && !compassFits) ...[
                    CompassStrip(client: client, width: compassWidth),
                    const SizedBox(height: 6),
                  ],
                  FeedPanel(client: client, compact: compact),
                ],
              ),
            ),

            // Top-center compass.
            if (!busPhase && compassFits)
              Positioned(
                top: pad.top + inset,
                left: 0,
                right: 0,
                child: Center(
                  child: CompassStrip(client: client, width: compassWidth),
                ),
              ),

            // Top-right: minimap, storm timer, alive / eliminations.
            Positioned(
              top: pad.top + inset,
              right: pad.right + inset,
              child: TopRightCluster(client: client, compact: compact),
            ),

            // Bottom-left: squad above the player's own shield / health.
            if (bottomFits)
              Positioned(
                left: pad.left + inset,
                bottom: pad.bottom + inset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSquad) ...[
                      SquadPanel(client: client, compact: compact),
                      const SizedBox(height: 6),
                    ],
                    VitalsPanel(client: client, compact: compact),
                  ],
                ),
              ),

            // Bottom-right: materials above the hotbar.
            Positioned(
              left: pad.left + inset,
              right: pad.right + inset,
              bottom: pad.bottom + inset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!bottomFits) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: VitalsPanel(client: client, compact: compact),
                    ),
                    const SizedBox(height: 6),
                  ],
                  MaterialsPanel(
                    client: client,
                    controls: controls,
                    compact: compact,
                  ),
                  const SizedBox(height: 6),
                  HotbarPanel(
                    client: client,
                    controls: controls,
                    compact: compact,
                  ),
                ],
              ),
            ),

            // Center prompts.
            if (inBus ||
                dropping ||
                spectating ||
                client.ended ||
                client.resumed && sim.tick < 40)
              Positioned(
                left: 0,
                right: 0,
                top: promptTop,
                child: Center(
                  child: _CenterPrompt(
                    client: client,
                    inBus: inBus,
                    dropping: dropping,
                    spectating: spectating,
                    touch: compact,
                  ),
                ),
              ),
            if (me != null && me.alive && !busPhase)
              Positioned(
                left: 0,
                right: 0,
                bottom: pad.bottom + inset + (compact ? 96 : 84),
                child: Center(
                  child: _InteractHint(client: client, touch: compact),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CenterPrompt extends StatelessWidget {
  const _CenterPrompt({
    required this.client,
    required this.inBus,
    required this.dropping,
    required this.spectating,
    required this.touch,
  });
  final MatchClient client;
  final bool inBus;
  final bool dropping;
  final bool spectating;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final me = client.me;
    if (client.ended) {
      final winner = client.summary?['winnerTeam'] as int?;
      final won = me != null && winner != null && me.team == winner;
      final placement = me?.stats.placement ?? 0;
      final accent = won ? LfTokens.warning : LfTokens.teal;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? 'LAST FORT STANDING' : 'MATCH OVER',
            style: hudCaps(13, color: accent).copyWith(letterSpacing: 3),
          ),
          const SizedBox(height: 6),
          HudSlab(
            strong: true,
            accent: accent,
            lean: 0.3,
            padding: const EdgeInsets.symmetric(
              horizontal: LfTokens.s7,
              vertical: LfTokens.s2,
            ),
            child: Text(
              won ? 'VICTORY' : 'PLACED #$placement',
              style: hudDigits(
                touch ? 30 : 40,
                color: accent,
              ).copyWith(letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 6),
          Text('Results in a moment', style: hudCaps(11)),
        ],
      );
    }
    if (spectating) {
      final t = client.viewTarget;
      final placement = me?.stats.placement ?? 0;
      return HudPanel(
        accent: LfTokens.teal,
        padding: const EdgeInsets.symmetric(
          horizontal: LfTokens.s4,
          vertical: LfTokens.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              placement > 0
                  ? 'ELIMINATED · #$placement'
                  : 'ELIMINATED · SQUAD STILL IN',
              style: hudLabel(context, color: LfTokens.danger),
            ),
            const SizedBox(height: 2),
            Text(
              t == null || t.id == me?.id
                  ? 'Spectating'
                  : 'Spectating ${t.name}',
              style: context.text.titleLarge?.copyWith(color: hudText),
            ),
            Text(
              touch
                  ? 'Tap NEXT to switch players'
                  : 'Press Tab to switch players',
              style: context.text.bodySmall?.copyWith(color: hudMuted),
            ),
          ],
        ),
      );
    }
    if (inBus) {
      return HudPanel(
        accent: LfTokens.teal,
        padding: const EdgeInsets.symmetric(
          horizontal: LfTokens.s4,
          vertical: LfTokens.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BALLOON BUS', style: hudLabel(context, color: LfTokens.teal)),
            const SizedBox(height: 2),
            Text(
              touch ? 'Tap JUMP to drop' : 'Press SPACE to drop',
              style: context.text.titleLarge?.copyWith(color: hudText),
            ),
            Text(
              client.busSecondsLeft < 3
                  ? 'Auto-drop imminent'
                  : 'Everyone still aboard drops at the end of the route',
              style: context.text.bodySmall?.copyWith(color: hudMuted),
            ),
          ],
        ),
      );
    }
    if (dropping) {
      final alt = (me?.altitude ?? 0).clamp(0.0, 1.0);
      return HudPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: LfTokens.s4,
          vertical: LfTokens.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GLIDING', style: hudLabel(context, color: LfTokens.teal)),
            const SizedBox(height: 4),
            SizedBox(
              width: 160,
              child: LfBar(
                value: 1 - alt,
                color: LfTokens.teal,
                height: 4,
                background: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Steer to pick a landing spot',
              style: context.text.bodySmall?.copyWith(color: hudMuted),
            ),
          ],
        ),
      );
    }
    return HudPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: LfTokens.s4,
        vertical: LfTokens.s2,
      ),
      child: Text(
        'Reconnected — welcome back',
        style: context.text.titleMedium?.copyWith(color: hudText),
      ),
    );
  }
}

/// Context hint for the nearest interactable (chest / loot / vehicle).
class _InteractHint extends StatelessWidget {
  const _InteractHint({required this.client, required this.touch});
  final MatchClient client;
  final bool touch;

  @override
  Widget build(BuildContext context) {
    final me = client.me;
    if (me == null) return const SizedBox.shrink();
    final sim = client.sim;
    final range = sim.rules.interactRange;
    final chest = sim.nearestChest(me.x, me.y, range);
    final loot = sim.nearestLoot(me.x, me.y, range);
    String? text;
    Color accent = LfTokens.warning;
    if (chest != null && !chest.opened) {
      text = 'Open chest';
    } else if (loot != null) {
      text = 'Pick up ${loot.item.label}';
      accent = LfTokens.rarity(loot.item.rarity);
    } else if (me.buildMode) {
      final tile = sim.targetTile(me, null, null);
      final ok =
          sim.canPlaceAt(me, tile.gx, tile.gy) &&
          me.materials[me.buildMaterial.index] >= sim.rules.pieceCost;
      text = ok
          ? '${touch ? 'Hold aim' : 'Click'} to place ${me.buildPiece.name}'
          : (me.materials[me.buildMaterial.index] < sim.rules.pieceCost
                ? 'Not enough ${me.buildMaterial.name}'
                : 'Cannot build here');
      accent = ok ? LfTokens.teal : LfTokens.danger;
    }
    if (text == null) return const SizedBox.shrink();
    return HudPanel(
      accent: accent,
      padding: const EdgeInsets.symmetric(horizontal: LfTokens.s3, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!me.buildMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                touch ? 'USE' : 'E',
                style: hudLabel(context, color: hudText),
              ),
            ),
          if (!me.buildMode) const SizedBox(width: 8),
          Text(text, style: context.text.labelLarge?.copyWith(color: hudText)),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onLeave});
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Match menu',
    child: GestureDetector(
      onTap: () => open(context, onLeave: onLeave),
      child: const HudPanel(
        padding: EdgeInsets.all(10),
        child: Icon(Icons.menu_rounded, color: hudText, size: 20),
      ),
    ),
  );

  static bool _showing = false;

  static Future<void> open(
    BuildContext context, {
    required VoidCallback onLeave,
  }) async {
    if (_showing) return;
    _showing = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave match?'),
        content: const Text(
          'You can rejoin from the lobby while the match is still running; your player stays in the world for 60 seconds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LfTokens.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    _showing = false;
    if (leave == true) onLeave();
  }
}

class _ReconnectOverlay extends StatelessWidget {
  const _ReconnectOverlay({required this.connection});
  final net.Connection connection;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: connection,
    builder: (context, _) {
      final show = connection.state != net.ConnectionState.connected;
      return IgnorePointer(
        ignoring: !show,
        child: AnimatedOpacity(
          duration: LfTokens.base,
          opacity: show ? 1 : 0,
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: LfPanel(
              strong: true,
              accent: LfTokens.warning,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: LfTokens.warning,
                    ),
                  ),
                  const SizedBox(height: LfTokens.s3),
                  Text('Reconnecting…', style: context.text.titleLarge),
                  const SizedBox(height: LfTokens.s1),
                  Text(
                    connection.lastError ??
                        'Your player is held in the match for 60 seconds.',
                    style: context.text.bodySmall?.copyWith(
                      color: context.lf.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
