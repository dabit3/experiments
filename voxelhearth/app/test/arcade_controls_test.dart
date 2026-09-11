import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxelhearth/app_state.dart';
import 'package:voxelhearth/audio.dart';
import 'package:voxelhearth/net/game_client.dart';
import 'package:voxelhearth/ui/chat_panel.dart';
import 'package:voxelhearth/ui/lobby_screen.dart';
import 'package:voxelhearth/ui/pixel.dart';

void main() {
  setUp(() => Sfx.enabled = false);

  testWidgets('button borders and focus stay within a compact menu row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(874, 402));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: Row(
                children: [
                  PxButton('Create World', width: 85, onPressed: () {}),
                  const SizedBox(width: 10),
                  PxButton('Player', width: 85, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PxButton).first), const Size(170, 40));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(PxButton).first), const Size(170, 40));
  });

  testWidgets('keyboard activates enabled buttons and skips disabled buttons', (tester) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const PxButton('Unavailable'),
              PxButton('Play', primary: true, onPressed: () => activations++),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(activations, 1);
    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();
    expect(activations, 1);
  });

  testWidgets('phone lobby keeps chat focus and draft when the keyboard opens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(874, 402));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final settings = await Settings.load();
    final client = GameClient(platform: 'ios');
    final session = RoomSession(1234)
      ..youId = 'phone'
      ..hostId = 'web'
      ..roomName = 'Testing'
      ..code = 'HEARTH'
      ..chat.add(ChatEntry(1, 'Web', 'Hello from Web', false, DateTime(2026)));
    addTearDown(client.dispose);
    addTearDown(settings.dispose);

    Widget lobby(double keyboard) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(874, 402),
          padding: const EdgeInsets.fromLTRB(62, 0, 62, 21),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: LobbyScreen(client: client, session: session, settings: settings),
      ),
    );

    await tester.pumpWidget(lobby(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'phone draft');
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    await tester.pumpWidget(lobby(220));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    expect(find.text('phone draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(lobby(0));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(ChatPanel)).height, greaterThanOrEqualTo(90));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
