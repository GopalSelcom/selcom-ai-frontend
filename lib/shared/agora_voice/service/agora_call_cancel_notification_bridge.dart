/// Delivers FCM `call_cancelled` payloads to the active ride session.
class AgoraCallCancelNotificationBridge {
  AgoraCallCancelNotificationBridge._();

  static final AgoraCallCancelNotificationBridge instance =
      AgoraCallCancelNotificationBridge._();

  String? _rideId;
  Future<void> Function(Map<String, dynamic> payload)? _onCancelled;

  void register({
    required String rideId,
    required Future<void> Function(Map<String, dynamic> payload) onCancelled,
  }) {
    _rideId = rideId;
    _onCancelled = onCancelled;
  }

  void unregister(String rideId) {
    if (_rideId == rideId) {
      _rideId = null;
      _onCancelled = null;
    }
  }

  Future<bool> deliverIfMatching(Map<String, dynamic> raw) async {
    final type = (raw['type'] ?? '').toString().toLowerCase();
    if (type != 'call_cancelled') return false;
    final rideId = (raw['ride_id'] ?? raw['rideId'])?.toString();
    if (rideId == null || rideId.isEmpty) return false;
    final activeRideId = _rideId;
    final handler = _onCancelled;
    if (activeRideId == null || handler == null || rideId != activeRideId) {
      return false;
    }
    await handler(raw);
    return true;
  }
}
