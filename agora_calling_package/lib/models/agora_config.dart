import 'package:flutter/foundation.dart';

/// Async header provider for backend calls. Returning headers async lets the
/// host app fetch a fresh access token before each request.
typedef AuthHeadersProvider = Future<Map<String, String>> Function();

/// Optional hook fired when the package receives a fresh iOS VoIP push token
/// (PushKit). Host app can use this for analytics; the package will already
/// have PATCHed the token to the configured `voipTokenPath` before invoking.
typedef VoipTokenHandler = Future<void> Function(String token);

/// Maps an incoming-call push payload's `caller_role` to a user-facing peer
/// name (e.g. rider sees "Your Driver"; driver sees "Your Rider").
typedef PeerNameResolver = String Function(Map<String, dynamic> pushData);

/// Per-host endpoint paths for the calling REST surface.
///
/// Rider app (Selcom Go) — paths under dukadirect_backend:
/// ```
/// CallEndpoints(
///   tokenPath:        (rideId) => '/v4/go/rides/$rideId/call/token',
///   cancelPath:       (rideId) => '/v4/go/rides/$rideId/call/cancel',
///   voipTokenPath:    '/v4/go/user/voip-token',
/// )
/// ```
///
/// Driver app (Delivery Agent) — paths under delivery_agent_backend (cancel
/// path has NO `:rideId` — backend resolves from current task):
/// ```
/// CallEndpoints(
///   tokenPath:        (rideId) => '/v1/app/agent/go/rides/$rideId/call/token',
///   cancelPath:       (_)      => '/v1/app/agent/go/rides/call/cancel',
///   voipTokenPath:    '/v1/app/agent/go/voip-token',
/// )
/// ```
@immutable
class CallEndpoints {
  const CallEndpoints({
    required this.tokenPath,
    required this.cancelPath,
    required this.voipTokenPath,
  });

  /// Returns the path for the token mint endpoint, given the current `rideId`.
  /// Both caller (initiate) and callee (accept) hit the same path.
  final String Function(String rideId) tokenPath;

  /// Returns the path for the cancel endpoint. `rideId` may be ignored by
  /// the host (driver app cancel has no `:rideId` in the URL).
  final String Function(String rideId) cancelPath;

  /// Path for the VoIP push-token registration endpoint (PATCH).
  final String voipTokenPath;
}

/// Runtime configuration for the calling layer. Provided once via
/// `AgoraCalling.init(...)` from the host app's bootstrap.
@immutable
class AgoraCallingConfig {
  const AgoraCallingConfig({
    required this.appId,
    required this.baseUrl,
    required this.getAuthHeaders,
    required this.endpoints,
    required this.localRole,
    this.peerNameResolver,
    this.unansweredTimeout = const Duration(seconds: 35),
    this.callerRingbackAsset = 'assets/sounds/ringback.mp3',
    this.incomingRingtoneAsset = 'assets/sounds/ringtone.mp3',
    this.endTone = 'assets/sounds/call_end.mp3',
    this.androidNotificationIcon = '@mipmap/ic_launcher',
    this.appName = 'Selcom Go',
    this.onVoipTokenChanged,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 20),
  });

  /// Public Agora App ID. The mint endpoint also returns `app_id` in its
  /// response — that one is authoritative; this is the fallback.
  final String appId;

  /// Backend base URL. Endpoint paths are joined to this base.
  final String baseUrl;

  /// Async provider for auth headers (Bearer / access_token / etc.).
  final AuthHeadersProvider getAuthHeaders;

  /// Per-host REST paths (rider vs driver paths differ).
  final CallEndpoints endpoints;

  /// Whether the local user is the rider or the driver. Drives default peer
  /// labels — rider sees "Your Driver", driver sees "Your Rider".
  final CallParticipantRole localRole;

  /// Optional override for resolving the peer's display name from an incoming
  /// `incoming_call` push payload. Default uses `localRole` to label the peer
  /// generically.
  final PeerNameResolver? peerNameResolver;

  /// Caller-side wait time before treating the call as unanswered.
  final Duration unansweredTimeout;

  /// Caller ringback (`...waiting...`) loop asset path.
  final String callerRingbackAsset;

  /// Callee ringtone loop asset path.
  final String incomingRingtoneAsset;

  /// Short tone played on call end. Optional.
  final String endTone;

  /// Android notification icon resource (`@mipmap/ic_launcher` or similar).
  final String androidNotificationIcon;

  /// User-facing app name (used in CallKit / heads-up titles).
  final String appName;

  /// Optional hook fired AFTER the package PATCHes the VoIP token to the
  /// backend's `voipTokenPath`. Useful for analytics / debug.
  final VoipTokenHandler? onVoipTokenChanged;

  /// Dio connect/receive timeouts for the backend client.
  final Duration connectTimeout;
  final Duration receiveTimeout;
}

/// Whether the local app is the rider or the driver. The package never
/// inspects the JWT — the host declares this once in config.
enum CallParticipantRole { rider, driver }
