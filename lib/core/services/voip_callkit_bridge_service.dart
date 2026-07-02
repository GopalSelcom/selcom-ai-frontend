import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';
import 'storage_service.dart';

/// Bridge for native iOS PushKit/CallKit events delivered via AppDelegate.
///
/// Aligned with `brain/docs/AGORA-FRONTEND-GUIDE.md` § 6.5:
/// - Incoming pushes always include `ride_id` (channel = `ride_<rideId>`).
/// - The VoIP push token is owned by PushKit on iOS and must be relayed to
///   the backend so it can deliver `incoming_call` via APNs VoIP.
class VoipCallkitBridgeService {
  VoipCallkitBridgeService._();
  static final VoipCallkitBridgeService instance = VoipCallkitBridgeService._();

  static const MethodChannel _channel = MethodChannel('com.selcom.go/voip');
  static const String _logTag = 'VOIP_BRIDGE';
  bool _initialized = false;

  String? _voipToken;
  Future<void> Function(String token)? _onVoipTokenChanged;
  void Function(Map<String, dynamic> data)? _onIncomingCall;

  /// Latest known VoIP push token (iOS / PushKit). Empty string when unknown.
  String get voipToken => _voipToken ?? '';

  /// Replays the cached token through the registered handler.
  /// Call after login/session restore so backend PATCH includes auth headers.
  Future<void> syncCachedTokenToBackend() async {
    final cached = _voipToken;
    if (cached == null || cached.isEmpty) return;
    await _safeInvokeTokenHandler(cached);
  }

  /// Registers a host-app callback fired whenever the VoIP token changes.
  /// Called once with the cached token if one is already known.
  void setOnVoipTokenChanged(Future<void> Function(String token)? handler) {
    _onVoipTokenChanged = handler;
    final cached = _voipToken;
    if (handler != null && cached != null && cached.isNotEmpty) {
      unawaited(_safeInvokeTokenHandler(cached));
    }
  }

  /// Registers a host-app sink for native PushKit-delivered incoming calls.
  /// Used to forward into `AgoraCalling.dispatchExternalIncomingCall`.
  void setOnIncomingCall(void Function(Map<String, dynamic> data)? sink) {
    _onIncomingCall = sink;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _voipToken = await StorageService().read(StorageKeys.voipToken);
    final cached = _voipToken;
    AppLogger.d(
      'initialize — cached token '
      '${cached == null || cached.isEmpty ? 'NONE' : 'len=${cached.length}'}',
      tag: _logTag,
    );
    _channel.setMethodCallHandler(_onNativeCall);
    await _consumePendingNativeEvents();
  }

  Future<void> _consumePendingNativeEvents() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.iOS) return;
      final dynamic raw = await _channel.invokeMethod(
        'consumePendingVoipEvents',
      );
      if (raw is! List) return;
      for (final dynamic item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final method = map['method']?.toString();
        final args = map['arguments'];
        if (method == null) continue;
        if (args is Map) {
          await _dispatch(method, Map<String, dynamic>.from(args));
        } else if (args is String && method == 'onVoipToken') {
          await _dispatch(method, {'token': args});
        }
      }
    } catch (e) {
      AppLogger.e('consume pending events failed', tag: _logTag, error: e);
    }
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    final args = call.arguments;
    if (args is Map) {
      await _dispatch(call.method, Map<String, dynamic>.from(args));
    } else if (args is String && call.method == 'onVoipToken') {
      await _dispatch(call.method, {'token': args});
    } else {
      await _dispatch(call.method, const <String, dynamic>{});
    }
    return null;
  }

  Future<void> _dispatch(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'onVoipIncomingCall':
      case 'onIncomingCall':
        AppLogger.d('$method received args=$args', tag: _logTag);
        final normalised = _normalizeIncoming(args);
        if (normalised == null) {
          AppLogger.d('$method dropped — no ride_id in payload', tag: _logTag);
          return;
        }
        final sink = _onIncomingCall;
        if (sink == null) {
          AppLogger.d(
            '$method dropped — no sink registered '
            '(setOnIncomingCall not called yet)',
            tag: _logTag,
          );
          return;
        }
        try {
          sink(normalised);
        } catch (e) {
          AppLogger.e('onIncomingCall sink failed', tag: _logTag, error: e);
        }
        return;
      case 'onVoipToken':
        final token = args['token']?.toString() ?? '';
        if (token.isEmpty) return;
        if (token == _voipToken) return;
        _voipToken = token;
        AppLogger.d('token received len=${token.length}', tag: _logTag);
        try {
          await StorageService().write(StorageKeys.voipToken, token);
        } catch (e) {
          AppLogger.e('persist token failed', tag: _logTag, error: e);
        }
        await _safeInvokeTokenHandler(token);
        break;
      default:
        AppLogger.d('unhandled method=$method', tag: _logTag);
    }
  }

  Future<void> _safeInvokeTokenHandler(String token) async {
    final handler = _onVoipTokenChanged;
    if (handler == null) return;
    try {
      await handler(token);
    } catch (e) {
      AppLogger.e('onVoipTokenChanged handler failed', tag: _logTag, error: e);
    }
  }

  /// Normalizes a native incoming-call payload to the package's expected shape:
  /// `{ type: 'incoming_call', ride_id, channel, caller_role }`. Drops the
  /// payload (returns `null`) when `ride_id` is missing — the contract
  /// requires it on every incoming call.
  Map<String, dynamic>? _normalizeIncoming(Map<String, dynamic> raw) {
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
