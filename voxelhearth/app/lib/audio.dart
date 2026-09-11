import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Short original sound cues (see tools/gen_audio.py) played through a small
/// pool of low-latency players so rapid dig/place cues can overlap.
class Sfx {
  Sfx._();

  static bool enabled = true;
  static double volume = 0.8;
  static const int _poolSize = 6;
  static final List<AudioPlayer> _pool = <AudioPlayer>[];
  static int _next = 0;
  static bool _ready = false;
  static int _lastMs = 0;
  static String _lastCue = '';

  static Future<void> init() async {
    if (_ready) return;
    _ready = true;
    AudioLogger.logLevel = AudioLogLevel.none;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } catch (e) {
      debugPrint('audio context: $e');
    }
    try {
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer(playerId: 'vh-sfx-$i');
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
    } catch (e) {
      debugPrint('audio unavailable: $e');
    }
  }

  /// Fire-and-forget; identical cues within 40 ms are coalesced.
  static void play(String cue, {double gain = 1}) {
    if (!enabled || _pool.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cue == _lastCue && now - _lastMs < 40) return;
    _lastCue = cue;
    _lastMs = now;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    p.stop().then((_) => p.play(AssetSource('audio/$cue.wav'), volume: (volume * gain).clamp(0, 1))).catchError((
      Object e,
    ) {
      debugPrint('sfx $cue: $e');
    });
  }

  static Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
    _ready = false;
  }
}
