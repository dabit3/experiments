import 'dart:convert';

import 'package:lastfort_core/lastfort_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'room.dart';

/// One WebSocket connection. Identity (token) survives reconnects; the
/// socket does not.
class Client {
  Client(this.channel, this.token);

  WebSocketChannel? channel;
  final String token;
  String name = 'Player';
  String platform = 'unknown';
  Loadout loadout = const Loadout();
  Room? room;
  final List<InputFrame> pendingInputs = [];
  int sent = 0;
  bool helloDone = false;

  bool get connected => channel != null;

  void send(Map<String, Object?> msg) {
    final ch = channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(msg));
      sent++;
    } catch (_) {
      channel = null;
    }
  }

  void error(String code, String message) =>
      send({'t': Protocol.error, 'code': code, 'message': message});
}
