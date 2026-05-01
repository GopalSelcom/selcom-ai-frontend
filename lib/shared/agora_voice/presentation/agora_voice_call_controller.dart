import 'package:agora_rtc_engine/agora_rtc_engine.dart';
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
    if (callState.value == AgoraVoiceCallState.connecting) return;
    callState.value = AgoraVoiceCallState.connecting;
    errorMessage.value = '';
    try {
      final hasMicPermission = await _ensureMicrophonePermission();
      if (!hasMicPermission) {
        return;
      }

      final creds = await engineService.tokenProvider.fetchCredentials(
        rideId: session.rideId,
      );

      await engineService.ensureInitialized(
        appId: creds.appId,
        registerEvents: _bindEvents,
      );
      await engineService.join(creds);
      await engineService.setSpeakerEnabled(isSpeakerEnabled.value);
      await engineService.setMuted(isMuted.value);
      callState.value = AgoraVoiceCallState.connected;
    } catch (_) {
      callState.value = AgoraVoiceCallState.error;
      errorMessage.value = 'Unable to connect call. Please try again.';
    }
  }

  /// Ensures mic permission is granted before joining RTC.
  /// Returns false after showing the appropriate permission dialog.
  Future<bool> _ensureMicrophonePermission() async {
    final currentStatus = await Permission.microphone.status;
    if (currentStatus.isGranted) return true;

    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      _showMicrophonePermissionDialog();
      callState.value = AgoraVoiceCallState.error;
      errorMessage.value =
          'Microphone access is disabled. Enable it in Settings to continue.';
      return false;
    }

    final requestStatus = await Permission.microphone.request();
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
    await engineService.leave();
    callState.value = AgoraVoiceCallState.ended;
  }

  /// Toggles local microphone publish state.
  Future<void> toggleMute() async {
    final next = !isMuted.value;
    isMuted.value = next;
    await engineService.setMuted(next);
  }

  /// Toggles speakerphone route.
  Future<void> toggleSpeaker() async {
    final next = !isSpeakerEnabled.value;
    isSpeakerEnabled.value = next;
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
        await engineService.renewRtcToken(fresh.token);
      }
    } catch (_) {
      // Agora disconnects on hard expiry; avoid noisy UI here.
    }
  }

  /// Registers runtime Agora callbacks that drive call UI state.
  void _bindEvents(RtcEngineEventHandler _) {
    engineService.setEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          callState.value = AgoraVoiceCallState.connected;
        },
        onTokenPrivilegeWillExpire: (_, __) {
          _refreshRtcToken();
        },
        onConnectionStateChanged: (_, state, __) {
          if (state == ConnectionStateType.connectionStateDisconnected) {
            callState.value = AgoraVoiceCallState.ended;
          }
        },
        onError: (_, __) {
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
