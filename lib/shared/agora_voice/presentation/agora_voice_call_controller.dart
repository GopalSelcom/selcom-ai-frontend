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

  Future<void> startCall() async {
    if (callState.value == AgoraVoiceCallState.connecting) return;
    callState.value = AgoraVoiceCallState.connecting;
    errorMessage.value = '';
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        callState.value = AgoraVoiceCallState.error;
        errorMessage.value =
            'Microphone permission is required for voice calls.';
        return;
      }

      await engineService.ensureInitialized(registerEvents: _bindEvents);
      await engineService.setSpeakerEnabled(isSpeakerEnabled.value);
      await engineService.setMuted(isMuted.value);
      await engineService.join(session);
      callState.value = AgoraVoiceCallState.connected;
    } catch (_) {
      callState.value = AgoraVoiceCallState.error;
      errorMessage.value = 'Unable to connect call. Please try again.';
    }
  }

  Future<void> endCall() async {
    await engineService.leave();
    callState.value = AgoraVoiceCallState.ended;
  }

  Future<void> toggleMute() async {
    final next = !isMuted.value;
    isMuted.value = next;
    await engineService.setMuted(next);
  }

  Future<void> toggleSpeaker() async {
    final next = !isSpeakerEnabled.value;
    isSpeakerEnabled.value = next;
    await engineService.setSpeakerEnabled(next);
  }

  Future<void> restartCall() async {
    await endCall();
    callState.value = AgoraVoiceCallState.idle;
    await startCall();
  }

  void _bindEvents(RtcEngineEventHandler _) {
    engineService.setEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          callState.value = AgoraVoiceCallState.connected;
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

  Future<void> disposeCall() async {
    await engineService.dispose();
  }

  @override
  void onClose() {
    engineService.dispose();
    super.onClose();
  }
}
