import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';

import '../game/track_art.dart';
import '../state/audio.dart';
import '../state/flow.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';

/// Cup or track selection plus race options for offline modes.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key, required this.flow, required this.feedback, required this.onBack, required this.onStart});
  final GameFlow flow;
  final NtFeedback feedback;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return AnimatedBuilder(
      animation: flow,
      builder: (context, _) {
        final title = switch (flow.mode) {
          PlayMode.grandPrix => 'Choose a cup',
          PlayMode.quickRace => 'Choose a track',
          PlayMode.timeTrial => 'Time trial',
          PlayMode.battle => 'Battle arena',
          PlayMode.online => 'Choose a track',
        };
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final picker = flow.isSeries ? _CupPicker(flow: flow, onPick: (id) => _pickCup(id)) : _TrackPicker(flow: flow, onPick: (id) => _pickTrack(id));
        final options = _Options(flow: flow, feedback: feedback);
        return NtScreen(
          title: title,
          subtitle: flow.isSeries ? 'Four races. Points carry across the cup.' : trackDefById(flow.trackId).description,
          onBack: onBack,
          footer: Row(
            children: [
              Expanded(
                child: Text(_summary(), style: NtType.body(nt.inkSoft), overflow: TextOverflow.ellipsis),
              ),
              NtButton(label: 'Start', icon: Icons.play_arrow_rounded, onPressed: onStart, autofocus: true),
            ],
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: picker),
                    const SizedBox(width: NtSpace.x8),
                    SizedBox(width: 320, child: options),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    picker,
                    const SizedBox(height: NtSpace.x6),
                    options,
                  ],
                ),
        );
      },
    );
  }

  String _summary() {
    if (flow.isSeries) {
      final cup = cupById(flow.cupId);
      return '${cup.name} · ${cup.trackIds.map((t) => trackDefById(t).name).join(' → ')}';
    }
    final t = trackDefById(flow.trackId);
    return switch (flow.mode) {
      PlayMode.battle => '${t.name} · 2 minutes · ${flow.racerCount} tots',
      PlayMode.timeTrial => '${t.name} · ${flow.laps} laps · solo',
      _ => '${t.name} · ${flow.laps} laps · ${flow.racerCount} racers',
    };
  }

  void _pickCup(String id) {
    feedback.tap();
    flow.setCup(id);
  }

  void _pickTrack(String id) {
    feedback.tap();
    flow.setTrack(id);
  }
}

class _CupPicker extends StatelessWidget {
  const _CupPicker({required this.flow, required this.onPick});
  final GameFlow flow;
  final void Function(String id) onPick;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cup in cups)
          Padding(
            padding: const EdgeInsets.only(bottom: NtSpace.x4),
            child: NtCard(
              onTap: () => onPick(cup.id),
              selected: cup.id == flow.cupId,
              accent: Color(cup.color),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Color(cup.color), size: 30),
                      const SizedBox(width: NtSpace.x2),
                      Text(cup.name, style: NtType.h2(nt.ink)),
                      const Spacer(),
                      if (cup.id == flow.cupId) const NtChip('Selected', color: NtColors.lime, icon: Icons.check_rounded),
                    ],
                  ),
                  const SizedBox(height: NtSpace.x3),
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth >= 640 ? 4 : 2;
                      final w = (c.maxWidth - (cols - 1) * NtSpace.x3) / cols;
                      return Wrap(
                        spacing: NtSpace.x3,
                        runSpacing: NtSpace.x3,
                        children: [
                          for (final (i, tid) in cup.trackIds.indexed)
                            SizedBox(
                              width: w,
                              child: TrackCard(def: trackDefById(tid), index: i + 1, compact: true),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TrackPicker extends StatelessWidget {
  const _TrackPicker({required this.flow, required this.onPick});
  final GameFlow flow;
  final void Function(String id) onPick;

  @override
  Widget build(BuildContext context) {
    final defs = flow.mode == PlayMode.battle ? arenaDefs : raceTrackDefs;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 720 ? 2 : 1;
        final w = (c.maxWidth - (cols - 1) * NtSpace.x4) / cols;
        return Wrap(
          spacing: NtSpace.x4,
          runSpacing: NtSpace.x4,
          children: [
            for (final d in defs)
              SizedBox(
                width: w,
                child: TrackCard(
                  def: d,
                  selected: d.id == flow.trackId,
                  onTap: () => onPick(d.id),
                  bestTicks: flow.mode == PlayMode.timeTrial ? (flow.app.ghosts[d.id]?['ticks'] as int?) : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Track preview card with a live-rendered overhead map.
class TrackCard extends StatelessWidget {
  const TrackCard({super.key, required this.def, this.index, this.selected = false, this.onTap, this.compact = false, this.bestTicks});
  final TrackDef def;
  final int? index;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;
  final int? bestTicks;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final theme = def.theme;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${def.name}, ${def.location}',
      child: NtCard(
        onTap: onTap,
        selected: selected,
        padding: EdgeInsets.zero,
        accent: selected ? Color(theme.accent) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(NtRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: compact ? 1.5 : 1.9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(decoration: BoxDecoration(color: Color(theme.ground))),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(painter: TrackThumbPainter(trackById(def.id))),
                    ),
                    if (index != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: NtColors.inkDark),
                          child: Text('$index', style: NtType.caption(Colors.white)),
                        ),
                      ),
                    if (bestTicks != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: NtChip(_fmt(bestTicks!), icon: Icons.timer_rounded, color: NtColors.sunny, textColor: NtColors.inkDark),
                      ),
                    if (selected)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: NtColors.lime,
                          size: 26,
                          shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? NtSpace.x2 : NtSpace.x3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.name, style: compact ? NtType.label(nt.ink) : NtType.h3(nt.ink), overflow: TextOverflow.ellipsis),
                    Text(def.location, style: compact ? NtType.caption(nt.inkSoft) : NtType.small(nt.inkSoft), overflow: TextOverflow.ellipsis),
                    if (!compact) ...[
                      const SizedBox(height: NtSpace.x2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (def.shortcuts.isNotEmpty)
                            NtChip(
                              '${def.shortcuts.length} shortcut${def.shortcuts.length > 1 ? 's' : ''}',
                              color: Color(theme.shortcut),
                              textColor: NtColors.inkDark,
                            ),
                          if (def.jumps.isNotEmpty) NtChip('${def.jumps.length} jumps', color: NtColors.sky),
                          if (def.boostPads.isNotEmpty) NtChip('${def.boostPads.length} pads', color: NtColors.nitro),
                          if (def.hazards.isNotEmpty) NtChip('${def.hazards.length} hazards', color: NtColors.grape),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int ticks) {
    final ms = ticks * 1000 ~/ ticksPerSecond;
    final m = ms ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    final h = (ms % 1000) ~/ 10;
    return '$m:${s.toString().padLeft(2, '0')}.${h.toString().padLeft(2, '0')}';
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.flow, required this.feedback});
  final GameFlow flow;
  final NtFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final battle = flow.mode == PlayMode.battle;
    final tt = flow.mode == PlayMode.timeTrial;
    return NtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Race options'),
          const SizedBox(height: NtSpace.x3),
          if (!battle) ...[
            _Stepper(
              label: 'Laps',
              value: flow.laps,
              min: 1,
              max: 5,
              onChanged: (v) => _set(laps: v),
            ),
            const SizedBox(height: NtSpace.x3),
          ],
          if (!tt) ...[
            _Stepper(
              label: battle ? 'Tots' : 'Racers',
              value: flow.racerCount,
              min: 2,
              max: 8,
              onChanged: (v) => _set(racers: v),
            ),
            const SizedBox(height: NtSpace.x3),
            Text('Bot difficulty', style: NtType.label(nt.inkSoft)),
            const SizedBox(height: NtSpace.x1),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0.45, label: Text('Easy')),
                ButtonSegment(value: 0.7, label: Text('Normal')),
                ButtonSegment(value: 0.95, label: Text('Fierce')),
              ],
              selected: {flow.botSkill},
              onSelectionChanged: (s) => _set(skill: s.first),
              showSelectedIcon: false,
            ),
          ],
          if (tt) Text('Race alone against your best ghost on this track. Beat it to save a new ghost.', style: NtType.body(nt.inkSoft)),
        ],
      ),
    );
  }

  void _set({int? laps, int? racers, double? skill}) {
    feedback.tap();
    flow.setOptions(laps: laps, racers: racers, skill: skill);
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return Row(
      children: [
        Expanded(child: Text(label, style: NtType.label(nt.inkSoft))),
        NtIconButton(icon: Icons.remove_rounded, tooltip: 'Fewer $label', onPressed: value > min ? () => onChanged(value - 1) : () {}, size: 36),
        SizedBox(
          width: 44,
          child: Text('$value', style: NtType.h3(nt.ink), textAlign: TextAlign.center),
        ),
        NtIconButton(icon: Icons.add_rounded, tooltip: 'More $label', onPressed: value < max ? () => onChanged(value + 1) : () {}, size: 36),
      ],
    );
  }
}
