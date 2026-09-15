import 'piece.dart';
import 'square.dart';

/// A move in coordinate form. Castling is encoded as the king moving two
/// squares; en passant as the capturing pawn's diagonal step.
class Move {
  const Move(this.from, this.to, {this.promotion});

  final int from;
  final int to;
  final PieceType? promotion;

  /// Long algebraic notation such as `e2e4` or `e7e8q`.
  String get uci =>
      '${Square.name(from)}${Square.name(to)}${promotion?.letter ?? ''}';

  static Move? parseUci(String text) {
    if (text.length < 4 || text.length > 5) return null;
    final from = Square.parse(text.substring(0, 2));
    final to = Square.parse(text.substring(2, 4));
    if (from == null || to == null) return null;
    PieceType? promotion;
    if (text.length == 5) {
      promotion = PieceType.fromLetter(text[4]);
      if (promotion == null ||
          !PieceType.promotionTargets.contains(promotion)) {
        return null;
      }
    }
    return Move(from, to, promotion: promotion);
  }

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => uci;
}
