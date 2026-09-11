import 'package:swapmate_core/swapmate_core.dart';
import 'package:test/test.dart';

void main() {
  group('BughouseMatch', () {
    test('captured pieces are passed to the partner on the other board', () {
      final m = BughouseMatch(timeControl: TimeControl.blitz3)..start(0);
      m.play(Seat.aWhite, Move.parse('e2e4'), 100);
      m.play(Seat.aBlack, Move.parse('d7d5'), 200);
      final entry = m.play(Seat.aWhite, Move.parse('e4d5'), 300);
      expect(entry.captured, PieceType.pawn);
      expect(entry.san, 'exd5');
      // A-White's partner is B-Black.
      expect(m.position(BoardId.b).blackReserve.has(PieceType.pawn), isTrue);
      expect(m.position(BoardId.b).whiteReserve.has(PieceType.pawn), isFalse);
      expect(m.position(BoardId.a).whiteReserve.has(PieceType.pawn), isFalse);
      expect(entry.bpgn, '2A. exd5');
    });

    test('turn enforcement', () {
      final m = BughouseMatch(timeControl: TimeControl.blitz3)..start(0);
      expect(
        () => m.play(Seat.aBlack, Move.parse('e7e5'), 1),
        throwsStateError,
      );
      expect(m.isTurn(Seat.bWhite), isTrue);
    });

    test('clocks run independently and increment applies', () {
      const tc = TimeControl(initialMs: 60000, incrementMs: 2000);
      final m = BughouseMatch(timeControl: tc)..start(0);
      m.play(Seat.aWhite, Move.parse('e2e4'), 5000);
      final a = m.snapshot(BoardId.a, 5000);
      final b = m.snapshot(BoardId.b, 5000);
      expect(a.whiteMs, 57000);
      expect(a.blackMs, 60000);
      expect(a.running, PieceColor.black);
      expect(b.whiteMs, 55000);
      expect(b.running, PieceColor.white);
    });

    test('flag fall ends the match for the other team', () {
      final m = BughouseMatch(timeControl: TimeControl.blitz3)..start(0);
      expect(m.checkFlags(179000), isFalse);
      expect(m.checkFlags(180001), isTrue);
      expect(m.result!.reason, ResultReason.timeout);
      expect(m.result!.loser, Seat.aWhite);
      expect(m.result!.winner, Team.two);
    });

    test('checkmate on either board ends the whole match', () {
      final m = BughouseMatch(timeControl: TimeControl.blitz3)..start(0);
      final line = ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6', 'h5f7'];
      var t = 0;
      for (final u in line) {
        final seat = m.seatToMove(BoardId.b);
        m.play(seat, Move.parse(u), t += 100);
      }
      expect(m.isOver, isTrue);
      expect(m.result!.reason, ResultReason.checkmate);
      expect(m.result!.board, BoardId.b);
      expect(m.result!.winner, Team.two); // B-White is team 2
      expect(
        () => m.play(Seat.aWhite, Move.parse('e2e4'), t + 1),
        throwsStateError,
      );
    });

    test('BPGN export lists both boards chronologically', () {
      final m = BughouseMatch(timeControl: TimeControl.blitz3)..start(0);
      m.play(Seat.aWhite, Move.parse('e2e4'), 1000);
      m.play(Seat.bWhite, Move.parse('d2d4'), 1500);
      m.play(Seat.aBlack, Move.parse('e7e5'), 2000);
      m.resign(Seat.bBlack, 2500);
      final text = Bpgn.export(
        match: m,
        names: {
          Seat.aWhite: 'Web',
          Seat.aBlack: 'iOS',
          Seat.bWhite: 'Android',
          Seat.bBlack: 'macOS',
        },
        date: DateTime(2026, 9, 9),
      );
      expect(text, contains('[WhiteA "Web"]'));
      expect(text, contains('[BlackB "macOS"]'));
      // B-Black is on Team 1, so their resignation is a Team 2 win.
      expect(text, contains('[Result "0-1"]'));
      expect(text, contains('1A. e4 {179} 1B. d4 {178.5} 1a. e5 {179}'));
      expect(text, contains('{BB resigns} 0-1'));
    });

    test('snapshot json round trip', () {
      final m = BughouseMatch(timeControl: TimeControl.blitz3)..start(0);
      m.play(Seat.aWhite, Move.parse('e2e4'), 1000);
      final s = m.snapshot(BoardId.a, 1000);
      final back = BoardSnapshot.fromJson(s.toJson());
      expect(back.fen, s.fen);
      expect(back.whiteMs, s.whiteMs);
      expect(back.lastMove, Move.parse('e2e4'));
    });
  });

  group('Bot', () {
    test('is deterministic for a given seed', () {
      final a = Bot(seed: 7);
      final b = Bot(seed: 7);
      var pa = Position.initial();
      var pb = Position.initial();
      for (var i = 0; i < 30; i++) {
        final ma = a.choose(pa);
        final mb = b.choose(pb);
        expect(ma, mb);
        if (ma == null) break;
        pa = pa.play(ma).position;
        pb = pb.play(mb!).position;
      }
    });

    test('takes mate in one', () {
      var p = Position.initial();
      for (final m in ['e2e4', 'e7e5', 'd1h5', 'b8c6', 'f1c4', 'g8f6']) {
        p = p.play(Move.parse(m)).position;
      }
      expect(Bot(seed: 1).choose(p), Move.parse('h5f7'));
    });

    test('two bots finish a match', () {
      final m = BughouseMatch(
        timeControl: const TimeControl(initialMs: 600000, incrementMs: 0),
      )..start(0);
      final bots = {for (final s in Seat.values) s: Bot(seed: s.index + 1)};
      var t = 0;
      while (!m.isOver && t < 2000) {
        for (final b in BoardId.values) {
          if (m.isOver) break;
          final seat = m.seatToMove(b);
          final mv = bots[seat]!.choose(m.position(b));
          if (mv == null) break;
          m.play(seat, mv, ++t);
        }
      }
      expect(m.isOver, isTrue, reason: 'bots should finish within 2000 plies');
    });
  });
}
