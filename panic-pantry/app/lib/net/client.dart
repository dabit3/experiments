import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsets, Size;
import 'package:panic_pantry_core/panic_pantry_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../widgets/platform_mark.dart';

enum ConnState { idle, connecting, connected, reconnecting, failed }

/// One step of a scripted test input: hold [input] for [ticks] server ticks.
class TestStep {
  const TestStep(this.input, this.ticks);
  final ChefInput input;
  final int ticks;

  static TestStep fromJson(Map<String, dynamic> j) =>
      TestStep(ChefInput.fromJson(j), ((j['ticks'] ?? 1) as num).toInt());
}

/// Lightweight room roster as broadcast by the server.
class RoomInfo {
  RoomInfo(this.json);
  final Map<String, dynamic> json;

  String get code => json['code'] as String;
  int get seed => json['seed'] as int;
  String get levelId => json['level'] as String;
  String? get hostId => json['hostId'] as String?;
  String get phase => json['phase'] as String;
  int get match => json['match'] as int;
  int get maxPlayers => json['maxPlayers'] as int;
  Map<String, dynamic>? get results => json['results'] as Map<String, dynamic>?;
  List<Map<String, dynamic>> get players => (json['players'] as List).cast<Map<String, dynamic>>();
}

/// Client-side session: connection, lobby state, authoritative snapshots and
/// the automation channel used by the cross-platform e2e test.
class GameClient extends ChangeNotifier {
  GameClient({required this.platform});

  final String platform;

  ConnState conn = ConnState.idle;
  String? lastError;
  String? serverUrl;
  String name = 'Chef';
  String? playerId;
  String? token;
  int rttMs = 0;

  RoomInfo? room;
  GameState? game;
  Map<String, dynamic>? results;
  int resultsMatch = -1;

  /// Positions from the previous snapshot for render interpolation.
  final Map<String, (double, double)> prevPos = {};
  DateTime lastSnapshotAt = DateTime.now();
  double tickSeconds = Rules.tickSeconds;

  /// Transient one-shot events since the last snapshot (for FX/sounds).
  final List<GameEvent> pendingEvents = [];

  /// Toast-style messages for the UI.
  final StreamController<String> toasts = StreamController.broadcast();

  /// Scripted test inputs currently being played back.
  final List<TestStep> testQueue = [];
  int _testTicksLeft = 0;
  bool get automated => testQueue.isNotEmpty || _testTicksLeft > 0;

  /// Commands from the harness that the UI must act on (e.g. `theme`).
  final StreamController<Map<String, dynamic>> commands = StreamController.broadcast();

  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _inputTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _closedByUser = false;
  ChefInput _held = ChefInput.none;
  bool _heldDirty = false;
  String _screen = 'home';
  DateTime _screenSince = DateTime.now();
  int _framesSinceScreen = 0;
  Map<String, dynamic> _view = const {};

  bool get isHost => room != null && room!.hostId == playerId;
  bool get inRoom => room != null;
  Chef? get me => game?.chefById(playerId ?? '');

  /// The UI reports which screen it's showing so test reports can include it.
  void setScreen(String s) {
    if (s == _screen) return;
    _screen = s;
    _screenSince = DateTime.now();
    _framesSinceScreen = 0;
  }

  /// Called once per rendered frame; together with [setScreen] this lets the
  /// harness tell a screen that has actually been drawn from one that was
  /// merely built (software-rendered emulators lag several frames behind).
  void noteFrame() {
    _framesSinceScreen++;
  }

  /// Logical viewport, pixel ratio and safe-area padding, so the visual-parity
  /// harness can size the web reference to match this device exactly.
  void setViewport(Size size, double dpr, EdgeInsets padding) {
    _view = {
      'width': size.width,
      'height': size.height,
      'dpr': dpr,
      'padding': {'top': padding.top, 'bottom': padding.bottom, 'left': padding.left, 'right': padding.right},
    };
  }

  /// Opens the connection. [retries] extra attempts are made when the first
  /// handshake fails (used by automated launches on slow devices).
  Future<void> connect(String url, {String? withName, int retries = 0}) async {
    _closedByUser = false;
    serverUrl = url;
    if (withName != null) name = withName;
    _reconnectTimer?.cancel();
    for (var attempt = 0; ; attempt++) {
      await _open(reconnect: false);
      if (conn != ConnState.failed || attempt >= retries || _closedByUser) return;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _open({required bool reconnect}) async {
    conn = reconnect ? ConnState.reconnecting : ConnState.connecting;
    lastError = null;
    notifyListeners();
    try {
      final ch = WebSocketChannel.connect(Uri.parse(serverUrl!));
      await ch.ready.timeout(const Duration(seconds: 15));
      _ch = ch;
      _sub = ch.stream.listen(_onMessage, onDone: _onClosed, onError: (Object e) => _onClosed());
      _send({'type': Msg.hello, 'name': name, 'platform': platform, if (token != null) 'token': token});
    } catch (e) {
      lastError = 'Could not reach $serverUrl';
      debugPrint('panic_pantry: connect failed: $e');
      conn = reconnect ? ConnState.reconnecting : ConnState.failed;
      notifyListeners();
      if (reconnect) _scheduleReconnect();
    }
  }

  void _onClosed() {
    _sub?.cancel();
    _sub = null;
    _ch = null;
    _pingTimer?.cancel();
    _inputTimer?.cancel();
    if (_closedByUser) {
      conn = ConnState.idle;
      notifyListeners();
      return;
    }
    conn = ConnState.reconnecting;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = Duration(milliseconds: math.min(8000, 400 * (1 << math.min(_reconnectAttempt, 4))));
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () => _open(reconnect: true));
  }

  void disconnect() {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _ch?.sink.close();
    _onClosed();
    room = null;
    game = null;
    results = null;
    notifyListeners();
  }

  void _send(Map<String, dynamic> m) {
    final ch = _ch;
    if (ch == null) return;
    ch.sink.add(jsonEncode(m));
  }

  void _onMessage(dynamic raw) {
    final m = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (m['type']) {
      case Msg.welcome:
        playerId = m['playerId'] as String;
        token = m['token'] as String;
        tickSeconds = ((m['tickSeconds'] ?? Rules.tickSeconds) as num).toDouble();
        conn = ConnState.connected;
        _reconnectAttempt = 0;
        _pingTimer?.cancel();
        _pingTimer = Timer.periodic(
          const Duration(seconds: 2),
          (_) => _send({'type': Msg.ping, 't': DateTime.now().millisecondsSinceEpoch}),
        );
        _inputTimer?.cancel();
        _inputTimer = Timer.periodic(Duration(microseconds: (tickSeconds * 1e6).round()), (_) => _inputTick());
        if (m['resumed'] == true) toasts.add('Reconnected — welcome back!');
      case Msg.pong:
        rttMs = DateTime.now().millisecondsSinceEpoch - (m['t'] as int);
      case Msg.roomState:
        final r = m['room'] as Map<String, dynamic>?;
        if (r == null) {
          room = null;
          game = null;
          results = null;
        } else {
          final prev = room;
          room = RoomInfo(r);
          if (prev == null) toasts.add('Joined kitchen ${room!.code}');
          if (room!.phase == 'lobby' && game != null && game!.phase == Phase.finished) {
            game = null;
          }
          if (room!.phase == 'lobby') {
            results = null;
          }
        }
      case Msg.snapshot:
        _applySnapshot(m['state'] as Map<String, dynamic>);
      case Msg.results:
        results = m['results'] as Map<String, dynamic>;
        resultsMatch = (m['match'] as num).toInt();
      case Msg.error:
        lastError = m['message'] as String? ?? 'Something went wrong';
        toasts.add(lastError!);
      case Msg.testInput:
        for (final s in (m['steps'] as List).cast<Map<String, dynamic>>()) {
          testQueue.add(TestStep.fromJson(s));
        }
      case Msg.testCommand:
        _onTestCommand(m);
    }
    notifyListeners();
  }

  void _applySnapshot(Map<String, dynamic> s) {
    final r = room;
    if (r == null) return;
    var g = game;
    if (g == null || g.level.id != r.levelId) {
      g = GameState(levelById(r.levelId), playerCount: 4);
      game = g;
    }
    prevPos
      ..clear()
      ..addEntries(g.chefs.map((c) => MapEntry(c.id, (c.x, c.y))));
    g.applySnapshot(s);
    lastSnapshotAt = DateTime.now();
    pendingEvents.addAll(g.events);
  }

  /// 0..1 progress between the last two snapshots, for smooth rendering.
  double get interpolation {
    final dt = DateTime.now().difference(lastSnapshotAt).inMicroseconds / 1e6;
    return (dt / tickSeconds).clamp(0.0, 1.0);
  }

  // ---- Lobby actions -------------------------------------------------------

  void createRoom({String? level}) => _send({'type': Msg.roomCreate, 'level': ?level});
  void joinRoom(String code) => _send({'type': Msg.roomJoin, 'code': code.trim().toUpperCase()});
  void leaveRoom() {
    _send({'type': Msg.roomLeave});
    room = null;
    game = null;
    results = null;
    notifyListeners();
  }

  void setReady(bool ready) => _send({'type': Msg.roomReady, 'ready': ready});
  void setLevel(String id) => _send({'type': Msg.roomSetLevel, 'level': id});
  void addBot() => _send({'type': Msg.roomAddBot});
  void removeBot() => _send({'type': Msg.roomRemoveBot});
  void start() => _send({'type': Msg.roomStart});
  void rematch() => _send({'type': Msg.roomRematch});

  // ---- Gameplay input ------------------------------------------------------

  /// Continuous input (movement) is sampled every tick; edge-triggered flags
  /// are sent immediately so button taps are never lost between ticks.
  void setMovement(double dx, double dy) {
    if (_held.dx == dx && _held.dy == dy) return;
    _held = ChefInput(dx: dx, dy: dy);
    _heldDirty = true;
  }

  void press({bool interact = false, bool action = false, bool dash = false, int? emote}) {
    _send({
      'type': Msg.input,
      ...ChefInput(dx: _held.dx, dy: _held.dy, interact: interact, action: action, dash: dash, emote: emote).toJson(),
    });
  }

  void _inputTick() {
    if (_testTicksLeft > 0 || testQueue.isNotEmpty) {
      if (_testTicksLeft == 0) {
        final step = testQueue.removeAt(0);
        _testTicksLeft = step.ticks;
        _held = ChefInput(dx: step.input.dx, dy: step.input.dy);
        _send({'type': Msg.input, ...step.input.toJson()});
        notifyListeners();
      } else {
        _send({'type': Msg.input, ...ChefInput(dx: _held.dx, dy: _held.dy).toJson()});
      }
      _testTicksLeft--;
      if (_testTicksLeft == 0 && testQueue.isEmpty) {
        _held = ChefInput.none;
        _send({'type': Msg.input});
        notifyListeners();
      }
      return;
    }
    if (_heldDirty || !_held.isIdle) {
      _heldDirty = false;
      _send({'type': Msg.input, ...ChefInput(dx: _held.dx, dy: _held.dy).toJson()});
    }
  }

  // ---- Test harness --------------------------------------------------------

  void _onTestCommand(Map<String, dynamic> m) {
    switch (m['cmd']) {
      case 'report':
        _send({
          'type': Msg.testReport,
          'platform': platform,
          'screen': _screen,
          'screenAgeMs': DateTime.now().difference(_screenSince).inMilliseconds,
          'framesSinceScreen': _framesSinceScreen,
          'view': _view,
          'platformRegions': PlatformMark.toJson(),
          if (room != null) 'code': room!.code,
          'phase': game?.phase.name ?? room?.phase ?? 'none',
          'tick': game?.tick,
          'score': game?.score,
          'stars': game?.stars,
          'results': results,
          'resultsMatch': resultsMatch,
          'lastError': lastError,
          'rtt': rttMs,
          'automated': automated,
        });
      case 'ready':
        setReady(m['ready'] != false);
      case 'start':
        start();
      case 'rematch':
        rematch();
      case 'addBot':
        addBot();
      case 'setLevel':
        setLevel(m['level'] as String);
      case 'emote':
        press(emote: (m['index'] as num).toInt());
      case 'clearInput':
        testQueue.clear();
        _testTicksLeft = 0;
        _held = ChefInput.none;
        _send({'type': Msg.input});
      default:
        commands.add(m);
    }
  }

  @override
  void dispose() {
    _closedByUser = true;
    _pingTimer?.cancel();
    _inputTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _ch?.sink.close();
    toasts.close();
    commands.close();
    super.dispose();
  }
}
