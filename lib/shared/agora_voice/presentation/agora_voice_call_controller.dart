import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/app_dialogs.dart';
import '../domain/agora_voice_call_end_reason.dart';
import '../domain/agora_voice_call_session.dart';
import '../domain/agora_voice_call_state.dart';
import '../service/agora_voice_engine_service.dart';

class AgoraVoiceCallController extends GetxController {
  AgoraVoiceCallController({
    required this.engineService,
    required this.session,
    this.onLocalEndRequested,
    this.enableRingbackOnConnectFlow = true,
    this.enableIncomingRingtone = true,
    this.enableUnansweredTimeout = true,
    this.unansweredTimeout = const Duration(seconds: 35),
    this.onUnansweredTimeout,
    this.onCallConnected,
    this.onCallEnded,
    this.onCallRejected,
    this.onCallMissed,
  });

  final AgoraVoiceEngineService engineService;
  final AgoraVoiceCallSession session;
  final Future<void> Function()? onLocalEndRequested;
  final bool enableRingbackOnConnectFlow;
  final bool enableIncomingRingtone;
  final bool enableUnansweredTimeout;
  final Duration unansweredTimeout;
  final Future<void> Function()? onUnansweredTimeout;
  final Future<void> Function()? onCallConnected;
  final Future<void> Function(AgoraVoiceCallEndReason reason)? onCallEnded;
  final Future<void> Function()? onCallRejected;
  final Future<void> Function()? onCallMissed;

  final callState = AgoraVoiceCallState.idle.obs;
  final errorMessage = ''.obs;
  final isMuted = false.obs;
  final isSpeakerEnabled = true.obs;
  final connectedDurationSeconds = 0.obs;
  final endReason = Rxn<AgoraVoiceCallEndReason>();
  Timer? _ringbackTimer;
  Timer? _incomingRingtoneTimer;
  Timer? _unansweredTimeoutTimer;
  Timer? _connectedDurationTimer;
  bool _isEnding = false;

  /// Main join flow used by both outgoing and incoming accept.
  /// If anything fails here, UI goes to [AgoraVoiceCallState.error].
  Future<void> startCall() async {
    if (callState.value == AgoraVoiceCallState.connecting ||
        callState.value == AgoraVoiceCallState.connected) {
      if (kDebugMode) {
        debugPrint(
          '[AGORA_FLOW] startCall skipped state=${callState.value.name} '
          'ride=${session.rideId}',
        );
      }
      return;
    }
    callState.value = AgoraVoiceCallState.connecting;
    errorMessage.value = '';
    endReason.value = null;
    _isEnding = false;
    stopIncomingRingtone();
    if (enableRingbackOnConnectFlow) {
      _startRingbackTone();
    }
    _startUnansweredTimeout();
    try {
      if (kDebugMode) {
        debugPrint(
          '[AGORA_FLOW] startCall ride=${session.rideId} '
          'provider=${engineService.tokenProvider.runtimeType}',
        );
      }
      final hasMicPermission = await _ensureMicrophonePermission();
      if (!hasMicPermission) {
        if (kDebugMode) {
          debugPrint('[AGORA_FLOW] startCall blocked: mic permission denied');
        }
        return;
      }

      final creds = await engineService.tokenProvider.fetchCredentials(
        rideId: session.rideId,
      );
      if (kDebugMode) {
        debugPrint(
          '[AGORA_FLOW] credentials ride=${session.rideId} '
          'channel=${creds.channel} uid=${creds.uid}',
        );
      }

      await engineService.ensureInitialized(
        appId: creds.appId,
        registerEvents: _bindEvents,
      );
      await engineService.join(creds);
      await engineService.setSpeakerEnabled(isSpeakerEnabled.value);
      await engineService.setMuted(isMuted.value);
      _stopRingbackTone();
      _stopUnansweredTimeout();
      callState.value = AgoraVoiceCallState.connected;
      _startConnectedDurationTimer();
      await onCallConnected?.call();
      if (kDebugMode) {
        debugPrint('[AGORA_FLOW] startCall success ride=${session.rideId}');
      }
    } catch (e, st) {
      _stopRingbackTone();
      _stopUnansweredTimeout();
      if (kDebugMode) {
        debugPrint('[AGORA_FLOW] startCall failed ride=${session.rideId} error=$e');
        debugPrint('$st');
      }
      callState.value = AgoraVoiceCallState.error;
      final msg = e.toString().toLowerCase();
      if (msg.contains('429') || msg.contains('rate-limited')) {
        errorMessage.value =
            'Call service is busy right now. Please try again shortly.';
      } else {
        errorMessage.value = 'Unable to connect call. Please try again.';
      }
    }
  }

  /// Ensures mic permission is granted before joining RTC.
  /// Returns false after showing the appropriate permission dialog.
  Future<bool> _ensureMicrophonePermission() async {
    final currentStatus = await Permission.microphone.status;
    if (kDebugMode) {
      debugPrint('[AGORA_FLOW] mic status current=${currentStatus.name}');
    }
    if (currentStatus.isGranted) return true;

    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      _showMicrophonePermissionDialog();
      callState.value = AgoraVoiceCallState.error;
      errorMessage.value =
          'Microphone access is disabled. Enable it in Settings to continue.';
      return false;
    }

    final requestStatus = await Permission.microphone.request();
    if (kDebugMode) {
      debugPrint('[AGORA_FLOW] mic status requested=${requestStatus.name}');
    }
    if (requestStatus.isGranted) return true;

    if (requestStatus.isPermanentlyDenied || requestStatus.isRestricted) {
      _showMicrophonePermissionDialog();
    } else {
      AppDialogs.showErrorDialog(
        title: 'Microphone Permission',
        message: 'Microphone permission is required for voice calls.',
      );
    }

    callState.value = AgoraVoiceCallState.error;
    errorMessage.value = 'Microphone permission is required for voice calls.';
    return false;
  }

  /// Opens the shared "Open Settings" permission dialog.
  void _showMicrophonePermissionDialog() {
    AppDialogs.showPermissionDialog(
      title: 'Microphone Permission Required',
      message:
          'Please enable microphone access in Settings to make or receive voice calls.',
      onOpenSettings: openAppSettings,
    );
  }

  /// Leaves Agora channel and marks the call as ended.
  ///
  /// With [notifyRemote] true (default), we invoke [onLocalEndRequested] once
  /// before leaving the channel so peer app can terminate its call UI too.
  Future<void> endCall({bool notifyRemote = true}) async {
    await _endWithReason(
      reason: AgoraVoiceCallEndReason.localHangup,
      notifyRemote: notifyRemote,
    );
  }

  Future<void> _endWithReason({
    required AgoraVoiceCallEndReason reason,
    required bool notifyRemote,
  }) async {
    if (_isEnding || callState.value == AgoraVoiceCallState.ended) return;
    _isEnding = true;
    try {
      if (kDebugMode) {
        debugPrint(
          '[AGORA_FLOW] endCall ride=${session.rideId} '
          'reason=${reason.name} notifyRemote=$notifyRemote',
        );
      }
      if (notifyRemote) {
        try {
          await onLocalEndRequested?.call();
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('[AGORA_FLOW] onLocalEndRequested failed: $e');
            debugPrint('$st');
          }
        }
      }
      _stopRingbackTone();
      stopIncomingRingtone();
      _stopUnansweredTimeout();
      _stopConnectedDurationTimer();
      await engineService.leave();
      endReason.value = reason;
      callState.value = AgoraVoiceCallState.ended;
      try {
        await onCallEnded?.call(reason);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[AGORA_FLOW] onCallEnded callback failed: $e');
          debugPrint('$st');
        }
      }
    } finally {
      _isEnding = false;
    }
  }

  /// Ends the call due to a remote signal without re-emitting local end signal.
  Future<void> endCallFromRemote({
    AgoraVoiceCallEndReason reason = AgoraVoiceCallEndReason.remoteEnded,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[AGORA_FLOW] endCallFromRemote ride=${session.rideId} '
        'reason=${reason.name}',
      );
    }
    if (reason == AgoraVoiceCallEndReason.remoteRejected) {
      try {
        await onCallRejected?.call();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[AGORA_FLOW] onCallRejected callback failed: $e');
          debugPrint('$st');
        }
      }
    }
    await _endWithReason(reason: reason, notifyRemote: false);
  }

  /// Toggles local microphone publish state.
  Future<void> toggleMute() async {
    final next = !isMuted.value;
    isMuted.value = next;
    if (kDebugMode) {
      debugPrint('[AGORA_FLOW] toggleMute next=$next ride=${session.rideId}');
    }
    await engineService.setMuted(next);
  }

  /// Toggles speakerphone route.
  Future<void> toggleSpeaker() async {
    final next = !isSpeakerEnabled.value;
    isSpeakerEnabled.value = next;
    if (kDebugMode) {
      debugPrint('[AGORA_FLOW] toggleSpeaker next=$next ride=${session.rideId}');
    }
    await engineService.setSpeakerEnabled(next);
  }

  /// Retry helper: end old session and run full start flow again.
  Future<void> restartCall() async {
    await endCall(notifyRemote: false);
    callState.value = AgoraVoiceCallState.idle;
    await startCall();
  }

  /// Leaves the local channel after the peer goes offline (matches typical
  /// Agora 1:1 voice teardown so we do not stay joined alone).
  Future<void> _leaveChannelAfterRemoteOffline() async {
    if (callState.value == AgoraVoiceCallState.ended ||
        callState.value == AgoraVoiceCallState.error ||
        callState.value == AgoraVoiceCallState.idle) {
      return;
    }
    await _endWithReason(
      reason: AgoraVoiceCallEndReason.remoteOffline,
      notifyRemote: false,
    );
  }

  /// Refreshes RTC token during long calls when Agora signals expiry.
  Future<void> _refreshRtcToken() async {
    try {
      final fresh = await engineService.tokenProvider.fetchCredentials(
        rideId: session.rideId,
      );
      if (fresh.token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[AGORA_FLOW] renew token ride=${session.rideId} '
            'channel=${fresh.channel} uid=${fresh.uid}',
          );
        }
        await engineService.renewRtcToken(fresh.token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_FLOW] renew token failed ride=${session.rideId} error=$e');
      }
      // Agora disconnects on hard expiry; avoid noisy UI here.
    }
  }

  /// Plays a lightweight caller ringback while waiting for peer answer.
  ///
  /// Uses [SystemSoundType.alert] so shared module has no external audio asset
  /// dependency. Pattern: two quick beeps, then pause.
  void _startRingbackTone() {
    _stopRingbackTone();
    _ringbackTimer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (callState.value != AgoraVoiceCallState.connecting) {
        _stopRingbackTone();
        return;
      }
      SystemSound.play(SystemSoundType.alert);
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (callState.value == AgoraVoiceCallState.connecting) {
          SystemSound.play(SystemSoundType.alert);
        }
      });
    });
    // Trigger immediately so user hears feedback right away.
    SystemSound.play(SystemSoundType.alert);
  }

  void _stopRingbackTone() {
    _ringbackTimer?.cancel();
    _ringbackTimer = null;
  }

  /// Starts incoming ringtone loop for callee-side incoming screen.
  ///
  /// Shared-module safe implementation using [SystemSoundType.alert] so no
  /// project-specific audio assets are required.
  void startIncomingRingtone() {
    if (!enableIncomingRingtone) return;
    stopIncomingRingtone();
    _incomingRingtoneTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (callState.value == AgoraVoiceCallState.connected ||
          callState.value == AgoraVoiceCallState.ended ||
          callState.value == AgoraVoiceCallState.error) {
        stopIncomingRingtone();
        return;
      }
      SystemSound.play(SystemSoundType.alert);
    });
    // Immediate cue so callee hears ring right when screen opens.
    SystemSound.play(SystemSoundType.alert);
  }

  void stopIncomingRingtone() {
    _incomingRingtoneTimer?.cancel();
    _incomingRingtoneTimer = null;
  }

  void _startUnansweredTimeout() {
    _stopUnansweredTimeout();
    if (!enableUnansweredTimeout || unansweredTimeout <= Duration.zero) return;

    _unansweredTimeoutTimer = Timer(unansweredTimeout, () {
      if (callState.value != AgoraVoiceCallState.connecting) return;
      if (kDebugMode) {
        debugPrint(
          '[AGORA_FLOW] unanswered timeout reached '
          'ride=${session.rideId} timeoutMs=${unansweredTimeout.inMilliseconds}',
        );
      }
      unawaited(_handleUnansweredTimeout());
    });
  }

  void _stopUnansweredTimeout() {
    _unansweredTimeoutTimer?.cancel();
    _unansweredTimeoutTimer = null;
  }

  void _startConnectedDurationTimer() {
    _stopConnectedDurationTimer(reset: true);
    _connectedDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (callState.value != AgoraVoiceCallState.connected) {
        _stopConnectedDurationTimer();
        return;
      }
      connectedDurationSeconds.value += 1;
    });
  }

  void _stopConnectedDurationTimer({bool reset = false}) {
    _connectedDurationTimer?.cancel();
    _connectedDurationTimer = null;
    if (reset) {
      connectedDurationSeconds.value = 0;
    }
  }

  String connectedDurationLabel() {
    final total = connectedDurationSeconds.value;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _handleUnansweredTimeout() async {
    await onCallMissed?.call();
    await onUnansweredTimeout?.call();
    await _endWithReason(
      reason: AgoraVoiceCallEndReason.unansweredTimeout,
      notifyRemote: true,
    );
  }

  /// Registers runtime Agora callbacks that drive call UI state.
  void _bindEvents(RtcEngineEventHandler _) {
    engineService.setEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          if (kDebugMode) {
            debugPrint('[AGORA_FLOW] onJoinChannelSuccess ride=${session.rideId}');
          }
          callState.value = AgoraVoiceCallState.connected;
        },
        /// Remote user left the channel (hang up, quit, or dropped) — see Agora
        /// [RtcEngineEventHandler.onUserOffline] in the Voice/Video SDK docs.
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          if (kDebugMode) {
            debugPrint(
              '[AGORA_FLOW] onUserOffline uid=$remoteUid reason=${reason.name} '
              'ride=${session.rideId}',
            );
          }
          if (callState.value == AgoraVoiceCallState.ended ||
              callState.value == AgoraVoiceCallState.error ||
              callState.value == AgoraVoiceCallState.idle) {
            return;
          }
          unawaited(_leaveChannelAfterRemoteOffline());
        },
        onTokenPrivilegeWillExpire: (_, __) {
          if (kDebugMode) {
            debugPrint('[AGORA_FLOW] onTokenPrivilegeWillExpire ride=${session.rideId}');
          }
          _refreshRtcToken();
        },
        onConnectionStateChanged: (_, state, __) {
          if (kDebugMode) {
            debugPrint('[AGORA_FLOW] connectionState=${state.name} ride=${session.rideId}');
          }
          if (state == ConnectionStateType.connectionStateDisconnected) {
            unawaited(
              _endWithReason(
                reason: AgoraVoiceCallEndReason.disconnected,
                notifyRemote: false,
              ),
            );
          }
        },
        onError: (_, err) {
          if (kDebugMode) {
            debugPrint('[AGORA_FLOW] agora onError code=$err ride=${session.rideId}');
          }
          callState.value = AgoraVoiceCallState.error;
          errorMessage.value =
              'Agora error occurred while handling voice call.';
        },
      ),
    );
  }

  /// Human-readable state label for debug/status UI.
  String stateLabel() {
    switch (callState.value) {
      case AgoraVoiceCallState.idle:
        return 'Idle';
      case AgoraVoiceCallState.connecting:
        return 'Connecting...';
      case AgoraVoiceCallState.connected:
        return 'Connected';
      case AgoraVoiceCallState.ended:
        return 'Ended';
      case AgoraVoiceCallState.error:
        return 'Error';
    }
  }

  String endReasonLabel() {
    switch (endReason.value) {
      case AgoraVoiceCallEndReason.localHangup:
        return 'Call ended';
      case AgoraVoiceCallEndReason.remoteEnded:
        return 'Call ended by other side';
      case AgoraVoiceCallEndReason.remoteRejected:
        return 'Call declined';
      case AgoraVoiceCallEndReason.remoteOffline:
        return 'Other side left the call';
      case AgoraVoiceCallEndReason.unansweredTimeout:
        return 'No answer';
      case AgoraVoiceCallEndReason.disconnected:
        return 'Connection lost';
      case null:
        return 'Call ended';
    }
  }

  /// Shows one error dialog when state transitions to error.
  void showErrorIfNeeded() {
    if (callState.value != AgoraVoiceCallState.error ||
        errorMessage.value.isEmpty) {
      return;
    }
    AppDialogs.showErrorDialog(
      title: 'Voice Call',
      message: errorMessage.value,
    );
  }

  /// Explicit disposal entry used by host feature controller.
  Future<void> disposeCall() async {
    _stopRingbackTone();
    stopIncomingRingtone();
    _stopUnansweredTimeout();
    _stopConnectedDurationTimer();
    await engineService.dispose();
  }

  @override
  void onClose() {
    _stopRingbackTone();
    stopIncomingRingtone();
    _stopUnansweredTimeout();
    _stopConnectedDurationTimer();
    engineService.dispose();
    super.onClose();
  }
}
