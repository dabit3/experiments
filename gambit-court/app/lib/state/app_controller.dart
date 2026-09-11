import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gambit_court_core/gambit_court_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/config.dart';
import '../audio/feedback.dart' as audio;
import '../audio/feedback.dart' show Sfx;
import '../net/connection.dart';

enum SidePreference { white, black, random }

enum Screen { lobby, game, review }

class Notice {
  Notice(this.id, this.text, {this.isError = false});
  final int id;
  final String text;
  final bool isError;
}

/// Bookkeeping for animating the most recent board change.
class BoardTransition {
  const BoardTransition({
    required this.seq,
    required this.fromFen,
    required this.move,
    required this.capture,
  });
  final int seq;
  final String fromFen;
  final Move? move;
  final bool capture;
}

/// Single source of truth for the client. Owns the connection, mirrors the
/// server's room snapshot, and exposes UI intents (moves, offers, lobby
/// actions). Automation commands from the server's control bridge arrive as
/// `ui_command` and are executed through the same intent methods so tests
/// exercise the real UI code paths.
class AppController extends ChangeNotifier {
  AppController(this.config, this._prefs) {
    clientId = config.clientId.isNotEmpty
        ? config.clientId
        : (_prefs.getString('clientId') ?? _newClientId());
    _prefs.setString('clientId', clientId);
    name = config.name.isNotEmpty
        ? config.name
        : (_prefs.getString('name') ?? _defaultName());
    if (config.name.isEmpty) _prefs.setString('name', name);
    final storedTheme = _prefs.getString('theme');
    themeMode = switch (config.theme.isNotEmpty ? config.theme : storedTheme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    feedback = audio.Feedback(
      enabled: _prefs.getBool('sound') ?? true,
      haptics: _prefs.getBool('haptics') ?? true,
    );
    final tcJson = _prefs.getString('timeControl');
    if (tcJson != null) {
      final parts = tcJson.split('+');
      if (parts.length == 2) {
        timeControl = TimeControl(
          initialMs: int.tryParse(parts[0]) ?? 300000,
          incrementMs: int.tryParse(parts[1]) ?? 3000,
        );
      }
    }
    connection = Connection(
      url: config.serverUrl,
      helloBuilder: () => {
        'type': Protocol.hello,
        'clientId': clientId,
        'name': name,
        'platform': config.platformLabel,
        'protocol': Protocol.version,
      },
    );
    connection.phase.addListener(notifyListeners);
    _sub = connection.messages.listen(_onMessage);
    connection.connect();
  }

  final AppConfig config;
  final SharedPreferences _prefs;
  late final Connection connection;
  late final audio.Feedback feedback;
  StreamSubscription<Json>? _sub;

  late String clientId;
  late String name;
  late ThemeMode themeMode;
  bool get soundOn => feedback.enabled;

  // ------------------------------------------------------------------ lobby
  List<RoomListing> rooms = const [];
  int online = 0;
  TimeControl timeControl = const TimeControl(
    initialMs: 300000,
    incrementMs: 3000,
  );
  SidePreference sidePreference = SidePreference.random;
  EngineLevel botLevel = EngineLevel.club;
  bool queued = false;
  TimeControl? queuedTimeControl;
  int? queuedBotAfterMs;
  bool _hasWelcome = false;
  bool get ready => _hasWelcome;

  // ------------------------------------------------------------------- room
  RoomSnapshot? room;
  Position? position;
  int _roomReceivedLocalMs = 0;
  int get roomReceivedLocalMs => _roomReceivedLocalMs;
  BoardTransition? transition;
  int _transitionSeq = 0;
  int? selectedSquare;
  Move? premove;
  int? viewPly;
  bool _flipOverride = false;
  bool _resultsDismissed = false;
  String? _lastRoomCode;
  final List<Notice> notices = [];
  int _noticeSeq = 0;
  final Map<String, Completer<void>> _pendingAcks = {};

  // ----------------------------------------------------------------- review
  Game? review;
  Map<String, String> reviewTags = const {};

  Screen get screen {
    if (review != null) return Screen.review;
    return room == null ? Screen.lobby : Screen.game;
  }

  PieceColor? get mySide => room?.sideOf(clientId);
  bool get isSpectator => room != null && mySide == null;
  bool get isPlaying => room?.status == RoomStatus.playing && mySide != null;
  bool get isMyTurn => isPlaying && room!.turn == mySide;
  bool get showResults =>
      room?.status == RoomStatus.finished && !_resultsDismissed;

  /// Board orientation: players see their own side at the bottom.
  PieceColor get orientation {
    final base = mySide ?? PieceColor.white;
    return _flipOverride ? base.opposite : base;
  }

  /// Position currently displayed (live, or a history ply when browsing).
  Position get displayedPosition {
    final game = review;
    if (game != null) {
      final ply = viewPly ?? game.ply;
      return game.positions[ply.clamp(0, game.ply)];
    }
    final snapshot = room;
    if (snapshot == null) return Position.initial;
    final ply = viewPly;
    if (ply == null || ply >= snapshot.moves.length) {
      return position ?? Position.initial;
    }
    if (ply <= 0) {
      return Position.fromFen(snapshot.startFen) ?? Position.initial;
    }
    return Position.fromFen(snapshot.moves[ply - 1].fenAfter) ??
        Position.initial;
  }

  List<PlayedMove> get displayedMoves =>
      review?.moves ?? room?.moves ?? const [];

  int get livePly => review?.ply ?? room?.moves.length ?? 0;

  bool get isBrowsingHistory => viewPly != null && viewPly! < livePly;

  Move? get displayedLastMove {
    final moves = displayedMoves;
    final ply = viewPly ?? moves.length;
    if (ply <= 0 || ply > moves.length) return null;
    return moves[ply - 1].move;
  }

  // -------------------------------------------------------------- messages

  void _onMessage(Json message) {
    switch (message['type']) {
      case Protocol.welcome:
        _hasWelcome = true;
        final serverName = message['name'] as String?;
        if (serverName != null && serverName.isNotEmpty) name = serverName;
        final roomJson = message['room'];
        if (roomJson is Map) {
          _applyRoom(RoomSnapshot.fromJson(roomJson.cast()));
        } else if (room != null) {
          // Session expired while we were offline.
          room = null;
          position = null;
          _notify('Your seat expired while you were offline.', isError: true);
        }
        notifyListeners();
      case Protocol.rooms:
        rooms = ((message['rooms'] as List?) ?? const [])
            .map((r) => RoomListing.fromJson((r as Map).cast()))
            .toList();
        online = (message['online'] as num?)?.toInt() ?? online;
        notifyListeners();
      case Protocol.roomState:
        _applyRoom(RoomSnapshot.fromJson((message['room'] as Map).cast()));
        notifyListeners();
      case Protocol.queued:
        queued = true;
        queuedTimeControl = TimeControl.fromJson(
          (message['timeControl'] as Map).cast(),
        );
        queuedBotAfterMs = (message['botAfterMs'] as num?)?.toInt();
        notifyListeners();
      case Protocol.left:
        queued = false;
        room = null;
        position = null;
        premove = null;
        selectedSquare = null;
        viewPly = null;
        _resultsDismissed = false;
        _ack('left');
        notifyListeners();
      case Protocol.error:
        final text = message['message'] as String? ?? 'Something went wrong.';
        final about = message['about'] as String?;
        if (about != null) _failAck(about, text);
        if (message['fatal'] == true) {
          connection.dispose();
        }
        _notify(text, isError: true);
        notifyListeners();
      case Protocol.uiCommand:
        _handleUiCommand(message);
      case Protocol.pong:
        break;
    }
  }

  void _applyRoom(RoomSnapshot next) {
    final previous = room;
    final prevPosition = position;
    final nextPosition = Position.fromFen(next.fen) ?? Position.initial;
    queued = false;
    if (previous?.code != next.code) {
      _flipOverride = false;
      _resultsDismissed = false;
      viewPly = null;
      premove = null;
      selectedSquare = null;
    }
    if (_lastRoomCode != next.code) {
      _lastRoomCode = next.code;
      transition = null;
    }
    room = next;
    position = nextPosition;
    _roomReceivedLocalMs = DateTime.now().millisecondsSinceEpoch;

    // Detect what changed for animation + feedback.
    final prevCount = previous?.moves.length ?? 0;
    final nextCount = next.moves.length;
    if (previous != null &&
        previous.code == next.code &&
        nextCount == prevCount + 1 &&
        prevPosition != null) {
      final move = next.moves.last.move;
      final capture = prevPosition.isCapture(move);
      transition = BoardTransition(
        seq: ++_transitionSeq,
        fromFen: prevPosition.fen,
        move: move,
        capture: capture,
      );
      if (viewPly != null && viewPly! >= prevCount) viewPly = null;
      if (next.result != null) {
        feedback.play(Sfx.end);
      } else if (nextPosition.isInCheck) {
        feedback.play(Sfx.check);
      } else {
        feedback.play(capture ? Sfx.capture : Sfx.move);
      }
    } else if (previous != null &&
        previous.code == next.code &&
        nextCount < prevCount) {
      // Takeback or rematch reset: snap without a slide.
      transition = BoardTransition(
        seq: ++_transitionSeq,
        fromFen: nextPosition.fen,
        move: null,
        capture: false,
      );
      viewPly = null;
      if (previous.status == RoomStatus.finished &&
          next.status == RoomStatus.playing) {
        _resultsDismissed = false;
        _notify('Rematch started. Colours swapped.');
      }
    } else if (previous != null &&
        previous.code == next.code &&
        next.result != null &&
        previous.result == null) {
      feedback.play(Sfx.end);
    }

    // Offer notifications.
    if (previous != null && previous.code == next.code) {
      final me = mySide;
      if (me != null) {
        if (next.offers.draw == me.opposite &&
            previous.offers.draw != me.opposite) {
          feedback.play(Sfx.notify);
        }
        if (next.offers.takeback == me.opposite &&
            previous.offers.takeback != me.opposite) {
          feedback.play(Sfx.notify);
        }
        if (next.offers.rematch == me.opposite &&
            previous.offers.rematch != me.opposite) {
          feedback.play(Sfx.notify);
        }
      }
      if (previous.status == RoomStatus.waiting &&
          next.status == RoomStatus.playing) {
        feedback.play(Sfx.notify);
      }
      if (next.rematchRoom != null &&
          next.rematchRoom != previous.rematchRoom &&
          mySide != null) {
        // Both players agreed; follow into the new room.
        joinRoom(next.rematchRoom!);
      }
    }

    // Premove: fire when it becomes our turn and the move is legal.
    final pending = premove;
    if (pending != null && isMyTurn) {
      premove = null;
      final resolved = nextPosition.resolve(
        pending.from,
        pending.to,
        promotion: pending.promotion ?? PieceType.queen,
      );
      if (resolved != null) {
        connection.send({'type': Protocol.move, 'uci': resolved.uci});
      }
    } else if (pending != null && !isPlaying) {
      premove = null;
    }
    if (selectedSquare != null && !isMyTurn && !isPlaying) {
      selectedSquare = null;
    }
    _ack(Protocol.roomState);
  }

  // --------------------------------------------------------------- intents

  void setName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == name) return;
    name = trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed;
    _prefs.setString('name', name);
    connection.send({'type': Protocol.setName, 'name': name});
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs.setString('theme', mode.name);
    notifyListeners();
  }

  void toggleSound() {
    feedback.enabled = !feedback.enabled;
    _prefs.setBool('sound', feedback.enabled);
    if (feedback.enabled) feedback.play(Sfx.move);
    notifyListeners();
  }

  void setTimeControl(TimeControl tc) {
    timeControl = tc;
    _prefs.setString('timeControl', '${tc.initialMs}+${tc.incrementMs}');
    notifyListeners();
  }

  void setSidePreference(SidePreference pref) {
    sidePreference = pref;
    notifyListeners();
  }

  void setBotLevel(EngineLevel level) {
    botLevel = level;
    notifyListeners();
  }

  Future<void> createRoom({
    bool withBot = false,
    bool isPublic = true,
    TimeControl? tc,
    SidePreference? side,
    EngineLevel? level,
  }) {
    final chosen = side ?? sidePreference;
    connection.send({
      'type': Protocol.createRoom,
      'timeControl': (tc ?? timeControl).toJson(),
      'side': switch (chosen) {
        SidePreference.white => 'white',
        SidePreference.black => 'black',
        SidePreference.random => config.automation ? 'white' : 'random',
      },
      if (withBot) 'botLevel': (level ?? botLevel).id,
      'isPublic': isPublic,
    });
    return _await(Protocol.roomState, about: Protocol.createRoom);
  }

  Future<void> joinRoom(String code, {bool asSpectator = false}) {
    connection.send({
      'type': Protocol.joinRoom,
      'code': code.trim().toUpperCase(),
      'asSpectator': asSpectator,
    });
    return _await(Protocol.roomState, about: Protocol.joinRoom);
  }

  void quickPair({bool fillWithBot = true}) {
    connection.send({
      'type': Protocol.quickPair,
      'timeControl': timeControl.toJson(),
      if (fillWithBot) 'botLevel': botLevel.id,
    });
  }

  void cancelPair() {
    connection.send({'type': Protocol.cancelPair});
    queued = false;
    notifyListeners();
  }

  void addBot() {
    connection.send({'type': Protocol.addBot, 'botLevel': botLevel.id});
  }

  Future<void> leaveRoom() {
    if (room == null) return Future.value();
    connection.send({'type': Protocol.leaveRoom});
    return _await('left', about: Protocol.leaveRoom);
  }

  void closeReview() {
    review = null;
    viewPly = null;
    selectedSquare = null;
    notifyListeners();
  }

  /// Board tap. Returns true when the tap started or completed a move.
  bool tapSquare(int square) {
    if (review != null) return false;
    if (isBrowsingHistory) {
      viewPly = null;
      notifyListeners();
    }
    final snapshot = room;
    final pos = position;
    if (snapshot == null || pos == null || mySide == null) return false;
    if (snapshot.status != RoomStatus.playing) return false;
    final me = mySide!;
    final selected = selectedSquare;
    final piece = pos.pieceAt(square);

    if (selected == null) {
      if (piece != null && piece.color == me) {
        selectedSquare = square;
        notifyListeners();
        return true;
      }
      return false;
    }
    if (selected == square) {
      selectedSquare = null;
      notifyListeners();
      return true;
    }
    if (piece != null && piece.color == me) {
      selectedSquare = square;
      notifyListeners();
      return true;
    }
    if (isMyTurn) {
      final started = requestMove(selected, square);
      if (!started) selectedSquare = null;
      notifyListeners();
      return started;
    }
    // Not our turn: register a premove if the piece could plausibly go there.
    premove = Move(selected, square);
    selectedSquare = null;
    notifyListeners();
    return true;
  }

  /// True when moving `from -> to` needs a promotion choice first.
  bool needsPromotion(int from, int to) =>
      position?.requiresPromotion(from, to) ?? false;

  /// Sends a move for the current turn. Returns false if it is not legal
  /// (or a promotion piece is still required).
  bool requestMove(int from, int to, {PieceType? promotion}) {
    final pos = position;
    if (pos == null || !isMyTurn) return false;
    if (pos.requiresPromotion(from, to) && promotion == null) return false;
    final move = pos.resolve(from, to, promotion: promotion ?? PieceType.queen);
    if (move == null) return false;
    selectedSquare = null;
    connection.send({'type': Protocol.move, 'uci': move.uci});
    notifyListeners();
    return true;
  }

  void setPremove(int from, int to, {PieceType? promotion}) {
    premove = Move(from, to, promotion: promotion);
    selectedSquare = null;
    notifyListeners();
  }

  void clearPremove() {
    premove = null;
    notifyListeners();
  }

  void clearSelection() {
    selectedSquare = null;
    notifyListeners();
  }

  void flipBoard() {
    _flipOverride = !_flipOverride;
    notifyListeners();
  }

  void restoreResults() {
    _resultsDismissed = false;
    notifyListeners();
  }

  void dismissResults() {
    _resultsDismissed = true;
    notifyListeners();
  }

  void viewPlyAt(int? ply) {
    final total = livePly;
    if (ply == null || ply >= total) {
      viewPly = null;
    } else {
      viewPly = ply.clamp(0, total);
    }
    selectedSquare = null;
    notifyListeners();
  }

  void stepHistory(int delta) {
    final total = livePly;
    final current = viewPly ?? total;
    viewPlyAt((current + delta).clamp(0, total));
  }

  void resign() => connection.send({'type': Protocol.resign});
  void offerDraw() => connection.send({'type': Protocol.offerDraw});
  void acceptDraw() => connection.send({'type': Protocol.acceptDraw});
  void declineDraw() => connection.send({'type': Protocol.declineDraw});
  void offerTakeback() => connection.send({'type': Protocol.offerTakeback});
  void acceptTakeback() => connection.send({'type': Protocol.acceptTakeback});
  void declineTakeback() => connection.send({'type': Protocol.declineTakeback});
  void offerRematch() => connection.send({'type': Protocol.offerRematch});
  void acceptRematch() => connection.send({'type': Protocol.acceptRematch});
  void declineRematch() => connection.send({'type': Protocol.declineRematch});

  /// PGN of the current game (live room or review).
  String exportPgn() {
    final game = review ?? _gameFromRoom();
    if (game == null) return '';
    final snapshot = room;
    final tags = review != null
        ? reviewTags
        : <String, String>{
            'Event': 'Gambit Court · ${snapshot!.timeControl.category}',
            'Site': 'Gambit Court (${config.platformLabel})',
            'Round': snapshot.code,
            'White': snapshot.white?.name ?? 'White',
            'Black': snapshot.black?.name ?? 'Black',
            'TimeControl': snapshot.timeControl.isUnlimited
                ? '-'
                : '${snapshot.timeControl.initialMs ~/ 1000}'
                      '+${snapshot.timeControl.incrementMs ~/ 1000}',
            if (snapshot.result != null)
              'Termination': snapshot.result!.reasonLabel,
          };
    return Pgn.export(game, tags: tags);
  }

  /// Loads a PGN into review mode. Returns an error message or null.
  String? importPgn(String text) {
    final imported = Pgn.import(text);
    if (imported == null) return 'That does not look like PGN.';
    if (imported.game.moves.isEmpty && imported.errors.isNotEmpty) {
      return imported.errors.first;
    }
    review = imported.game;
    reviewTags = imported.tags;
    viewPly = null;
    selectedSquare = null;
    notifyListeners();
    if (imported.errors.isNotEmpty) {
      _notify('Stopped at: ${imported.errors.first}', isError: true);
    }
    return null;
  }

  Game? _gameFromRoom() {
    final snapshot = room;
    if (snapshot == null) return null;
    final start = Position.fromFen(snapshot.startFen);
    final game = Game(start: start);
    for (final m in snapshot.moves) {
      game.play(m.move);
    }
    if (snapshot.result != null) game.end(snapshot.result!);
    return game;
  }

  // ---------------------------------------------------------------- notices

  void _notify(String text, {bool isError = false}) {
    final notice = Notice(++_noticeSeq, text, isError: isError);
    notices.add(notice);
    if (notices.length > 3) notices.removeAt(0);
    Timer(const Duration(seconds: 4), () {
      notices.remove(notice);
      notifyListeners();
    });
    notifyListeners();
  }

  void showNotice(String text) => _notify(text);

  void dismissNotice(Notice notice) {
    if (notices.remove(notice)) notifyListeners();
  }

  // ------------------------------------------------------------------- acks

  Future<void> _await(String key, {required String about}) {
    final completer = Completer<void>();
    _pendingAcks[key] = completer;
    _pendingAcks['about:$about'] = completer;
    Timer(const Duration(seconds: 8), () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('No response to $about'));
        _notify(
          'The server did not answer. Check your connection.',
          isError: true,
        );
      }
      _pendingAcks.remove(key);
      _pendingAcks.remove('about:$about');
    });
    return completer.future;
  }

  void _ack(String key) {
    final completer = _pendingAcks.remove(key);
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _failAck(String about, String message) {
    final completer = _pendingAcks.remove('about:$about');
    if (completer != null && !completer.isCompleted) {
      completer.completeError(StateError(message));
    }
  }

  // ------------------------------------------------------------- automation

  Future<void> _handleUiCommand(Json command) async {
    final id = command['id'];
    Json report;
    try {
      report = await _runUiCommand(command);
    } catch (e) {
      report = {'ok': false, 'error': e.toString()};
    }
    connection.send({'type': Protocol.uiReport, 'id': id, ...report});
  }

  Future<Json> _runUiCommand(Json command) async {
    final action = command['action'] as String?;
    switch (action) {
      case 'state':
        return {'ok': true, ...describeState()};
      case 'set_name':
        setName(command['name'] as String? ?? '');
        return {'ok': true, 'name': name};
      case 'set_theme':
        setThemeMode(
          command['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark,
        );
        await _settle();
        return {'ok': true};
      case 'create_room':
        final tcJson = command['timeControl'];
        final tc = tcJson is Map
            ? TimeControl.fromJson(tcJson.cast<String, Object?>())
            : timeControl;
        final side = switch (command['side']) {
          'white' => SidePreference.white,
          'black' => SidePreference.black,
          _ => SidePreference.random,
        };
        final level = command['botLevel'] is num
            ? EngineLevel.fromId((command['botLevel'] as num).toInt())
            : null;
        await createRoom(
          withBot: level != null,
          isPublic: command['isPublic'] as bool? ?? true,
          tc: tc,
          side: side,
          level: level,
        );
        await _settle();
        return {'ok': true, ...describeState()};
      case 'join_room':
        await joinRoom(
          command['code'] as String? ?? '',
          asSpectator: command['asSpectator'] as bool? ?? false,
        );
        await _settle();
        return {'ok': true, ...describeState()};
      case 'quick_pair':
        quickPair(fillWithBot: command['bot'] as bool? ?? false);
        return {'ok': true};
      case 'leave_room':
        await leaveRoom();
        return {'ok': true, ...describeState()};
      case 'move':
        return _automatedMove(command['uci'] as String? ?? '');
      case 'premove':
        final move = Move.parseUci(command['uci'] as String? ?? '');
        if (move == null) return {'ok': false, 'error': 'bad uci'};
        setPremove(move.from, move.to, promotion: move.promotion);
        return {'ok': true};
      case 'resign':
        resign();
        await _nextRoomState();
        return {'ok': true, ...describeState()};
      case 'offer_draw':
        offerDraw();
        await _nextRoomState();
        return {'ok': true, ...describeState()};
      case 'accept_draw':
        acceptDraw();
        await _nextRoomState();
        return {'ok': true, ...describeState()};
      case 'offer_takeback':
        offerTakeback();
        await _nextRoomState();
        return {'ok': true, ...describeState()};
      case 'accept_takeback':
        acceptTakeback();
        await _nextRoomState();
        return {'ok': true, ...describeState()};
      case 'offer_rematch':
        offerRematch();
        await _nextRoomState();
        return {'ok': true, ...describeState()};
      case 'accept_rematch':
        acceptRematch();
        await _nextRoomState();
        await _settle();
        return {'ok': true, ...describeState()};
      case 'flip':
        flipBoard();
        return {'ok': true, 'orientation': orientation.name};
      case 'view_ply':
        viewPlyAt((command['ply'] as num?)?.toInt());
        await _settle();
        return {'ok': true, 'viewPly': viewPly};
      case 'dismiss_results':
        dismissResults();
        await _settle();
        return {'ok': true};
      case 'export_pgn':
        return {'ok': true, 'pgn': exportPgn()};
      case 'import_pgn':
        final error = importPgn(command['pgn'] as String? ?? '');
        await _settle();
        return {'ok': error == null, 'error': ?error};
      case 'close_review':
        closeReview();
        return {'ok': true};
      case 'drop_connection':
        // Report first: the socket is gone once the drop happens.
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          connection.simulateDrop,
        );
        return {'ok': true};
      case 'settle':
        await _settle();
        return {'ok': true, ...describeState()};
      default:
        return {'ok': false, 'error': 'unknown action $action'};
    }
  }

  Future<Json> _automatedMove(String uci) async {
    final move = Move.parseUci(uci);
    if (move == null) return {'ok': false, 'error': 'bad uci $uci'};
    if (!isMyTurn) {
      // Wait briefly for the turn to arrive (opponent may still be moving).
      final deadline = DateTime.now().add(const Duration(seconds: 6));
      while (!isMyTurn && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (!isMyTurn) return {'ok': false, 'error': 'not my turn'};
    }
    final before = room!.seq;
    // Drive the same code path as a tap-tap interaction.
    tapSquare(move.from);
    if (selectedSquare != move.from) {
      return {
        'ok': false,
        'error': 'no own piece on ${Square.name(move.from)}',
      };
    }
    await _settle();
    final bool sent;
    if (needsPromotion(move.from, move.to)) {
      sent = requestMove(
        move.from,
        move.to,
        promotion: move.promotion ?? PieceType.queen,
      );
    } else {
      sent = tapSquare(move.to) && selectedSquare == null;
    }
    if (!sent) return {'ok': false, 'error': 'illegal move $uci'};
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while ((room?.seq ?? 0) <= before && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    if ((room?.seq ?? 0) <= before) {
      return {'ok': false, 'error': 'server did not confirm $uci'};
    }
    if (room!.moves.isEmpty || room!.moves.last.move.uci != uci) {
      return {'ok': false, 'error': 'server applied a different move'};
    }
    await _settle();
    return {'ok': true, ...describeState()};
  }

  Future<void> _nextRoomState() async {
    final before = room?.seq ?? -1;
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while ((room?.seq ?? -1) == before && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  /// Lets animations finish so screenshots taken right after are stable.
  Future<void> _settle() =>
      Future<void>.delayed(const Duration(milliseconds: 450));

  /// Snapshot of what this client is showing, used by the cross-platform
  /// test to assert every client renders the identical game.
  Json describeState() {
    final snapshot = room;
    final displayed = displayedPosition;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final dpr = view.devicePixelRatio;
    return {
      'clientId': clientId,
      'platform': config.platformLabel,
      'view': {
        'width': view.physicalSize.width / dpr,
        'height': view.physicalSize.height / dpr,
        'devicePixelRatio': dpr,
        'paddingTop': view.padding.top / dpr,
        'paddingBottom': max(view.padding.bottom / dpr, config.safeBottom),
      },
      'name': name,
      'connection': connection.phase.value.name,
      'screen': showResults ? 'results' : screen.name,
      'theme': themeMode.name,
      'roomCode': snapshot?.code,
      'status': snapshot?.status.name,
      'seq': snapshot?.seq,
      'fen': displayed.fen,
      'liveFen': snapshot?.fen,
      'moves': displayedMoves.map((m) => m.san).toList(),
      'moveCount': displayedMoves.length,
      'turn': displayed.turn.letter,
      'mySide': mySide?.letter,
      'isSpectator': isSpectator,
      'orientation': orientation.letter,
      'result': snapshot?.result?.toJson(),
      'score': snapshot?.result?.score,
      'clocks': snapshot == null
          ? null
          : {
              'whiteMs': snapshot.clocks.whiteMs,
              'blackMs': snapshot.clocks.blackMs,
              'running': snapshot.clocks.running?.letter,
              'frozen': snapshot.clocks.frozen,
            },
      'white': snapshot?.white?.name,
      'black': snapshot?.black?.name,
      'spectators': snapshot?.spectators.map((s) => s.name).toList(),
      'offers': snapshot?.offers.toJson(),
      'premove': premove?.uci,
      'queued': queued,
      'roomsListed': rooms.length,
    };
  }

  // ----------------------------------------------------------------- utils

  static String _newClientId() {
    final r = Random.secure();
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      16,
      (_) => alphabet[r.nextInt(alphabet.length)],
    ).join();
  }

  static String _defaultName() {
    const names = [
      'Ada', 'Bram', 'Cass', 'Dov', 'Esme', 'Finn', 'Greta', 'Hal', //
      'Iris', 'Jude', 'Kit', 'Lior', 'Mira', 'Nell', 'Otis', 'Pia',
    ];
    return '${names[Random().nextInt(names.length)]} ${Random().nextInt(90) + 10}';
  }

  @override
  void dispose() {
    _sub?.cancel();
    connection.phase.removeListener(notifyListeners);
    connection.dispose();
    feedback.dispose();
    super.dispose();
  }
}
