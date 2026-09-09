import 'math.dart';
import 'track.dart';

/// Hand-designed Nitro Tots circuits. Coordinates are world units; a kart is
/// roughly 7 units long. Feature `t` values are in control-point space.
const sprinkleSpeedway = TrackDef(
  id: 'sprinkle',
  name: 'Sprinkle Speedway',
  location: 'Candy Coast',
  description: 'A friendly opener: wide sweepers, one tight chicane and a frosting shortcut.',
  controlPoints: [
    V2(220, 220),
    V2(900, 150),
    V2(1420, 230),
    V2(1640, 520),
    V2(1460, 820),
    V2(1020, 760),
    V2(720, 920),
    V2(300, 840),
    V2(140, 520),
  ],
  widths: [50, 50, 48, 46, 46, 42, 46, 50, 50],
  theme: TrackTheme(
    ground: 0xFFF6D6E4,
    groundAlt: 0xFFF2C9DB,
    road: 0xFF5B5470,
    roadEdge: 0xFF463F5A,
    curbA: 0xFFFF6B9D,
    curbB: 0xFFFFFFFF,
    shortcut: 0xFFFFE08A,
    accent: 0xFFFF6B9D,
    sky: 0xFFFFF1F6,
  ),
  itemBoxes: [
    ItemBoxDef(1.4, [-14, 0, 14]),
    ItemBoxDef(4.5, [-12, 12]),
    ItemBoxDef(7.3, [-14, 0, 14]),
  ],
  boostPads: [
    BoostPadDef(2.6, -10),
    BoostPadDef(2.6, 10),
    BoostPadDef(6.5, 0),
  ],
  hazards: [
    HazardDef(HazardKind.oilSlick, 3.5, 8),
    HazardDef(HazardKind.oilSlick, 5.6, -10),
    HazardDef(HazardKind.pillar, 8.5, 0),
  ],
  jumps: [JumpDef(0.5, length: 22)],
  shortcuts: [
    ShortcutDef(
      'Frosting cut',
      [V2(1440, 240), V2(1520, 300), V2(1560, 620), V2(1470, 760), V2(1400, 720), V2(1480, 560), V2(1430, 330)],
      entryT: 2.1,
      exitT: 3.9,
    ),
  ],
);

const mossyHollow = TrackDef(
  id: 'mossy',
  name: 'Mossy Hollow',
  location: 'Whisperwood',
  description: 'Twisting forest lanes, slippery roots and a hidden creek-bed shortcut.',
  controlPoints: [
    V2(300, 300),
    V2(700, 180),
    V2(1100, 320),
    V2(1500, 200),
    V2(1800, 450),
    V2(1650, 750),
    V2(1300, 650),
    V2(1000, 850),
    V2(1300, 1100),
    V2(900, 1300),
    V2(500, 1150),
    V2(250, 850),
    V2(450, 600),
  ],
  widths: [42, 42, 40, 40, 42, 38, 36, 36, 38, 42, 42, 40, 40],
  theme: TrackTheme(
    ground: 0xFF3E7D4A,
    groundAlt: 0xFF376F42,
    road: 0xFF6B5B4A,
    roadEdge: 0xFF4E4236,
    curbA: 0xFFD9B36B,
    curbB: 0xFF7A5C3C,
    shortcut: 0xFF8FB9A8,
    accent: 0xFF9BE15D,
    sky: 0xFFDDEFD3,
  ),
  itemBoxes: [
    ItemBoxDef(1.5, [-12, 0, 12]),
    ItemBoxDef(5.3, [-10, 10]),
    ItemBoxDef(9.4, [-12, 0, 12]),
    ItemBoxDef(11.6, [-10, 10]),
  ],
  boostPads: [
    BoostPadDef(3.4, 0),
    BoostPadDef(8.5, -8),
    BoostPadDef(8.5, 8),
  ],
  hazards: [
    HazardDef(HazardKind.oilSlick, 2.5, -8),
    HazardDef(HazardKind.oilSlick, 4.4, 6),
    HazardDef(HazardKind.pillar, 7.0, -6),
    HazardDef(HazardKind.oilSlick, 10.5, 0),
  ],
  jumps: [JumpDef(4.7, length: 22)],
  shortcuts: [
    ShortcutDef(
      'Creek bed',
      [V2(1268, 690), V2(1340, 690), V2(1350, 1060), V2(1262, 1060)],
      entryT: 6.1,
      exitT: 7.9,
    ),
  ],
);

const tinCityLoop = TrackDef(
  id: 'tincity',
  name: 'Tin City Loop',
  location: 'Downtown Neon',
  description: 'Right-angle streets, street-sweeper rollers and a rooftop jump.',
  controlPoints: [
    V2(200, 200),
    V2(800, 200),
    V2(1400, 200),
    V2(1700, 400),
    V2(1700, 800),
    V2(1400, 1000),
    V2(1000, 1000),
    V2(1000, 700),
    V2(600, 700),
    V2(600, 1000),
    V2(200, 1000),
    V2(200, 600),
  ],
  widths: [46, 46, 46, 44, 44, 44, 40, 38, 38, 40, 44, 46],
  theme: TrackTheme(
    ground: 0xFF1E1B2E,
    groundAlt: 0xFF23203A,
    road: 0xFF3B3A52,
    roadEdge: 0xFF2A2940,
    curbA: 0xFFFFD60A,
    curbB: 0xFF16141F,
    shortcut: 0xFF5F5A85,
    accent: 0xFF00E5FF,
    sky: 0xFF120F22,
  ),
  itemBoxes: [
    ItemBoxDef(0.7, [-14, 0, 14]),
    ItemBoxDef(4.3, [-12, 12]),
    ItemBoxDef(8.5, [-10, 10]),
    ItemBoxDef(10.6, [-14, 0, 14]),
  ],
  boostPads: [
    BoostPadDef(2.4, 0, length: 30),
    BoostPadDef(6.6, -8),
    BoostPadDef(6.6, 8),
  ],
  hazards: [
    HazardDef(HazardKind.roller, 1.4, 0, range: 16),
    HazardDef(HazardKind.roller, 1.7, 0, range: 16),
    HazardDef(HazardKind.oilSlick, 5.5, -10),
    HazardDef(HazardKind.pillar, 9.5, 0),
  ],
  jumps: [JumpDef(3.5, length: 26)],
  shortcuts: [
    ShortcutDef(
      'Alley',
      [V2(560, 740), V2(640, 740), V2(640, 970), V2(560, 970)],
      entryT: 8.0,
      exitT: 9.0,
    ),
  ],
);

const frostbitePass = TrackDef(
  id: 'frostbite',
  name: 'Frostbite Pass',
  location: 'Glacier Ridge',
  description: 'Long icy sweepers, a narrow ice bridge and a cliff-side jump.',
  controlPoints: [
    V2(300, 500),
    V2(600, 250),
    V2(1100, 150),
    V2(1600, 250),
    V2(1900, 550),
    V2(1750, 900),
    V2(1400, 1100),
    V2(1000, 1000),
    V2(700, 1150),
    V2(350, 950),
    V2(200, 700),
  ],
  widths: [44, 44, 46, 46, 42, 40, 38, 28, 38, 42, 44],
  theme: TrackTheme(
    ground: 0xFFDCEFFB,
    groundAlt: 0xFFCFE6F6,
    road: 0xFF7FA7C9,
    roadEdge: 0xFF5C86AA,
    curbA: 0xFF2B6CB0,
    curbB: 0xFFFFFFFF,
    shortcut: 0xFFB9E3F7,
    accent: 0xFF2B6CB0,
    sky: 0xFFEAF6FF,
  ),
  itemBoxes: [
    ItemBoxDef(1.5, [-14, 0, 14]),
    ItemBoxDef(4.4, [-12, 12]),
    ItemBoxDef(6.4, [-10, 10]),
    ItemBoxDef(9.5, [-14, 0, 14]),
  ],
  boostPads: [
    BoostPadDef(2.5, 0, length: 30),
    BoostPadDef(5.4, -8),
    BoostPadDef(5.4, 8),
    BoostPadDef(8.6, 0),
  ],
  hazards: [
    HazardDef(HazardKind.oilSlick, 3.3, 6),
    HazardDef(HazardKind.oilSlick, 3.6, -8),
    HazardDef(HazardKind.pillar, 8.3, 0),
    HazardDef(HazardKind.roller, 10.5, 0, range: 14),
  ],
  jumps: [JumpDef(4.6, length: 26)],
  shortcuts: [
    ShortcutDef(
      'Ice slide',
      [V2(1680, 260), V2(1760, 300), V2(1800, 560), V2(1720, 640), V2(1640, 600), V2(1690, 420)],
      entryT: 3.1,
      exitT: 4.9,
    ),
  ],
);

const bumperBowl = TrackDef(
  id: 'bowl',
  name: 'Bumper Bowl',
  location: 'Battle Arena',
  description: 'A round arena with a fountain in the middle. Pop balloons, score points.',
  isArena: true,
  controlPoints: [
    V2(1060, 600),
    V2(984, 784),
    V2(800, 860),
    V2(616, 784),
    V2(540, 600),
    V2(616, 416),
    V2(800, 340),
    V2(984, 416),
  ],
  widths: [400],
  grassMargin: 0,
  theme: TrackTheme(
    ground: 0xFF2D3142,
    groundAlt: 0xFF353A4F,
    road: 0xFF4F5D75,
    roadEdge: 0xFF3B465C,
    curbA: 0xFFEF8354,
    curbB: 0xFFFFFFFF,
    shortcut: 0xFF4F5D75,
    accent: 0xFFEF8354,
    sky: 0xFF22263A,
  ),
  itemBoxes: [
    ItemBoxDef(0.0, [-120, 120]),
    ItemBoxDef(2.0, [-120, 120]),
    ItemBoxDef(4.0, [-120, 120]),
    ItemBoxDef(6.0, [-120, 120]),
    ItemBoxDef(1.0, [0]),
    ItemBoxDef(3.0, [0]),
    ItemBoxDef(5.0, [0]),
    ItemBoxDef(7.0, [0]),
  ],
  boostPads: [
    BoostPadDef(0.5, -140),
    BoostPadDef(2.5, 140),
    BoostPadDef(4.5, -140),
    BoostPadDef(6.5, 140),
  ],
  hazards: [
    HazardDef(HazardKind.pillar, 1.5, 60),
    HazardDef(HazardKind.pillar, 3.5, 60),
    HazardDef(HazardKind.pillar, 5.5, 60),
    HazardDef(HazardKind.pillar, 7.5, 60),
  ],
);

const raceTrackDefs = <TrackDef>[sprinkleSpeedway, mossyHollow, tinCityLoop, frostbitePass];
const arenaDefs = <TrackDef>[bumperBowl];
const allTrackDefs = <TrackDef>[...raceTrackDefs, ...arenaDefs];

TrackDef trackDefById(String id) =>
    allTrackDefs.firstWhere((t) => t.id == id, orElse: () => sprinkleSpeedway);

final Map<String, Track> _trackCache = {};

/// Builds (and caches) the sampled geometry for a track id.
Track trackById(String id) => _trackCache.putIfAbsent(id, () => Track(trackDefById(id)));

/// Grand Prix cups.
class Cup {
  const Cup({required this.id, required this.name, required this.trackIds, required this.color});
  final String id;
  final String name;
  final List<String> trackIds;
  final int color;
}

const cups = <Cup>[
  Cup(
    id: 'sugar',
    name: 'Sugar Cup',
    trackIds: ['sprinkle', 'mossy', 'tincity', 'frostbite'],
    color: 0xFFFF6B9D,
  ),
  Cup(
    id: 'nitro',
    name: 'Nitro Cup',
    trackIds: ['frostbite', 'tincity', 'mossy', 'sprinkle'],
    color: 0xFF00E5FF,
  ),
];

Cup cupById(String id) => cups.firstWhere((c) => c.id == id, orElse: () => cups.first);
