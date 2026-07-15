import 'dart:async';
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:agora_calling_package/agora_calling_package.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/services/deeplink/deeplink_manager.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/config/environment.dart';
import 'core/di/injection_container.dart' as di;
import 'core/localization/delegate.dart';
import 'core/localization/getx_languages_translations.dart';
import 'core/localization/localization.dart';
import 'core/services/agora_calling_bootstrap.dart';
import 'core/services/session_auth_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/voip_callkit_bridge_service.dart';
import 'core/bindings/initial_binding.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/services/live_activity/live_activity_manager.dart';
import 'core/services/live_activity/android_order_tracking_manager.dart';
import 'core/data/models/notification_model.dart';
import 'core/services/error_reporting/error_reporter.dart';
import 'package:screenshot/screenshot.dart';

/// **Change this for local runs** (`dev` | `staging` | `prod`).
///
/// Same idea as `ApiEnvironment` in our other apps — one line to flip QA target.
/// Release CI can still pass `--dart-define=ENV=prod` (overrides when set).
/// const Environment kAppEnvironment = Environment.prod;
const Environment kAppEnvironment = Environment.prod;

void _registerKillCallLogSink() {
  // AgoraCallLogger matches AppLogger: debug-only by default.
  // Uncomment for release kill-state / CallKit debugging (main + FCM isolate):
  // AgoraCallLogger.forceRelease = true;
  AgoraCallLogger.sink = (line) {
    try {
      FirebaseCrashlytics.instance.log(line);
    } catch (_) {}
  };
}

/// FCM handler for **background and killed** app state.
///
/// Runs in a separate Dart isolate — logcat filter: `KILL_CALL` or `adb logcat -s flutter`.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _registerKillCallLogSink();

  AgoraCallLogger.kill(
    'FCM_BG',
    'isolate woke — messageId=${message.messageId} '
    'has_notification=${message.notification != null} '
    'release=$kReleaseMode',
  );
  if (message.notification != null) {
    AgoraCallLogger.kill(
      'FCM_BG',
      'WARNING: push has notification block — Android may NOT run '
      'CallKit in killed state. title=${message.notification?.title}',
    );
  }

  final type = (message.data['type'] ?? '').toString().toLowerCase().trim();
  final resolvedType = PushTypes.typeFromData(message.data) ?? '';
  AgoraCallLogger.kill(
    'FCM_BG',
    'data keys=${message.data.keys.toList()} '
    'directType="$type" resolvedType="$resolvedType"',
  );

  // Hand off Agora calling pushes to the package — CallKit / CallStyle UI.
  if (type == 'incoming_call' ||
      type == 'call_joined' ||
      type == 'call_cancelled') {
    AgoraCallLogger.kill('FCM_BG', 'routing to Agora background handler type=$type');
    try {
      await AgoraCallingNotificationService.firebaseBackgroundHandler(
        message,
        iosCallKitIconName: AgoraCallingBootstrap.iosCallKitIconName,
        callKitCallIdNamespace: AgoraCallingBootstrap.callKitCallIdNamespace,
        backgroundCallKitAppName:
            AgoraCallingBootstrap.fcmBackgroundCallKitAppName,
        localRole: CallParticipantRole.rider,
      );
      AgoraCallLogger.kill('FCM_BG', 'Agora background handler finished type=$type');
    } catch (e, st) {
      AgoraCallLogger.kill('FCM_BG', 'Agora background handler FAILED type=$type err=$e');
      AgoraCallLogger.kill('FCM_BG', 'stack=$st');
    }
    return;
  }

  final data = FCMNotificationData.fromJson(message.data);

  // 🚗 Refresh Sticky Notification if this is a ride update
  if (data.rideId != null && data.status != null) {
    await AndroidOrderTrackingManager().show(
      orderId: data.rideId!,
      status: data.status!,
      driverName: data.driverName ?? '',
      vehicleName: data.vehicleName ?? '',
      plateNumber: data.plateNumber ?? '',
      etaSeconds: data.etaSeconds ?? 0,
    );
  }
}

void main() async {
  debugPrint("==========================================================================");
  debugPrint("[NATIVE_DEEPLINK_LOG] main() EXECUTED. PID: $pid, Time: ${DateTime.now().toIso8601String()}");
  debugPrint("==========================================================================");
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      // Initialize Google Maps Renderer for Android
      // final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
      // if (mapsImplementation is GoogleMapsFlutterAndroid) {
      //   mapsImplementation.useAndroidViewSurface = true;
      //   await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
      // }

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Hive app storage (tokens, user, prefs) — must run before readers.
      await StorageService().init();

      // Initialize Error Reporter
      await ErrorReporter.instance.init();

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Report all framework errors to Crashlytics outside debug mode.
      FlutterError.onError = (details) {
        if (kDebugMode) {
          FlutterError.presentError(details);
          return;
        }
        ErrorReporter.instance.report(
          error: details.exception,
          stackTrace: details.stack,
          customMessage: details.context?.toString(),
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          ErrorReporter.instance.report(
            error: error,
            stackTrace: stack,
            fatal: true,
          );
        }
        return true;
      };

      AppConfig.init(env: resolveAppEnvironment(localDefault: kAppEnvironment));
      await di.init();

      // Initialize Notification Service
      await di.sl<NotificationService>().initialize();

      // Load saved session before calling init so CallKit Accept from
      // killed/background state can mint tokens (splash has not run yet).
      await SessionAuthService.instance.preloadFromStorage();

      _registerKillCallLogSink();

      // Initialize Agora calling package (REST + FCM + Android FG service).
      AgoraCallLogger.kill('COLD_START', 'AgoraCallingBootstrap.init starting');
      await AgoraCallingBootstrap.init();
      AgoraCallLogger.kill('COLD_START', 'AgoraCallingBootstrap.init done');

      // Bridge native iOS PushKit/CallKit events into the calling package.
      // Token registration goes through `AgoraCalling.registerVoipToken`,
      // which PATCHes the voip-token path from [URLS.profile.voipToken].
      await VoipCallkitBridgeService.instance.initialize();
      VoipCallkitBridgeService.instance.setOnVoipTokenChanged(
        AgoraCalling.registerVoipToken,
      );
      VoipCallkitBridgeService.instance.setOnIncomingCall(
        AgoraCalling.dispatchExternalIncomingCall,
      );

      await di.sl<AnalyticsService>().logEvent('app_opened');

      // Initialize Live Activity Service
      await di.sl<LiveActivityManager>().init();

      runApp(const MyApp());
    },
    (error, stack) {
      if (!kDebugMode) {
        ErrorReporter.instance.report(
          error: error,
          stackTrace: stack,
          fatal: true,
        );
      }
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  final DeepLinkManager _deepLinkManager = DeepLinkManager();

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedLocale());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService().flushPendingNavigationIfAny());
    });
    _deepLinkManager.initializeDeepLinks();
  }

  Future<void> _loadSavedLocale() async {
    final locale = await Localization.instance.getLocale();
    setLocale(locale);
  }

  void setLocale(Locale locale) {
    if (!mounted) return;
    setState(() {
      _locale = locale;
    });
    Get.updateLocale(locale);
  }
  @override
  void dispose() {
    _deepLinkManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Basic design size for ScreenUtil (e.g., iPhone 13/14 size)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Screenshot(
          controller: ErrorReporter.instance.screenshotController,
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Selcom Go',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            scrollBehavior: const BouncingScrollBehavior(),
            locale: _locale,
            fallbackLocale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('sw')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            translations: GetxLanguagesTranslations(),
            initialBinding: InitialBinding(),
            initialRoute: AppRoutes.splash,
            getPages: AppRoutes.pages,
          ),
        );
      },
    );
  }
}
