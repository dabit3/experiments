import 'dart:convert';

import 'package:brickfolk_server/brickfolk_server.dart';
import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:test/test.dart';

/// In-process fake client bound to a [Hub].
class FakeClient {
  FakeClient(this.hub, this.platform) {
    session = hub.connect((text) {
      final frame = (jsonDecode(text) as Map).cast<String, Object?>();
      frames.add(frame);
      last[frame['type'] as String] = frame;
    }, () => closed = true);
    session.platform = platform;
  }

  final Hub hub;
  final String platform;
  late final Session session;
  final frames = <Map<String, Object?>>[];
  final last = <String, Map<String, Object?>>{};
  bool closed = false;

  void send(Map<String, Object?> frame) =>
      hub.handle(session, jsonEncode(frame));

  void hello(String name, {String? token}) => send({
    'type': MsgType.hello,
    'protocolVersion': protocolVersion,
    'name': name,
    'token': token,
    'platform': platform,
  });

  String get token => last[MsgType.welcome]!['token'] as String;
  String get playerId =>
      (last[MsgType.welcome]!['player'] as Map)['id'] as String;
  Map<String, Object?>? get room =>
      (last[MsgType.roomState]?['room'] as Map?)?.cast<String, Object?>();
  Map<String, Object?>? get results =>
      (last[MsgType.gameResults]?['results'] as Map?)?.cast<String, Object?>();
  List<Map<String, Object?>> errors() =>
      frames.where((f) => f['type'] == MsgType.error).map((f) => f).toList();
}

Hub makeHub() => Hub(
  store: Store(':memory:'),
  clock: FixedClock(),
  seed: 1234,
  testMode: true,
);

void main() {
  test('rejects bad names and duplicate names', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('x');
    expect(a.last[MsgType.error]?['code'], ErrorCode.invalidName);
    a.hello('Alice');
    expect(a.last[MsgType.welcome], isNotNull);
    final b = FakeClient(hub, 'ios')..hello('alice');
    expect(b.last[MsgType.error]?['code'], ErrorCode.nameTaken);
  });

  test('token resumes the same player and profile persists', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('Alice');
    final token = a.token;
    a.send({'type': MsgType.shopBuy, 'item': 'hat_cap'});
    final profile = (a.last[MsgType.playerUpdated]!['player'] as Map);
    expect(profile['pips'], 50);
    hub.disconnect(a.session);
    final b = FakeClient(hub, 'macos')..hello('ignored', token: token);
    final p = b.last[MsgType.welcome]!['player'] as Map;
    expect(p['name'], 'Alice');
    expect(p['pips'], 50);
    expect(p['owned'], contains('hat_cap'));
  });

  test('unknown token without a name is rejected as unauthenticated', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'macos')
      ..send({
        'type': MsgType.hello,
        'protocolVersion': protocolVersion,
        'token': 'stale-token-from-an-older-database',
        'platform': 'macos',
      });
    expect(a.last[MsgType.welcome], isNull);
    expect(a.last[MsgType.error]?['code'], ErrorCode.unauthenticated);
    expect(a.last[MsgType.error]?['inReplyTo'], MsgType.hello);
    a.hello('MacMia', token: 'stale-token-from-an-older-database');
    expect(a.last[MsgType.welcome], isNotNull);
  });

  test('online count is pushed to everyone on sign-in and disconnect', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('Alice');
    expect(a.last[MsgType.places]?['online'], 1);
    final b = FakeClient(hub, 'ios')..hello('Bobby');
    expect(a.last[MsgType.places]?['online'], 2);
    expect(b.last[MsgType.places]?['online'], 2);
    hub.disconnect(b.session);
    expect(a.last[MsgType.places]?['online'], 1);
  });

  test('daily reward claims once and reports cooldown', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('Alice');
    a.send({'type': MsgType.dailyClaim});
    expect(a.last[MsgType.dailyResult]!['claimed'], true);
    expect(a.last[MsgType.dailyResult]!['reward'], 25);
    a.send({'type': MsgType.dailyClaim});
    expect(a.last[MsgType.dailyResult]!['claimed'], false);
  });

  test('chat is filtered and rate limited', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('Alice');
    final b = FakeClient(hub, 'android')..hello('Bob');
    a.send({'type': MsgType.chatSend, 'text': 'hi bob visit http://x.y'});
    final msg = b.last[MsgType.chatMessage]!['message'] as Map;
    expect(msg['text'], isNot(contains('http')));
    expect(msg['filtered'], true);
    a.send({'type': MsgType.chatSend, 'text': 'again'});
    expect(a.last[MsgType.error]?['code'], ErrorCode.rateLimited);
  });

  test('friends request/accept flow awards social badge', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('Alice');
    final b = FakeClient(hub, 'ios')..hello('Bob');
    a.send({'type': MsgType.friendsRequest, 'player': 'Bob'});
    expect((b.last[MsgType.friendsState]!['incoming'] as List), hasLength(1));
    b.send({'type': MsgType.friendsAccept, 'player': 'Alice'});
    expect((a.last[MsgType.friendsState]!['friends'] as List), hasLength(1));
    final badges = (a.last[MsgType.playerUpdated]!['player'] as Map)['badges'];
    expect(badges, contains('social'));
  });

  test('four platforms party up, play an obby match, identical results', () {
    final hub = makeHub();
    final clients = {
      'web': FakeClient(hub, 'web')..hello('WebWanda'),
      'ios': FakeClient(hub, 'ios')..hello('IosIvy'),
      'android': FakeClient(hub, 'android')..hello('DroidDan'),
      'macos': FakeClient(hub, 'macos')..hello('MacMia'),
    };
    final leader = clients['web']!;
    leader.send({'type': MsgType.partyCreate});
    final code = (leader.last[MsgType.partyState]!['party'] as Map)['code'];
    for (final c in clients.values) {
      if (c != leader) c.send({'type': MsgType.partyJoin, 'code': code});
    }
    expect(
      ((leader.last[MsgType.partyState]!['party'] as Map)['members'] as List),
      hasLength(4),
    );
    leader.send({'type': MsgType.partyLaunch, 'experience': 'obby', 'bots': 2});
    for (final c in clients.values) {
      expect(c.room, isNotNull, reason: '${c.platform} did not get room');
      expect(c.room!['code'], leader.room!['code']);
      c.send({'type': MsgType.roomReady, 'ready': true});
    }
    expect(leader.room!['phase'], 'countdown');

    // Drive humans with the shared autopilot from their own view of state.
    final pilots = {
      for (final c in clients.values)
        c.playerId: ObbyAutopilot(hesitationTicks: 2),
    };
    var ticks = 0;
    while (clients.values.any((c) => c.results == null) && ticks < 30 * 200) {
      hub.tick();
      ticks++;
      for (final c in clients.values) {
        final frame = c.last[MsgType.gameState];
        if (frame == null || c.room!['phase'] != 'playing') continue;
        final packed = (frame['players'] as Map)[c.playerId] as List?;
        if (packed == null) continue;
        final state = ObbyPlayerState.fromPacked(packed);
        final input = pilots[c.playerId]!.decide(
          ObbyCourse.instance,
          state,
          (frame['tick'] as num).toInt(),
        );
        c.send({'type': MsgType.input, 'data': input.toJson()});
      }
    }
    final checksums = clients.values.map((c) => c.results!['checksum']).toSet();
    expect(checksums, hasLength(1));
    final entries = leader.results!['entries'] as List;
    expect(entries, hasLength(6));
    expect(
      MatchResults.computeChecksum(
        entries.map((e) => LeaderboardEntry.fromJson((e as Map).cast())),
      ),
      leader.results!['checksum'],
    );
    final humansFinished = entries
        .where(
          (e) =>
              (e as Map)['player']['isBot'] == false &&
              (e['detail'] as String).startsWith('Finished'),
        )
        .length;
    expect(humansFinished, 4, reason: jsonEncode(entries));
    for (final c in clients.values) {
      expect(c.errors(), isEmpty, reason: '${c.platform}: ${c.errors()}');
      final profile = c.last[MsgType.playerUpdated]!['player'] as Map;
      expect(profile['badges'], containsAll(['summit', 'first_steps']));
      expect((profile['pips'] as int), greaterThan(100));
    }
    // Results phase eventually returns to the lobby.
    for (var i = 0; i < 30 * 25; i++) {
      hub.tick();
    }
    expect(leader.room!['phase'], 'lobby');
  });

  test('reconnect within grace keeps the seat and re-sends room state', () {
    final hub = makeHub();
    final a = FakeClient(hub, 'web')..hello('Alice');
    a.send({'type': MsgType.roomCreate, 'experience': 'tag', 'bots': 3});
    final roomCode = a.room!['code'];
    final token = a.token;
    hub.disconnect(a.session);
    for (var i = 0; i < 60; i++) {
      hub.tick();
    }
    final b = FakeClient(hub, 'ios')..hello('x', token: token);
    expect(b.last[MsgType.welcome]!['roomCode'], roomCode);
    expect(b.room!['code'], roomCode);
  });

  test('an obby plan applies each entry at its tick and does not expire', () {
    final me = Participant(
      summary: const PlayerSummary(id: 'p1', name: 'Alice', avatar: Avatar()),
      plot: TycoonPlot(),
    );
    final game = ObbyGame([me], 1, ticksPerSecond * 120);
    final s = game.states['p1']!;
    // Hold left for 50 ticks (longer than the 30-tick hold), then release.
    game.handleInput('p1', {
      't': 0,
      'plan': [
        [5, 1],
        [55, 0],
      ],
    });
    for (var i = 0; i < 5; i++) {
      game.step();
      expect(s.lastInput.left, isFalse);
    }
    for (var i = 5; i < 55; i++) {
      game.step();
      expect(s.lastInput.left, isTrue, reason: 'tick $i');
    }
    for (var i = 0; i < 10; i++) {
      game.step();
      expect(s.lastInput.left, isFalse);
    }
    expect(s.inputLag, 0);
    // A late plan whose entries are already due applies immediately, and a
    // new plan replaces the old one from its first tick on.
    game.handleInput('p1', {
      't': 60,
      'plan': [
        [60, 4],
        [200, 0],
      ],
    });
    game.handleInput('p1', {
      't': 62,
      'plan': [
        [70, 0],
      ],
    });
    expect(game.plans['p1']!.map((e) => e.$1), [70]);
    expect(s.inputLag, 3);
    game.step();
    expect(s.lastInput.jump, isTrue);
    expect(s.grounded, isFalse);
  });

  test('a held obby input expires when the client stops refreshing it', () {
    final me = Participant(
      summary: const PlayerSummary(id: 'p1', name: 'Alice', avatar: Avatar()),
      plot: TycoonPlot(),
    );
    final game = ObbyGame([me], 1, ticksPerSecond * 120);
    final s = game.states['p1']!;
    // Holding jump keeps hopping in place while the input is fresh.
    game.handleInput('p1', const ObbyInput(jump: true).toJson());
    var airborne = 0;
    for (var i = 0; i <= HeldInput.holdTicks; i++) {
      game.step();
      if (!s.grounded) airborne++;
    }
    expect(airborne, greaterThan(0));
    // Once the hold lapses the avatar lands and stays put.
    for (var i = 0; i < 2 * ticksPerSecond; i++) {
      game.step();
    }
    for (var i = 0; i < 10; i++) {
      game.step();
      expect(s.grounded, isTrue);
    }
    game.handleInput('p1', const ObbyInput(jump: true).toJson());
    game.step();
    expect(s.grounded, isFalse);
  });

  test('tycoon and tag matches complete with bots and persist the plot', () {
    for (final kind in ['tycoon', 'tag']) {
      final hub = makeHub();
      final a = FakeClient(hub, 'web')..hello('Alice');
      a.send({'type': MsgType.roomCreate, 'experience': kind, 'bots': 3});
      a.send({'type': MsgType.roomReady});
      var ticks = 0;
      while (a.results == null && ticks < 30 * 200) {
        hub.tick();
        ticks++;
        if (kind == 'tycoon' &&
            ticks % 30 == 5 &&
            a.room!['phase'] == 'playing') {
          a.send({
            'type': MsgType.input,
            'data': {'a': 'place', 'cell': ticks ~/ 30, 'item': 'dropper'},
          });
        }
      }
      expect(a.results, isNotNull, reason: '$kind never finished');
      expect(a.results!['entries'], hasLength(4));
      if (kind == 'tycoon') {
        final plot = hub.store.byId(a.playerId)!.plot;
        expect(plot.brickCount, greaterThan(0));
      }
    }
  });
}
