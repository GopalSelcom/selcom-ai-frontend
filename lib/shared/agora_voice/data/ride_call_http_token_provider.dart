import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/agora_rtc_join_credentials.dart';
import '../domain/agora_voice_token_provider.dart';

typedef AgoraHttpHeadersProvider = Future<Map<String, dynamic>> Function();

/// POST ride call token — matches `AGORA-FRONTEND-GUIDE.md` flow.
///
/// Example path: `/v4/go/rides/<rideId>/call/token` (rider) or
/// `/v4/agent/go/rides/<rideId>/call/token` (driver app).
class RideCallHttpTokenProvider implements AgoraVoiceTokenProvider {
  RideCallHttpTokenProvider({
    required Dio dio,
    required this.tokenPathBuilder,
    this.headersProvider,
    this.max429Retries = 3,
  }) : _dio = dio;

  final Dio _dio;
  final String Function(String rideId) tokenPathBuilder;
  final AgoraHttpHeadersProvider? headersProvider;
  final int max429Retries;

  @override
  Future<AgoraRtcJoinCredentials> fetchCredentials({required String rideId}) async {
    if (rideId.trim().isEmpty) {
      throw StateError('rideId is required to mint an RTC token');
    }
    final path = tokenPathBuilder(rideId.trim());
    final headers = await headersProvider?.call() ?? const <String, dynamic>{};
    if (kDebugMode) {
      final hasAuth = headers.keys.any(
        (k) => k.toLowerCase() == 'authorization' || k.toLowerCase() == 'access_token',
      );
      debugPrint('[AGORA_TOKEN] POST $path ride=$rideId authHeader=$hasAuth');
    }

    final response = await _postWithRateLimitRetry(
      path: path,
      headers: headers,
      rideId: rideId,
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Agora token: expected JSON object body');
    }

    final nested = data['data'];
    final Map<String, dynamic> payload = nested is Map<String, dynamic>
        ? nested
        : nested is Map
        ? Map<String, dynamic>.from(nested)
        : data;

    final creds = AgoraRtcJoinCredentials.fromBackendData(payload);
    if (!creds.isValidForJoin) {
      if (kDebugMode) {
        debugPrint('[AGORA_TOKEN] invalid payload keys=${payload.keys.toList()}');
      }
      throw const FormatException('Agora token: missing app_id/channel');
    }
    if (kDebugMode) {
      debugPrint(
        '[AGORA_TOKEN] minted channel=${creds.channel} uid=${creds.uid} '
        'expiresAt=${creds.expiresAt?.toIso8601String() ?? 'n/a'}',
      );
    }
    return creds;
  }

  Future<Response<dynamic>> _postWithRateLimitRetry({
    required String path,
    required Map<String, dynamic> headers,
    required String rideId,
  }) async {
    DioException? lastRateLimitError;
    for (var attempt = 0; attempt <= max429Retries; attempt++) {
      try {
        return await _dio.post<dynamic>(
          path,
          options: Options(headers: headers),
        );
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if (statusCode != 429) rethrow;
        lastRateLimitError = e;
        if (attempt >= max429Retries) break;

        final retryAfter = _retryAfterDurationFromHeaders(e.response?.headers);
        final fallbackSeconds = math.min(1 << attempt, 8);
        final wait = retryAfter ?? Duration(seconds: fallbackSeconds);
        if (kDebugMode) {
          debugPrint(
            '[AGORA_TOKEN] rate-limited ride=$rideId '
            'attempt=${attempt + 1}/${max429Retries + 1} '
            'waitingMs=${wait.inMilliseconds}',
          );
        }
        await Future<void>.delayed(wait);
      }
    }

    throw DioException(
      requestOptions: lastRateLimitError?.requestOptions ??
          RequestOptions(path: path),
      response: lastRateLimitError?.response,
      type: DioExceptionType.badResponse,
      error:
          'Token mint endpoint rate-limited (429). Please try again in a moment.',
      message:
          'Token mint endpoint rate-limited (429). Please try again in a moment.',
    );
  }

  Duration? _retryAfterDurationFromHeaders(Headers? headers) {
    if (headers == null) return null;
    final raw = headers.value('retry-after')?.trim();
    if (raw == null || raw.isEmpty) return null;
    final seconds = int.tryParse(raw);
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }
    return null;
  }
}

/// Same as POST but some staging backends expose GET with query `channel` + `uid`.
class ChannelQueryTokenProvider implements AgoraVoiceTokenProvider {
  ChannelQueryTokenProvider({
    required Dio dio,
    required this.endpoint,
    required this.channel,
    required this.uid,
    required this.appId,
  }) : _dio = dio;

  final Dio _dio;
  final String endpoint;
  final String channel;
  final int uid;
  final String appId;

  @override
  Future<AgoraRtcJoinCredentials> fetchCredentials({required String rideId}) async {
    if (rideId.trim().isEmpty) {
      throw StateError('rideId is required');
    }
    final response = await _dio.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'channel': channel, 'uid': uid},
    );

    final data = response.data;
    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      }
    }
    if (map == null) {
      throw const FormatException('Agora token: invalid response shape');
    }

    final nested = map['data'];
    final payload = nested is Map<String, dynamic>
        ? nested
        : nested is Map
        ? Map<String, dynamic>.from(nested)
        : map;

    final token = (payload['token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw const FormatException('Agora token: missing token');
    }

    return AgoraRtcJoinCredentials(
      appId: appId,
      channel: channel,
      token: token,
      uid: uid,
    );
  }
}
