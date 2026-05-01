import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/app_dialogs.dart';
import '../domain/agora_voice_call_session.dart';
import '../domain/agora_voice_call_state.dart';
import '../service/agora_voice_engine_service.dart';

class AgoraVoiceCallController extends GetxController {
  AgoraVoiceCallController({
    required this.engineService,
    required this.session,
  });

  final AgoraVoiceEngineService engineService;
  final AgoraVoiceCallSession session;

  final callState = AgoraVoiceCallState.idle.obs;
  final errorMessage = ''.obs;
  final isMuted = false.obs;
  final isSpeakerEnabled = true.obs;

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
      callState.value = AgoraVoiceCallState.connected;
      if (kDebugMode) {
        debugPrint('[AGORA_FLOW] startCall success ride=${session.rideId}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AGORA_FLOW] startCall failed ride=${session.rideId} error=$e');
        debugPrint('$st');
      }
      callState.value = AgoraVoiceCallState.error;
      errorMessage.value = 'Unable to connect call. Please try again.';
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
  Future<void> endCall() async {
    if (kDebugMode) {
      debugPrint('[AGORA_FLOW] endCall ride=${session.rideId}');
    }
    await engineService.leave();
    callState.value = AgoraVoiceCallState.ended;
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
    await endCall();
    callState.value = AgoraVoiceCallState.idle;
    await startCall();
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
            callState.value = AgoraVoiceCallState.ended;
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
    await engineService.dispose();
  }

  @override
  void onClose() {
    engineService.dispose();
    super.onClose();
  }
}
