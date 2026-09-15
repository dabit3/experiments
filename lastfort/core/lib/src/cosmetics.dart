import 'items.dart';

enum CosmeticSlot { outfit, pickaxe, glider, banner }

/// An original Lastfort cosmetic. Outfits are rendered procedurally from
/// their palette, so every asset is generated art rather than a copied file.
class Cosmetic {
  const Cosmetic({
    required this.id,
    required this.slot,
    required this.name,
    required this.rarity,
    required this.primary,
    required this.secondary,
    required this.accent,
    this.description = '',
    this.shape = 0,
  });

  final String id;
  final CosmeticSlot slot;
  final String name;
  final Rarity rarity;
  final int primary;
  final int secondary;
  final int accent;
  final String description;

  /// Procedural silhouette / pattern variant used by the renderer.
  final int shape;

  Map<String, Object?> toJson() => {'id': id};
}

const cosmetics = <Cosmetic>[
  // Outfits
  Cosmetic(
    id: 'outfit_recruit',
    slot: CosmeticSlot.outfit,
    name: 'Recruit',
    rarity: Rarity.common,
    primary: 0xFF4C6A8A,
    secondary: 0xFF2E3D4F,
    accent: 0xFFE8EDF2,
    description: 'Standard-issue drop suit for first-time islanders.',
  ),
  Cosmetic(
    id: 'outfit_ember',
    slot: CosmeticSlot.outfit,
    name: 'Ember Scout',
    rarity: Rarity.uncommon,
    primary: 0xFFE0552B,
    secondary: 0xFF5A1E12,
    accent: 0xFFFFC857,
    description: 'Runs hot, lands first.',
    shape: 1,
  ),
  Cosmetic(
    id: 'outfit_tide',
    slot: CosmeticSlot.outfit,
    name: 'Tide Runner',
    rarity: Rarity.rare,
    primary: 0xFF1FB6C9,
    secondary: 0xFF0D3E4A,
    accent: 0xFFD6FFF8,
    description: 'Saltwater in the veins.',
    shape: 2,
  ),
  Cosmetic(
    id: 'outfit_null',
    slot: CosmeticSlot.outfit,
    name: 'Null Knight',
    rarity: Rarity.epic,
    primary: 0xFF6B3FD1,
    secondary: 0xFF1B1030,
    accent: 0xFFB9F5FF,
    description: 'Armour forged from storm glass.',
    shape: 3,
  ),
  Cosmetic(
    id: 'outfit_aurum',
    slot: CosmeticSlot.outfit,
    name: 'Aurum Warden',
    rarity: Rarity.legendary,
    primary: 0xFFF2B134,
    secondary: 0xFF3A2A08,
    accent: 0xFFFFF4D6,
    description: 'Only the last fort standing wears gold.',
    shape: 4,
  ),
  Cosmetic(
    id: 'outfit_moss',
    slot: CosmeticSlot.outfit,
    name: 'Moss Sentinel',
    rarity: Rarity.rare,
    primary: 0xFF5FA55A,
    secondary: 0xFF1E3B1C,
    accent: 0xFFE3F5C8,
    description: 'Blends into Hollow Pines.',
    shape: 2,
  ),
  // Pickaxes
  Cosmetic(
    id: 'pickaxe_splinter',
    slot: CosmeticSlot.pickaxe,
    name: 'Splinter',
    rarity: Rarity.common,
    primary: 0xFF8B6B4A,
    secondary: 0xFF3E2A18,
    accent: 0xFFC9C9C9,
    description: 'Gets the job done.',
  ),
  Cosmetic(
    id: 'pickaxe_prism',
    slot: CosmeticSlot.pickaxe,
    name: 'Prism Pick',
    rarity: Rarity.epic,
    primary: 0xFF9BE7FF,
    secondary: 0xFF3B2F7A,
    accent: 0xFFFF9CF3,
    description: 'Refracts everything it breaks.',
    shape: 1,
  ),
  Cosmetic(
    id: 'pickaxe_anvil',
    slot: CosmeticSlot.pickaxe,
    name: 'Anvil Breaker',
    rarity: Rarity.rare,
    primary: 0xFF9AA3AD,
    secondary: 0xFF2C3238,
    accent: 0xFFFF7A3D,
    description: 'Heavy enough to argue with metal.',
    shape: 2,
  ),
  // Gliders
  Cosmetic(
    id: 'glider_kite',
    slot: CosmeticSlot.glider,
    name: 'Kite Wing',
    rarity: Rarity.common,
    primary: 0xFFE8EDF2,
    secondary: 0xFF4C6A8A,
    accent: 0xFFFFC857,
    description: 'Simple, stable, dependable.',
  ),
  Cosmetic(
    id: 'glider_stormsail',
    slot: CosmeticSlot.glider,
    name: 'Storm Sail',
    rarity: Rarity.epic,
    primary: 0xFF6B3FD1,
    secondary: 0xFF2A1B50,
    accent: 0xFFB9F5FF,
    description: 'Catches the wind the storm leaves behind.',
    shape: 1,
  ),
  Cosmetic(
    id: 'glider_sunburst',
    slot: CosmeticSlot.glider,
    name: 'Sunburst',
    rarity: Rarity.legendary,
    primary: 0xFFF2B134,
    secondary: 0xFFE0552B,
    accent: 0xFFFFF4D6,
    description: 'Arrive like a sunrise.',
    shape: 2,
  ),
  // Banners
  Cosmetic(
    id: 'banner_fort',
    slot: CosmeticSlot.banner,
    name: 'Fort Mark',
    rarity: Rarity.common,
    primary: 0xFF4C6A8A,
    secondary: 0xFF2E3D4F,
    accent: 0xFFE8EDF2,
  ),
  Cosmetic(
    id: 'banner_bolt',
    slot: CosmeticSlot.banner,
    name: 'Bolt Sigil',
    rarity: Rarity.uncommon,
    primary: 0xFFFFC857,
    secondary: 0xFF3A2A08,
    accent: 0xFFFFFFFF,
    shape: 1,
  ),
  Cosmetic(
    id: 'banner_eye',
    slot: CosmeticSlot.banner,
    name: 'Storm Eye',
    rarity: Rarity.rare,
    primary: 0xFFB86BFF,
    secondary: 0xFF1B1030,
    accent: 0xFFD6FFF8,
    shape: 2,
  ),
];

Cosmetic cosmeticById(String id) =>
    cosmetics.firstWhere((c) => c.id == id, orElse: () => cosmetics.first);

List<Cosmetic> cosmeticsFor(CosmeticSlot slot) => [
      for (final c in cosmetics)
        if (c.slot == slot) c
    ];

/// The cosmetics a player currently wears.
class Loadout {
  const Loadout({
    this.outfit = 'outfit_recruit',
    this.pickaxe = 'pickaxe_splinter',
    this.glider = 'glider_kite',
    this.banner = 'banner_fort',
  });

  final String outfit;
  final String pickaxe;
  final String glider;
  final String banner;

  Loadout withSlot(CosmeticSlot slot, String id) => switch (slot) {
        CosmeticSlot.outfit =>
          Loadout(outfit: id, pickaxe: pickaxe, glider: glider, banner: banner),
        CosmeticSlot.pickaxe =>
          Loadout(outfit: outfit, pickaxe: id, glider: glider, banner: banner),
        CosmeticSlot.glider =>
          Loadout(outfit: outfit, pickaxe: pickaxe, glider: id, banner: banner),
        CosmeticSlot.banner =>
          Loadout(outfit: outfit, pickaxe: pickaxe, glider: glider, banner: id),
      };

  String idFor(CosmeticSlot slot) => switch (slot) {
        CosmeticSlot.outfit => outfit,
        CosmeticSlot.pickaxe => pickaxe,
        CosmeticSlot.glider => glider,
        CosmeticSlot.banner => banner,
      };

  Map<String, Object?> toJson() =>
      {'o': outfit, 'p': pickaxe, 'g': glider, 'b': banner};

  static Loadout fromJson(Map<String, Object?>? j) => j == null
      ? const Loadout()
      : Loadout(
          outfit: j['o'] as String? ?? 'outfit_recruit',
          pickaxe: j['p'] as String? ?? 'pickaxe_splinter',
          glider: j['g'] as String? ?? 'glider_kite',
          banner: j['b'] as String? ?? 'banner_fort',
        );
}

/// Fort Pass: XP unlocks one reward per tier.
class PassTier {
  const PassTier(this.tier, this.xpRequired, this.rewardId);
  final int tier;
  final int xpRequired;
  final String rewardId;
}

const xpPerTier = 300;

const passTiers = <PassTier>[
  PassTier(1, xpPerTier * 1, 'banner_bolt'),
  PassTier(2, xpPerTier * 2, 'outfit_ember'),
  PassTier(3, xpPerTier * 3, 'pickaxe_anvil'),
  PassTier(4, xpPerTier * 4, 'outfit_moss'),
  PassTier(5, xpPerTier * 5, 'glider_stormsail'),
  PassTier(6, xpPerTier * 6, 'banner_eye'),
  PassTier(7, xpPerTier * 7, 'outfit_tide'),
  PassTier(8, xpPerTier * 8, 'pickaxe_prism'),
  PassTier(9, xpPerTier * 9, 'outfit_null'),
  PassTier(10, xpPerTier * 10, 'glider_sunburst'),
  PassTier(11, xpPerTier * 11, 'outfit_aurum'),
];

const defaultUnlocked = <String>{
  'outfit_recruit',
  'pickaxe_splinter',
  'glider_kite',
  'banner_fort',
};

int tierForXp(int xp) => (xp ~/ xpPerTier).clamp(0, passTiers.length);

/// Match XP formula. Deterministic so every client and the server agree.
int matchXp({
  required int placement,
  required int teams,
  required int kills,
  required int damage,
  required int survivedSeconds,
}) {
  var xp = 25 + kills * 50 + damage ~/ 4 + survivedSeconds ~/ 6 * 2;
  if (placement == 1) {
    xp += 200;
  } else if (placement <= 3) {
    xp += 100;
  } else if (placement <= (teams / 2).ceil()) {
    xp += 50;
  }
  return xp;
}
