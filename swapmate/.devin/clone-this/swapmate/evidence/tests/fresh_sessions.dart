import 'dart:convert';

import 'package:swapmate_core/swapmate_core.dart';
import 'package:swapmate_server/swapmate_server.dart';

import '../../../../../server/test/server_test.dart' show TestClient;

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  for (final seed in [73, 97]) {
    final server = SwapmateServer(
      ServerConfig(seed: seed, botDelayMs: 20, reconnectGraceMs: 2000),
    );
    await server.start(host: '127.0.0.1', port: 0);
    final clients = <TestClient>[];
    try {
      for (var i = 0; i < 5; i++) {
        final client = await TestClient.connect(server.port);
        clients.add(client);
        client.send(
          ClientMsg.hello(name: 'Fresh $i', platform: 'protocol-probe'),
        );
        await client.until(() => client.playerId != null);
      }
      final host = clients.first;
      final spectator = clients.last;
      host.send(ClientMsg.roomJoin('VOID'));
      await host.until(() => host.errors.isNotEmpty);
      check(host.errors.last['code'] == ErrorCode.roomNotFound, 'invalid room');
      host.send(ClientMsg.roomCreate());
      await host.until(() => host.room != null);
      for (var i = 1; i < clients.length; i++) {
        final client = clients[i];
        client.send(ClientMsg.roomJoin(host.room!.code, spectate: i == 4));
        await client.until(() => client.room != null);
      }
      await host.until(() => host.room!.spectators.length == 1);
      check(host.room!.players.length == 4, 'four occupied seats');
      clients[1].send(ClientMsg.roomStart());
      await clients[1].until(() => clients[1].errors.isNotEmpty);
      check(clients[1].errors.last['code'] == ErrorCode.notHost, 'host guard');

      host.send(ClientMsg.chatQuick(QuickChat.needKnight));
      await clients[3].until(() => clients[3].chats.isNotEmpty);
      host.send(ClientMsg.chatText('Fresh room $seed'));
      for (final client in clients) {
        await client.until(
          () => client.chats.any((c) => c.text == 'Fresh room $seed'),
        );
      }
      for (final client in [clients[1], clients[2], spectator]) {
        check(
          client.chats.every((c) => c.quick == null),
          'partner chat privacy',
        );
      }
      for (final client in clients.take(4)) {
        client.send(ClientMsg.roomReady(true));
      }
      for (final client in clients) {
        await client.until(() => client.game != null);
      }
      var moveCount = 0;
      for (final (client, uci) in [
        (clients[2], 'e2e4'),
        (clients[3], 'd7d5'),
        (clients[2], 'e4d5'),
      ]) {
        client.send(ClientMsg.gameMove(Move.parse(uci)));
        moveCount++;
        await client.until(() => client.game!.moves.length == moveCount);
      }
      await clients[1].until(
        () => clients[1].game!.boards[BoardId.a]!.position.blackReserve.has(
          PieceType.pawn,
        ),
      );
      clients[1].send(ClientMsg.gamePremove(Move.parse('P@h6')));
      await clients[1].until(() => clients[1].game!.premove != null);
      host.send(ClientMsg.gameMove(Move.parse('e2e4')));
      for (final client in clients) {
        await client.until(() => client.game!.moves.length == 5);
        check(client.game!.moves.last.san == 'P@h6', 'pre-drop executed');
      }
      check(clients[1].game!.premove == null, 'pre-drop cleared');
      check(
        !clients[1].game!.boards[BoardId.a]!.position.blackReserve.has(
          PieceType.pawn,
        ),
        'transferred reserve consumed',
      );
      host.send(ClientMsg.gameResign());
      for (final client in clients) {
        await client.until(() => client.game!.isOver);
        check(
          client.game!.result!.reason == ResultReason.resignation,
          'result',
        );
        check(client.game!.bpgn == host.game!.bpgn, 'BPGN agreement');
      }
      final finishedGameId = host.game!.gameId;
      for (final client in clients.take(4)) {
        client.send(ClientMsg.roomRematch());
      }
      for (final client in clients) {
        await client.until(
          () =>
              client.room!.phase == RoomPhase.playing &&
              client.game!.gameId != finishedGameId &&
              !client.game!.isOver &&
              client.game!.moves.isEmpty,
        );
      }
      check(host.seat == Seat.aBlack, 'rematch color swap');
      final previous = clients[2];
      final token = previous.resumeToken!;
      final playerId = previous.playerId;
      final seat = previous.seat;
      await previous.close();
      await host.until(() => host.room!.byId(playerId!)?.connected == false);
      final resumed = await TestClient.connect(server.port);
      clients[2] = resumed;
      resumed.send(
        ClientMsg.hello(
          name: 'Fresh resumed',
          platform: 'protocol-probe',
          resumeToken: token,
        ),
      );
      await resumed.until(() => resumed.room != null);
      check(
        resumed.playerId == playerId && resumed.seat == seat,
        'socket resume',
      );
      for (final client in clients) {
        client.send(ClientMsg.roomLeave());
        await client.until(() => client.room == null);
      }

      host.send(ClientMsg.roomCreate(fillBots: true));
      await host.until(() => host.room?.players.length == 4);
      check(host.room!.players.where((p) => p.isBot).length == 3, 'solo fill');
      host.send(ClientMsg.roomReady(true));
      await host.until(() => host.game?.isOver == false);
      host.send(ClientMsg.gameResign());
      await host.until(() => host.game!.isOver);
      host.send(ClientMsg.roomLeave());
      await host.until(() => host.room == null);

      host.send(ClientMsg.roomCreate());
      await host.until(() => host.room != null);
      host.send(ClientMsg.roomSeat(null));
      await host.until(() => host.seat == null);
      for (final seat in Seat.values) {
        host.send(ClientMsg.roomBot(seat, add: true));
      }
      await host.until(() => host.room!.players.length == 4);
      host.send(ClientMsg.roomStart());
      await host.until(() => host.game?.isOver == false);
      await host.until(
        () => host.game!.isOver,
        timeout: const Duration(seconds: 60),
      );
      check(host.game!.moves.isNotEmpty, 'bots played');
      print(
        jsonEncode({
          'seed': seed,
          'roles': ['host', 'player', 'spectator', 'resumed player', 'bot'],
          'passed': [
            'invalid room',
            'host guard',
            'private partner chat',
            'room chat',
            'move synchronization',
            'pre-drop from transferred reserve',
            'resignation and BPGN agreement',
            'rematch color swap',
            'socket resume',
            'leave',
            'solo with bots',
            'four bots complete a match',
          ],
          'botMoves': host.game!.moves.length,
          'botResult': host.game!.result!.reason.name,
        }),
      );
    } finally {
      for (final client in clients) {
        await client.close();
      }
      await server.stop();
    }
  }
}
