import 'package:gambit_court_core/gambit_court_core.dart';

/// Injectable wall clock so tests and deterministic runs can control time.
abstract class WallClock {
  int nowMs();
}

class SystemWallClock implements WallClock {
  const SystemWallClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// Manually advanced clock used by tests and `--frozen-clocks` runs.
class ManualWallClock implements WallClock {
  ManualWallClock([this._now = 1700000000000]);

  int _now;

  void advance(int ms) => _now += ms;

  @override
  int nowMs() => _now;
}

/// Server-side game clock. Remaining times are stored for both sides and the
/// running side's elapsed time is derived from [turnStartedAt].
class GameClock {
  GameClock(this.timeControl, this.wall, {required this.frozen})
      : whiteMs = timeControl.initialMs,
        blackMs = timeControl.initialMs;

  final TimeControl timeControl;
  final WallClock wall;
  final bool frozen;

  int whiteMs;
  int blackMs;
  PieceColor? running;
  int turnStartedAt = 0;

  int remaining(PieceColor color) {
    final base = color == PieceColor.white ? whiteMs : blackMs;
    if (running != color || frozen || timeControl.isUnlimited) return base;
    final elapsed = wall.nowMs() - turnStartedAt;
    return (base - elapsed).clamp(0, base);
  }

  bool get flagged =>
      running != null && !timeControl.isUnlimited && remaining(running!) <= 0;

  void start(PieceColor toMove) {
    running = toMove;
    turnStartedAt = wall.nowMs();
  }

  void stop() {
    if (running != null) _settle(running!);
    running = null;
  }

  /// Records that [mover] just moved: charges elapsed time, applies the
  /// increment, and hands the clock to the other side. Neither side's first
  /// move is timed or credited; the clock starts running once both have moved.
  void punch(PieceColor mover) {
    if (running == mover) {
      _settle(mover);
      if (mover == PieceColor.white) {
        whiteMs += timeControl.incrementMs;
      } else {
        blackMs += timeControl.incrementMs;
      }
    }
    if (running != null || mover == PieceColor.black) start(mover.opposite);
  }

  void _settle(PieceColor color) {
    final left = remaining(color);
    if (color == PieceColor.white) {
      whiteMs = left;
    } else {
      blackMs = left;
    }
  }

  ClockState snapshot() => ClockState(
        whiteMs: remaining(PieceColor.white),
        blackMs: remaining(PieceColor.black),
        running: running,
        asOfServerMs: wall.nowMs(),
        frozen: frozen,
      );
}
