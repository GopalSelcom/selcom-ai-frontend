// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_callkit_incoming/entities/entities.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:uuid/uuid.dart';
//
// /// Service to handle native CallKit (iOS) and Full-Screen Intent (Android)
// /// using [flutter_callkit_incoming].
// class AgoraCallKitService {
//   AgoraCallKitService._();
//   static final AgoraCallKitService instance = AgoraCallKitService._();
//
//   String? _currentCallUuid;
//
//   /// Callback when a call is accepted via native UI.
//   Future<void> Function(Map<String, dynamic> payload)? onCallAccepted;
//
//   /// Callback when a call is declined via native UI.
//   Future<void> Function(Map<String, dynamic> payload)? onCallDeclined;
//
//   /// Initializes listeners for CallKit events.
//   /// Should be called early in the app lifecycle.
//   void initialize() {
//     FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
//       if (event == null) return;
//
//       switch (event.event) {
//         case Event.actionCallIncoming:
//           if (kDebugMode) debugPrint('[CallKit] Incoming call');
//           break;
//         case Event.actionCallStart:
//           if (kDebugMode) debugPrint('[CallKit] Call started');
//           break;
//         case Event.actionCallAccept:
//           if (kDebugMode) debugPrint('[CallKit] Call accepted');
//           if (onCallAccepted != null) {
//             final body = event.body as Map<String, dynamic>?;
//             final extra = body?['extra'] as Map<String, dynamic>?;
//             if (extra != null) {
//               await onCallAccepted!(extra);
//             }
//           }
//           break;
//         case Event.actionCallDecline:
//           if (kDebugMode) debugPrint('[CallKit] Call declined');
//           _currentCallUuid = null;
//           if (onCallDeclined != null) {
//             final body = event.body as Map<String, dynamic>?;
//             final extra = body?['extra'] as Map<String, dynamic>?;
//             if (extra != null) {
//               await onCallDeclined!(extra);
//             }
//           }
//           break;
//         case Event.actionCallEnded:
//           if (kDebugMode) debugPrint('[CallKit] Call ended');
//           _currentCallUuid = null;
//           break;
//         case Event.actionCallTimeout:
//           if (kDebugMode) debugPrint('[CallKit] Call timeout');
//           _currentCallUuid = null;
//           break;
//         default:
//           break;
//       }
//     });
//   }
//
//   /// Shows the native incoming call UI.
//   Future<void> showIncomingCall({
//     required String rideId,
//     required String callerName,
//     required String handle,
//     Map<String, dynamic>? extra,
//   }) async {
//     // If there's already an active call UI, don't show another one.
//     // This prevents "Multiple Callers" issue.
//     if (_currentCallUuid != null) {
//       if (kDebugMode) {
//         debugPrint('[CallKit] showIncomingCall skipped: Call already active');
//       }
//       return;
//     }
//
//     final uuid = const Uuid().v4();
//     _currentCallUuid = uuid;
//
//     final params = CallKitParams(
//       id: uuid,
//       nameCaller: callerName,
//       appName: 'Selcom Go',
//       avatar: 'https://i.pravatar.cc/100', // Optional: could be dynamic
//       handle: handle,
//       type: 0, // 0: Audio, 1: Video
//       duration: 30000,
//       textAccept: 'Accept',
//       textDecline: 'Decline',
//       missedCallNotification: const NotificationParams(
//         showNotification: true,
//         isShowCallback: true,
//         subtitle: 'Missed call',
//         callbackText: 'Call back',
//       ),
//       extra: <String, dynamic>{
//         'ride_id': rideId,
//         'type': 'incoming_call',
//         ...?extra,
//       },
//       headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
//       android: const AndroidParams(
//         isCustomNotification: true,
//         isShowLogo: false,
//         ringtonePath: 'system_ringtone_default',
//         backgroundColor: '#F3004C',
//         backgroundUrl: 'https://i.pravatar.cc/500',
//         actionColor: '#4CAF50',
//         textColor: '#ffffff',
//       ),
//       ios: const IOSParams(
//         iconName: 'CallKitLogo',
//         handleType: 'generic',
//         supportsVideo: false,
//         maximumCallGroups: 1,
//         maximumCallsPerCallGroup: 1,
//         audioSessionMode: 'default',
//         audioSessionActive: true,
//         audioSessionPreferredSampleRate: 44100.0,
//         audioSessionPreferredIOBufferDuration: 0.005,
//         supportsDTMF: true,
//         supportsHolding: true,
//         supportsGrouping: false,
//         supportsUngrouping: false,
//         ringtonePath: 'system_ringtone_default',
//       ),
//     );
//
//     await FlutterCallkitIncoming.showCallkitIncoming(params);
//   }
//
//   /// Ends the current native call UI.
//   Future<void> endCall(String uuid) async {
//     await FlutterCallkitIncoming.endCall(uuid);
//     if (_currentCallUuid == uuid) {
//       _currentCallUuid = null;
//     }
//   }
//
//   /// Ends all active calls.
//   Future<void> endAllCalls() async {
//     await FlutterCallkitIncoming.endAllCalls();
//     _currentCallUuid = null;
//   }
//
//   /// Returns the current active call UUID if any.
//   String? get currentCallUuid => _currentCallUuid;
// }
