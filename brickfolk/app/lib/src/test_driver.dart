import 'dart:async';
import 'dart:ui' show FrameTiming, PlatformDispatcher;

import 'package:brickfolk_shared/brickfolk_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'app_state.dart';
import 'config.dart';
import 'net/client.dart';

/// Drives a client through a full deterministic match for the automated
/// cross-platform test: sign in → party → ready → autopilot → report.
///
/// Every step is idempotent and re-checked on each client update so the
/// driver survives reconnects and out-of-order events. It also reports each
/// phase over `test.report` so the harness knows when to take screenshots.
///
/// In [AppConfig.visualTour] mode the driver only signs in and then shows
/// hub screens on `test.control` `show` commands, reporting `tour` once each
/// screen is up so the harness can capture equivalent states per platform.
///
/// Screen-state reports wait for [RasterGate] so a screenshot taken on
/// receipt shows the reported state even where rendering lags the game
/// (a software-emulated Android device takes many seconds per frame). Where
/// the device display trails the app by minutes the harness instead reads
/// the phase marker painted with [AppConfig.phaseMarker] off the display and
/// holds the lobby open ([AppConfig.autoReady] off) until it has seen it.
class TestDriver {
  TestDriver(this.app) : client = app.client, config = app.config;

  final AppState app;
  final BrickfolkClient client;
  final AppConfig config;

  Timer? _poll;
  int _lastInputTick = -1;
  final _reported = <String>{};
  ObbyAutopilot? _obby;
  TagAutopilot? _tag;
  TycoonAutopilot? _tycoon;
  int _lastTycoonSecond = -1;
  bool _launched = false;
  int _joinAttemptAt = 0;
  int _signInAttemptAt = 0;

  ExperienceKind get _experience =>
      ExperienceKind.fromId(config.experience) ?? ExperienceKind.obby;

  void start() {
    client.addListener(_onUpdate);
    client.testControl.listen(_onControl);
    client.signIn(name: config.autoName ?? 'Tester${config.platformLabel}');
    // Poll as a safety net for steps that wait on wall-clock (party joins).
    _poll = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _onUpdate(),
    );
  }

  void dispose() {
    _poll?.cancel();
    client.removeListener(_onUpdate);
  }

  void _report(
    String phase,
    Map<String, Object?> payload, {
    String? once,
    bool afterRaster = false,
  }) {
    if (once != null) {
      if (_reported.contains(once)) return;
      _reported.add(once);
    }
    if (!afterRaster) {
      client.testReport(phase, payload);
      debugPrint('[test] $phase ${payload.keys.join(',')}');
      return;
    }
    final armed = DateTime.now();
    _raster.nextRaster().then((rendered) {
      final waited = DateTime.now().difference(armed).inMilliseconds;
      client.testReport(phase, {...payload, 'rendered': rendered});
      debugPrint(
        '[test] $phase ${payload.keys.join(',')} '
        '(${rendered ? 'rastered' : 'raster gate timed out'} after ${waited}ms)',
      );
    });
  }

  final _raster = RasterGate();

  /// A rejected hello (e.g. the name is still held by a stale session that
  /// has not timed out yet) leaves the client idle; keep retrying so the
  /// harness only has to wait, not relaunch.
  void _retrySignIn() {
    final err = client.lastError;
    if (err == null || err.inReplyTo != MsgType.hello) return;
    if (client.status != ConnectionStatus.connecting &&
        client.status != ConnectionStatus.connected) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _signInAttemptAt < 3000) return;
    _signInAttemptAt = now;
    client.signIn(name: config.autoName ?? 'Tester${config.platformLabel}');
  }

  void _onControl(Map<String, Object?> msg) {
    // Harness-initiated commands, e.g. {"type":"test.control","cmd":"leave"};
    // an optional `platform` addresses one client.
    final platform = msg['platform'];
    if (platform != null && platform != config.platformLabel) return;
    switch (msg['cmd']) {
      case 'leave':
        client.roomLeave();
      case 'ready':
        client.roomReady(true);
        debugPrint('[test] ready on request');
      case 'report':
        _report('ping', {
          'room': client.room?.code,
          'phase': client.room?.phase.name,
        });
      case 'show':
        final screen = msg['screen'] as String? ?? 'hub';
        app.requestScreen(screen);
        // Give the shell a few frames to switch tabs and settle its layout.
        Timer(const Duration(milliseconds: 400), () {
          _report('tour', {'screen': screen}, afterRaster: true);
        });
    }
  }

  void _onUpdate() {
    if (!client.signedIn) {
      _retrySignIn();
      return;
    }
    _report('signedIn', {'name': client.me!.summary.name}, once: 'signedIn');
    if (config.visualTour) {
      _report('tour', {'screen': 'ready'}, once: 'tour-ready');
      return;
    }

    final room = client.room;
    if (room == null) {
      _ensureParty();
      return;
    }

    switch (room.phase) {
      case RoomPhase.lobby:
        _report(
          'lobby',
          {'room': room.code, 'members': room.members.length},
          once: 'lobby-${room.code}-${room.round}',
          afterRaster: true,
        );
        final me = room.members
            .where((m) => m.player.id == client.myId)
            .firstOrNull;
        if (me != null && !me.ready && room.round == 0 && config.autoReady) {
          client.roomReady(true);
        }
        _obby = null;
        _tag = null;
        _tycoon = null;
      case RoomPhase.countdown:
        _report('countdown', {
          'room': room.code,
        }, once: 'countdown-${room.code}-${room.round}');
      case RoomPhase.playing:
        _play(room);
      case RoomPhase.results:
        final r = client.results;
        if (r != null) {
          _report(
            'results',
            {
              'room': room.code,
              'checksum': r.checksum,
              'experience': r.experience.id,
              'leaderboard': [
                for (final e in r.entries)
                  {
                    'rank': e.rank,
                    'player': e.player.name,
                    'score': e.score,
                    'detail': e.detail,
                  },
              ],
            },
            once: 'results-${room.code}-${room.round}',
            afterRaster: true,
          );
        }
    }
  }

  void _ensureParty() {
    final code = config.partyCode;
    if (code == null) {
      // Solo test: create a room directly.
      if (!_launched) {
        _launched = true;
        client.roomCreate(_experience, bots: config.bots);
      }
      return;
    }
    final party = client.party;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (party == null) {
      if (now - _joinAttemptAt < 900) return;
      _joinAttemptAt = now;
      if (config.isHost) {
        client.partyCreate(code: code);
      } else {
        client.partyJoin(code);
      }
      debugPrint('[test] party ${config.isHost ? 'create' : 'join'} $code');
      return;
    }
    _report('party', {
      'code': party.code,
      'members': party.members.length,
    }, once: 'party');
    if (party.roomCode != null) {
      // Room already exists (e.g. after reconnect) — re-enter it.
      if (now - _joinAttemptAt < 900) return;
      _joinAttemptAt = now;
      client.roomJoin(party.roomCode!);
      return;
    }
    final online = party.members.where((m) => m.online).length;
    if (config.isHost && !_launched && online >= config.expectedPlayers) {
      _launched = true;
      _report('launch', {'members': online, 'experience': _experience.id});
      client.partyLaunch(_experience, bots: config.bots);
    }
  }

  void _play(RoomState room) {
    _report(
      'playing',
      {'room': room.code},
      once: 'playing-${room.code}-${room.round}',
      afterRaster: true,
    );
    final frame = client.frame;
    final me = client.myId;
    if (frame == null || me == null || frame.tick == _lastInputTick) return;
    _lastInputTick = frame.tick;
    // Seeded per player name so behaviour is deterministic across runs.
    final seed =
        client.me!.summary.name.codeUnits.fold<int>(17, (a, c) => a * 31 + c) &
        0x7fffffff;

    switch (room.experience) {
      case ExperienceKind.obby:
        final packed = (frame.json['players'] as Map?)?[me];
        if (packed is! List) return;
        final state = ObbyPlayerState.fromPacked(packed.cast());
        _obby ??= ObbyAutopilot(hesitationTicks: 2 + seed % 5, remote: true);
        final plan = _obby!.plan(ObbyCourse.instance, state, frame.tick);
        if (plan != null) client.sendInput(plan.toJson());
      case ExperienceKind.tag:
        final players = (frame.json['players'] as Map?)
            ?.cast<String, Object?>();
        if (players == null || !players.containsKey(me)) return;
        final states = {
          for (final e in players.entries)
            e.key: TagPlayerState.fromPacked((e.value as List).cast()),
        };
        _tag ??= TagAutopilot(seed);
        client.sendInput(_tag!.decide(TagArena.instance, me, states).toJson());
      case ExperienceKind.tycoon:
        final second = frame.ticksLeft ~/ ticksPerSecond;
        if (second == _lastTycoonSecond) return;
        _lastTycoonSecond = second;
        final raw = (frame.json['plots'] as Map?)?[me];
        if (raw is! Map) return;
        _tycoon ??= TycoonAutopilot(seed);
        final action = _tycoon!.decide(TycoonPlot.fromJson(raw.cast()), second);
        if (action != null) client.sendInput(action.toJson());
    }
  }
}

/// Resolves once a frame built after the call has finished rasterising.
///
/// `FrameTiming.frameNumber` matches `PlatformDispatcher.frameData` for the
/// frame it measures, so the gate notes the number of the frame that follows
/// the request and waits for its timing to be reported. Timings are batched
/// by the engine and, on the web, only flushed when a later frame is drawn,
/// so the gate keeps requesting frames every [nudge] while it waits: a
/// static screen would otherwise never report. A platform that never reports
/// timings releases the gate after [timeout] with `false`.
class RasterGate {
  RasterGate() {
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static const timeout = Duration(seconds: 90);
  static const nudge = Duration(milliseconds: 1200);

  final _waiters = <(int, Completer<bool>)>[];
  int _rastered = -1;

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      if (t.frameNumber > _rastered) _rastered = t.frameNumber;
    }
    _waiters.removeWhere((w) {
      if (w.$1 > _rastered) return false;
      if (!w.$2.isCompleted) w.$2.complete(true);
      return true;
    });
  }

  Future<bool> nextRaster() {
    final done = Completer<bool>();
    final binding = SchedulerBinding.instance;
    binding.addPostFrameCallback((_) {
      final frame = PlatformDispatcher.instance.frameData.frameNumber;
      if (frame <= _rastered) {
        done.complete(true);
      } else {
        _waiters.add((frame, done));
      }
    });
    binding.scheduleFrame();
    final keepAlive = Timer.periodic(nudge, (_) => binding.scheduleFrame());
    return done.future
        .timeout(timeout, onTimeout: () => false)
        .whenComplete(keepAlive.cancel);
  }
}
