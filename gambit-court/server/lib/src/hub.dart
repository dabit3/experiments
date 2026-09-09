import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:gambit_court_core/gambit_court_core.dart';

import 'clock.dart';

typedef Json = Map<String, Object?>;

/// Tunables for a hub instance. Test runs pass a fixed seed, frozen clocks and
/// a short bot delay so every run is reproducible.
class HubConfig {
  const HubConfig({
    this.seed,
    this.frozenClocks = false,
    this.botDelayMs = 600,
    this.reconnectGraceMs = 45000,
    this.quickPairBotAfterMs = 8000,
    this.log,
  });

  final int? seed;
  final bool frozenClocks;
  final int botDelayMs;
  final int reconnectGraceMs;
  final int quickPairBotAfterMs;
  final void Function(String line)? log;
}

/// A connected (or recently disconnected) client.
class Session {
  Session(this.clientId, this.name, this.platform);

  final String clientId;
  String name;
  String platform;
  void Function(Json message)? _send;
  bool get connected => _send != null;
  String? roomCode;
  Timer? graceTimer;
  final Map<String, Completer<Json>> pendingUi = {};

  void send(Json message) => _send?.call(message);

  Participant toParticipant() => Participant(
        clientId: clientId,
        name: name,
        platform: platform,
        connected: connected,
      );
}

class Seat {
  Seat.human(this.session)
      : bot = null,
        botLevel = null;

  Seat.bot(this.botLevel, String code)
      : session = null,
        bot = Participant(
          clientId: 'bot:$code:${botLevel!.id}',
          name: 'Court Bot · ${botLevel.label}',
          platform: 'server',
          connected: true,
          isBot: true,
          botLevel: botLevel.id,
        );

  final Session? session;
  final Participant? bot;
  final EngineLevel? botLevel;

  bool get isBot => bot != null;
  String get clientId => bot?.clientId ?? session!.clientId;
  Participant toParticipant() => bot ?? session!.toParticipant();
}

class Room {
  Room(this.code, this.timeControl, this.isPublic, this.hostClientId, this.hub)
      : game = Game(),
        clock =
            GameClock(timeControl, hub.wall, frozen: hub.config.frozenClocks);

  final String code;
  final TimeControl timeControl;
  final bool isPublic;
  final String hostClientId;
  final Hub hub;

  Game game;
  GameClock clock;
  RoomStatus status = RoomStatus.waiting;
  Seat? white;
  Seat? black;
  final List<Session> spectators = [];
  PieceColor? drawOffer;
  PieceColor? takebackOffer;
  PieceColor? rematchOffer;
  int seq = 0;
  Timer? flagTimer;
  Timer? botTimer;
  int botGeneration = 0;

  Seat? seat(PieceColor color) => color == PieceColor.white ? white : black;

  PieceColor? sideOf(String clientId) {
    if (white?.clientId == clientId) return PieceColor.white;
    if (black?.clientId == clientId) return PieceColor.black;
    return null;
  }

  Iterable<Session> get sessions => [
        if (white?.session != null) white!.session!,
        if (black?.session != null) black!.session!,
        ...spectators,
      ];

  bool get hasHumans => sessions.isNotEmpty;
  bool get hasBot => (white?.isBot ?? false) || (black?.isBot ?? false);
  int get playerCount => (white == null ? 0 : 1) + (black == null ? 0 : 1);

  RoomSnapshot snapshot() => RoomSnapshot(
        code: code,
        seq: seq,
        status: status,
        timeControl: timeControl,
        white: white?.toParticipant(),
        black: black?.toParticipant(),
        spectators: spectators.map((s) => s.toParticipant()).toList(),
        hostClientId: hostClientId,
        startFen: game.start.fen,
        fen: game.position.fen,
        moves: game.moves,
        turn: game.position.turn,
        clocks: clock.snapshot(),
        result: game.result,
        offers: Offers(
          draw: drawOffer,
          takeback: takebackOffer,
          rematch: rematchOffer,
        ),
        rematchRoom: null,
        isPublic: isPublic,
      );

  RoomListing listing() {
    final host = white?.clientId == hostClientId ? white : black;
    return RoomListing(
      code: code,
      hostName: host?.toParticipant().name ?? 'Open table',
      hostPlatform: host?.toParticipant().platform ?? 'unknown',
      timeControl: timeControl,
      status: status,
      playerCount: playerCount,
      spectatorCount: spectators.length,
      hasBot: hasBot,
    );
  }

  void dispose() {
    flagTimer?.cancel();
    botTimer?.cancel();
  }
}

class HubError implements Exception {
  HubError(this.code, this.message);

  final String code;
  final String message;
}

class _QueueEntry {
  _QueueEntry(this.session, this.timeControl, this.botLevel, this.timer);

  final Session session;
  final TimeControl timeControl;
  final EngineLevel? botLevel;
  Timer? timer;
}

/// Owns all sessions, rooms, matchmaking and bots. Transport-agnostic: the
/// WebSocket layer calls [attach], [handle] and [detach].
class Hub {
  Hub({this.config = const HubConfig(), WallClock? wall})
      : wall = wall ?? const SystemWallClock(),
        _random = Random(config.seed);

  final HubConfig config;
  final WallClock wall;
  final Random _random;
  final Map<String, Session> sessions = {};
  final Map<String, Room> rooms = {};
  final List<_QueueEntry> _queue = [];

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  void _log(String line) => config.log?.call(line);

  // ---------------------------------------------------------------- sessions

  /// Registers a connection for [clientId]. Returns the session; if a session
  /// with that id already exists (reconnect or duplicate tab) it is reused.
  Session attach(
    String clientId,
    String name,
    String platform,
    void Function(Json) send,
  ) {
    var session = sessions[clientId];
    if (session == null) {
      session = Session(clientId, name, platform);
      sessions[clientId] = session;
    } else {
      session.graceTimer?.cancel();
      session.graceTimer = null;
      session._send?.call({
        'type': Protocol.error,
        'code': ErrorCodes.notAllowed,
        'message': 'This client id connected from another tab or device.',
        'fatal': true,
      });
      if (name.isNotEmpty) session.name = name;
      session.platform = platform;
    }
    session._send = send;
    _log('attach ${session.clientId} (${session.platform}) as ${session.name}');
    final room = session.roomCode == null ? null : rooms[session.roomCode];
    send({
      'type': Protocol.welcome,
      'protocol': Protocol.version,
      'clientId': session.clientId,
      'name': session.name,
      'serverTimeMs': wall.nowMs(),
      'frozenClocks': config.frozenClocks,
      'room': room?.snapshot().toJson(),
    });
    if (room != null) {
      _broadcastRoom(room);
    } else {
      _sendRooms(session);
    }
    return session;
  }

  void detach(Session session, void Function(Json) send) {
    if (session._send != send) return;
    session._send = null;
    _log('detach ${session.clientId}');
    _removeFromQueue(session);
    final room = session.roomCode == null ? null : rooms[session.roomCode];
    if (room == null) {
      sessions.remove(session.clientId);
      return;
    }
    _broadcastRoom(room);
    session.graceTimer = Timer(
      Duration(milliseconds: config.reconnectGraceMs),
      () => _expire(session),
    );
  }

  void _expire(Session session) {
    if (session.connected) return;
    final room = session.roomCode == null ? null : rooms[session.roomCode];
    if (room != null) _leave(room, session, abandon: true);
    sessions.remove(session.clientId);
  }

  // --------------------------------------------------------------- dispatch

  void handle(Session session, Json message) {
    final type = message['type'];
    try {
      switch (type) {
        case Protocol.ping:
          session.send({
            'type': Protocol.pong,
            'serverTimeMs': wall.nowMs(),
            'nonce': message['nonce'],
          });
        case Protocol.setName:
          final name = (message['name'] as String? ?? '').trim();
          if (name.isEmpty || name.length > 24) {
            throw HubError(
              ErrorCodes.badRequest,
              'Name must be 1-24 characters.',
            );
          }
          session.name = name;
          final room = _roomOf(session);
          if (room != null) {
            _broadcastRoom(room);
          } else {
            _broadcastRooms();
          }
        case Protocol.listRooms:
          _sendRooms(session);
        case Protocol.createRoom:
          _createRoom(session, message);
        case Protocol.joinRoom:
          _joinRoom(session, message);
        case Protocol.quickPair:
          _quickPair(session, message);
        case Protocol.cancelPair:
          _removeFromQueue(session);
          session.send({'type': Protocol.left, 'reason': 'pair_cancelled'});
          _sendRooms(session);
        case Protocol.leaveRoom:
          final room = _requireRoom(session);
          _leave(room, session, abandon: false);
        case Protocol.addBot:
          _addBot(session, message);
        case Protocol.move:
          _move(session, message);
        case Protocol.resign:
          _resign(session);
        case Protocol.offerDraw:
          _offer(session, _OfferKind.draw);
        case Protocol.acceptDraw:
          _accept(session, _OfferKind.draw);
        case Protocol.declineDraw:
          _decline(session, _OfferKind.draw);
        case Protocol.offerTakeback:
          _offer(session, _OfferKind.takeback);
        case Protocol.acceptTakeback:
          _accept(session, _OfferKind.takeback);
        case Protocol.declineTakeback:
          _decline(session, _OfferKind.takeback);
        case Protocol.offerRematch:
          _offer(session, _OfferKind.rematch);
        case Protocol.acceptRematch:
          _accept(session, _OfferKind.rematch);
        case Protocol.declineRematch:
          _decline(session, _OfferKind.rematch);
        case Protocol.uiReport:
          final id = message['id'] as String?;
          final completer = id == null ? null : session.pendingUi.remove(id);
          completer?.complete(message);
        default:
          throw HubError(ErrorCodes.badRequest, 'Unknown message type: $type');
      }
    } on HubError catch (e) {
      session.send({
        'type': Protocol.error,
        'code': e.code,
        'message': e.message,
        'about': type,
      });
    }
  }

  // ------------------------------------------------------------------ lobby

  List<RoomListing> listings() => rooms.values
      .where((r) => r.isPublic && r.status != RoomStatus.finished)
      .map((r) => r.listing())
      .toList()
    ..sort((a, b) => a.code.compareTo(b.code));

  Json _roomsMessage() => {
        'type': Protocol.rooms,
        'rooms': listings().map((l) => l.toJson()).toList(),
        'online': sessions.values.where((s) => s.connected).length,
      };

  void _sendRooms(Session session) => session.send(_roomsMessage());

  void _broadcastRooms() {
    final message = _roomsMessage();
    for (final s in sessions.values) {
      if (s.roomCode == null) s.send(message);
    }
  }

  String _newCode() {
    while (true) {
      final code = List.generate(
        6,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join();
      if (!rooms.containsKey(code)) return code;
    }
  }

  TimeControl _parseTimeControl(Object? raw) {
    if (raw is! Map) {
      return const TimeControl(initialMs: 300000, incrementMs: 3000);
    }
    final tc = TimeControl.fromJson(raw.cast<String, Object?>());
    if (tc.initialMs < 0 ||
        tc.incrementMs < 0 ||
        tc.initialMs > 24 * 3600 * 1000 ||
        tc.incrementMs > 3600 * 1000) {
      throw HubError(ErrorCodes.badRequest, 'Time control out of range.');
    }
    return tc;
  }

  EngineLevel? _parseBotLevel(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return EngineLevel.fromId(raw.toInt());
    throw HubError(ErrorCodes.badRequest, 'botLevel must be a number 1-4.');
  }

  PieceColor _pickSide(Object? raw) {
    switch (raw) {
      case 'white':
        return PieceColor.white;
      case 'black':
        return PieceColor.black;
      default:
        return _random.nextBool() ? PieceColor.white : PieceColor.black;
    }
  }

  void _createRoom(Session session, Json message) {
    if (session.roomCode != null) {
      throw HubError(ErrorCodes.notAllowed, 'Leave your current room first.');
    }
    _removeFromQueue(session);
    final tc = _parseTimeControl(message['timeControl']);
    final botLevel = _parseBotLevel(message['botLevel']);
    final side = _pickSide(message['side']);
    final isPublic = message['isPublic'] as bool? ?? true;
    final room = Room(_newCode(), tc, isPublic, session.clientId, this);
    rooms[room.code] = room;
    _sit(room, side, Seat.human(session));
    if (botLevel != null) {
      _sit(room, side.opposite, Seat.bot(botLevel, room.code));
    }
    _log(
        'room ${room.code} created by ${session.clientId} ($tc, bot=$botLevel)');
    _afterSeating(room);
  }

  void _sit(Room room, PieceColor side, Seat seat) {
    if (side == PieceColor.white) {
      room.white = seat;
    } else {
      room.black = seat;
    }
    seat.session?.roomCode = room.code;
  }

  void _joinRoom(Session session, Json message) {
    final code = (message['code'] as String? ?? '').trim().toUpperCase();
    final room = rooms[code];
    if (room == null) {
      throw HubError(ErrorCodes.roomNotFound, 'No room with code $code.');
    }
    if (session.roomCode != null && session.roomCode != code) {
      throw HubError(ErrorCodes.notAllowed, 'Leave your current room first.');
    }
    if (session.roomCode == code) {
      session.send({
        'type': Protocol.roomState,
        'room': room.snapshot().toJson(),
      });
      return;
    }
    _removeFromQueue(session);
    final asSpectator = message['asSpectator'] as bool? ?? false;
    final open = room.white == null
        ? PieceColor.white
        : room.black == null
            ? PieceColor.black
            : null;
    if (!asSpectator && open != null && room.status == RoomStatus.waiting) {
      _sit(room, open, Seat.human(session));
      _log('${session.clientId} sits ${open.name} in ${room.code}');
      _afterSeating(room);
    } else {
      room.spectators.add(session);
      session.roomCode = room.code;
      _log('${session.clientId} spectates ${room.code}');
      _broadcastRoom(room);
      _broadcastRooms();
    }
  }

  /// Host of a waiting room fills the empty seat with an engine.
  void _addBot(Session session, Json message) {
    final room = _requireRoom(session);
    if (room.status != RoomStatus.waiting) {
      throw HubError(ErrorCodes.notAllowed, 'The game has already started.');
    }
    if (room.hostClientId != session.clientId) {
      throw HubError(ErrorCodes.notAllowed, 'Only the host can seat a bot.');
    }
    final open = room.white == null
        ? PieceColor.white
        : room.black == null
            ? PieceColor.black
            : null;
    if (open == null) {
      throw HubError(ErrorCodes.notAllowed, 'Both seats are taken.');
    }
    final level = _parseBotLevel(message['botLevel']) ?? EngineLevel.club;
    _sit(room, open, Seat.bot(level, room.code));
    _log('bot ${level.name} seated ${open.name} in ${room.code}');
    _afterSeating(room);
  }

  void _afterSeating(Room room) {
    if (room.white != null && room.black != null) {
      _startGame(room);
    } else {
      _broadcastRoom(room);
    }
    _broadcastRooms();
  }

  void _startGame(Room room) {
    room.game = Game();
    room.clock = GameClock(room.timeControl, wall, frozen: config.frozenClocks);
    room.status = RoomStatus.playing;
    room.drawOffer = null;
    room.takebackOffer = null;
    room.rematchOffer = null;
    _log('room ${room.code} game started');
    _broadcastRoom(room);
    _maybeBotMove(room);
  }

  // ------------------------------------------------------------- quick pair

  void _quickPair(Session session, Json message) {
    if (session.roomCode != null) {
      throw HubError(ErrorCodes.notAllowed, 'Leave your current room first.');
    }
    _removeFromQueue(session);
    final tc = _parseTimeControl(message['timeControl']);
    final botLevel = _parseBotLevel(message['botLevel']);
    final match = _queue.where((e) => e.timeControl == tc).firstOrNull;
    if (match != null) {
      _removeFromQueue(match.session);
      final room = Room(_newCode(), tc, true, match.session.clientId, this);
      rooms[room.code] = room;
      final side = _pickSide(null);
      _sit(room, side, Seat.human(match.session));
      _sit(room, side.opposite, Seat.human(session));
      _log('quick pair ${match.session.clientId} vs ${session.clientId} '
          'in ${room.code}');
      _afterSeating(room);
      return;
    }
    final entry = _QueueEntry(session, tc, botLevel, null);
    final botAfter =
        (message['botAfterMs'] as num?)?.toInt() ?? config.quickPairBotAfterMs;
    if (botLevel != null) {
      entry.timer = Timer(Duration(milliseconds: botAfter), () {
        if (!_queue.contains(entry)) return;
        _removeFromQueue(session);
        final room = Room(_newCode(), tc, true, session.clientId, this);
        rooms[room.code] = room;
        final side = _pickSide(null);
        _sit(room, side, Seat.human(session));
        _sit(room, side.opposite, Seat.bot(botLevel, room.code));
        _log('quick pair ${session.clientId} filled by bot in ${room.code}');
        _afterSeating(room);
      });
    }
    _queue.add(entry);
    session.send({
      'type': Protocol.queued,
      'timeControl': tc.toJson(),
      'position': _queue.length,
      'botAfterMs': botLevel == null ? null : botAfter,
    });
  }

  void _removeFromQueue(Session session) {
    _queue.removeWhere((e) {
      if (e.session != session) return false;
      e.timer?.cancel();
      return true;
    });
  }

  // ---------------------------------------------------------------- leaving

  void _leave(Room room, Session session, {required bool abandon}) {
    final side = room.sideOf(session.clientId);
    room.spectators.remove(session);
    session.roomCode = null;
    if (side != null) {
      if (room.status == RoomStatus.playing) {
        final reason =
            abandon ? GameEndReason.abandonment : GameEndReason.resignation;
        if (room.game.moves.isEmpty) {
          _finish(
              room, GameResult(GameOutcome.draw, GameEndReason.abandonment));
        } else {
          _finish(
            room,
            GameResult(
              side == PieceColor.white
                  ? GameOutcome.blackWins
                  : GameOutcome.whiteWins,
              reason,
            ),
          );
        }
      }
      if (side == PieceColor.white) {
        room.white = null;
      } else {
        room.black = null;
      }
      if (room.status == RoomStatus.waiting && room.hasBot) {
        room.white = null;
        room.black = null;
      }
    }
    _log('${session.clientId} left ${room.code}${abandon ? ' (expired)' : ''}');
    if (session.connected) {
      session.send({'type': Protocol.left, 'code': room.code});
      _sendRooms(session);
    }
    if (!room.hasHumans) {
      room.dispose();
      rooms.remove(room.code);
      _log('room ${room.code} closed');
    } else {
      _broadcastRoom(room);
    }
    _broadcastRooms();
  }

  // ------------------------------------------------------------------ moves

  Room _requireRoom(Session session) {
    final room = _roomOf(session);
    if (room == null) {
      throw HubError(ErrorCodes.notInRoom, 'You are not in a room.');
    }
    return room;
  }

  Room? _roomOf(Session session) =>
      session.roomCode == null ? null : rooms[session.roomCode];

  (Room, PieceColor) _requirePlayer(Session session) {
    final room = _requireRoom(session);
    final side = room.sideOf(session.clientId);
    if (side == null) {
      throw HubError(ErrorCodes.notAllowed, 'Spectators cannot do that.');
    }
    return (room, side);
  }

  void _move(Session session, Json message) {
    final (room, side) = _requirePlayer(session);
    if (room.status != RoomStatus.playing) {
      throw HubError(ErrorCodes.notPlaying, 'The game is not in progress.');
    }
    if (room.game.position.turn != side) {
      throw HubError(ErrorCodes.notYourTurn, 'It is not your turn.');
    }
    final uci = message['uci'] as String? ?? '';
    final move = Move.parseUci(uci);
    if (move == null) throw HubError(ErrorCodes.badRequest, 'Bad move: $uci');
    if (room.game.position.requiresPromotion(move.from, move.to) &&
        move.promotion == null) {
      throw HubError(ErrorCodes.illegalMove, 'Promotion piece required.');
    }
    if (!room.game.position.isLegal(move)) {
      throw HubError(ErrorCodes.illegalMove, 'Illegal move: $uci');
    }
    _applyMove(room, side, move);
  }

  void _applyMove(Room room, PieceColor side, Move move) {
    if (room.clock.running == side && room.clock.flagged) {
      _timeout(room, side);
      return;
    }
    final played = room.game.play(move)!;
    room.clock.punch(side);
    if (room.drawOffer == side.opposite) room.drawOffer = null;
    if (room.takebackOffer != null) room.takebackOffer = null;
    _log('room ${room.code} ${side.name} ${played.san} (${move.uci})');
    if (room.game.isOver) {
      _finish(room, room.game.result!);
      return;
    }
    _armFlagTimer(room);
    _broadcastRoom(room);
    _maybeBotMove(room);
  }

  void _armFlagTimer(Room room) {
    room.flagTimer?.cancel();
    final running = room.clock.running;
    if (running == null || room.clock.frozen || room.timeControl.isUnlimited) {
      return;
    }
    final ms = room.clock.remaining(running) + 5;
    room.flagTimer = Timer(Duration(milliseconds: ms), () {
      if (room.status != RoomStatus.playing) return;
      if (room.clock.running == running && room.clock.flagged) {
        _timeout(room, running);
      } else {
        _armFlagTimer(room);
      }
    });
  }

  void _timeout(Room room, PieceColor flagged) {
    final opponentCanMate =
        room.game.position.hasMatingMaterial(flagged.opposite);
    _finish(
      room,
      opponentCanMate
          ? GameResult(
              flagged == PieceColor.white
                  ? GameOutcome.blackWins
                  : GameOutcome.whiteWins,
              GameEndReason.timeout,
            )
          : GameResult(GameOutcome.draw, GameEndReason.timeout),
    );
  }

  void _finish(Room room, GameResult result) {
    room.flagTimer?.cancel();
    room.botTimer?.cancel();
    room.botGeneration++;
    room.clock.stop();
    if (!room.game.isOver) room.game.end(result);
    room.status = RoomStatus.finished;
    room.drawOffer = null;
    room.takebackOffer = null;
    _log(
        'room ${room.code} finished: ${result.headline} ${result.reasonLabel}');
    _broadcastRoom(room);
    _broadcastRooms();
  }

  void _resign(Session session) {
    final (room, side) = _requirePlayer(session);
    if (room.status != RoomStatus.playing) {
      throw HubError(ErrorCodes.notPlaying, 'The game is not in progress.');
    }
    _finish(
      room,
      GameResult(
        side == PieceColor.white
            ? GameOutcome.blackWins
            : GameOutcome.whiteWins,
        GameEndReason.resignation,
      ),
    );
  }

  // ----------------------------------------------------------------- offers

  void _offer(Session session, _OfferKind kind) {
    final (room, side) = _requirePlayer(session);
    switch (kind) {
      case _OfferKind.draw:
        _requirePlaying(room);
        room.drawOffer = side;
      case _OfferKind.takeback:
        _requirePlaying(room);
        if (room.game.moves.isEmpty) {
          throw HubError(ErrorCodes.notAllowed, 'Nothing to take back.');
        }
        room.takebackOffer = side;
      case _OfferKind.rematch:
        if (room.status != RoomStatus.finished) {
          throw HubError(ErrorCodes.notAllowed, 'The game is still running.');
        }
        room.rematchOffer = side;
    }
    _log('room ${room.code} ${side.name} offers ${kind.name}');
    _broadcastRoom(room);
    final opponent = room.seat(side.opposite);
    if (opponent != null && opponent.isBot) {
      _botRespond(room, kind, side.opposite);
    }
  }

  void _requirePlaying(Room room) {
    if (room.status != RoomStatus.playing) {
      throw HubError(ErrorCodes.notPlaying, 'The game is not in progress.');
    }
  }

  void _accept(Session session, _OfferKind kind) {
    final (room, side) = _requirePlayer(session);
    _acceptAs(room, side, kind);
  }

  void _acceptAs(Room room, PieceColor side, _OfferKind kind) {
    switch (kind) {
      case _OfferKind.draw:
        if (room.drawOffer != side.opposite ||
            room.status != RoomStatus.playing) {
          throw HubError(ErrorCodes.notAllowed, 'No draw offer to accept.');
        }
        _finish(room, GameResult(GameOutcome.draw, GameEndReason.agreement));
      case _OfferKind.takeback:
        if (room.takebackOffer != side.opposite ||
            room.status != RoomStatus.playing) {
          throw HubError(ErrorCodes.notAllowed, 'No takeback to accept.');
        }
        final offerer = side.opposite;
        final plies = room.game.position.turn == offerer ? 2 : 1;
        room.game.takeBack(min(plies, room.game.moves.length));
        room.takebackOffer = null;
        room.drawOffer = null;
        room.botGeneration++;
        room.botTimer?.cancel();
        if (room.game.moves.length < 2) {
          room.clock.stop();
        } else {
          room.clock.start(room.game.position.turn);
        }
        _armFlagTimer(room);
        _log('room ${room.code} takeback of $plies plies accepted');
        _broadcastRoom(room);
        _maybeBotMove(room);
      case _OfferKind.rematch:
        if (room.rematchOffer != side.opposite ||
            room.status != RoomStatus.finished) {
          throw HubError(ErrorCodes.notAllowed, 'No rematch to accept.');
        }
        final w = room.white;
        room.white = room.black;
        room.black = w;
        _log('room ${room.code} rematch accepted, colours swapped');
        _startGame(room);
        _broadcastRooms();
    }
  }

  void _decline(Session session, _OfferKind kind) {
    final (room, side) = _requirePlayer(session);
    switch (kind) {
      case _OfferKind.draw:
        if (room.drawOffer == side.opposite) room.drawOffer = null;
      case _OfferKind.takeback:
        if (room.takebackOffer == side.opposite) room.takebackOffer = null;
      case _OfferKind.rematch:
        if (room.rematchOffer == side.opposite) room.rematchOffer = null;
    }
    _broadcastRoom(room);
  }

  // ------------------------------------------------------------------- bots

  void _maybeBotMove(Room room) {
    if (room.status != RoomStatus.playing) return;
    final turn = room.game.position.turn;
    final seat = room.seat(turn);
    if (seat == null || !seat.isBot) return;
    final generation = ++room.botGeneration;
    final level = seat.botLevel!;
    final fen = room.game.position.fen;
    final seed = (config.seed ?? 0) ^ room.game.moves.length ^ level.id * 7919;
    room.botTimer?.cancel();
    room.botTimer = Timer(Duration(milliseconds: config.botDelayMs), () async {
      final result = await _think(level, seed, fen);
      if (room.botGeneration != generation ||
          room.status != RoomStatus.playing ||
          room.game.position.turn != turn) {
        return;
      }
      final move = result.move;
      if (move == null) return;
      _applyMove(room, turn, move);
    });
  }

  /// Runs the engine on a worker isolate. Kept as a separate method so the
  /// closure captures only sendable values.
  static Future<EngineResult> _think(EngineLevel level, int seed, String fen) =>
      Isolate.run(
        () => Engine(level: level, seed: seed).bestMove(Position.fromFen(fen)!),
      );

  void _botRespond(Room room, _OfferKind kind, PieceColor botSide) {
    Timer(Duration(milliseconds: config.botDelayMs), () {
      if (!rooms.containsKey(room.code)) return;
      try {
        switch (kind) {
          case _OfferKind.draw:
            final eval = Engine.evaluate(room.game.position) *
                (room.game.position.turn == botSide ? 1 : -1);
            if (eval < -250) {
              _acceptAs(room, botSide, kind);
            } else {
              room.drawOffer = null;
              _broadcastRoom(room);
            }
          case _OfferKind.takeback:
          case _OfferKind.rematch:
            _acceptAs(room, botSide, kind);
        }
      } on HubError {
        // The offer was withdrawn or the game changed; nothing to do.
      }
    });
  }

  // -------------------------------------------------------------- broadcast

  void _broadcastRoom(Room room) {
    room.seq++;
    final message = {
      'type': Protocol.roomState,
      'room': room.snapshot().toJson(),
    };
    for (final s in room.sessions) {
      s.send(message);
    }
  }

  // ------------------------------------------------------------ test control

  /// Sends a UI command to a client and waits for its `ui_report` reply.
  Future<Json> uiCommand(
      String clientId, Json command, Duration timeout) async {
    final session = sessions[clientId];
    if (session == null || !session.connected) {
      throw HubError(ErrorCodes.roomNotFound, 'No connected client $clientId.');
    }
    final id = '${wall.nowMs()}-${_random.nextInt(1 << 30)}';
    final completer = Completer<Json>();
    session.pendingUi[id] = completer;
    session.send({'type': Protocol.uiCommand, 'id': id, ...command});
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      session.pendingUi.remove(id);
      throw HubError('timeout', 'Client $clientId did not report in time.');
    }
  }

  Json debugState() => {
        'clients': sessions.values
            .map((s) => {
                  'clientId': s.clientId,
                  'name': s.name,
                  'platform': s.platform,
                  'connected': s.connected,
                  'room': s.roomCode,
                })
            .toList(),
        'rooms': rooms.values.map((r) => r.snapshot().toJson()).toList(),
        'queue': _queue.length,
        'serverTimeMs': wall.nowMs(),
      };

  void dispose() {
    for (final room in rooms.values) {
      room.dispose();
    }
    for (final s in sessions.values) {
      s.graceTimer?.cancel();
    }
    for (final e in _queue) {
      e.timer?.cancel();
    }
  }
}

enum _OfferKind { draw, takeback, rematch }

/// Convenience for the transport layer.
Json? decodeJson(Object? raw) {
  if (raw is! String) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.cast<String, Object?>() : null;
  } on FormatException {
    return null;
  }
}
