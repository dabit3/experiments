import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef Json = Map<String, Object?>;

enum ConnectionPhase { connecting, online, reconnecting, offline }

/// Auto-reconnecting JSON WebSocket. Emits decoded messages on [messages]
/// and phase changes on [phase]. Re-sends `hello` after each (re)connect so
/// the server can re-attach the session.
class Connection {
  Connection({
    required this.url,
    required this.helloBuilder,
    this.maxBackoff = const Duration(seconds: 8),
  });

  final String url;
  final Json Function() helloBuilder;
  final Duration maxBackoff;

  final ValueNotifier<ConnectionPhase> phase = ValueNotifier(
    ConnectionPhase.connecting,
  );
  final StreamController<Json> _messages = StreamController.broadcast();
  Stream<Json> get messages => _messages.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retry;
  Timer? _ping;
  int _attempt = 0;
  bool _closed = false;
  int _rttMs = 0;
  int _serverOffsetMs = 0;

  /// Last measured round-trip time.
  int get rttMs => _rttMs;

  /// Estimated `serverTime - localTime` in milliseconds.
  int get serverOffsetMs => _serverOffsetMs;

  Future<void> connect() async {
    if (_closed) return;
    _retry?.cancel();
    phase.value = _attempt == 0
        ? ConnectionPhase.connecting
        : ConnectionPhase.reconnecting;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      await channel.ready;
      _channel = channel;
      _sub = channel.stream.listen(
        _onData,
        onDone: _onClosed,
        onError: (Object _) => _onClosed(),
        cancelOnError: true,
      );
      send(helloBuilder());
      _attempt = 0;
      phase.value = ConnectionPhase.online;
      _startPing();
    } catch (_) {
      _onClosed();
    }
  }

  void _startPing() {
    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 10), (_) {
      send({
        'type': 'ping',
        'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });
    send({
      'type': 'ping',
      'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final message = decoded.cast<String, Object?>();
    if (message['type'] == 'pong') {
      final sent = int.tryParse(message['nonce'] as String? ?? '');
      final now = DateTime.now().millisecondsSinceEpoch;
      if (sent != null) {
        _rttMs = now - sent;
        final serverMs = (message['serverTimeMs'] as num?)?.toInt();
        if (serverMs != null) {
          _serverOffsetMs = serverMs - (sent + _rttMs ~/ 2);
        }
      }
    }
    _messages.add(message);
  }

  void _onClosed() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _ping?.cancel();
    if (_closed) {
      phase.value = ConnectionPhase.offline;
      return;
    }
    _attempt++;
    phase.value = _attempt >= 4
        ? ConnectionPhase.offline
        : ConnectionPhase.reconnecting;
    final backoffMs = min(
      maxBackoff.inMilliseconds,
      250 * pow(2, min(_attempt, 6)).toInt(),
    );
    _retry?.cancel();
    _retry = Timer(Duration(milliseconds: backoffMs), connect);
  }

  /// Skip the remaining backoff and try to connect immediately.
  void reconnectNow() {
    if (_channel != null || _closed) return;
    _retry?.cancel();
    connect();
  }

  bool send(Json message) {
    final channel = _channel;
    if (channel == null) return false;
    channel.sink.add(jsonEncode(message));
    return true;
  }

  /// Drops the socket without marking the connection closed; a reconnect
  /// follows automatically. Used to exercise the reconnect path in tests.
  void simulateDrop() {
    _channel?.sink.close();
  }

  Future<void> dispose() async {
    _closed = true;
    _retry?.cancel();
    _ping?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _messages.close();
    phase.dispose();
  }
}
