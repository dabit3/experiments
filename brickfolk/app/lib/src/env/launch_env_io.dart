import 'dart:io';

const _prefix = 'BRICKFOLK_';

Map<String, String> launchOverrides() => {
  for (final e in Platform.environment.entries)
    if (e.key.startsWith(_prefix))
      e.key.substring(_prefix.length).toLowerCase(): e.value,
};
