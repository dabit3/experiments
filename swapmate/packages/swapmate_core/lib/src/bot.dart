import 'dart:math';

import 'move.dart';
import 'piece.dart';
import 'position.dart';
import 'square.dart';

/// A small deterministic bughouse bot.
///
/// Given the same seed and the same positions it always picks the same moves,
/// which keeps automated matches reproducible. It plays checkmates when
/// available, otherwise scores each legal move with a light heuristic
/// (material, checks, drop safety, development) and picks uniformly among the
/// best-scoring candidates using its seeded RNG.
class Bot {
  Bot({required int seed, this.name = 'Bot'}) : _rng = Random(seed);

  final Random _rng;
  final String name;

  /// Board layouts this bot has already produced, used to steer away from
  /// repetition (which would otherwise draw the whole match).
  final _seen = <String, int>{};

  static const _value = {
    PieceType.pawn: 1,
    PieceType.knight: 3,
    PieceType.bishop: 3,
    PieceType.rook: 5,
    PieceType.queen: 9,
    PieceType.king: 100,
  };

  Move? choose(Position pos) {
    final moves = pos.legalMoves();
    if (moves.isEmpty) return null;
    final me = pos.turn;
    var best = <Move>[];
    var bestScore = double.negativeInfinity;
    for (final m in moves) {
      final outcome = _preview(pos, m);
      if (outcome.isCheckmate) return m;
      var score = 0.0;
      if (outcome.captured != null) {
        score += 10.0 * _value[outcome.captured!.type]!;
      }
      if (outcome.isCheck) score += 2.5;
      if (m.promotion != null) score += 8;
      final next = outcome.position;
      final seen = _seen[_layout(next)] ?? 0;
      if (seen > 0) score -= 4.0 * seen;
      // Penalise leaving the moved/dropped piece en prise.
      final landed = next.at(m.to);
      if (landed != null && next.isAttacked(m.to, me.opposite)) {
        final defended = next.isAttacked(m.to, me);
        score -= _value[landed.type]! * (defended ? 0.5 : 1.5);
      }
      if (m.isDrop) {
        // Dropping a queen into a quiet square is wasteful; prefer cheap drops
        // near the enemy king.
        score -= _value[m.drop!]! * 0.4;
        final ek = next.kingSquare(me.opposite);
        if (ek != null) {
          final d = _dist(m.to, ek);
          score += (7 - d) * 0.6;
        }
      } else {
        final mover = pos.at(m.from!)!;
        final fromRank = Square.rankOf(m.from!);
        final home = me == PieceColor.white ? 0 : 7;
        final toRank = Square.rankOf(m.to);
        if ((mover.type == PieceType.knight ||
                mover.type == PieceType.bishop) &&
            fromRank == home) {
          score += 1.2; // development
        }
        if (mover.type == PieceType.rook || mover.type == PieceType.queen) {
          // Heavy pieces stay home until minor pieces and pawns have moved.
          score -= 0.6;
        }
        if (toRank == home && mover.type != PieceType.king) score -= 0.8;
        if (mover.type == PieceType.pawn) {
          final f = Square.fileOf(m.from!);
          score += (f == 3 || f == 4) ? 1.0 : 0.3;
          final advance = me == PieceColor.white
              ? toRank - fromRank
              : fromRank - toRank;
          score += advance * 0.2;
        }
        if (mover.type == PieceType.king &&
            (Square.fileOf(m.from!) - Square.fileOf(m.to)).abs() == 2) {
          score += 2; // castling
        }
        // Centralisation.
        final cf = (Square.fileOf(m.to) - 3.5).abs();
        final cr = (Square.rankOf(m.to) - 3.5).abs();
        score += (3.5 - (cf + cr) / 2) * 0.15;
      }
      // Deterministic jitter so games vary by seed but replay identically.
      score += _rng.nextDouble() * 0.35;
      if (score > bestScore + 1e-9) {
        bestScore = score;
        best = [m];
      } else if ((score - bestScore).abs() <= 1e-9) {
        best.add(m);
      }
    }
    final pick = best[_rng.nextInt(best.length)];
    final layout = _layout(pos.play(pick).position);
    _seen[layout] = (_seen[layout] ?? 0) + 1;
    return pick;
  }

  static String _layout(Position p) => p.fen.split(' ').first;

  static int _dist(int a, int b) => max(
    (Square.fileOf(a) - Square.fileOf(b)).abs(),
    (Square.rankOf(a) - Square.rankOf(b)).abs(),
  );

  static MoveOutcome _preview(Position pos, Move m) => pos.play(m);
}
