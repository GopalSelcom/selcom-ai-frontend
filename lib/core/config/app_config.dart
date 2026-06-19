import '../env/env.dart';

/// App runtime environment (which host set from [Env] to use).
enum Environment { dev, staging, prod }

/// Runtime URLs and keys. Initialized once in main via [init].
///
/// Source: `.env` → [Env] (generated) → this class.
class AppConfig {
  static late Environment environment;
  static late String baseUrl;
  static late String socketBaseUrl;
  static late String errorReportHost;
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
  static bool ridePaymentBypass = true;

  /// In-memory toggle only (not persisted, not env-derived).
  ///
  /// `true` → `go_simulate_selcom_pesa_top_up` (dev/staging); skips USSD / app handoff.
  /// `false` → real `go_send_transfer_request_selcom_pesa` + status polling.
  static bool selcomPesaBypass = false;

  static void init({required Environment env}) {
    environment = env;

    // Third-party keys (same across environments unless overridden in .env).
    agoraAppId = Env.agoraAppId.trim();
    agoraTokenMode = Env.agoraTokenMode.trim().toLowerCase();
    agoraTokenEndpoint = Env.agoraTokenEndpoint.trim();

    final apiHost = _apiHostFor(env);
    socketBaseUrl = _socketBaseUrlFor(env);
    errorReportHost = _errorReportHostFor(env);

    // baseUrl: dev/staging append `/api`; prod uses host as-is (legacy contract).
    switch (env) {
      case Environment.dev:
      case Environment.staging:
        baseUrl = '$apiHost/api';
        break;
      case Environment.prod:
        ridePaymentBypass = false;
        selcomPesaBypass = false;
        baseUrl = apiHost;
        break;
    }

    selcomPesaDeepLinkHost = Env.selcomPesaDeepLinkHost.trim();
    if (selcomPesaDeepLinkHost.isEmpty) {
      selcomPesaDeepLinkHost = selcomPesaDeepLinkHostDefault;
    }
  }

  /// Host root for [ApiService] (no `/api` suffix).
  static String apiHostFor(Environment env) => _apiHostFor(env);

  static String _apiHostFor(Environment env) {
    switch (env) {
      case Environment.dev:
        final devHost = Env.apiHostDev.trim();
        return _stripTrailingSlash(
          devHost.isEmpty ? Env.apiHostStaging : devHost,
        );
      case Environment.staging:
        return _stripTrailingSlash(Env.apiHostStaging);
      case Environment.prod:
        return _stripTrailingSlash(Env.apiHostProduction);
    }
  }

  static String _socketBaseUrlFor(Environment env) {
    switch (env) {
      case Environment.dev:
        final devSocket = Env.socketBaseUrlDev.trim();
        return _stripTrailingSlash(
          devSocket.isEmpty ? Env.socketBaseUrlStaging : devSocket,
        );
      case Environment.staging:
        return _stripTrailingSlash(Env.socketBaseUrlStaging);
      case Environment.prod:
        return _stripTrailingSlash(Env.socketBaseUrlProduction);
    }
  }

  static String _errorReportHostFor(Environment env) {
    switch (env) {
      case Environment.dev:
      case Environment.staging:
        return _stripTrailingSlash(Env.errorReportHostStaging);
      case Environment.prod:
        return _stripTrailingSlash(Env.errorReportHostProduction);
    }
  }

  static String _stripTrailingSlash(String value) {
    return value.replaceAll(RegExp(r'/+$'), '');
  }
}
