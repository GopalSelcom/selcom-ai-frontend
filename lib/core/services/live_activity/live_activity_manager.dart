import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
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
  final Map<String, DateTime> _lastUpdateTime = {};
  final Map<String, String> _lastSyncedTokens = {};
  final Map<String, Future<String?>> _inProgressStarts = {};

  Stream<ActivityUpdate> get activityUpdateStream =>
      _liveActivitiesPlugin.activityUpdateStream;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  static const String _activityIdKey = 'live_activity_order_to_id';
  static const String _merchantNameKey = 'live_activity_order_to_merchant';

  Future<void> init() async {
    developer.log("🎬 LiveActivityManager.init()", name: 'ORDER_TRACKING');
    try {
      final String? activitiesData = await StorageService().read(
        _activityIdKey,
      );
      final String? merchantsData = await StorageService().read(
        _merchantNameKey,
      );

      if (activitiesData != null && activitiesData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(activitiesData);
        _orderToActivityId = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
      if (merchantsData != null && merchantsData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(merchantsData);
        _orderToMerchantName = decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      developer.log(
        "❌ Error loading persisted state: $e",
        name: 'ORDER_TRACKING',
      );
    }

    if (_isIOS) {
      try {
        await _liveActivitiesPlugin.init(appGroupId: 'group.com.selcom.go');

        _liveActivitiesPlugin.activityUpdateStream.listen((event) {
          developer.log(
            "📢 RECEIVED activity update from plugin: ${event.activityId}",
            name: 'ORDER_TRACKING',
          );
        });

        final activeIds = await _liveActivitiesPlugin.getAllActivitiesIds();

        final List<String> staleOrderIds = [];
        _orderToActivityId.forEach((orderId, activityId) {
          if (activityId != 'android' && !activeIds.contains(activityId)) {
            staleOrderIds.add(orderId);
          }
        });

        if (staleOrderIds.isNotEmpty) {
          developer.log(
            "🧹 Pruning ${staleOrderIds.length} stale activities",
            name: 'ORDER_TRACKING',
          );
          for (final id in staleOrderIds) {
            _orderToActivityId.remove(id);
            _orderToMerchantName.remove(id);
          }
          await _saveState();
        }

        _syncAllActiveTokens();
        Timer.periodic(
          const Duration(minutes: 5),
          (_) => _syncAllActiveTokens(),
        );
      } catch (e) {
        developer.log(
          "❌ Error initializing ActivityKit: $e",
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
      developer.log("❌ Error saving state: $e", name: 'ORDER_TRACKING');
    }
  }

  Future<void> _clearState(String orderId) async {
    _orderToActivityId.remove(orderId);
    _orderToMerchantName.remove(orderId);
    _lastUpdateTime.remove(orderId);
    await _saveState();
  }

  Future<Map<String, String>> getAllActivityTokens() async {
    if (!_isIOS) return {};
    final Map<String, String> tokens = {};
    for (final orderId in _orderToActivityId.keys.toList()) {
      final activityId = _orderToActivityId[orderId];
      if (activityId == null || activityId == 'android') continue;

      String? token;
      try {
        token = await _liveActivitiesPlugin
            .getPushToken(activityId)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        developer.log(
          "⚠️ Error fetching token for $orderId: $e",
          name: 'ORDER_TRACKING',
        );
      }
      if (token != null && token.isNotEmpty) tokens[orderId] = token;
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
    if (_inProgressStarts.containsKey(orderId))
      return _inProgressStarts[orderId];

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
      final String? existingId = _orderToActivityId[orderId];
      if (_isIOS && existingId != null && existingId != 'android') {
        final activeIds = await _liveActivitiesPlugin.getAllActivitiesIds();
        if (!activeIds.contains(existingId)) {
          _orderToActivityId.remove(orderId);
        } else {
          await updateActivity(
            orderId: orderId,
            status: status,
            title: title,
            merchantName: merchantName,
            subtitle: subtitle,
            fare: fare,
            eta: eta,
            vehicleDesc: vehicleDesc,
            plateNumber: plateNumber,
            step: step,
            totalSteps: totalSteps,
            isRiderDelivering: isRiderDelivering,
            deliveryStartDate: deliveryStartDate,
            etaSeconds: etaSeconds,
            pickupDistance: pickupDistance,
            deliveryDistance: deliveryDistance,
          );
          return existingId;
        }
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
          riderPhotoUrl: '',
          pickupDistance: pickupDistance,
          deliveryDistance: deliveryDistance,
        );
        _orderToActivityId[orderId] = 'android';
        await _saveState();
        return 'android';
      }

      if (_isIOS) {
        if (!await _liveActivitiesPlugin.areActivitiesEnabled())
          return "disabled";
        if (_iosActivityCount >= _maxConcurrentIOSActivities)
          return "limit_reached";

        final activityModel = {
          'order_id': orderId,
          'merchant_name': merchantName,
          'status': status,
          'title': title,
          'subtitle': subtitle,
          'fare': fare,
          'eta': eta ?? '',
          'vehicle_desc': vehicleDesc,
          'plate_number': plateNumber,
          'rider_photo_url': '',
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
        await sl<RideRepository>().updateActivityToken(entry.key, entry.value);
        _lastSyncedTokens[entry.key] = entry.value;
      } catch (e) {
        developer.log(
          "⚠️ Token sync error for ${entry.key}: $e",
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
    String? token;
    for (int i = 0; i < 10; i++) {
      try {
        token = await _liveActivitiesPlugin.getPushToken(activityId);
        if (token != null && token.isNotEmpty) break;
      } catch (e) {}
      await Future.delayed(const Duration(seconds: 3));
    }
    if (token != null && token.isNotEmpty) {
      try {
        await sl<RideRepository>().updateActivityToken(orderId, token);
        _lastSyncedTokens[orderId] = token;
      } catch (e) {}
    }
  }

  Future<void> updateActivity({
    required String orderId,
    required String status,
    required String title,
    String? merchantName,
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
    developer.log(
      "🔄 updateActivity for $orderId (status: $status)",
      name: 'ORDER_TRACKING',
    );
    try {
      if (merchantName != null && merchantName.isNotEmpty) {
        _orderToMerchantName[orderId] = merchantName;
        await _saveState();
      }

      final String? effMerchant = _orderToMerchantName[orderId];
      final String? activityId = _orderToActivityId[orderId];

      developer.log(
        "🔍 Status: $status, ActivityID: $activityId, merchant: $effMerchant",
        name: 'ORDER_TRACKING',
      );

      if (activityId == null) {
        developer.log(
          "⚠️ No activity ID found for ride $orderId. Skipping update.",
          name: 'ORDER_TRACKING',
        );
        return;
      }

      if (_isIOS && activityId != 'android') {
        final updateData = {
          'order_id': orderId,
          'merchant_name': effMerchant ?? '',
          'status': status,
          'title': title,
          'subtitle': subtitle,
          'fare': fare,
          'eta': eta ?? '',
          'vehicle_desc': vehicleDesc,
          'plate_number': plateNumber,
          'rider_photo_url': '',
          'step': step,
          'total_steps': totalSteps,
          'is_completed': isCompleted,
          'is_rider_delivering': isRiderDelivering,
          'delivery_start_date': deliveryStartDate,
          'eta_seconds': etaSeconds,
          'pickup_distance': pickupDistance,
          'delivery_distance': deliveryDistance,
        };

        developer.log(
          "📡 Pushing update to ActivityKit: ID=$activityId PAYLOAD: ${jsonEncode(updateData)}",
          name: 'ORDER_TRACKING',
        );

        try {
          await _liveActivitiesPlugin.updateActivity(activityId, updateData);
          developer.log("✅ ActivityKit push SUCCESS", name: 'ORDER_TRACKING');
        } catch (e) {
          developer.log(
            "❌ ActivityKit push FAILED: $e",
            name: 'ORDER_TRACKING',
          );
        }
      }
    } catch (e) {
      developer.log("❌ Error in updateActivity: $e", name: 'ORDER_TRACKING');
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
      await _clearState(orderId);
    }
  }

  Future<void> endAllTracking() async {
    final ids = _orderToActivityId.keys.toList();
    for (final id in ids) {
      await endActivity(id);
    }
  }
}
