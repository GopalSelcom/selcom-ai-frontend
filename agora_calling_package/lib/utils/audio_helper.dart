import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Audio + haptic helpers for ringback / ringtone / hangup.
///
/// Instance-scoped so an active call can stop its own players without racing
/// with another call's audio.
class CallAudio {
  CallAudio({this.ringbackAsset, this.ringtoneAsset, this.endToneAsset});

  final String? ringbackAsset;
  final String? ringtoneAsset;
  final String? endToneAsset;

  AudioPlayer? _ringback;
  AudioPlayer? _ringtone;

  Future<void> startRingback() async {
    if (ringbackAsset == null) return;
    await stopRingback();
    _ringback = AudioPlayer();
    try {
      await _ringback!.setReleaseMode(ReleaseMode.loop);
      await _ringback!.play(_assetSource(ringbackAsset!));
    } catch (_) {
      // Best-effort; fall through.
    }
  }

  Future<void> stopRingback() async {
    final player = _ringback;
    _ringback = null;
    await player?.stop();
    await player?.dispose();
  }

  Future<void> startRingtone({bool vibrate = true}) async {
    if (ringtoneAsset == null) return;
    await stopRingtone();
    _ringtone = AudioPlayer();
    try {
      await _ringtone!.setReleaseMode(ReleaseMode.loop);
      await _ringtone!.play(_assetSource(ringtoneAsset!), volume: 1.0);
    } catch (_) {
      // Best-effort.
    }
    if (vibrate) {
      unawaited(Vibration.hasVibrator().then((has) {
        if (has == true) {
          Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
        }
      }));
    }
  }

  Future<void> stopRingtone() async {
    final player = _ringtone;
    _ringtone = null;
    await player?.stop();
    await player?.dispose();
    unawaited(Vibration.cancel());
  }

  Future<void> playEndTone() async {
    if (endToneAsset == null) return;
    final player = AudioPlayer();
    try {
      await player.play(_assetSource(endToneAsset!));
      // Auto-dispose after a short delay so the buffer can play out.
      Future.delayed(const Duration(seconds: 2), () => player.dispose());
    } catch (_) {
      await player.dispose();
    }
  }

  Future<void> disposeAll() async {
    await stopRingback();
    await stopRingtone();
  }

  /// Asset paths registered through pubspec start with `assets/` and are
  /// addressed without that prefix by [AssetSource].
  AssetSource _assetSource(String path) {
    return AssetSource(path.startsWith('assets/') ? path.substring(7) : path);
  }
}
