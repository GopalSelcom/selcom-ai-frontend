import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { dev, staging, prod }

class AppConfig {
  static late Environment environment;
  static late String baseUrl;
  static late String socketUrl;
  static late String agoraAppId;
  static late String agoraTokenMode;
  static late String agoraTokenEndpoint;

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
        baseUrl = 'https://api.duka.direct';
        socketUrl = 'wss://socket.duka.direct';
        break;
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
