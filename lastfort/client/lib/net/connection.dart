import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lastfort_core/lastfort_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionState { disconnected, connecting, connected, reconnecting }

/// JSON-over-WebSocket link to the Lastfort server with automatic reconnect.
/// The `hello`/`welcome` handshake runs on every (re)connection and reuses the
/// session token so the server can resume the same player mid-match.
class Connection extends ChangeNotifier {
  Connection({
    required this.url,
    required this.platform,
    required this.name,
    required this.loadout,
    this.token,
  });

  String url;
  final String platform;
  String name;
  Loadout loadout;
  String? token;

  ConnectionState state = ConnectionState.disconnected;
  String? lastError;
  int rttMs = 0;
  int serverOffsetMs = 0;
  int attempts = 0;

  final _messages = StreamController<Map<String, Object?>>.broadcast();
  Stream<Map<String, Object?>> get messages => _messages.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _closedByUser = false;
  bool _everConnected = false;
  Completer<void>? _welcome;

  bool get isConnected => state == ConnectionState.connected;

  Future<void> connect() async {
    _closedByUser = false;
    _reconnectTimer?.cancel();
    if (_channel != null) return;
    state = _everConnected
        ? ConnectionState.reconnecting
        : ConnectionState.connecting;
    lastError = null;
    notifyListeners();
    final welcome = _welcome = Completer<void>();
    try {
      final ch = WebSocketChannel.connect(Uri.parse(url));
      _channel = ch;
      // Subscribe before awaiting `ready` so a failed handshake surfaces via
      // `_onError` instead of an unhandled stream error.
      _sub = ch.stream.listen(_onData, onDone: _onDone, onError: _onError);
      await ch.ready.timeout(const Duration(seconds: 6));
      if (_channel != ch) return;
      _raw({
        't': Protocol.hello,
        'v': Protocol.version,
        'name': name,
        'platform': platform,
        'ld': loadout.toJson(),
        if (token != null) 'token': token,
      });
      await welcome.future.timeout(const Duration(seconds: 6));
    } on Object catch (e) {
      if (_channel == null && _reconnectTimer != null) return;
      lastError = _describe(e);
      _teardown();
      _scheduleReconnect();
    }
  }

  void send(Map<String, Object?> msg) {
    if (state != ConnectionState.connected) return;
    _raw(msg);
  }

  int _testId = 0;
  final Map<int, Completer<Map<String, Object?>>> _pendingTests = {};

  /// Sends a `testControl` op and resolves with its `testAck`.
  Future<Map<String, Object?>> testControl(Map<String, Object?> op) {
    final id = ++_testId;
    final c = Completer<Map<String, Object?>>();
    _pendingTests[id] = c;
    send({'t': Protocol.testControl, 'id': id, ...op});
    return c.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingTests.remove(id);
        return {'error': 'timeout'};
      },
    );
  }

  void _raw(Map<String, Object?> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } on Object catch (e) {
      lastError = _describe(e);
    }
  }

  void _onData(dynamic data) {
    if (data is! String) return;
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, Object?>) return;
    final t = decoded['t'];
    if (t == Protocol.welcome) {
      token = decoded['token'] as String?;
      name = decoded['name'] as String? ?? name;
      final serverTime = (decoded['serverTime'] as num?)?.toInt();
      if (serverTime != null) {
        serverOffsetMs = serverTime - DateTime.now().millisecondsSinceEpoch;
      }
      state = ConnectionState.connected;
      attempts = 0;
      _everConnected = true;
      _welcome?.complete();
      _welcome = null;
      _startPing();
      notifyListeners();
    } else if (t == Protocol.pong) {
      final sent = (decoded['c'] as num?)?.toInt();
      if (sent != null) {
        rttMs = DateTime.now().millisecondsSinceEpoch - sent;
        notifyListeners();
      }
    } else if (t == Protocol.testAck) {
      final id = (decoded['id'] as num?)?.toInt();
      final c = id == null ? null : _pendingTests.remove(id);
      c?.complete(decoded);
    } else if (t == Protocol.error) {
      lastError = decoded['message'] as String? ?? decoded['code'] as String?;
      // Another connection (e.g. a second browser tab) took over this token;
      // reconnect as a fresh identity instead of fighting over it.
      if (decoded['code'] == ProtocolError.superseded) token = null;
      notifyListeners();
    }
    _messages.add(decoded);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _raw({'t': Protocol.ping, 'c': DateTime.now().millisecondsSinceEpoch});
    });
  }

  void _onDone() {
    if (_closedByUser) return;
    lastError ??= 'Connection closed';
    _teardown();
    _scheduleReconnect();
  }

  void _onError(Object e) {
    if (_channel == null) return;
    lastError = _describe(e);
    _teardown();
    _scheduleReconnect();
  }

  void _teardown() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    final w = _welcome;
    if (w != null && !w.isCompleted) {
      w.completeError(StateError(lastError ?? 'closed'));
    }
    _welcome = null;
    state = _closedByUser
        ? ConnectionState.disconnected
        : (_everConnected
              ? ConnectionState.reconnecting
              : ConnectionState.disconnected);
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_closedByUser) return;
    attempts++;
    final delay = Duration(
      milliseconds: (400 * (1 << attempts.clamp(0, 5))).clamp(400, 8000),
    );
    state = ConnectionState.reconnecting;
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  /// Drops the socket without clearing the token; the next [connect] resumes.
  void simulateDrop() {
    _channel?.sink.close();
  }

  Future<void> close() async {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    state = ConnectionState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    close();
    _messages.close();
    super.dispose();
  }

  static String _describe(Object e) {
    if (e is TimeoutException) return 'Server did not answer';
    final s = e.toString();
    if (s.contains('refused') || s.contains('Failed host lookup')) {
      return 'Server unreachable';
    }
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }
}
