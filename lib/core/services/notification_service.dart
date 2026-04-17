import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/storage_service.dart';
import 'package:logger/logger.dart';

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

  /// Returns the cached device token or a default value.
  String get deviceToken => _deviceToken ?? "123";

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

    // Fetch and cache device token (don't await to avoid blocking app startup)
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

    // 4. Listeners
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
      String? token = await _fcm.getToken();
      _deviceToken = token;
      if (token != null) {
        await StorageService().write(StorageKeys.fcmToken, token);
      }
      _logger.d("FCM Token: $token");
      return token;
    } catch (e) {
      // On iOS, sometimes the APNS token isn't ready immediately.
      // We retry a few times after a delay to give it time to be received.
      if (Platform.isIOS &&
          e.toString().contains('apns-token-not-set') &&
          retryCount < 5) {
        _logger.w(
          "APNS token not set, retrying in 3 seconds (Attempt $retryCount)...",
        );
        await Future.delayed(const Duration(seconds: 3));
        return getToken(retryCount: retryCount + 1);
      }
      _logger.e("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _logger.d("Foreground Message received: ${message.messageId}");

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      showLocalNotification(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _logger.d("Message opened app: ${message.messageId}");
    // Handle navigation or state updates based on message.data
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.d("Local notification clicked: ${response.payload}");
    if (response.payload != null) {
      // Map payload back to data and handle navigation
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
            'high_importance_channel',
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
    } catch (e) {
      debugPrint("Error in _localNotifications.show: $e");
    }
  }
}
