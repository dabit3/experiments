/// Badge definitions. Badges are awarded by the server and persisted.
class BadgeDef {
  const BadgeDef(this.id, this.name, this.description, this.color);

  final String id;
  final String name;
  final String description;
  final int color;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'color': color,
  };
}

const List<BadgeDef> badges = [
  BadgeDef(
    'welcome',
    'Welcome to Brickfolk',
    'Joined Brickfolk for the first time.',
    0xFF3E7BFA,
  ),
  BadgeDef(
    'first_steps',
    'First Steps',
    'Reached a checkpoint in Skyline Obby.',
    0xFF2F9E5B,
  ),
  BadgeDef('summit', 'Summit', 'Finished Skyline Obby.', 0xFFF5C04A),
  BadgeDef(
    'speedrunner',
    'Speedrunner',
    'Finished Skyline Obby in under 75 seconds.',
    0xFFE5484D,
  ),
  BadgeDef(
    'founder',
    'Founder',
    'Placed your first brick in Brick Tycoon.',
    0xFF8E5CF7,
  ),
  BadgeDef(
    'magnate',
    'Magnate',
    'Earned 500 pips in one Brick Tycoon session.',
    0xFFFF8A4C,
  ),
  BadgeDef(
    'untouchable',
    'Untouchable',
    'Survived a whole Freeze Tag round.',
    0xFF35B8D6,
  ),
  BadgeDef(
    'it_factor',
    'It Factor',
    'Froze three players in one Freeze Tag match.',
    0xFFF06BB7,
  ),
  BadgeDef('social', 'Social Brick', 'Made a friend.', 0xFFB7D24B),
  BadgeDef(
    'streak_3',
    'Three-Day Streak',
    'Claimed the daily reward three days in a row.',
    0xFF8C5A3C,
  ),
];

final Map<String, BadgeDef> badgeById = {for (final b in badges) b.id: b};
