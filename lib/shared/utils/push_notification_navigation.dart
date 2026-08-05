import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/models/responses/rides/ride_details_response.dart';
import '../../core/di/injection_container.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/error_reporting/error_reporter.dart';
import '../../core/services/progress_indicator/loader.dart';
import '../../core/utils/app_logger.dart';
import '../../features/ride/domain/repositories/ride_repository.dart';
import '../../features/ride/presentation/controllers/ride_details_controller.dart';
import '../../features/ride/presentation/screens/ride_details_screen.dart';
import 'app_dialogs.dart';
import 'mid_ride_cancel_navigation.dart';
import 'ride_active_navigation.dart';
import 'ride_status_normalizer.dart';

/// Push tap routing for notification `type` codes:
/// 500 RIDE_STATUS, 501 CHAT, 502 REVIEW, 503 PAYMENT, 504 MARKETING.
abstract final class PushNotificationNavigation {
  static const int rideStatus = 500;
  static const int chat = 501;
  static const int review = 502;
  static const int payment = 503;
  static const int marketing = 504;

  static const String _logTag = 'PushNav';

  static bool _isHandling = false;
  static DateTime? _lastHandledAt;
  static String? _lastHandledKey;
  static Map<String, dynamic>? _coalescedRaw;

  /// Resolves numeric type from FCM data (`type`: `500` or `RIDE_STATUS`).
  static int? parseType(Map<String, dynamic> raw) {
    final rawType = raw['type']?.toString().trim();
    if (rawType == null || rawType.isEmpty) return null;

    final asInt = int.tryParse(rawType);
    if (asInt != null) return asInt;

    switch (rawType.toUpperCase()) {
      case 'RIDE_STATUS':
        return rideStatus;
      case 'CHAT':
        return chat;
      case 'REVIEW':
        return review;
      case 'PAYMENT':
        return payment;
      case 'MARKETING':
        return marketing;
      default:
        return null;
    }
  }

  static String? _rideId(Map<String, dynamic> raw) {
    final id =
        raw['ride_id']?.toString() ??
        raw['rideId']?.toString() ??
        raw['order_id']?.toString();
    final trimmed = id?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _url(Map<String, dynamic> raw) {
    final url =
        raw['url']?.toString() ??
        raw['link']?.toString() ??
        raw['deep_link']?.toString();
    final trimmed = url?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Handles a push / local-notification tap payload.
  static Future<void> handle(Map<String, dynamic> raw) async {
    final type = parseType(raw);
    final rideId = _rideId(raw);
    final url = _url(raw);
    final dedupeKey = '${type ?? 'none'}|${rideId ?? ''}|${url ?? ''}';
    final rawType = raw['type']?.toString().trim() ?? '';

    // Ignore silent tracking updates (not user-tappable routing types).
    if (rawType.toUpperCase() == 'LIVE_TRACKING') {
      AppLogger.d('Push nav skip LIVE_TRACKING update', tag: _logTag);
      return;
    }

    if (_isHandling) {
      // Keep the latest tap; run it when the current open finishes.
      _coalescedRaw = Map<String, dynamic>.from(raw);
      AppLogger.w(
        'Push nav coalesced (in-flight) key=$dedupeKey',
        tag: _logTag,
      );
      return;
    }

    // Only skip if we *successfully* opened the same destination moments ago.
    final now = DateTime.now();
    final lastAt = _lastHandledAt;
    if (lastAt != null &&
        _lastHandledKey == dedupeKey &&
        now.difference(lastAt) < const Duration(seconds: 2)) {
      AppLogger.w(
        'Push nav ignored (recent success) key=$dedupeKey',
        tag: _logTag,
      );
      return;
    }

    _isHandling = true;
    AppLogger.i(
      'Push tap — type=$type rideId=$rideId hasUrl=${url != null} '
      'rawType=$rawType',
      tag: _logTag,
    );

    var opened = false;
    try {
      // Legacy fallback only when `type` key is absent (not for LIVE_TRACKING etc.).
      final resolvedType = type ??
          ((rawType.isEmpty && rideId != null) ? rideStatus : null);

      switch (resolvedType) {
        case rideStatus:
          opened = await _openRideStatus(rideId);
        case chat:
          opened = await _openChat(rideId);
        case review:
          opened = await _openReview(rideId);
        case payment:
          opened = await _openPayment(rideId);
        case marketing:
          opened = await _openMarketing(url);
        default:
          AppLogger.w(
            'Unhandled push type=$rawType — opening home',
            tag: _logTag,
          );
          opened = await _openHome();
      }
      if (opened) {
        _lastHandledAt = DateTime.now();
        _lastHandledKey = dedupeKey;
      }
    } finally {
      _isHandling = false;
      final next = _coalescedRaw;
      _coalescedRaw = null;
      if (next != null) {
        unawaited(handle(next));
      }
    }
  }

  /// Same rules as My Rides history card tap:
  /// ongoing → live tracking; otherwise → ride details.
  static Future<bool> _openRideStatus(String? rideId) async {
    if (rideId == null) {
      AppLogger.w('RIDE_STATUS missing ride_id — opening home', tag: _logTag);
      return _openHome();
    }

    final details = await _fetchRideDetails(rideId);
    if (details == null) {
      return _openHome();
    }

    return _openOngoingOrRideDetails(details, source: 'RIDE_STATUS');
  }

  /// Chat UI exists only in the pickup-phase sheet (before ride start).
  /// After [ride_started] (or later), match My Rides: ongoing → live tracking,
  /// otherwise → ride details — do not open the chat screen.
  static Future<bool> _openChat(String? rideId) async {
    if (rideId == null) {
      AppLogger.w('CHAT missing ride_id — opening home', tag: _logTag);
      return _openHome();
    }

    final details = await _fetchRideDetails(rideId);
    if (details == null) {
      return _openHome();
    }

    final status = normalizeRideStatusString(details.status);
    if (!isDriverPickupEnRouteStatus(status)) {
      AppLogger.i(
        'CHAT after pickup phase ($status) → ongoing/details',
        tag: _logTag,
      );
      return _openOngoingOrRideDetails(details, source: 'CHAT');
    }

    final driver = details.driverSnapshot;
    final plate =
        (driver?.vehicleRegistrationNumber ?? '').trim().isNotEmpty
        ? driver!.vehicleRegistrationNumber!.trim()
        : (details.vehicleSnapshot?.vehicleName ??
                  details.vehicleSnapshot?.displayName ??
                  '')
              .trim();

    AppLogger.i('CHAT pickup phase ($status) → chat screen', tag: _logTag);
    unawaited(
      Get.toNamed(
        AppRoutes.rideMessage,
        arguments: {
          'rideId': rideId,
          'driverName': (driver?.name ?? '').trim().isNotEmpty
              ? driver!.name!.trim()
              : AppStrings.driver.tr,
          'driverPhone': (driver?.phone ?? '').trim(),
          'driverSubtitle': plate,
          'riderName': 'Rider',
          'initialStatus': status,
        },
      ),
    );
    return true;
  }

  static Future<bool> _openOngoingOrRideDetails(
    RideDetailsRide details, {
    required String source,
  }) async {
    final rideModel = details.toRideModel();
    if (rideNeedsMidRideCancelScreen(rideModel)) {
      final block = rideModel.midRideCancel;
      if (block != null) {
        showMidRideDriverCancelledDialog(rideId: rideModel.id, cancel: block);
        return true;
      }
    }

    if (rideStatusIsOngoingActive(details.status)) {
      AppLogger.i(
        '$source ongoing (${details.status}) → live tracking',
        tag: _logTag,
      );
      navigateToOngoingRide(rideModel, skipInitialRideDetailsFetch: true);
      return true;
    }

    AppLogger.i(
      '$source terminal (${details.status}) → ride details',
      tag: _logTag,
    );
    RideDetailsController.ensureBound(
      ride: details,
      openedFromCompletionFlow: false,
      refreshOnInit: false,
    );
    // Do not await — Get.to completes only when the route is popped.
    unawaited(
      Get.to(
        () => RideDetailsScreen(
          ride: details,
          openedFromCompletionFlow: false,
          refreshOnInit: false,
        ),
      ),
    );
    return true;
  }

  static Future<bool> _openReview(String? rideId) async {
    if (rideId == null) {
      AppLogger.w('REVIEW missing ride_id — opening home', tag: _logTag);
      return _openHome();
    }

    final details = await _fetchRideDetails(rideId);
    if (details == null) {
      return _openHome();
    }

    // Do not open the rating bottom sheet — ride details embeds the review UI.
    return _openOngoingOrRideDetails(details, source: 'REVIEW');
  }

  static Future<bool> _openPayment(String? rideId) async {
    // Table: ride_id may be null → wallet; with ride_id → ride payment detail.
    if (rideId == null || rideId.isEmpty) {
      AppLogger.i('PAYMENT without ride_id — opening wallet', tag: _logTag);
      unawaited(Get.toNamed(AppRoutes.wallet));
      return true;
    }

    final details = await _fetchRideDetails(rideId);
    if (details == null) {
      return _openHome();
    }

    RideDetailsController.ensureBound(
      ride: details,
      openedFromCompletionFlow: false,
      refreshOnInit: false,
    );
    unawaited(
      Get.to(
        () => RideDetailsScreen(
          ride: details,
          openedFromCompletionFlow: false,
          refreshOnInit: false,
        ),
      ),
    );
    return true;
  }

  static Future<bool> _openMarketing(String? url) async {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _openHome();
    }

    // In-app named route (e.g. `/wallet`, `/promotions`).
    if (trimmed.startsWith('/')) {
      unawaited(Get.toNamed(trimmed));
      return true;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
        AppLogger.w('Marketing url launch failed: $e', tag: _logTag);
      }
    }

    return _openHome();
  }

  static Future<bool> _openHome() async {
    if (Get.currentRoute == AppRoutes.home) return true;
    await AppDialogs.navigateHomeReplacingStack();
    return true;
  }

  static Future<RideDetailsRide?> _fetchRideDetails(String rideId) async {
    Loader.instance.show();
    try {
      final result = await sl<RideRepository>().getRideDetails(rideId);
      return result.fold((failure) {
        AppLogger.e(
          'Failed to fetch ride $rideId: ${failure.message}',
          tag: _logTag,
        );
        return null;
      }, (details) => details);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e('Exception fetching ride $rideId: $e', tag: _logTag);
      return null;
    } finally {
      Loader.instance.hide();
    }
  }
}
