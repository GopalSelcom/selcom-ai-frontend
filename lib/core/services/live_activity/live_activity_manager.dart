import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import '../storage_service.dart';
import 'android_order_tracking_manager.dart';
import '../../../features/ride/domain/repositories/ride_repository.dart';
import '../../di/injection_container.dart';

class LiveActivityManager {
  static final LiveActivityManager _instance = LiveActivityManager._internal();
  factory LiveActivityManager() => _instance;
  LiveActivityManager._internal();

  final LiveActivities _liveActivitiesPlugin = LiveActivities();

  Map<String, String> _orderToActivityId = {};
  Map<String, String> _orderToMerchantName = {};
  final Map<String, String> _urlToLocalPath = {};
  final Map<String, Future<String?>> _inProgressStarts = {};

  Stream<ActivityUpdate> get activityUpdateStream =>
      _liveActivitiesPlugin.activityUpdateStream;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  static const String _activityIdKey = 'live_activity_order_to_id';
  static const String _merchantNameKey = 'live_activity_order_to_merchant';

  Future<void> init() async {
    try {
      final String? activitiesJson = await StorageService().read(
        _activityIdKey,
      );
      final String? merchantsJson = await StorageService().read(
        _merchantNameKey,
      );

      if (activitiesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(activitiesJson);
        _orderToActivityId = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
      if (merchantsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(merchantsJson);
        _orderToMerchantName = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      developer.log(
        "❌ Error loading persisted tracking state: $e",
        name: 'ORDER_TRACKING',
      );
    }

    if (_isIOS) {
      try {
        // MATCH THIS WITH THE APP GROUP CREATED IN PORTAL
        await _liveActivitiesPlugin.init(appGroupId: 'group.com.selcom.go');

        // 🛰️ Periodically sync all tokens to handle rotations
        Timer.periodic(const Duration(minutes: 5), (_) {
          _syncAllActiveTokens();
        });
      } catch (e) {
        developer.log(
          "❌ Error initializing LiveActivities: $e",
          name: 'ORDER_TRACKING',
        );
      }
    }
  }

  Future<void> _saveState() async {
    try {
      await StorageService().write(
        _activityIdKey,
        jsonEncode(_orderToActivityId),
      );
      await StorageService().write(
        _merchantNameKey,
        jsonEncode(_orderToMerchantName),
      );
    } catch (e) {
      developer.log(
        "❌ Error saving tracking state: $e",
        name: 'ORDER_TRACKING',
      );
    }
  }

  Future<void> _clearState(String orderId) async {
    _orderToActivityId.remove(orderId);
    _orderToMerchantName.remove(orderId);
    await _saveState();
  }

  String? getOrderIdByActivityId(String activityId) {
    return _orderToActivityId.entries
        .firstWhereOrNull((e) => e.value == activityId)
        ?.key;
  }

  Future<Map<String, String>> getAllActivityTokens() async {
    if (!_isIOS) return {};
    final Map<String, String> tokens = {};
    for (final entry in _orderToActivityId.entries) {
      if (entry.value != 'android') {
        try {
          final token = await _liveActivitiesPlugin.getPushToken(entry.value);
          if (token != null && token.isNotEmpty) {
            tokens[entry.key] = token;
          }
        } catch (e) {
          developer.log(
            "⚠️ Error getting token for ${entry.key}: $e",
            name: 'ORDER_TRACKING',
          );
        }
      }
    }
    return tokens;
  }

  static const int _maxConcurrentIOSActivities = 5;
  int get _iosActivityCount =>
      _orderToActivityId.values.where((v) => v != 'android').length;

  Future<String?> startActivity({
    required String orderId,
    required String status,
    required String title,
    String merchantName = '',
    String subtitle = '',
    String? fare,
    String? eta,
    String vehicleDesc = '',
    String plateNumber = '',
    String riderPhotoUrl = '',
    int step = 0,
    int totalSteps = 6,
    bool isRiderDelivering = false,
    bool isCompleted = false,
    double deliveryStartDate = 0,
    double etaSeconds = 0,
    String pickupDistance = '0',
    String deliveryDistance = '0',
  }) async {
    if (_inProgressStarts.containsKey(orderId)) {
      developer.log(
        "⏳ Activity start already in progress for $orderId, awaiting existing future...",
        name: 'ORDER_TRACKING',
      );
      return _inProgressStarts[orderId];
    }

    final work = _startActivityInternal(
      orderId: orderId,
      status: status,
      title: title,
      merchantName: merchantName,
      subtitle: subtitle,
      fare: fare,
      eta: eta,
      vehicleDesc: vehicleDesc,
      plateNumber: plateNumber,
      riderPhotoUrl: riderPhotoUrl,
      step: step,
      totalSteps: totalSteps,
      isRiderDelivering: isRiderDelivering,
      isCompleted: isCompleted,
      deliveryStartDate: deliveryStartDate,
      etaSeconds: etaSeconds,
      pickupDistance: pickupDistance,
      deliveryDistance: deliveryDistance,
    );

    _inProgressStarts[orderId] = work;

    try {
      return await work;
    } finally {
      _inProgressStarts.remove(orderId);
    }
  }

  Future<String?> _startActivityInternal({
    required String orderId,
    required String status,
    required String title,
    String merchantName = '',
    String subtitle = '',
    String? fare,
    String? eta,
    String vehicleDesc = '',
    String plateNumber = '',
    String riderPhotoUrl = '',
    int step = 0,
    int totalSteps = 6,
    bool isRiderDelivering = false,
    bool isCompleted = false,
    double deliveryStartDate = 0,
    double etaSeconds = 0,
    String pickupDistance = '0',
    String deliveryDistance = '0',
  }) async {
    try {
      final String? existingActivityId = _orderToActivityId[orderId];

      if (_isIOS &&
          existingActivityId != null &&
          existingActivityId != 'android') {
        final activeIds = await _liveActivitiesPlugin.getAllActivitiesIds();
        if (!activeIds.contains(existingActivityId)) {
          _orderToActivityId.remove(orderId);
        } else {
          await updateActivity(
            orderId: orderId,
            status: status,
            title: title,
            subtitle: subtitle,
            fare: fare,
            eta: eta,
            vehicleDesc: vehicleDesc,
            plateNumber: plateNumber,
            riderPhotoUrl: riderPhotoUrl,
            step: step,
            totalSteps: totalSteps,
            isRiderDelivering: isRiderDelivering,
            deliveryStartDate: deliveryStartDate,
            etaSeconds: etaSeconds,
            pickupDistance: pickupDistance,
            deliveryDistance: deliveryDistance,
          );
          return existingActivityId;
        }
      } else if (_isAndroid && existingActivityId == 'android') {
        await updateActivity(
          orderId: orderId,
          status: status,
          title: title,
          subtitle: subtitle,
          fare: fare,
          eta: eta,
          vehicleDesc: vehicleDesc,
          plateNumber: plateNumber,
          riderPhotoUrl: riderPhotoUrl,
          step: step,
          totalSteps: totalSteps,
          isRiderDelivering: isRiderDelivering,
          deliveryStartDate: deliveryStartDate,
          etaSeconds: etaSeconds,
          pickupDistance: pickupDistance,
          deliveryDistance: deliveryDistance,
        );
        return 'android';
      }

      // 🖼️ Remote Image Support
      String localRiderPhoto = riderPhotoUrl;
      if (riderPhotoUrl.isNotEmpty && riderPhotoUrl.startsWith('http')) {
        localRiderPhoto = await _maybeDownloadImage(riderPhotoUrl);
      } else if (riderPhotoUrl.isEmpty) {
        localRiderPhoto = '';
      }

      _orderToMerchantName[orderId] = merchantName;
      await _saveState();

      if (_isAndroid) {
        await AndroidOrderTrackingManager().show(
          orderId: orderId,
          title: title,
          merchantName: merchantName,
          status: status,
          subtitle: subtitle,
          step: step,
          totalSteps: totalSteps,
          isRiderDelivering: isRiderDelivering,
          vehicleDesc: vehicleDesc,
          plateNumber: plateNumber,
          eta: eta ?? '',
          isCompleted: isCompleted,
          riderPhotoUrl: localRiderPhoto,
          pickupDistance: pickupDistance,
          deliveryDistance: deliveryDistance,
        );
        _orderToActivityId[orderId] = 'android';
        await _saveState();
        return 'android';
      }

      if (_isIOS) {
        if (!await _liveActivitiesPlugin.areActivitiesEnabled()) {
          return "disabled";
        }
        if (_iosActivityCount >= _maxConcurrentIOSActivities) {
          return "limit_reached";
        }

        final Map<String, dynamic> activityModel = {
          'order_id': orderId,
          'merchant_name': merchantName,
          'status': status,
          'title': title,
          'subtitle': subtitle,
          'fare': fare,
          'eta': eta ?? '',
          'vehicle_desc': vehicleDesc,
          'plate_number': plateNumber,
          'rider_photo_url': localRiderPhoto,
          'step': step,
          'total_steps': totalSteps,
          'is_completed': isCompleted,
          'is_rider_delivering': isRiderDelivering,
          'delivery_start_date': deliveryStartDate,
          'eta_seconds': etaSeconds,
          'pickup_distance': pickupDistance,
          'delivery_distance': deliveryDistance,
        };

        final activityId = await _liveActivitiesPlugin.createActivity(
          orderId,
          activityModel,
        );
        if (activityId != null) {
          _orderToActivityId[orderId] = activityId;
          await _saveState();

          // 🛰️ Sync Push Token with Backend (iOS only)
          _syncPushTokenWithBackend(orderId, activityId);

          return activityId;
        }
      }
    } catch (e) {
      developer.log("❌ Error starting tracking: $e", name: 'ORDER_TRACKING');
    }
    return null;
  }

  Future<void> _syncAllActiveTokens() async {
    if (!_isIOS) return;

    final tokens = await getAllActivityTokens();
    for (final entry in tokens.entries) {
      try {
        developer.log(
          "📡 Periodic sync: registering Live Activity push token for ${entry.key}",
          name: 'ORDER_TRACKING',
        );
        await sl<RideRepository>().updateActivityToken(entry.key, entry.value);
      } catch (e) {
        developer.log(
          "⚠️ Periodic sync error for ${entry.key}: $e",
          name: 'ORDER_TRACKING',
        );
      }
    }
  }

  Future<void> _syncPushTokenWithBackend(
    String orderId,
    String activityId,
  ) async {
    if (!_isIOS) return;

    // Retry logic: ActivityKit push tokens may not be available immediately
    String? token;
    int retries = 5;

    while (retries > 0) {
      try {
        token = await _liveActivitiesPlugin.getPushToken(activityId);
        if (token != null && token.isNotEmpty) break;
      } catch (e) {
        developer.log(
          "⚠️ Error fetching push token: $e",
          name: 'ORDER_TRACKING',
        );
      }

      developer.log(
        "⏳ Push token not ready for $orderId, retrying... ($retries left)",
        name: 'ORDER_TRACKING',
      );
      await Future.delayed(const Duration(seconds: 2));
      retries--;
    }

    if (token != null && token.isNotEmpty) {
      try {
        developer.log(
          "📡 registering initial Live Activity push token for $orderId",
          name: 'ORDER_TRACKING',
        );
        await sl<RideRepository>().updateActivityToken(orderId, token);
      } catch (e) {
        developer.log(
          "❌ Error registering push token with backend: $e",
          name: 'ORDER_TRACKING',
        );
      }
    } else {
      developer.log(
        "❌ Failed to get push token for $orderId after retries",
        name: 'ORDER_TRACKING',
      );
    }
  }

  Future<void> updateActivity({
    required String orderId,
    required String status,
    required String title,
    String subtitle = '',
    String? fare,
    String? eta,
    String vehicleDesc = '',
    String plateNumber = '',
    String riderPhotoUrl = '',
    int step = 0,
    int totalSteps = 6,
    bool isRiderDelivering = false,
    bool isCompleted = false,
    double deliveryStartDate = 0,
    double etaSeconds = 0,
    String pickupDistance = '0',
    String deliveryDistance = '0',
  }) async {
    try {
      String localRiderPhoto = riderPhotoUrl;
      if (riderPhotoUrl.isNotEmpty && riderPhotoUrl.startsWith('http')) {
        localRiderPhoto = await _maybeDownloadImage(riderPhotoUrl);
      } else if (riderPhotoUrl.isEmpty) {
        localRiderPhoto = '';
      }

      final String? merchantName = _orderToMerchantName[orderId];
      final String? activityId = _orderToActivityId[orderId];

      if (activityId == null) return;

      if (_isAndroid && activityId == 'android') {
        await AndroidOrderTrackingManager().show(
          orderId: orderId,
          title: title,
          merchantName: merchantName ?? '',
          status: status,
          subtitle: subtitle,
          step: step,
          totalSteps: totalSteps,
          isRiderDelivering: isRiderDelivering,
          vehicleDesc: vehicleDesc,
          plateNumber: plateNumber,
          eta: eta ?? '',
          isCompleted: isCompleted,
          riderPhotoUrl: localRiderPhoto,
          pickupDistance: pickupDistance,
          deliveryDistance: deliveryDistance,
        );
        return;
      }

      if (_isIOS && activityId != 'android') {
        final Map<String, dynamic> updateData = {
          'order_id': orderId,
          'merchant_name': merchantName ?? '',
          'status': status,
          'title': title,
          'subtitle': subtitle,
          'fare': fare,
          'eta': eta ?? '',
          'vehicle_desc': vehicleDesc,
          'plate_number': plateNumber,
          'rider_photo_url': localRiderPhoto,
          'step': step,
          'total_steps': totalSteps,
          'is_completed': isCompleted,
          'is_rider_delivering': isRiderDelivering,
          'delivery_start_date': deliveryStartDate,
          'eta_seconds': etaSeconds,
          'pickup_distance': pickupDistance,
          'delivery_distance': deliveryDistance,
        };
        await _liveActivitiesPlugin.updateActivity(activityId, updateData);
      }
    } catch (e) {
      developer.log("❌ Error updating tracking: $e", name: 'ORDER_TRACKING');
    }
  }

  Future<void> endActivity(String orderId) async {
    try {
      final String? activityId = _orderToActivityId[orderId];
      if (activityId == null) return;

      if (_isAndroid && activityId == 'android') {
        await AndroidOrderTrackingManager().dismiss(orderId);
      } else if (_isIOS) {
        await _liveActivitiesPlugin.endActivity(activityId);
      }
      await _clearState(orderId);
    } catch (e) {
      developer.log("❌ Error ending tracking: $e", name: 'ORDER_TRACKING');
      await _clearState(orderId);
    }
  }

  Future<void> endAllTracking() async {
    try {
      final orderIds = _orderToActivityId.keys.toList();
      for (final id in orderIds) {
        await endActivity(id);
      }
    } catch (e) {
      developer.log("❌ Error ending all tracking: $e", name: 'ORDER_TRACKING');
    }
  }

  Future<String> _maybeDownloadImage(String url) async {
    if (!url.startsWith('http')) return url;
    if (_urlToLocalPath.containsKey(url)) {
      final cachedFile = File(_urlToLocalPath[url]!);
      if (await cachedFile.exists()) return _urlToLocalPath[url]!;
    }

    try {
      final dio = Dio();
      final baseDir = (await getApplicationDocumentsDirectory()).path;
      final String fileName = "rider_${url.hashCode}.jpg";
      final String path = "$baseDir/$fileName";

      await dio.download(url, path);
      _urlToLocalPath[url] = path;
      return path;
    } catch (e) {
      developer.log("⚠️ Error downloading image: $e", name: 'ORDER_TRACKING');
      return url;
    }
  }
}
