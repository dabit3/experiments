import 'move.dart';
import 'piece.dart';
import 'square.dart';

/// Castling-right bits.
class Castling {
  Castling._();
  static const whiteKing = 1;
  static const whiteQueen = 2;
  static const blackKing = 4;
  static const blackQueen = 8;
  static const all = 15;
}

/// Result of applying a move to a [Position].
class MoveOutcome {
  const MoveOutcome({
    required this.position,
    required this.captured,
    required this.san,
    required this.isCheck,
    required this.isCheckmate,
    required this.isStalemate,
  });

  final Position position;

  /// The captured piece, already converted to what the partner receives
  /// (promoted pieces revert to pawns). Null when nothing was captured.
  final Piece? captured;
  final String san;
  final bool isCheck;
  final bool isCheckmate;
  final bool isStalemate;
}

/// One bughouse board: the 64 squares, side to move, castling rights, en
/// passant target and the two reserve trays. Immutable; every mutation
/// returns a new instance.
class Position {
  Position({
    required List<Piece?> squares,
    required this.turn,
    this.castling = Castling.all,
    this.epSquare,
    Reserve? whiteReserve,
    Reserve? blackReserve,
    this.fullmove = 1,
  }) : squares = List.unmodifiable(squares),
       whiteReserve = whiteReserve ?? Reserve(),
       blackReserve = blackReserve ?? Reserve();

  final List<Piece?> squares;
  final PieceColor turn;
  final int castling;
  final int? epSquare;
  final Reserve whiteReserve;
  final Reserve blackReserve;
  final int fullmove;

  static const _backRank = [
    PieceType.rook,
    PieceType.knight,
    PieceType.bishop,
    PieceType.queen,
    PieceType.king,
    PieceType.bishop,
    PieceType.knight,
    PieceType.rook,
  ];

  factory Position.initial() {
    final squares = List<Piece?>.filled(64, null);
    for (var f = 0; f < 8; f++) {
      squares[Square.of(f, 0)] = Piece(PieceColor.white, _backRank[f]);
      squares[Square.of(f, 1)] = const Piece(PieceColor.white, PieceType.pawn);
      squares[Square.of(f, 6)] = const Piece(PieceColor.black, PieceType.pawn);
      squares[Square.of(f, 7)] = Piece(PieceColor.black, _backRank[f]);
    }
    return Position(squares: squares, turn: PieceColor.white);
  }

  Piece? at(int sq) => squares[sq];

  Reserve reserve(PieceColor c) =>
      c == PieceColor.white ? whiteReserve : blackReserve;

  Position copyWith({
    List<Piece?>? squares,
    PieceColor? turn,
    int? castling,
    int? epSquare = _keep,
    Reserve? whiteReserve,
    Reserve? blackReserve,
    int? fullmove,
  }) => Position(
    squares: squares ?? this.squares,
    turn: turn ?? this.turn,
    castling: castling ?? this.castling,
    epSquare: identical(epSquare, _keep) ? this.epSquare : epSquare,
    whiteReserve: whiteReserve ?? this.whiteReserve,
    blackReserve: blackReserve ?? this.blackReserve,
    fullmove: fullmove ?? this.fullmove,
  );

  static const int _keep = -99;

  /// Adds a captured piece from the partner board to this board's reserve.
  Position addToReserve(PieceColor color, PieceType type) =>
      color == PieceColor.white
      ? copyWith(whiteReserve: whiteReserve.add(type))
      : copyWith(blackReserve: blackReserve.add(type));

  int? kingSquare(PieceColor c) {
    for (var i = 0; i < 64; i++) {
      final p = squares[i];
      if (p != null && p.color == c && p.type == PieceType.king) return i;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Attack detection
  // ---------------------------------------------------------------------------

  static const _knightDeltas = [
    [1, 2],
    [2, 1],
    [2, -1],
    [1, -2],
    [-1, -2],
    [-2, -1],
    [-2, 1],
    [-1, 2],
  ];
  static const _kingDeltas = [
    [1, 0],
    [1, 1],
    [0, 1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [0, -1],
    [1, -1],
  ];
  static const _rookDirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];
  static const _bishopDirs = [
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  /// Whether [sq] is attacked by any piece of [by].
  bool isAttacked(int sq, PieceColor by) {
    final f = Square.fileOf(sq);
    final r = Square.rankOf(sq);
    // Pawns: a pawn of color `by` attacks diagonally forward.
    final pawnRank = by == PieceColor.white ? r - 1 : r + 1;
    for (final df in const [-1, 1]) {
      if (Square.valid(f + df, pawnRank)) {
        final p = squares[Square.of(f + df, pawnRank)];
        if (p != null && p.color == by && p.type == PieceType.pawn) return true;
      }
    }
    for (final d in _knightDeltas) {
      if (Square.valid(f + d[0], r + d[1])) {
        final p = squares[Square.of(f + d[0], r + d[1])];
        if (p != null && p.color == by && p.type == PieceType.knight) {
          return true;
        }
      }
    }
    for (final d in _kingDeltas) {
      if (Square.valid(f + d[0], r + d[1])) {
        final p = squares[Square.of(f + d[0], r + d[1])];
        if (p != null && p.color == by && p.type == PieceType.king) return true;
      }
    }
    if (_slidingAttack(f, r, by, _rookDirs, PieceType.rook)) return true;
    if (_slidingAttack(f, r, by, _bishopDirs, PieceType.bishop)) return true;
    return false;
  }

  bool _slidingAttack(
    int f,
    int r,
    PieceColor by,
    List<List<int>> dirs,
    PieceType slider,
  ) {
    for (final d in dirs) {
      var nf = f + d[0];
      var nr = r + d[1];
      while (Square.valid(nf, nr)) {
        final p = squares[Square.of(nf, nr)];
        if (p != null) {
          if (p.color == by &&
              (p.type == slider || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        nf += d[0];
        nr += d[1];
      }
    }
    return false;
  }

  bool inCheck([PieceColor? color]) {
    final c = color ?? turn;
    final k = kingSquare(c);
    return k != null && isAttacked(k, c.opposite);
  }

  // ---------------------------------------------------------------------------
  // Move generation
  // ---------------------------------------------------------------------------

  /// All legal moves (including drops) for the side to move.
  List<Move> legalMoves() {
    final out = <Move>[];
    for (final m in _pseudoMoves()) {
      if (!_apply(m).inCheck(turn)) out.add(m);
    }
    return out;
  }

  /// Legal destinations for a piece standing on [from].
  List<Move> legalMovesFrom(int from) =>
      legalMoves().where((m) => m.from == from).toList();

  /// Legal drop squares for a reserve piece of the side to move.
  List<int> legalDropSquares(PieceType type) =>
      legalMoves().where((m) => m.drop == type).map((m) => m.to).toList();

  bool isLegal(Move m) => legalMoves().contains(m);

  bool get hasLegalMoves => legalMoves().isNotEmpty;

  bool get isCheckmate => inCheck() && !hasLegalMoves;

  bool get isStalemate => !inCheck() && !hasLegalMoves;

  List<Move> _pseudoMoves() {
    final out = <Move>[];
    final me = turn;
    for (var sq = 0; sq < 64; sq++) {
      final p = squares[sq];
      if (p == null || p.color != me) continue;
      final f = Square.fileOf(sq);
      final r = Square.rankOf(sq);
      switch (p.type) {
        case PieceType.pawn:
          _pawnMoves(sq, f, r, me, out);
        case PieceType.knight:
          _stepMoves(sq, f, r, me, _knightDeltas, out);
        case PieceType.king:
          _stepMoves(sq, f, r, me, _kingDeltas, out);
          _castlingMoves(sq, me, out);
        case PieceType.bishop:
          _slideMoves(sq, f, r, me, _bishopDirs, out);
        case PieceType.rook:
          _slideMoves(sq, f, r, me, _rookDirs, out);
        case PieceType.queen:
          _slideMoves(sq, f, r, me, _rookDirs, out);
          _slideMoves(sq, f, r, me, _bishopDirs, out);
      }
    }
    final res = reserve(me);
    if (!res.isEmpty) {
      for (var sq = 0; sq < 64; sq++) {
        if (squares[sq] != null) continue;
        final rank = Square.rankOf(sq);
        for (final t in PieceType.droppable) {
          if (!res.has(t)) continue;
          if (t == PieceType.pawn && (rank == 0 || rank == 7)) continue;
          out.add(Move.drop(t, sq));
        }
      }
    }
    return out;
  }

  void _pawnMoves(int sq, int f, int r, PieceColor me, List<Move> out) {
    final dir = me == PieceColor.white ? 1 : -1;
    final startRank = me == PieceColor.white ? 1 : 6;
    final promoRank = me == PieceColor.white ? 7 : 0;
    void push(int to) {
      if (Square.rankOf(to) == promoRank) {
        for (final t in PieceType.promotions) {
          out.add(Move.normal(sq, to, promotion: t));
        }
      } else {
        out.add(Move.normal(sq, to));
      }
    }

    final r1 = r + dir;
    if (Square.valid(f, r1) && squares[Square.of(f, r1)] == null) {
      push(Square.of(f, r1));
      final r2 = r + 2 * dir;
      if (r == startRank && squares[Square.of(f, r2)] == null) {
        out.add(Move.normal(sq, Square.of(f, r2)));
      }
    }
    for (final df in const [-1, 1]) {
      if (!Square.valid(f + df, r1)) continue;
      final to = Square.of(f + df, r1);
      final target = squares[to];
      if (target != null && target.color != me) {
        push(to);
      } else if (target == null && to == epSquare) {
        out.add(Move.normal(sq, to));
      }
    }
  }

  void _stepMoves(
    int sq,
    int f,
    int r,
    PieceColor me,
    List<List<int>> deltas,
    List<Move> out,
  ) {
    for (final d in deltas) {
      if (!Square.valid(f + d[0], r + d[1])) continue;
      final to = Square.of(f + d[0], r + d[1]);
      final target = squares[to];
      if (target == null || target.color != me) out.add(Move.normal(sq, to));
    }
  }

  void _slideMoves(
    int sq,
    int f,
    int r,
    PieceColor me,
    List<List<int>> dirs,
    List<Move> out,
  ) {
    for (final d in dirs) {
      var nf = f + d[0];
      var nr = r + d[1];
      while (Square.valid(nf, nr)) {
        final to = Square.of(nf, nr);
        final target = squares[to];
        if (target == null) {
          out.add(Move.normal(sq, to));
        } else {
          if (target.color != me) out.add(Move.normal(sq, to));
          break;
        }
        nf += d[0];
        nr += d[1];
      }
    }
  }

  void _castlingMoves(int kingSq, PieceColor me, List<Move> out) {
    final rank = me == PieceColor.white ? 0 : 7;
    if (kingSq != Square.of(4, rank)) return;
    if (inCheck(me)) return;
    final kingSide = me == PieceColor.white
        ? Castling.whiteKing
        : Castling.blackKing;
    final queenSide = me == PieceColor.white
        ? Castling.whiteQueen
        : Castling.blackQueen;
    final enemy = me.opposite;
    bool rookAt(int f) {
      final p = squares[Square.of(f, rank)];
      return p != null && p.color == me && p.type == PieceType.rook;
    }

    if (castling & kingSide != 0 && rookAt(7)) {
      final f1 = Square.of(5, rank);
      final g1 = Square.of(6, rank);
      if (squares[f1] == null &&
          squares[g1] == null &&
          !isAttacked(f1, enemy) &&
          !isAttacked(g1, enemy)) {
        out.add(Move.normal(kingSq, g1));
      }
    }
    if (castling & queenSide != 0 && rookAt(0)) {
      final d1 = Square.of(3, rank);
      final c1 = Square.of(2, rank);
      final b1 = Square.of(1, rank);
      if (squares[d1] == null &&
          squares[c1] == null &&
          squares[b1] == null &&
          !isAttacked(d1, enemy) &&
          !isAttacked(c1, enemy)) {
        out.add(Move.normal(kingSq, c1));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Applying moves
  // ---------------------------------------------------------------------------

  bool _isCastle(Move m) {
    if (m.isDrop) return false;
    final p = squares[m.from!];
    return p != null &&
        p.type == PieceType.king &&
        (Square.fileOf(m.from!) - Square.fileOf(m.to)).abs() == 2;
  }

  /// Applies a legal move and returns the new position plus the piece the
  /// partner receives (if any) and the SAN text of the move.
  MoveOutcome play(Move m) {
    if (!isLegal(m)) {
      throw StateError('illegal move ${m.uci}');
    }
    final san = _sanBase(m);
    final captured = _capturedPiece(m);
    final next = _apply(m);
    final check = next.inCheck();
    final mate = check && !next.hasLegalMoves;
    final stalemate = !check && !next.hasLegalMoves;
    return MoveOutcome(
      position: next,
      captured: captured?.asReserve,
      san:
          '$san${mate
              ? '#'
              : check
              ? '+'
              : ''}',
      isCheck: check,
      isCheckmate: mate,
      isStalemate: stalemate,
    );
  }

  Piece? _capturedPiece(Move m) {
    if (m.isDrop) return null;
    final direct = squares[m.to];
    if (direct != null) return direct;
    final mover = squares[m.from!]!;
    if (mover.type == PieceType.pawn && m.to == epSquare) {
      final dir = mover.color == PieceColor.white ? -1 : 1;
      return squares[Square.of(Square.fileOf(m.to), Square.rankOf(m.to) + dir)];
    }
    return null;
  }

  Position _apply(Move m) {
    final sq = List<Piece?>.of(squares);
    var rights = castling;
    int? ep;
    var wr = whiteReserve;
    var br = blackReserve;
    final me = turn;

    if (m.isDrop) {
      sq[m.to] = Piece(me, m.drop!);
      if (me == PieceColor.white) {
        wr = wr.remove(m.drop!);
      } else {
        br = br.remove(m.drop!);
      }
    } else {
      final from = m.from!;
      final mover = sq[from]!;
      final target = sq[m.to];
      // En passant capture removes the pawn behind the target square.
      if (mover.type == PieceType.pawn && target == null && m.to == epSquare) {
        final dir = me == PieceColor.white ? -1 : 1;
        sq[Square.of(Square.fileOf(m.to), Square.rankOf(m.to) + dir)] = null;
      }
      sq[from] = null;
      if (m.promotion != null) {
        sq[m.to] = Piece(me, m.promotion!, promoted: true);
      } else {
        sq[m.to] = mover;
      }
      if (mover.type == PieceType.pawn &&
          (Square.rankOf(from) - Square.rankOf(m.to)).abs() == 2) {
        ep = Square.of(
          Square.fileOf(from),
          (Square.rankOf(from) + Square.rankOf(m.to)) ~/ 2,
        );
      }
      if (_isCastle(m)) {
        final rank = Square.rankOf(from);
        if (Square.fileOf(m.to) == 6) {
          sq[Square.of(5, rank)] = sq[Square.of(7, rank)];
          sq[Square.of(7, rank)] = null;
        } else {
          sq[Square.of(3, rank)] = sq[Square.of(0, rank)];
          sq[Square.of(0, rank)] = null;
        }
      }
      // Update castling rights.
      if (mover.type == PieceType.king) {
        rights &= me == PieceColor.white
            ? ~(Castling.whiteKing | Castling.whiteQueen)
            : ~(Castling.blackKing | Castling.blackQueen);
      }
      rights &= ~_rightForSquare(from);
      rights &= ~_rightForSquare(m.to);
    }

    return Position(
      squares: sq,
      turn: me.opposite,
      castling: rights,
      epSquare: ep,
      whiteReserve: wr,
      blackReserve: br,
      fullmove: me == PieceColor.black ? fullmove + 1 : fullmove,
    );
  }

  static int _rightForSquare(int sq) => switch (sq) {
    7 => Castling.whiteKing,
    0 => Castling.whiteQueen,
    63 => Castling.blackKing,
    56 => Castling.blackQueen,
    _ => 0,
  };

  // ---------------------------------------------------------------------------
  // Notation
  // ---------------------------------------------------------------------------

  /// SAN without the check/mate suffix (which depends on the resulting position).
  String _sanBase(Move m) {
    if (m.isDrop) return '${m.drop!.letter}@${Square.name(m.to)}';
    final from = m.from!;
    final mover = squares[from]!;
    if (_isCastle(m)) return Square.fileOf(m.to) == 6 ? 'O-O' : 'O-O-O';
    final capture = _capturedPiece(m) != null;
    final dest = Square.name(m.to);
    if (mover.type == PieceType.pawn) {
      final promo = m.promotion == null ? '' : '=${m.promotion!.letter}';
      if (capture) return '${Square.files[Square.fileOf(from)]}x$dest$promo';
      return '$dest$promo';
    }
    // Disambiguate among other legal moves of the same piece type to `to`.
    final others = legalMoves().where(
      (o) =>
          !o.isDrop &&
          o.to == m.to &&
          o.from != from &&
          squares[o.from!]!.type == mover.type &&
          squares[o.from!]!.color == mover.color,
    );
    var dis = '';
    if (others.isNotEmpty) {
      final sameFile = others.any(
        (o) => Square.fileOf(o.from!) == Square.fileOf(from),
      );
      final sameRank = others.any(
        (o) => Square.rankOf(o.from!) == Square.rankOf(from),
      );
      if (!sameFile) {
        dis = Square.files[Square.fileOf(from)];
      } else if (!sameRank) {
        dis = '${Square.rankOf(from) + 1}';
      } else {
        dis = Square.name(from);
      }
    }
    return '${mover.type.letter}$dis${capture ? 'x' : ''}$dest';
  }

  /// Finds the legal move matching [san] (check suffixes are ignored).
  Move? moveFromSan(String san) {
    final clean = san.replaceAll(RegExp(r'[+#!?]'), '');
    for (final m in legalMoves()) {
      if (_sanBase(m) == clean) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // FEN
  // ---------------------------------------------------------------------------

  /// Crazyhouse-style FEN with the reserves in brackets after the board,
  /// e.g. `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[Pn] w KQkq - 0 1`.
  /// The halfmove clock is always 0: bughouse has no fifty-move rule.
  String get fen {
    final rows = <String>[];
    for (var r = 7; r >= 0; r--) {
      var row = '';
      var empty = 0;
      for (var f = 0; f < 8; f++) {
        final p = squares[Square.of(f, r)];
        if (p == null) {
          empty++;
        } else {
          if (empty > 0) row += '$empty';
          empty = 0;
          row += p.fen;
        }
      }
      if (empty > 0) row += '$empty';
      rows.add(row);
    }
    final pocket =
        '${whiteReserve.fen(PieceColor.white)}${blackReserve.fen(PieceColor.black)}';
    var rights = '';
    if (castling & Castling.whiteKing != 0) rights += 'K';
    if (castling & Castling.whiteQueen != 0) rights += 'Q';
    if (castling & Castling.blackKing != 0) rights += 'k';
    if (castling & Castling.blackQueen != 0) rights += 'q';
    if (rights.isEmpty) rights = '-';
    final ep = epSquare == null ? '-' : Square.name(epSquare!);
    return '${rows.join('/')}[$pocket] ${turn.letter} $rights $ep 0 $fullmove';
  }

  /// Position identity used for threefold repetition (FICS / chess.com style:
  /// board, side to move, castling and en passant, ignoring the reserves).
  String get repetitionKey =>
      fen.replaceFirst(RegExp(r'\[[^\]]*\]'), '').split(' ').take(4).join(' ');

  static Position fromFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    final boardAndPocket = parts[0];
    final bracket = boardAndPocket.indexOf('[');
    final board = bracket < 0
        ? boardAndPocket
        : boardAndPocket.substring(0, bracket);
    final pocket = bracket < 0
        ? ''
        : boardAndPocket.substring(bracket + 1, boardAndPocket.indexOf(']'));
    final squares = List<Piece?>.filled(64, null);
    final rows = board.split('/');
    for (var i = 0; i < 8; i++) {
      final rank = 7 - i;
      var file = 0;
      final row = rows[i];
      for (var j = 0; j < row.length; j++) {
        final ch = row[j];
        if (ch == '~') {
          final prev = squares[Square.of(file - 1, rank)]!;
          squares[Square.of(file - 1, rank)] = Piece(
            prev.color,
            prev.type,
            promoted: true,
          );
          continue;
        }
        final digit = int.tryParse(ch);
        if (digit != null) {
          file += digit;
          continue;
        }
        final color = ch == ch.toUpperCase()
            ? PieceColor.white
            : PieceColor.black;
        squares[Square.of(file, rank)] = Piece(color, PieceType.fromLetter(ch));
        file++;
      }
    }
    var wr = Reserve();
    var br = Reserve();
    for (var i = 0; i < pocket.length; i++) {
      final ch = pocket[i];
      final t = PieceType.fromLetter(ch);
      if (ch == ch.toUpperCase()) {
        wr = wr.add(t);
      } else {
        br = br.add(t);
      }
    }
    var rights = 0;
    final r = parts.length > 2 ? parts[2] : '-';
    if (r.contains('K')) rights |= Castling.whiteKing;
    if (r.contains('Q')) rights |= Castling.whiteQueen;
    if (r.contains('k')) rights |= Castling.blackKing;
    if (r.contains('q')) rights |= Castling.blackQueen;
    final epText = parts.length > 3 ? parts[3] : '-';
    return Position(
      squares: squares,
      turn: parts.length > 1
          ? PieceColor.fromLetter(parts[1])
          : PieceColor.white,
      castling: rights,
      epSquare: epText == '-' ? null : Square.parse(epText),
      whiteReserve: wr,
      blackReserve: br,
      fullmove: parts.length > 5 ? int.parse(parts[5]) : 1,
    );
  }

  @override
  String toString() => fen;

  @override
  bool operator ==(Object other) => other is Position && other.fen == fen;

  @override
  int get hashCode => fen.hashCode;
}
