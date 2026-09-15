import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Wraps UI whose content is intentionally platform-specific (e.g. the local
/// player's "iOS" / "web" device label). Each frame the widget publishes its
/// on-screen rectangle so the visual-parity harness can exclude exactly that
/// region and verify the differing text separately.
class PlatformMark extends StatefulWidget {
  const PlatformMark({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  /// Logical-pixel rectangles of every mounted mark, keyed by [id].
  static final Map<String, Rect> regions = {};

  static Map<String, Map<String, double>> toJson() => {
    for (final e in regions.entries)
      e.key: {'x': e.value.left, 'y': e.value.top, 'w': e.value.width, 'h': e.value.height},
  };

  @override
  State<PlatformMark> createState() => _PlatformMarkState();
}

class _PlatformMarkState extends State<PlatformMark> {
  void _publish(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      PlatformMark.regions[widget.id] = box.localToGlobal(Offset.zero) & box.size;
    }
  }

  @override
  void dispose() {
    PlatformMark.regions.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(_publish);
    return widget.child;
  }
}
