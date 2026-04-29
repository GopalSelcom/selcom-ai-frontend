import '../../../core/config/app_config.dart';
import '../data/api_token_provider.dart';
import '../data/dev_null_token_provider.dart';
import '../domain/agora_token_provider.dart';

class AgoraVoiceConfig {
  const AgoraVoiceConfig({
    required this.appId,
    required this.tokenMode,
    required this.tokenEndpoint,
  });

  final String appId;
  final String tokenMode;
  final String tokenEndpoint;

  bool get isValid => appId.isNotEmpty;

  AgoraTokenProvider createTokenProvider() {
    if (tokenMode == 'api' && tokenEndpoint.isNotEmpty) {
      return ApiTokenProvider(endpoint: tokenEndpoint);
    }
    return const DevNullTokenProvider();
  }

  static AgoraVoiceConfig fromAppConfig() {
    return AgoraVoiceConfig(
      appId: AppConfig.agoraAppId,
      tokenMode: AppConfig.agoraTokenMode,
      tokenEndpoint: AppConfig.agoraTokenEndpoint,
    );
  }
}
