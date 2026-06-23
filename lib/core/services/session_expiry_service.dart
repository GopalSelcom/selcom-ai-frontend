import 'package:get/get.dart';

import '../../features/home/presentation/controllers/home_controller.dart';
import '../network/api_service.dart';

/// Central handling when the backend invalidates the session (e.g. login on another device).
class SessionExpiryService {
  SessionExpiryService._();

  static bool _isHandling = false;
  static bool _userLoggedOut = false;

  /// True when authenticated background work (e.g. active-ride poll) must stop.
  static bool get isHandling =>
      _userLoggedOut ||
      _isHandling ||
      AuthInterceptor.isLoggingOutDueToAuthFailure;

  /// Resets coordinator state after a successful login (new session).
  static void resetOnLogin() {
    _isHandling = false;
    _userLoggedOut = false;
    AuthInterceptor.isLoggingOutDueToAuthFailure = false;
  }

  /// Manual logout from profile/settings — stop polling, no session dialog.
  static void teardownOnLogout() {
    _userLoggedOut = true;
    _stopActiveRidePolling();
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

  /// Stops background work and shows the session-expired login prompt once.
  static Future<void> handleSessionExpired() async {
    if (isHandling) return;
    _isHandling = true;
    _userLoggedOut = true;

    _stopActiveRidePolling();

    ApiService().showLogoutPopup();
  }

  static void _stopActiveRidePolling() {
    if (!Get.isRegistered<HomeController>()) return;
    Get.find<HomeController>().onSessionExpired();
  }
}
