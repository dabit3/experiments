import 'game.dart';
import 'piece.dart';
import 'time_control.dart';

/// JSON-over-WebSocket protocol shared by the server and every client.
/// See PROTOCOL.md at the repository root for the human-readable spec.
class Protocol {
  Protocol._();

  static const int version = 1;

  /// Wire message type names (client -> server).
  static const hello = 'hello';
  static const setName = 'set_name';
  static const listRooms = 'list_rooms';
  static const createRoom = 'create_room';
  static const joinRoom = 'join_room';
  static const quickPair = 'quick_pair';
  static const cancelPair = 'cancel_pair';
  static const leaveRoom = 'leave_room';
  static const addBot = 'add_bot';
  static const move = 'move';
  static const resign = 'resign';
  static const offerDraw = 'offer_draw';
  static const acceptDraw = 'accept_draw';
  static const declineDraw = 'decline_draw';
  static const offerTakeback = 'offer_takeback';
  static const acceptTakeback = 'accept_takeback';
  static const declineTakeback = 'decline_takeback';
  static const offerRematch = 'offer_rematch';
  static const acceptRematch = 'accept_rematch';
  static const declineRematch = 'decline_rematch';
  static const ping = 'ping';
  static const uiReport = 'ui_report';

  /// Wire message type names (server -> client).
  static const welcome = 'welcome';
  static const rooms = 'rooms';
  static const roomState = 'room_state';
  static const queued = 'queued';
  static const left = 'left';
  static const error = 'error';
  static const pong = 'pong';
  static const uiCommand = 'ui_command';
}

enum RoomStatus { waiting, playing, finished }

enum PlayerSide {
  white,
  black;

  PieceColor get color =>
      this == PlayerSide.white ? PieceColor.white : PieceColor.black;

  static PlayerSide of(PieceColor color) =>
      color == PieceColor.white ? PlayerSide.white : PlayerSide.black;
}

class Participant {
  const Participant({
    required this.clientId,
    required this.name,
    required this.platform,
    required this.connected,
    this.isBot = false,
    this.botLevel,
  });

  final String clientId;
  final String name;
  final String platform;
  final bool connected;
  final bool isBot;
  final int? botLevel;

  Map<String, Object?> toJson() => {
        'clientId': clientId,
        'name': name,
        'platform': platform,
        'connected': connected,
        'isBot': isBot,
        if (botLevel != null) 'botLevel': botLevel,
      };

  static Participant fromJson(Map<String, Object?> json) => Participant(
        clientId: json['clientId'] as String,
        name: json['name'] as String,
        platform: json['platform'] as String? ?? 'unknown',
        connected: json['connected'] as bool? ?? true,
        isBot: json['isBot'] as bool? ?? false,
        botLevel: (json['botLevel'] as num?)?.toInt(),
      );
}

/// Server-authoritative clock snapshot. Remaining times are exact at
/// [asOfServerMs]; clients extrapolate the running side locally.
class ClockState {
  const ClockState({
    required this.whiteMs,
    required this.blackMs,
    required this.running,
    required this.asOfServerMs,
    required this.frozen,
  });

  final int whiteMs;
  final int blackMs;
  final PieceColor? running;
  final int asOfServerMs;

  /// True in deterministic test mode: clocks never tick.
  final bool frozen;

  Map<String, Object?> toJson() => {
        'whiteMs': whiteMs,
        'blackMs': blackMs,
        'running': running?.letter,
        'asOfServerMs': asOfServerMs,
        'frozen': frozen,
      };

  static ClockState fromJson(Map<String, Object?> json) => ClockState(
        whiteMs: (json['whiteMs'] as num).toInt(),
        blackMs: (json['blackMs'] as num).toInt(),
        running: json['running'] == null
            ? null
            : PieceColor.fromLetter(json['running'] as String),
        asOfServerMs: (json['asOfServerMs'] as num).toInt(),
        frozen: json['frozen'] as bool? ?? false,
      );
}

/// Pending offers keyed by the offering side.
class Offers {
  const Offers({this.draw, this.takeback, this.rematch});

  final PieceColor? draw;
  final PieceColor? takeback;
  final PieceColor? rematch;

  Map<String, Object?> toJson() => {
        'draw': draw?.letter,
        'takeback': takeback?.letter,
        'rematch': rematch?.letter,
      };

  static Offers fromJson(Map<String, Object?>? json) {
    if (json == null) return const Offers();
    PieceColor? read(String key) =>
        json[key] == null ? null : PieceColor.fromLetter(json[key] as String);
    return Offers(
      draw: read('draw'),
      takeback: read('takeback'),
      rematch: read('rematch'),
    );
  }
}

/// Full room snapshot broadcast to everyone in the room after every change.
class RoomSnapshot {
  const RoomSnapshot({
    required this.code,
    required this.seq,
    required this.status,
    required this.timeControl,
    required this.white,
    required this.black,
    required this.spectators,
    required this.hostClientId,
    required this.startFen,
    required this.fen,
    required this.moves,
    required this.turn,
    required this.clocks,
    required this.result,
    required this.offers,
    required this.rematchRoom,
    required this.isPublic,
  });

  final String code;
  final int seq;
  final RoomStatus status;
  final TimeControl timeControl;
  final Participant? white;
  final Participant? black;
  final List<Participant> spectators;
  final String? hostClientId;
  final String startFen;
  final String fen;
  final List<PlayedMove> moves;
  final PieceColor turn;
  final ClockState clocks;
  final GameResult? result;
  final Offers offers;
  final String? rematchRoom;
  final bool isPublic;

  Participant? player(PieceColor color) =>
      color == PieceColor.white ? white : black;

  PieceColor? sideOf(String clientId) {
    if (white?.clientId == clientId) return PieceColor.white;
    if (black?.clientId == clientId) return PieceColor.black;
    return null;
  }

  Map<String, Object?> toJson() => {
        'code': code,
        'seq': seq,
        'status': status.name,
        'timeControl': timeControl.toJson(),
        'white': white?.toJson(),
        'black': black?.toJson(),
        'spectators': spectators.map((s) => s.toJson()).toList(),
        'hostClientId': hostClientId,
        'startFen': startFen,
        'fen': fen,
        'moves': moves.map((m) => m.toJson()).toList(),
        'turn': turn.letter,
        'clocks': clocks.toJson(),
        'result': result?.toJson(),
        'offers': offers.toJson(),
        'rematchRoom': rematchRoom,
        'isPublic': isPublic,
      };

  static RoomSnapshot fromJson(Map<String, Object?> json) => RoomSnapshot(
        code: json['code'] as String,
        seq: (json['seq'] as num?)?.toInt() ?? 0,
        status: RoomStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RoomStatus.waiting,
        ),
        timeControl: TimeControl.fromJson(
          (json['timeControl'] as Map).cast<String, Object?>(),
        ),
        white: json['white'] == null
            ? null
            : Participant.fromJson((json['white'] as Map).cast()),
        black: json['black'] == null
            ? null
            : Participant.fromJson((json['black'] as Map).cast()),
        spectators: ((json['spectators'] as List?) ?? const [])
            .map((s) => Participant.fromJson((s as Map).cast()))
            .toList(),
        hostClientId: json['hostClientId'] as String?,
        startFen: json['startFen'] as String,
        fen: json['fen'] as String,
        moves: ((json['moves'] as List?) ?? const [])
            .map((m) => PlayedMove.fromJson((m as Map).cast()))
            .toList(),
        turn: PieceColor.fromLetter(json['turn'] as String) ?? PieceColor.white,
        clocks: ClockState.fromJson((json['clocks'] as Map).cast()),
        result: GameResult.fromJson((json['result'] as Map?)?.cast()),
        offers: Offers.fromJson((json['offers'] as Map?)?.cast()),
        rematchRoom: json['rematchRoom'] as String?,
        isPublic: json['isPublic'] as bool? ?? true,
      );
}

/// Lobby listing entry.
class RoomListing {
  const RoomListing({
    required this.code,
    required this.hostName,
    required this.hostPlatform,
    required this.timeControl,
    required this.status,
    required this.playerCount,
    required this.spectatorCount,
    required this.hasBot,
  });

  final String code;
  final String hostName;
  final String hostPlatform;
  final TimeControl timeControl;
  final RoomStatus status;
  final int playerCount;
  final int spectatorCount;
  final bool hasBot;

  Map<String, Object?> toJson() => {
        'code': code,
        'hostName': hostName,
        'hostPlatform': hostPlatform,
        'timeControl': timeControl.toJson(),
        'status': status.name,
        'playerCount': playerCount,
        'spectatorCount': spectatorCount,
        'hasBot': hasBot,
      };

  static RoomListing fromJson(Map<String, Object?> json) => RoomListing(
        code: json['code'] as String,
        hostName: json['hostName'] as String,
        hostPlatform: json['hostPlatform'] as String? ?? 'unknown',
        timeControl: TimeControl.fromJson(
          (json['timeControl'] as Map).cast<String, Object?>(),
        ),
        status: RoomStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RoomStatus.waiting,
        ),
        playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
        spectatorCount: (json['spectatorCount'] as num?)?.toInt() ?? 0,
        hasBot: json['hasBot'] as bool? ?? false,
      );
}

/// Error codes the server may return.
class ErrorCodes {
  ErrorCodes._();

  static const badRequest = 'bad_request';
  static const roomNotFound = 'room_not_found';
  static const roomFull = 'room_full';
  static const notInRoom = 'not_in_room';
  static const notYourTurn = 'not_your_turn';
  static const illegalMove = 'illegal_move';
  static const notPlaying = 'not_playing';
  static const notAllowed = 'not_allowed';
}
