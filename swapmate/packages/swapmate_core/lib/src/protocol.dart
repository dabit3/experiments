import 'match.dart';
import 'move.dart';
import 'piece.dart';

/// Wire protocol version. Bumped whenever a message shape changes.
const protocolVersion = 1;

/// Message type names shared by the server and clients. See PROTOCOL.md.
class MsgType {
  MsgType._();

  // client -> server
  static const hello = 'hello';
  static const ping = 'ping';
  static const roomCreate = 'room.create';
  static const roomJoin = 'room.join';
  static const roomLeave = 'room.leave';
  static const roomSeat = 'room.seat';
  static const roomBot = 'room.bot';
  static const roomReady = 'room.ready';
  static const roomStart = 'room.start';
  static const roomTimeControl = 'room.timeControl';
  static const roomRematch = 'room.rematch';
  static const gameMove = 'game.move';
  static const gamePremove = 'game.premove';
  static const gameResign = 'game.resign';
  static const gameDraw = 'game.draw';
  static const chatSend = 'chat.send';
  static const testResult = 'test.result';

  // server -> client
  static const welcome = 'welcome';
  static const pong = 'pong';
  static const roomState = 'room.state';
  static const gameState = 'game.state';
  static const gameEvent = 'game.event';
  static const chatMessage = 'chat.message';
  static const error = 'error';
  static const testCommand = 'test.command';
}

/// Error codes carried by `error` messages.
class ErrorCode {
  ErrorCode._();
  static const badRequest = 'bad_request';
  static const roomNotFound = 'room_not_found';
  static const roomFull = 'room_full';
  static const seatTaken = 'seat_taken';
  static const notHost = 'not_host';
  static const notSeated = 'not_seated';
  static const notYourTurn = 'not_your_turn';
  static const illegalMove = 'illegal_move';
  static const notPlaying = 'not_playing';
  static const notReady = 'not_ready';
  static const rateLimited = 'rate_limited';
}

enum RoomPhase {
  lobby,
  playing,
  finished;

  static RoomPhase parse(String s) =>
      RoomPhase.values.firstWhere((p) => p.name == s);
}

/// Quick-chat phrases partners can send with one tap. The wire format sends
/// the [code]; clients render the [text] so the copy stays consistent.
enum QuickChat {
  needPawn('need_p', 'Need a pawn!', 'P'),
  needKnight('need_n', 'Need a knight!', 'N'),
  needBishop('need_b', 'Need a bishop!', 'B'),
  needRook('need_r', 'Need a rook!', 'R'),
  needQueen('need_q', 'Need a queen!', 'Q'),
  noQueen('no_q', "Don't give up your queen", null),
  sit('sit', 'Sit! Don\'t move', null),
  go('go', 'Go go go!', null),
  trades('trades', 'Trade everything', null),
  mating('mating', 'I\'m mating soon', null),
  help('help', 'Help, I\'m getting mated', null),
  gg('gg', 'Good game', null),
  thanks('thanks', 'Thanks!', null),
  sorry('sorry', 'Sorry!', null);

  const QuickChat(this.code, this.text, this.piece);

  final String code;
  final String text;

  /// Piece letter for "need X" requests, used to draw the icon.
  final String? piece;

  static QuickChat? byCode(String code) {
    for (final q in QuickChat.values) {
      if (q.code == code) return q;
    }
    return null;
  }
}

class PlayerInfo {
  const PlayerInfo({
    required this.id,
    required this.name,
    required this.seat,
    required this.ready,
    required this.isBot,
    required this.connected,
    required this.platform,
  });

  final String id;
  final String name;
  final Seat? seat;
  final bool ready;
  final bool isBot;
  final bool connected;
  final String platform;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'seat': seat?.id,
    'ready': ready,
    'bot': isBot,
    'connected': connected,
    'platform': platform,
  };

  static PlayerInfo fromJson(Map<String, dynamic> j) => PlayerInfo(
    id: j['id'] as String,
    name: j['name'] as String,
    seat: j['seat'] == null ? null : Seat.parse(j['seat'] as String),
    ready: j['ready'] as bool,
    isBot: j['bot'] as bool,
    connected: j['connected'] as bool,
    platform: j['platform'] as String,
  );
}

class RoomState {
  const RoomState({
    required this.code,
    required this.phase,
    required this.hostId,
    required this.timeControl,
    required this.players,
    required this.spectators,
    required this.rematchVotes,
  });

  final String code;
  final RoomPhase phase;
  final String hostId;
  final TimeControl timeControl;
  final List<PlayerInfo> players;
  final List<PlayerInfo> spectators;
  final List<String> rematchVotes;

  PlayerInfo? seated(Seat s) {
    for (final p in players) {
      if (p.seat == s) return p;
    }
    return null;
  }

  PlayerInfo? byId(String id) {
    for (final p in [...players, ...spectators]) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool get allSeated => Seat.values.every((s) => seated(s) != null);

  bool get allReady => Seat.values.every((s) {
    final p = seated(s);
    return p != null && (p.ready || p.isBot);
  });

  Map<Seat, String> get names => {
    for (final s in Seat.values) s: seated(s)?.name ?? 'Empty',
  };

  Map<String, dynamic> toJson() => {
    'code': code,
    'phase': phase.name,
    'host': hostId,
    'timeControl': timeControl.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
    'spectators': spectators.map((p) => p.toJson()).toList(),
    'rematchVotes': rematchVotes,
  };

  static RoomState fromJson(Map<String, dynamic> j) => RoomState(
    code: j['code'] as String,
    phase: RoomPhase.parse(j['phase'] as String),
    hostId: j['host'] as String,
    timeControl: TimeControl.fromJson(j['timeControl'] as Map<String, dynamic>),
    players: (j['players'] as List)
        .map((p) => PlayerInfo.fromJson(p as Map<String, dynamic>))
        .toList(),
    spectators: (j['spectators'] as List)
        .map((p) => PlayerInfo.fromJson(p as Map<String, dynamic>))
        .toList(),
    rematchVotes: (j['rematchVotes'] as List).cast<String>(),
  );
}

/// Full game snapshot broadcast after every change.
class GameState {
  const GameState({
    required this.gameId,
    required this.boards,
    required this.moves,
    required this.result,
    required this.serverTime,
    required this.premove,
    required this.drawOffers,
    required this.bpgn,
  });

  final String gameId;
  final Map<BoardId, BoardSnapshot> boards;
  final List<MatchMove> moves;
  final MatchResult? result;

  /// Server timestamp (ms) at which the clock values were sampled.
  final int serverTime;

  /// The receiving player's own pending premove, if any (per-recipient).
  final Move? premove;

  /// Seats that currently have a draw offer outstanding.
  final List<Seat> drawOffers;

  /// BPGN export, present once the match is finished.
  final String? bpgn;

  bool get isOver => result != null;

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'boards': {for (final e in boards.entries) e.key.id: e.value.toJson()},
    'moves': moves.map((m) => m.toJson()).toList(),
    'result': result?.toJson(),
    'serverTime': serverTime,
    'premove': premove?.toJson(),
    'drawOffers': drawOffers.map((s) => s.id).toList(),
    'bpgn': bpgn,
  };

  static GameState fromJson(Map<String, dynamic> j) => GameState(
    gameId: j['gameId'] as String,
    boards: {
      for (final e in (j['boards'] as Map<String, dynamic>).entries)
        BoardId.parse(e.key): BoardSnapshot.fromJson(
          e.value as Map<String, dynamic>,
        ),
    },
    moves: (j['moves'] as List)
        .map((m) => MatchMove.fromJson(m as Map<String, dynamic>))
        .toList(),
    result: j['result'] == null
        ? null
        : MatchResult.fromJson(j['result'] as Map<String, dynamic>),
    serverTime: j['serverTime'] as int,
    premove: j['premove'] == null
        ? null
        : Move.fromJson(j['premove'] as Map<String, dynamic>),
    drawOffers: (j['drawOffers'] as List)
        .map((s) => Seat.parse(s as String))
        .toList(),
    bpgn: j['bpgn'] as String?,
  );

  GameState copyWith({Move? premove, bool clearPremove = false}) => GameState(
    gameId: gameId,
    boards: boards,
    moves: moves,
    result: result,
    serverTime: serverTime,
    premove: clearPremove ? null : (premove ?? this.premove),
    drawOffers: drawOffers,
    bpgn: bpgn,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.fromId,
    required this.fromName,
    required this.seat,
    required this.ts,
    this.scope = 'room',
    this.quick,
    this.text,
  });

  final String fromId;
  final String fromName;
  final Seat? seat;
  final int ts;

  /// `team` or `room`.
  final String scope;
  final QuickChat? quick;
  final String? text;

  bool get isTeam => scope == 'team';

  String get display => quick?.text ?? text ?? '';

  Map<String, dynamic> toJson() => {
    'from': fromId,
    'name': fromName,
    'seat': seat?.id,
    'ts': ts,
    'scope': scope,
    if (quick != null) 'quick': quick!.code,
    if (text != null) 'text': text,
  };

  static ChatMessage fromJson(Map<String, dynamic> j) => ChatMessage(
    fromId: j['from'] as String,
    fromName: j['name'] as String,
    seat: j['seat'] == null ? null : Seat.parse(j['seat'] as String),
    ts: j['ts'] as int,
    scope: (j['scope'] as String?) ?? 'room',
    quick: j['quick'] == null ? null : QuickChat.byCode(j['quick'] as String),
    text: j['text'] as String?,
  );
}

/// A game event describing what just happened, used by clients to animate.
class GameEvent {
  const GameEvent({
    required this.kind,
    required this.board,
    required this.seat,
    this.move,
    this.san,
    this.captured,
    this.toBoard,
    this.toColor,
  });

  /// `move`, `drop`, `pass` (piece handed to partner), `start`, `finish`.
  final String kind;
  final BoardId? board;
  final Seat? seat;
  final Move? move;
  final String? san;
  final PieceType? captured;
  final BoardId? toBoard;
  final PieceColor? toColor;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'board': board?.id,
    'seat': seat?.id,
    'move': move?.toJson(),
    'san': san,
    'captured': captured?.letter,
    'toBoard': toBoard?.id,
    'toColor': toColor?.letter,
  };

  static GameEvent fromJson(Map<String, dynamic> j) => GameEvent(
    kind: j['kind'] as String,
    board: j['board'] == null ? null : BoardId.parse(j['board'] as String),
    seat: j['seat'] == null ? null : Seat.parse(j['seat'] as String),
    move: j['move'] == null
        ? null
        : Move.fromJson(j['move'] as Map<String, dynamic>),
    san: j['san'] as String?,
    captured: j['captured'] == null
        ? null
        : PieceType.fromLetter(j['captured'] as String),
    toBoard: j['toBoard'] == null
        ? null
        : BoardId.parse(j['toBoard'] as String),
    toColor: j['toColor'] == null
        ? null
        : PieceColor.fromLetter(j['toColor'] as String),
  );
}

/// Helpers to build client messages so every client speaks identical JSON.
class ClientMsg {
  ClientMsg._();

  static Map<String, dynamic> hello({
    required String name,
    required String platform,
    String? resumeToken,
    String? testId,
  }) => {
    'type': MsgType.hello,
    'v': protocolVersion,
    'name': name,
    'platform': platform,
    'resumeToken': ?resumeToken,
    'testId': ?testId,
  };

  static Map<String, dynamic> ping(int t) => {'type': MsgType.ping, 't': t};

  /// [code] is only honoured by servers started in test mode.
  static Map<String, dynamic> roomCreate({
    TimeControl? timeControl,
    bool fillBots = false,
    String? code,
  }) => {
    'type': MsgType.roomCreate,
    if (timeControl != null) 'timeControl': timeControl.toJson(),
    'fillBots': fillBots,
    'code': ?code,
  };

  static Map<String, dynamic> roomJoin(String code, {bool spectate = false}) =>
      {'type': MsgType.roomJoin, 'code': code, 'spectate': spectate};

  static Map<String, dynamic> roomLeave() => {'type': MsgType.roomLeave};

  static Map<String, dynamic> roomSeat(Seat? seat) => {
    'type': MsgType.roomSeat,
    'seat': seat?.id,
  };

  static Map<String, dynamic> roomBot(Seat seat, {required bool add}) => {
    'type': MsgType.roomBot,
    'seat': seat.id,
    'add': add,
  };

  static Map<String, dynamic> roomReady(bool ready) => {
    'type': MsgType.roomReady,
    'ready': ready,
  };

  static Map<String, dynamic> roomStart() => {'type': MsgType.roomStart};

  static Map<String, dynamic> roomTimeControl(TimeControl tc) => {
    'type': MsgType.roomTimeControl,
    'timeControl': tc.toJson(),
  };

  static Map<String, dynamic> roomRematch() => {'type': MsgType.roomRematch};

  static Map<String, dynamic> gameMove(Move m) => {
    'type': MsgType.gameMove,
    'move': m.toJson(),
  };

  static Map<String, dynamic> gamePremove(Move? m) => {
    'type': MsgType.gamePremove,
    'move': m?.toJson(),
  };

  static Map<String, dynamic> gameResign() => {'type': MsgType.gameResign};

  /// [action] is `offer`, `accept` or `decline`.
  static Map<String, dynamic> gameDraw(String action) => {
    'type': MsgType.gameDraw,
    'action': action,
  };

  /// [scope] is `team` (partner only) or `room` (everyone incl. spectators).
  static Map<String, dynamic> chatQuick(QuickChat q, {String scope = 'team'}) =>
      {'type': MsgType.chatSend, 'quick': q.code, 'scope': scope};

  static Map<String, dynamic> chatText(String text, {String scope = 'room'}) =>
      {'type': MsgType.chatSend, 'text': text, 'scope': scope};

  static Map<String, dynamic> testResult(
    String id,
    Map<String, dynamic> payload,
  ) => {'type': MsgType.testResult, 'id': id, ...payload};
}
