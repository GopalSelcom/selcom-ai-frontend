import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../domain/agora_call_invite_event.dart';
import '../domain/agora_incoming_call_signal.dart';
import '../domain/agora_call_signaling_service.dart';
import '../domain/agora_voice_call_end_reason.dart';
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
    this.onRejectCallApi,
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
  final Future<void> Function(String rideId)? onRejectCallApi;

  Worker? _callStateWorker;

  /// True while `_showIncomingCallScreen` owns the fullscreen route — prevents a
  /// second `invite` (e.g. FCM after socket or duplicate pushes) from opening
  /// another Accept/Reject layer on top of an active session.
  bool _incomingCallUiActive = false;

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
        if (kDebugMode) {
          debugPrint(
            '[AGORA_SIGNAL] remote reject received '
            'ride=${event.rideId} channel=${event.channelName} '
            'callerId=${event.callerId}',
          );
        }
        final rejectController = getActiveController();
        if (rejectController != null) {
          await rejectController.endCallFromRemote(
            reason: AgoraVoiceCallEndReason.remoteRejected,
          );
          // Route is closed by [_attachCallStateListener] / host ever(worker) on ended.
        } else {
          closeCallRouteIfOpen();
        }
        break;
      case AgoraCallInviteEventType.end:
        if (kDebugMode) {
          debugPrint(
            '[AGORA_SIGNAL] remote end received '
            'ride=${event.rideId} channel=${event.channelName} '
            'callerId=${event.callerId}',
          );
        }
        final endController = getActiveController();
        if (endController != null) {
          await endController.endCallFromRemote(
            reason: AgoraVoiceCallEndReason.remoteEnded,
          );
        } else {
          closeCallRouteIfOpen();
        }
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

  /// Another invite must not stack a second [AgoraVoiceCallScreen] while the user
  /// is already placing or in a call for this ride (outgoing or accepted incoming).
  bool _shouldIgnoreInviteBecauseCallSessionBusy() {
    final c = getActiveController();
    if (c == null) return false;
    switch (c.callState.value) {
      case AgoraVoiceCallState.connecting:
      case AgoraVoiceCallState.connected:
        return true;
      case AgoraVoiceCallState.idle:
      case AgoraVoiceCallState.ended:
      case AgoraVoiceCallState.error:
        return false;
    }
  }

  Future<void> _showIncomingCallScreen(AgoraCallInviteEvent event) async {
    if (!canStartCall()) {
      if (kDebugMode) {
        debugPrint('[AGORA_SIGNAL] cannot start call for incoming invite');
      }
      return;
    }

    if (_incomingCallUiActive) {
      if (kDebugMode) {
        debugPrint(
          '[AGORA_SIGNAL] skip duplicate invite (incoming UI already active) '
          'ride=$rideId',
        );
      }
      return;
    }

    if (_shouldIgnoreInviteBecauseCallSessionBusy()) {
      if (kDebugMode) {
        debugPrint(
          '[AGORA_SIGNAL] skip invite (call already connecting or connected) '
          'ride=$rideId',
        );
      }
      return;
    }

    _incomingCallUiActive = true;
    AgoraVoiceCallController? controller;
    try {
      controller = buildController(event);
      setActiveController(controller);
      _attachCallStateListener(controller);
      controller.startIncomingRingtone();

      await Get.to(
        () => AgoraVoiceCallScreen(
          controller: controller!,
          displayName: event.callerName,
          isIncoming: true,
          onAccept: () async {
            if (kDebugMode) {
              debugPrint('[AGORA_SIGNAL] incoming accept tapped ride=${event.rideId}');
            }
            controller!.stopIncomingRingtone();
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
            // Once incoming call is accepted, stop caller-style ringback/timeout behavior.
            await controller.startCall();
          },
          onReject: () async {
            if (kDebugMode) {
              debugPrint('[AGORA_SIGNAL] incoming reject tapped ride=${event.rideId}');
            }
            controller!.stopIncomingRingtone();
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
            if (onRejectCallApi != null) {
              try {
                await onRejectCallApi?.call(event.rideId);
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('[AGORA_SIGNAL] onRejectCallApi failed: $e');
                }
              }
            }
            // Reject already notified peer. Avoid sending end again.
            await controller.endCall(notifyRemote: false);
            // [_callStateWorker] pops the call route when state becomes ended.
          },
          onHangUp: () async {
            if (kDebugMode) {
              debugPrint('[AGORA_SIGNAL] incoming hang up ride=${event.rideId}');
            }
            controller!.stopIncomingRingtone();
            await controller.endCall();
            // [_callStateWorker] pops the call route when state becomes ended.
          },
        ),
        fullscreenDialog: true,
      );

      controller.stopIncomingRingtone();
      _detachCallStateListener();
      setActiveController(null);
    } finally {
      _incomingCallUiActive = false;
    }
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
    _incomingCallUiActive = false;
  }
}
