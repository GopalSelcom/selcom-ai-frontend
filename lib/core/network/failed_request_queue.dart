import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../localization/app_strings.dart';
import 'api_service.dart';

/// Represents a failed API request waiting for retry
class FailedRequest {
  final String id;
  final ApiRequest request;
  final Completer<Response> completer;
  final DateTime timestamp;
  final String requestHash;

  FailedRequest({
    required this.id,
    required this.request,
    required this.completer,
    required this.timestamp,
    required this.requestHash,
  });
}

/// Manages queue of failed API requests with deduplication
class FailedRequestQueue {
  static final FailedRequestQueue instance = FailedRequestQueue._();

  FailedRequestQueue._();

  final List<FailedRequest> _queue = [];
  static const int _maxQueueSize = 100;

  /// Get all queued requests
  List<FailedRequest> getAll() => List.unmodifiable(_queue);

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue is not empty
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Get queue size
  int get size => _queue.length;

  /// Add a failed request to the queue
  /// Returns true if added, false if duplicate or queue is full
  Future<bool> add(ApiRequest request, Completer<Response> completer) async {
    // Check queue size limit
    if (_queue.length >= _maxQueueSize) {
      developer.log(
        "⚠️ Queue is full (${_queue.length}/$_maxQueueSize), rejecting request",
        name: 'FailedRequestQueue',
      );
      completer.completeError(
        DioException(
          requestOptions: RequestOptions(path: request.endpoint),
          message: AppStrings.requestQueueFullPleaseTryAgainLater.tr,
        ),
      );
      return false;
    }

    // Generate hash for deduplication
    final hash = _hashRequest(request);

    // Same logical request may be fired twice in parallel (e.g. active ride
    // polls). If the first is already queued, complete this caller with the
    // same outcome as the queued request instead of surfacing a user-facing error.
    final existing = _firstWithHash(hash);
    if (existing != null) {
      developer.log(
        "🔄 Duplicate request coalesced with queued: ${request.endpoint}",
        name: 'FailedRequestQueue',
      );
      unawaited(
        existing.completer.future.then<void>(
          (response) {
            if (!completer.isCompleted) completer.complete(response);
          },
          onError: (Object e, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(e, stackTrace);
            }
          },
        ),
      );
      return false;
    }

    // Add to queue
    final timestamp = DateTime.now();
    final failedRequest = FailedRequest(
      id: '${timestamp.microsecondsSinceEpoch}_${request.endpoint}',
      request: request,
      completer: completer,
      timestamp: timestamp,
      requestHash: hash,
    );

    _queue.add(failedRequest);
    developer.log(
      "➕ Added to queue (${_queue.length}/$_maxQueueSize): ${request.endpoint}",
      name: 'FailedRequestQueue',
    );

    return true;
  }

  /// Remove a request from queue by ID
  bool remove(String id) {
    final index = _queue.indexWhere((req) => req.id == id);
    if (index != -1) {
      final removed = _queue.removeAt(index);
      developer.log(
        "➖ Removed from queue: ${removed.request.endpoint}",
        name: 'FailedRequestQueue',
      );
      return true;
    }
    return false;
  }

  FailedRequest? _firstWithHash(String hash) {
    for (final req in _queue) {
      if (req.requestHash == hash) return req;
    }
    return null;
  }

  /// Clear all requests from queue
  void clear() {
    developer.log(
      "🗑️ Clearing queue (${_queue.length} requests)",
      name: 'FailedRequestQueue',
    );

    // Complete all pending requests with error
    for (final req in _queue) {
      if (!req.completer.isCompleted) {
        req.completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: req.request.endpoint),
            message: AppStrings.requestQueueCleared.tr,
          ),
        );
      }
    }

    _queue.clear();
  }

  /// Generate hash for request deduplication
  /// Hash = MD5(endpoint + method + body + queryParams)
  String _hashRequest(ApiRequest request) {
    final components = [
      request.endpoint,
      request.method.name,
      jsonEncode(request.body ?? {}),
      jsonEncode(request.queryParams ?? {}),
    ];

    final combined = components.join('|');
    final bytes = utf8.encode(combined);
    final digest = md5.convert(bytes);

    return digest.toString();
  }
}
