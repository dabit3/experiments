import 'dart:async';
import 'dart:convert';

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

class ServerError {
  const ServerError(this.code, this.message, this.inReplyTo);

  final String code;
  final String message;
  final String? inReplyTo;
}

class PlaceListing {
  const PlaceListing(this.info, this.playing, this.rooms);

  final PlaceInfo info;
  final int playing;
  final List<RoomSummary> rooms;
}

class RoomSummary {
  const RoomSummary(this.code, this.players, this.phase);

  final String code;
  final int players;
  final String phase;
}

class FriendsState {
  const FriendsState({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  final List<PlayerSummary> friends;
  final List<PlayerSummary> incoming;
  final List<PlayerSummary> outgoing;
}

class DailyResult {
  const DailyResult({
    required this.claimed,
    required this.reward,
    required this.streak,
    required this.nextClaimAt,
    this.badges = const [],
  });

  final bool claimed;
  final int reward;
  final int streak;
  final int nextClaimAt;
  final List<String> badges;
}

/// One decoded `game.state` frame.
class GameFrame {
  const GameFrame(this.json, this.receivedAt);

  final Map<String, Object?> json;
  final int receivedAt;

  int get tick => (json['tick'] as num).toInt();
  int get ticksLeft => (json['ticksLeft'] as num?)?.toInt() ?? 0;
}

/// WebSocket client for the Brickfolk protocol. All server state lives here
/// and the UI listens through [ChangeNotifier].
class BrickfolkClient extends ChangeNotifier {
  BrickfolkClient({required this.serverUrl, required this.platform});

  final String serverUrl;
  final String platform;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _attempt = 0;
  bool _disposed = false;
  String? _pendingName;
  String? token;

  ConnectionStatus status = ConnectionStatus.disconnected;
  PlayerProfile? me;
  ServerError? lastError;
  bool serverTestMode = false;
  int serverTimeOffsetMs = 0;
  int onlineCount = 0;
  List<PlaceListing> places = const [];
  FriendsState friends = const FriendsState();
  PartyState? party;
  RoomState? room;
  int roomBotCount = 0;
  MatchResults? results;
  int? resultsEndsAt;
  GameFrame? frame;
  GameFrame? previousFrame;
  final List<ChatMessage> chat = [];
  final StreamController<ServerError> _errors = StreamController.broadcast();
  final StreamController<Map<String, Object?>> _events =
      StreamController.broadcast();
  final StreamController<DailyResult> _daily = StreamController.broadcast();
  final StreamController<PlayerProfile> _profiles =
      StreamController.broadcast();
  final StreamController<Map<String, Object?>> _testControl =
      StreamController.broadcast();
  final StreamController<MatchResults> _resultsStream =
      StreamController.broadcast();

  Stream<ServerError> get errors => _errors.stream;

  /// Raw `game.event` payloads (one per event).
  Stream<Map<String, Object?>> get gameEvents => _events.stream;
  Stream<DailyResult> get dailyResults => _daily.stream;
  Stream<PlayerProfile> get profiles => _profiles.stream;
  Stream<Map<String, Object?>> get testControl => _testControl.stream;
  Stream<MatchResults> get resultsStream => _resultsStream.stream;

  bool get connected => status == ConnectionStatus.connected;
  bool get signedIn => me != null && connected;
  String? get myId => me?.summary.id;
  bool get inRoom => room != null;
  bool get isPartyLeader => party != null && party!.leaderId == myId;

  int serverNow() => DateTime.now().millisecondsSinceEpoch + serverTimeOffsetMs;

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  /// Connects and signs in with [name] (new player) or [token] (returning).
  void signIn({String? name, String? savedToken}) {
    _pendingName = name;
    token = savedToken ?? token;
    lastError = null;
    _connect();
  }

  void _connect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    status = _attempt == 0
        ? ConnectionStatus.connecting
        : ConnectionStatus.reconnecting;
    notifyListeners();
    try {
      final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel = channel;
      _sub = channel.stream.listen(
        (data) {
          if (data is String) _onFrame(data);
        },
        onDone: _onClosed,
        onError: (_) => _onClosed(),
        cancelOnError: true,
      );
      channel.ready.then((_) {
        _send({
          'type': MsgType.hello,
          'protocolVersion': protocolVersion,
          'name': _pendingName,
          'token': token,
          'platform': platform,
        });
      }, onError: (_) => _onClosed());
    } catch (_) {
      _onClosed();
    }
  }

  void _onClosed() {
    if (_disposed) return;
    _pingTimer?.cancel();
    final wasSignedIn = me != null;
    status = ConnectionStatus.disconnected;
    frame = null;
    previousFrame = null;
    notifyListeners();
    if (!wasSignedIn && token == null && _pendingName == null) return;
    // Exponential backoff capped at 8 seconds.
    _attempt++;
    final delay = Duration(milliseconds: (400 * (1 << _attempt.clamp(0, 4))));
    status = ConnectionStatus.reconnecting;
    notifyListeners();
    _reconnectTimer = Timer(delay, _connect);
  }

  void signOut() {
    token = null;
    _pendingName = null;
    me = null;
    room = null;
    party = null;
    results = null;
    chat.clear();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  void _send(Map<String, Object?> frame) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(frame));
  }

  void _onFrame(String raw) {
    final msg = (jsonDecode(raw) as Map).cast<String, Object?>();
    final type = msg['type'] as String?;
    switch (type) {
      case MsgType.welcome:
        _attempt = 0;
        status = ConnectionStatus.connected;
        token = msg['token'] as String?;
        me = PlayerProfile.fromJson((msg['player'] as Map).cast());
        serverTestMode = msg['testMode'] == true;
        serverTimeOffsetMs =
            (msg['serverTime'] as num).toInt() -
            DateTime.now().millisecondsSinceEpoch;
        _pingTimer?.cancel();
        _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          _send({
            'type': MsgType.ping,
            'nonce': DateTime.now().millisecondsSinceEpoch,
          });
        });
        if (msg['roomCode'] == null) room = null;
        if (msg['partyCode'] == null) party = null;
      case MsgType.pong:
        serverTimeOffsetMs =
            (msg['serverTime'] as num).toInt() -
            DateTime.now().millisecondsSinceEpoch;
        return;
      case MsgType.error:
        lastError = ServerError(
          msg['code'] as String? ?? ErrorCode.badRequest,
          msg['message'] as String? ?? 'Something went wrong.',
          msg['inReplyTo'] as String?,
        );
        if (lastError!.inReplyTo == MsgType.hello &&
            lastError!.code == ErrorCode.unauthenticated) {
          // The saved token no longer resolves to a player (e.g. the server
          // database was reset): forget it so the sign-in form takes over.
          token = null;
        }
        _errors.add(lastError!);
      case MsgType.playerUpdated:
        me = PlayerProfile.fromJson((msg['player'] as Map).cast());
      case MsgType.dailyResult:
        _daily.add(
          DailyResult(
            claimed: msg['claimed'] == true,
            reward: (msg['reward'] as num?)?.toInt() ?? 0,
            streak: (msg['streak'] as num?)?.toInt() ?? 0,
            nextClaimAt: (msg['nextClaimAt'] as num?)?.toInt() ?? 0,
            badges: ((msg['badges'] as List?) ?? const []).cast<String>(),
          ),
        );
        return;
      case MsgType.friendsState:
        List<PlayerSummary> list(String key) =>
            ((msg[key] as List?) ?? const [])
                .map((e) => PlayerSummary.fromJson((e as Map).cast()))
                .toList();
        friends = FriendsState(
          friends: list('friends'),
          incoming: list('incoming'),
          outgoing: list('outgoing'),
        );
      case MsgType.partyState:
        final raw = msg['party'];
        party = raw is Map ? PartyState.fromJson(raw.cast()) : null;
      case MsgType.chatMessage:
        chat.add(ChatMessage.fromJson((msg['message'] as Map).cast()));
        if (chat.length > 200) chat.removeAt(0);
      case MsgType.places:
        onlineCount = (msg['online'] as num?)?.toInt() ?? 0;
        places = [
          for (final p in (msg['places'] as List))
            PlaceListing(
              placeFor(ExperienceKind.fromId((p as Map)['kind'] as String)!),
              (p['playing'] as num?)?.toInt() ?? 0,
              [
                for (final r in (p['rooms'] as List? ?? const []))
                  RoomSummary(
                    (r as Map)['code'] as String,
                    (r['players'] as num).toInt(),
                    r['phase'] as String,
                  ),
              ],
            ),
        ];
      case MsgType.profile:
        _profiles.add(PlayerProfile.fromJson((msg['profile'] as Map).cast()));
        return;
      case MsgType.roomState:
        final raw = msg['room'];
        final previous = room;
        room = raw is Map ? RoomState.fromJson(raw.cast()) : null;
        roomBotCount = (msg['botCount'] as num?)?.toInt() ?? 0;
        if (room == null || previous?.code != room!.code) {
          results = null;
          frame = null;
          previousFrame = null;
        }
        if (room?.phase == RoomPhase.playing &&
            previous?.phase != RoomPhase.playing) {
          results = null;
        }
        if (room?.phase == RoomPhase.lobby) {
          frame = null;
          previousFrame = null;
        }
      case MsgType.gameState:
        previousFrame = frame;
        frame = GameFrame(msg, DateTime.now().millisecondsSinceEpoch);
      case MsgType.gameEvent:
        for (final e in (msg['events'] as List? ?? const [])) {
          _events.add((e as Map).cast<String, Object?>());
        }
        return;
      case MsgType.gameResults:
        results = MatchResults.fromJson((msg['results'] as Map).cast());
        resultsEndsAt = (msg['resultsEndsAt'] as num?)?.toInt();
        _resultsStream.add(results!);
      case MsgType.testControl:
        _testControl.add(msg);
        return;
      default:
        return;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  void updateAvatar(Avatar avatar) =>
      _send({'type': MsgType.avatarUpdate, 'avatar': avatar.toJson()});

  void buy(String itemId) => _send({'type': MsgType.shopBuy, 'item': itemId});

  void claimDaily() => _send({'type': MsgType.dailyClaim});

  void friendRequest(String name) =>
      _send({'type': MsgType.friendsRequest, 'player': name});

  void friendAccept(String id) =>
      _send({'type': MsgType.friendsAccept, 'player': id});

  void friendDecline(String id) =>
      _send({'type': MsgType.friendsDecline, 'player': id});

  void friendRemove(String id) =>
      _send({'type': MsgType.friendsRemove, 'player': id});

  void partyCreate({String? code}) =>
      _send({'type': MsgType.partyCreate, 'code': ?code});

  void partyJoin(String code) =>
      _send({'type': MsgType.partyJoin, 'code': code});

  void partyLeave() => _send({'type': MsgType.partyLeave});

  void partyLaunch(ExperienceKind kind, {int bots = 2}) =>
      _send({'type': MsgType.partyLaunch, 'experience': kind.id, 'bots': bots});

  void chatSend(String channel, String text) =>
      _send({'type': MsgType.chatSend, 'channel': channel, 'text': text});

  void refreshPlaces() => _send({'type': MsgType.placesList});

  void profileGet([String? nameOrId]) =>
      _send({'type': MsgType.profileGet, 'player': nameOrId});

  void roomCreate(ExperienceKind kind, {int bots = 2}) =>
      _send({'type': MsgType.roomCreate, 'experience': kind.id, 'bots': bots});

  void roomJoin(String code) => _send({'type': MsgType.roomJoin, 'code': code});

  void roomLeave() {
    _send({'type': MsgType.roomLeave});
    room = null;
    results = null;
    frame = null;
    notifyListeners();
  }

  void roomReady(bool ready) =>
      _send({'type': MsgType.roomReady, 'ready': ready});

  void sendInput(Map<String, Object?> data) =>
      _send({'type': MsgType.input, 'data': data});

  void testReport(String phase, Map<String, Object?> payload) =>
      _send({'type': MsgType.testReport, 'phase': phase, 'payload': payload});

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _errors.close();
    _events.close();
    _daily.close();
    _profiles.close();
    _testControl.close();
    _resultsStream.close();
    super.dispose();
  }
}
