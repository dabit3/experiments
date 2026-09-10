import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:swapmate_core/swapmate_core.dart';

import '../screens/game_screen.dart';
import 'game_client.dart';

/// Executes `test.command` messages from the server (test mode only) by
/// driving the real UI, then replies with `test.result`.
///
/// Commands (`cmd` field):
/// - `state`                → snapshot of what this client is showing
/// - `create_room {code?, timeControl?, fillBots?}`
/// - `join_room {code, spectate?}`
/// - `seat {seat|null}` · `ready {ready}` · `start` · `rematch` · `leave`
/// - `move {uci}`          → plays through the board UI (tap/drop path)
/// - `premove {uci}`       → queues a premove/pre-drop
/// - `quick_chat {code}` · `chat {text}` · `resign` · `draw {action}`
/// - `theme {mode}`        → `dark` | `light`
/// - `wait {phase?, moves?, over?, frames?, timeoutMs?}` → blocks until the
///   condition holds, then until `frames` more frames have been produced
/// - `capture`              → `{png: base64}` rasterized by the client itself
class TestChannel {
  TestChannel({
    required this.client,
    required this.setTheme,
    required this.currentTheme,
    required this.capture,
  }) {
    _sub = client.testCommands.listen(_handle);
  }

  final GameClient client;
  final void Function(String mode) setTheme;
  final String Function() currentTheme;
  final Future<ui.Image> Function() capture;
  StreamSubscription<Map<String, dynamic>>? _sub;

  void dispose() => _sub?.cancel();

  Future<void> _handle(Map<String, dynamic> msg) async {
    final id = msg['id'] as String;
    Map<String, dynamic> result;
    try {
      result = await _run(msg);
      result['ok'] = true;
    } catch (e) {
      result = {'ok': false, 'error': e.toString()};
    }
    client.testResult(id, result);
  }

  Future<Map<String, dynamic>> _run(Map<String, dynamic> m) async {
    final cmd = m['cmd'] as String;
    switch (cmd) {
      case 'state':
        return state();
      case 'create_room':
        final tc = m['timeControl'];
        client.createRoom(
          code: m['code'] as String?,
          fillBots: m['fillBots'] as bool? ?? false,
          timeControl: tc == null
              ? null
              : TimeControl.fromJson(tc as Map<String, dynamic>),
        );
        await _until(() => client.room != null);
        return state();
      case 'join_room':
        client.joinRoom(
          m['code'] as String,
          spectate: m['spectate'] as bool? ?? false,
        );
        await _until(() => client.room != null);
        return state();
      case 'seat':
        final s = m['seat'] as String?;
        client.takeSeat(s == null ? null : Seat.parse(s));
        await _until(() => client.mySeat?.id == s);
        return state();
      case 'bot':
        final s = Seat.parse(m['seat'] as String);
        final add = m['add'] as bool? ?? true;
        client.setBot(s, add: add);
        await _until(
          () => client.room?.players.any((p) => p.seat == s && p.isBot) == add,
        );
        return state();
      case 'ready':
        final r = m['ready'] as bool? ?? true;
        client.setReady(r);
        await _until(
          () => client.me?.ready == r || client.room?.phase != RoomPhase.lobby,
        );
        return state();
      case 'start':
        if (client.room?.phase == RoomPhase.lobby) client.startMatch();
        await _until(
          () => client.room?.phase == RoomPhase.playing && client.game != null,
        );
        return state();
      case 'rematch':
        client.rematch();
        return state();
      case 'leave':
        client.leaveRoom();
        return state();
      case 'move':
        final ctl = await _gameScreen();
        final before = client.game?.moves.length ?? 0;
        final err = ctl.playUci(m['uci'] as String);
        if (err != null) throw StateError(err);
        await _until(
          () =>
              (client.game?.moves.length ?? 0) > before ||
              client.lastError != null,
        );
        if (client.lastError != null &&
            (client.game?.moves.length ?? 0) == before) {
          final e = client.lastError!;
          client.clearError();
          throw StateError('${e.code}: ${e.message}');
        }
        return state();
      case 'premove':
        final ctl = await _gameScreen();
        final err = ctl.premoveUci(m['uci'] as String);
        if (err != null) throw StateError(err);
        return state();
      case 'quick_chat':
        final q = QuickChat.byCode(m['code'] as String);
        if (q == null) throw ArgumentError('unknown quick chat');
        client.quickChat(q);
        return state();
      case 'chat':
        client.chat(m['text'] as String);
        return state();
      case 'resign':
        client.resign();
        await _until(() => client.game?.isOver ?? false);
        return state();
      case 'draw':
        client.draw(m['action'] as String);
        return state();
      case 'theme':
        setTheme(m['mode'] as String);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return state();
      case 'wait':
        final phase = m['phase'] as String?;
        final moves = m['moves'] as int?;
        final over = m['over'] as bool?;
        final frames = m['frames'] as int? ?? 0;
        final timeout = Duration(milliseconds: m['timeoutMs'] as int? ?? 30000);
        await _until(
          () =>
              (phase == null || client.room?.phase.name == phase) &&
              (moves == null || (client.game?.moves.length ?? 0) >= moves) &&
              (over == null || (client.game?.isOver ?? false) == over),
          timeout: timeout,
        );
        await _frames(frames);
        return state();
      case 'capture':
        final image = await capture();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final (w, h) = (image.width, image.height);
        image.dispose();
        if (bytes == null) throw StateError('capture failed');
        return {
          ...state(),
          'png': base64Encode(bytes.buffer.asUint8List()),
          'pngWidth': w,
          'pngHeight': h,
        };
      default:
        throw ArgumentError('unknown cmd $cmd');
    }
  }

  /// The game screen is built one frame after the room starts playing; slow
  /// hosts (software-emulated Android) need a moment before it exists.
  Future<GameScreenController> _gameScreen() async {
    await _until(
      () => GameScreenController.current != null,
      timeout: const Duration(minutes: 3),
    );
    return GameScreenController.current!;
  }

  /// Completes after [n] further frames have been built and handed to the
  /// engine; the raster pipeline is at most two frames deep, so three frames
  /// guarantee that the first one is on screen for a device screenshot.
  Future<void> _frames(int n) async {
    for (var i = 0; i < n; i++) {
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _until(
    bool Function() cond, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!cond()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('condition not met');
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    // Let one frame render so screenshots reflect the state.
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }

  Map<String, dynamic> state() {
    final room = client.room;
    final game = client.game;
    final screen = room == null
        ? 'home'
        : switch (room.phase) {
            RoomPhase.lobby => 'lobby',
            RoomPhase.playing => 'game',
            RoomPhase.finished => 'results',
          };
    return {
      'platform': client.platform,
      'screen': screen,
      'status': client.status.name,
      'theme': currentTheme(),
      'playerId': client.playerId,
      'name': client.name,
      'room': room == null
          ? null
          : {
              'code': room.code,
              'phase': room.phase.name,
              'mySeat': client.mySeat?.id,
              'timeControl': room.timeControl.pgn,
              'players': [
                for (final p in room.players)
                  {
                    'name': p.name,
                    'seat': p.seat?.id,
                    'platform': p.platform,
                    'bot': p.isBot,
                  },
              ],
              'spectators': room.spectators.length,
            },
      'game': game == null
          ? null
          : {
              'gameId': game.gameId,
              'moves': game.moves.length,
              'fenA': game.boards[BoardId.a]!.fen,
              'fenB': game.boards[BoardId.b]!.fen,
              'lastSan': game.moves.isEmpty ? null : game.moves.last.san,
              'over': game.isOver,
              'result': game.result?.toJson(),
              'score': game.result?.pgn,
              'bpgn': game.bpgn,
              'moveText': game.moves.map((m) => m.bpgn).join(' '),
            },
      'chats': client.chats.length,
      'ui': GameScreenController.current?.debugState(),
      'viewport': _viewport(),
    };
  }

  /// Physical size, scale and safe-area insets of the main view so the visual
  /// harness can crop native captures to the area the web baseline renders.
  Map<String, num>? _viewport() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return null;
    final v = views.first;
    return {
      'width': v.physicalSize.width,
      'height': v.physicalSize.height,
      'dpr': v.devicePixelRatio,
      'padTop': v.padding.top,
      'padBottom': v.padding.bottom,
      'padLeft': v.padding.left,
      'padRight': v.padding.right,
    };
  }
}
