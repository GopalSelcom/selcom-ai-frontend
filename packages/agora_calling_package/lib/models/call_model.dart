import 'package:flutter/foundation.dart';

/// Where the local user sits in this call.
enum CallRole { caller, callee }

/// All states a call session passes through. UI binds to this.
enum CallState {
  /// No call in progress.
  idle,

  /// Outgoing — caller has joined the channel; waiting for the peer.
  dialing,

  /// Incoming — callee is being shown the CallKit / incoming UI.
  ringing,

  /// Token fetched, joining channel.
  connecting,

  /// Both sides in the channel, audio flowing.
  connected,

  /// Call has terminated. Inspect [CallEndReason].
  ended,

  /// Unrecoverable error. Inspect `errorMessage`.
  error,
}

/// Why a call ended.
enum CallEndReason {
  localHangup,
  remoteHangup,
  remoteCancelled,
  unanswered,
  remoteOffline,
  disconnected,
  rejectedByLocal,
  error,
}

/// Backend mint-endpoint response.
///
/// Both rider and driver mint endpoints return the same shape:
/// `{ app_id, channel, token, uid, expires_at }`.
@immutable
class TokenMintResponse {
  const TokenMintResponse({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.expiresAt,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final DateTime expiresAt;

  factory TokenMintResponse.fromJson(Map<String, dynamic> j) {
    return TokenMintResponse(
      appId: (j['app_id'] ?? '').toString(),
      channel: (j['channel'] ?? '').toString(),
      token: (j['token'] ?? '').toString(),
      uid: (j['uid'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse((j['expires_at'] ?? '').toString())
              ?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(hours: 24)),
    );
  }
}

/// In-memory session model. Keyed by `rideId` (the backend has no separate
/// `call_id` — `rideId` is the call identifier).
@immutable
class CallModel {
  const CallModel({
    required this.rideId,
    required this.role,
    required this.peerDisplayName,
    this.appId,
    this.channel,
    this.token,
    this.uid,
    this.tokenExpiresAt,
    this.callerRole,
    this.peerAvatarUrl,
    this.startedAt,
    this.endedAt,
  });

  /// Stable backend identifier for the call session.
  final String rideId;

  /// Whether the local user is the caller or callee in this session.
  final CallRole role;

  /// Display label shown in the call UI (e.g. "John", "Your Driver").
  final String peerDisplayName;

  /// Optional avatar of the peer.
  final String? peerAvatarUrl;

  /// Caller's role as advertised in the push payload (`'rider'` | `'driver'`).
  /// Set on incoming sessions.
  final String? callerRole;

  /// Filled once the mint endpoint returns.
  final String? appId;
  final String? channel;
  final String? token;
  final int? uid;
  final DateTime? tokenExpiresAt;

  final DateTime? startedAt;
  final DateTime? endedAt;

  CallModel copyWith({
    String? appId,
    String? channel,
    String? token,
    int? uid,
    DateTime? tokenExpiresAt,
    String? peerDisplayName,
    String? peerAvatarUrl,
    String? callerRole,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return CallModel(
      rideId: rideId,
      role: role,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      callerRole: callerRole ?? this.callerRole,
      appId: appId ?? this.appId,
      channel: channel ?? this.channel,
      token: token ?? this.token,
      uid: uid ?? this.uid,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  /// Builds an outgoing-call seed — fields filled in by the controller after
  /// the mint endpoint returns.
  factory CallModel.outgoing({
    required String rideId,
    required String peerDisplayName,
    String? peerAvatarUrl,
  }) {
    return CallModel(
      rideId: rideId,
      role: CallRole.caller,
      peerDisplayName: peerDisplayName,
      peerAvatarUrl: peerAvatarUrl,
      startedAt: DateTime.now().toUtc(),
    );
  }

  /// Builds an incoming-call seed from the FCM/APNs `data` payload. Returns
  /// `null` when `ride_id` is missing — the contract requires it.
  static CallModel? fromIncomingPush({
    required Map<String, dynamic> data,
    required String defaultPeerLabel,
  }) {
    final rideId = (data['ride_id'] ?? data['rideId'])?.toString().trim();
    if (rideId == null || rideId.isEmpty) return null;
    final callerRole =
        (data['caller_role'] ?? data['callerRole'])?.toString().toLowerCase();
    final channelRaw = (data['channel'] ?? data['channelName'])?.toString();
    return CallModel(
      rideId: rideId,
      role: CallRole.callee,
      peerDisplayName: defaultPeerLabel,
      callerRole: callerRole,
      channel: (channelRaw == null || channelRaw.isEmpty) ? null : channelRaw,
      startedAt: DateTime.now().toUtc(),
    );
  }
}
