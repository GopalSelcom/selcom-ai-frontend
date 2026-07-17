import 'package:envied/envied.dart';

part 'env.g.dart';

/// Values from root `.env`, obfuscated into `env.g.dart` by Envied.
///
/// Edit `.env` → run `dart run build_runner build` → [AppConfig.init] in main.
@Envied(path: '.env')
abstract class Env {
  // API hosts (no /api suffix)
  @EnviedField(varName: 'API_HOST_PRODUCTION', obfuscate: true)
  static final String apiHostProduction = _Env.apiHostProduction;

  @EnviedField(varName: 'API_HOST_STAGING', obfuscate: true)
  static final String apiHostStaging = _Env.apiHostStaging;

  @EnviedField(varName: 'API_HOST_DEV', obfuscate: true, defaultValue: '')
  static final String apiHostDev = _Env.apiHostDev;

  // Socket.IO origins (path: /go-socket.io in AppConfig for dev/staging)
  @EnviedField(varName: 'SOCKET_BASE_URL_PRODUCTION', obfuscate: true)
  static final String socketBaseUrlProduction = _Env.socketBaseUrlProduction;

  @EnviedField(varName: 'SOCKET_BASE_URL_STAGING', obfuscate: true)
  static final String socketBaseUrlStaging = _Env.socketBaseUrlStaging;

  @EnviedField(
    varName: 'SOCKET_BASE_URL_DEV',
    obfuscate: true,
    defaultValue: '',
  )
  static final String socketBaseUrlDev = _Env.socketBaseUrlDev;

  // Error report upload hosts
  @EnviedField(varName: 'ERROR_REPORT_HOST_PRODUCTION', obfuscate: true)
  static final String errorReportHostProduction =
      _Env.errorReportHostProduction;

  @EnviedField(varName: 'ERROR_REPORT_HOST_STAGING', obfuscate: true)
  static final String errorReportHostStaging = _Env.errorReportHostStaging;

  // Agora voice
  @EnviedField(varName: 'AGORA_APP_ID', obfuscate: true)
  static final String agoraAppId = _Env.agoraAppId;

  @EnviedField(
    varName: 'AGORA_TOKEN_MODE',
    obfuscate: true,
    defaultValue: 'none',
  )
  static final String agoraTokenMode = _Env.agoraTokenMode;

  @EnviedField(
    varName: 'AGORA_TOKEN_ENDPOINT',
    obfuscate: true,
    defaultValue: '',
  )
  static final String agoraTokenEndpoint = _Env.agoraTokenEndpoint;

  // Selcom Pesa
  @EnviedField(
    varName: 'SELCOM_PESA_DEEPLINK_HOST',
    obfuscate: true,
    defaultValue: 'spd.selcommobile.com',
  )
  static final String selcomPesaDeepLinkHost = _Env.selcomPesaDeepLinkHost;
}
