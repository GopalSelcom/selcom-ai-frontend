import 'package:get/get.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/ride/presentation/controllers/driver_accepted_controller.dart';
import '../../features/wallet/presentation/utils/wallet_session.dart';
import '../di/injection_container.dart' as di;
import '../network/api_service.dart';
import 'nearby_drivers_socket_service.dart';
import 'session_auth_service.dart';
import 'storage_service.dart';

/// Central handling when the backend invalidates the session
/// (for example: revoked token, login on another device, expired auth state).
///
/// This service is the single coordinator for the "session expired" UX:
/// - stop authenticated background work
/// - clear local auth/session state once
/// - show one non-duplicated re-login dialog
/// - keep guards active until a fresh login succeeds
class SessionExpiryService {
  SessionExpiryService._();

  static bool _isHandling = false;
  static bool _userLoggedOut = false;
  static bool _localSessionCleared = false;
  static bool _sessionExpiredDialogShown = false;

  /// True when authenticated background work must stop immediately.
  ///
  /// Controllers and interceptors use this to avoid:
  /// - starting new authenticated requests
  /// - reopening the same dialog from in-flight failures
  /// - navigating back into authenticated screens during teardown
  static bool get isHandling =>
      _userLoggedOut ||
      _isHandling ||
      AuthInterceptor.isLoggingOutDueToAuthFailure;

  /// Marks the session-expired dialog as visible exactly once.
  ///
  /// We keep this separate from `Get.isDialogOpen` because the product rule is
  /// about this specific dialog, not every modal in the app.
  static bool tryMarkSessionExpiredDialogShown() {
    if (_sessionExpiredDialogShown) return false;
    _sessionExpiredDialogShown = true;
    return true;
  }

  /// Resets coordinator state after a successful login (new session).
  ///
  /// Do not call from the session-expired dialog — flags must stay set until
  /// auth completes or a second prompt can appear on the login screen.
  static void resetOnLogin() {
    _isHandling = false;
    _userLoggedOut = false;
    _localSessionCleared = false;
    _sessionExpiredDialogShown = false;
    AuthInterceptor.isLoggingOutDueToAuthFailure = false;
  }

  /// Manual logout from profile/settings.
  ///
  /// This path does not show the session-expired dialog; it only stops
  /// authenticated work and lets the logout flow perform its own navigation.
  static void teardownOnLogout() {
    _userLoggedOut = true;
    _stopAllBackgroundWork();
  }

  /// Clears all local session/auth state once per expired-session cycle.
  ///
  /// Aligns with profile logout cache/sign-out (wallet teardown, Firebase,
  /// Hive, in-memory JWT) but **does not** POST backend `logout` — the server
  /// session is already invalid when the dialog is shown.
  static Future<void> clearLocalSessionForReLogin() async {
    if (_localSessionCleared) return;
    _localSessionCleared = true;

    // Wallet UI/cache first so observers cannot flash the previous user.
    WalletSession.teardownOnLogout();

    // Best-effort Firebase sign-out for Google/Apple/Facebook sessions.
    final firebaseResult = await di.sl<AuthRepository>().signOutFirebase();
    firebaseResult.fold((_) {}, (_) {});

    await StorageService().deleteAll();
    SessionAuthService.instance.clearInMemorySession();
  }

  static bool isSessionExpired({int? httpStatus, Map<String, dynamic>? body}) {
    if (httpStatus == 405) return true;

    if (body == null || body.isEmpty) return false;

    final envelopeStatus = body['status_code'];
    final envelopeCode = envelopeStatus is num
        ? envelopeStatus.toInt()
        : int.tryParse('$envelopeStatus');
    if (envelopeCode == 405) return true;

    final message = (body['message'] ?? '').toString().toLowerCase();
    if (message.contains('session expired') ||
        message.contains('login again')) {
      return true;
    }

    final errorCode = body['error_code']?.toString();
    switch (errorCode) {
      case 'AUTH_NO_TOKEN':
      case 'AUTH_INVALID_TOKEN':
      case 'AUTH_SESSION_REVOKED':
      case 'AUTH_TOKEN_EXPIRED':
        return true;
      default:
        return false;
    }
  }

  static bool isSessionExpiredMessage(String? message) {
    final normalized = (message ?? '').toLowerCase();
    return normalized.contains('session expired') ||
        normalized.contains('login again');
  }

  /// Main expired-session entry point used by API/auth failure handling.
  ///
  /// Order matters here:
  /// 1. mark teardown in progress
  /// 2. stop active authenticated work
  /// 3. clear local session once
  /// 4. show one login dialog
  ///
  /// The dialog stays on the current route until the user taps **Login**.
  /// Splash and interceptors use the guard flags to avoid racing back into Home.
  static Future<void> handleSessionExpired() async {
    if (_isHandling) return;
    _isHandling = true;
    _userLoggedOut = true;

    _stopAllBackgroundWork();
    SessionAuthService.instance.clearInMemorySession();
    await clearLocalSessionForReLogin();

    ApiService().showLogoutPopup();
  }

  /// User acknowledged the dialog and chose to re-login.
  ///
  /// Keeps [isHandling] / interceptor flags set so in-flight 401s cannot reopen
  /// the dialog on the login screen. [resetOnLogin] runs only after auth succeeds.
  static void acknowledgeExpiredSessionForReLogin() {
    _isHandling = true;
    _userLoggedOut = true;
    AuthInterceptor.isLoggingOutDueToAuthFailure = true;
  }

  static void _stopAllBackgroundWork() {
    // Current scope intentionally stops only auth-sensitive background work
    // that is known to outlive the screen:
    // - home active-ride polling
    // - driver-accepted fallback polling
    // - socket reconnect / ride socket activity
    // - in-flight REST requests
    //
    // Payment top-up polling remains owned by its feature controllers and is
    // intentionally not forced down from here.
    _stopActiveRidePolling();
    _stopDriverAcceptedPolling();
    AppSocketService().disconnect();
    ApiService().cancelAllRequests();
  }

  static void _stopActiveRidePolling() {
    if (!Get.isRegistered<HomeController>()) return;
    Get.find<HomeController>().onSessionExpired();
  }

  static void _stopDriverAcceptedPolling() {
    if (!Get.isRegistered<DriverAcceptedController>()) return;
    Get.find<DriverAcceptedController>().onSessionExpired();
  }
}
