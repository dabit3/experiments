enum PieceColor {
  white,
  black;

  PieceColor get opposite =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;

  String get letter => this == PieceColor.white ? 'w' : 'b';

  String get label => this == PieceColor.white ? 'White' : 'Black';

  static PieceColor? fromLetter(String letter) => switch (letter) {
        'w' => PieceColor.white,
        'b' => PieceColor.black,
        _ => null,
      };
}

enum PieceType {
  pawn('p', 'P', 100),
  knight('n', 'N', 320),
  bishop('b', 'B', 330),
  rook('r', 'R', 500),
  queen('q', 'Q', 900),
  king('k', 'K', 0);

  const PieceType(this.letter, this.sanLetter, this.value);

  /// Lowercase FEN letter.
  final String letter;

  /// Uppercase letter used in SAN (empty for pawns when rendering).
  final String sanLetter;

  /// Material value in centipawns.
  final int value;

  static PieceType? fromLetter(String letter) {
    for (final type in values) {
      if (type.letter == letter.toLowerCase()) return type;
    }
    return null;
  }

  static const promotionTargets = [
    PieceType.queen,
    PieceType.rook,
    PieceType.bishop,
    PieceType.knight,
  ];
}

class Piece {
  const Piece(this.color, this.type);

  final PieceColor color;
  final PieceType type;

  /// FEN character: uppercase for white, lowercase for black.
  String get fenChar =>
      color == PieceColor.white ? type.letter.toUpperCase() : type.letter;

  static Piece? fromFenChar(String char) {
    final type = PieceType.fromLetter(char);
    if (type == null) return null;
    final color =
        char == char.toUpperCase() ? PieceColor.white : PieceColor.black;
    return Piece(color, type);
  }

  bool get isWhite => color == PieceColor.white;

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.type == type;

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => fenChar;
}
