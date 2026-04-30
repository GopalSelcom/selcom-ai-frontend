import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import '../../theme/app_colors.dart';
import '../storage_service.dart';

class AndroidOrderTrackingManager {
  static final AndroidOrderTrackingManager _instance =
      AndroidOrderTrackingManager._internal();
  factory AndroidOrderTrackingManager() => _instance;
  AndroidOrderTrackingManager._internal();

  static const int _baseNotificationId = 88000;
  static const String _channelId = 'order_tracking_channel';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isPluginInitialized = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  int _getNotificationId(String orderId) {
    return _baseNotificationId + (orderId.hashCode % 1000).abs();
  }

  String _getCacheKey(String orderId) => 'ride_telemetry_$orderId';

  Future<Map<String, dynamic>> _getCachedTelemetry(String orderId) async {
    try {
      final String? data = await StorageService().read(_getCacheKey(orderId));
      if (data != null && data.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _saveTelemetry(
    String orderId,
    Map<String, dynamic> telemetry,
  ) async {
    try {
      await StorageService().write(
        _getCacheKey(orderId),
        jsonEncode(telemetry),
      );
    } catch (_) {}
  }

  Future<void> ensureInitialized() async {
    if (_isPluginInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _plugin.initialize(initializationSettings);
    _isPluginInitialized = true;
    developer.log(
      'AndroidOrderTrackingManager: Plugin Initialized',
      name: 'ORDER_TRACKING',
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    
    final int totalMinutes = (totalSeconds / 60).ceil();
    if (totalMinutes >= 60) {
      final int h = totalMinutes ~/ 60;
      final int m = totalMinutes % 60;
      final String hStr = h == 1 ? 'hr' : 'hrs';
      if (m > 0) {
        final String mStr = m == 1 ? 'min' : 'mins';
        return '$h $hStr $m $mStr';
      }
      return '$h $hStr';
    }
    return '$totalMinutes ${totalMinutes == 1 ? "min" : "mins"}';
  }

  Future<void> show({
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
    if (!_isAndroid) return;
    await ensureInitialized();

    try {
      final int notificationId = _getNotificationId(orderId);

      // 💾 Load and Merge Telemetry Cache
      final cached = await _getCachedTelemetry(orderId);

      final String effectiveDriverName = driverName.isNotEmpty
          ? driverName
          : (cached['driver_name'] ?? '');
      final String effectiveVehicleName = vehicleName.isNotEmpty
          ? vehicleName
          : (cached['vehicle_name'] ?? '');
      final String effectivePlateNumber = plateNumber.isNotEmpty
          ? plateNumber
          : (cached['plate_number'] ?? '');
      final double effectiveEtaSeconds = etaSeconds > 0
          ? etaSeconds
          : (double.tryParse(cached['eta_seconds']?.toString() ?? '') ?? 0.0);
      final bool effectiveIsCompleted =
          isCompleted || (cached['is_completed'] == true);

      // Update Cache
      await _saveTelemetry(orderId, {
        'driver_name': effectiveDriverName,
        'vehicle_name': effectiveVehicleName,
        'plate_number': effectivePlateNumber,
        'eta_seconds': effectiveEtaSeconds,
        'is_completed': effectiveIsCompleted,
      });

      final String normalizedStatus = status.toLowerCase();
      String displayStatus = status;

      // 📡 Status-Based Phase/Progress Detection
      final bool isInRide =
          normalizedStatus.contains('ride_started') ||
          normalizedStatus.contains('ride_in_progress') ||
          normalizedStatus.contains('in_progress') ||
          normalizedStatus.contains('near_destination') ||
          normalizedStatus.contains('neardestination');

      int progress = 0;

      // 🏷️ Premium Status Mapping & Progress Logic
      if (effectiveIsCompleted || normalizedStatus.contains('completed')) {
        displayStatus = 'Arrived at Destination';
        progress = 100;
      } else if (normalizedStatus.contains('near_destination') ||
          normalizedStatus.contains('neardestination')) {
        displayStatus = 'Almost There';
        progress = 95;
      } else if (normalizedStatus.contains('ride_in_progress') ||
          normalizedStatus.contains('rideinprogress')) {
        displayStatus = 'On Your Way';
        progress = 80;
      } else if (normalizedStatus.contains('ride_started') ||
          normalizedStatus.contains('ridestarted')) {
        displayStatus = 'Ride Started';
        progress = 70;
      } else if (normalizedStatus.contains('driver_arrived') ||
          normalizedStatus.contains('driverarrived')) {
        displayStatus = 'Driver Arrived';
        progress = 60;
      } else if (normalizedStatus.contains('driver_arriving') ||
          normalizedStatus.contains('driverarriving')) {
        displayStatus = 'Driver En Route';
        progress = 40;
      } else if (normalizedStatus.contains('assigned')) {
        displayStatus = 'Driver Assigned';
        progress = 30;
      } else if (normalizedStatus.contains('searching') ||
          normalizedStatus.contains('finding')) {
        displayStatus = 'Finding Driver';
        progress = 10;
      }

      String displayEta = 'Soon';
      if (effectiveIsCompleted) {
        displayEta = 'Arrived';
      } else if (effectiveEtaSeconds > 0) {
        displayEta = _formatDuration(effectiveEtaSeconds.toInt());
      }

      String etaDetail = '';
      if (effectiveIsCompleted || normalizedStatus.contains('completed')) {
        etaDetail = 'Hope you had a great ride!';
      } else {
        final String phase = isInRide
            ? 'Arriving at destination'
            : 'Arriving at pickup';
        etaDetail = '$phase • $displayEta';
      }

      final String contentTitle = effectiveDriverName.isNotEmpty
          ? effectiveDriverName
          : 'Trip Tracking';

      final String bigText = [
        displayStatus,
        etaDetail,
        if (effectiveVehicleName.isNotEmpty) effectiveVehicleName,
        if (effectivePlateNumber.isNotEmpty) effectivePlateNumber,
      ].join('\n');

      final String contentText = etaDetail;

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _channelId,
            'Ride Tracking',
            channelDescription: 'Live ride status updates',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
            indeterminate: false,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              bigText,
              contentTitle: contentTitle,
              summaryText: null,
            ),
            color: AppColors.primary,
            colorized: true,
            ticker: status,
          );

      await _plugin.show(
        notificationId,
        contentTitle,
        contentText,
        NotificationDetails(android: androidDetails),
      );

      developer.log(
        'Android ride tracking notification shown for $orderId: $status',
        name: 'ORDER_TRACKING',
      );
    } catch (e) {
      developer.log(
        'Error showing Android ride tracking notification: $e',
        name: 'ORDER_TRACKING',
      );
    }
  }

  Future<void> dismiss(String orderId) async {
    if (!_isAndroid) return;
    try {
      final int notificationId = _getNotificationId(orderId);
      await _plugin.cancel(notificationId);
      developer.log(
        'Android ride tracking notification dismissed for $orderId',
        name: 'ORDER_TRACKING',
      );
    } catch (e) {
      developer.log(
        'Error dismissing Android ride tracking notification: $e',
        name: 'ORDER_TRACKING',
      );
    }
  }
}
