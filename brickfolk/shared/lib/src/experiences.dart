/// The built-in experiences ("places") of Brickfolk.
enum ExperienceKind {
  obby('obby'),
  tycoon('tycoon'),
  tag('tag');

  const ExperienceKind(this.id);

  final String id;

  static ExperienceKind? fromId(String? id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }
}

class PlaceInfo {
  const PlaceInfo({
    required this.kind,
    required this.name,
    required this.tagline,
    required this.description,
    required this.accent,
    required this.matchSeconds,
    required this.minPlayers,
  });

  final ExperienceKind kind;
  final String name;
  final String tagline;
  final String description;
  final int accent;

  /// Duration of one match in seconds.
  final int matchSeconds;

  /// Minimum players before the lobby countdown starts (bots fill the rest).
  final int minPlayers;

  Map<String, Object?> toJson() => {
    'kind': kind.id,
    'name': name,
    'tagline': tagline,
    'description': description,
    'accent': accent,
    'matchSeconds': matchSeconds,
    'minPlayers': minPlayers,
  };
}

const List<PlaceInfo> places = [
  PlaceInfo(
    kind: ExperienceKind.obby,
    name: 'Skyline Obby',
    tagline: 'Leap across the rooftops.',
    description:
        'A twelve-stage obstacle course in the clouds. Reach every checkpoint, '
        'dodge the kiln bricks and hit the summit pad first. Falling sends you '
        'back to your last checkpoint.',
    accent: 0xFF3E7BFA,
    matchSeconds: 120,
    minPlayers: 2,
  ),
  PlaceInfo(
    kind: ExperienceKind.tycoon,
    name: 'Brick Tycoon',
    tagline: 'Build a plot that pays.',
    description:
        'Place droppers, conveyors and vaults on your 6x6 plot. Every brick '
        'earns pips each second; upgrades multiply the whole plot. The richest '
        'builder when the timer ends wins.',
    accent: 0xFFFF8A4C,
    matchSeconds: 90,
    minPlayers: 1,
  ),
  PlaceInfo(
    kind: ExperienceKind.tag,
    name: 'Freeze Tag Arena',
    tagline: 'Run, freeze, rescue.',
    description:
        'One tagger, seven runners, sixty seconds. Frozen runners can be '
        'thawed by a teammate. Survive to score; freeze everyone to win the '
        'round.',
    accent: 0xFF35B8D6,
    matchSeconds: 60,
    minPlayers: 2,
  ),
];

PlaceInfo placeFor(ExperienceKind kind) =>
    places.firstWhere((p) => p.kind == kind);
