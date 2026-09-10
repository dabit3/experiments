import 'dart:async';

import 'package:flutter/widgets.dart';

/// A widgets binding that spaces rendered frames at least [interval] apart.
///
/// Frame requests arriving while the timer runs are coalesced into the one
/// already scheduled; forced frames (first frame, app resume) bypass the cap.
class ThrottledFrameBinding extends WidgetsFlutterBinding {
  ThrottledFrameBinding(this.interval);

  final Duration interval;
  Timer? _pending;

  @override
  void scheduleFrame() {
    if (!framesEnabled || (_pending?.isActive ?? false)) return;
    _pending = Timer(interval, super.scheduleFrame);
  }
}
