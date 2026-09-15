/// Avatar configuration and the original Brickfolk item catalog.
///
/// Colors are ARGB integers so the same values render identically on every
/// client. Items are referenced by stable IDs.
class Avatar {
  const Avatar({
    this.headColor = 0xFFF5C04A,
    this.torsoColor = 0xFF3E7BFA,
    this.armColor = 0xFFF5C04A,
    this.legColor = 0xFF2F9E5B,
    this.face = 'face_smile',
    this.hat = 'hat_none',
    this.accessory = 'acc_none',
  });

  final int headColor;
  final int torsoColor;
  final int armColor;
  final int legColor;
  final String face;
  final String hat;
  final String accessory;

  Avatar copyWith({
    int? headColor,
    int? torsoColor,
    int? armColor,
    int? legColor,
    String? face,
    String? hat,
    String? accessory,
  }) {
    return Avatar(
      headColor: headColor ?? this.headColor,
      torsoColor: torsoColor ?? this.torsoColor,
      armColor: armColor ?? this.armColor,
      legColor: legColor ?? this.legColor,
      face: face ?? this.face,
      hat: hat ?? this.hat,
      accessory: accessory ?? this.accessory,
    );
  }

  Map<String, Object?> toJson() => {
    'headColor': headColor,
    'torsoColor': torsoColor,
    'armColor': armColor,
    'legColor': legColor,
    'face': face,
    'hat': hat,
    'accessory': accessory,
  };

  static Avatar fromJson(Map<String, Object?> json) {
    const d = Avatar();
    return Avatar(
      headColor: _int(json['headColor']) ?? d.headColor,
      torsoColor: _int(json['torsoColor']) ?? d.torsoColor,
      armColor: _int(json['armColor']) ?? d.armColor,
      legColor: _int(json['legColor']) ?? d.legColor,
      face: json['face'] as String? ?? d.face,
      hat: json['hat'] as String? ?? d.hat,
      accessory: json['accessory'] as String? ?? d.accessory,
    );
  }

  /// Returns a copy that only references items the player owns (or free ones).
  Avatar sanitized(Set<String> owned) {
    String keep(String id, String fallback) {
      final item = catalogById[id];
      if (item == null) return fallback;
      if (item.price == 0 || owned.contains(id)) return id;
      return fallback;
    }

    return Avatar(
      headColor: _keepColor(headColor),
      torsoColor: _keepColor(torsoColor),
      armColor: _keepColor(armColor),
      legColor: _keepColor(legColor),
      face: keep(face, 'face_smile'),
      hat: keep(hat, 'hat_none'),
      accessory: keep(accessory, 'acc_none'),
    );
  }

  static int _keepColor(int c) => bodyColors.contains(c) ? c : bodyColors.first;

  static int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

  @override
  bool operator ==(Object other) =>
      other is Avatar &&
      other.headColor == headColor &&
      other.torsoColor == torsoColor &&
      other.armColor == armColor &&
      other.legColor == legColor &&
      other.face == face &&
      other.hat == hat &&
      other.accessory == accessory;

  @override
  int get hashCode => Object.hash(
    headColor,
    torsoColor,
    armColor,
    legColor,
    face,
    hat,
    accessory,
  );
}

enum ItemSlot { face, hat, accessory }

class CatalogItem {
  const CatalogItem(this.id, this.name, this.slot, this.price, this.blurb);

  final String id;
  final String name;
  final ItemSlot slot;
  final int price;
  final String blurb;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'slot': slot.name,
    'price': price,
    'blurb': blurb,
  };
}

/// Body color palette (ARGB). Names are used for accessibility labels.
const List<int> bodyColors = [
  0xFFF5C04A, // Sunbrick yellow
  0xFFFF8A4C, // Kiln orange
  0xFFE5484D, // Cherry red
  0xFFF06BB7, // Bubblegum
  0xFF8E5CF7, // Grape
  0xFF3E7BFA, // Sky blue
  0xFF35B8D6, // Lagoon
  0xFF2F9E5B, // Meadow green
  0xFFB7D24B, // Lime
  0xFF8C5A3C, // Cocoa
  0xFFF4E6D2, // Sand
  0xFF9AA3AF, // Pebble grey
  0xFF3A3F4B, // Charcoal
  0xFFFFFFFF, // Cloud white
];

const List<String> bodyColorNames = [
  'Sunbrick yellow',
  'Kiln orange',
  'Cherry red',
  'Bubblegum',
  'Grape',
  'Sky blue',
  'Lagoon',
  'Meadow green',
  'Lime',
  'Cocoa',
  'Sand',
  'Pebble grey',
  'Charcoal',
  'Cloud white',
];

const List<CatalogItem> catalog = [
  // Faces
  CatalogItem('face_smile', 'Classic Smile', ItemSlot.face, 0, 'Default face.'),
  CatalogItem('face_grin', 'Big Grin', ItemSlot.face, 40, 'All teeth.'),
  CatalogItem('face_wink', 'Wink', ItemSlot.face, 60, 'Knows something.'),
  CatalogItem('face_shades', 'Shades', ItemSlot.face, 120, 'Too cool.'),
  CatalogItem('face_sleepy', 'Sleepy', ItemSlot.face, 50, 'Five more minutes.'),
  CatalogItem('face_robot', 'Bolt Face', ItemSlot.face, 200, 'Beep boop.'),
  // Hats
  CatalogItem('hat_none', 'No Hat', ItemSlot.hat, 0, 'Fresh air.'),
  CatalogItem('hat_cap', 'Builder Cap', ItemSlot.hat, 50, 'Classic cap.'),
  CatalogItem('hat_crown', 'Pip Crown', ItemSlot.hat, 400, 'For royalty.'),
  CatalogItem('hat_helmet', 'Hard Hat', ItemSlot.hat, 90, 'Safety first.'),
  CatalogItem(
    'hat_wizard',
    'Star Wizard',
    ItemSlot.hat,
    250,
    'Pointy and wise.',
  ),
  CatalogItem('hat_beanie', 'Cozy Beanie', ItemSlot.hat, 70, 'Warm ears.'),
  CatalogItem('hat_propeller', 'Propeller Top', ItemSlot.hat, 150, 'Spins.'),
  // Accessories
  CatalogItem('acc_none', 'None', ItemSlot.accessory, 0, 'Plain torso.'),
  CatalogItem('acc_scarf', 'Red Scarf', ItemSlot.accessory, 60, 'Flowing.'),
  CatalogItem(
    'acc_backpack',
    'Brick Pack',
    ItemSlot.accessory,
    110,
    'Carries bricks.',
  ),
  CatalogItem('acc_cape', 'Hero Cape', ItemSlot.accessory, 300, 'Dramatic.'),
  CatalogItem('acc_tie', 'Bow Tie', ItemSlot.accessory, 45, 'Dapper.'),
  CatalogItem(
    'acc_wings',
    'Pixel Wings',
    ItemSlot.accessory,
    500,
    'Cosmetic flight.',
  ),
];

final Map<String, CatalogItem> catalogById = {
  for (final item in catalog) item.id: item,
};
