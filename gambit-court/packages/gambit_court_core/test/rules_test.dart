import 'package:gambit_court_core/gambit_court_core.dart';
import 'package:test/test.dart';

/// Counts leaf nodes at [depth] (perft) for legal-move generation checks.
int perft(Position position, int depth) {
  if (depth == 0) return 1;
  var nodes = 0;
  for (final move in position.legalMoves()) {
    nodes += perft(position.apply(move), depth - 1);
  }
  return nodes;
}

void main() {
  group('FEN', () {
    test('round-trips the start position', () {
      expect(Position.initial.fen, Position.startFen);
    });

    test('rejects malformed input', () {
      expect(Position.fromFen('rnbqkbnr/pppppppp w'), isNull);
      expect(Position.fromFen('8/8/8/8/8/8/8/8 w - - 0 1'), isNull);
    });
  });

  group('perft (well-known reference node counts)', () {
    test('start position', () {
      expect(perft(Position.initial, 1), 20);
      expect(perft(Position.initial, 2), 400);
      expect(perft(Position.initial, 3), 8902);
    });

    test('kiwipete covers castling, en passant, promotions, and checks', () {
      final pos = Position.fromFen(
        'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
      )!;
      expect(perft(pos, 1), 48);
      expect(perft(pos, 2), 2039);
      expect(perft(pos, 3), 97862);
    });

    test('position 3 (rook and pawn endgame with en passant)', () {
      final pos =
          Position.fromFen('8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1')!;
      expect(perft(pos, 1), 14);
      expect(perft(pos, 2), 191);
      expect(perft(pos, 3), 2812);
      expect(perft(pos, 4), 43238);
    });

    test('position 4 (promotions and castling into check)', () {
      final pos = Position.fromFen(
        'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
      )!;
      expect(perft(pos, 1), 6);
      expect(perft(pos, 2), 264);
      expect(perft(pos, 3), 9467);
    });

    test('position 5', () {
      final pos = Position.fromFen(
        'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
      )!;
      expect(perft(pos, 1), 44);
      expect(perft(pos, 2), 1486);
      expect(perft(pos, 3), 62379);
    });
  });

  group('special moves', () {
    test('castling moves the rook and clears rights', () {
      final pos = Position.fromFen(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      )!;
      final castle = Move.parseUci('e1g1')!;
      expect(pos.isLegal(castle), isTrue);
      final next = pos.apply(castle);
      expect(next.pieceAt(Square.parse('f1')!)?.type, PieceType.rook);
      expect(next.pieceAt(Square.parse('h1')!), isNull);
      expect(next.castling & Castling.whiteKing, 0);
      expect(next.castling & Castling.whiteQueen, 0);
      expect(next.castling & Castling.blackKing, Castling.blackKing);
    });

    test('castling is illegal through check', () {
      final pos = Position.fromFen('4k3/8/8/8/8/8/5r2/4K2R w K - 0 1')!;
      expect(pos.isLegal(Move.parseUci('e1g1')!), isFalse);
    });

    test('en passant removes the captured pawn', () {
      final pos = Position.fromFen(
        'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3',
      )!;
      final ep = Move.parseUci('e5f6')!;
      expect(pos.isLegal(ep), isTrue);
      expect(pos.isEnPassant(ep), isTrue);
      final next = pos.apply(ep);
      expect(next.pieceAt(Square.parse('f5')!), isNull);
      expect(next.pieceAt(Square.parse('f6')!)?.type, PieceType.pawn);
    });

    test('promotion requires an explicit piece over the wire', () {
      final game = Game(
        start: Position.fromFen('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
      );
      expect(game.playUci('a7a8'), isNull);
      expect(game.playUci('a7a8n')?.san, 'a8=N');
      expect(
          game.position.pieceAt(Square.parse('a8')!)?.type, PieceType.knight);
    });
  });

  group('game end detection', () {
    test('fools mate is checkmate', () {
      final game = Game();
      for (final san in ['f3', 'e5', 'g4', 'Qh4#']) {
        expect(game.playSan(san), isNotNull, reason: san);
      }
      expect(game.result?.outcome, GameOutcome.blackWins);
      expect(game.result?.reason, GameEndReason.checkmate);
      expect(game.moves.last.san, 'Qh4#');
    });

    test('stalemate', () {
      final game =
          Game(start: Position.fromFen('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'));
      expect(game.result?.reason, GameEndReason.stalemate);
    });

    test('insufficient material', () {
      final game =
          Game(start: Position.fromFen('8/8/8/3k4/8/8/8/3K2B1 w - - 0 1'));
      expect(game.result?.reason, GameEndReason.insufficientMaterial);
      final bishops = Position.fromFen('8/8/8/3k4/8/2b5/8/3K2B1 w - - 0 1')!;
      expect(bishops.isInsufficientMaterial, isTrue);
      final oppositeBishops =
          Position.fromFen('8/8/8/3k4/8/3b4/8/3K2B1 w - - 0 1')!;
      expect(oppositeBishops.isInsufficientMaterial, isFalse);
    });

    test('mating material for the timeout rule', () {
      final bare = Position.fromFen('4k3/8/8/8/8/8/8/4K3 w - - 0 1')!;
      expect(bare.hasMatingMaterial(PieceColor.white), isFalse);
      final pawn = Position.fromFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1')!;
      expect(pawn.hasMatingMaterial(PieceColor.white), isTrue);
      final minor = Position.fromFen('4k3/8/8/8/8/8/8/4KB2 w - - 0 1')!;
      expect(minor.hasMatingMaterial(PieceColor.white), isFalse);
      final two = Position.fromFen('4k3/8/8/8/8/8/8/4KBN1 w - - 0 1')!;
      expect(two.hasMatingMaterial(PieceColor.white), isTrue);
    });

    test('threefold repetition ends the game', () {
      final game = Game();
      for (final san in [
        'Nf3',
        'Nf6',
        'Ng1',
        'Ng8',
        'Nf3',
        'Nf6',
        'Ng1',
        'Ng8'
      ]) {
        expect(game.playSan(san), isNotNull, reason: san);
      }
      expect(game.result?.reason, GameEndReason.threefoldRepetition);
    });

    test('fifty-move rule', () {
      final game = Game(
        start: Position.fromFen('8/8/8/3k4/8/8/8/R3K3 w - - 99 80'),
      );
      expect(game.result, isNull);
      expect(game.playSan('Ra2'), isNotNull);
      expect(game.result?.reason, GameEndReason.fiftyMoveRule);
    });

    test('takeback reopens a finished game', () {
      final game = Game();
      for (final san in ['f3', 'e5', 'g4', 'Qh4#']) {
        game.playSan(san);
      }
      expect(game.isOver, isTrue);
      expect(game.takeBack(), isTrue);
      expect(game.isOver, isFalse);
      expect(game.moves.length, 3);
    });
  });

  group('SAN', () {
    test('disambiguates by file, rank, and square', () {
      final pos = Position.fromFen('4k3/8/8/8/8/8/4K3/R6R w - - 0 1')!;
      expect(San.render(pos, Move.parseUci('a1d1')!), 'Rad1');
      final knights = Position.fromFen('4k3/8/8/N7/8/8/8/N3K3 w - - 0 1')!;
      expect(San.render(knights, Move.parseUci('a1b3')!), 'N1b3');
      final queens = Position.fromFen('k7/8/8/2Q4K/8/8/8/2Q1Q3 w - - 0 1')!;
      expect(San.render(queens, Move.parseUci('c1c3')!), 'Qc1c3');
    });

    test('parses checks, captures, and promotions', () {
      final game = Game();
      expect(game.playSan('e4'), isNotNull);
      expect(game.playSan('d5'), isNotNull);
      expect(game.playSan('exd5')?.move.uci, 'e4d5');
      expect(game.playSan('Qxd5'), isNotNull);
      expect(game.playSan('Nc3'), isNotNull);
      expect(game.playSan('Qe5+'), isNotNull);
      expect(game.position.isInCheck, isTrue);
    });
  });

  group('PGN', () {
    test('export then import reproduces the game', () {
      final game = Game();
      for (final san in ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'O-O']) {
        game.playSan(san);
      }
      final pgn = Pgn.export(game, tags: {'White': 'Ada', 'Black': 'Bo'});
      expect(pgn, contains('[White "Ada"]'));
      expect(pgn, contains('1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. O-O *'));
      final imported = Pgn.import(pgn)!;
      expect(imported.errors, isEmpty);
      expect(imported.game.moves.map((m) => m.san).toList(),
          game.moves.map((m) => m.san).toList());
      expect(imported.tags['Black'], 'Bo');
    });

    test('import tolerates comments, variations, NAGs, and results', () {
      final imported = Pgn.import('''
[Event "Test"]
[Result "1-0"]

1. e4 {best by test} e5 (1... c5 2. Nf3) 2. Nf3 \$1 Nc6 3. Bb5 1-0
''')!;
      expect(imported.errors, isEmpty);
      expect(imported.game.moves.length, 5);
      expect(imported.result, '1-0');
    });

    test('import reports the first illegal move', () {
      final imported = Pgn.import('1. e4 e5 2. Ke2 Ke7 3. Qh5')!;
      expect(imported.game.moves.length, 4);
      expect(imported.errors.single, contains('Qh5'));
    });
  });

  group('engine', () {
    test('finds mate in one', () {
      final pos = Position.fromFen('6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1')!;
      final result = Engine(level: EngineLevel.club).bestMove(pos);
      expect(result.move?.uci, 'a1a8');
    });

    test('is deterministic for a fixed seed', () {
      final pos = Position.initial;
      final a = Engine(level: EngineLevel.novice, seed: 7).bestMove(pos).move;
      final b = Engine(level: EngineLevel.novice, seed: 7).bestMove(pos).move;
      expect(a, b);
    });

    test('takes free material', () {
      final pos = Position.fromFen('4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1')!;
      final result = Engine(level: EngineLevel.expert).bestMove(pos);
      expect(result.move?.uci, 'd1d5');
    });
  });

  group('time control', () {
    test('categories and labels', () {
      expect(const TimeControl(initialMs: 60000, incrementMs: 0).category,
          'Bullet');
      expect(
          const TimeControl(initialMs: 180000, incrementMs: 2000).label, '3+2');
      expect(const TimeControl(initialMs: 600000, incrementMs: 0).category,
          'Rapid');
      expect(const TimeControl(initialMs: 1800000, incrementMs: 0).category,
          'Classical');
    });
  });
}
