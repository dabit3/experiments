import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../game/session.dart';

enum ConnState { offline, connecting, online, reconnecting, failed }

/// Lobby snapshot as broadcast by the server.
class RoomView {
  RoomView({
    required this.code,
    required this.hostId,
    required this.status,
    required this.settings,
    required this.players,
    required this.raceIndex,
    required this.totalRaces,
    required this.standings,
  });

  factory RoomView.fromJson(Map<String, dynamic> j) => RoomView(
    code: j['code'] as String,
    hostId: j['hostId'] as String?,
    status: j['status'] as String,
    settings: RoomSettings.fromJson((j['settings'] as Map).cast<String, dynamic>()),
    players: [for (final p in j['players'] as List) PlayerInfo.fromJson((p as Map).cast<String, dynamic>())],
    raceIndex: j['raceIndex'] as int,
    totalRaces: j['totalRaces'] as int,
    standings: [for (final s in (j['standings'] as List?) ?? const []) Standing.fromJson((s as Map).cast<String, dynamic>())],
  );

  final String code;
  final String? hostId;
  final String status;
  final RoomSettings settings;
  final List<PlayerInfo> players;
  final int raceIndex;
  final int totalRaces;
  final List<Standing> standings;
}

class RaceOutcome {
  RaceOutcome({
    required this.raceIndex,
    required this.totalRaces,
    required this.trackId,
    required this.results,
    required this.standings,
    required this.isLast,
    required this.nextInMs,
  });
  final int raceIndex;
  final int totalRaces;
  final String trackId;
  final List<RaceResult> results;
  final List<Standing> standings;
  final bool isLast;
  final int nextInMs;
}

class MatchOutcome {
  MatchOutcome({required this.standings, required this.hash, required this.races});
  final List<Standing> standings;
  final String hash;
  final List<({String trackId, List<RaceResult> results})> races;
}

/// WebSocket client for the Nitro Tots server: connection lifecycle,
/// reconnection, lobby state and the live [NetSession] during a race.
class NetClient extends ChangeNotifier {
  NetClient({required this.platform});

  final String platform;
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _sub;
  ConnState state = ConnState.offline;
  String? lastError;
  String? playerId;
  String? token;
  String url = '';
  int rttMs = 0;
  int _attempt = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _wantConnected = false;
  Map<String, dynamic> _profile = {};

  RoomView? room;
  NetSession? session;
  final ValueNotifier<RaceOutcome?> raceOutcome = ValueNotifier(null);
  final ValueNotifier<MatchOutcome?> matchOutcome = ValueNotifier(null);
  final StreamController<Map<String, dynamic>> _errors = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _events = StreamController.broadcast();

  Stream<Map<String, dynamic>> get errors => _errors.stream;

  /// Raw server messages, for screens that need specific transitions.
  Stream<Map<String, dynamic>> get events => _events.stream;

  void Function(String id, String token)? onCredentials;

  bool get isHost => room != null && room!.hostId == playerId;

  Future<void> connect(String serverUrl, {required String name, required String character, required String kart, String? resumeId, String? resumeToken}) async {
    url = serverUrl;
    _profile = {'name': name, 'character': character, 'kart': kart};
    playerId = resumeId;
    token = resumeToken;
    _wantConnected = true;
    _attempt = 0;
    await _open();
  }

  Future<void> _open() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    state = _attempt == 0 ? ConnState.connecting : ConnState.reconnecting;
    lastError = null;
    notifyListeners();
    try {
      final ws = WebSocketChannel.connect(Uri.parse(url));
      await ws.ready.timeout(const Duration(seconds: 6));
      _ws = ws;
      _sub = ws.stream.listen(
        _onData,
        onDone: _onClosed,
        onError: (Object e) => _onClosed(error: e),
      );
      if (playerId != null && token != null) {
        send({'type': Msg.resume, 'playerId': playerId, 'token': token});
      } else {
        send({'type': Msg.hello, 'v': protocolVersion, ...(_profile), 'platform': platform});
      }
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 3), (_) => send({'type': Msg.ping, 't': DateTime.now().millisecondsSinceEpoch}));
    } catch (e) {
      lastError = 'Could not reach $url';
      _onClosed(error: e);
    }
  }

  void _onClosed({Object? error}) {
    _pingTimer?.cancel();
    _ws = null;
    if (!_wantConnected) {
      state = ConnState.offline;
      notifyListeners();
      return;
    }
    _attempt++;
    if (_attempt > 8) {
      state = ConnState.failed;
      lastError ??= 'Lost connection to the server.';
      notifyListeners();
      return;
    }
    state = ConnState.reconnecting;
    if (error != null) lastError ??= 'Connection dropped. Reconnecting…';
    notifyListeners();
    final delay = Duration(milliseconds: math.min(8000, 400 * (1 << (_attempt - 1))));
    _reconnectTimer = Timer(delay, _open);
  }

  /// Manual retry after [ConnState.failed].
  Future<void> retry() async {
    _attempt = 0;
    _wantConnected = true;
    await _open();
  }

  Future<void> disconnect() async {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    final subscription = _sub;
    final socket = _ws;
    _sub = null;
    _ws = null;
    room = null;
    session?.dispose();
    session = null;
    state = ConnState.offline;
    notifyListeners();
    await subscription?.cancel();
    await socket?.sink.close();
  }

  void send(Map<String, dynamic> msg) {
    final ws = _ws;
    if (ws == null) return;
    ws.sink.add(jsonEncode(msg));
  }

  // Lobby actions -------------------------------------------------------------

  void createRoom(RoomSettings settings, {String? code}) => send({'type': Msg.createRoom, 'settings': settings.toJson(), 'code': ?code});
  void joinRoom(String code) => send({'type': Msg.joinRoom, 'code': code.toUpperCase().trim()});
  void leaveRoom() {
    send({'type': Msg.leaveRoom});
    room = null;
    session?.dispose();
    session = null;
    raceOutcome.value = null;
    matchOutcome.value = null;
    notifyListeners();
  }

  void setReady(bool ready) => send({'type': Msg.setReady, 'ready': ready});
  void updateSettings(Map<String, dynamic> patch) => send({'type': Msg.updateSettings, 'settings': patch});
  void updateProfile({String? name, String? character, String? kart}) {
    _profile = {..._profile, 'name': ?name, 'character': ?character, 'kart': ?kart};
    send({'type': Msg.updateProfile, 'name': ?name, 'character': ?character, 'kart': ?kart});
  }

  void startMatch() => send({'type': Msg.startMatch});
  void nextRace() => send({'type': Msg.nextRace});
  void testReport(Map<String, dynamic> report) => send({'type': Msg.testReport, ...report});

  // Inbound -------------------------------------------------------------------

  void _onData(dynamic data) {
    final m = jsonDecode(data as String) as Map<String, dynamic>;
    final type = m['type'] as String?;
    switch (type) {
      case Msg.welcome:
        playerId = m['playerId'] as String;
        token = m['token'] as String;
        onCredentials?.call(playerId!, token!);
        state = ConnState.online;
        _attempt = 0;
        lastError = null;
        if (m['resumed'] == true) {
          send({'type': Msg.updateProfile, ..._profile});
        } else {
          room = null;
        }
        notifyListeners();
      case Msg.pong:
        final t = m['t'] as int?;
        if (t != null) rttMs = DateTime.now().millisecondsSinceEpoch - t;
      case Msg.roomState:
        room = RoomView.fromJson(m);
        if (room!.status == 'lobby' && session != null && session!.finished) {
          // Match ended; the results screen owns the transition back.
        }
        notifyListeners();
      case Msg.matchStart:
        raceOutcome.value = null;
        matchOutcome.value = null;
        session?.dispose();
        session = NetSession.fromMatchStart(this, m, playerId!);
        notifyListeners();
      case Msg.snapshot:
        session?.onSnapshot(m);
      case Msg.raceFinished:
        raceOutcome.value = RaceOutcome(
          raceIndex: m['raceIndex'] as int,
          totalRaces: m['totalRaces'] as int,
          trackId: m['trackId'] as String,
          results: [for (final r in m['results'] as List) RaceResult.fromJson((r as Map).cast<String, dynamic>())],
          standings: [for (final s in m['standings'] as List) Standing.fromJson((s as Map).cast<String, dynamic>())],
          isLast: m['isLast'] == true,
          nextInMs: m['nextInMs'] as int,
        );
        notifyListeners();
      case Msg.matchOver:
        matchOutcome.value = MatchOutcome(
          standings: [for (final s in m['standings'] as List) Standing.fromJson((s as Map).cast<String, dynamic>())],
          hash: m['hash'] as String,
          races: [
            for (final r in m['races'] as List)
              (
                trackId: (r as Map)['trackId'] as String,
                results: [for (final x in r['results'] as List) RaceResult.fromJson((x as Map).cast<String, dynamic>())],
              ),
          ],
        );
        notifyListeners();
      case Msg.error:
        lastError = m['message'] as String?;
        if (m['code'] == 'resume_failed') {
          // Fall back to a fresh identity.
          playerId = null;
          token = null;
          onCredentials?.call('', '');
          send({'type': Msg.hello, 'v': protocolVersion, ..._profile, 'platform': platform});
        }
        _errors.add(m);
        notifyListeners();
      case Msg.playerLeft:
        break;
    }
    _events.add(m);
  }

  @override
  void dispose() {
    disconnect();
    _errors.close();
    _events.close();
    super.dispose();
  }
}

/// Server-driven race: predicts the local kart, interpolates everyone else.
class NetSession extends RaceSession {
  NetSession._(this.client, this.sim, this.info, this.localSlot) {
    capturePoses();
  }

  factory NetSession.fromMatchStart(NetClient client, Map<String, dynamic> m, String playerId) {
    final racers = [
      for (final r in (m['racers'] as List).cast<Map<String, dynamic>>())
        Racer(
          slot: r['slot'] as int,
          playerId: r['playerId'] as String,
          name: r['name'] as String,
          characterId: r['character'] as String,
          kartId: r['kart'] as String,
          isBot: r['bot'] as bool,
          platform: r['platform'] as String,
        ),
    ];
    final mode = GameMode.values.byName(m['mode'] as String);
    final sim = RaceSim(
      track: trackById(m['trackId'] as String),
      racers: racers,
      seed: m['seed'] as int,
      laps: m['laps'] as int,
      mode: mode,
      battleSeconds: m['battleSeconds'] as int,
    );
    final mine = racers.where((r) => r.playerId == playerId).firstOrNull;
    final info = MatchInfo(
      trackId: m['trackId'] as String,
      laps: m['laps'] as int,
      mode: mode,
      raceIndex: m['raceIndex'] as int,
      totalRaces: m['totalRaces'] as int,
      battleSeconds: m['battleSeconds'] as int,
      online: true,
    );
    return NetSession._(client, sim, info, mine?.slot ?? -1);
  }

  final NetClient client;
  @override
  final RaceSim sim;
  @override
  final MatchInfo info;
  @override
  final int localSlot;

  final List<(int, KartInput)> _pending = [];
  double _acc = 0;
  double _elapsed = 0;
  int _snapshotAtUs = 0;
  int _snapshotIntervalUs = 66000;
  int snapshots = 0;
  V2 _localErr = V2.zero;
  double _localErrHeading = 0;
  bool _disposed = false;

  @override
  double get elapsed => _elapsed;

  static const _maxPending = 10;

  @override
  void advance(double dt) {
    if (_disposed) return;
    _elapsed += dt;
    if (finished || localSlot < 0) {
      alpha = 1;
      return;
    }
    _acc += math.min(dt, 0.25);
    while (_acc >= tickDt) {
      _acc -= tickDt;
      final tickInput = consumeInput();
      if (sim.phase == RacePhase.racing) {
        final tick = sim.tick + 1;
        _pending.add((tick, tickInput));
        if (_pending.length > _maxPending) _pending.removeAt(0);
        // Snapshot-derived poses for remote karts; predicted pose for me.
        _captureLocal();
        sim.predictStep(localSlot, tickInput);
      }
      client.send({'type': Msg.input, 'tick': sim.tick, ...tickInput.toJson()});
    }
    alpha = _acc / tickDt;
    // Bleed off reconciliation error smoothly.
    final k = math.pow(0.001, dt * 6).toDouble();
    _localErr = _localErr * k;
    _localErrHeading *= k;
  }

  void _captureLocal() {
    final me = local;
    if (me == null) return;
    final c = currPoses[me.slot];
    if (c == null) {
      prevPoses[me.slot] = RenderPose(me.pos, me.heading);
      currPoses[me.slot] = RenderPose(me.pos, me.heading);
    } else {
      prevPoses[me.slot] = RenderPose(c.pos, c.heading);
      c.pos = me.pos;
      c.heading = me.heading;
    }
  }

  void onSnapshot(Map<String, dynamic> m) {
    if (_disposed) return;
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    if (_snapshotAtUs != 0) {
      final gap = nowUs - _snapshotAtUs;
      // Track the observed cadence, resisting outliers.
      _snapshotIntervalUs = (_snapshotIntervalUs * 0.8 + gap.clamp(33000, 200000) * 0.2).round();
    }
    _snapshotAtUs = nowUs;
    snapshots++;

    final me = local;
    final beforePos = me?.pos ?? V2.zero;
    final beforeHeading = me?.heading ?? 0;

    // Remote karts: previous render pose is the current rendered spot so they
    // glide to the new server position over one snapshot interval.
    for (final r in sim.racers) {
      if (r.slot == localSlot) continue;
      final rendered = poseOf(r);
      prevPoses[r.slot] = RenderPose(rendered.pos, rendered.heading);
    }

    applySnapshot(sim, m);
    frameEvents.addAll(sim.events);

    for (final r in sim.racers) {
      if (r.slot == localSlot) continue;
      currPoses[r.slot] = RenderPose(r.pos, r.heading);
    }

    // Reconcile: drop acknowledged inputs and replay the rest.
    final acks = (m['acks'] as Map?)?.cast<String, dynamic>() ?? const {};
    final ack = (acks['$localSlot'] as num?)?.toInt() ?? -1;
    _pending.removeWhere((p) => p.$1 <= ack);
    if (me != null && sim.phase == RacePhase.racing) {
      for (final p in _pending) {
        sim.predictStep(localSlot, p.$2);
      }
      // Fold the correction into a decaying visual offset instead of snapping.
      final after = local!;
      final jump = after.pos - beforePos;
      if (jump.length < 40) {
        _localErr = _localErr + jump;
        _localErrHeading += wrapAngle(after.heading - beforeHeading);
      } else {
        _localErr = V2.zero;
        _localErrHeading = 0;
      }
      prevPoses[localSlot] = RenderPose(after.pos, after.heading);
      currPoses[localSlot] = RenderPose(after.pos, after.heading);
    }

    if (sim.phase == RacePhase.finished && results.value == null) {
      results.value = sim.results;
    }
    notifyListeners();
  }

  @override
  RenderPose poseOf(Racer r) {
    if (r.slot == localSlot) {
      final p = interpolated(r);
      return RenderPose(p.pos - _localErr, p.heading - _localErrHeading);
    }
    final p = prevPoses[r.slot];
    final c = currPoses[r.slot];
    if (p == null || c == null) return RenderPose(r.pos, r.heading);
    if (p.pos.distanceTo(c.pos) > 80) return RenderPose(c.pos, c.heading);
    final t = ((DateTime.now().microsecondsSinceEpoch - _snapshotAtUs) / _snapshotIntervalUs).clamp(0.0, 1.0);
    return RenderPose(V2(lerpD(p.pos.x, c.pos.x, t), lerpD(p.pos.y, c.pos.y, t)), p.heading + wrapAngle(c.heading - p.heading) * t);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
