import 'dart:math';

import 'move.dart';
import 'piece.dart';
import 'position.dart';
import 'square.dart';

/// Bot strength presets. Depth is in plies; `noise` adds a bounded,
/// seed-deterministic evaluation jitter so weaker levels play less
/// mechanically.
enum EngineLevel {
  novice(1, 1, 120),
  club(2, 2, 40),
  expert(3, 3, 10),
  master(4, 4, 0);

  const EngineLevel(this.id, this.depth, this.noise);

  final int id;
  final int depth;
  final int noise;

  String get label => switch (this) {
        EngineLevel.novice => 'Novice',
        EngineLevel.club => 'Club',
        EngineLevel.expert => 'Expert',
        EngineLevel.master => 'Master',
      };

  static EngineLevel fromId(int id) =>
      values.firstWhere((l) => l.id == id, orElse: () => EngineLevel.club);
}

class EngineResult {
  const EngineResult(this.move, this.score, this.nodes);

  final Move? move;

  /// Centipawns from the side to move's perspective.
  final int score;
  final int nodes;
}

/// Deterministic alpha-beta (negamax) search with quiescence, MVV-LVA
/// ordering, piece-square tables, and a repetition-free evaluation.
class Engine {
  Engine({required this.level, int seed = 0}) : _random = Random(seed);

  final EngineLevel level;
  final Random _random;
  int _nodes = 0;

  static const int _mate = 100000;

  EngineResult bestMove(Position position) {
    _nodes = 0;
    final moves = _ordered(position, position.legalMoves());
    if (moves.isEmpty) return const EngineResult(null, 0, 0);
    Move? best;
    var bestScore = -_mate * 2;
    const window = _mate * 2;
    // Root moves are searched with a full window so every score is exact and
    // the seeded noise compares like against like.
    for (final move in moves) {
      final next = position.apply(move);
      var score = -_search(next, level.depth - 1, -window, window, 1);
      if (level.noise > 0 && score.abs() < _mate ~/ 2) {
        score += _random.nextInt(level.noise * 2 + 1) - level.noise;
      }
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return EngineResult(best, bestScore, _nodes);
  }

  int _search(
      Position position, int depth, int alpha, int beta, int plyFromRoot) {
    _nodes++;
    final moves = position.legalMoves();
    if (moves.isEmpty) {
      if (position.isInCheck) return -_mate + plyFromRoot;
      return 0;
    }
    if (position.isInsufficientMaterial || position.halfmoveClock >= 100) {
      return 0;
    }
    if (depth <= 0) return _quiescence(position, alpha, beta, plyFromRoot);
    var a = alpha;
    for (final move in _ordered(position, moves)) {
      final score =
          -_search(position.apply(move), depth - 1, -beta, -a, plyFromRoot + 1);
      if (score >= beta) return beta;
      if (score > a) a = score;
    }
    return a;
  }

  int _quiescence(Position position, int alpha, int beta, int plyFromRoot) {
    _nodes++;
    final stand = evaluate(position);
    if (stand >= beta) return beta;
    var a = max(alpha, stand);
    if (plyFromRoot > 12) return a;
    final captures = position.legalMoves().where(position.isCapture).toList();
    for (final move in _ordered(position, captures)) {
      final score =
          -_quiescence(position.apply(move), -beta, -a, plyFromRoot + 1);
      if (score >= beta) return beta;
      if (score > a) a = score;
    }
    return a;
  }

  List<Move> _ordered(Position position, List<Move> moves) {
    final scored = moves.map((move) {
      var score = 0;
      final victim = position.capturedPiece(move);
      if (victim != null) {
        score += 10 * victim.type.value -
            position.pieceAt(move.from)!.type.value ~/ 10;
      }
      if (move.promotion != null) score += move.promotion!.value;
      return (move, score);
    }).toList();
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      return a.$1.uci.compareTo(b.$1.uci);
    });
    return scored.map((e) => e.$1).toList();
  }

  /// Static evaluation from the side to move's perspective.
  static int evaluate(Position position) {
    var score = 0;
    var whiteMaterial = 0;
    var blackMaterial = 0;
    for (var square = 0; square < 64; square++) {
      final piece = position.pieceAt(square);
      if (piece == null) continue;
      final pst = _tables[piece.type]!;
      final index = piece.isWhite ? square : _mirror(square);
      final value = piece.type.value + pst[index];
      if (piece.isWhite) {
        score += value;
        whiteMaterial += piece.type.value;
      } else {
        score -= value;
        blackMaterial += piece.type.value;
      }
    }
    // Endgame king centralisation when queens are gone.
    if (whiteMaterial + blackMaterial < 2600) {
      score += _kingEndgame[position.kingSquare(PieceColor.white)];
      score -= _kingEndgame[_mirror(position.kingSquare(PieceColor.black))];
    }
    return position.turn == PieceColor.white ? score : -score;
  }

  /// Tables are stored a1-first from White's perspective; Black mirrors ranks.
  static int _mirror(int square) =>
      Square.of(Square.fileOf(square), 7 - Square.rankOf(square));

  static final Map<PieceType, List<int>> _tables = {
    PieceType.pawn: _flip([
      0, 0, 0, 0, 0, 0, 0, 0, //
      50, 50, 50, 50, 50, 50, 50, 50,
      10, 10, 20, 30, 30, 20, 10, 10,
      5, 5, 10, 25, 25, 10, 5, 5,
      0, 0, 0, 20, 20, 0, 0, 0,
      5, -5, -10, 0, 0, -10, -5, 5,
      5, 10, 10, -20, -20, 10, 10, 5,
      0, 0, 0, 0, 0, 0, 0, 0,
    ]),
    PieceType.knight: _flip([
      -50, -40, -30, -30, -30, -30, -40, -50, //
      -40, -20, 0, 0, 0, 0, -20, -40,
      -30, 0, 10, 15, 15, 10, 0, -30,
      -30, 5, 15, 20, 20, 15, 5, -30,
      -30, 0, 15, 20, 20, 15, 0, -30,
      -30, 5, 10, 15, 15, 10, 5, -30,
      -40, -20, 0, 5, 5, 0, -20, -40,
      -50, -40, -30, -30, -30, -30, -40, -50,
    ]),
    PieceType.bishop: _flip([
      -20, -10, -10, -10, -10, -10, -10, -20, //
      -10, 0, 0, 0, 0, 0, 0, -10,
      -10, 0, 5, 10, 10, 5, 0, -10,
      -10, 5, 5, 10, 10, 5, 5, -10,
      -10, 0, 10, 10, 10, 10, 0, -10,
      -10, 10, 10, 10, 10, 10, 10, -10,
      -10, 5, 0, 0, 0, 0, 5, -10,
      -20, -10, -10, -10, -10, -10, -10, -20,
    ]),
    PieceType.rook: _flip([
      0, 0, 0, 0, 0, 0, 0, 0, //
      5, 10, 10, 10, 10, 10, 10, 5,
      -5, 0, 0, 0, 0, 0, 0, -5,
      -5, 0, 0, 0, 0, 0, 0, -5,
      -5, 0, 0, 0, 0, 0, 0, -5,
      -5, 0, 0, 0, 0, 0, 0, -5,
      -5, 0, 0, 0, 0, 0, 0, -5,
      0, 0, 0, 5, 5, 0, 0, 0,
    ]),
    PieceType.queen: _flip([
      -20, -10, -10, -5, -5, -10, -10, -20, //
      -10, 0, 0, 0, 0, 0, 0, -10,
      -10, 0, 5, 5, 5, 5, 0, -10,
      -5, 0, 5, 5, 5, 5, 0, -5,
      0, 0, 5, 5, 5, 5, 0, -5,
      -10, 5, 5, 5, 5, 5, 0, -10,
      -10, 0, 5, 0, 0, 0, 0, -10,
      -20, -10, -10, -5, -5, -10, -10, -20,
    ]),
    PieceType.king: _flip([
      -30, -40, -40, -50, -50, -40, -40, -30, //
      -30, -40, -40, -50, -50, -40, -40, -30,
      -30, -40, -40, -50, -50, -40, -40, -30,
      -30, -40, -40, -50, -50, -40, -40, -30,
      -20, -30, -30, -40, -40, -30, -30, -20,
      -10, -20, -20, -20, -20, -20, -20, -10,
      20, 20, 0, 0, 0, 0, 20, 20,
      20, 30, 10, 0, 0, 10, 30, 20,
    ]),
  };

  static final List<int> _kingEndgame = _flip([
    -50, -40, -30, -20, -20, -30, -40, -50, //
    -30, -20, -10, 0, 0, -10, -20, -30,
    -30, -10, 20, 30, 30, 20, -10, -30,
    -30, -10, 30, 40, 40, 30, -10, -30,
    -30, -10, 30, 40, 40, 30, -10, -30,
    -30, -10, 20, 30, 30, 20, -10, -30,
    -30, -30, 0, 0, 0, 0, -30, -30,
    -50, -30, -30, -30, -30, -30, -30, -50,
  ]);

  /// Source tables list rank 8 first (as a diagram); convert to a1-first.
  static List<int> _flip(List<int> visual) {
    final out = List<int>.filled(64, 0);
    for (var square = 0; square < 64; square++) {
      final visualIndex =
          (7 - Square.rankOf(square)) * 8 + Square.fileOf(square);
      out[square] = visual[visualIndex];
    }
    return out;
  }
}
