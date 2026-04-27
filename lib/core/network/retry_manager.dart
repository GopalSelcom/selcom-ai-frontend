import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:get/get.dart';
import 'package:get/get.dart' hide Response;

import '../theme/app_colors.dart';
import 'api_service.dart';
import 'failed_request_queue.dart';
import 'network_connectivity_service.dart';
import '../services/error_reporting/error_reporter.dart';

/// Orchestrates API retry operations and manages popup state
class RetryManager {
  static final RetryManager instance = RetryManager._();

  RetryManager._();

  final _queue = FailedRequestQueue.instance;
  final _connectivity = NetworkConnectivityService.instance;

  bool _isRetrying = false;
  bool _isPopupShowing = false;
  StreamSubscription<bool>? _connectivitySubscription;

  /// Whether a retry popup is currently showing
  bool get isPopupShowing => _isPopupShowing;

  /// Whether retry is currently in progress
  bool get isRetrying => _isRetrying;

  /// Initialize the retry manager and setup auto-retry
  void initialize() {
    _setupAutoRetry();
    developer.log("🔄 RetryManager initialized", name: 'RetryManager');
  }

  /// Setup auto-retry when connection is restored
  void _setupAutoRetry() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = _connectivity.connectivityStream.listen((
      isOnline,
    ) {
      if (isOnline && _queue.isNotEmpty) {
        developer.log(
          "🌐 Connection restored, auto-retrying ${_queue.size} requests",
          name: 'RetryManager',
        );

        // Wait 1 second before retrying (debounce)
        Future.delayed(const Duration(seconds: 1), () {
          retryAll();
        });
      }
    });
  }

  /// Show retry popup using GetX dialog
  Future<void> showRetryPopup() async {
    if (_isPopupShowing) {
      developer.log("⚠️ Popup already showing, skipping", name: 'RetryManager');
      return;
    }

    _isPopupShowing = true;
    developer.log(
      "📱 Showing retry popup for ${_queue.size} queued requests",
      name: 'RetryManager',
    );

    await Get.dialog(
      Dialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.errorBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.connectionError.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "We couldn't complete your request. Please try again.",
                style: TextStyle(fontSize: 15, color: AppColors.textBody),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.back();
                    retryAll();
                  },
                  child: Text(AppStrings.retry.tr),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    _isPopupShowing = false;
  }

  /// Dismiss popup if showing
  void dismissPopup() {
    if (_isPopupShowing) {
      _isPopupShowing = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  /// Retry all queued requests in batches
  Future<void> retryAll() async {
    if (_isRetrying) {
      developer.log(
        "⚠️ Retry already in progress, skipping",
        name: 'RetryManager',
      );
      return;
    }

    final requests = _queue.getAll();
    if (requests.isEmpty) {
      developer.log("ℹ️ No requests to retry", name: 'RetryManager');
      dismissPopup();
      return;
    }

    _isRetrying = true;
    developer.log(
      "🔄 Starting batch retry for ${requests.length} requests",
      name: 'RetryManager',
    );

    const batchSize = 5;
    int successCount = 0;
    int failureCount = 0;

    for (int i = 0; i < requests.length; i += batchSize) {
      final batch = requests.skip(i).take(batchSize).toList();
      final results = await _retryBatch(batch);

      successCount += results['success'] as int;
      failureCount += results['failure'] as int;

      // Delay between batches to avoid overwhelming server
      if (i + batchSize < requests.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    _isRetrying = false;

    developer.log(
      "✅ Retry completed: $successCount succeeded, $failureCount failed",
      name: 'RetryManager',
    );

    // Dismiss popup if all succeeded
    if (failureCount == 0) {
      dismissPopup();
    } else {
      // If some failed, show popup again
      developer.log(
        "⚠️ $failureCount requests still failed, showing popup again",
        name: 'RetryManager',
      );
      showRetryPopup();
    }
  }

  /// Retry a batch of requests
  Future<Map<String, int>> _retryBatch(List<FailedRequest> batch) async {
    int successCount = 0;
    int failureCount = 0;

    await Future.wait(
      batch.map((failedRequest) async {
        try {
          developer.log(
            "🔄 Retrying: ${failedRequest.request.endpoint}",
            name: 'RetryManager',
          );

          // Create a modified request that won't be queued if it fails again
          final retryRequest = ApiRequest(
            endpoint: failedRequest.request.endpoint,
            method: failedRequest.request.method,
            version: failedRequest.request.version,
            route: failedRequest.request.route,
            body: failedRequest.request.body,
            customBaseUrl: failedRequest.request.customBaseUrl,
            queryParams: failedRequest.request.queryParams,
            headers: failedRequest.request.headers,
            showLoader: failedRequest.request.showLoader,
            errorPresentationType: ErrorPresentationType.none,
            skipAuthInterceptor: failedRequest.request.skipAuthInterceptor,
            multipartFiles: failedRequest.request.multipartFiles,
            shouldQueue: false, // DON'T queue again if it fails
          );

          // Call ApiService again
          final response = await ApiService().call(request: retryRequest);

          // Check if request was successful
          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            // Success - complete the original completer
            if (!failedRequest.completer.isCompleted) {
              failedRequest.completer.complete(response);
            }

            // Remove from queue
            _queue.remove(failedRequest.id);
            successCount++;

            developer.log(
              "✅ Retry succeeded: ${failedRequest.request.endpoint}",
              name: 'RetryManager',
            );
          } else {
            // Failed - keep in queue
            failureCount++;
            developer.log(
              "❌ Retry failed (${response.statusCode}): ${failedRequest.request.endpoint}",
              name: 'RetryManager',
            );
          }
        } catch (e, stackTrace) {
          ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
          // Error during retry - keep in queue
          failureCount++;
          developer.log(
            "❌ Retry error: ${failedRequest.request.endpoint} - $e",
            name: 'RetryManager',
          );
        }
      }),
    );

    return {'success': successCount, 'failure': failureCount};
  }

  /// Dispose and cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _queue.clear();
    dismissPopup();
    developer.log("🔄 RetryManager disposed", name: 'RetryManager');
  }
}
