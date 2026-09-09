import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gambit_court/theme/app_theme.dart';
import 'package:gambit_court/widgets/game/player_card.dart';
import 'package:gambit_court_core/gambit_court_core.dart';

const _thirtyMinutes = TimeControl(initialMs: 1800000, incrementMs: 0);

Widget _clock(ClockState clocks, {required int receivedLocalMs}) {
  return MaterialApp(
    theme: buildGcTheme(Brightness.dark),
    home: Scaffold(
      body: Center(
        child: ClockDisplay(
          color: PieceColor.white,
          clocks: clocks,
          receivedLocalMs: receivedLocalMs,
          timeControl: _thirtyMinutes,
          active: true,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a running clock extrapolates from the snapshot time', (
    tester,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      _clock(
        ClockState(
          whiteMs: 1800000,
          blackMs: 1800000,
          running: PieceColor.white,
          asOfServerMs: now,
          frozen: false,
        ),
        receivedLocalMs: now - 2500,
      ),
    );
    await tester.pump();
    expect(find.text('29:57'), findsOneWidget);
  });

  testWidgets('a stopped clock shows the exact snapshot value', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      _clock(
        ClockState(
          whiteMs: 212000,
          blackMs: 210000,
          running: null,
          asOfServerMs: now,
          frozen: true,
        ),
        receivedLocalMs: now - 60000,
      ),
    );
    await tester.pump();
    expect(find.text('3:32'), findsOneWidget);
  });

  test('formatClock never goes below zero and shows tenths under 20s', () {
    expect(formatClock(-5), '0:00.0');
    expect(formatClock(19400), '0:19.4');
    expect(formatClock(3661000), '1:01:01');
  });
}
