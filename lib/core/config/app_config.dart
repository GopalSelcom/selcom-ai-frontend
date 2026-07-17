import '../env/env.dart';
import 'environment.dart';

/// All runtime config from `.env`.
///
/// **Startup:** call [init] once in `main` with [resolveAppEnvironment], then read
/// values anywhere via `AppConfig.*`.
///
/// **API URLs:** only [apiHost] is stored. [ApiService] prepends [apiRouteSegment]
/// when building `/{route}/{apiVersion}/...` paths (prod uses `api`; dev/staging
/// omit it). Callers outside [ApiService] (Agora, WebView) use [versionedApiPath]
/// / [versionedApiUrl] the same way.
class AppConfig {
  AppConfig._();

  // ── Environment ───────────────────────────────────────────────────────────

  /// Active target: `dev` | `staging` | `prod` (from `--dart-define=ENV=...`).
  static late Environment environment;

  // ── API ───────────────────────────────────────────────────────────────────

  /// API host from `.env` (no trailing slash, no `/api` suffix).
  ///
  /// Used as Dio [baseUrl] in [ApiService].
  static late String apiHost;

  /// Single source of truth for the API version segment (e.g. `v4`).
  ///
  /// Used by [ApiRequest] defaults and by [versionedApiPath] / [versionedApiUrl]
  /// for callers outside [ApiService] (Agora, WebView, error reporting).
  static const String apiVersion = 'v4';

  /// Route segment before version: `api` in prod, empty in dev/staging.
  ///
  /// Used as [ApiRequest.route] default in [ApiService].
  static String get apiRouteSegment {
    switch (environment) {
      case Environment.dev:
      case Environment.staging:
        return 'api';
      case Environment.prod:
        return 'api';
    }
  }

  /// Leading path prefix derived from [apiRouteSegment] (`/api` or empty).
  ///
  /// Prefer [versionedApiPath] / [versionedApiUrl] over composing this by hand.
  static String get apiPathPrefix =>
      apiRouteSegment.isEmpty ? '' : '/$apiRouteSegment';

  /// Path after host: `/{apiRouteSegment}/{apiVersion}/{endpoint}` (leading slash).
  static String versionedApiPath(String endpoint) {
    final clean =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    if (apiRouteSegment.isEmpty) {
      return '/$apiVersion/$clean';
    }
    return '/$apiRouteSegment/$apiVersion/$clean';
  }

  /// Absolute URL: `{apiHost}{versionedApiPath}`.
  static String versionedApiUrl(String endpoint) =>
      '$apiHost${versionedApiPath(endpoint)}';

  // ── Socket & error reporting ──────────────────────────────────────────────

  /// Socket.IO origin (path comes from [socketPath]).
  static late String socketBaseUrl;

  /// Socket.IO engine path: `/go-socket.io` in dev/staging; empty in prod
  /// (library default — no custom `.setPath`).
  static String get socketPath {
    switch (environment) {
      case Environment.dev:
      case Environment.staging:
        return '/go-socket.io';
      case Environment.prod:
        return '';
    }
  }

  /// Host for multipart error-report uploads (separate from main API).
  static late String errorReportHost;

  // ── Agora voice ───────────────────────────────────────────────────────────

  static late String agoraAppId;

  /// `none` (default) | `ride_api` | `api`
  static late String agoraTokenMode;
  static late String agoraTokenEndpoint;

  // ── Selcom Pesa ───────────────────────────────────────────────────────────

  /// Deep-link host for pcode handoff: `https://{host}/pcode/{shortCode}`.
  static late String selcomPesaDeepLinkHost;
  static const String selcomPesaDeepLinkHostDefault = 'spd.selcommobile.com';
  static const String selcomPesaDownloadUrl = 'https://get.selcompesa.app/';

  // ── Feature toggles (in-memory, not from `.env`) ──────────────────────────

  /// When true, ride payment endpoints skip the `_new` production suffix.
  static bool ridePaymentBypass = false;

  /// When true, Selcom Pesa top-up skips the real app handoff (QA only).
  static bool selcomPesaBypass = false;

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Loads all values from `.env` ([Env]). Call once before `di.init()`.
  static void init({required Environment env}) {
    environment = env;
    apiHost = _apiHostFor(env);
    socketBaseUrl = _socketBaseUrlFor(env);
    errorReportHost = _errorReportHostFor(env);

    agoraAppId = Env.agoraAppId.trim();
    agoraTokenMode = Env.agoraTokenMode.trim().toLowerCase();
    agoraTokenEndpoint = Env.agoraTokenEndpoint.trim();

    selcomPesaDeepLinkHost = Env.selcomPesaDeepLinkHost.trim();
    if (selcomPesaDeepLinkHost.isEmpty) {
      selcomPesaDeepLinkHost = selcomPesaDeepLinkHostDefault;
    }

    // Production builds must use real payment flows.
    if (env == Environment.prod) {
      ridePaymentBypass = false;
      selcomPesaBypass = false;
    }
  }

  // ── `.env` host resolution ────────────────────────────────────────────────
  static String _apiHostFor(Environment env) {
    switch (env) {
      case Environment.dev:
        // Optional override; falls back to staging host when empty.
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
