import 'package:flutter/material.dart';
import 'package:nitro_core/nitro_core.dart';

import '../state/app_state.dart';
import '../state/audio.dart';
import '../theme/tokens.dart';
import '../widgets/nt_widgets.dart';

/// Character + kart selection with a live preview and stat comparison.
class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key, required this.app, required this.feedback, required this.onBack, required this.onDone, this.doneLabel = 'Done'});
  final AppState app;
  final NtFeedback feedback;
  final VoidCallback onBack;
  final VoidCallback onDone;
  final String doneLabel;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.app.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final nt = context.nt;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final preview = _Preview(app: app, nameController: _name);
        final pickers = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Pick a tot'),
            const SizedBox(height: NtSpace.x3),
            _CharacterGrid(
              app: app,
              onPick: (id) {
                widget.feedback.tap();
                widget.feedback.haptic(HapticsKind.select);
                app.update((s) => s.characterId = id);
              },
            ),
            const SizedBox(height: NtSpace.x6),
            const SectionTitle('Pick a kart'),
            const SizedBox(height: NtSpace.x3),
            _KartList(
              app: app,
              onPick: (id) {
                widget.feedback.tap();
                widget.feedback.haptic(HapticsKind.select);
                app.update((s) => s.kartId = id);
              },
            ),
          ],
        );

        return NtScreen(
          title: 'Garage',
          subtitle: 'Every tot and kart is available from the start.',
          onBack: widget.onBack,
          footer: Row(
            children: [
              Expanded(
                child: Text('${app.character.name} in the ${app.kart.name}', style: NtType.body(nt.inkSoft), overflow: TextOverflow.ellipsis),
              ),
              NtButton(
                label: widget.doneLabel,
                icon: Icons.check_rounded,
                onPressed: () {
                  app.update((s) => s.name = _name.text.trim().isEmpty ? 'Racer' : _name.text.trim());
                  widget.onDone();
                },
              ),
            ],
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: preview),
                    const SizedBox(width: NtSpace.x6),
                    Expanded(child: pickers),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    preview,
                    const SizedBox(height: NtSpace.x6),
                    pickers,
                  ],
                ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.app, required this.nameController});
  final AppState app;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    final c = app.character;
    final k = app.kart;
    final color = NtColors.forCharacter(c.id);
    return NtCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            maxLength: 14,
            textCapitalization: TextCapitalization.words,
            style: NtType.h3(nt.ink),
            decoration: const InputDecoration(labelText: 'Racer name', counterText: '', prefixIcon: Icon(Icons.badge_rounded)),
            onChanged: (v) => app.update((s) => s.name = v.trim().isEmpty ? 'Racer' : v.trim()),
          ),
          const SizedBox(height: NtSpace.x4),
          Center(
            child: AnimatedSwitcher(
              duration: NtMotion.normal,
              switchInCurve: NtMotion.emphasized,
              transitionBuilder: (child, a) => ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Container(
                key: ValueKey('${c.id}-${k.id}'),
                width: 220,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)]),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    KartPreview(kart: k, characterId: c.id, size: 190),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: Avatar(characterId: c.id, size: 64, ring: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: NtSpace.x3),
          Text(c.name, style: NtType.h2(nt.ink), textAlign: TextAlign.center),
          Text(c.tagline, style: NtType.body(nt.inkSoft), textAlign: TextAlign.center),
          const SizedBox(height: NtSpace.x4),
          _CombinedStats(character: c, kart: k),
        ],
      ),
    );
  }
}

class _CombinedStats extends StatelessWidget {
  const _CombinedStats({required this.character, required this.kart});
  final Character character;
  final Kart kart;

  @override
  Widget build(BuildContext context) {
    final stats = RacerStats(character, kart);
    return Column(
      children: [
        StatBar(label: 'Speed', value: stats.speed * 5, color: NtColors.nitro),
        StatBar(label: 'Accel', value: stats.accel * 5, color: NtColors.lime),
        StatBar(label: 'Handling', value: stats.handling * 5, color: NtColors.sky),
        StatBar(label: 'Weight', value: stats.mass * 5, color: NtColors.grape),
      ],
    );
  }
}

class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({required this.app, required this.onPick});
  final AppState app;
  final void Function(String id) onPick;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return LayoutBuilder(
      builder: (context, c) {
        final fit = (c.maxWidth / 104).floor();
        final cols = fit >= characters.length ? characters.length : (fit >= 4 ? 4 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: NtSpace.x3,
            crossAxisSpacing: NtSpace.x3,
            childAspectRatio: 0.9,
          ),
          itemCount: characters.length,
          itemBuilder: (_, i) {
            final ch = characters[i];
            final selected = ch.id == app.characterId;
            final color = NtColors.forCharacter(ch.id);
            return Semantics(
              selected: selected,
              button: true,
              label: '${ch.name}, ${_weightLabel(ch.weight)}',
              child: NtCard(
                onTap: () => onPick(ch.id),
                selected: selected,
                accent: selected ? color : null,
                padding: const EdgeInsets.all(NtSpace.x2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Avatar(characterId: ch.id, size: 48, ring: selected ? color : nt.outline),
                    const SizedBox(height: NtSpace.x2),
                    Text(ch.name, style: NtType.label(nt.ink)),
                    Text(_weightLabel(ch.weight), style: NtType.caption(nt.inkSoft)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _weightLabel(WeightClass w) => switch (w) {
    WeightClass.light => 'Light',
    WeightClass.medium => 'Medium',
    WeightClass.heavy => 'Heavy',
  };
}

class _KartList extends StatelessWidget {
  const _KartList({required this.app, required this.onPick});
  final AppState app;
  final void Function(String id) onPick;

  @override
  Widget build(BuildContext context) {
    final nt = context.nt;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / 250).floor().clamp(1, 3);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: NtSpace.x3,
            crossAxisSpacing: NtSpace.x3,
            mainAxisExtent: 84,
          ),
          itemCount: karts.length,
          itemBuilder: (_, i) {
            final k = karts[i];
            final selected = k.id == app.kartId;
            return Semantics(
              selected: selected,
              button: true,
              label: k.name,
              child: NtCard(
                onTap: () => onPick(k.id),
                selected: selected,
                accent: selected ? Color(k.bodyColor) : null,
                padding: const EdgeInsets.symmetric(horizontal: NtSpace.x3, vertical: NtSpace.x2),
                child: Row(
                  children: [
                    KartPreview(kart: k, characterId: app.characterId, size: 56),
                    const SizedBox(width: NtSpace.x2),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.name, style: NtType.label(nt.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(_kartHint(k), style: NtType.caption(nt.inkSoft), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle_rounded, color: NtColors.lime),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _kartHint(Kart k) {
    if (k.speed >= 4.5) return 'Top speed';
    if (k.accel >= 4.5) return 'Quick off the line';
    if (k.handling >= 4.5) return 'Tight turns';
    if (k.weight >= 4.5) return 'Heavy bumper';
    return 'All-rounder';
  }
}
