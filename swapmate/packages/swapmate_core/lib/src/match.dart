import 'dart:math';

import 'move.dart';
import 'piece.dart';
import 'position.dart';

/// The two boards of a bughouse match.
enum BoardId {
  a('a'),
  b('b');

  const BoardId(this.id);
  final String id;

  BoardId get other => this == a ? b : a;

  static BoardId parse(String id) => id == 'a' ? a : b;

  /// Upper-case BPGN move-number tag for white, lower-case for black.
  String tag(PieceColor color) =>
      color == PieceColor.white ? id.toUpperCase() : id;
}

/// One of the four chairs at the table.
enum Seat {
  aWhite(BoardId.a, PieceColor.white, 'aw', 'Board A · White'),
  aBlack(BoardId.a, PieceColor.black, 'ab', 'Board A · Black'),
  bWhite(BoardId.b, PieceColor.white, 'bw', 'Board B · White'),
  bBlack(BoardId.b, PieceColor.black, 'bb', 'Board B · Black');

  const Seat(this.board, this.color, this.id, this.label);

  final BoardId board;
  final PieceColor color;
  final String id;
  final String label;

  /// Team 1 = A-White + B-Black, Team 2 = A-Black + B-White.
  Team get team => this == aWhite || this == bBlack ? Team.one : Team.two;

  Seat get partner => switch (this) {
    aWhite => bBlack,
    bBlack => aWhite,
    aBlack => bWhite,
    bWhite => aBlack,
  };

  Seat get opponent => switch (this) {
    aWhite => aBlack,
    aBlack => aWhite,
    bWhite => bBlack,
    bBlack => bWhite,
  };

  static Seat parse(String id) => Seat.values.firstWhere((s) => s.id == id);

  static Seat at(BoardId board, PieceColor color) =>
      Seat.values.firstWhere((s) => s.board == board && s.color == color);
}

enum Team {
  one('1'),
  two('2');

  const Team(this.id);
  final String id;

  Team get other => this == one ? two : one;

  static Team parse(String id) => id == '1' ? one : two;

  /// Result token from Team 1's perspective, like PGN `1-0`.
  String get pgnResult => this == one ? '1-0' : '0-1';
}

class TimeControl {
  const TimeControl({required this.initialMs, required this.incrementMs});

  final int initialMs;
  final int incrementMs;

  static const blitz3 = TimeControl(initialMs: 180000, incrementMs: 0);

  /// PGN `TimeControl` tag, seconds `+` increment seconds.
  String get pgn => '${initialMs ~/ 1000}+${incrementMs ~/ 1000}';

  String get label {
    final m = initialMs ~/ 60000;
    final s = (initialMs % 60000) ~/ 1000;
    final base = s == 0 ? '$m' : '$m:${s.toString().padLeft(2, '0')}';
    return '$base+${incrementMs ~/ 1000}';
  }

  Map<String, dynamic> toJson() => {
    'initialMs': initialMs,
    'incrementMs': incrementMs,
  };

  static TimeControl fromJson(Map<String, dynamic> json) => TimeControl(
    initialMs: json['initialMs'] as int,
    incrementMs: json['incrementMs'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is TimeControl &&
      other.initialMs == initialMs &&
      other.incrementMs == incrementMs;

  @override
  int get hashCode => Object.hash(initialMs, incrementMs);
}

enum ResultReason {
  checkmate,
  timeout,
  resignation,
  stalemate,
  repetition,
  agreement,
  abandonment;

  static ResultReason parse(String s) =>
      ResultReason.values.firstWhere((r) => r.name == s);
}

class MatchResult {
  const MatchResult({
    required this.winner,
    required this.reason,
    required this.board,
    this.loser,
  });

  /// Null for a draw.
  final Team? winner;
  final ResultReason reason;

  /// Board on which the match was decided (null for agreement/abandonment).
  final BoardId? board;

  /// Seat that lost on that board (null for draws).
  final Seat? loser;

  bool get isDraw => winner == null;

  String get pgn => winner?.pgnResult ?? '1/2-1/2';

  Map<String, dynamic> toJson() => {
    'winner': winner?.id,
    'reason': reason.name,
    'board': board?.id,
    'loser': loser?.id,
  };

  static MatchResult fromJson(Map<String, dynamic> json) => MatchResult(
    winner: json['winner'] == null
        ? null
        : Team.parse(json['winner'] as String),
    reason: ResultReason.parse(json['reason'] as String),
    board: json['board'] == null
        ? null
        : BoardId.parse(json['board'] as String),
    loser: json['loser'] == null ? null : Seat.parse(json['loser'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is MatchResult &&
      other.winner == winner &&
      other.reason == reason &&
      other.board == board &&
      other.loser == loser;

  @override
  int get hashCode => Object.hash(winner, reason, board, loser);
}

/// A move as recorded in the match history.
class MatchMove {
  const MatchMove({
    required this.seq,
    required this.board,
    required this.color,
    required this.number,
    required this.move,
    required this.san,
    required this.clockMs,
    this.captured,
  });

  /// Zero-based global sequence across both boards.
  final int seq;
  final BoardId board;
  final PieceColor color;

  /// Board-local move number (1 for both white's and black's first move).
  final int number;
  final Move move;
  final String san;

  /// Mover's remaining time after the move, for BPGN `{180}` comments.
  final int clockMs;

  /// Piece type passed to the partner, if the move captured.
  final PieceType? captured;

  Seat get seat => Seat.at(board, color);

  /// BPGN token such as `3A. e4` or `3a. Nc6`.
  String get bpgn => '$number${board.tag(color)}. $san';

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'board': board.id,
    'color': color.letter,
    'number': number,
    'move': move.toJson(),
    'san': san,
    'clockMs': clockMs,
    if (captured != null) 'captured': captured!.letter,
  };

  static MatchMove fromJson(Map<String, dynamic> json) => MatchMove(
    seq: json['seq'] as int,
    board: BoardId.parse(json['board'] as String),
    color: PieceColor.fromLetter(json['color'] as String),
    number: json['number'] as int,
    move: Move.fromJson(json['move'] as Map<String, dynamic>),
    san: json['san'] as String,
    clockMs: json['clockMs'] as int,
    captured: json['captured'] == null
        ? null
        : PieceType.fromLetter(json['captured'] as String),
  );
}

/// Clock state for one board. Time is expressed in milliseconds of a
/// caller-supplied monotonic clock so the model stays deterministic.
class BoardClock {
  BoardClock({
    required this.whiteMs,
    required this.blackMs,
    this.running,
    this.lastTickAt,
  });

  int whiteMs;
  int blackMs;

  /// Which color's clock is counting down, or null when stopped.
  PieceColor? running;
  int? lastTickAt;

  int remaining(PieceColor c, int now) {
    final base = c == PieceColor.white ? whiteMs : blackMs;
    if (running != c || lastTickAt == null) return base;
    return base - (now - lastTickAt!);
  }

  void _set(PieceColor c, int ms) {
    if (c == PieceColor.white) {
      whiteMs = ms;
    } else {
      blackMs = ms;
    }
  }

  /// Folds elapsed time into the running side. Returns the running side's
  /// remaining time (may be negative when it has flagged).
  int settle(int now) {
    final r = running;
    if (r == null || lastTickAt == null) return 0;
    _set(r, remaining(r, now));
    lastTickAt = now;
    return r == PieceColor.white ? whiteMs : blackMs;
  }

  void start(PieceColor c, int now) {
    running = c;
    lastTickAt = now;
  }

  void stop(int now) {
    settle(now);
    running = null;
    lastTickAt = null;
  }

  /// Called when [mover] completes a move: settles, adds increment and hands
  /// the clock to the other side.
  void press(PieceColor mover, int incrementMs, int now) {
    settle(now);
    _set(mover, (mover == PieceColor.white ? whiteMs : blackMs) + incrementMs);
    start(mover.opposite, now);
  }

  Map<String, dynamic> toJson(int now) => {
    'w': remaining(PieceColor.white, now),
    'b': remaining(PieceColor.black, now),
    'running': running?.letter,
  };
}

/// Snapshot of one board for the wire protocol and clients.
class BoardSnapshot {
  const BoardSnapshot({
    required this.id,
    required this.fen,
    required this.whiteMs,
    required this.blackMs,
    required this.running,
    required this.lastMove,
    required this.inCheck,
  });

  final BoardId id;
  final String fen;
  final int whiteMs;
  final int blackMs;
  final PieceColor? running;
  final Move? lastMove;
  final bool inCheck;

  Position get position => Position.fromFen(fen);

  Map<String, dynamic> toJson() => {
    'id': id.id,
    'fen': fen,
    'clock': {'w': whiteMs, 'b': blackMs, 'running': running?.letter},
    'lastMove': lastMove?.toJson(),
    'inCheck': inCheck,
  };

  static BoardSnapshot fromJson(Map<String, dynamic> json) {
    final clock = json['clock'] as Map<String, dynamic>;
    return BoardSnapshot(
      id: BoardId.parse(json['id'] as String),
      fen: json['fen'] as String,
      whiteMs: clock['w'] as int,
      blackMs: clock['b'] as int,
      running: clock['running'] == null
          ? null
          : PieceColor.fromLetter(clock['running'] as String),
      lastMove: json['lastMove'] == null
          ? null
          : Move.fromJson(json['lastMove'] as Map<String, dynamic>),
      inCheck: json['inCheck'] as bool,
    );
  }
}

/// Authoritative bughouse match: two boards, four clocks, shared history.
///
/// Time is injected as an integer millisecond timestamp so the server can use
/// wall-clock time while tests use a fixed virtual clock.
class BughouseMatch {
  BughouseMatch({required this.timeControl, this.startedAt}) {
    for (final b in BoardId.values) {
      _positions[b] = Position.initial();
      _clocks[b] = BoardClock(
        whiteMs: timeControl.initialMs,
        blackMs: timeControl.initialMs,
      );
      _repetitions[b] = {_positions[b]!.repetitionKey: 1};
      _lastMove[b] = null;
    }
  }

  final TimeControl timeControl;
  int? startedAt;

  final Map<BoardId, Position> _positions = {};
  final Map<BoardId, BoardClock> _clocks = {};
  final Map<BoardId, Map<String, int>> _repetitions = {};
  final Map<BoardId, Move?> _lastMove = {};
  final List<MatchMove> history = [];
  MatchResult? result;

  Position position(BoardId b) => _positions[b]!;
  BoardClock clock(BoardId b) => _clocks[b]!;
  Move? lastMove(BoardId b) => _lastMove[b];

  bool get isOver => result != null;
  bool get hasStarted => startedAt != null;

  /// Starts both clocks (white to move on each board) at [now].
  void start(int now) {
    startedAt = now;
    for (final b in BoardId.values) {
      _clocks[b]!.start(PieceColor.white, now);
    }
  }

  Seat seatToMove(BoardId b) => Seat.at(b, position(b).turn);

  bool isTurn(Seat seat) =>
      !isOver && hasStarted && position(seat.board).turn == seat.color;

  List<Move> legalMoves(Seat seat) =>
      isTurn(seat) ? position(seat.board).legalMoves() : const [];

  /// Applies [move] for [seat]. Throws [StateError] when it is not that
  /// seat's turn or the move is illegal. Returns the recorded history entry.
  MatchMove play(Seat seat, Move move, int now) {
    if (isOver) throw StateError('match is over');
    if (!hasStarted) throw StateError('match has not started');
    if (!isTurn(seat)) throw StateError('not your turn');
    final board = seat.board;
    final pos = position(board);
    // Flag check before accepting the move.
    final remaining = _clocks[board]!.settle(now);
    if (remaining <= 0) {
      _finishOnTime(seat, now);
      throw StateError('flag fell');
    }
    final outcome = pos.play(move);
    _positions[board] = outcome.position;
    _lastMove[board] = move;
    _clocks[board]!.press(seat.color, timeControl.incrementMs, now);
    if (outcome.captured != null) {
      final partner = seat.partner;
      _positions[partner.board] = position(partner.board)
          .addToReserve(partner.color, outcome.captured!.type);
    }
    final entry = MatchMove(
      seq: history.length,
      board: board,
      color: seat.color,
      number: pos.fullmove,
      move: move,
      san: outcome.san,
      clockMs: _clocks[board]!.remaining(seat.color, now),
      captured: outcome.captured?.type,
    );
    history.add(entry);

    if (outcome.isCheckmate) {
      _finish(
        MatchResult(
          winner: seat.team,
          reason: ResultReason.checkmate,
          board: board,
          loser: seat.opponent,
        ),
        now,
      );
    } else if (outcome.isStalemate) {
      _finish(
        MatchResult(winner: null, reason: ResultReason.stalemate, board: board),
        now,
      );
    } else {
      final key = outcome.position.repetitionKey;
      final reps = _repetitions[board]!;
      reps[key] = (reps[key] ?? 0) + 1;
      if (reps[key]! >= 3) {
        _finish(
          MatchResult(
            winner: null,
            reason: ResultReason.repetition,
            board: board,
          ),
          now,
        );
      }
    }
    return entry;
  }

  /// Checks both boards for a fallen flag. Returns true if the match ended.
  bool checkFlags(int now) {
    if (isOver || !hasStarted) return false;
    for (final b in BoardId.values) {
      final c = _clocks[b]!;
      final r = c.running;
      if (r != null && c.remaining(r, now) <= 0) {
        _finishOnTime(Seat.at(b, r), now);
        return true;
      }
    }
    return false;
  }

  void _finishOnTime(Seat flagged, int now) {
    final c = _clocks[flagged.board]!;
    c.settle(now);
    if (flagged.color == PieceColor.white) {
      c.whiteMs = 0;
    } else {
      c.blackMs = 0;
    }
    _finish(
      MatchResult(
        winner: flagged.team.other,
        reason: ResultReason.timeout,
        board: flagged.board,
        loser: flagged,
      ),
      now,
    );
  }

  void resign(Seat seat, int now) {
    if (isOver) return;
    _finish(
      MatchResult(
        winner: seat.team.other,
        reason: ResultReason.resignation,
        board: seat.board,
        loser: seat,
      ),
      now,
    );
  }

  void agreeDraw(int now) {
    if (isOver) return;
    _finish(
      const MatchResult(
        winner: null,
        reason: ResultReason.agreement,
        board: null,
      ),
      now,
    );
  }

  void abandon(Seat seat, int now) {
    if (isOver) return;
    _finish(
      MatchResult(
        winner: seat.team.other,
        reason: ResultReason.abandonment,
        board: seat.board,
        loser: seat,
      ),
      now,
    );
  }

  void _finish(MatchResult r, int now) {
    result = r;
    for (final b in BoardId.values) {
      _clocks[b]!.stop(now);
    }
  }

  BoardSnapshot snapshot(BoardId b, int now) {
    final pos = position(b);
    final c = clock(b);
    return BoardSnapshot(
      id: b,
      fen: pos.fen,
      whiteMs: max(0, c.remaining(PieceColor.white, now)),
      blackMs: max(0, c.remaining(PieceColor.black, now)),
      running: c.running,
      lastMove: lastMove(b),
      inCheck: pos.inCheck(),
    );
  }
}
