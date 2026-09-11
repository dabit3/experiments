import 'move.dart';
import 'piece.dart';
import 'position.dart';
import 'san.dart';

enum GameOutcome { whiteWins, blackWins, draw }

enum GameEndReason {
  checkmate,
  stalemate,
  resignation,
  timeout,
  agreement,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial,
  abandonment,
}

class GameResult {
  const GameResult(this.outcome, this.reason);

  final GameOutcome outcome;
  final GameEndReason reason;

  PieceColor? get winner => switch (outcome) {
        GameOutcome.whiteWins => PieceColor.white,
        GameOutcome.blackWins => PieceColor.black,
        GameOutcome.draw => null,
      };

  /// PGN result token.
  String get score => switch (outcome) {
        GameOutcome.whiteWins => '1-0',
        GameOutcome.blackWins => '0-1',
        GameOutcome.draw => '½-½',
      };

  String get reasonLabel => switch (reason) {
        GameEndReason.checkmate => 'by checkmate',
        GameEndReason.stalemate => 'by stalemate',
        GameEndReason.resignation => 'by resignation',
        GameEndReason.timeout => 'on time',
        GameEndReason.agreement => 'by agreement',
        GameEndReason.threefoldRepetition => 'by threefold repetition',
        GameEndReason.fiftyMoveRule => 'by the fifty-move rule',
        GameEndReason.insufficientMaterial => 'by insufficient material',
        GameEndReason.abandonment => 'by abandonment',
      };

  String get headline => switch (outcome) {
        GameOutcome.whiteWins => 'White wins',
        GameOutcome.blackWins => 'Black wins',
        GameOutcome.draw => 'Draw',
      };

  Map<String, Object?> toJson() => {
        'outcome': outcome.name,
        'reason': reason.name,
      };

  static GameResult? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    final outcome =
        GameOutcome.values.where((o) => o.name == json['outcome']).firstOrNull;
    final reason =
        GameEndReason.values.where((r) => r.name == json['reason']).firstOrNull;
    if (outcome == null || reason == null) return null;
    return GameResult(outcome, reason);
  }

  @override
  bool operator ==(Object other) =>
      other is GameResult && other.outcome == outcome && other.reason == reason;

  @override
  int get hashCode => Object.hash(outcome, reason);
}

/// One played move with its notation, kept for move lists and PGN.
class PlayedMove {
  const PlayedMove(this.move, this.san, this.fenAfter);

  final Move move;
  final String san;
  final String fenAfter;

  Map<String, Object?> toJson() =>
      {'uci': move.uci, 'san': san, 'fen': fenAfter};

  static PlayedMove fromJson(Map<String, Object?> json) => PlayedMove(
        Move.parseUci(json['uci'] as String)!,
        json['san'] as String,
        json['fen'] as String,
      );
}

/// A full game: start position, move history, and automatic result
/// detection. Threefold repetition and the fifty-move rule end the game
/// automatically (the common online convention), as does insufficient
/// material.
class Game {
  Game({Position? start}) : start = start ?? Position.initial {
    _positions.add(this.start);
    _repetitions[this.start.repetitionKey] = 1;
    _refreshResult();
  }

  final Position start;
  final List<Position> _positions = [];
  final List<PlayedMove> _moves = [];
  final Map<String, int> _repetitions = {};
  GameResult? _result;

  Position get position => _positions.last;

  List<Position> get positions => List.unmodifiable(_positions);

  List<PlayedMove> get moves => List.unmodifiable(_moves);

  GameResult? get result => _result;

  bool get isOver => _result != null;

  PieceColor get turn => position.turn;

  int get ply => _moves.length;

  /// Plays a legal move. Returns the [PlayedMove] or null when illegal or the
  /// game is already finished.
  PlayedMove? play(Move move) {
    if (isOver) return null;
    if (!position.isLegal(move)) return null;
    final san = San.render(position, move);
    final next = position.apply(move);
    final played = PlayedMove(move, san, next.fen);
    _moves.add(played);
    _positions.add(next);
    final key = next.repetitionKey;
    _repetitions[key] = (_repetitions[key] ?? 0) + 1;
    _refreshResult();
    return played;
  }

  PlayedMove? playUci(String uci) {
    final parsed = Move.parseUci(uci);
    if (parsed == null) return null;
    final resolved = position.resolve(parsed.from, parsed.to,
        promotion: parsed.promotion ?? PieceType.queen);
    if (resolved == null) return null;
    // A promotion given without a piece letter is rejected: clients must
    // choose explicitly so that the picker is honoured.
    if (resolved.promotion != null && parsed.promotion == null) return null;
    return play(resolved);
  }

  PlayedMove? playSan(String san) {
    final move = San.parse(position, san);
    if (move == null) return null;
    return play(move);
  }

  /// Removes the last [count] plies (takeback). Clears any result derived
  /// from the board; explicit results (resignation etc.) are also cleared
  /// because the game continues.
  bool takeBack([int count = 1]) {
    if (count <= 0 || count > _moves.length) return false;
    for (var i = 0; i < count; i++) {
      final removed = _positions.removeLast();
      _moves.removeLast();
      final key = removed.repetitionKey;
      final n = (_repetitions[key] ?? 1) - 1;
      if (n <= 0) {
        _repetitions.remove(key);
      } else {
        _repetitions[key] = n;
      }
    }
    _result = null;
    _refreshResult();
    return true;
  }

  /// Ends the game with an explicit result (resign, timeout, agreement).
  void end(GameResult result) {
    _result ??= result;
  }

  void _refreshResult() {
    final pos = position;
    if (pos.isCheckmate) {
      _result = GameResult(
        pos.turn == PieceColor.white
            ? GameOutcome.blackWins
            : GameOutcome.whiteWins,
        GameEndReason.checkmate,
      );
    } else if (pos.isStalemate) {
      _result = const GameResult(GameOutcome.draw, GameEndReason.stalemate);
    } else if (pos.isInsufficientMaterial) {
      _result = const GameResult(
          GameOutcome.draw, GameEndReason.insufficientMaterial);
    } else if ((_repetitions[pos.repetitionKey] ?? 0) >= 3) {
      _result =
          const GameResult(GameOutcome.draw, GameEndReason.threefoldRepetition);
    } else if (pos.halfmoveClock >= 100) {
      _result = const GameResult(GameOutcome.draw, GameEndReason.fiftyMoveRule);
    }
  }

  /// Count of occurrences of the current position (for UI hints).
  int get currentRepetitions => _repetitions[position.repetitionKey] ?? 0;

  Map<PieceColor, List<PieceType>> get captured =>
      position.capturedSince(start);

  Move? get lastMove => _moves.isEmpty ? null : _moves.last.move;
}
