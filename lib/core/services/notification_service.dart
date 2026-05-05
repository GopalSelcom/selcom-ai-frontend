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
import '../../shared/agora_voice/service/agora_call_cancel_notification_bridge.dart';
import '../../shared/agora_voice/service/agora_incoming_call_notification_bridge.dart';
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
  Map<String, dynamic>? _pendingNavigationRaw;
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

    // Handle app launch from a local notification tap (background/terminated).
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          final rawData = Map<String, dynamic>.from(jsonDecode(payload));
          _queueOrHandleNavigationRaw(rawData);
        } catch (e, stackTrace) {
          ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
          _logger.e("Error decoding launched notification payload: $e");
        }
      }
    }

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
      unawaited(_handleForegroundIncomingCall(message));
      return;
    }
    if (type == 'call_cancelled') {
      unawaited(_handleForegroundCallCancelled(message));
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
    _queueOrHandleNavigationRaw(Map<String, dynamic>.from(message.data));
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.d("Local notification clicked: ${response.payload}");
    if (response.payload != null) {
      try {
        final Map<String, dynamic> rawData = jsonDecode(response.payload!);
        _queueOrHandleNavigationRaw(rawData);
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
        _logger.e("Error decoding notification payload: $e");
      }
    }
  }

  void _queueOrHandleNavigationRaw(Map<String, dynamic> raw) {
    if (_isNavigationReady()) {
      unawaited(_handleNotificationNavigationRaw(raw));
      return;
    }
    _pendingNavigationRaw = raw;
  }

  bool _isNavigationReady() {
    return Get.key.currentState != null;
  }

  Future<void> flushPendingNavigationIfAny() async {
    final raw = _pendingNavigationRaw;
    if (raw == null || !_isNavigationReady()) return;
    _pendingNavigationRaw = null;
    await _handleNotificationNavigationRaw(raw);
  }

  /// Foreground: show in-app incoming UI when already on the live ride screen;
  /// otherwise show the incoming-call channel notification.
  Future<void> _handleForegroundIncomingCall(RemoteMessage message) async {
    final raw = Map<String, dynamic>.from(message.data);
    if (await AgoraIncomingCallNotificationBridge.instance.deliverIfMatching(
          raw,
        )) {
      return;
    }
    // If user is already in app, open the ride incoming-call flow directly.
    _queueOrHandleNavigationRaw(raw);

    final role = (message.data['caller_role'] ?? 'rider').toString();
    final title = role == 'driver'
        ? 'Incoming call from driver'
        : 'Incoming call from rider';
    const body = 'Tap to open incoming call screen';
    final rideId = raw['ride_id']?.toString();
    await showIncomingCallNotification(
      id: _incomingCallNotificationId(rideId),
      title: title,
      body: body,
      payload: jsonEncode(raw),
    );
  }

  Future<void> _handleForegroundCallCancelled(RemoteMessage message) async {
    final raw = Map<String, dynamic>.from(message.data);
    if (await AgoraCallCancelNotificationBridge.instance.deliverIfMatching(raw)) {
      return;
    }
    final rideId = raw['ride_id']?.toString() ?? raw['rideId']?.toString();
    await cancelIncomingCallNotification(rideId: rideId);
  }

  Future<void> _handleNotificationNavigationRaw(
    Map<String, dynamic> raw,
  ) async {
    final type = (raw['type'] ?? '').toString().toLowerCase();
    final rideId = raw['ride_id']?.toString() ?? raw['rideId']?.toString();

    if (type == 'incoming_call' &&
        rideId != null &&
        rideId.isNotEmpty) {
      if (await AgoraIncomingCallNotificationBridge.instance.deliverIfMatching(
            raw,
          )) {
        return;
      }
    }
    if (type == 'call_cancelled' &&
        rideId != null &&
        rideId.isNotEmpty) {
      await cancelIncomingCallNotification(rideId: rideId);
      await AgoraCallCancelNotificationBridge.instance.deliverIfMatching(raw);
      return;
    }

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
          if (type == 'incoming_call') {
            navigateToDriverAcceptedForRide(
              ride,
              pendingIncomingCallPayload: raw,
            );
          } else {
            navigateToDriverAcceptedForRide(ride);
          }
        },
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (Get.isDialogOpen ?? false) Get.back();
      _logger.e("Exception in _handleNotificationNavigationRaw: $e");
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
            audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
            visibility: NotificationVisibility.public,
            ticker: 'incoming_call',
            icon: '@mipmap/ic_launcher',
            ongoing: true,
            autoCancel: true,
            timeoutAfter: 30000,
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

  int _incomingCallNotificationId(String? rideId) {
    final normalized = rideId?.trim() ?? '';
    if (normalized.isEmpty) return 700001;
    return 'incoming_call_$normalized'.hashCode;
  }

  Future<void> cancelIncomingCallNotification({String? rideId}) async {
    final id = _incomingCallNotificationId(rideId);
    try {
      await _localNotifications.cancel(id);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      _logger.e('Error cancelling incoming call notification: $e');
    }
  }
}
