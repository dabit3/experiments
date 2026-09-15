import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lastfort_core/lastfort_core.dart';

import '../app/config.dart';
import '../app/profile.dart';
import '../game/match_client.dart';
import 'connection.dart';

/// Lobby member as reported by `roomState`.
class RoomMember {
  RoomMember(this.json);
  final Map<String, Object?> json;
  int get id => (json['id'] as num).toInt();
  String get name => json['name'] as String;
  String get platform => json['platform'] as String;
  bool get ready => json['ready'] == true;
  bool get host => json['host'] == true;
  int get team => (json['team'] as num? ?? 0).toInt();
  Loadout get loadout => Loadout.fromJson(json['ld'] as Map<String, Object?>?);
}

class RoomState {
  RoomState(this.json);
  final Map<String, Object?> json;
  String get code => json['code'] as String;
  SquadMode get mode => SquadMode.parse(json['mode'] as String);
  bool get fast => json['fast'] == true;
  int get seed => (json['seed'] as num).toInt();
  int get maxPlayers => (json['maxPlayers'] as num).toInt();
  String get phase => json['phase'] as String;
  int? get countdownMs => (json['countdownMs'] as num?)?.toInt();
  List<RoomMember> get members => [
    for (final m in json['players'] as List<Object?>)
      RoomMember(m as Map<String, Object?>),
  ];
}

enum SessionPhase { idle, lobby, match, results }

/// Owns the connection, current room and match, and exposes them to the UI.
/// Also implements the automation hooks used by the cross-platform test.
class Session extends ChangeNotifier {
  Session({required this.profile, required this.config}) {
    connection = Connection(
      url: _effectiveServerUrl,
      platform: config.platformName,
      name: profile.name,
      loadout: profile.loadout,
      token: profile.sessionToken,
    );
    connection.addListener(_onConnectionChanged);
    _sub = connection.messages.listen(_onMessage);
    profile.addListener(_onProfileChanged);
  }

  final Profile profile;
  final AppConfig config;
  late final Connection connection;

  /// Launch configuration wins in test mode so a persisted custom server
  /// cannot redirect an automated client away from the harness server.
  String get _effectiveServerUrl =>
      config.auto ? config.serverUrl : (profile.serverUrl ?? config.serverUrl);
  StreamSubscription<Map<String, Object?>>? _sub;
  Timer? _resultsTimer;

  /// How long the final moment stays on screen before the results screen.
  static const resultsDelay = Duration(seconds: 4);

  /// Lobby countdown when the room fills to `autostart` members, long enough
  /// for every client to render the full lobby before the bus phase.
  static const autoStartCountdown = Duration(seconds: 10);

  SessionPhase phase = SessionPhase.idle;
  RoomState? room;
  MatchClient? match;
  Map<String, Object?>? lastSummary;
  int lastXpGained = 0;
  String? notice;
  String? errorCode;
  bool autopilot = false;
  bool _autoJoined = false;
  bool _autoStarted = false;
  bool reported = false;

  /// Our player id inside the current room (from `roomState.you` / `you`).
  int myId = 0;

  RoomMember? get me {
    final r = room;
    if (r == null) return null;
    for (final m in r.members) {
      if (m.id == myId) return m;
    }
    return null;
  }

  bool get isHost => me?.host ?? false;
  bool get isReady => me?.ready ?? false;

  Future<void> start() async {
    await connection.connect();
  }

  void _onProfileChanged() {
    connection.name = profile.name;
    connection.loadout = profile.loadout;
    if (connection.isConnected) {
      connection.send({'t': Protocol.hello, 'name': profile.name});
      connection.send({
        't': Protocol.setLoadout,
        'ld': profile.loadout.toJson(),
      });
    }
    final url = _effectiveServerUrl;
    if (url != connection.url) {
      connection.url = url;
      connection.close().then((_) => connection.connect());
    }
  }

  void _onConnectionChanged() {
    if (connection.isConnected) {
      profile.saveSessionToken(connection.token);
      if (config.auto && !_autoJoined) {
        _autoJoined = true;
        _autoJoin();
      }
    }
    notifyListeners();
  }

  Future<void> _autoJoin() async {
    final code = config.roomCode;
    if (code == null) return;
    // First client creates the room with the deterministic seed; later ones
    // join. The server rejects a duplicate code so the fallback is safe.
    connection.send({
      't': Protocol.createRoom,
      'code': code,
      'mode': config.mode,
      'fast': config.fast,
      if (config.seed != null) 'seed': config.seed,
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (room == null) {
      connection.send({'t': Protocol.joinRoom, 'code': code});
    }
  }

  // ------------------------------------------------------------- lobby ops

  void createRoom({required SquadMode mode, bool? fast, int? seed}) {
    notice = null;
    connection.send({
      't': Protocol.createRoom,
      'mode': mode.name,
      // Omitted unless requested so the server's own default applies.
      if (fast ?? config.fast) 'fast': true,
      'seed': ?(seed ?? config.seed),
    });
  }

  void joinRoom(String code) {
    notice = null;
    connection.send({
      't': Protocol.joinRoom,
      'code': code.trim().toUpperCase(),
    });
  }

  void leaveRoom() {
    _resultsTimer?.cancel();
    connection.send({'t': Protocol.leaveRoom});
    room = null;
    match = null;
    phase = SessionPhase.idle;
    myId = 0;
    notifyListeners();
  }

  /// Leaving mid-match forfeits the player and returns to the hub.
  void leaveMatch() => leaveRoom();

  void setReady(bool v) => connection.send({'t': Protocol.ready, 'ready': v});

  void setMode(SquadMode m) =>
      connection.send({'t': 'setMode', 'mode': m.name});

  void startMatch({int? fill, int countdownMs = 3000}) => connection.send({
    't': Protocol.startMatch,
    'fill': ?fill,
    'countdownMs': countdownMs,
  });

  Future<void> setAutopilot(bool on) async {
    autopilot = on;
    await connection.testControl({'op': 'autopilot', 'on': on});
    notifyListeners();
  }

  void sendInput(Map<String, Object?> msg) => connection.send(msg);

  void clearNotice() {
    notice = null;
    errorCode = null;
    notifyListeners();
  }

  void backToLobby() {
    if (isHost) {
      connection.send({'t': 'returnToLobby'});
    }
    match = null;
    phase = room == null ? SessionPhase.idle : SessionPhase.lobby;
    notifyListeners();
  }

  // ------------------------------------------------------------- messages

  void _onMessage(Map<String, Object?> msg) {
    final t = msg['t'];
    switch (t) {
      case Protocol.roomState:
        room = RoomState(msg);
        final you = (msg['you'] as num?)?.toInt();
        if (you != null) myId = you;
        if (phase == SessionPhase.idle ||
            phase == SessionPhase.results &&
                room!.phase == 'lobby' &&
                match == null) {
          phase = SessionPhase.lobby;
        }
        if (config.auto) _maybeAutoStart();
        notifyListeners();
      case Protocol.matchStart:
        final mc = MatchClient(start: msg, localName: connection.name)
          ..setLocalId(myId);
        match = mc;
        phase = SessionPhase.match;
        reported = false;
        if (config.auto && !autopilot) setAutopilot(true);
        notifyListeners();
      case 'you':
        myId = (msg['id'] as num).toInt();
        match?.setLocalId(myId);
        notifyListeners();
      case Protocol.snapshot:
        match?.applySnapshot(msg);
      case Protocol.matchEnd:
        final summary = msg['summary'] as Map<String, Object?>;
        match?.setSummary(summary);
        lastSummary = summary;
        _recordProgress(summary);
        if (config.auto) _report(summary);
        _resultsTimer?.cancel();
        _resultsTimer = Timer(resultsDelay, () {
          if (match?.summary != summary) return;
          phase = SessionPhase.results;
          notifyListeners();
        });
        notifyListeners();
      case Protocol.error:
        errorCode = msg['code'] as String?;
        notice = msg['message'] as String?;
        if (errorCode == 'room_not_found' && config.auto && room == null) {
          // The create raced another client; join instead.
          connection.send({'t': Protocol.joinRoom, 'code': config.roomCode});
        }
        if (errorCode == ProtocolError.superseded) {
          // Our player now lives on another connection; this client starts
          // over as a new identity when it reconnects.
          _resultsTimer?.cancel();
          room = null;
          match = null;
          phase = SessionPhase.idle;
          myId = 0;
        }
        notifyListeners();
    }
  }

  void _maybeAutoStart() {
    final r = room;
    if (r == null || _autoStarted || config.autoStartPlayers <= 0) return;
    if (!isHost || r.phase != 'lobby') return;
    if (r.members.length >= config.autoStartPlayers) {
      _autoStarted = true;
      startMatch(
        fill: r.maxPlayers,
        countdownMs: autoStartCountdown.inMilliseconds,
      );
    }
  }

  Future<void> _recordProgress(Map<String, Object?> summary) async {
    final id = myId;
    final rows = (summary['players'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final mine = rows.where((r) => (r['id'] as num).toInt() == id).toList();
    if (mine.isEmpty) return;
    final row = mine.first;
    final won =
        summary['winnerTeam'] != null &&
        (summary['winnerTeam'] as num).toInt() == (row['team'] as num).toInt();
    lastXpGained = await profile.recordMatch(row, won: won);
    notifyListeners();
  }

  /// Test mode: send the received summary back so the harness can compare
  /// what every platform actually displayed.
  Future<void> _report(Map<String, Object?> summary) async {
    if (reported) return;
    reported = true;
    await connection.testControl({
      'op': 'report',
      'platform': config.platformName,
      'digest': MatchClient.digest(summary),
      'summary': jsonEncode(summary),
      'snapshots': match?.snapshotsReceived ?? 0,
      'test': config.testId,
    });
  }

  @override
  void dispose() {
    _resultsTimer?.cancel();
    _sub?.cancel();
    profile.removeListener(_onProfileChanged);
    connection.removeListener(_onConnectionChanged);
    connection.dispose();
    super.dispose();
  }
}
