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
  final Map<String, String> _lastStatus = {};
  final Map<String, String> _lastSyncedTokens = {};
  final Map<String, Completer<String?>> _inProgressStarts = {};

  // 📝 Telemetry Cache: Stores last known good values to prevent "empty-payload" flickering
  final Map<String, String> _cacheVehicleName = {};
  final Map<String, String> _cachePlateNumber = {};
  final Map<String, String> _cacheDriverName = {};
  final Map<String, String> _cacheDriverAvatarUrl = {};
  final Map<String, double> _cacheEtaSeconds = {};

  Stream<ActivityUpdate> get activityUpdateStream =>
      _liveActivitiesPlugin.activityUpdateStream;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  static const String _activityIdKey = 'live_activity_order_to_id';
  static const String _merchantNameKey = 'live_activity_order_to_merchant';

  Future<void> init() async {
    developer.log("🎬 LiveActivityManager.init()", name: 'LIVE_ACTIVITY');
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
        name: 'LIVE_ACTIVITY',
      );
    }

    if (_isIOS) {
      try {
        await _liveActivitiesPlugin.init(appGroupId: 'group.com.selcom.go');
        final activeIds = await _liveActivitiesPlugin.getAllActivitiesIds();

        final List<String> staleOrderIds = [];
        _orderToActivityId.forEach((orderId, activityId) {
          if (activityId != 'android' && !activeIds.contains(activityId)) {
            staleOrderIds.add(orderId);
          }
        });

        if (staleOrderIds.isNotEmpty) {
          for (final id in staleOrderIds) {
            _orderToActivityId.remove(id);
            _orderToMerchantName.remove(id);
          }
          await _saveState();
        }
        for (final activeId in activeIds) {
          if (!_orderToActivityId.values.contains(activeId)) {
            developer.log(
              "🧹 Ending dangling activity: $activeId",
              name: 'LIVE_ACTIVITY',
            );
            await _liveActivitiesPlugin
                .endActivity(activeId)
                .catchError((_) {});
          }
        }

        _syncAllActiveTokens();
        Timer.periodic(
          const Duration(minutes: 5),
          (_) => _syncAllActiveTokens(),
        );
      } catch (e) {
        developer.log(
          "❌ Error initializing ActivityKit: $e",
          name: 'LIVE_ACTIVITY',
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
      developer.log("❌ Error saving state: $e", name: 'LIVE_ACTIVITY');
    }
  }

  Future<void> _clearState(String orderId) async {
    _orderToActivityId.remove(orderId);
    _orderToMerchantName.remove(orderId);
    _lastUpdateTime.remove(orderId);
    _lastStatus.remove(orderId);

    // Clear telemetry caches
    _cacheVehicleName.remove(orderId);
    _cachePlateNumber.remove(orderId);
    _cacheDriverName.remove(orderId);
    _cacheDriverAvatarUrl.remove(orderId);
    _cacheEtaSeconds.remove(orderId);

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
      } catch (e) {}
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
    String driverName = '',
    String vehicleName = '',
    String driverAvatarUrl = '',
    String plateNumber = '',
    double etaSeconds = 0,
    bool isCompleted = false,
    double? driverLatitude,
    double? driverLongitude,
    bool updateIfExists = true,
  }) async {
    if (_inProgressStarts.containsKey(orderId)) {
      return _inProgressStarts[orderId]!.future;
    }

    final completer = Completer<String?>();
    _inProgressStarts[orderId] = completer;

    try {
      final result = await _startActivityInternal(
        orderId: orderId,
        status: status,
        driverName: driverName,
        vehicleName: vehicleName,
        driverAvatarUrl: driverAvatarUrl,
        plateNumber: plateNumber,
        etaSeconds: etaSeconds,
        isCompleted: isCompleted,
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        updateIfExists: updateIfExists,
      );
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _inProgressStarts.remove(orderId);
    }
  }

  Future<String?> _startActivityInternal({
    required String orderId,
    required String status,
    String driverName = '',
    String vehicleName = '',
    String driverAvatarUrl = '',
    String plateNumber = '',
    double etaSeconds = 0,
    bool isCompleted = false,
    double? driverLatitude,
    double? driverLongitude,
    bool updateIfExists = true,
  }) async {
    try {
      final String? existingId = _orderToActivityId[orderId];

      // Update Cache with incoming data
      if (driverName.isNotEmpty) _cacheDriverName[orderId] = driverName;
      if (vehicleName.isNotEmpty) _cacheVehicleName[orderId] = vehicleName;
      if (plateNumber.isNotEmpty) _cachePlateNumber[orderId] = plateNumber;
      if (driverAvatarUrl.isNotEmpty)
        _cacheDriverAvatarUrl[orderId] = driverAvatarUrl;
      if (etaSeconds > 0) _cacheEtaSeconds[orderId] = etaSeconds;

      if (_isIOS && existingId != null && existingId != 'android') {
        if (updateIfExists) {
          await updateActivity(
            orderId: orderId,
            status: status,
            driverName: driverName,
            vehicleName: vehicleName,
            driverAvatarUrl: driverAvatarUrl,
            plateNumber: plateNumber,
            etaSeconds: etaSeconds,
            isCompleted: isCompleted,
            driverLatitude: driverLatitude,
            driverLongitude: driverLongitude,
          );
          return existingId;
        }
      }

      _orderToMerchantName[orderId] = driverName;
      await _saveState();

      if (_isAndroid) {
        await AndroidOrderTrackingManager().show(
          orderId: orderId,
          title: 'Trip Tracking',
          merchantName: driverName.isNotEmpty
              ? driverName
              : (plateNumber.isNotEmpty ? plateNumber : 'Trip Tracking'),
          status: status,
          subtitle: plateNumber,
          step: isCompleted ? 5 : 2,
          totalSteps: 5,
          isRiderDelivering: false,
          vehicleDesc: vehicleName,
          plateNumber: plateNumber,
          eta: '',
          isCompleted: isCompleted,
          riderPhotoUrl: driverAvatarUrl,
          pickupDistance: '0',
          deliveryDistance: '0',
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

        final activityModel = <String, dynamic>{
          'status': status,
          'driver_name': driverName,
          'driver_avatar_url': driverAvatarUrl,
          'vehicle_name': vehicleName,
          'plate_number': plateNumber,
          'eta_seconds': etaSeconds,
          'driver_latitude': driverLatitude,
          'driver_longitude': driverLongitude,
          'is_completed': isCompleted,
        };

        activityModel.removeWhere((key, value) => value == null);
        developer.log(
          "📦 Creation Payload: $activityModel",
          name: 'LIVE_ACTIVITY',
        );

        final activityId = await _liveActivitiesPlugin
            .createActivity(orderId, activityModel)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        if (activityId != null) {
          _orderToActivityId[orderId] = activityId;
          developer.log(
            "✨ Activity created! ID: $activityId",
            name: 'LIVE_ACTIVITY',
          );
          await _saveState();
          _syncPushTokenWithBackend(orderId, activityId);
          return activityId;
        }
      }
    } catch (e) {
      developer.log("❌ Error starting tracking: $e", name: 'LIVE_ACTIVITY');
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
      } catch (e) {}
    }
  }

  Future<void> _syncPushTokenWithBackend(
    String orderId,
    String activityId,
  ) async {
    if (!_isIOS) return;
    developer.log(
      "🔑 Starting Push Token sync for $orderId",
      name: 'LIVE_ACTIVITY',
    );
    String? token;
    for (int i = 0; i < 10; i++) {
      try {
        developer.log(
          "⏳ Polling token attempt ${i + 1}/10...",
          name: 'LIVE_ACTIVITY',
        );
        token = await _liveActivitiesPlugin.getPushToken(activityId);
        if (token != null && token.isNotEmpty) {
          developer.log("✅ Token received from OS!", name: 'LIVE_ACTIVITY');
          break;
        }
      } catch (e) {
        developer.log("⚠️ Token poll error: $e", name: 'LIVE_ACTIVITY');
      }
      await Future.delayed(const Duration(seconds: 3));
    }

    if (token != null && token.isNotEmpty) {
      try {
        developer.log(
          "📡 Sending token to backend for $orderId",
          name: 'LIVE_ACTIVITY',
        );
        final result = await sl<RideRepository>().updateActivityToken(
          orderId,
          token,
        );
        result.fold(
          (f) => developer.log(
            "❌ Failed to sync token with backend: $f",
            name: 'LIVE_ACTIVITY',
          ),
          (s) {
            developer.log(
              "🎊 Token synced successfully!",
              name: 'LIVE_ACTIVITY',
            );
            _lastSyncedTokens[orderId] = token!;
          },
        );
      } catch (e) {
        developer.log(
          "❌ Exception during token sync: $e",
          name: 'LIVE_ACTIVITY',
        );
      }
    } else {
      developer.log(
        "🚫 Failed to get token after 10 attempts",
        name: 'LIVE_ACTIVITY',
      );
    }
  }

  Future<void> updateActivity({
    required String orderId,
    required String status,
    String driverName = '',
    String vehicleName = '',
    String driverAvatarUrl = '',
    String plateNumber = '',
    double etaSeconds = 0,
    bool isCompleted = false,
    double? driverLatitude,
    double? driverLongitude,
  }) async {
    try {
      final now = DateTime.now();
      final lastUpdate = _lastUpdateTime[orderId];
      final previousStatus = _lastStatus[orderId];

      // Bypass throttle if status has changed (critical transition)
      final isStatusChange =
          previousStatus != null && status.toLowerCase() != previousStatus;

      if (!isStatusChange &&
          lastUpdate != null &&
          now.difference(lastUpdate).inMilliseconds < 1500) {
        developer.log(
          "⏳ Throttling update for $orderId (Status: $status)",
          name: 'LIVE_ACTIVITY',
        );
        return;
      }

      _lastUpdateTime[orderId] = now;
      _lastStatus[orderId] = status.toLowerCase();

      if (driverName.isNotEmpty) {
        _orderToMerchantName[orderId] = driverName;
        _cacheDriverName[orderId] = driverName;
        await _saveState();
      }

      // Update other caches with incoming fresh data
      if (vehicleName.isNotEmpty) _cacheVehicleName[orderId] = vehicleName;
      if (plateNumber.isNotEmpty) _cachePlateNumber[orderId] = plateNumber;
      if (driverAvatarUrl.isNotEmpty) {
        _cacheDriverAvatarUrl[orderId] = driverAvatarUrl;
      }
      if (etaSeconds > 0) _cacheEtaSeconds[orderId] = etaSeconds;

      final String? activityId = _orderToActivityId[orderId];
      if (activityId == null || activityId == 'android') return;

      final updateData = <String, dynamic>{
        'status': status,
        'driver_name': driverName.isNotEmpty
            ? driverName
            : (_cacheDriverName[orderId] ?? ''),
        'driver_avatar_url': driverAvatarUrl.isNotEmpty
            ? driverAvatarUrl
            : (_cacheDriverAvatarUrl[orderId] ?? ''),
        'vehicle_name': vehicleName.isNotEmpty
            ? vehicleName
            : (_cacheVehicleName[orderId] ?? ''),
        'plate_number': plateNumber.isNotEmpty
            ? plateNumber
            : (_cachePlateNumber[orderId] ?? ''),
        'eta_seconds': (etaSeconds > 0
            ? etaSeconds
            : (_cacheEtaSeconds[orderId] ?? 0.0)),
        'driver_latitude': driverLatitude,
        'driver_longitude': driverLongitude,
        'is_completed': isCompleted,
      };

      updateData.removeWhere((key, value) => value == null);
      developer.log(
        "📦 Update Payload (Merged): $updateData",
        name: 'LIVE_ACTIVITY',
      );

      await _liveActivitiesPlugin
          .updateActivity(activityId, updateData)
          .timeout(const Duration(seconds: 4), onTimeout: () {});
      developer.log(
        "📡 Activity updated! Status: $status",
        name: 'LIVE_ACTIVITY',
      );
    } catch (e) {
      developer.log("❌ Error in updateActivity: $e", name: 'LIVE_ACTIVITY');
    }
  }

  Future<void> endActivity(String orderId) async {
    try {
      final String? activityId = _orderToActivityId[orderId];
      if (activityId == null) return;
      if (_isAndroid && activityId == 'android') {
        await AndroidOrderTrackingManager().dismiss(orderId);
      } else if (_isIOS) {
        await _liveActivitiesPlugin
            .endActivity(activityId)
            .timeout(const Duration(seconds: 4), onTimeout: () {});
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
