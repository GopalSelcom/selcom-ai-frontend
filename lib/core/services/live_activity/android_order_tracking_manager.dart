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

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  int _getNotificationId(String orderId) {
    return _baseNotificationId + (orderId.hashCode % 1000).abs();
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

      final int progress = totalStepsVal > 0
          ? ((stepVal / totalStepsVal) * 100).round()
          : 0;

      final String etaLabel = displayEta == 'Arrived'
          ? 'Ride arrived'
          : 'Arriving in $displayEta';

      final String contentTitle = merchantName.isNotEmpty
          ? merchantName
          : title;

      final String bigText = [
        status,
        if (etaLabel.isNotEmpty) etaLabel,
        if (vehicleDesc.isNotEmpty) vehicleDesc,
        if (plateNumber.isNotEmpty) plateNumber,
      ].join('\n');

      final String contentText = etaLabel.isNotEmpty ? etaLabel : status;

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
