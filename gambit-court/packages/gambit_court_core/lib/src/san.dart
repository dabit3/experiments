import 'move.dart';
import 'piece.dart';
import 'position.dart';
import 'square.dart';

/// Standard Algebraic Notation rendering and parsing.
class San {
  San._();

  /// Renders [move] (which must be legal in [position]) as SAN, including
  /// `+` / `#` suffixes.
  static String render(Position position, Move move) {
    final piece = position.pieceAt(move.from)!;
    final buffer = StringBuffer();
    if (position.isCastle(move)) {
      buffer.write(move.to > move.from ? 'O-O' : 'O-O-O');
    } else {
      final capture = position.isCapture(move);
      if (piece.type == PieceType.pawn) {
        if (capture) buffer.write('abcdefgh'[Square.fileOf(move.from)]);
      } else {
        buffer.write(piece.type.sanLetter);
        buffer.write(_disambiguation(position, move, piece));
      }
      if (capture) buffer.write('x');
      buffer.write(Square.name(move.to));
      if (move.promotion != null) {
        buffer.write('=${move.promotion!.sanLetter}');
      }
    }
    final next = position.apply(move);
    if (next.isCheckmate) {
      buffer.write('#');
    } else if (next.isInCheck) {
      buffer.write('+');
    }
    return buffer.toString();
  }

  static String _disambiguation(Position position, Move move, Piece piece) {
    final rivals = position
        .legalMoves()
        .where((m) =>
            m.to == move.to &&
            m.from != move.from &&
            position.pieceAt(m.from) == piece)
        .toList();
    if (rivals.isEmpty) return '';
    final file = Square.fileOf(move.from);
    final rank = Square.rankOf(move.from);
    final sameFile = rivals.any((m) => Square.fileOf(m.from) == file);
    final sameRank = rivals.any((m) => Square.rankOf(m.from) == rank);
    if (!sameFile) return 'abcdefgh'[file];
    if (!sameRank) return '${rank + 1}';
    return Square.name(move.from);
  }

  /// Parses SAN (tolerant of `+`, `#`, `!?`, `x`, `=`, `0-0`) into a legal
  /// move. Returns null when the text is not a legal move here.
  static Move? parse(Position position, String text) {
    var san = text.trim();
    san = san.replaceAll(RegExp(r'[+#!?]+$'), '');
    if (san.isEmpty) return null;
    final normalized = san.replaceAll('0', 'O');
    final legal = position.legalMoves();
    if (normalized == 'O-O' || normalized == 'O-O-O') {
      final kingSide = normalized == 'O-O';
      for (final move in legal) {
        if (position.isCastle(move) && (move.to > move.from) == kingSide) {
          return move;
        }
      }
      return null;
    }
    final match = RegExp(
      r'^([NBRQK])?([a-h])?([1-8])?x?([a-h][1-8])(?:=?([NBRQ]))?$',
    ).firstMatch(san);
    if (match == null) {
      // Accept long algebraic / UCI too.
      final uci = Move.parseUci(san.replaceAll('-', '').toLowerCase());
      if (uci != null) {
        return position.resolve(uci.from, uci.to,
            promotion: uci.promotion ?? PieceType.queen);
      }
      return null;
    }
    final pieceLetter = match.group(1);
    final fromFile = match.group(2);
    final fromRank = match.group(3);
    final to = Square.parse(match.group(4)!)!;
    final promoLetter = match.group(5);
    final type = pieceLetter == null
        ? PieceType.pawn
        : PieceType.fromLetter(pieceLetter.toLowerCase())!;
    final promotion = promoLetter == null
        ? null
        : PieceType.fromLetter(promoLetter.toLowerCase());
    final candidates = legal.where((m) {
      if (m.to != to) return false;
      final piece = position.pieceAt(m.from)!;
      if (piece.type != type) return false;
      if (fromFile != null && 'abcdefgh'[Square.fileOf(m.from)] != fromFile) {
        return false;
      }
      if (fromRank != null && '${Square.rankOf(m.from) + 1}' != fromRank) {
        return false;
      }
      if (type == PieceType.pawn) {
        if (promotion != null) return m.promotion == promotion;
        // Pawn promotions without a suffix default to queen.
        if (m.promotion != null) return m.promotion == PieceType.queen;
      }
      return true;
    }).toList();
    if (candidates.length == 1) return candidates.first;
    return null;
  }
}
