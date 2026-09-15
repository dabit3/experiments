/// Playable characters ("Tots") and karts. All names and looks are original
/// to Nitro Tots.
enum WeightClass { light, medium, heavy }

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.tagline,
    required this.weight,
    required this.primaryColor,
    required this.accentColor,
    required this.skinTone,
  });

  final String id;
  final String name;
  final String tagline;
  final WeightClass weight;

  /// ARGB colors as ints so the core stays free of Flutter imports.
  final int primaryColor;
  final int accentColor;
  final int skinTone;

  /// Stat deltas applied on top of the kart stats (each -1..1).
  double get speedBonus => switch (weight) {
    WeightClass.light => -0.4,
    WeightClass.medium => 0,
    WeightClass.heavy => 0.5,
  };
  double get accelBonus => switch (weight) {
    WeightClass.light => 0.6,
    WeightClass.medium => 0.1,
    WeightClass.heavy => -0.5,
  };
  double get handlingBonus => switch (weight) {
    WeightClass.light => 0.5,
    WeightClass.medium => 0.1,
    WeightClass.heavy => -0.4,
  };
  double get massBonus => switch (weight) {
    WeightClass.light => -0.5,
    WeightClass.medium => 0,
    WeightClass.heavy => 0.7,
  };
}

class Kart {
  const Kart({
    required this.id,
    required this.name,
    required this.speed,
    required this.accel,
    required this.handling,
    required this.weight,
    required this.bodyColor,
  });

  final String id;
  final String name;

  /// Stats on a 1..5 scale.
  final double speed;
  final double accel;
  final double handling;
  final double weight;
  final int bodyColor;
}

const characters = <Character>[
  Character(
    id: 'pip',
    name: 'Pip',
    tagline: 'Tiny. Turbo. Trouble.',
    weight: WeightClass.light,
    primaryColor: 0xFFFF7A1A,
    accentColor: 0xFFFFD166,
    skinTone: 0xFFF3C6A5,
  ),
  Character(
    id: 'bea',
    name: 'Bea',
    tagline: 'Buzzes past the pack.',
    weight: WeightClass.light,
    primaryColor: 0xFFFFC300,
    accentColor: 0xFF2B2D42,
    skinTone: 0xFF8D5524,
  ),
  Character(
    id: 'juno',
    name: 'Juno',
    tagline: 'Cool head, hot laps.',
    weight: WeightClass.medium,
    primaryColor: 0xFF3A86FF,
    accentColor: 0xFFB8F2FF,
    skinTone: 0xFFC68642,
  ),
  Character(
    id: 'ozzie',
    name: 'Ozzie',
    tagline: 'Drifts for dessert.',
    weight: WeightClass.medium,
    primaryColor: 0xFF06D6A0,
    accentColor: 0xFF073B4C,
    skinTone: 0xFFE0AC69,
  ),
  Character(
    id: 'mabel',
    name: 'Mabel',
    tagline: 'Sweet on the outside.',
    weight: WeightClass.medium,
    primaryColor: 0xFFEF476F,
    accentColor: 0xFFFFE5EC,
    skinTone: 0xFFF1C27D,
  ),
  Character(
    id: 'kiki',
    name: 'Kiki',
    tagline: 'Never seen the brake.',
    weight: WeightClass.light,
    primaryColor: 0xFFB56BFF,
    accentColor: 0xFF2A0944,
    skinTone: 0xFFFFDBAC,
  ),
  Character(
    id: 'rocco',
    name: 'Rocco',
    tagline: 'Big kart energy.',
    weight: WeightClass.heavy,
    primaryColor: 0xFF8338EC,
    accentColor: 0xFFFFBE0B,
    skinTone: 0xFF6B3E26,
  ),
  Character(
    id: 'tank',
    name: 'Tank',
    tagline: 'Moves mountains. Slowly.',
    weight: WeightClass.heavy,
    primaryColor: 0xFF2EC4B6,
    accentColor: 0xFFCBF3F0,
    skinTone: 0xFFA1665E,
  ),
];

const karts = <Kart>[
  Kart(id: 'jellybean', name: 'Jellybean', speed: 3, accel: 4, handling: 4, weight: 2, bodyColor: 0xFFFF5D8F),
  Kart(id: 'tincan', name: 'Tin Can', speed: 2.5, accel: 5, handling: 4.5, weight: 1.5, bodyColor: 0xFFB0BEC5),
  Kart(id: 'bubble', name: 'Bubble Buggy', speed: 3.5, accel: 3.5, handling: 3.5, weight: 3, bodyColor: 0xFF4CC9F0),
  Kart(id: 'pinewood', name: 'Pinewood Racer', speed: 4, accel: 3, handling: 3, weight: 3.5, bodyColor: 0xFFC97B4B),
  Kart(id: 'rocketscoot', name: 'Rocket Scoot', speed: 4.5, accel: 2.5, handling: 2.5, weight: 4, bodyColor: 0xFFF72585),
  Kart(id: 'bigwheel', name: 'Big Wheel', speed: 5, accel: 2, handling: 2, weight: 5, bodyColor: 0xFF3D405B),
];

Character characterById(String id) => characters.firstWhere((c) => c.id == id, orElse: () => characters.first);

Kart kartById(String id) => karts.firstWhere((k) => k.id == id, orElse: () => karts.first);

/// Combined stats normalised for the physics step.
class RacerStats {
  RacerStats(Character c, Kart k)
    : speed = ((k.speed + c.speedBonus).clamp(1, 5.5)) / 5,
      accel = ((k.accel + c.accelBonus).clamp(1, 5.5)) / 5,
      handling = ((k.handling + c.handlingBonus).clamp(1, 5.5)) / 5,
      mass = ((k.weight + c.massBonus).clamp(1, 5.5)) / 5;

  final double speed;
  final double accel;
  final double handling;
  final double mass;
}
