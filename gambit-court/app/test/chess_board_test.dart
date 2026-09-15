import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gambit_court/theme/app_theme.dart';
import 'package:gambit_court/widgets/board/chess_board.dart';
import 'package:gambit_court/widgets/board/piece_glyph.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.dark}) {
  return MaterialApp(
    theme: buildGcTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders all 32 pieces of the initial position', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChessBoard(
          position: Position.initial,
          orientation: PieceColor.white,
          size: 400,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PieceGlyph), findsNWidgets(32));
  });

  testWidgets('tapping a square reports its index for either orientation', (
    tester,
  ) async {
    for (final orientation in PieceColor.values) {
      final taps = <int>[];
      await tester.pumpWidget(
        _wrap(
          ChessBoard(
            position: Position.initial,
            orientation: orientation,
            size: 400,
            movableColor: PieceColor.white,
            onTap: taps.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final board = find.byType(ChessBoard);
      final topLeft = tester.getTopLeft(board);
      // Centre of the bottom-left square.
      await tester.tapAt(topLeft + const Offset(25, 375));
      await tester.pump();
      expect(taps, [
        orientation == PieceColor.white
            ? Square.parse('a1')
            : Square.parse('h8'),
      ]);
    }
  });

  testWidgets('light and dark themes both lay out without overflow', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        _wrap(
          ChessBoard(
            position: Position.fromFen(
              '1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b k - 1 17',
            )!,
            orientation: PieceColor.black,
            size: 320,
            lastMove: Move(Square.parse('d1')!, Square.parse('d8')!),
          ),
          brightness: brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(PieceGlyph), findsNWidgets(20));
    }
  });
}
