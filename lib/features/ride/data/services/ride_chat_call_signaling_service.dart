// import 'dart:async';
// import 'dart:convert';
//
// import 'package:flutter/foundation.dart';
//
// import '../../../../core/services/nearby_drivers_socket_service.dart';
// // import '../../../../shared/agora_voice/domain/agora_call_invite_event.dart';
// // import '../../../../shared/agora_voice/domain/agora_call_signaling_service.dart';
//
// class RideChatCallSignalingService implements AgoraCallSignalingService {
//   RideChatCallSignalingService({
//     required this.rideId,
//     required AppSocketService socketService,
//   }) : _socketService = socketService;
//
//   final String rideId;
//   final AppSocketService _socketService;
//
//   final StreamController<AgoraCallInviteEvent> _eventsController =
//       StreamController<AgoraCallInviteEvent>.broadcast();
//   StreamSubscription<Map<String, dynamic>>? _chatSub;
//
//   @override
//   Stream<AgoraCallInviteEvent> get events => _eventsController.stream;
//
//   @override
//   Future<void> start() async {
//     if (kDebugMode) {
//       debugPrint('[CALL_SOCKET] start signaling ride=$rideId');
//     }
//     await _socketService.connect();
//     _socketService.joinRideRoom(rideId: rideId);
//     _chatSub?.cancel();
//     _chatSub = _socketService.chatStream.listen(_handleChatPayload);
//   }
//
//   @override
//   Future<void> sendEvent(AgoraCallInviteEvent event) async {
//     if (kDebugMode) {
//       debugPrint(
//         '[CALL_SOCKET] send type=${event.type.name} '
//         'channel=${event.channelName} ride=${event.rideId}',
//       );
//     }
//     _socketService.sendMessage(
//       rideId: rideId,
//       message: jsonEncode(event.toJson()),
//     );
//   }
//
//   @override
//   Future<void> dispose() async {
//     if (kDebugMode) {
//       debugPrint('[CALL_SOCKET] dispose signaling ride=$rideId');
//     }
//     await _chatSub?.cancel();
//     await _eventsController.close();
//   }
//
//   void _handleChatPayload(Map<String, dynamic> payload) {
//     final payloadRideId =
//         (payload['ride_id'] ?? payload['rideId'])?.toString().trim() ?? '';
//     if (payloadRideId != rideId) {
//       if (kDebugMode) {
//         debugPrint(
//           '[CALL_SOCKET] skip payload ride=$payloadRideId expected=$rideId',
//         );
//       }
//       return;
//     }
//     final messageRaw = payload['message']?.toString().trim() ?? '';
//     if (messageRaw.isEmpty) return;
//
//     Map<String, dynamic>? map;
//     try {
//       final decoded = jsonDecode(messageRaw);
//       if (decoded is Map<String, dynamic>) {
//         map = decoded;
//       } else if (decoded is Map) {
//         map = Map<String, dynamic>.from(decoded);
//       }
//     } catch (_) {
//       map = null;
//     }
//     if (map == null) {
//       if (kDebugMode) {
//         debugPrint('[CALL_SOCKET] skip non-json chat message');
//       }
//       return;
//     }
//     final event = AgoraCallInviteEvent.fromJson(map);
//     if (event == null) {
//       if (kDebugMode) {
//         debugPrint('[CALL_SOCKET] skip non-call payload');
//       }
//       return;
//     }
//     if (kDebugMode) {
//       debugPrint(
//         '[CALL_SOCKET] receive type=${event.type.name} '
//         'channel=${event.channelName} ride=${event.rideId}',
//       );
//     }
//     _eventsController.add(event);
//   }
// }
