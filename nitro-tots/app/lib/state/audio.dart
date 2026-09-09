import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';

/// Thin wrapper over flame_audio with volume settings and haptics.
class NtFeedback {
  NtFeedback(this.state);

  final AppState state;
  String? _music;
  bool _musicStarted = false;
  int _lastTickMs = 0;

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'click.wav',
        'select.wav',
        'back.wav',
        'countdown.wav',
        'go.wav',
        'boost.wav',
        'drift.wav',
        'turbo.wav',
        'pickup.wav',
        'use.wav',
        'hit.wav',
        'bump.wav',
        'shield.wav',
        'jump.wav',
        'land.wav',
        'lap.wav',
        'finish.wav',
        'wrongway.wav',
        'error.wav',
      ]);
    } catch (e) {
      debugPrint('audio preload failed: $e');
    }
  }

  void sfx(String name, {double volume = 1, int throttleMs = 0}) {
    if (state.sfxVolume <= 0) return;
    if (throttleMs > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastTickMs < throttleMs) return;
      _lastTickMs = now;
    }
    try {
      FlameAudio.play('$name.wav', volume: (volume * state.sfxVolume).clamp(0, 1));
    } catch (e) {
      debugPrint('sfx failed: $e');
    }
  }

  Future<void> music(String name) async {
    if (_music == name && _musicStarted) {
      await setMusicVolume(state.musicVolume);
      return;
    }
    _music = name;
    if (state.musicVolume <= 0) {
      await stopMusic();
      return;
    }
    try {
      await FlameAudio.bgm.play('$name.wav', volume: state.musicVolume);
      _musicStarted = true;
    } catch (e) {
      debugPrint('music failed: $e');
    }
  }

  Future<void> setMusicVolume(double v) async {
    try {
      if (v <= 0) {
        await FlameAudio.bgm.stop();
        _musicStarted = false;
      } else if (!_musicStarted && _music != null) {
        await FlameAudio.bgm.play('$_music.wav', volume: v);
        _musicStarted = true;
      } else {
        await FlameAudio.bgm.audioPlayer.setVolume(v);
      }
    } catch (e) {
      debugPrint('music volume failed: $e');
    }
  }

  Future<void> applyVolumes() => setMusicVolume(state.musicVolume);

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
    _musicStarted = false;
  }

  void tap() {
    sfx('click', volume: 0.6);
    haptic(HapticsKind.light);
  }

  void haptic(HapticsKind kind) {
    if (!state.haptics || !state.isMobile) return;
    switch (kind) {
      case HapticsKind.light:
        HapticFeedback.lightImpact();
      case HapticsKind.medium:
        HapticFeedback.mediumImpact();
      case HapticsKind.heavy:
        HapticFeedback.heavyImpact();
      case HapticsKind.select:
        HapticFeedback.selectionClick();
    }
  }
}

enum HapticsKind { light, medium, heavy, select }
