import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import 'api_service.dart';
import 'failed_request_queue.dart';
import 'network_connectivity_service.dart';

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
    debugPrint("🔄 RetryManager initialized");
  }

  /// Setup auto-retry when connection is restored
  void _setupAutoRetry() {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = _connectivity.connectivityStream.listen((
      isOnline,
    ) {
      if (isOnline && _queue.isNotEmpty) {
        debugPrint(
          "🌐 Connection restored, auto-retrying ${_queue.size} requests",
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
      debugPrint("⚠️ Popup already showing, skipping");
      return;
    }

    _isPopupShowing = true;
    debugPrint("📱 Showing retry popup for ${_queue.size} queued requests");

    await Get.defaultDialog(
      title: 'Connection Error',
      middleText: "We couldn't complete your request. Please try again.",
      textConfirm: 'Retry',
      barrierDismissible: false,
      onConfirm: () {
        Get.back();
        retryAll();
      },
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
      debugPrint("⚠️ Retry already in progress, skipping");
      return;
    }

    final requests = _queue.getAll();
    if (requests.isEmpty) {
      debugPrint("ℹ️ No requests to retry");
      dismissPopup();
      return;
    }

    _isRetrying = true;
    debugPrint("🔄 Starting batch retry for ${requests.length} requests");

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

    debugPrint(
      "✅ Retry completed: $successCount succeeded, $failureCount failed",
    );

    // Dismiss popup if all succeeded
    if (failureCount == 0) {
      dismissPopup();
    } else {
      // If some failed, show popup again
      debugPrint("⚠️ $failureCount requests still failed, showing popup again");
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
          debugPrint("🔄 Retrying: ${failedRequest.request.endpoint}");

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

            debugPrint(
              "✅ Retry succeeded: ${failedRequest.request.endpoint}",
            );
          } else {
            // Failed - keep in queue
            failureCount++;
            debugPrint(
              "❌ Retry failed (${response.statusCode}): ${failedRequest.request.endpoint}",
            );
          }
        } catch (e) {
          // Error during retry - keep in queue
          failureCount++;
          debugPrint(
            "❌ Retry error: ${failedRequest.request.endpoint} - $e",
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
    debugPrint("🔄 RetryManager disposed");
  }
}
