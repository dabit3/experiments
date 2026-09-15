import 'package:brickfolk_shared/brickfolk_shared.dart';

import 'bots.dart';
import 'games.dart';

/// Human member of a room.
class RoomSeat {
  RoomSeat(this.summary);

  PlayerSummary summary;
  bool ready = false;

  /// Set while the player is disconnected; the seat is kept for a grace
  /// period so they can reconnect.
  int? disconnectedAtMs;
}

/// Callbacks the room uses to talk to the outside world.
abstract class RoomHost {
  void sendTo(String playerId, Map<String, Object?> frame);
  void broadcast(Room room, Map<String, Object?> frame);
  TycoonPlot plotFor(String playerId);
  MatchResults finalizeResults(Room room, List<RawResult> raw, int durationMs);
  void roomClosed(Room room);
  int nowMs();

  /// Multiplier applied to a place's match length (1.0 outside test mode).
  double get matchLengthScale;

  /// Milliseconds a room stays in results before its next lobby.
  int get resultsMs;
}

class Room {
  Room({
    required this.code,
    required this.experience,
    required this.seed,
    required this.host,
    required this.botCount,
    this.partyCode,
  });

  final String code;
  final ExperienceKind experience;
  final int seed;
  final RoomHost host;
  final String? partyCode;

  /// Number of bots that fill the match when it starts.
  int botCount;

  final seats = <String, RoomSeat>{};
  RoomPhase phase = RoomPhase.lobby;
  int? countdownEndsAt;
  int? matchEndsAt;
  int? matchStartedAt;
  int? resultsEndsAt;
  int matchNumber = 0;
  GameRunner? game;
  MatchResults? lastResults;

  static const countdownMs = 3000;
  static const defaultResultsMs = 20000;
  static const reconnectGraceMs = 30000;

  PlaceInfo get place => placeFor(experience);

  int get humanCount => seats.length;

  bool get isEmpty => seats.isEmpty;

  RoomState get state => RoomState(
    code: code,
    experience: experience,
    phase: phase,
    members: [
      for (final s in seats.values)
        RoomMember(
          player: PlayerSummary(
            id: s.summary.id,
            name: s.summary.name,
            avatar: s.summary.avatar,
            platform: s.summary.platform,
            online: s.disconnectedAtMs == null,
          ),
          ready: s.ready,
        ),
      if (game != null)
        for (final p in game!.participants.where((p) => p.isBot))
          RoomMember(player: p.summary, ready: true),
    ],
    seed: seed,
    countdownEndsAt: countdownEndsAt,
    matchEndsAt: matchEndsAt,
    round: matchNumber,
  );

  Map<String, Object?> stateFrame() => {
    'type': MsgType.roomState,
    'room': state.toJson(),
    'botCount': botCount,
    'serverTime': host.nowMs(),
  };

  void broadcastState() => host.broadcast(this, stateFrame());

  bool join(PlayerSummary player) {
    final existing = seats[player.id];
    if (existing != null) {
      existing.summary = player;
      existing.disconnectedAtMs = null;
      broadcastState();
      _sendCatchUp(player.id);
      return true;
    }
    if (seats.length >= maxRoomPlayers) return false;
    seats[player.id] = RoomSeat(player);
    if (phase == RoomPhase.playing) {
      // Late joiners spectate until the next match.
      seats[player.id]!.ready = false;
    }
    broadcastState();
    _sendCatchUp(player.id);
    return true;
  }

  void _sendCatchUp(String playerId) {
    if (phase == RoomPhase.results && lastResults != null) {
      host.sendTo(playerId, {
        'type': MsgType.gameResults,
        'results': lastResults!.toJson(),
        'resultsEndsAt': resultsEndsAt,
      });
    }
  }

  void leave(String playerId) {
    if (seats.remove(playerId) == null) return;
    if (seats.isEmpty) {
      host.roomClosed(this);
      return;
    }
    _checkAutoStart();
    broadcastState();
  }

  void markDisconnected(String playerId) {
    final seat = seats[playerId];
    if (seat == null) return;
    seat.disconnectedAtMs = host.nowMs();
    broadcastState();
  }

  void setReady(String playerId, bool ready) {
    final seat = seats[playerId];
    if (seat == null ||
        (phase != RoomPhase.lobby && phase != RoomPhase.countdown)) {
      return;
    }
    seat.ready = ready;
    _checkAutoStart();
    broadcastState();
  }

  void updateAvatar(PlayerSummary summary) {
    final seat = seats[summary.id];
    if (seat == null) return;
    seat.summary = summary;
    broadcastState();
  }

  void _checkAutoStart() {
    if (phase != RoomPhase.lobby && phase != RoomPhase.countdown) return;
    final online = seats.values.where((s) => s.disconnectedAtMs == null);
    final allReady = online.isNotEmpty && online.every((s) => s.ready);
    if (allReady && phase == RoomPhase.lobby) {
      phase = RoomPhase.countdown;
      countdownEndsAt = host.nowMs() + countdownMs;
    } else if (!allReady && phase == RoomPhase.countdown) {
      phase = RoomPhase.lobby;
      countdownEndsAt = null;
    }
  }

  void _startMatch() {
    matchNumber++;
    final participants = <Participant>[
      for (final s in seats.values)
        Participant(summary: s.summary, plot: host.plotFor(s.summary.id)),
    ];
    final botsToAdd = (botCount).clamp(0, maxRoomPlayers - participants.length);
    for (var i = 0; i < botsToAdd; i++) {
      participants.add(Participant(summary: botSummary(i), plot: TycoonPlot()));
    }
    participants.sort((a, b) => a.id.compareTo(b.id));
    game = createGame(
      experience,
      participants,
      seed + matchNumber,
      lengthScale: host.matchLengthScale,
    );
    phase = RoomPhase.playing;
    countdownEndsAt = null;
    matchStartedAt = host.nowMs();
    matchEndsAt =
        matchStartedAt! +
        (place.matchSeconds * 1000 * host.matchLengthScale).round();
    broadcastState();
    host.broadcast(this, {
      'type': MsgType.gameEvent,
      'events': [
        {'kind': 'start', 'value': matchNumber},
      ],
      'tick': 0,
    });
  }

  void handleInput(String playerId, Map<String, Object?> data) {
    if (phase != RoomPhase.playing) return;
    game?.handleInput(playerId, data);
  }

  /// Called once per server tick.
  void tick() {
    final now = host.nowMs();
    switch (phase) {
      case RoomPhase.lobby:
        _expireSeats(now);
      case RoomPhase.countdown:
        _expireSeats(now);
        if (countdownEndsAt != null && now >= countdownEndsAt!) _startMatch();
      case RoomPhase.playing:
        final g = game!;
        final events = g.step();
        if (events.isNotEmpty) {
          host.broadcast(this, {
            'type': MsgType.gameEvent,
            'events': events,
            'tick': g.tick,
          });
        }
        final frame = g.frame();
        if (frame != null) {
          host.broadcast(this, {'type': MsgType.gameState, ...frame});
        }
        if (g.isOver) _finishMatch(now);
      case RoomPhase.results:
        _expireSeats(now);
        if (resultsEndsAt != null && now >= resultsEndsAt!) {
          phase = RoomPhase.lobby;
          resultsEndsAt = null;
          game = null;
          for (final s in seats.values) {
            s.ready = false;
          }
          broadcastState();
        }
    }
  }

  void _finishMatch(int now) {
    final g = game!;
    final raw = g.results();
    lastResults = host.finalizeResults(this, raw, now - matchStartedAt!);
    phase = RoomPhase.results;
    matchEndsAt = null;
    resultsEndsAt = now + host.resultsMs;
    broadcastState();
    host.broadcast(this, {
      'type': MsgType.gameResults,
      'results': lastResults!.toJson(),
      'resultsEndsAt': resultsEndsAt,
    });
  }

  void _expireSeats(int now) {
    final expired = seats.entries
        .where(
          (e) =>
              e.value.disconnectedAtMs != null &&
              now - e.value.disconnectedAtMs! > reconnectGraceMs,
        )
        .map((e) => e.key)
        .toList();
    for (final id in expired) {
      leave(id);
    }
  }
}
