import 'package:brickfolk_shared/brickfolk_shared.dart';

const List<String> botNames = [
  'Pipsqueak',
  'Mortar',
  'Gable',
  'Trowel',
  'Kiln',
  'Rafter',
  'Grout',
  'Plumb',
];

/// Deterministic cosmetic loadout for bot [index].
Avatar botAvatar(int index) {
  const hats = ['hat_cap', 'hat_helmet', 'hat_beanie', 'hat_none'];
  const faces = ['face_smile', 'face_grin', 'face_wink', 'face_sleepy'];
  return Avatar(
    headColor: bodyColors[(index * 3 + 1) % bodyColors.length],
    torsoColor: bodyColors[(index * 5 + 2) % bodyColors.length],
    armColor: bodyColors[(index * 3 + 1) % bodyColors.length],
    legColor: bodyColors[(index * 7 + 4) % bodyColors.length],
    hat: hats[index % hats.length],
    face: faces[index % faces.length],
  );
}

PlayerSummary botSummary(int index) => PlayerSummary(
  id: 'bot$index',
  name: botNames[index % botNames.length],
  avatar: botAvatar(index),
  platform: 'server',
  isBot: true,
);
