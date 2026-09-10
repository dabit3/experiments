import 'dart:io';

import 'package:brickfolk_app/main.dart';
import 'package:brickfolk_app/src/app_state.dart';
import 'package:brickfolk_app/src/config.dart';
import 'package:brickfolk_app/src/net/client.dart';
import 'package:brickfolk_app/src/theme/theme.dart';
import 'package:brickfolk_app/src/widgets/avatar_painter.dart';
import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state({Map<String, String> query = const {}}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final config = AppConfig.load({'server': 'ws://127.0.0.1:1/ws', ...query});
  final client = BrickfolkClient(
    serverUrl: config.serverUrl,
    platform: config.platformLabel,
  );
  return AppState(config, client, prefs);
}

const _profile = PlayerProfile(
  summary: PlayerSummary(
    id: 'p1_TEST',
    name: 'HubHazel',
    avatar: Avatar(),
    platform: 'macos',
  ),
  pips: 120,
  owned: {},
  badges: [],
  createdAt: 0,
  dailyStreak: 1,
  lastDailyClaim: null,
  stats: {},
);

/// The test binding substitutes a block glyph font, so register the real
/// Inter faces when a test measures layout.
Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/Inter-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  group('AppConfig', () {
    test('query parameters override defines', () {
      final c = AppConfig.load({
        'server': 'ws://example:9/ws',
        'test': '1',
        'name': 'WebWren',
        'party': 'ABCD',
        'host': '1',
        'players': '4',
        'bots': '0',
        'experience': 'tag',
        'theme': 'dark',
      });
      expect(c.serverUrl, 'ws://example:9/ws');
      expect(c.testMode, isTrue);
      expect(c.autoName, 'WebWren');
      expect(c.partyCode, 'ABCD');
      expect(c.isHost, isTrue);
      expect(c.expectedPlayers, 4);
      expect(c.bots, 0);
      expect(c.experience, 'tag');
      expect(c.forceTheme, 'dark');
    });

    test('defaults are sane', () {
      final c = AppConfig.load(const {});
      expect(c.testMode, isFalse);
      expect(c.bots, 2);
      expect(c.experience, 'obby');
      expect(c.serverUrl, startsWith('ws://'));
    });
  });

  group('theme', () {
    test('light and dark themes share the Inter type family', () {
      final light = brickTheme(Brightness.light);
      final dark = brickTheme(Brightness.dark);
      expect(light.useMaterial3, isTrue);
      expect(light.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(dark.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });
  });

  group('AvatarView', () {
    testWidgets('paints every catalog hat/face/accessory without errors', (
      tester,
    ) async {
      final hats = catalog.where((i) => i.slot == ItemSlot.hat);
      final faces = catalog.where((i) => i.slot == ItemSlot.face);
      final accessories = catalog.where((i) => i.slot == ItemSlot.accessory);
      final avatars = <Avatar>[
        for (final hat in hats)
          for (final face in faces) Avatar(hat: hat.id, face: face.id),
        for (final acc in accessories) Avatar(accessory: acc.id),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Wrap(
              children: [
                for (final a in avatars) AvatarView(a, size: 48),
                const AvatarView(Avatar(), size: 48, frozen: true),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AvatarView), findsNWidgets(avatars.length + 1));
    });
  });

  group('BrickfolkApp', () {
    testWidgets('shows the sign-in screen when signed out', (tester) async {
      final state = await _state();
      await tester.pumpWidget(BrickfolkApp(state: state));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Pick a name'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Brickfolk'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      state.client.dispose();
    });

    testWidgets('rejects an invalid name locally', (tester) async {
      final state = await _state();
      await tester.pumpWidget(BrickfolkApp(state: state));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byType(TextField), '1x');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      expect(find.textContaining('3–16 letters'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      state.client.dispose();
    });

    testWidgets('lays out on a compact 320px phone without overflow', (
      tester,
    ) async {
      await _loadInter();
      tester.view.physicalSize = const Size(480, 854);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.reset);
      final state = await _state();
      await tester.pumpWidget(BrickfolkApp(state: state));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      state.client.dispose();
    });

    for (final (label, size) in [
      ('phone', const Size(390, 844)),
      ('tablet', const Size(820, 1180)),
      ('desktop', const Size(1180, 760)),
    ]) {
      testWidgets('signed-in hub lays out on $label without errors', (
        tester,
      ) async {
        await _loadInter();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final state = await _state();
        state.client.me = _profile;
        await tester.pumpWidget(BrickfolkApp(state: state));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(find.byType(AvatarView), findsWidgets);
        expect(find.text('Pick a name'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        state.client.dispose();
      });
    }

    testWidgets('forced dark theme applies', (tester) async {
      final state = await _state(query: {'theme': 'dark'});
      await tester.pumpWidget(BrickfolkApp(state: state));
      await tester.pump(const Duration(milliseconds: 600));
      final ctx = tester.element(find.byType(TextField));
      expect(Theme.of(ctx).brightness, Brightness.dark);
      await tester.pumpWidget(const SizedBox());
      state.client.dispose();
    });
  });
}
