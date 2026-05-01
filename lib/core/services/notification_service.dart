import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../di/injection_container.dart';
import '../../features/ride/domain/repositories/ride_repository.dart';
import '../../shared/utils/ride_active_navigation.dart';
import '../../shared/utils/app_dialogs.dart';
import '../data/models/notification_model.dart';
import 'live_activity/android_order_tracking_manager.dart';
import '../services/error_reporting/error_reporter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  bool _isInitialized = false;
  String? _deviceToken;
  static const String _defaultChannelId = 'high_importance_channel';
  static const String _incomingCallChannelId = 'go_incoming_calls';

  /// Returns the cached device token or an empty string.
  String get deviceToken => _deviceToken ?? "";

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load persisted token if available (to avoid "123" on start)
    _deviceToken = await StorageService().read(StorageKeys.fcmToken);
    if (_deviceToken != null) {
      _logger.d("Loaded persisted FCM token: $_deviceToken");
    }

    // Listen for token refreshes to keep the cached token updated
    _fcm.onTokenRefresh.listen((token) async {
      _deviceToken = token;
      _logger.d("FCM Token Updated: $token");
      await StorageService().write(StorageKeys.fcmToken, token);
    });

    // Fetch and cache device token (background)
    getToken();

    // 1. Initialize Local Notifications

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          defaultPresentAlert: true,
          defaultPresentSound: true,
          defaultPresentBadge: true,
          defaultPresentBanner: true,
          defaultPresentList: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: null,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions for iOS immediately
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // 3. Create Android Notification Channel
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // 4. iOS Foreground Notification Options
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 5. Listeners
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Initial message if app was terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
    _logger.i("Notification Service Initialized");
  }

  Future<NotificationSettings> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      _logger.i('User granted provisional permission');
    } else {
      _logger.w('User declined or has not accepted permission');
    }
    return settings;
  }

  Future<bool> isPermissionDenied() async {
    NotificationSettings settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.denied;
  }

  Future<String?> getToken({int retryCount = 0}) async {
    try {
      // Fetch token from Firebase
      String? token = await _fcm.getToken();

      if (token != null && token.isNotEmpty) {
        _deviceToken = token;
        await StorageService().write(StorageKeys.fcmToken, token);
        _logger.i("FCM Token: $token");
      }

      return token;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      // On iOS, sometimes the APNS token isn't ready immediately.
      if (Platform.isIOS &&
          e.toString().contains('apns-token-not-set') &&
          retryCount < 5) {
        _logger.w("APNS token not set, retrying in 3 seconds...");
        await Future.delayed(const Duration(seconds: 3));
        return getToken(retryCount: retryCount + 1);
      }
      _logger.e("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _defaultChannelId, // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    const AndroidNotificationChannel incomingCallChannel =
        AndroidNotificationChannel(
          _incomingCallChannelId,
          'Incoming Calls',
          description: 'Incoming in-app voice calls',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(incomingCallChannel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _logger.d("Foreground Message received: ${message.messageId}");
    final data = FCMNotificationData.fromJson(message.data);
    final type = (message.data['type'] ?? '').toString().toLowerCase();

    if (type == 'incoming_call') {
      final role = (message.data['caller_role'] ?? 'rider').toString();
      final title = role == 'driver' ? 'Incoming call from driver' : 'Incoming call from rider';
      final body = 'Tap to open incoming call screen';
      showIncomingCallNotification(
        id: message.messageId.hashCode,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
      return;
    }

    String? title = message.notification?.title ?? data.title;
    String? body = message.notification?.body ?? data.body;

    if (title != null || body != null) {
      _logger.d("Showing local notification for foreground message");
      showLocalNotification(
        id: message.notification?.hashCode ?? message.messageId.hashCode,
        title: title,
        body: body,
        payload: jsonEncode(data.toJson()),
      );
    }

    // 🚗 Refresh Sticky Notification if this is a ride update
    if (data.rideId != null && data.status != null) {
      AndroidOrderTrackingManager().show(
        orderId: data.rideId!,
        status: data.status!,
        driverName: data.driverName ?? '',
        vehicleName: data.vehicleName ?? '',
        plateNumber: data.plateNumber ?? '',
        etaSeconds: data.etaSeconds ?? 0,
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _logger.d("Message opened app: ${message.messageId}");
    final data = FCMNotificationData.fromJson(message.data);
    _handleNotificationNavigation(data);
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.d("Local notification clicked: ${response.payload}");
    if (response.payload != null) {
      try {
        final Map<String, dynamic> rawData = jsonDecode(response.payload!);
        final data = FCMNotificationData.fromJson(rawData);
        _handleNotificationNavigation(data);
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
        _logger.e("Error decoding notification payload: $e");
      }
    }
  }

  Future<void> _handleNotificationNavigation(FCMNotificationData data) async {
    final rideId = data.rideId;
    if (rideId == null || rideId.isEmpty) {
      _logger.w("No ride_id found in notification data");
      return;
    }

    try {
      _logger.i("Navigating to ride $rideId from notification");

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final rideRepo = sl<RideRepository>();
      final result = await rideRepo.getRideDetails(rideId);

      if (Get.isDialogOpen ?? false) Get.back();

      result.fold(
        (failure) {
          _logger.e("Error fetching ride details: ${failure.message}");
          AppDialogs.showErrorDialog(
            message: AppStrings.unableToOpenRideDetails.tr,
          );
        },
        (ride) {
          navigateToDriverAcceptedForRide(ride);
        },
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (Get.isDialogOpen ?? false) Get.back();
      _logger.e("Exception in _handleNotificationNavigation: $e");
    }
  }

  int _idCounter = 0;
  Future<void> showLocalNotification({
    int? id,
    String? title,
    String? body,
    String? payload,
  }) async {
    _idCounter++;
    final finalId = id ?? _idCounter;

    // 1. System Notification (Always triggered for the Notification Drawer/History)
    try {
      await _localNotifications.show(
        finalId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _defaultChannelId,
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            presentList: true,
          ),
        ),
        payload: payload,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("Error in _localNotifications.show: $e");
    }
  }

  Future<void> showIncomingCallNotification({
    int? id,
    String? title,
    String? body,
    String? payload,
  }) async {
    _idCounter++;
    final finalId = id ?? _idCounter;
    try {
      await _localNotifications.show(
        finalId,
        title ?? 'Incoming call',
        body ?? 'Tap to answer',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _incomingCallChannelId,
            'Incoming Calls',
            channelDescription: 'Incoming in-app voice calls',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            ticker: 'incoming_call',
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      _logger.e('Error showing incoming call notification: $e');
    }
  }
}
