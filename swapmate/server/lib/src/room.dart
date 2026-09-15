import 'dart:async';

import 'package:swapmate_core/swapmate_core.dart';

/// Server configuration shared by every room.
class ServerConfig {
  const ServerConfig({
    this.seed,
    this.botDelayMs = 700,
    this.reconnectGraceMs = 60000,
    this.testMode = false,
    this.now = _wallClock,
  });

  /// Seed for room codes and bots. When null, bots and codes are random.
  final int? seed;

  /// Delay before a bot answers, so humans can follow what happens.
  final int botDelayMs;

  /// How long a disconnected seated player keeps their seat.
  final int reconnectGraceMs;

  /// Enables the test channel and fixed room codes.
  final bool testMode;

  /// Millisecond clock. Injectable for deterministic tests.
  final int Function() now;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;
}

/// Chat flood guard: at most [chatBurst] messages per [chatWindowMs], each
/// at most [chatMaxLength] characters.
const chatBurst = 10;
const chatWindowMs = 5000;
const chatMaxLength = 200;

/// A connected participant (human or bot) in a room.
class Player {
  Player({
    required this.id,
    required this.name,
    required this.platform,
    required this.resumeToken,
    this.isBot = false,
  });

  final String id;
  String name;
  final String platform;
  final String resumeToken;
  final bool isBot;
  Seat? seat;
  bool ready = false;
  bool connected = true;
  Timer? graceTimer;

  /// Send timestamps (ms) of recent chat messages, for the flood guard.
  final List<int> recentChat = [];

  /// Sends a JSON message to this player; a no-op for bots and offline players.
  void Function(Map<String, dynamic> msg)? send;

  PlayerInfo info() => PlayerInfo(
    id: id,
    name: name,
    seat: seat,
    ready: ready,
    isBot: isBot,
    connected: connected,
    platform: platform,
  );
}

/// A lobby plus (optionally) a running or finished match.
class Room {
  Room({
    required this.code,
    required this.hostId,
    required this.config,
    required this._timeControl,
    required this.onEmpty,
  });

  final String code;
  String hostId;
  final ServerConfig config;
  TimeControl _timeControl;
  final void Function(Room) onEmpty;

  RoomPhase phase = RoomPhase.lobby;
  final Map<String, Player> players = {};
  final Map<String, Player> spectators = {};
  final Set<String> rematchVotes = {};
  final List<ChatMessage> chat = [];

  BughouseMatch? match;
  int _gameCounter = 0;
  String gameId = '';
  final Map<Seat, Move> premoves = {};
  final Set<Seat> drawOffers = {};
  final Map<Seat, Bot> _bots = {};
  final Map<Seat, Timer> _botTimers = {};
  Timer? _flagTimer;
  int _botSalt = 0;

  TimeControl get timeControl => _timeControl;

  Iterable<Player> get everyone => [...players.values, ...spectators.values];

  Player? seated(Seat s) {
    for (final p in players.values) {
      if (p.seat == s) return p;
    }
    return null;
  }

  Player? find(String id) => players[id] ?? spectators[id];

  bool get isEmpty => everyone.where((p) => !p.isBot && p.connected).isEmpty;

  // ---------------------------------------------------------------------------
  // Lobby
  // ---------------------------------------------------------------------------

  void addPlayer(Player p, {bool spectate = false}) {
    if (spectate || phase != RoomPhase.lobby) {
      spectators[p.id] = p;
    } else {
      players[p.id] = p;
      // Auto-seat into the first free chair so a fresh room is one tap away.
      for (final s in Seat.values) {
        if (seated(s) == null) {
          p.seat = s;
          break;
        }
      }
      if (p.seat == null) {
        players.remove(p.id);
        spectators[p.id] = p;
      }
    }
    broadcastRoom();
    if (match != null) sendGame(p);
    for (final c in chat) {
      if (!c.isTeam) p.send?.call(_chatMsg(c));
    }
  }

  void removePlayer(String id) {
    final p = find(id);
    if (p == null) return;
    p.graceTimer?.cancel();
    players.remove(id);
    spectators.remove(id);
    rematchVotes.remove(id);
    if (phase == RoomPhase.playing && p.seat != null && match != null) {
      match!.abandon(p.seat!, config.now());
      _finishIfOver();
    }
    if (hostId == id) {
      final next = everyone.where((x) => !x.isBot).firstOrNull;
      if (next != null) hostId = next.id;
    }
    broadcastRoom();
    if (isEmpty) onEmpty(this);
  }

  /// Player's socket dropped. Keep their seat for a grace period.
  void disconnected(Player p) {
    p.connected = false;
    p.send = null;
    p.graceTimer?.cancel();
    p.graceTimer = Timer(Duration(milliseconds: config.reconnectGraceMs), () {
      if (!p.connected) removePlayer(p.id);
    });
    broadcastRoom();
  }

  void reconnected(Player p, void Function(Map<String, dynamic>) send) {
    p.connected = true;
    p.send = send;
    p.graceTimer?.cancel();
    broadcastRoom();
    if (match != null) sendGame(p);
    for (final c in chat) {
      if (!c.isTeam || (p.seat != null && c.seat?.team == p.seat!.team)) {
        p.send?.call(_chatMsg(c));
      }
    }
  }

  String? takeSeat(Player p, Seat? seat) {
    if (phase == RoomPhase.playing) return ErrorCode.notPlaying;
    if (seat == null) {
      players.remove(p.id);
      p.seat = null;
      p.ready = false;
      spectators[p.id] = p;
      broadcastRoom();
      return null;
    }
    final occupant = seated(seat);
    if (occupant != null && occupant.id != p.id) {
      if (occupant.isBot) {
        players.remove(occupant.id);
        _bots.remove(seat);
      } else {
        return ErrorCode.seatTaken;
      }
    }
    spectators.remove(p.id);
    players[p.id] = p;
    p.seat = seat;
    p.ready = false;
    broadcastRoom();
    return null;
  }

  String? setBot(Player by, Seat seat, {required bool add}) {
    if (by.id != hostId) return ErrorCode.notHost;
    if (phase == RoomPhase.playing) return ErrorCode.notPlaying;
    final occupant = seated(seat);
    if (add) {
      if (occupant != null && !occupant.isBot) return ErrorCode.seatTaken;
      if (occupant != null) return null;
      _addBot(seat);
    } else {
      if (occupant == null || !occupant.isBot) return null;
      players.remove(occupant.id);
      _bots.remove(seat);
    }
    broadcastRoom();
    return null;
  }

  static const _botNames = [
    'Rook Rivera',
    'Knight Nakamura',
    'Bishop Bell',
    'Queenie Quill',
  ];

  void _addBot(Seat seat) {
    final id = 'bot-${seat.id}';
    final p = Player(
      id: id,
      name: _botNames[seat.index],
      platform: 'server',
      resumeToken: '',
      isBot: true,
    )..seat = seat;
    players[id] = p;
    final seed = (config.seed ?? config.now()) + seat.index * 7919 + _botSalt;
    _bots[seat] = Bot(seed: seed, name: p.name);
  }

  void fillBots() {
    for (final s in Seat.values) {
      if (seated(s) == null) _addBot(s);
    }
    broadcastRoom();
  }

  String? setReady(Player p, bool ready) {
    if (p.seat == null) return ErrorCode.notSeated;
    p.ready = ready;
    broadcastRoom();
    _maybeAutoStart();
    return null;
  }

  String? setTimeControl(Player by, TimeControl tc) {
    if (by.id != hostId) return ErrorCode.notHost;
    if (phase == RoomPhase.playing) return ErrorCode.notPlaying;
    _timeControl = tc;
    broadcastRoom();
    return null;
  }

  RoomState state() => RoomState(
    code: code,
    phase: phase,
    hostId: hostId,
    timeControl: _timeControl,
    players: players.values.map((p) => p.info()).toList(),
    spectators: spectators.values.map((p) => p.info()).toList(),
    rematchVotes: rematchVotes.toList(),
  );

  void _maybeAutoStart() {
    final rs = state();
    if (phase == RoomPhase.lobby && rs.allSeated && rs.allReady) startMatch();
  }

  String? requestStart(Player by) {
    if (by.id != hostId) return ErrorCode.notHost;
    if (phase == RoomPhase.playing) return ErrorCode.notPlaying;
    for (final s in Seat.values) {
      if (seated(s) == null) _addBot(s);
    }
    final rs = state();
    if (!rs.allReady) return ErrorCode.notReady;
    startMatch();
    return null;
  }

  // ---------------------------------------------------------------------------
  // Match lifecycle
  // ---------------------------------------------------------------------------

  void startMatch() {
    _gameCounter++;
    gameId = '$code-$_gameCounter';
    premoves.clear();
    drawOffers.clear();
    rematchVotes.clear();
    _botSalt = _gameCounter;
    for (final s in _bots.keys.toList()) {
      final seed = (config.seed ?? config.now()) + s.index * 7919 + _botSalt;
      _bots[s] = Bot(seed: seed, name: _bots[s]!.name);
    }
    match = BughouseMatch(timeControl: _timeControl);
    match!.start(config.now());
    phase = RoomPhase.playing;
    for (final p in players.values) {
      p.ready = false;
    }
    broadcastRoom();
    broadcastGame();
    broadcastEvent(const GameEvent(kind: 'start', board: null, seat: null));
    _flagTimer?.cancel();
    _flagTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _tick(),
    );
    for (final b in BoardId.values) {
      _scheduleBot(b);
    }
  }

  void _tick() {
    final m = match;
    if (m == null || m.isOver) return;
    if (m.checkFlags(config.now())) _finishIfOver();
  }

  String? playMove(Player p, Move move) {
    final m = match;
    final seat = p.seat;
    if (m == null || phase != RoomPhase.playing) return ErrorCode.notPlaying;
    if (seat == null) return ErrorCode.notSeated;
    if (!m.isTurn(seat)) return ErrorCode.notYourTurn;
    if (!m.position(seat.board).isLegal(move)) return ErrorCode.illegalMove;
    _apply(seat, move);
    return null;
  }

  void _apply(Seat seat, Move move) {
    final m = match!;
    final now = config.now();
    final MatchMove entry;
    try {
      entry = m.play(seat, move, now);
    } on StateError {
      _finishIfOver();
      return;
    }
    premoves.remove(seat);
    drawOffers.clear();
    broadcastEvent(
      GameEvent(
        kind: move.isDrop ? 'drop' : 'move',
        board: seat.board,
        seat: seat,
        move: move,
        san: entry.san,
      ),
    );
    if (entry.captured != null) {
      broadcastEvent(
        GameEvent(
          kind: 'pass',
          board: seat.board,
          seat: seat,
          move: move,
          captured: entry.captured,
          toBoard: seat.partner.board,
          toColor: seat.partner.color,
        ),
      );
    }
    if (m.isOver) {
      _finishIfOver();
      return;
    }
    broadcastGame();
    // The partner may now have a legal pre-drop; the opponent a premove.
    _runPremove(seat.opponent);
    _runPremove(seat.partner);
    if (match!.isOver) return;
    _scheduleBot(seat.board);
    if (entry.captured != null) _scheduleBot(seat.partner.board);
  }

  void _runPremove(Seat seat) {
    final m = match;
    if (m == null || m.isOver) return;
    final pm = premoves[seat];
    if (pm == null || !m.isTurn(seat)) return;
    premoves.remove(seat);
    if (m.position(seat.board).isLegal(pm)) {
      _apply(seat, pm);
    } else {
      broadcastGame();
    }
  }

  String? setPremove(Player p, Move? move) {
    final seat = p.seat;
    if (match == null || phase != RoomPhase.playing) {
      return ErrorCode.notPlaying;
    }
    if (seat == null) return ErrorCode.notSeated;
    if (move == null) {
      premoves.remove(seat);
    } else if (match!.isTurn(seat)) {
      // It is already this player's turn: treat as a normal move attempt.
      if (!match!.position(seat.board).isLegal(move)) {
        return ErrorCode.illegalMove;
      }
      _apply(seat, move);
      return null;
    } else {
      premoves[seat] = move;
    }
    sendGame(p);
    return null;
  }

  void _scheduleBot(BoardId board) {
    final m = match;
    if (m == null || m.isOver) return;
    final seat = m.seatToMove(board);
    final bot = _bots[seat];
    if (bot == null) return;
    _botTimers[seat]?.cancel();
    _botTimers[seat] = Timer(Duration(milliseconds: config.botDelayMs), () {
      final mm = match;
      if (mm == null || mm.isOver || !mm.isTurn(seat)) return;
      final mv = bot.choose(mm.position(board));
      if (mv != null) _apply(seat, mv);
    });
  }

  String? resign(Player p) {
    final seat = p.seat;
    if (match == null || phase != RoomPhase.playing) {
      return ErrorCode.notPlaying;
    }
    if (seat == null) return ErrorCode.notSeated;
    match!.resign(seat, config.now());
    _finishIfOver();
    return null;
  }

  String? draw(Player p, String action) {
    final seat = p.seat;
    if (match == null || phase != RoomPhase.playing) {
      return ErrorCode.notPlaying;
    }
    if (seat == null) return ErrorCode.notSeated;
    switch (action) {
      case 'offer':
        drawOffers.add(seat);
        // Everyone who is not a bot on the other team has to agree.
        final others = Seat.values.where((s) => s.team != seat.team);
        final agreed = others.every(
          (s) => drawOffers.contains(s) || seated(s)?.isBot == true,
        );
        final teamAgreed = Seat.values
            .where((s) => s.team == seat.team)
            .every((s) => drawOffers.contains(s) || seated(s)?.isBot == true);
        if (agreed && teamAgreed) {
          match!.agreeDraw(config.now());
          _finishIfOver();
        } else {
          broadcastGame();
        }
      case 'accept':
        if (drawOffers.any((s) => s.team != seat.team)) {
          drawOffers.add(seat);
          final teamAgreed = Seat.values
              .where((s) => s.team == seat.team)
              .every((s) => drawOffers.contains(s) || seated(s)?.isBot == true);
          if (teamAgreed) {
            match!.agreeDraw(config.now());
            _finishIfOver();
          } else {
            broadcastGame();
          }
        }
      case 'decline':
        drawOffers.clear();
        broadcastGame();
      default:
        return ErrorCode.badRequest;
    }
    return null;
  }

  void _finishIfOver() {
    final m = match;
    if (m == null || !m.isOver) return;
    if (phase == RoomPhase.finished) return;
    phase = RoomPhase.finished;
    _flagTimer?.cancel();
    for (final t in _botTimers.values) {
      t.cancel();
    }
    _botTimers.clear();
    premoves.clear();
    drawOffers.clear();
    broadcastRoom();
    broadcastGame();
    broadcastEvent(
      GameEvent(kind: 'finish', board: m.result!.board, seat: m.result!.loser),
    );
  }

  String? voteRematch(Player p) {
    if (phase != RoomPhase.finished) return ErrorCode.notPlaying;
    if (p.seat == null) return ErrorCode.notSeated;
    rematchVotes.add(p.id);
    final humans = players.values.where((x) => !x.isBot && x.seat != null);
    if (humans.every((h) => rematchVotes.contains(h.id))) {
      // Swap colours within each board for the rematch.
      final swapped = <Player, Seat>{};
      for (final pl in players.values) {
        if (pl.seat != null) swapped[pl] = pl.seat!.opponent;
      }
      final bots = <Seat, Bot>{};
      swapped.forEach((pl, s) {
        pl.seat = s;
        if (pl.isBot) {
          bots[s] = _bots.values.firstWhere((b) => b.name == pl.name);
        }
      });
      _bots
        ..clear()
        ..addAll(bots);
      phase = RoomPhase.lobby;
      startMatch();
    } else {
      broadcastRoom();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  String? sendChat(
    Player p, {
    QuickChat? quick,
    String? text,
    String scope = 'room',
  }) {
    final body = text?.trim();
    if (quick == null && (body == null || body.isEmpty)) {
      return ErrorCode.badRequest;
    }
    final now = config.now();
    p.recentChat.removeWhere((t) => now - t > chatWindowMs);
    if (p.recentChat.length >= chatBurst) return ErrorCode.rateLimited;
    p.recentChat.add(now);
    final msg = ChatMessage(
      fromId: p.id,
      fromName: p.name,
      seat: p.seat,
      ts: now,
      scope: p.seat == null ? 'room' : scope,
      quick: quick,
      text: body,
    );
    chat.add(msg);
    if (chat.length > 200) chat.removeAt(0);
    final wire = _chatMsg(msg);
    for (final x in everyone) {
      if (msg.isTeam && (x.seat == null || x.seat!.team != p.seat!.team)) {
        continue;
      }
      x.send?.call(wire);
    }
    return null;
  }

  Map<String, dynamic> _chatMsg(ChatMessage c) => {
    'type': MsgType.chatMessage,
    'message': c.toJson(),
  };

  // ---------------------------------------------------------------------------
  // Broadcasting
  // ---------------------------------------------------------------------------

  void broadcastRoom() {
    final wire = {'type': MsgType.roomState, 'room': state().toJson()};
    for (final p in everyone) {
      p.send?.call(wire);
    }
  }

  GameState? gameState({Seat? forSeat}) {
    final m = match;
    if (m == null) return null;
    final now = config.now();
    return GameState(
      gameId: gameId,
      boards: {for (final b in BoardId.values) b: m.snapshot(b, now)},
      moves: m.history,
      result: m.result,
      serverTime: now,
      premove: forSeat == null ? null : premoves[forSeat],
      drawOffers: drawOffers.toList(),
      bpgn: m.isOver ? bpgn() : null,
    );
  }

  String bpgn() => Bpgn.export(
    match: match!,
    names: state().names,
    date: DateTime.fromMillisecondsSinceEpoch(match!.startedAt ?? config.now()),
  );

  void sendGame(Player p) {
    final gs = gameState(forSeat: p.seat);
    if (gs == null) return;
    p.send?.call({'type': MsgType.gameState, 'game': gs.toJson()});
  }

  void broadcastGame() {
    for (final p in everyone) {
      sendGame(p);
    }
  }

  void broadcastEvent(GameEvent e) {
    final wire = {'type': MsgType.gameEvent, 'event': e.toJson()};
    for (final p in everyone) {
      p.send?.call(wire);
    }
  }

  void dispose() {
    _flagTimer?.cancel();
    for (final t in _botTimers.values) {
      t.cancel();
    }
    for (final p in everyone) {
      p.graceTimer?.cancel();
    }
  }
}
