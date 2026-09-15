import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitro_core/nitro_core.dart';
import 'package:nitro_tots/net/client.dart';

void main() {
  test('Resuming an identity sends the current Garage profile before room actions', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = NetClient(platform: 'test');
    final packets = <Map<String, dynamic>>[];
    final created = Completer<void>();
    WebSocket? socket;
    addTearDown(() async {
      await client.disconnect();
      await socket?.close();
      await server.close(force: true);
    });
    server.transform(WebSocketTransformer()).listen((connection) {
      socket = connection;
      connection.listen((data) {
        final packet = jsonDecode(data as String) as Map<String, dynamic>;
        packets.add(packet);
        if (packet['type'] == Msg.resume) {
          connection.add(jsonEncode({'type': Msg.welcome, 'playerId': 'test-player', 'token': 'fixture-token', 'resumed': true}));
        } else if (packet['type'] == Msg.createRoom) {
          created.complete();
        }
      });
    });
    client.addListener(() {
      if (client.state == ConnState.online) client.createRoom(const RoomSettings());
    });
    await client.connect(
      'ws://127.0.0.1:${server.port}/ws',
      name: 'arcade qa',
      character: 'rocco',
      kart: 'bubble',
      resumeId: 'test-player',
      resumeToken: 'fixture-token',
    );
    await created.future.timeout(const Duration(seconds: 5));
    expect(packets.map((packet) => packet['type']), [Msg.resume, Msg.updateProfile, Msg.createRoom]);
    expect(packets[1], {'type': Msg.updateProfile, 'name': 'arcade qa', 'character': 'rocco', 'kart': 'bubble'});
    expect(client.playerId, 'test-player');
  });
}
