import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/bindings/initial_binding.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/services/live_activity/live_activity_manager.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint("Background Message Data: ${message.data}");
  if (message.notification != null) {
    debugPrint(
      "Background Message Notification: ${message.notification?.title} - ${message.notification?.body}",
    );
  }
}

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };

      // Choose environment (can be set via --dart-define)
      const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
      final env = Environment.values.firstWhere(
        (e) => e.toString() == 'Environment.$envString',
        orElse: () => Environment.dev,
      );

      AppConfig.init(env: env);
      await di.init();

      // Initialize Notification Service
      await di.sl<NotificationService>().initialize();

      await di.sl<AnalyticsService>().logEvent('app_opened');

      // Initialize Live Activity Service
      await di.sl<LiveActivityManager>().init();

      runApp(const MyApp());
    },
    (error, stack) {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic design size for ScreenUtil (e.g., iPhone 13/14 size)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Selcom Rides',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialBinding: InitialBinding(),
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.pages,
        );
      },
    );
  }
}
