import 'dart:convert';
import 'dart:math';

import 'package:brickfolk_shared/brickfolk_shared.dart';

import 'clock.dart';
import 'db.dart';
import 'games.dart';
import 'room.dart';

/// A connected client. One per WebSocket.
class Session {
  Session(this.id, this._send, this._close);

  final int id;
  final void Function(String) _send;
  final void Function() _close;

  PlayerRecord? player;
  String platform = 'unknown';
  String? roomCode;
  int lastChatMs = 0;
  bool closed = false;

  bool get authenticated => player != null;

  void send(Map<String, Object?> frame) {
    if (closed) return;
    _send(jsonEncode(frame));
  }

  void error(String code, String message, {String? inReplyTo}) => send({
    'type': MsgType.error,
    'code': code,
    'message': message,
    'inReplyTo': ?inReplyTo,
  });

  void close() {
    closed = true;
    _close();
  }
}

class Party {
  Party(this.code, this.leaderId);

  final String code;
  String leaderId;
  final members = <String>[];
  String? roomCode;
  ExperienceKind? experience;
}

class TestReport {
  const TestReport(
    this.playerId,
    this.platform,
    this.phase,
    this.payload,
    this.receivedAt,
  );

  final String playerId;
  final String platform;
  final String phase;
  final Map<String, Object?> payload;
  final int receivedAt;

  Map<String, Object?> toJson() => {
    'playerId': playerId,
    'platform': platform,
    'phase': phase,
    'payload': payload,
    'receivedAt': receivedAt,
  };
}

/// Owns every session, party and room. Single-threaded by design.
class Hub implements RoomHost {
  Hub({
    required this.store,
    required this.clock,
    required int seed,
    this.testMode = false,
    this.matchLengthScale = 1.0,
    this.resultsMs = Room.defaultResultsMs,
    this.log,
  }) : rng = SeededRng(seed) {
    _random = seed == 0 ? Random.secure() : Random(seed);
  }

  final Store store;
  final Clock clock;
  final bool testMode;

  /// Stretches match timers so slow test clients (software-emulated Android)
  /// can finish; results only depend on what happens before the timer ends.
  @override
  final double matchLengthScale;

  /// How long a room shows results before returning to its lobby.
  @override
  final int resultsMs;
  final SeededRng rng;
  final void Function(String)? log;
  late final Random _random;

  final sessions = <int, Session>{};
  final byPlayer = <String, Session>{};
  final rooms = <String, Room>{};
  final parties = <String, Party>{};
  final partyOf = <String, String>{};
  final chatFilter = ChatFilter();
  final testReports = <TestReport>[];
  final chatHistory = <String, List<ChatMessage>>{};
  int _chatId = 0;
  int _sessionCounter = 0;
  int tickCount = 0;

  static const codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  int nowMs() => clock.nowMs();

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  Session connect(void Function(String) send, void Function() close) {
    final s = Session(++_sessionCounter, send, close);
    sessions[s.id] = s;
    return s;
  }

  void disconnect(Session s) {
    sessions.remove(s.id);
    s.closed = true;
    final p = s.player;
    if (p == null) return;
    if (byPlayer[p.id] == s) {
      byPlayer.remove(p.id);
      rooms[s.roomCode]?.markDisconnected(p.id);
      _broadcastPartyState(partyOf[p.id]);
      _notifyFriendsPresence(p.id);
      _broadcastPlaces();
    }
  }

  void handle(Session s, String raw) {
    Map<String, Object?> msg;
    try {
      msg = (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (_) {
      s.error(ErrorCode.badRequest, 'Frame is not a JSON object.');
      return;
    }
    final type = msg['type'];
    if (type is! String) {
      s.error(ErrorCode.badRequest, 'Missing type.');
      return;
    }
    if (type == MsgType.hello) {
      _hello(s, msg);
      return;
    }
    if (type == MsgType.ping) {
      s.send({
        'type': MsgType.pong,
        'nonce': msg['nonce'],
        'serverTime': nowMs(),
      });
      return;
    }
    final p = s.player;
    if (p == null) {
      s.error(ErrorCode.unauthenticated, 'Send hello first.', inReplyTo: type);
      return;
    }
    switch (type) {
      case MsgType.avatarUpdate:
        _avatarUpdate(s, p, msg);
      case MsgType.shopBuy:
        _shopBuy(s, p, msg);
      case MsgType.dailyClaim:
        _dailyClaim(s, p);
      case MsgType.friendsRequest:
        _friendsRequest(s, p, msg);
      case MsgType.friendsAccept:
        _friendsRespond(s, p, msg, accept: true);
      case MsgType.friendsDecline:
        _friendsRespond(s, p, msg, accept: false);
      case MsgType.friendsRemove:
        _friendsRemove(s, p, msg);
      case MsgType.partyCreate:
        _partyCreate(s, p, msg);
      case MsgType.partyJoin:
        _partyJoin(s, p, msg);
      case MsgType.partyLeave:
        _partyLeave(s, p);
      case MsgType.partyLaunch:
        _partyLaunch(s, p, msg);
      case MsgType.chatSend:
        _chatSend(s, p, msg);
      case MsgType.placesList:
        _sendPlaces(s);
      case MsgType.placeRate:
        _placeRate(s, p, msg);
      case MsgType.profileGet:
        _profileGet(s, p, msg);
      case MsgType.roomCreate:
        _roomCreate(s, p, msg);
      case MsgType.roomJoin:
        _roomJoin(s, p, msg);
      case MsgType.roomLeave:
        _roomLeave(s, p);
      case MsgType.roomReady:
        rooms[s.roomCode]?.setReady(p.id, msg['ready'] != false);
      case MsgType.input:
        final data = msg['data'];
        if (data is Map) {
          rooms[s.roomCode]?.handleInput(p.id, data.cast<String, Object?>());
        }
      case MsgType.testReport:
        _testReport(s, p, msg);
      default:
        s.error(ErrorCode.badRequest, 'Unknown type $type.', inReplyTo: type);
    }
  }

  // ---------------------------------------------------------------------------
  // Hello / identity
  // ---------------------------------------------------------------------------

  void _hello(Session s, Map<String, Object?> msg) {
    final version = msg['protocolVersion'];
    if (version != protocolVersion) {
      s.error(
        ErrorCode.badRequest,
        'Unsupported protocol version $version (server $protocolVersion).',
        inReplyTo: MsgType.hello,
      );
      s.close();
      return;
    }
    s.platform = (msg['platform'] as String?) ?? 'unknown';
    final token = msg['token'] as String?;
    final name = (msg['name'] as String?)?.trim();
    PlayerRecord? record;
    if (token != null) record = store.byToken(token);
    if (record == null) {
      if (token != null && name == null) {
        s.error(
          ErrorCode.unauthenticated,
          'Your saved session is no longer valid. Sign in with a name.',
          inReplyTo: MsgType.hello,
        );
        return;
      }
      if (name == null || !playerNamePattern.hasMatch(name)) {
        s.error(
          ErrorCode.invalidName,
          'Names are 3-16 letters, digits or underscores and start with a letter.',
          inReplyTo: MsgType.hello,
        );
        return;
      }
      final taken = store.byName(name);
      if (taken != null && testMode && !byPlayer.containsKey(taken.id)) {
        // Test harnesses reuse fixed names across restarts.
        record = taken;
      } else if (taken != null) {
        s.error(
          ErrorCode.nameTaken,
          'That name is already taken.',
          inReplyTo: MsgType.hello,
        );
        return;
      }
      record ??= store.create(
        id: 'p${store.playerCount + 1}_${_code(4)}',
        name: name,
        token: _code(32),
        nowMs: nowMs(),
      );
      log?.call('player ${record.name} (${record.id}) on ${s.platform}');
    }
    // Replace any older session for the same player (reconnect).
    final old = byPlayer[record.id];
    if (old != null && old != s) {
      old.send({
        'type': MsgType.error,
        'code': ErrorCode.badRequest,
        'message': 'Signed in from another client.',
      });
      old.player = null;
      old.close();
      sessions.remove(old.id);
      s.roomCode = old.roomCode;
    } else {
      // Rejoin a room the player was in before disconnecting.
      for (final r in rooms.values) {
        if (r.seats.containsKey(record.id)) s.roomCode = r.code;
      }
    }
    s.player = record;
    byPlayer[record.id] = s;
    s.send({
      'type': MsgType.welcome,
      'protocolVersion': protocolVersion,
      'token': record.token,
      'player': record.profile(platform: s.platform).toJson(),
      'serverTime': nowMs(),
      'testMode': testMode,
      'roomCode': s.roomCode,
      'partyCode': partyOf[record.id],
    });
    _broadcastPlaces();
    _sendFriends(s, record);
    _notifyFriendsPresence(record.id);
    final party = parties[partyOf[record.id]];
    if (party != null) _broadcastPartyState(party.code);
    final room = rooms[s.roomCode];
    if (room != null) {
      room.join(record.summary(platform: s.platform));
    }
    for (final m in chatHistory[ChatChannel.global] ?? const <ChatMessage>[]) {
      s.send({'type': MsgType.chatMessage, 'message': m.toJson()});
    }
  }

  PlayerSummary _summaryOf(PlayerRecord p) {
    final s = byPlayer[p.id];
    return p.summary(platform: s?.platform ?? 'unknown', online: s != null);
  }

  void _pushPlayer(Session s, PlayerRecord p) {
    store.save(p);
    s.send({
      'type': MsgType.playerUpdated,
      'player': p.profile(platform: s.platform).toJson(),
    });
  }

  // ---------------------------------------------------------------------------
  // Avatar, shop, daily
  // ---------------------------------------------------------------------------

  void _avatarUpdate(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final raw = msg['avatar'];
    if (raw is! Map) {
      s.error(
        ErrorCode.badRequest,
        'Missing avatar.',
        inReplyTo: msg['type'] as String,
      );
      return;
    }
    p.avatar = Avatar.fromJson(raw.cast<String, Object?>()).sanitized(p.owned);
    _pushPlayer(s, p);
    final summary = _summaryOf(p);
    rooms[s.roomCode]?.updateAvatar(summary);
    _broadcastPartyState(partyOf[p.id]);
  }

  void _shopBuy(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final item = catalogById[msg['item']];
    if (item == null) {
      s.error(ErrorCode.notFound, 'Unknown item.', inReplyTo: MsgType.shopBuy);
      return;
    }
    if (p.owned.contains(item.id)) {
      s.error(
        ErrorCode.alreadyOwned,
        'You already own ${item.name}.',
        inReplyTo: MsgType.shopBuy,
      );
      return;
    }
    if (p.pips < item.price) {
      s.error(
        ErrorCode.notEnoughPips,
        'You need ${item.price - p.pips} more pips for ${item.name}.',
        inReplyTo: MsgType.shopBuy,
      );
      return;
    }
    p.pips -= item.price;
    p.owned.add(item.id);
    p.bump('itemsBought');
    _pushPlayer(s, p);
  }

  void _dailyClaim(Session s, PlayerRecord p) {
    final now = nowMs();
    if (!DailyReward.canClaim(p.lastDailyClaim, now)) {
      s.send({
        'type': MsgType.dailyResult,
        'claimed': false,
        'reward': 0,
        'streak': p.dailyStreak,
        'nextClaimAt': p.lastDailyClaim! + DailyReward.dayMs,
      });
      return;
    }
    p.dailyStreak = DailyReward.nextStreak(
      p.lastDailyClaim,
      p.dailyStreak,
      now,
    );
    p.lastDailyClaim = now;
    final reward = DailyReward.rewardForStreak(p.dailyStreak);
    p.pips += reward;
    final newBadges = <String>[];
    if (p.dailyStreak >= 3 && p.award('streak_3')) newBadges.add('streak_3');
    _pushPlayer(s, p);
    s.send({
      'type': MsgType.dailyResult,
      'claimed': true,
      'reward': reward,
      'streak': p.dailyStreak,
      'nextClaimAt': now + DailyReward.dayMs,
      'badges': newBadges,
    });
  }

  // ---------------------------------------------------------------------------
  // Friends
  // ---------------------------------------------------------------------------

  void _sendFriends(Session s, PlayerRecord p) {
    final rows = store.friendRowsFor(p.id);
    final friends = <Map<String, Object?>>[];
    final incoming = <Map<String, Object?>>[];
    final outgoing = <Map<String, Object?>>[];
    for (final r in rows) {
      final otherId = r.fromId == p.id ? r.toId : r.fromId;
      final other = store.byId(otherId);
      if (other == null) continue;
      final json = _summaryOf(other).toJson();
      if (r.accepted) {
        friends.add(json);
      } else if (r.fromId == p.id) {
        outgoing.add(json);
      } else {
        incoming.add(json);
      }
    }
    s.send({
      'type': MsgType.friendsState,
      'friends': friends,
      'incoming': incoming,
      'outgoing': outgoing,
    });
  }

  void _notifyFriendsPresence(String playerId) {
    for (final r in store.friendRowsFor(playerId)) {
      final otherId = r.fromId == playerId ? r.toId : r.fromId;
      final other = byPlayer[otherId];
      if (other?.player != null) _sendFriends(other!, other.player!);
    }
  }

  PlayerRecord? _lookup(Session s, Object? nameOrId, String inReplyTo) {
    if (nameOrId is! String) {
      s.error(ErrorCode.badRequest, 'Missing player.', inReplyTo: inReplyTo);
      return null;
    }
    final r = store.byName(nameOrId) ?? store.byId(nameOrId);
    if (r == null) {
      s.error(
        ErrorCode.notFound,
        'No player named $nameOrId.',
        inReplyTo: inReplyTo,
      );
    }
    return r;
  }

  void _friendsRequest(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final other = _lookup(s, msg['player'], MsgType.friendsRequest);
    if (other == null) return;
    if (other.id == p.id) {
      s.error(
        ErrorCode.badRequest,
        "You can't friend yourself.",
        inReplyTo: MsgType.friendsRequest,
      );
      return;
    }
    final existing = store.friendRow(p.id, other.id);
    if (existing != null && existing.fromId == other.id && !existing.accepted) {
      // They already asked us: accept.
      store.acceptRequest(other.id, p.id);
      _friendsMade(p, other);
    } else if (existing == null) {
      store.addRequest(p.id, other.id);
    }
    _sendFriends(s, p);
    final otherSession = byPlayer[other.id];
    if (otherSession != null) _sendFriends(otherSession, other);
  }

  void _friendsRespond(
    Session s,
    PlayerRecord p,
    Map<String, Object?> msg, {
    required bool accept,
  }) {
    final other = _lookup(s, msg['player'], msg['type'] as String);
    if (other == null) return;
    final row = store.friendRow(p.id, other.id);
    if (row == null || row.accepted || row.fromId != other.id) {
      s.error(
        ErrorCode.notFound,
        'No pending request from ${other.name}.',
        inReplyTo: msg['type'] as String,
      );
      return;
    }
    if (accept) {
      store.acceptRequest(other.id, p.id);
      _friendsMade(p, other);
    } else {
      store.removeFriendship(p.id, other.id);
    }
    _sendFriends(s, p);
    final otherSession = byPlayer[other.id];
    if (otherSession != null) _sendFriends(otherSession, other);
  }

  void _friendsMade(PlayerRecord a, PlayerRecord b) {
    for (final p in [a, b]) {
      p.bump('friends');
      if (p.award('social')) {
        store.save(p);
        final session = byPlayer[p.id];
        if (session != null) _pushPlayer(session, p);
      } else {
        store.save(p);
      }
    }
  }

  void _friendsRemove(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final other = _lookup(s, msg['player'], MsgType.friendsRemove);
    if (other == null) return;
    store.removeFriendship(p.id, other.id);
    _sendFriends(s, p);
    final otherSession = byPlayer[other.id];
    if (otherSession != null) _sendFriends(otherSession, other);
  }

  // ---------------------------------------------------------------------------
  // Parties
  // ---------------------------------------------------------------------------

  String _code(int length) => List.generate(
    length,
    (_) => codeAlphabet[_random.nextInt(codeAlphabet.length)],
  ).join();

  String _uniqueCode(Map<String, Object?> taken) {
    while (true) {
      final code = _code(4);
      if (!taken.containsKey(code)) return code;
    }
  }

  PartyState _partyState(Party party) => PartyState(
    code: party.code,
    leaderId: party.leaderId,
    members: [
      for (final id in party.members)
        if (store.byId(id) case final r?) _summaryOf(r),
    ],
    roomCode: party.roomCode,
    experience: party.experience,
  );

  void _broadcastPartyState(String? code) {
    final party = parties[code];
    if (party == null) return;
    final frame = {
      'type': MsgType.partyState,
      'party': _partyState(party).toJson(),
    };
    for (final id in party.members) {
      byPlayer[id]?.send(frame);
    }
  }

  void _partyCreate(Session s, PlayerRecord p, Map<String, Object?> msg) {
    // Test mode lets clients pick a code so scripted clients can meet up.
    final requested = (msg['code'] as String?)?.toUpperCase().trim();
    if (requested != null && partyOf[p.id] == requested) {
      // Repeated create for a party the player already leads (a client that
      // retried before our state reached it) must not split the party.
      _broadcastPartyState(requested);
      return;
    }
    _partyLeave(s, p, silent: true);
    final code =
        testMode &&
            requested != null &&
            requested.isNotEmpty &&
            !parties.containsKey(requested)
        ? requested
        : _uniqueCode(parties);
    final party = Party(code, p.id)..members.add(p.id);
    parties[party.code] = party;
    partyOf[p.id] = party.code;
    log?.call('party ${party.code} created by ${p.name}');
    _broadcastPartyState(party.code);
  }

  void _partyJoin(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final code = (msg['code'] as String?)?.toUpperCase().trim();
    final party = parties[code];
    if (party == null) {
      s.error(
        ErrorCode.notFound,
        'No party with code $code.',
        inReplyTo: MsgType.partyJoin,
      );
      return;
    }
    if (partyOf[p.id] == party.code) {
      _broadcastPartyState(party.code);
      return;
    }
    if (party.members.length >= maxRoomPlayers) {
      s.error(
        ErrorCode.roomFull,
        'That party is full.',
        inReplyTo: MsgType.partyJoin,
      );
      return;
    }
    _partyLeave(s, p, silent: true);
    party.members.add(p.id);
    partyOf[p.id] = party.code;
    log?.call(
      'party ${party.code}: ${p.name} joined (${party.members.length})',
    );
    _broadcastPartyState(party.code);
    // Follow the party into its room if it already launched.
    if (party.roomCode != null && rooms.containsKey(party.roomCode)) {
      _enterRoom(s, p, rooms[party.roomCode]!);
    }
  }

  void _partyLeave(Session s, PlayerRecord p, {bool silent = false}) {
    final code = partyOf.remove(p.id);
    final party = parties[code];
    if (party == null) {
      if (!silent) {
        s.send({'type': MsgType.partyState, 'party': null});
      }
      return;
    }
    party.members.remove(p.id);
    log?.call('party ${party.code}: ${p.name} left (${party.members.length})');
    if (party.members.isEmpty) {
      parties.remove(party.code);
    } else {
      if (party.leaderId == p.id) party.leaderId = party.members.first;
      _broadcastPartyState(party.code);
    }
    s.send({'type': MsgType.partyState, 'party': null});
  }

  void _partyLaunch(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final party = parties[partyOf[p.id]];
    if (party == null) {
      s.error(
        ErrorCode.notFound,
        'You are not in a party.',
        inReplyTo: MsgType.partyLaunch,
      );
      return;
    }
    if (party.leaderId != p.id) {
      s.error(
        ErrorCode.notLeader,
        'Only the party leader can launch.',
        inReplyTo: MsgType.partyLaunch,
      );
      return;
    }
    final kind = ExperienceKind.fromId(msg['experience'] as String?);
    if (kind == null) {
      s.error(
        ErrorCode.notFound,
        'Unknown experience.',
        inReplyTo: MsgType.partyLaunch,
      );
      return;
    }
    final room = _createRoom(
      kind,
      (msg['bots'] as num?)?.toInt(),
      partyCode: party.code,
    );
    party.roomCode = room.code;
    party.experience = kind;
    for (final id in party.members) {
      final member = byPlayer[id];
      if (member?.player != null) _enterRoom(member!, member.player!, room);
    }
    _broadcastPartyState(party.code);
    _broadcastPlaces();
  }

  // ---------------------------------------------------------------------------
  // Rooms
  // ---------------------------------------------------------------------------

  Room _createRoom(ExperienceKind kind, int? bots, {String? partyCode}) {
    final place = placeFor(kind);
    final room = Room(
      code: _uniqueCode(rooms),
      experience: kind,
      seed: rng.nextInt32(),
      host: this,
      botCount: (bots ?? (place.minPlayers + 1)).clamp(0, maxRoomPlayers - 1),
      partyCode: partyCode,
    );
    rooms[room.code] = room;
    log?.call(
      'room ${room.code} created for ${kind.id} (bots ${room.botCount})',
    );
    return room;
  }

  void _enterRoom(Session s, PlayerRecord p, Room room) {
    if (s.roomCode != null && s.roomCode != room.code) {
      rooms[s.roomCode]?.leave(p.id);
    }
    if (!room.join(p.summary(platform: s.platform))) {
      s.error(
        ErrorCode.roomFull,
        'Room ${room.code} is full.',
        inReplyTo: MsgType.roomJoin,
      );
      return;
    }
    s.roomCode = room.code;
    store.bumpVisits(room.experience.id);
    _broadcastPlaces();
  }

  void _roomCreate(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final kind = ExperienceKind.fromId(msg['experience'] as String?);
    if (kind == null) {
      s.error(
        ErrorCode.notFound,
        'Unknown experience.',
        inReplyTo: MsgType.roomCreate,
      );
      return;
    }
    final room = _createRoom(kind, (msg['bots'] as num?)?.toInt());
    _enterRoom(s, p, room);
    final party = parties[partyOf[p.id]];
    if (party != null && party.leaderId == p.id) {
      party.roomCode = room.code;
      party.experience = kind;
      for (final id in party.members) {
        final member = byPlayer[id];
        if (member?.player != null && member!.player!.id != p.id) {
          _enterRoom(member, member.player!, room);
        }
      }
      _broadcastPartyState(party.code);
    }
  }

  void _roomJoin(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final code = (msg['code'] as String?)?.toUpperCase().trim();
    final room = rooms[code];
    if (room == null) {
      s.error(
        ErrorCode.notFound,
        'No room with code $code.',
        inReplyTo: MsgType.roomJoin,
      );
      return;
    }
    _enterRoom(s, p, room);
  }

  void _roomLeave(Session s, PlayerRecord p) {
    final room = rooms[s.roomCode];
    s.roomCode = null;
    room?.leave(p.id);
    s.send({'type': MsgType.roomState, 'room': null});
    _broadcastPlaces();
  }

  @override
  void sendTo(String playerId, Map<String, Object?> frame) =>
      byPlayer[playerId]?.send(frame);

  @override
  void broadcast(Room room, Map<String, Object?> frame) {
    for (final id in room.seats.keys) {
      byPlayer[id]?.send(frame);
    }
  }

  @override
  TycoonPlot plotFor(String playerId) =>
      store.byId(playerId)?.plot ?? TycoonPlot();

  @override
  void roomClosed(Room room) {
    rooms.remove(room.code);
    for (final party in parties.values) {
      if (party.roomCode == room.code) {
        party.roomCode = null;
        party.experience = null;
        _broadcastPartyState(party.code);
      }
    }
    _broadcastPlaces();
  }

  @override
  MatchResults finalizeResults(Room room, List<RawResult> raw, int durationMs) {
    final entries = <LeaderboardEntry>[];
    final n = raw.length;
    for (var i = 0; i < n; i++) {
      final r = raw[i];
      final rank = i + 1;
      final participant = room.game!.participants.firstWhere(
        (p) => p.id == r.playerId,
      );
      var pips = 0;
      final newBadges = <String>[];
      if (!participant.isBot) {
        final record = store.byId(r.playerId);
        if (record != null) {
          pips = _pipsForRank(room.experience, rank, n, r.score);
          record.pips += pips;
          record.bump('matches');
          record.bump('matches_${room.experience.id}');
          if (rank == 1) record.bump('wins');
          record.bump('pipsEarned', pips);
          switch (room.experience) {
            case ExperienceKind.obby:
              if (r.detail.startsWith('Finished')) record.bump('obbyFinishes');
            case ExperienceKind.tycoon:
              record.bump(
                'bricksPlaced',
                participant.plot.bricksPlaced - participant.bricksAtStart,
              );
            case ExperienceKind.tag:
              record.bump('freezes', r.stat);
          }
          for (final b in r.badges) {
            if (record.award(b)) newBadges.add(b);
          }
          if (room.experience == ExperienceKind.tycoon) {
            record.plot = participant.plot;
          }
          store.save(record);
          final session = byPlayer[r.playerId];
          if (session != null) _pushPlayer(session, record);
        }
      }
      entries.add(
        LeaderboardEntry(
          rank: rank,
          player: participant.summary,
          score: r.score,
          detail: r.detail,
          pipsEarned: pips,
          badgesEarned: newBadges,
        ),
      );
    }
    final results = MatchResults(
      roomCode: room.code,
      experience: room.experience,
      entries: entries,
      checksum: MatchResults.computeChecksum(entries),
      durationMs: durationMs,
    );
    log?.call(
      'room ${room.code} match ${room.matchNumber} finished '
      'checksum=${results.checksum}',
    );
    return results;
  }

  int _pipsForRank(ExperienceKind kind, int rank, int players, int score) {
    final base = switch (kind) {
      ExperienceKind.obby => 40,
      ExperienceKind.tycoon => 30,
      ExperienceKind.tag => 35,
    };
    final placeBonus = ((players - rank) * 15).clamp(0, 105);
    return base + placeBonus;
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  void _chatSend(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final now = nowMs();
    if (now - s.lastChatMs < 700) {
      s.error(
        ErrorCode.rateLimited,
        'Slow down a little.',
        inReplyTo: MsgType.chatSend,
      );
      return;
    }
    final text = msg['text'];
    final channel = (msg['channel'] as String?) ?? ChatChannel.global;
    if (text is! String || text.trim().isEmpty) return;
    final result = chatFilter.filter(text);
    if (result.text.isEmpty) return;
    s.lastChatMs = now;
    final message = ChatMessage(
      id: ++_chatId,
      channel: channel,
      from: _summaryOf(p),
      text: result.text,
      filtered: result.filtered,
      timestamp: now,
    );
    final frame = {'type': MsgType.chatMessage, 'message': message.toJson()};
    switch (channel) {
      case ChatChannel.party:
        final party = parties[partyOf[p.id]];
        if (party == null) return;
        for (final id in party.members) {
          byPlayer[id]?.send(frame);
        }
      case ChatChannel.room:
        final room = rooms[s.roomCode];
        if (room == null) return;
        broadcast(room, frame);
      default:
        final history = chatHistory.putIfAbsent(ChatChannel.global, () => []);
        history.add(message);
        if (history.length > 30) history.removeAt(0);
        for (final other in byPlayer.values) {
          other.send(frame);
        }
    }
    p.bump('messages');
  }

  // ---------------------------------------------------------------------------
  // Places, profiles
  // ---------------------------------------------------------------------------

  Map<String, Object?> _placesFrame(Session s) {
    final votes = s.player == null
        ? const <String, bool>{}
        : store.votesOf(s.player!.id);
    return {
      'type': MsgType.places,
      'places': [
        for (final place in places)
          {
            ...place.toJson(),
            'playing': rooms.values
                .where((r) => r.experience == place.kind)
                .fold<int>(0, (n, r) => n + r.humanCount),
            'rooms': [
              for (final r in rooms.values)
                if (r.experience == place.kind)
                  {
                    'code': r.code,
                    'players': r.humanCount,
                    'phase': r.phase.name,
                  },
            ],
            ..._placeStatsJson(place.kind.id),
            'myVote': votes[place.kind.id],
          },
      ],
      'online': byPlayer.length,
    };
  }

  Map<String, Object?> _placeStatsJson(String kind) {
    final stats = store.placeStats(kind);
    return {
      'visits': stats.visits,
      'likes': stats.likes,
      'dislikes': stats.dislikes,
    };
  }

  void _sendPlaces(Session s) => s.send(_placesFrame(s));

  void _broadcastPlaces() {
    for (final s in byPlayer.values) {
      s.send(_placesFrame(s));
    }
  }

  void _placeRate(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final kind = ExperienceKind.fromId(msg['place'] as String?);
    if (kind == null) {
      s.error(
        ErrorCode.notFound,
        'Unknown place.',
        inReplyTo: MsgType.placeRate,
      );
      return;
    }
    final up = msg['up'];
    if (up != null && up is! bool) {
      s.error(
        ErrorCode.badRequest,
        '`up` must be true, false or null.',
        inReplyTo: MsgType.placeRate,
      );
      return;
    }
    store.vote(p.id, kind.id, up as bool?);
    _broadcastPlaces();
  }

  void _profileGet(Session s, PlayerRecord p, Map<String, Object?> msg) {
    final target = msg['player'] == null
        ? p
        : _lookup(s, msg['player'], MsgType.profileGet);
    if (target == null) return;
    final profile = target.profile(
      platform: byPlayer[target.id]?.platform ?? 'unknown',
      online: byPlayer.containsKey(target.id),
    );
    final json = profile.toJson();
    if (target.id != p.id) json.remove('owned');
    s.send({
      'type': MsgType.profile,
      'profile': json,
      'isFriend': store.friendRow(p.id, target.id)?.accepted ?? false,
    });
  }

  // ---------------------------------------------------------------------------
  // Test channel
  // ---------------------------------------------------------------------------

  void _testReport(Session s, PlayerRecord p, Map<String, Object?> msg) {
    if (!testMode) {
      s.error(
        ErrorCode.badRequest,
        'Test mode is off.',
        inReplyTo: MsgType.testReport,
      );
      return;
    }
    final report = TestReport(
      p.id,
      s.platform,
      (msg['phase'] as String?) ?? 'unknown',
      ((msg['payload'] as Map?) ?? const {}).cast<String, Object?>(),
      nowMs(),
    );
    testReports.add(report);
    log?.call(
      'test.report ${p.name}@${s.platform} ${report.phase} '
      '${jsonEncode(report.payload)}',
    );
  }

  /// Sends a control command to every client in [roomCode] (test mode only).
  void testControl(String? roomCode, Map<String, Object?> command) {
    final frame = {'type': MsgType.testControl, ...command};
    if (roomCode == null) {
      for (final s in byPlayer.values) {
        s.send(frame);
      }
    } else {
      final room = rooms[roomCode];
      if (room != null) broadcast(room, frame);
    }
  }

  /// JSON snapshot for the `/test/state` endpoint and diagnostics.
  Map<String, Object?> snapshot() => {
    'serverTime': nowMs(),
    'tick': tickCount,
    'online': byPlayer.length,
    'players': [
      for (final s in byPlayer.values)
        {
          'id': s.player!.id,
          'name': s.player!.name,
          'platform': s.platform,
          'room': s.roomCode,
          'party': partyOf[s.player!.id],
        },
    ],
    'rooms': [
      for (final r in rooms.values)
        {
          ...r.state.toJson(),
          'botCount': r.botCount,
          'matchNumber': r.matchNumber,
          'gameTick': r.game?.tick,
          'progress': r.game?.progress(),
          'lastResults': r.lastResults?.toJson(),
        },
    ],
    'parties': [for (final p in parties.values) _partyState(p).toJson()],
    'testReports': testReports.map((r) => r.toJson()).toList(),
  };

  // ---------------------------------------------------------------------------
  // Tick
  // ---------------------------------------------------------------------------

  void tick() {
    clock.tick((1000 / ticksPerSecond).round());
    tickCount++;
    for (final room in rooms.values.toList()) {
      room.tick();
    }
  }
}
