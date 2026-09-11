import 'piece.dart';
import 'square.dart';

/// A single board action: either a normal move (`from` != null) or a drop of a
/// reserve piece (`drop` != null) onto an empty square.
class Move {
  const Move.normal(this.from, this.to, {this.promotion}) : drop = null;

  const Move.drop(this.drop, this.to) : from = null, promotion = null;

  final int? from;
  final int to;
  final PieceType? promotion;
  final PieceType? drop;

  bool get isDrop => drop != null;

  /// Compact UCI-like text: `e2e4`, `e7e8q`, `N@f3`.
  String get uci {
    if (isDrop) return '${drop!.letter}@${Square.name(to)}';
    final p = promotion == null ? '' : promotion!.letter.toLowerCase();
    return '${Square.name(from!)}${Square.name(to)}$p';
  }

  static Move parse(String text) {
    if (text.length >= 4 && text[1] == '@') {
      return Move.drop(
        PieceType.fromLetter(text[0]),
        Square.parse(text.substring(2, 4)),
      );
    }
    if (text.length < 4) throw FormatException('bad move $text');
    return Move.normal(
      Square.parse(text.substring(0, 2)),
      Square.parse(text.substring(2, 4)),
      promotion: text.length > 4 ? PieceType.fromLetter(text[4]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (from != null) 'from': Square.name(from!),
    'to': Square.name(to),
    if (promotion != null) 'promotion': promotion!.letter,
    if (drop != null) 'drop': drop!.letter,
  };

  static Move fromJson(Map<String, dynamic> json) {
    final to = Square.parse(json['to'] as String);
    if (json['drop'] != null) {
      return Move.drop(PieceType.fromLetter(json['drop'] as String), to);
    }
    return Move.normal(
      Square.parse(json['from'] as String),
      to,
      promotion: json['promotion'] == null
          ? null
          : PieceType.fromLetter(json['promotion'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion &&
      other.drop == drop;

  @override
  int get hashCode => Object.hash(from, to, promotion, drop);

  @override
  String toString() => uci;
}
