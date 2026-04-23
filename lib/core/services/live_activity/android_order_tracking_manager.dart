import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

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

  String _formatDuration(int totalMinutes) {
    if (totalMinutes >= 60) {
      final int h = totalMinutes ~/ 60;
      final int m = totalMinutes % 60;
      return '${h}h ${m}m';
    }
    return '$totalMinutes mins';
  }

  Future<void> show({
    required String orderId,
    required String title,
    required String merchantName,
    required String status,
    required String subtitle,
    required int step,
    required int totalSteps,
    required bool isRiderDelivering,
    required bool isCompleted,
    required String vehicleDesc,
    required String plateNumber,
    required String eta,
    required String riderPhotoUrl,
    double etaSeconds = 0,
    String pickupDistance = '0',
    String deliveryDistance = '0',
  }) async {
    if (!_isAndroid) return;
    await ensureInitialized();

    try {
      final int notificationId = _getNotificationId(orderId);

      final double pickupVal = double.tryParse(pickupDistance) ?? 0.0;
      final double deliveryVal = double.tryParse(deliveryDistance) ?? 0.0;
      final double stepVal = step.toDouble();
      final double totalStepsVal = totalSteps.toDouble().clamp(6.0, 100.0);

      String displayEta = '';
      if (stepVal >= totalStepsVal || isCompleted) {
        displayEta = 'Arrived';
      } else {
        if (etaSeconds > 0) {
          displayEta = _formatDuration((etaSeconds / 60.0).ceil());
        } else {
          final double totalDist = (stepVal < totalStepsVal - 1)
              ? (pickupVal + deliveryVal)
              : deliveryVal;
          final int calcMin = (totalDist / 35.0 * 60.0).ceil();

          if (calcMin > 0) {
            displayEta = _formatDuration(calcMin);
          } else {
            displayEta = eta
                .toLowerCase()
                .replaceAll(" min", " mins")
                .replaceAll(" soon", " soon");
            if (displayEta.isEmpty || displayEta.toLowerCase().contains("na")) {
              displayEta = "soon";
            }
          }
        }
      }

      final String normalizedStatus = status.toLowerCase();
      String displayStatus = status;

      // 🏷️ Premium Status Mapping (Replicated from Swift)
      if (isCompleted || normalizedStatus.contains('completed')) {
        displayStatus = 'Arrived at Destination';
      } else if (normalizedStatus.contains('near_destination') ||
          normalizedStatus.contains('neardestination')) {
        displayStatus = 'Almost There';
      } else if (normalizedStatus.contains('ride_in_progress') ||
          normalizedStatus.contains('rideinprogress')) {
        displayStatus = 'On Your Way';
      } else if (normalizedStatus.contains('ride_started') ||
          normalizedStatus.contains('ridestarted')) {
        displayStatus = 'Ride Started';
      } else if (normalizedStatus.contains('driver_arrived') ||
          normalizedStatus.contains('driverarrived')) {
        displayStatus = 'Driver Arrived';
      } else if (normalizedStatus.contains('driver_arriving') ||
          normalizedStatus.contains('driverarriving')) {
        displayStatus = 'Driver En Route';
      } else if (normalizedStatus.contains('searching') ||
          normalizedStatus.contains('finding')) {
        displayStatus = 'Finding Driver';
      } else if (normalizedStatus.contains('assigned')) {
        displayStatus = 'Driver Assigned';
      }

      final int progress =
          (isCompleted || normalizedStatus.contains('completed'))
          ? 100
          : (totalStepsVal > 0 ? ((stepVal / totalStepsVal) * 100).round() : 0);

      String etaDetail = '';
      if (isCompleted || normalizedStatus.contains('completed')) {
        etaDetail = 'Hope you had a great ride!';
      } else {
        final String phase = isRiderDelivering
            ? 'Arriving at destination'
            : 'Arriving at pickup';
        final String time = displayEta.toLowerCase() == 'soon'
            ? 'Soon'
            : displayEta;
        etaDetail = '$phase • $time';
      }

      final String contentTitle = merchantName.isNotEmpty
          ? merchantName
          : title;

      final String bigText = [
        displayStatus,
        etaDetail,
        if (vehicleDesc.isNotEmpty) vehicleDesc,
        if (plateNumber.isNotEmpty) plateNumber,
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
            // Make sure these assets exist or use generic ones
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(
              bigText,
              contentTitle: contentTitle,
              summaryText: null,
            ),
            color: const Color(0xFFF3004C),
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
        'Android ride tracking notification shown for $orderId: $status (step $step/$totalSteps)',
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
