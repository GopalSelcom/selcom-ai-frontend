import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

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

  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      _logger.d("FCM Token: $token");
      return token;
    } catch (e) {
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
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _showLocalNotification(
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

  Future<void> _showLocalNotification({
    required int id,
    String? title,
    String? body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
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
        ),
      ),
      payload: payload,
    );
  }
}
