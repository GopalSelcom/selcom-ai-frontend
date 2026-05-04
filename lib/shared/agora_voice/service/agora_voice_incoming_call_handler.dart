import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../domain/agora_call_invite_event.dart';
import '../domain/agora_incoming_call_signal.dart';
import '../domain/agora_call_signaling_service.dart';
import '../domain/agora_voice_call_state.dart';
import '../presentation/agora_voice_call_controller.dart';
import '../presentation/agora_voice_call_screen.dart';

typedef AgoraVoiceControllerBuilder =
    AgoraVoiceCallController Function(AgoraCallInviteEvent event);
typedef AgoraVoiceControllerAccessor = AgoraVoiceCallController? Function();
typedef AgoraVoiceControllerSetter = void Function(AgoraVoiceCallController? c);
typedef AgoraRouteCloser = void Function();

/// Shared incoming-call orchestration used by feature controllers.
///
/// Keeps invite/accept/reject/end handling in `lib/shared/agora_voice/` so host
/// apps can reuse the same behavior with different token/signaling implementations.
class AgoraVoiceIncomingCallHandler {
  AgoraVoiceIncomingCallHandler({
    required this.signalingService,
    required this.localClientId,
    required this.rideId,
    required this.localDisplayName,
    required this.canStartCall,
    required this.buildController,
    required this.getActiveController,
    required this.setActiveController,
    required this.closeCallRouteIfOpen,
  });

  final AgoraCallSignalingService signalingService;
  final String localClientId;
  final String rideId;
  final String localDisplayName;
  final bool Function() canStartCall;
  final AgoraVoiceControllerBuilder buildController;
  final AgoraVoiceControllerAccessor getActiveController;
  final AgoraVoiceControllerSetter setActiveController;
  final AgoraRouteCloser closeCallRouteIfOpen;

  Worker? _callStateWorker;

  /// Entry point from host signaling listeners.
  Future<void> handleEvent(AgoraCallInviteEvent event) async {
    if (kDebugMode) {
      debugPrint(
        '[AGORA_SIGNAL] event=${event.type.name} ride=${event.rideId} '
        'channel=${event.channelName} callerId=${event.callerId}',
      );
    }
    if (event.callerId == localClientId) return;
    if (event.rideId != rideId) return;

    switch (event.type) {
      case AgoraCallInviteEventType.invite:
        await _showIncomingCallScreen(event);
        break;
      case AgoraCallInviteEventType.accept:
        await getActiveController()?.startCall();
        break;
      case AgoraCallInviteEventType.reject:
      case AgoraCallInviteEventType.end:
        await getActiveController()?.endCall();
        closeCallRouteIfOpen();
        break;
    }
  }

  /// Entry point for backend push payloads (`type=incoming_call`).
  ///
  /// This allows FCM/APNs wake signals to reuse the same in-app incoming-call UI
  /// flow as socket invite events.
  Future<void> handleIncomingCallPush(
    Map<String, dynamic> payload, {
    String callerId = 'backend_push',
    String? callerName,
  }) async {
    if (kDebugMode) {
      debugPrint('[AGORA_SIGNAL] incoming push payload=$payload');
    }
    final signal = AgoraIncomingCallSignal.fromMap(payload);
    if (signal == null) return;
    final invite = signal.toInviteEvent(
      callerId: callerId,
      callerName: callerName,
    );
    await handleEvent(invite);
  }

  Future<void> _showIncomingCallScreen(AgoraCallInviteEvent event) async {
    if (!canStartCall()) {
      if (kDebugMode) {
        debugPrint('[AGORA_SIGNAL] cannot start call for incoming invite');
      }
      return;
    }

    final controller = buildController(event);
    setActiveController(controller);
    _attachCallStateListener(controller);

    await Get.to(
      () => AgoraVoiceCallScreen(
        controller: controller,
        displayName: event.callerName,
        isIncoming: true,
        onAccept: () async {
          if (kDebugMode) {
            debugPrint('[AGORA_SIGNAL] incoming accept tapped ride=${event.rideId}');
          }
          await signalingService.sendEvent(
            AgoraCallInviteEvent(
              type: AgoraCallInviteEventType.accept,
              channelName: event.channelName,
              rideId: event.rideId,
              callerName: localDisplayName,
              callerId: localClientId,
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          await controller.startCall();
        },
        onReject: () async {
          if (kDebugMode) {
            debugPrint('[AGORA_SIGNAL] incoming reject tapped ride=${event.rideId}');
          }
          await signalingService.sendEvent(
            AgoraCallInviteEvent(
              type: AgoraCallInviteEventType.reject,
              channelName: event.channelName,
              rideId: event.rideId,
              callerName: localDisplayName,
              callerId: localClientId,
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          await controller.endCall();
          closeCallRouteIfOpen();
        },
        onHangUp: () async {
          if (kDebugMode) {
            debugPrint('[AGORA_SIGNAL] incoming hang up ride=${event.rideId}');
          }
          await signalingService.sendEvent(
            AgoraCallInviteEvent(
              type: AgoraCallInviteEventType.end,
              channelName: event.channelName,
              rideId: event.rideId,
              callerName: localDisplayName,
              callerId: localClientId,
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          await controller.endCall();
          closeCallRouteIfOpen();
        },
      ),
      fullscreenDialog: true,
    );

    _detachCallStateListener();
    setActiveController(null);
  }

  void _attachCallStateListener(AgoraVoiceCallController controller) {
    _detachCallStateListener();
    _callStateWorker = ever(controller.callState, (state) {
      if (state == AgoraVoiceCallState.ended) {
        closeCallRouteIfOpen();
      }
    });
  }

  void _detachCallStateListener() {
    _callStateWorker?.dispose();
    _callStateWorker = null;
  }

  void dispose() {
    _detachCallStateListener();
  }
}
