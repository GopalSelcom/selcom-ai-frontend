import 'dart:async';

import 'package:agora_calling_package/agora_calling.dart';
import 'package:agora_calling_package/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/localization/delegate.dart';
import 'core/localization/getx_languages_translations.dart';
import 'core/localization/localization.dart';
import 'core/services/agora_calling_bootstrap.dart';
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background FCM: ${message.data}');
  debugPrint("Handling a background message: ${message.messageId}");

  // Hand off Agora calling pushes (incoming_call / call_joined / call_cancelled)
  // to the package — it owns the full-screen-intent / CallKit-fallback rendering.
  final type = (message.data['type'] ?? '').toString().toLowerCase().trim();
  if (type == 'incoming_call' ||
      type == 'call_joined' ||
      type == 'call_cancelled') {
    await AgoraCallingNotificationService.firebaseBackgroundHandler(
      message,
      iosCallKitIconName: AgoraCallingBootstrap.iosCallKitIconName,
      callKitCallIdNamespace: AgoraCallingBootstrap.callKitCallIdNamespace,
      backgroundCallKitAppName:
          AgoraCallingBootstrap.fcmBackgroundCallKitAppName,
    );
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
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      try {
        await dotenv.load(fileName: '.env');
      } catch (e, st) {
        // Usually means `.env` was not listed under `flutter: assets:` in pubspec.yaml,
        // or the file is missing at build time. App continues with dart-define / defaults.
        if (kDebugMode) {
          debugPrint(
            'flutter_dotenv: could not load .env ($e). '
            'Ensure pubspec lists `- .env` under flutter assets and the file exists.',
          );
          debugPrint('$st');
        }
      }

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

      // Choose environment (can be set via --dart-define)
      const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
      final env = Environment.values.firstWhere(
        (e) => e.toString() == 'Environment.$envString',
        orElse: () => Environment.prod,
      );

      AppConfig.init(env: env);
      await di.init();

      // Initialize Notification Service
      await di.sl<NotificationService>().initialize();

      // Initialize Agora calling package (REST + FCM + Android FG service).
      // Identity comes from the JWT on each request — `getAuthHeaders` is
      // called per-call via Dio interceptor, so it picks up post-login state.
      await AgoraCallingBootstrap.init();

      // Bridge native iOS PushKit/CallKit events into the calling package.
      // Token registration goes through `AgoraCalling.registerVoipToken`,
      // which PATCHes `/v4/go/user/voip-token`.
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

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedLocale());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService().flushPendingNavigationIfAny());
    });
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
