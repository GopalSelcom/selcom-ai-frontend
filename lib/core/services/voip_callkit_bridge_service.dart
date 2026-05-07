import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';
import 'storage_service.dart';

/// Bridge for native iOS PushKit/CallKit events delivered via AppDelegate.
///
/// Aligned with the backend voice-calling handoff contract:
/// - Incoming pushes always include `ride_id` and the channel is
///   ride-scoped as `ride_<rideId>`.
/// - The VoIP push token is owned by the platform (PushKit on iOS) and must
///   be relayed to the backend so it can deliver `incoming_call` /
///   `call_cancelled` pushes through the APNs VoIP path.
class VoipCallkitBridgeService {
  VoipCallkitBridgeService._();
  static final VoipCallkitBridgeService instance = VoipCallkitBridgeService._();

  static const MethodChannel _channel = MethodChannel('com.selcom.go/voip');
  bool _initialized = false;

  String? _voipToken;
  Future<void> Function(String token)? _onVoipTokenChanged;

  /// Latest known VoIP push token (iOS / PushKit). Empty string when unknown.
  String get voipToken => _voipToken ?? '';

  /// Registers a host-app callback fired whenever the VoIP token changes.
  ///
  /// Host app should register the token with the backend (e.g.
  /// `PATCH /v1/app/go/voip-token`). Called once with the cached token if one
  /// is already known when [setOnVoipTokenChanged] is invoked.
  void setOnVoipTokenChanged(
    Future<void> Function(String token)? handler,
  ) {
    _onVoipTokenChanged = handler;
    final cached = _voipToken;
    if (handler != null && cached != null && cached.isNotEmpty) {
      unawaited(_safeInvokeTokenHandler(cached));
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _voipToken = await StorageService().read(StorageKeys.voipToken);
    _channel.setMethodCallHandler(_onNativeCall);
    await _consumePendingNativeEvents();
  }

  Future<void> _consumePendingNativeEvents() async {
    try {
      final dynamic raw = await _channel.invokeMethod('consumePendingVoipEvents');
      if (raw is! List) return;
      for (final dynamic item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final method = map['method']?.toString();
        final args = map['arguments'];
        if (method == null || args is! Map) continue;
        await _dispatch(method, Map<String, dynamic>.from(args));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VOIP_BRIDGE] consume pending events failed: $e');
      }
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    final args = call.arguments;
    if (args is Map) {
      await _dispatch(call.method, Map<String, dynamic>.from(args));
    }
    return null;
  }

  Future<void> _dispatch(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'onVoipIncomingCall':
        final raw = _normalizeIncomingRaw(args);
        if (raw == null) return;
        NotificationService().markSystemIncomingActive(raw);
        break;
      case 'onVoipCallAccepted':
        final raw = _normalizeIncomingRaw(args);
        if (raw == null) return;
        await NotificationService().handleSystemIncomingAccepted(raw);
        break;
      case 'onVoipCallCancelled':
        final raw = _normalizeCancelRaw(args);
        if (raw == null) return;
        await NotificationService().handleSystemIncomingCancelled(raw);
        break;
      case 'onVoipToken':
        final token = args['token']?.toString() ?? '';
        if (token.isEmpty) return;
        if (token == _voipToken) return;
        _voipToken = token;
        if (kDebugMode) {
          debugPrint('[VOIP_BRIDGE] token received len=${token.length}');
        }
        try {
          await StorageService().write(StorageKeys.voipToken, token);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[VOIP_BRIDGE] persist token failed: $e');
          }
        }
        await _safeInvokeTokenHandler(token);
        break;
      default:
        if (kDebugMode) {
          debugPrint('[VOIP_BRIDGE] unhandled method=$method');
        }
    }
  }

  Future<void> _safeInvokeTokenHandler(String token) async {
    final handler = _onVoipTokenChanged;
    if (handler == null) return;
    try {
      await handler(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[VOIP_BRIDGE] onVoipTokenChanged handler failed: $e');
      }
    }
  }

  /// Normalizes an incoming-call payload to the backend contract shape.
  /// Returns `null` when `ride_id` is missing — the contract requires it on
  /// every `incoming_call`.
  Map<String, dynamic>? _normalizeIncomingRaw(Map<String, dynamic> raw) {
    final rideId = (raw['ride_id'] ?? raw['rideId'])?.toString().trim() ?? '';
    if (rideId.isEmpty) return null;
    final channel = _resolveChannelForRide(
      rawChannel: (raw['channel'] ?? raw['channel_name'])?.toString(),
      rideId: rideId,
    );
    final callerRole =
        (raw['caller_role'] ?? raw['callerRole'])?.toString().trim() ?? '';
    return <String, dynamic>{
      ...raw,
      'type': 'incoming_call',
      'ride_id': rideId,
      'channel': channel,
      if (callerRole.isNotEmpty) 'caller_role': callerRole.toLowerCase(),
    };
  }

  /// Normalizes a `call_cancelled` payload. Returns `null` when `ride_id` is
  /// missing — required by the contract.
  Map<String, dynamic>? _normalizeCancelRaw(Map<String, dynamic> raw) {
    final rideId = (raw['ride_id'] ?? raw['rideId'])?.toString().trim() ?? '';
    if (rideId.isEmpty) return null;
    return <String, dynamic>{
      ...raw,
      'type': 'call_cancelled',
      'ride_id': rideId,
    };
  }

  /// Channel naming must be deterministic and identical for both users:
  /// `channel = ride_<rideId>` (sanitized).
  String _resolveChannelForRide({
    required String? rawChannel,
    required String rideId,
  }) {
    final trimmed = rawChannel?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    final sanitized = rideId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return sanitized.isEmpty ? 'ride_unknown' : 'ride_$sanitized';
  }
}
