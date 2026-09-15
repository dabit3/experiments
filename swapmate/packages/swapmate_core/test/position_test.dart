import 'package:swapmate_core/swapmate_core.dart';
import 'package:test/test.dart';

void main() {
  group('Position', () {
    test('initial position has 20 legal moves and standard FEN', () {
      final p = Position.initial();
      expect(p.legalMoves().length, 20);
      expect(
        p.fen,
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR[] w KQkq - 0 1',
      );
    });

    test('FEN round trip', () {
      final p = Position.initial().play(Move.parse('e2e4')).position;
      final again = Position.fromFen(p.fen);
      expect(again.fen, p.fen);
      expect(again.epSquare, Square.parse('e3'));
    });

    test('scholar\'s mate is checkmate', () {
      var p = Position.initial();
      for (final m in ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6']) {
        p = p.play(Move.parse(m)).position;
      }
      final out = p.play(Move.parse('h5f7'));
      expect(out.isCheckmate, isTrue);
      expect(out.san, 'Qxf7#');
      expect(out.captured, Piece(PieceColor.black, PieceType.pawn));
    });

    test(
      'capture reports the captured piece and promoted pieces revert to pawns',
      () {
        final p = Position.fromFen('k7/7P/8/8/8/8/7r/K7[] w - - 0 1');
        final promo = p.play(Move.parse('h7h8q'));
        expect(promo.san, 'h8=Q+');
        expect(promo.position.at(Square.parse('h8'))!.promoted, isTrue);
        // Black rook captures the promoted queen: it is passed as a pawn.
        final cap = promo.position.play(Move.parse('h2h8'));
        expect(cap.captured, Piece(PieceColor.white, PieceType.pawn));
      },
    );

    test('pawns cannot be dropped on the first or eighth rank', () {
      final p = Position.fromFen('k7/8/8/8/8/8/8/K7[Pp] w - - 0 1');
      final drops = p.legalMoves().where((m) => m.isDrop).toList();
      expect(drops, isNotEmpty);
      for (final d in drops) {
        final r = Square.rankOf(d.to);
        expect(r, isNot(0));
        expect(r, isNot(7));
      }
      expect(p.isLegal(Move.drop(PieceType.pawn, Square.parse('e8'))), isFalse);
      expect(p.isLegal(Move.drop(PieceType.pawn, Square.parse('e2'))), isTrue);
    });

    test('drops can give checkmate', () {
      // Black king boxed on h8 by white queen on g6 and pawn h7 protected;
      // white drops a rook on h-file? Simpler: smother.
      final p = Position.fromFen('6rk/6pp/8/8/8/8/8/K7[N] w - - 0 1');
      final drop = Move.drop(PieceType.knight, Square.parse('f7'));
      expect(p.isLegal(drop), isTrue);
      final out = p.play(drop);
      expect(out.isCheckmate, isTrue);
      expect(out.san, 'N@f7#');
    });

    test('drop consumes reserve and SAN uses @', () {
      final p = Position.fromFen('k7/8/8/8/8/8/8/K7[Qq] w - - 0 1');
      final out = p.play(Move.drop(PieceType.queen, Square.parse('d4')));
      expect(out.san, 'Q@d4');
      expect(out.position.whiteReserve.has(PieceType.queen), isFalse);
      expect(out.position.blackReserve.has(PieceType.queen), isTrue);
      expect(out.position.fen, startsWith('k7/8/8/8/3Q4/8/8/K7[q] b'));
    });

    test('castling and en passant', () {
      final p = Position.fromFen('r3k2r/8/8/3pP3/8/8/8/R3K2R[] w KQkq d6 0 1');
      expect(p.isLegal(Move.parse('e1g1')), isTrue);
      expect(p.isLegal(Move.parse('e1c1')), isTrue);
      final ep = p.play(Move.parse('e5d6'));
      expect(ep.san, 'exd6');
      expect(ep.captured, Piece(PieceColor.black, PieceType.pawn));
      expect(ep.position.at(Square.parse('d5')), isNull);
      final castle = p.play(Move.parse('e1g1'));
      expect(castle.san, 'O-O');
      expect(castle.position.at(Square.parse('f1'))?.type, PieceType.rook);
    });

    test('stalemate detection', () {
      final p = Position.fromFen('k7/2Q5/1K6/8/8/8/8/8[] b - - 0 1');
      expect(p.isStalemate, isTrue);
      expect(p.isCheckmate, isFalse);
    });

    test('cannot move into check, must escape check', () {
      final p = Position.fromFen('k7/8/8/8/8/8/1r6/K7[] w - - 0 1');
      expect(p.inCheck(), isFalse);
      expect(p.isLegal(Move.parse('a1b1')), isFalse);
      expect(p.isLegal(Move.parse('a1b2')), isTrue);
    });

    test('moveFromSan parses drops and moves', () {
      final p = Position.fromFen('k7/8/8/8/8/8/8/K7[N] w - - 0 1');
      expect(
        p.moveFromSan('N@f3'),
        Move.drop(PieceType.knight, Square.parse('f3')),
      );
      expect(p.moveFromSan('Kb1'), Move.parse('a1b1'));
    });
  });

  group('Move', () {
    test('uci round trip', () {
      for (final s in ['e2e4', 'e7e8q', 'N@f3', 'P@e2']) {
        expect(Move.parse(s).uci, s);
        expect(Move.fromJson(Move.parse(s).toJson()), Move.parse(s));
      }
    });
  });
}
