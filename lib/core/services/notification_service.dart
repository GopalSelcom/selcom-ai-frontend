import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agora_calling_package/utils/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/utils/push_notification_navigation.dart';
import '../data/models/notification_model.dart';
import '../routes/app_routes.dart';
import '../utils/app_logger.dart';
import 'call_permission_prompt_service.dart';
import 'error_reporting/error_reporter.dart';
import 'live_activity/android_order_tracking_manager.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _logTag = 'Notification';

  void _logD(String message) => AppLogger.d(message, tag: _logTag);

  void _logI(String message) => AppLogger.i(message, tag: _logTag);

  void _logW(String message) => AppLogger.w(message, tag: _logTag);

  void _logE(String message) => AppLogger.e(message, tag: _logTag);

  void _logRemoteMessage(String source, RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    _logI(
      '[$source] FCM received — '
      'messageId=${message.messageId} '
      'sentTime=${message.sentTime} '
      'from=${message.from} '
      'hasNotificationBlock=${notification != null} '
      'title=${notification?.title ?? data['title']} '
      'body=${notification?.body ?? data['body']} '
      'dataKeys=${data.keys.toList()} '
      'rideId=${data['ride_id'] ?? data['rideId'] ?? data['order_id']} '
      'status=${data['status']} '
      'type=${data['type']}',
    );
  }

  bool _isInitialized = false;
  bool _homePermissionFlowRunning = false;
  String? _deviceToken;
  Map<String, dynamic>? _pendingNavigationRaw;
  static const String _defaultChannelId = 'high_importance_channel';

  /// Returns the cached device token or an empty string.
  String get deviceToken => _deviceToken ?? "";

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load persisted token if available (to avoid "123" on start)
    _deviceToken = await StorageService().read(StorageKeys.fcmToken);
    if (_deviceToken != null) {
      _logD("Loaded persisted FCM token: $_deviceToken");
    }

    // Listen for token refreshes to keep the cached token updated
    _fcm.onTokenRefresh.listen((token) async {
      _deviceToken = token;
      _logD("FCM Token Updated: $token");
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

    // 3. Create Android Notification Channel
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // 4. iOS Foreground Notification Options
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    }

    // 5. Listeners (background→foreground taps)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Cold start: prefer FCM initial message (real tray tap while killed).
    // Local launch-details is a fallback for data-only → local tray taps, but
    // must be deduped — the plugin can keep returning the same payload on later
    // icon opens (does not consume launch details).
    await _consumeColdStartNotificationLaunch();

    _isInitialized = true;
    _logI(
      'Notification Service Initialized — '
      'tokenPresent=${(_deviceToken ?? '').isNotEmpty}',
    );
  }

  /// Handles terminated-state notification taps exactly once per payload.
  Future<void> _consumeColdStartNotificationLaunch() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final raw = Map<String, dynamic>.from(initialMessage.data);
      if (_isLiveTrackingPayload(raw)) {
        _logD('INITIAL FCM skipped LIVE_TRACKING (no navigation)');
        await _rememberHandledNavPayload(raw);
        return;
      }
      if (await _wasNavPayloadAlreadyHandled(raw)) {
        _logD(
          'INITIAL FCM skipped (stale — already handled, not a new tap)',
        );
        return;
      }
      _logRemoteMessage('INITIAL (terminated launch)', initialMessage);
      await _rememberHandledNavPayload(raw);
      _queueOrHandleNavigationRaw(raw);
      return;
    }

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (!(launchDetails?.didNotificationLaunchApp ?? false)) {
      _logD('No initial FCM / local notification launch');
      return;
    }

    final payload = launchDetails?.notificationResponse?.payload;
    if (payload == null || payload.isEmpty) {
      _logD('Local notification launch has empty payload — ignore');
      return;
    }

    try {
      final raw = Map<String, dynamic>.from(jsonDecode(payload));
      if (_isLiveTrackingPayload(raw)) {
        _logD('Local launch skipped LIVE_TRACKING (no navigation)');
        await _rememberHandledNavPayload(raw);
        return;
      }
      // Plugin keeps returning the last launch payload on later icon opens.
      if (await _wasNavPayloadAlreadyHandled(raw)) {
        _logD(
          'Local launch skipped (stale — open from icon, not a new notification tap)',
        );
        return;
      }
      // Android + singleTask: without an FCM initial message, local launch
      // details are usually a replay of an older tap — not a fresh icon-open.
      // Real FCM tray taps (type 500–504 with notification block) use
      // getInitialMessage above. Mark handled so the replay stops.
      if (Platform.isAndroid) {
        _logD(
          'Android local launch ignored without FCM initial '
          '(avoids ride-details on icon open)',
        );
        await _rememberHandledNavPayload(raw);
        return;
      }
      _logI('LOCAL launch from notification tap — queueing navigation');
      await _rememberHandledNavPayload(raw);
      _queueOrHandleNavigationRaw(raw);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      _logE("Error decoding launched notification payload: $e");
    }
  }

  /// Stable fingerprint for a notification data map (used to ignore stale launches).
  String _navPayloadFingerprint(Map<String, dynamic> raw) {
    final type = (raw['type'] ?? '').toString();
    final rideId =
        (raw['ride_id'] ?? raw['rideId'] ?? raw['order_id'] ?? '').toString();
    final status = (raw['status'] ?? '').toString();
    final phase = (raw['phase'] ?? '').toString();
    final title = (raw['title'] ?? '').toString();
    final body = (raw['body'] ?? '').toString();
    return '$type|$rideId|$status|$phase|$title|$body';
  }

  Future<bool> _wasNavPayloadAlreadyHandled(Map<String, dynamic> raw) async {
    final last = await StorageService().read(
      StorageKeys.lastHandledPushLaunchKey,
    );
    return last != null && last == _navPayloadFingerprint(raw);
  }

  Future<void> _rememberHandledNavPayload(Map<String, dynamic> raw) async {
    await StorageService().write(
      StorageKeys.lastHandledPushLaunchKey,
      _navPayloadFingerprint(raw),
    );
  }

  Future<NotificationSettings> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logI('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      _logI('User granted provisional permission');
    } else {
      _logW('User declined or has not accepted permission');
    }
    return settings;
  }

  /// Home entry: system notification sheet, then Android call/full-screen prompts.
  /// Runs strictly one step at a time (no overlapping dialogs).
  Future<void> runHomePermissionFlow() async {
    if (_homePermissionFlowRunning) return;
    _homePermissionFlowRunning = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!await CallPermissionPromptService.waitUntilUiReady()) return;

      await _requestSystemNotificationPermission();
      if (!await CallPermissionPromptService.waitUntilUiReady()) return;

      if (Platform.isAndroid) {
        await CallPermissionPromptService.ensureAndroidCallPermissions();
      }
    } finally {
      _homePermissionFlowRunning = false;
    }
  }

  Future<void> _requestSystemNotificationPermission() async {
    if (Platform.isAndroid) {
      final current = await Permission.notification.status;
      if (!current.isGranted && !current.isPermanentlyDenied) {
        await Permission.notification.request();
      }
    } else {
      await requestPermission();
    }
    unawaited(getToken());
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
        _logI("FCM Token: $token");
      }

      return token;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      // On iOS, sometimes the APNS token isn't ready immediately.
      if (Platform.isIOS &&
          e.toString().contains('apns-token-not-set') &&
          retryCount < 5) {
        _logW("APNS token not set, retrying in 3 seconds...");
        await Future.delayed(const Duration(seconds: 3));
        return getToken(retryCount: retryCount + 1);
      }
      _logE("Error getting FCM token: $e");
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _logRemoteMessage('FOREGROUND', message);

    // Call pushes use CallKit / in-app UI — not a generic banner.
    final callType = PushTypes.typeFromData(message.data);
    if (PushTypes.isLiveCallSignaling(callType)) {
      _logI(
        '[FOREGROUND] Skipped — call push type=$callType '
        '(handled by agora_calling_package)',
      );
      return;
    }

    final data = FCMNotificationData.fromJson(message.data);
    String? title = message.notification?.title ?? data.title;
    String? body = message.notification?.body ?? data.body;
    final isDataOnly = message.notification == null;

    // Android does not auto-display FCM notification payloads in foreground.
    // iOS may already show the system banner when a notification block is
    // present — only mirror data-only pushes locally to avoid duplicates.
    final shouldShowLocal =
        title != null &&
        body != null &&
        (Platform.isAndroid || isDataOnly);

    if (shouldShowLocal) {
      _logI(
        '[FOREGROUND] Showing local notification — title="$title" body="$body" '
        'platform=${Platform.operatingSystem} '
        'source=${isDataOnly ? "data_payload" : "fcm_notification_block"}',
      );
      showLocalNotification(
        id: message.notification?.hashCode ?? message.messageId.hashCode,
        title: title,
        body: body,
        // Preserve full FCM data (type, ride_id, url) for tap routing.
        payload: jsonEncode(Map<String, dynamic>.from(message.data)),
      );
    } else if (!isDataOnly && Platform.isIOS) {
      _logI(
        '[FOREGROUND] iOS skipped local notification — '
        'FCM notification block present (avoids duplicate banner)',
      );
    } else {
      _logW(
        '[FOREGROUND] No notification shown — '
        'missing title/body (title=$title body=$body)',
      );
    }

    // 🚗 Refresh Sticky Notification if this is a ride update
    if (data.rideId != null && data.status != null) {
      _logI(
        '[FOREGROUND] Updating ride sticky notification — '
        'rideId=${data.rideId} status=${data.status}',
      );
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
    _logRemoteMessage('OPENED_APP', message);
    final raw = Map<String, dynamic>.from(message.data);
    // Sticky GPS/ETA pushes must not route (no ride-details fetch on reopen).
    if (_isLiveTrackingPayload(raw)) {
      _logD('OPENED_APP skipped LIVE_TRACKING (no navigation)');
      return;
    }
    // Remember so a later icon open does not re-use stale launch-details.
    unawaited(_rememberHandledNavPayload(raw));
    _queueOrHandleNavigationRaw(raw);
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logD("Local notification clicked: ${response.payload}");
    if (response.payload != null) {
      try {
        final Map<String, dynamic> rawData = jsonDecode(response.payload!);
        if (_isLiveTrackingPayload(rawData)) {
          _logD('Local tap skipped LIVE_TRACKING (no navigation)');
          return;
        }
        unawaited(_rememberHandledNavPayload(rawData));
        _queueOrHandleNavigationRaw(rawData);
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
        _logE("Error decoding notification payload: $e");
      }
    }
  }

  static bool _isLiveTrackingPayload(Map<String, dynamic> raw) {
    final type = (raw['type'] ?? '').toString().trim().toUpperCase();
    return type == 'LIVE_TRACKING';
  }

  /// Routes a notification tap through [PushNotificationNavigation], or queues
  /// it until after splash/auth so `Get.offAllNamed(home)` cannot wipe the
  /// destination (see [flushPendingNavigationIfAny] / SplashController).
  void _queueOrHandleNavigationRaw(Map<String, dynamic> raw) {
    if (_isNavigationReady()) {
      unawaited(_handleNotificationNavigationRaw(raw));
      return;
    }
    // Keep latest tap; flushed after splash → Home (see SplashController).
    _pendingNavigationRaw = raw;
    _logD(
      'Push nav queued until past splash/auth '
      '(route=${Get.currentRoute})',
    );
  }

  /// True when the main navigator exists and splash/auth bootstrap is done.
  ///
  /// Navigating during splash is unsafe: ~2.5s later splash runs
  /// [Get.offAllNamed](home) and wipes the push destination (looks like a crash).
  bool _isNavigationReady() {
    if (Get.key.currentState == null) return false;
    final route = Get.currentRoute;
    const blocked = <String>{
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.loginSupport,
      AppRoutes.phone,
      AppRoutes.otp,
      AppRoutes.profileLoading,
    };
    return !blocked.contains(route);
  }

  /// Drops a queued push tap (e.g. user landed on onboarding, not Home).
  void clearPendingNavigation() {
    _pendingNavigationRaw = null;
  }

  /// Runs a previously queued push tap once the user is past splash/auth
  /// (typically right after Home is shown).
  Future<void> flushPendingNavigationIfAny() async {
    final raw = _pendingNavigationRaw;
    if (raw == null) return;
    if (!_isNavigationReady()) {
      _logD(
        'flushPendingNavigation skipped — still on ${Get.currentRoute}',
      );
      return;
    }
    _pendingNavigationRaw = null;
    await _handleNotificationNavigationRaw(raw);
  }

  Future<void> _handleNotificationNavigationRaw(
    Map<String, dynamic> raw,
  ) async {
    try {
      await PushNotificationNavigation.handle(raw);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      _logE("Exception in _handleNotificationNavigationRaw: $e");
    }
  }

  int _idCounter = 0;

  /// Shows a tray notification from the **FCM background isolate** for
  /// data-only pushes (title/body in `data`, no `notification` block).
  /// Without this, Android may deliver the message but show nothing to tap.
  static Future<void> showFromBackgroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      // System already shows the FCM notification banner.
      return;
    }

    final type = (message.data['type'] ?? '').toString().toUpperCase().trim();
    // Backend GPS/ETA sticky updates (`LIVE_TRACKING`) — do not create a second tray item.
    if (type == 'LIVE_TRACKING') {
      return;
    }

    final title = (message.data['title'] ?? '').toString().trim();
    final body = (message.data['body'] ?? '').toString().trim();
    if (title.isEmpty && body.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const channel = AndroidNotificationChannel(
      _defaultChannelId,
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    final id = message.messageId?.hashCode ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await plugin.show(
      id,
      title.isEmpty ? 'Selcom Go' : title,
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
        ),
      ),
      payload: jsonEncode(Map<String, dynamic>.from(message.data)),
    );
  }

  Future<void> showLocalNotification({
    int? id,
    String? title,
    String? body,
    String? payload,
  }) async {
    _idCounter++;
    final finalId = id ?? _idCounter;
    _logD(
      'showLocalNotification — id=$finalId title="$title" body="$body" '
      'hasPayload=${payload != null && payload.isNotEmpty}'
      'payload=$payload',
    );

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
      _logI('Local notification displayed — id=$finalId title="$title"');
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      _logE('Failed to show local notification id=$finalId: $e');
    }
  }
}
