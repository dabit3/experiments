import 'package:flutter/material.dart';

import '../config.dart';
import '../theme/tokens.dart';
import '../widgets/ui.dart';

Future<void> showHowToPlay(BuildContext context) {
  final s = PPScheme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: s.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: PPRadius.lg)),
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => const _HowToPlaySheet(),
  );
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    final s = PPScheme.of(context);
    final touch = AppConfig.isTouch;
    final steps = [
      (
        Icons.inventory_2_rounded,
        PPColor.wood,
        'Grab ingredients',
        'Face a crate and press Grab to take a raw ingredient.',
      ),
      (
        Icons.content_cut_rounded,
        PPColor.basil,
        'Chop',
        'Drop it on a cutting board, then hold Action until the bar fills.',
      ),
      (
        Icons.soup_kitchen_rounded,
        PPColor.paprika,
        'Cook',
        'Put three chopped ingredients into a pot on a stove. Watch the bar — cooked soup burns if you leave it!',
      ),
      (
        Icons.dinner_dining_rounded,
        PPColor.blueberry,
        'Plate & serve',
        'Grab a plate from the rack, pour the pot into it, and drop it at the blue pass.',
      ),
      (
        Icons.water_drop_rounded,
        PPColor.water,
        'Wash up',
        'Served plates come back dirty. Take them to the sink and hold Action.',
      ),
      (
        Icons.local_fire_department_rounded,
        PPColor.paprikaDark,
        'Fires',
        'Burnt pots catch fire and it spreads. Grab the extinguisher and hold Action while facing the flames.',
      ),
      (
        Icons.timer_rounded,
        PPColor.butter,
        'Tips',
        'Serve quickly for tips; serve tickets in order to build a combo. Expired tickets cost points.',
      ),
    ];
    final controls = touch
        ? [
            ('Move', 'Left joystick'),
            ('Grab / drop', 'Grab button'),
            ('Chop / wash / spray', 'Action button'),
            ('Dash', 'Dash button'),
            ('Emote', 'Smile button'),
          ]
        : [
            ('Move', 'WASD or arrow keys'),
            ('Grab / drop', 'Space or J'),
            ('Chop / wash / spray', 'E, K or Shift'),
            ('Dash', 'F or L'),
            ('Emote', '1 – 6'),
          ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(PPSpace.x6, PPSpace.x4, PPSpace.x6, PPSpace.x10),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: s.outline, borderRadius: PPRadius.chip),
            ),
          ),
          const SizedBox(height: PPSpace.x5),
          Text('How to play', style: PPType.h1(s.text)),
          const SizedBox(height: PPSpace.x2),
          Text(
            'Work together to serve every ticket before it expires. Score more to earn stars.',
            style: PPType.body(s.text2),
          ),
          const SizedBox(height: PPSpace.x6),
          for (final (i, step) in steps.indexed)
            Enter(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: PPSpace.x4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: step.$2.withValues(alpha: 0.15), borderRadius: PPRadius.button),
                      child: Icon(step.$1, color: step.$2),
                    ),
                    const SizedBox(width: PPSpace.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.$3, style: PPType.h3(s.text)),
                          const SizedBox(height: 2),
                          Text(step.$4, style: PPType.body(s.text2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: PPSpace.x4),
          SectionLabel('Controls · ${AppConfig.platformLabel}'),
          PPCard(
            elevated: false,
            padding: const EdgeInsets.symmetric(horizontal: PPSpace.x4, vertical: PPSpace.x2),
            child: Column(
              children: [
                for (final (k, v) in controls)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: PPSpace.x2),
                    child: Row(
                      children: [
                        Expanded(child: Text(k, style: PPType.body(s.text))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: PPSpace.x2, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.surface2,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: s.outline),
                          ),
                          child: Text(v, style: PPType.mono(s.text2).copyWith(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: PPSpace.x6),
          PPButton(label: 'Got it', expand: true, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
