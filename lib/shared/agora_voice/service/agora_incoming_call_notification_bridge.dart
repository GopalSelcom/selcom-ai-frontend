import '../domain/agora_incoming_call_signal.dart';

/// Delivers FCM `incoming_call` payloads to the active [DriverAccepted] session
/// when the user is already on the live ride screen for that [rideId].
///
/// Registered when call signaling is ready; cleared when the controller disposes.
class AgoraIncomingCallNotificationBridge {
  AgoraIncomingCallNotificationBridge._();
  static final AgoraIncomingCallNotificationBridge instance =
      AgoraIncomingCallNotificationBridge._();

  String? _rideId;
  Future<void> Function(Map<String, dynamic> payload)? _onIncoming;

  /// Called when [rideId] matches and incoming-call UI can be shown.
  void register({
    required String rideId,
    required Future<void> Function(Map<String, dynamic> payload) onIncoming,
  }) {
    _rideId = rideId;
    _onIncoming = onIncoming;
  }

  void unregister(String rideId) {
    if (_rideId == rideId) {
      _rideId = null;
      _onIncoming = null;
    }
  }

  /// Returns true if the payload was routed to the active ride session.
  Future<bool> deliverIfMatching(Map<String, dynamic> raw) async {
    final signal = AgoraIncomingCallSignal.fromMap(raw);
    if (signal == null) return false;
    final activeRide = _rideId;
    final handler = _onIncoming;
    if (activeRide == null ||
        handler == null ||
        signal.rideId != activeRide) {
      return false;
    }
    await handler(raw);
    return true;
  }
}
