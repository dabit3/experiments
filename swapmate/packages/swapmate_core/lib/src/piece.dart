enum PieceColor {
  white,
  black;

  PieceColor get opposite => this == white ? black : white;

  String get letter => this == white ? 'w' : 'b';

  static PieceColor fromLetter(String letter) => letter == 'w' ? white : black;
}

enum PieceType {
  pawn('P'),
  knight('N'),
  bishop('B'),
  rook('R'),
  queen('Q'),
  king('K');

  const PieceType(this.letter);

  /// Upper-case SAN / FEN letter.
  final String letter;

  static PieceType fromLetter(String letter) =>
      PieceType.values.firstWhere((t) => t.letter == letter.toUpperCase());

  /// Types a pawn may promote to.
  static const promotions = [
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
  ];

  /// Types that may sit in a reserve tray.
  static const droppable = [
    PieceType.pawn,
    PieceType.knight,
    PieceType.bishop,
    PieceType.rook,
    PieceType.queen,
  ];
}

/// A piece on the board. [promoted] marks a piece that started life as a pawn
/// and therefore reverts to a pawn when captured.
class Piece {
  const Piece(this.color, this.type, {this.promoted = false});

  final PieceColor color;
  final PieceType type;
  final bool promoted;

  /// FEN letter: upper-case for white, lower-case for black, with a trailing
  /// `~` for promoted pieces (the crazyhouse/bughouse FEN convention).
  String get fen {
    final l = color == PieceColor.white
        ? type.letter
        : type.letter.toLowerCase();
    return promoted ? '$l~' : l;
  }

  /// The piece a partner receives when this piece is captured.
  Piece get asReserve => Piece(color, promoted ? PieceType.pawn : type);

  Piece withType(PieceType t, {bool? promoted}) =>
      Piece(color, t, promoted: promoted ?? this.promoted);

  @override
  bool operator ==(Object other) =>
      other is Piece &&
      other.color == color &&
      other.type == type &&
      other.promoted == promoted;

  @override
  int get hashCode => Object.hash(color, type, promoted);

  @override
  String toString() => fen;
}

/// A tray of droppable pieces of a single color.
class Reserve {
  Reserve([Map<PieceType, int>? counts])
    : _counts = {for (final t in PieceType.droppable) t: counts?[t] ?? 0};

  final Map<PieceType, int> _counts;

  int count(PieceType t) => _counts[t] ?? 0;

  bool has(PieceType t) => count(t) > 0;

  bool get isEmpty => _counts.values.every((c) => c == 0);

  int get total => _counts.values.fold(0, (a, b) => a + b);

  Reserve add(PieceType t) => Reserve({..._counts, t: count(t) + 1});

  Reserve remove(PieceType t) {
    assert(has(t), 'no $t in reserve');
    return Reserve({..._counts, t: count(t) - 1});
  }

  /// Pieces in canonical display order (P N B R Q), one entry per piece.
  List<PieceType> get expanded => [
    for (final t in PieceType.droppable)
      for (var i = 0; i < count(t); i++) t,
  ];

  Map<String, int> toJson() => {
    for (final t in PieceType.droppable)
      if (count(t) > 0) t.letter: count(t),
  };

  static Reserve fromJson(Map<String, dynamic> json) => Reserve({
    for (final e in json.entries) PieceType.fromLetter(e.key): e.value as int,
  });

  /// Crazyhouse-style reserve string, e.g. `PPN` (letters in the color's case).
  String fen(PieceColor color) => expanded
      .map((t) => color == PieceColor.white ? t.letter : t.letter.toLowerCase())
      .join();

  @override
  bool operator ==(Object other) =>
      other is Reserve &&
      PieceType.droppable.every((t) => other.count(t) == count(t));

  @override
  int get hashCode => Object.hashAll(PieceType.droppable.map(count));

  @override
  String toString() => fen(PieceColor.white);
}
