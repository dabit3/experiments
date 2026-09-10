import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:swapmate_core/swapmate_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { offline, connecting, online, reconnecting }

/// Connection-level error surfaced to the UI.
class ClientError {
  const ClientError(this.code, this.message, {this.ref});
  final String code;
  final String message;
  final String? ref;
}

/// Client-side mirror of the server state plus the WebSocket plumbing.
///
/// Every mutation notifies listeners; screens rebuild from [room], [game] and
/// [chats]. Reconnection is automatic with exponential backoff and the resume
/// token from the last `welcome` so a dropped socket keeps the player's seat.
class GameClient extends ChangeNotifier {
  GameClient({required this.platform});

  final String platform;

  String serverUrl = '';
  String name = '';
  String? testId;

  ConnectionStatus status = ConnectionStatus.offline;
  String? playerId;
  String? resumeToken;
  bool serverTestMode = false;
  RoomState? room;
  GameState? game;
  final List<ChatMessage> chats = [];
  ClientError? lastError;
  int latencyMs = 0;

  /// Offset between server clock and local clock so clocks tick smoothly.
  int _serverOffset = 0;

  final _events = StreamController<GameEvent>.broadcast();
  final _errors = StreamController<ClientError>.broadcast();
  final _chatStream = StreamController<ChatMessage>.broadcast();
  final _testCommands = StreamController<Map<String, dynamic>>.broadcast();

  Stream<GameEvent> get events => _events.stream;
  Stream<ClientError> get errors => _errors.stream;
  Stream<ChatMessage> get chatStream => _chatStream.stream;
  Stream<Map<String, dynamic>> get testCommands => _testCommands.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _wantConnection = false;

  bool get isOnline => status == ConnectionStatus.online;
  bool get inRoom => room != null;

  PlayerInfo? get me => playerId == null ? null : room?.byId(playerId!);
  Seat? get mySeat => me?.seat;
  bool get isHost => room != null && room!.hostId == playerId;
  bool get isSpectator => room != null && mySeat == null;

  /// Server-time "now" estimated from the last pong.
  int get serverNow => DateTime.now().millisecondsSinceEpoch + _serverOffset;

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  Future<void> connect({
    required String url,
    required String name,
    String? testId,
  }) async {
    serverUrl = url;
    this.name = name;
    this.testId = testId;
    _wantConnection = true;
    _attempt = 0;
    await _open();
  }

  Future<void> _open() async {
    _reconnectTimer?.cancel();
    await _teardownSocket();
    status = resumeToken == null
        ? ConnectionStatus.connecting
        : ConnectionStatus.reconnecting;
    lastError = null;
    notifyListeners();
    try {
      final ch = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel = ch;
      _sub = ch.stream.listen(
        _onData,
        onDone: _onClosed,
        onError: (_) => _onClosed(),
      );
      await ch.ready.timeout(const Duration(seconds: 6));
      _send(
        ClientMsg.hello(
          name: name,
          platform: platform,
          resumeToken: resumeToken,
          testId: testId,
        ),
      );
    } catch (e) {
      _fail('connect_failed', 'Could not reach $serverUrl');
      _onClosed();
    }
  }

  void disconnect() {
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _teardownSocket();
    status = ConnectionStatus.offline;
    room = null;
    game = null;
    chats.clear();
    playerId = null;
    resumeToken = null;
    notifyListeners();
  }

  Future<void> _teardownSocket() async {
    _pingTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      unawaited(ch.sink.close());
    }
  }

  void _onClosed() {
    if (_channel == null && !_wantConnection) return;
    _channel = null;
    _sub = null;
    _pingTimer?.cancel();
    if (!_wantConnection) {
      status = ConnectionStatus.offline;
      notifyListeners();
      return;
    }
    status = ConnectionStatus.reconnecting;
    notifyListeners();
    final delay = Duration(
      milliseconds: min(8000, 400 * (1 << min(_attempt, 4))),
    );
    _attempt++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _open);
  }

  void _fail(String code, String message, {String? ref}) {
    lastError = ClientError(code, message, ref: ref);
    _errors.add(lastError!);
    notifyListeners();
  }

  void _send(Map<String, dynamic> msg) {
    final ch = _channel;
    if (ch == null) return;
    ch.sink.add(jsonEncode(msg));
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _send(ClientMsg.ping(DateTime.now().millisecondsSinceEpoch));
    });
    _send(ClientMsg.ping(DateTime.now().millisecondsSinceEpoch));
  }

  void _onData(dynamic data) {
    final msg = jsonDecode(data as String) as Map<String, dynamic>;
    switch (msg['type'] as String) {
      case MsgType.welcome:
        playerId = msg['playerId'] as String;
        resumeToken = msg['resumeToken'] as String;
        serverTestMode = msg['testMode'] as bool? ?? false;
        _serverOffset =
            (msg['serverTime'] as int) - DateTime.now().millisecondsSinceEpoch;
        status = ConnectionStatus.online;
        _attempt = 0;
        if (msg['room'] == null) {
          room = null;
          game = null;
        }
        _startPing();
      case MsgType.pong:
        final sent = msg['t'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        latencyMs = now - sent;
        _serverOffset = (msg['serverTime'] as int) + latencyMs ~/ 2 - now;
      case MsgType.roomState:
        final r = msg['room'];
        final wasIn = room != null;
        room = r == null ? null : RoomState.fromJson(r as Map<String, dynamic>);
        if (room == null && wasIn) {
          game = null;
          chats.clear();
        }
      case MsgType.gameState:
        game = GameState.fromJson(msg['game'] as Map<String, dynamic>);
      case MsgType.gameEvent:
        _events.add(GameEvent.fromJson(msg['event'] as Map<String, dynamic>));
        return;
      case MsgType.chatMessage:
        final c = ChatMessage.fromJson(msg['message'] as Map<String, dynamic>);
        chats.add(c);
        if (chats.length > 200) chats.removeAt(0);
        _chatStream.add(c);
      case MsgType.error:
        _fail(
          msg['code'] as String,
          msg['message'] as String,
          ref: msg['ref'] as String?,
        );
        return;
      case MsgType.testCommand:
        _testCommands.add(msg);
        return;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  void createRoom({
    TimeControl? timeControl,
    bool fillBots = false,
    String? code,
  }) {
    chats.clear();
    _send(
      ClientMsg.roomCreate(
        timeControl: timeControl,
        fillBots: fillBots,
        code: code,
      ),
    );
  }

  void joinRoom(String code, {bool spectate = false}) {
    chats.clear();
    _send(ClientMsg.roomJoin(code, spectate: spectate));
  }

  void leaveRoom() {
    _send(ClientMsg.roomLeave());
    room = null;
    game = null;
    chats.clear();
    notifyListeners();
  }

  void takeSeat(Seat? seat) => _send(ClientMsg.roomSeat(seat));
  void setBot(Seat seat, {required bool add}) =>
      _send(ClientMsg.roomBot(seat, add: add));
  void setReady(bool ready) => _send(ClientMsg.roomReady(ready));
  void startMatch() => _send(ClientMsg.roomStart());
  void setTimeControl(TimeControl tc) => _send(ClientMsg.roomTimeControl(tc));
  void rematch() => _send(ClientMsg.roomRematch());
  void move(Move m) => _send(ClientMsg.gameMove(m));
  void premove(Move? m) => _send(ClientMsg.gamePremove(m));
  void resign() => _send(ClientMsg.gameResign());
  void draw(String action) => _send(ClientMsg.gameDraw(action));
  void quickChat(QuickChat q) => _send(ClientMsg.chatQuick(q));
  void chat(String text) => _send(ClientMsg.chatText(text));
  void testResult(String id, Map<String, dynamic> payload) =>
      _send(ClientMsg.testResult(id, payload));

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _teardownSocket();
    _events.close();
    _errors.close();
    _chatStream.close();
    _testCommands.close();
    super.dispose();
  }
}
