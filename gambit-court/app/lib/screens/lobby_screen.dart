import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/board/piece_glyph.dart';
import '../widgets/top_bar.dart';
import '../widgets/ui.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < GcBreakpoints.tablet;
    return Column(
      children: [
        TopBar(controller: controller, compact: compact),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _Backdrop()),
              _LobbyContent(controller: controller, compact: compact),
              if (controller.queued)
                Positioned.fill(child: _QueueOverlay(controller: controller)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Backdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -1),
            radius: 1.4,
            colors: [
              GcArcade.royal.withValues(alpha: context.isDark ? 0.35 : 0.12),
              c.bg.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyContent extends StatelessWidget {
  const _LobbyContent({required this.controller, required this.compact});
  final AppController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? GcSpace.md : GcSpace.xl;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        pad,
        pad,
        pad,
        pad + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(compact: compact),
              SizedBox(height: compact ? GcSpace.lg : GcSpace.xl),
              if (compact) ...[
                _PlayCard(controller: controller, compact: true),
                const SizedBox(height: GcSpace.lg),
                _JoinCard(controller: controller),
                const SizedBox(height: GcSpace.lg),
                _TablesCard(controller: controller),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _PlayCard(controller: controller)),
                    const SizedBox(width: GcSpace.xl),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _JoinCard(controller: controller),
                          const SizedBox(height: GcSpace.lg),
                          _TablesCard(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: GcSpace.lg),
              _ReviewCard(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 242 : 320,
      decoration: BoxDecoration(
        color: GcArcade.royal,
        borderRadius: GcRadius.xlAll,
        border: Border.all(color: const Color(0xFF4C72DC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 600;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: narrow ? -100 : 0,
                width: narrow ? 365 : box.maxWidth * 0.66,
                child: Image.asset(
                  'assets/art/arena.png',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GcArcade.royal,
                      GcArcade.royal.withValues(alpha: narrow ? 0.88 : 0.92),
                      GcArcade.royal.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.3, 0.76],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(narrow ? 22 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'THE CLASSIC. A NEW ARENA.',
                      style: GcType.label(GcArcade.aqua, size: narrow ? 9 : 11),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'YOUR NEXT\nBRILLIANT\nMOVE.',
                      style:
                          GcType.display(
                            GcArcade.porcelain,
                            size: narrow ? 27 : 44,
                          ).copyWith(
                            shadows: const [
                              Shadow(
                                color: GcArcade.midnight,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      narrow ? 'Big plays. Any device.' : 'Play a friend. Challenge the court.\nMake every move count.',
                      style: GcType.body(
                        GcArcade.porcelain,
                        size: narrow ? 12 : 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({required this.controller, this.compact = false});
  final AppController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final tc = controller.timeControl;
    return GcCard(
      raised: true,
      padding: EdgeInsets.all(compact ? GcSpace.lg : GcSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LET’S PLAY', style: GcType.display(c.text, size: 20)),
              const Spacer(),
              GcPill(
                label: '${tc.category} · ${tc.label}',
                color: c.brass,
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: GcSpace.lg),
          Row(
            children: [
              Expanded(
                child: _ModeTile(
                  label: 'Quick pair',
                  caption: 'Find your next rival',
                  icon: Icons.bolt_rounded,
                  primary: true,
                  onTap: controller.ready ? controller.quickPair : null,
                ),
              ),
              const SizedBox(width: GcSpace.md),
              Expanded(
                child: _ModeTile(
                  label: 'Play the bot',
                  caption: 'Train with the court',
                  icon: Icons.smart_toy_rounded,
                  onTap: controller.ready
                      ? () => controller
                            .createRoom(withBot: true, isPublic: false)
                            .ignore()
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: GcSpace.lg),
          Row(
            children: [
              Expanded(
                child: GcButton(
                  label: 'Create invite',
                  icon: Icons.link_rounded,
                  expand: true,
                  onPressed: controller.ready
                      ? () => controller.createRoom(isPublic: false).ignore()
                      : null,
                ),
              ),
              const SizedBox(width: GcSpace.sm),
              Expanded(
                child: GcButton(
                  label: 'Open table',
                  icon: Icons.public_rounded,
                  expand: true,
                  onPressed: controller.ready
                      ? () => controller.createRoom(isPublic: true).ignore()
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: GcSpace.md),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: GcSpace.sm),
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: c.textMuted,
            collapsedIconColor: c.textMuted,
            title: Text(
              'Match settings',
              style: GcType.heading(c.text, size: 14),
            ),
            subtitle: Text(
              '${tc.label} clock · ${controller.sidePreference.name} pieces · ${controller.botLevel.label} bot',
              style: GcType.body(c.textMuted, size: 12),
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GcLabel('Time control'),
                  const SizedBox(height: GcSpace.sm),
                  _TimeControlPicker(controller: controller),
                  const SizedBox(height: GcSpace.lg),
                  Wrap(
                    spacing: GcSpace.xl,
                    runSpacing: GcSpace.lg,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GcLabel('Play as'),
                          const SizedBox(height: GcSpace.sm),
                          Wrap(
                            spacing: GcSpace.sm,
                            runSpacing: GcSpace.sm,
                            children: [
                              for (final pref in SidePreference.values)
                                _SideChip(
                                  pref: pref,
                                  selected: controller.sidePreference == pref,
                                  onTap: () =>
                                      controller.setSidePreference(pref),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GcLabel('Bot strength'),
                          const SizedBox(height: GcSpace.sm),
                          Wrap(
                            spacing: GcSpace.sm,
                            runSpacing: GcSpace.sm,
                            children: [
                              for (final level in EngineLevel.values)
                                GcChip(
                                  label: level.label,
                                  selected: controller.botLevel == level,
                                  onTap: () => controller.setBotLevel(level),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final String caption;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final ink = primary ? GcArcade.midnight : c.text;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: GcRadius.lgAll,
          boxShadow: [
            BoxShadow(
              color: primary ? const Color(0xFF987018) : c.surfaceSunken,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: primary ? GcArcade.sunshine : c.surfaceSunken,
          shape: RoundedRectangleBorder(
            borderRadius: GcRadius.lgAll,
            side: BorderSide(
              color: primary ? GcArcade.sunshine : c.borderStrong,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: primary ? ink : c.verdigris, size: 28),
                  const SizedBox(height: 10),
                  Text(label, style: GcType.heading(ink, size: 16)),
                  const SizedBox(height: 4),
                  Text(caption, style: GcType.body(ink, size: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideChip extends StatelessWidget {
  const _SideChip({
    required this.pref,
    required this.selected,
    required this.onTap,
  });
  final SidePreference pref;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final label = switch (pref) {
      SidePreference.white => 'White',
      SidePreference.black => 'Black',
      SidePreference.random => 'Random',
    };
    Widget icon;
    if (pref == SidePreference.random) {
      icon = Icon(
        Icons.shuffle_rounded,
        size: 18,
        color: selected ? c.brass : c.textMuted,
      );
    } else {
      icon = PieceGlyph(
        Piece(
          pref == SidePreference.white ? PieceColor.white : PieceColor.black,
          PieceType.king,
        ),
        size: 20,
      );
    }
    return Semantics(
      selected: selected,
      button: true,
      label: 'Play as $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: GcRadius.mdAll,
          child: AnimatedContainer(
            duration: GcMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? c.brassSoft : c.surfaceSunken,
              borderRadius: GcRadius.mdAll,
              border: Border.all(
                color: selected ? c.brass : c.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GcType.body(
                    selected ? c.text : c.textMuted,
                    size: 13,
                    weight: FontWeight.w600,
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

class _TimeControlPicker extends StatelessWidget {
  const _TimeControlPicker({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final groups = <String, List<TimeControl>>{};
    for (final tc in TimeControl.presets) {
      groups.putIfAbsent(tc.category, () => []).add(tc);
    }
    final selected = controller.timeControl;
    final isCustom =
        !TimeControl.presets.contains(selected) && !selected.isUnlimited;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(entry.key, style: GcType.label(c.textFaint, size: 10)),
          ),
          Wrap(
            spacing: GcSpace.sm,
            runSpacing: GcSpace.sm,
            children: [
              for (final tc in entry.value)
                GcChip(
                  label: tc.label,
                  selected: selected == tc,
                  onTap: () => controller.setTimeControl(tc),
                ),
            ],
          ),
        ],
        const SizedBox(height: GcSpace.sm),
        Wrap(
          spacing: GcSpace.sm,
          runSpacing: GcSpace.sm,
          children: [
            GcChip(
              label: isCustom ? selected.label : 'Custom',
              icon: Icons.tune_rounded,
              selected: isCustom,
              onTap: () => _showCustom(context),
            ),
            GcChip(
              label: 'No clock',
              icon: Icons.all_inclusive_rounded,
              selected: selected.isUnlimited,
              onTap: () => controller.setTimeControl(TimeControl.unlimited),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCustom(BuildContext context) async {
    final current = controller.timeControl;
    var minutes = (current.initialMs / 60000).clamp(0.5, 180).toDouble();
    var increment = (current.incrementMs / 1000).clamp(0, 180).toDouble();
    final c = context.gc;
    final result = await showDialog<TimeControl>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Custom time control',
            style: GcType.heading(c.text, size: 18),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SliderRow(
                  label: 'Minutes per side',
                  value: minutes,
                  min: 0.5,
                  max: 180,
                  display: minutes < 1 ? '30 sec' : '${minutes.round()} min',
                  onChanged: (v) =>
                      setState(() => minutes = v < 1 ? 0.5 : v.roundToDouble()),
                ),
                const SizedBox(height: GcSpace.md),
                _SliderRow(
                  label: 'Increment per move',
                  value: increment,
                  min: 0,
                  max: 180,
                  display: '${increment.round()} sec',
                  onChanged: (v) =>
                      setState(() => increment = v.roundToDouble()),
                ),
              ],
            ),
          ),
          actions: [
            GcButton(
              label: 'Cancel',
              kind: GcButtonKind.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
            GcButton(
              label:
                  'Use ${TimeControl(initialMs: (minutes * 60000).round(), incrementMs: (increment * 1000).round()).label}',
              kind: GcButtonKind.primary,
              onPressed: () => Navigator.of(context).pop(
                TimeControl(
                  initialMs: (minutes * 60000).round(),
                  incrementMs: (increment * 1000).round(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) controller.setTimeControl(result);
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GcType.body(c.textMuted, size: 13)),
            const Spacer(),
            Text(
              display,
              style: GcType.mono(c.text, size: 14, weight: FontWeight.w600),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _JoinCard extends StatefulWidget {
  const _JoinCard({required this.controller});
  final AppController controller;

  @override
  State<_JoinCard> createState() => _JoinCardState();
}

class _JoinCardState extends State<_JoinCard> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join({required bool spectate}) async {
    final code = _code.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Codes are 6 characters, like KNGHT7.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.joinRoom(code, asSpectator: spectate);
    } on StateError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on TimeoutException {
      if (mounted) setState(() => _error = 'No answer from the server.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join with a code', style: GcType.heading(c.text, size: 17)),
          const SizedBox(height: GcSpace.xs),
          Text(
            'Ask your opponent for their six-character table code.',
            style: GcType.body(c.textMuted, size: 13),
          ),
          const SizedBox(height: GcSpace.md),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(6),
              _UpperCaseFormatter(),
            ],
            onSubmitted: (_) => _join(spectate: false),
            style: GcType.mono(
              c.text,
              size: 22,
              weight: FontWeight.w600,
            ).copyWith(letterSpacing: 6),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '······',
              hintStyle: GcType.mono(
                c.textFaint,
                size: 22,
              ).copyWith(letterSpacing: 6),
              errorText: _error,
            ),
          ),
          const SizedBox(height: GcSpace.md),
          Row(
            children: [
              Expanded(
                child: GcButton(
                  label: _busy ? 'Joining…' : 'Join as player',
                  kind: GcButtonKind.primary,
                  expand: true,
                  onPressed: _busy || !widget.controller.ready
                      ? null
                      : () => _join(spectate: false),
                ),
              ),
              const SizedBox(width: GcSpace.sm),
              Expanded(
                child: GcButton(
                  label: 'Watch',
                  icon: Icons.visibility_outlined,
                  expand: true,
                  onPressed: _busy || !widget.controller.ready
                      ? null
                      : () => _join(spectate: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _TablesCard extends StatelessWidget {
  const _TablesCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final rooms = controller.rooms;
    return GcCard(
      padding: const EdgeInsets.all(GcSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Open tables', style: GcType.heading(c.text, size: 17)),
              const Spacer(),
              Text(
                '${rooms.length}',
                style: GcType.mono(c.textFaint, size: 13),
              ),
            ],
          ),
          const SizedBox(height: GcSpace.md),
          if (!controller.ready)
            Column(
              children: [
                for (var i = 0; i < 3; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: GcSpace.sm),
                    child: GcShimmer(width: double.infinity, height: 52),
                  ),
              ],
            )
          else if (rooms.isEmpty)
            _EmptyTables()
          else
            AnimatedSize(
              duration: GcMotion.medium,
              curve: GcMotion.enter,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  for (final room in rooms.take(8))
                    _TableRow(room: room, controller: controller),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyTables extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: GcSpace.xl,
        horizontal: GcSpace.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: GcRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Icon(Icons.table_restaurant_outlined, color: c.textFaint, size: 28),
          const SizedBox(height: GcSpace.sm),
          Text(
            'No public tables right now.',
            style: GcType.body(c.textMuted, size: 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Open one and it will appear here for everyone.',
            style: GcType.body(c.textFaint, size: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.room, required this.controller});
  final RoomListing room;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final playing = room.status == RoomStatus.playing;
    final full = room.playerCount >= 2;
    return Padding(
      padding: const EdgeInsets.only(bottom: GcSpace.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GcSpace.md,
          vertical: GcSpace.sm,
        ),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: GcRadius.mdAll,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius: GcRadius.smAll,
              ),
              child: Text(
                room.code,
                style: GcType.mono(c.brass, size: 13, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: GcSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GcType.body(
                      c.text,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${room.timeControl.category} ${room.timeControl.label}'
                    '${room.hasBot ? ' · vs bot' : ''}'
                    '${room.spectatorCount > 0 ? ' · ${room.spectatorCount} watching' : ''}',
                    style: GcType.body(c.textFaint, size: 11.5),
                  ),
                ],
              ),
            ),
            if (!full && !playing)
              GcButton(
                label: 'Join',
                compact: true,
                kind: GcButtonKind.primary,
                onPressed: () => controller.joinRoom(room.code).ignore(),
              )
            else
              GcButton(
                label: 'Watch',
                compact: true,
                icon: Icons.visibility_outlined,
                onPressed: () =>
                    controller.joinRoom(room.code, asSpectator: true).ignore(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return GcCard(
      padding: const EdgeInsets.all(GcSpace.lg),
      child: Row(
        children: [
          Icon(Icons.article_outlined, color: c.textMuted),
          const SizedBox(width: GcSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review a PGN', style: GcType.heading(c.text, size: 15)),
                Text(
                  'Paste a game to step through it on the board.',
                  style: GcType.body(c.textFaint, size: 12),
                ),
              ],
            ),
          ),
          GcButton(
            label: 'Import',
            compact: true,
            onPressed: () => showPgnImportDialog(context, controller),
          ),
        ],
      ),
    );
  }
}

Future<void> showPgnImportDialog(
  BuildContext context,
  AppController controller,
) async {
  final text = TextEditingController();
  final c = context.gc;
  String? error;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Import PGN', style: GcType.heading(c.text, size: 18)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                autofocus: true,
                maxLines: 10,
                minLines: 6,
                style: GcType.mono(c.text, size: 12.5),
                decoration: InputDecoration(
                  hintText: '[Event "…"]\n1. e4 e5 2. Nf3 …',
                  errorText: error,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          GcButton(
            label: 'Paste',
            kind: GcButtonKind.ghost,
            icon: Icons.content_paste_rounded,
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) text.text = data!.text!;
            },
          ),
          GcButton(
            label: 'Cancel',
            kind: GcButtonKind.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          GcButton(
            label: 'Open review',
            kind: GcButtonKind.primary,
            onPressed: () {
              final err = controller.importPgn(text.text);
              if (err != null) {
                setState(() => error = err);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    ),
  );
}

class _QueueOverlay extends StatefulWidget {
  const _QueueOverlay({required this.controller});
  final AppController controller;

  @override
  State<_QueueOverlay> createState() => _QueueOverlayState();
}

class _QueueOverlayState extends State<_QueueOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  late final int _startedAt = DateTime.now().millisecondsSinceEpoch;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final controller = widget.controller;
    final tc = controller.queuedTimeControl ?? controller.timeControl;
    final botAfter = controller.queuedBotAfterMs;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startedAt;
    final remaining = botAfter == null
        ? null
        : ((botAfter - elapsed) / 1000).ceil().clamp(0, 999);
    return Container(
      color: c.bg.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: GcCard(
        raised: true,
        padding: const EdgeInsets.all(GcSpace.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _spin,
                child: PieceGlyph(
                  const Piece(PieceColor.white, PieceType.knight),
                  size: 56,
                ),
              ),
              const SizedBox(height: GcSpace.lg),
              Text(
                'Finding an opponent',
                style: GcType.heading(c.text, size: 20),
              ),
              const SizedBox(height: GcSpace.xs),
              Text(
                '${tc.category} · ${tc.label}',
                style: GcType.mono(c.textMuted, size: 14),
              ),
              const SizedBox(height: GcSpace.md),
              Text(
                remaining == null
                    ? 'Waiting for another player at this time control.'
                    : remaining > 0
                    ? 'A court bot will take the seat in ${remaining}s if nobody joins.'
                    : 'Seating the court bot…',
                textAlign: TextAlign.center,
                style: GcType.body(c.textMuted, size: 13, height: 1.5),
              ),
              const SizedBox(height: GcSpace.xl),
              GcButton(label: 'Cancel', onPressed: controller.cancelPair),
            ],
          ),
        ),
      ),
    );
  }
}
