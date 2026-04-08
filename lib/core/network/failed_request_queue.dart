import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint(
        "⚠️ Queue is full (${_queue.length}/$_maxQueueSize), rejecting request",
      );
      completer.completeError(
        DioException(
          requestOptions: RequestOptions(path: request.endpoint),
          message: 'Request queue is full. Please try again later.',
        ),
      );
      return false;
    }

    // Generate hash for deduplication
    final hash = _hashRequest(request);

    // Check for duplicates
    if (contains(hash)) {
      debugPrint(
        "🔄 Duplicate request detected, skipping: ${request.endpoint}",
      );
      completer.completeError(
        DioException(
          requestOptions: RequestOptions(path: request.endpoint),
          message: 'Duplicate request already queued',
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
    debugPrint(
      "➕ Added to queue (${_queue.length}/$_maxQueueSize): ${request.endpoint}",
    );

    return true;
  }

  /// Remove a request from queue by ID
  bool remove(String id) {
    final index = _queue.indexWhere((req) => req.id == id);
    if (index != -1) {
      final removed = _queue.removeAt(index);
      debugPrint("➖ Removed from queue: ${removed.request.endpoint}");
      return true;
    }
    return false;
  }

  /// Check if a request hash exists in queue
  bool contains(String hash) {
    return _queue.any((req) => req.requestHash == hash);
  }

  /// Clear all requests from queue
  void clear() {
    debugPrint("🗑️ Clearing queue (${_queue.length} requests)");

    // Complete all pending requests with error
    for (final req in _queue) {
      if (!req.completer.isCompleted) {
        req.completer.completeError(
          DioException(
            requestOptions: RequestOptions(path: req.request.endpoint),
            message: 'Request queue cleared',
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
