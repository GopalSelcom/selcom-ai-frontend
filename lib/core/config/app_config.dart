import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { dev, staging, prod }

class AppConfig {
  static late Environment environment;
  static late String baseUrl;
  static late String socketUrl;
  static late String agoraAppId;

  /// `none` (default) | `ride_api` POST mint per brain guide | `api` GET legacy **or** POST if endpoint contains `{rideId}`.
  static late String agoraTokenMode;
  static late String agoraTokenEndpoint;

  /// Host for Selcom Pesa pcode handoff (`https://{host}/pcode/{shortCode}`).
  /// Decoupled from API environment — production Selcom Pesa uses `spd.selcommobile.com`.
  static late String selcomPesaDeepLinkHost;
  static const String selcomPesaDeepLinkHostDefault = 'spd.selcommobile.com';
  static const String selcomPesaDownloadUrl = 'https://get.selcompesa.app/';

  /// In-memory toggle only (not persisted, not env-derived).
  ///
  /// `true` → `go/validate_ride_payment` + `go/dev/payment_callback` + unsuffixed ride paths.
  /// `false` → `go/validate_ride_payment_new` + socket payment block + `_new` ride paths.
  static bool ridePaymentBypass = false;

  static const String _agoraAppIdDefine = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '',
  );
  static const String _agoraTokenModeDefine = String.fromEnvironment(
    'AGORA_TOKEN_MODE',
    defaultValue: 'none',
  );
  static const String _agoraTokenEndpointDefine = String.fromEnvironment(
    'AGORA_TOKEN_ENDPOINT',
    defaultValue: '',
  );
  static const String _selcomPesaDeepLinkHostDefine = String.fromEnvironment(
    'SELCOM_PESA_DEEPLINK_HOST',
    defaultValue: '',
  );

  static void init({required Environment env}) {
    environment = env;
    agoraAppId = _readEnv('AGORA_APP_ID', _agoraAppIdDefine).trim();
    agoraTokenMode = _readEnv(
      'AGORA_TOKEN_MODE',
      _agoraTokenModeDefine,
    ).trim().toLowerCase();
    agoraTokenEndpoint = _readEnv(
      'AGORA_TOKEN_ENDPOINT',
      _agoraTokenEndpointDefine,
    ).trim();
    switch (env) {
      case Environment.dev:
        baseUrl = 'https://dukastaging.selcom.dev:7443/api';
        socketUrl = 'ws://localhost:5010';
        break;
      case Environment.staging:
        baseUrl = 'https://dukastaging.selcom.dev:7443/api/';
        socketUrl = 'wss://staging-socket.duka.direct';
        break;
      case Environment.prod:
        ridePaymentBypass = false;
        baseUrl = 'https://api.duka.direct';
        socketUrl = 'wss://socket.duka.direct';
        break;
    }

    selcomPesaDeepLinkHost = _readEnv(
      'SELCOM_PESA_DEEPLINK_HOST',
      _selcomPesaDeepLinkHostDefine,
    ).trim();
    if (selcomPesaDeepLinkHost.isEmpty) {
      selcomPesaDeepLinkHost = selcomPesaDeepLinkHostDefault;
    }
  }

  static String _readEnv(String key, String fallback) {
    final dotEnvValue = dotenv.env[key];
    if (dotEnvValue != null && dotEnvValue.trim().isNotEmpty) {
      return dotEnvValue;
    }
    return fallback;
  }
}
