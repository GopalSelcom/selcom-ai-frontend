import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../network/headers.dart';
import '../../shared/agora_voice/data/ride_call_http_token_provider.dart';
import '../../shared/agora_voice/domain/agora_voice_token_provider.dart';

/// Selcom-specific wiring for the portable `lib/shared/agora_voice/` module.
///
/// Other apps: copy `agora_voice/` and replace this file with your own DI/config.
class AgoraVoiceSelcom {
  AgoraVoiceSelcom._();

  /// Whether in-app calling can be attempted (config sanity).
  static bool canStartCall() {
    final mode = AppConfig.agoraTokenMode.trim().toLowerCase();
    final ep = AppConfig.agoraTokenEndpoint.trim();
    if (mode == 'ride_api' ||
        mode == 'none' ||
        mode.isEmpty ||
        (mode == 'api' && ep.contains('{rideId}'))) {
      return AppConfig.baseUrl.trim().isNotEmpty;
    }
    return mode == 'api' && ep.isNotEmpty;
  }

  /// Token provider for rider app (see `brain/docs/AGORA-FRONTEND-GUIDE.md`).
  ///
  /// - `none` / empty: defaults to rider POST mint (`ride_api`) to avoid static-token fallback.
  /// - `api` + endpoint without `{rideId}`: legacy GET token (channel + uid query).
  /// - `api` + endpoint with `{rideId}` OR `ride_api`: POST mint using [AppConfig.baseUrl].
  static AgoraVoiceTokenProvider buildRiderTokenProvider({
    required String fallbackChannel,
    required int fallbackUid,
    Dio? dio,
  }) {
    return _buildTokenProvider(
      rideMintPathTemplate: '/v4/go/rides/{rideId}/call/token',
      fallbackChannel: fallbackChannel,
      fallbackUid: fallbackUid,
      dio: dio,
    );
  }

  /// Driver / agent app — same as rider but hits `delivery_agent_backend` path from the guide.
  static AgoraVoiceTokenProvider buildAgentDriverTokenProvider({
    required String fallbackChannel,
    required int fallbackUid,
    Dio? dio,
  }) {
    return _buildTokenProvider(
      rideMintPathTemplate: '/v4/agent/go/rides/{rideId}/call/token',
      fallbackChannel: fallbackChannel,
      fallbackUid: fallbackUid,
      dio: dio,
    );
  }

  /// Central provider switch used by rider/driver factories.
  /// Chooses POST ride token API, legacy GET API, or static dev credentials.
  static AgoraVoiceTokenProvider _buildTokenProvider({
    required String rideMintPathTemplate,
    required String fallbackChannel,
    required int fallbackUid,
    Dio? dio,
  }) {
    final mode = AppConfig.agoraTokenMode.trim().toLowerCase();
    final ep = AppConfig.agoraTokenEndpoint.trim();
    if (kDebugMode) {
      debugPrint(
        '[AGORA_CONFIG] mode=$mode endpoint=${ep.isEmpty ? '<empty>' : ep} '
        'baseUrl=${AppConfig.baseUrl}',
      );
    }

    if (mode == 'ride_api' ||
        mode == 'none' ||
        mode.isEmpty ||
        (mode == 'api' && ep.contains('{rideId}'))) {
      final d = dio ?? _defaultDio();
      final template =
          (mode == 'ride_api' || mode == 'none' || mode.isEmpty)
          ? rideMintPathTemplate
          : ep;
      return RideCallHttpTokenProvider(
        dio: d,
        tokenPathBuilder: (rideId) =>
            template.replaceAll('{rideId}', rideId.trim()),
        headersProvider: _bearerHeaders,
      );
    }

    if (mode == 'api' && ep.isNotEmpty) {
      final d = dio ?? _defaultDio();
      return ChannelQueryTokenProvider(
        dio: d,
        endpoint: ep,
        channel: fallbackChannel,
        uid: fallbackUid,
        appId: AppConfig.agoraAppId.trim(),
      );
    }

    throw StateError(
      'Unsupported AGORA_TOKEN_MODE="$mode". '
      'Use ride_api or api.',
    );
  }

  /// Builds a Dio instance suitable for token mint calls.
  static Dio _defaultDio() {
    var base = AppConfig.baseUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  /// Resolves authorization headers from secure storage.
  /// Returns empty map when user token is unavailable.
  static Future<Map<String, dynamic>> _bearerHeaders() async {
    if (kDebugMode) {
      debugPrint('[AGORA_CONFIG] auth header present for token mint');
    }
    return await commonHeaders(accessTokenRequired: true);
  }
}
