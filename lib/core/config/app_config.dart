enum Environment { dev, staging, prod }

class AppConfig {
  static late Environment environment;
  static late String baseUrl;
  static late String socketUrl;

  static void init({required Environment env}) {
    environment = env;
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
}
