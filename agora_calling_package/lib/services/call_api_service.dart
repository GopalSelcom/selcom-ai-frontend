import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/agora_config.dart';
import '../models/call_model.dart';

/// REST client for the call signaling endpoints.
///
/// Aligned with `brain/docs/AGORA-FRONTEND-GUIDE.md` — the real backend
/// surfaces only:
///   • POST  `<tokenPath(rideId)>`     — mint the local user's RTC token
///                                        (caller AND callee hit the same path)
///   • POST  `<cancelPath(rideId)>`    — cancel the outgoing call before answer
///   • PATCH `<voipTokenPath>`         — register the iOS PushKit token
class CallApiService {
  CallApiService({required this.config, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _stripTrailingSlash(config.baseUrl),
              connectTimeout: config.connectTimeout,
              receiveTimeout: config.receiveTimeout,
              headers: const {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) async {
        final headers = await config.getAuthHeaders();
        options.headers.addAll(headers);
        handler.next(options);
      }),
    );
  }

  final AgoraCallingConfig config;
  final Dio _dio;

  /// Mints (or refreshes) the local user's Agora token for a ride.
  ///
  /// Caller flow:  POST tokenPath → join channel.
  /// Callee flow:  POST tokenPath after accept → join channel (backend uses
  ///               this same call as the implicit "accept" signal and pushes
  ///               `call_joined` to the caller).
  /// Refresh flow: same call when `onTokenPrivilegeWillExpire` fires.
  Future<TokenMintResponse> mintToken(String rideId) async {
    final path = config.endpoints.tokenPath(rideId);
    if (kDebugMode) {
      debugPrint('[AGORA_API] POST $path (mintToken rideId=$rideId)');
    }
    try {
      final res = await _dio.post(path);
      if (kDebugMode) {
        debugPrint('[AGORA_API] POST $path -> ${res.statusCode}');
      }
      return TokenMintResponse.fromJson(_unwrapData(res));
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_API] POST $path FAILED status=${e.response?.statusCode} '
            'type=${e.type} body=${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Cancels an outgoing call before the peer joins.
  ///
  /// Per brain doc § 6.2: always best-effort — the local channel must be left
  /// regardless of API outcome (so cancel failures never strand the user).
  Future<void> cancelCall(String rideId) async {
    final path = config.endpoints.cancelPath(rideId);
    if (kDebugMode) {
      debugPrint('[AGORA_API] POST $path (cancelCall rideId=$rideId)');
    }
    try {
      await _dio.post(path);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_API] POST $path FAILED status=${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  /// PATCH the iOS PushKit VoIP token for the local user.
  Future<void> registerVoipToken(String token) async {
    if (token.isEmpty) return;
    final path = config.endpoints.voipTokenPath;
    if (kDebugMode) {
      debugPrint('[AGORA_API] PATCH $path (registerVoipToken '
          'tokenLen=${token.length})');
    }
    try {
      final res = await _dio.patch(
        path,
        data: {'voip_push_token': token},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (kDebugMode) {
        debugPrint('[AGORA_API] PATCH $path -> ${res.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_API] PATCH $path FAILED status=${e.response?.statusCode} '
            'type=${e.type} body=${e.response?.data}');
      }
      rethrow;
    }
  }

  static String _stripTrailingSlash(String url) {
    final t = url.trim();
    if (t.endsWith('/')) return t.substring(0, t.length - 1);
    return t;
  }

  /// Backend success envelope is `{ status_code, message, data: { ... } }`.
  /// Tolerant of bare-data responses too.
  Map<String, dynamic> _unwrapData(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }
}
