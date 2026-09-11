import 'move.dart';
import 'piece.dart';
import 'square.dart';

/// Castling rights as a bit set.
class Castling {
  Castling._();

  static const int whiteKing = 1;
  static const int whiteQueen = 2;
  static const int blackKing = 4;
  static const int blackQueen = 8;
  static const int all = 15;
}

/// Immutable chess position with full FIDE legal move generation.
class Position {
  Position._({
    required List<Piece?> board,
    required this.turn,
    required this.castling,
    required this.epSquare,
    required this.halfmoveClock,
    required this.fullmoveNumber,
  }) : _board = board;

  final List<Piece?> _board;
  final PieceColor turn;
  final int castling;
  final int? epSquare;
  final int halfmoveClock;
  final int fullmoveNumber;

  static const String startFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static final Position initial = Position.fromFen(startFen)!;

  Piece? pieceAt(int square) => _board[square];

  /// Unmodifiable view of the 64 squares.
  List<Piece?> get board => List.unmodifiable(_board);

  // ---------------------------------------------------------------- FEN

  static Position? fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final ranks = parts[0].split('/');
    if (ranks.length != 8) return null;
    final board = List<Piece?>.filled(64, null);
    for (var r = 0; r < 8; r++) {
      final rank = 7 - r;
      var file = 0;
      for (final char in ranks[r].split('')) {
        final digit = int.tryParse(char);
        if (digit != null) {
          file += digit;
        } else {
          final piece = Piece.fromFenChar(char);
          if (piece == null || file > 7) return null;
          board[Square.of(file, rank)] = piece;
          file++;
        }
      }
      if (file != 8) return null;
    }
    final turn = PieceColor.fromLetter(parts[1]);
    if (turn == null) return null;
    var castling = 0;
    if (parts.length > 2 && parts[2] != '-') {
      for (final char in parts[2].split('')) {
        castling |= switch (char) {
          'K' => Castling.whiteKing,
          'Q' => Castling.whiteQueen,
          'k' => Castling.blackKing,
          'q' => Castling.blackQueen,
          _ => 0,
        };
      }
    }
    int? ep;
    if (parts.length > 3 && parts[3] != '-') {
      ep = Square.parse(parts[3]);
    }
    final halfmove = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    final fullmove = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    final position = Position._(
      board: board,
      turn: turn,
      castling: castling,
      epSquare: ep,
      halfmoveClock: halfmove,
      fullmoveNumber: fullmove,
    );
    // Both kings must exist for the rules to be well defined.
    if (position.kingSquare(PieceColor.white) < 0 ||
        position.kingSquare(PieceColor.black) < 0) {
      return null;
    }
    return position;
  }

  String get fen {
    final buffer = StringBuffer();
    for (var rank = 7; rank >= 0; rank--) {
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final piece = _board[Square.of(file, rank)];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            buffer.write(empty);
            empty = 0;
          }
          buffer.write(piece.fenChar);
        }
      }
      if (empty > 0) buffer.write(empty);
      if (rank > 0) buffer.write('/');
    }
    buffer.write(' ${turn.letter} ');
    if (castling == 0) {
      buffer.write('-');
    } else {
      if (castling & Castling.whiteKing != 0) buffer.write('K');
      if (castling & Castling.whiteQueen != 0) buffer.write('Q');
      if (castling & Castling.blackKing != 0) buffer.write('k');
      if (castling & Castling.blackQueen != 0) buffer.write('q');
    }
    buffer.write(' ${epSquare == null ? '-' : Square.name(epSquare!)}');
    buffer.write(' $halfmoveClock $fullmoveNumber');
    return buffer.toString();
  }

  /// Repetition key: piece placement, side to move, castling, and en passant
  /// (only when a legal en passant capture actually exists, per FIDE 9.2).
  String get repetitionKey {
    final parts = fen.split(' ');
    final epRelevant =
        epSquare != null && legalMoves().any((m) => m.to == epSquare);
    return '${parts[0]} ${parts[1]} ${parts[2]} ${epRelevant ? parts[3] : '-'}';
  }

  // ------------------------------------------------------------ queries

  int kingSquare(PieceColor color) {
    for (var i = 0; i < 64; i++) {
      final piece = _board[i];
      if (piece != null &&
          piece.type == PieceType.king &&
          piece.color == color) {
        return i;
      }
    }
    return -1;
  }

  static const _knightSteps = [
    [1, 2],
    [2, 1],
    [2, -1],
    [1, -2],
    [-1, -2],
    [-2, -1],
    [-2, 1],
    [-1, 2],
  ];
  static const _kingSteps = [
    [1, 0],
    [1, 1],
    [0, 1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [0, -1],
    [1, -1],
  ];
  static const _bishopDirs = [
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];
  static const _rookDirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];

  /// True when [square] is attacked by any piece of [by].
  bool isAttacked(int square, PieceColor by) {
    final file = Square.fileOf(square);
    final rank = Square.rankOf(square);
    // Pawns.
    final pawnDir = by == PieceColor.white ? -1 : 1;
    for (final df in [-1, 1]) {
      final f = file + df;
      final r = rank + pawnDir;
      if (Square.isValid(f, r)) {
        final p = _board[Square.of(f, r)];
        if (p != null && p.color == by && p.type == PieceType.pawn) return true;
      }
    }
    // Knights.
    for (final step in _knightSteps) {
      final f = file + step[0];
      final r = rank + step[1];
      if (Square.isValid(f, r)) {
        final p = _board[Square.of(f, r)];
        if (p != null && p.color == by && p.type == PieceType.knight) {
          return true;
        }
      }
    }
    // Kings.
    for (final step in _kingSteps) {
      final f = file + step[0];
      final r = rank + step[1];
      if (Square.isValid(f, r)) {
        final p = _board[Square.of(f, r)];
        if (p != null && p.color == by && p.type == PieceType.king) return true;
      }
    }
    // Sliders.
    if (_slidingAttack(file, rank, by, _bishopDirs, PieceType.bishop)) {
      return true;
    }
    if (_slidingAttack(file, rank, by, _rookDirs, PieceType.rook)) return true;
    return false;
  }

  bool _slidingAttack(
    int file,
    int rank,
    PieceColor by,
    List<List<int>> dirs,
    PieceType slider,
  ) {
    for (final dir in dirs) {
      var f = file + dir[0];
      var r = rank + dir[1];
      while (Square.isValid(f, r)) {
        final p = _board[Square.of(f, r)];
        if (p != null) {
          if (p.color == by &&
              (p.type == slider || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        f += dir[0];
        r += dir[1];
      }
    }
    return false;
  }

  bool get isInCheck {
    final king = kingSquare(turn);
    return king >= 0 && isAttacked(king, turn.opposite);
  }

  List<Move>? _legalCache;

  /// All legal moves for the side to move. Cached per instance.
  List<Move> legalMoves() {
    final cached = _legalCache;
    if (cached != null) return cached;
    final result = <Move>[];
    for (final move in _pseudoLegalMoves()) {
      final next = apply(move);
      final king = next.kingSquare(turn);
      if (king >= 0 && !next.isAttacked(king, turn.opposite)) {
        result.add(move);
      }
    }
    _legalCache = List.unmodifiable(result);
    return _legalCache!;
  }

  List<Move> legalMovesFrom(int square) =>
      legalMoves().where((m) => m.from == square).toList();

  bool isLegal(Move move) => legalMoves().contains(move);

  /// Resolves a move that may lack a promotion piece: if the move requires
  /// promotion, the given [promotion] (default queen) is used.
  Move? resolve(int from, int to, {PieceType promotion = PieceType.queen}) {
    for (final move in legalMoves()) {
      if (move.from == from && move.to == to) {
        if (move.promotion == null) return move;
        if (move.promotion == promotion) return move;
      }
    }
    return null;
  }

  bool requiresPromotion(int from, int to) => legalMoves()
      .any((m) => m.from == from && m.to == to && m.promotion != null);

  bool get isCheckmate => isInCheck && legalMoves().isEmpty;

  bool get isStalemate => !isInCheck && legalMoves().isEmpty;

  /// FIDE 5.2.2 style dead positions covered: K v K, K+minor v K,
  /// K+B v K+B with same-colored bishops, and K+N v K+N.
  bool get isInsufficientMaterial {
    final pieces = <Piece>[];
    final bishopSquares = <int>[];
    for (var i = 0; i < 64; i++) {
      final piece = _board[i];
      if (piece == null || piece.type == PieceType.king) continue;
      if (piece.type == PieceType.pawn ||
          piece.type == PieceType.rook ||
          piece.type == PieceType.queen) {
        return false;
      }
      pieces.add(piece);
      if (piece.type == PieceType.bishop) bishopSquares.add(i);
    }
    if (pieces.isEmpty) return true;
    if (pieces.length == 1) return true;
    if (pieces.length == 2) {
      if (bishopSquares.length == 2) {
        // Bishops on the same square color (any owners) cannot mate.
        return Square.isDark(bishopSquares[0]) ==
            Square.isDark(bishopSquares[1]);
      }
      if (pieces.every((p) => p.type == PieceType.knight) &&
          pieces[0].color != pieces[1].color) {
        return true;
      }
    }
    return false;
  }

  /// Whether [color] could, in principle, still deliver checkmate. Used for
  /// the timeout rule: flagging against a bare king (or lone minor) is a draw.
  bool hasMatingMaterial(PieceColor color) {
    var minors = 0;
    for (var i = 0; i < 64; i++) {
      final piece = _board[i];
      if (piece == null || piece.color != color) continue;
      switch (piece.type) {
        case PieceType.pawn:
        case PieceType.rook:
        case PieceType.queen:
          return true;
        case PieceType.knight:
        case PieceType.bishop:
          minors++;
        case PieceType.king:
          break;
      }
    }
    return minors >= 2;
  }

  bool isCapture(Move move) =>
      _board[move.to] != null ||
      (_board[move.from]?.type == PieceType.pawn && move.to == epSquare);

  bool isCastle(Move move) =>
      _board[move.from]?.type == PieceType.king &&
      (move.from - move.to).abs() == 2;

  bool isEnPassant(Move move) =>
      _board[move.from]?.type == PieceType.pawn &&
      move.to == epSquare &&
      _board[move.to] == null;

  /// Piece removed by [move], if any (including en passant victims).
  Piece? capturedPiece(Move move) {
    if (isEnPassant(move)) {
      return Piece(turn.opposite, PieceType.pawn);
    }
    return _board[move.to];
  }

  // ------------------------------------------------------ move generation

  Iterable<Move> _pseudoLegalMoves() sync* {
    final us = turn;
    for (var from = 0; from < 64; from++) {
      final piece = _board[from];
      if (piece == null || piece.color != us) continue;
      final file = Square.fileOf(from);
      final rank = Square.rankOf(from);
      switch (piece.type) {
        case PieceType.pawn:
          yield* _pawnMoves(from, file, rank, us);
        case PieceType.knight:
          for (final step in _knightSteps) {
            final f = file + step[0];
            final r = rank + step[1];
            if (!Square.isValid(f, r)) continue;
            final to = Square.of(f, r);
            final target = _board[to];
            if (target == null || target.color != us) yield Move(from, to);
          }
        case PieceType.bishop:
          yield* _slides(from, file, rank, us, _bishopDirs);
        case PieceType.rook:
          yield* _slides(from, file, rank, us, _rookDirs);
        case PieceType.queen:
          yield* _slides(from, file, rank, us, _bishopDirs);
          yield* _slides(from, file, rank, us, _rookDirs);
        case PieceType.king:
          for (final step in _kingSteps) {
            final f = file + step[0];
            final r = rank + step[1];
            if (!Square.isValid(f, r)) continue;
            final to = Square.of(f, r);
            final target = _board[to];
            if (target == null || target.color != us) yield Move(from, to);
          }
          yield* _castlingMoves(from, us);
      }
    }
  }

  Iterable<Move> _slides(
    int from,
    int file,
    int rank,
    PieceColor us,
    List<List<int>> dirs,
  ) sync* {
    for (final dir in dirs) {
      var f = file + dir[0];
      var r = rank + dir[1];
      while (Square.isValid(f, r)) {
        final to = Square.of(f, r);
        final target = _board[to];
        if (target == null) {
          yield Move(from, to);
        } else {
          if (target.color != us) yield Move(from, to);
          break;
        }
        f += dir[0];
        r += dir[1];
      }
    }
  }

  Iterable<Move> _pawnMoves(int from, int file, int rank, PieceColor us) sync* {
    final dir = us == PieceColor.white ? 1 : -1;
    final startRank = us == PieceColor.white ? 1 : 6;
    final promoRank = us == PieceColor.white ? 7 : 0;
    final oneRank = rank + dir;
    if (!Square.isValid(file, oneRank)) return;
    final one = Square.of(file, oneRank);
    if (_board[one] == null) {
      yield* _pawnTargets(from, one, oneRank == promoRank);
      if (rank == startRank) {
        final two = Square.of(file, rank + 2 * dir);
        if (_board[two] == null) yield Move(from, two);
      }
    }
    for (final df in [-1, 1]) {
      final f = file + df;
      if (!Square.isValid(f, oneRank)) continue;
      final to = Square.of(f, oneRank);
      final target = _board[to];
      if ((target != null && target.color != us) || to == epSquare) {
        yield* _pawnTargets(from, to, oneRank == promoRank);
      }
    }
  }

  Iterable<Move> _pawnTargets(int from, int to, bool promotes) sync* {
    if (promotes) {
      for (final type in PieceType.promotionTargets) {
        yield Move(from, to, promotion: type);
      }
    } else {
      yield Move(from, to);
    }
  }

  Iterable<Move> _castlingMoves(int from, PieceColor us) sync* {
    final home = us == PieceColor.white ? Square.of(4, 0) : Square.of(4, 7);
    if (from != home) return;
    final enemy = us.opposite;
    if (isAttacked(from, enemy)) return;
    final kingRight =
        us == PieceColor.white ? Castling.whiteKing : Castling.blackKing;
    final queenRight =
        us == PieceColor.white ? Castling.whiteQueen : Castling.blackQueen;
    final rank = Square.rankOf(from);
    if (castling & kingRight != 0) {
      final f = Square.of(5, rank);
      final g = Square.of(6, rank);
      final h = Square.of(7, rank);
      final rook = _board[h];
      if (rook != null &&
          rook.type == PieceType.rook &&
          rook.color == us &&
          _board[f] == null &&
          _board[g] == null &&
          !isAttacked(f, enemy) &&
          !isAttacked(g, enemy)) {
        yield Move(from, g);
      }
    }
    if (castling & queenRight != 0) {
      final d = Square.of(3, rank);
      final c = Square.of(2, rank);
      final b = Square.of(1, rank);
      final a = Square.of(0, rank);
      final rook = _board[a];
      if (rook != null &&
          rook.type == PieceType.rook &&
          rook.color == us &&
          _board[d] == null &&
          _board[c] == null &&
          _board[b] == null &&
          !isAttacked(d, enemy) &&
          !isAttacked(c, enemy)) {
        yield Move(from, c);
      }
    }
  }

  // -------------------------------------------------------------- apply

  /// Applies [move] without legality checks (callers validate first).
  Position apply(Move move) {
    final board = List<Piece?>.of(_board);
    final piece = board[move.from]!;
    var castlingRights = castling;
    int? nextEp;
    var halfmove = halfmoveClock + 1;
    final captured = board[move.to];
    if (captured != null || piece.type == PieceType.pawn) halfmove = 0;

    board[move.from] = null;
    board[move.to] = piece;

    if (piece.type == PieceType.pawn) {
      final fromRank = Square.rankOf(move.from);
      final toRank = Square.rankOf(move.to);
      if ((fromRank - toRank).abs() == 2) {
        nextEp = Square.of(Square.fileOf(move.from), (fromRank + toRank) ~/ 2);
      }
      if (move.to == epSquare && captured == null) {
        board[Square.of(Square.fileOf(move.to), fromRank)] = null;
      }
      if (move.promotion != null) {
        board[move.to] = Piece(piece.color, move.promotion!);
      }
    }

    if (piece.type == PieceType.king) {
      castlingRights &= piece.color == PieceColor.white
          ? ~(Castling.whiteKing | Castling.whiteQueen)
          : ~(Castling.blackKing | Castling.blackQueen);
      final delta = move.to - move.from;
      if (delta == 2) {
        final rank = Square.rankOf(move.from);
        board[Square.of(5, rank)] = board[Square.of(7, rank)];
        board[Square.of(7, rank)] = null;
      } else if (delta == -2) {
        final rank = Square.rankOf(move.from);
        board[Square.of(3, rank)] = board[Square.of(0, rank)];
        board[Square.of(0, rank)] = null;
      }
    }

    // Rook moves or captures remove the matching right.
    castlingRights &= ~_rookRight(move.from);
    castlingRights &= ~_rookRight(move.to);

    return Position._(
      board: board,
      turn: turn.opposite,
      castling: castlingRights,
      epSquare: nextEp,
      halfmoveClock: halfmove,
      fullmoveNumber:
          turn == PieceColor.black ? fullmoveNumber + 1 : fullmoveNumber,
    );
  }

  static int _rookRight(int square) => switch (square) {
        0 => Castling.whiteQueen,
        7 => Castling.whiteKing,
        56 => Castling.blackQueen,
        63 => Castling.blackKing,
        _ => 0,
      };

  /// Material balance from White's point of view, in centipawns.
  int get materialBalance {
    var total = 0;
    for (final piece in _board) {
      if (piece == null) continue;
      total += piece.isWhite ? piece.type.value : -piece.type.value;
    }
    return total;
  }

  /// Pieces captured so far relative to the standard starting set, per color.
  Map<PieceColor, List<PieceType>> capturedSince(Position start) {
    final result = {
      PieceColor.white: <PieceType>[],
      PieceColor.black: <PieceType>[],
    };
    for (final color in PieceColor.values) {
      for (final type in PieceType.values) {
        final before = start._count(color, type);
        final now = _count(color, type);
        for (var i = now; i < before; i++) {
          result[color]!.add(type);
        }
      }
    }
    return result;
  }

  int _count(PieceColor color, PieceType type) {
    var n = 0;
    for (final piece in _board) {
      if (piece != null && piece.color == color && piece.type == type) n++;
    }
    return n;
  }

  @override
  String toString() => fen;
}
