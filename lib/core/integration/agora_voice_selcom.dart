import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../../shared/agora_voice/data/ride_call_http_token_provider.dart';
import '../../shared/agora_voice/data/static_voice_token_provider.dart';
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
        (mode == 'api' && ep.contains('{rideId}'))) {
      return AppConfig.baseUrl.trim().isNotEmpty;
    }
    return AppConfig.agoraAppId.trim().isNotEmpty;
  }

  /// Token provider for rider app (see `brain/docs/AGORA-FRONTEND-GUIDE.md`).
  ///
  /// - `none` / unknown: [StaticVoiceTokenProvider] (tokenless / dev project).
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

    if (mode == 'ride_api' ||
        (mode == 'api' && ep.contains('{rideId}'))) {
      final d = dio ?? _defaultDio();
      final template =
          mode == 'ride_api' ? rideMintPathTemplate : ep;
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

    return StaticVoiceTokenProvider(
      appId: AppConfig.agoraAppId.trim(),
      channel: fallbackChannel,
      uid: fallbackUid,
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
    final storage = StorageService();
    final token =
        (await storage.read(StorageKeys.accessToken)) ??
        (await storage.read(StorageKeys.authorizationToken)) ??
        '';
    if (token.isEmpty) return const {};
    return <String, dynamic>{'Authorization': 'Bearer $token'};
  }
}
