import 'package:brickfolk_shared/brickfolk_shared.dart';

import '../net/client.dart';

/// Blends the last two server frames so 30 Hz simulation renders smoothly at
/// the display refresh rate. `alpha` is the normalized time since the newest
/// frame arrived, clamped to one tick.
class FrameBlend {
  FrameBlend(this.current, this.previous, int nowMs)
    : alpha = previous == null
          ? 1
          : ((nowMs - current.receivedAt) / (tickDt * 1000)).clamp(0.0, 1.0);

  final GameFrame current;
  final GameFrame? previous;
  final double alpha;

  Map<String, List<Object?>> get players =>
      ((current.json['players'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as List).cast<Object?>()),
      );

  List<Object?>? previousPacked(String id) {
    final prev = previous?.json['players'] as Map?;
    final v = prev?[id];
    return v is List ? v.cast<Object?>() : null;
  }

  double lerp(double a, double b) => a + (b - a) * alpha;

  /// Interpolated obby position for [id]; snaps on respawn teleports.
  ({double x, double y}) obbyPos(String id, ObbyPlayerState now) {
    final prevPacked = previousPacked(id);
    if (prevPacked == null) return (x: now.x, y: now.y);
    final prev = ObbyPlayerState.fromPacked(prevPacked);
    if ((prev.x - now.x).abs() > 3 || (prev.y - now.y).abs() > 3) {
      return (x: now.x, y: now.y);
    }
    return (x: lerp(prev.x, now.x), y: lerp(prev.y, now.y));
  }

  ({double x, double y}) tagPos(String id, TagPlayerState now) {
    final prevPacked = previousPacked(id);
    if (prevPacked == null) return (x: now.x, y: now.y);
    final prev = TagPlayerState.fromPacked(prevPacked);
    if ((prev.x - now.x).abs() > 3 || (prev.y - now.y).abs() > 3) {
      return (x: now.x, y: now.y);
    }
    return (x: lerp(prev.x, now.x), y: lerp(prev.y, now.y));
  }
}
