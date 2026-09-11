/// Fischer time control: an initial budget plus an increment added after each
/// completed move. `initialMs == 0 && incrementMs == 0` means no clock.
class TimeControl {
  const TimeControl({required this.initialMs, required this.incrementMs});

  final int initialMs;
  final int incrementMs;

  static const unlimited = TimeControl(initialMs: 0, incrementMs: 0);

  bool get isUnlimited => initialMs == 0 && incrementMs == 0;

  /// Category names follow the widely used speed bands.
  String get category {
    if (isUnlimited) return 'Unlimited';
    final estimate = initialMs + incrementMs * 40;
    if (estimate < 3 * 60 * 1000) return 'Bullet';
    if (estimate < 8 * 60 * 1000) return 'Blitz';
    if (estimate < 25 * 60 * 1000) return 'Rapid';
    return 'Classical';
  }

  /// Short label such as `3+2` or `15+10`.
  String get label {
    if (isUnlimited) return '∞';
    final minutes = initialMs / 60000;
    final minuteText = minutes == minutes.roundToDouble()
        ? minutes.round().toString()
        : minutes.toStringAsFixed(1);
    return '$minuteText+${incrementMs ~/ 1000}';
  }

  static const presets = <TimeControl>[
    TimeControl(initialMs: 60000, incrementMs: 0),
    TimeControl(initialMs: 120000, incrementMs: 1000),
    TimeControl(initialMs: 180000, incrementMs: 0),
    TimeControl(initialMs: 180000, incrementMs: 2000),
    TimeControl(initialMs: 300000, incrementMs: 0),
    TimeControl(initialMs: 300000, incrementMs: 3000),
    TimeControl(initialMs: 600000, incrementMs: 0),
    TimeControl(initialMs: 600000, incrementMs: 5000),
    TimeControl(initialMs: 900000, incrementMs: 10000),
    TimeControl(initialMs: 1800000, incrementMs: 0),
    TimeControl(initialMs: 1800000, incrementMs: 20000),
    TimeControl(initialMs: 5400000, incrementMs: 30000),
  ];

  Map<String, Object?> toJson() => {
        'initialMs': initialMs,
        'incrementMs': incrementMs,
      };

  static TimeControl fromJson(Map<String, Object?> json) => TimeControl(
        initialMs: (json['initialMs'] as num?)?.toInt() ?? 0,
        incrementMs: (json['incrementMs'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is TimeControl &&
      other.initialMs == initialMs &&
      other.incrementMs == incrementMs;

  @override
  int get hashCode => Object.hash(initialMs, incrementMs);

  @override
  String toString() => label;
}
