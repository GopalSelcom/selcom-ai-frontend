import 'dart:io';

import 'package:get/get.dart';

import 'controllers/call_controller.dart';
import 'models/agora_config.dart';
import 'services/agora_service.dart';
import 'services/call_api_service.dart';
import 'services/notification_service.dart';
import 'ui/screens/active_call_screen.dart';
import 'ui/screens/incoming_call_screen.dart';
import 'utils/agora_call_log.dart';
import 'utils/full_screen_call_permission_prompt.dart';

/// Entry-point facade. Host apps call [AgoraCalling.init] once, then resolve
/// the controller through `Get.find<CallController>()`.
class AgoraCalling {
  AgoraCalling._();

  static bool _initialized = false;

  /// Wires the entire calling stack into GetX DI. Idempotent.
  ///
  /// **Initialization order matters.** We construct the controller and call
  /// `bootstrap()` BEFORE `notif.initialize()`, because:
  ///
  ///   1. `notif.initialize()` registers `FirebaseMessaging.onMessage`/
  ///      `onMessageOpenedApp` listeners AND consumes
  ///      `FirebaseMessaging.getInitialMessage()`. Any of those callbacks can
  ///      synchronously dispatch an event onto the broadcast `_pushes` stream.
  ///   2. `_pushes` is a broadcast `StreamController` — it **silently drops**
  ///      events that arrive while no listener is attached.
  ///   3. If the controller subscribes after step 1, an in-flight or
  ///      replayed-on-launch incoming-call push lands in the void and the
  ///      ringing UI never appears.
  ///
  /// So: instantiate notif, register controller (which lazily subscribes when
  /// `bootstrap()` runs), THEN tell notif to start fanning events.
  static Future<void> init(AgoraCallingConfig config) async {
    if (_initialized) {
      AgoraCallLogger.kill('COLD_START', 'AgoraCalling.init skipped — already initialized');
      return;
    }
    _initialized = true;
    AgoraCallLogger.kill('COLD_START', 'AgoraCalling.init starting role=${config.localRole}');

    final notif = AgoraCallingNotificationService(config);
    final api = CallApiService(config: config);
    final agora = AgoraService(appId: config.appId);

    Get.put<AgoraCallingConfig>(config, permanent: true);
    Get.put<CallApiService>(api, permanent: true);
    Get.put<AgoraService>(agora, permanent: true);
    Get.put<AgoraCallingNotificationService>(notif, permanent: true);

    final controller = CallController(
      config: config,
      api: api,
      agora: agora,
      notifications: notif,
    );
    Get.put<CallController>(controller, permanent: true);

    AgoraCallLogger.kill('COLD_START', 'CallController.bootstrap starting (CallKit replay listener)');
    await controller.bootstrap();
    AgoraCallLogger.kill('COLD_START', 'CallController.bootstrap done');
    await notif.initialize();
    AgoraCallLogger.kill('COLD_START', 'AgoraCalling.init complete — FCM foreground listeners ready');
  }

  static List<GetPage<dynamic>> routes() {
    return [
      GetPage(
        name: IncomingCallScreen.routeName,
        page: () => const IncomingCallScreen(),
        fullscreenDialog: true,
        opaque: true,
        transition: Transition.fade,
      ),
      GetPage(
        name: ActiveCallScreen.routeName,
        page: () => const ActiveCallScreen(),
        fullscreenDialog: true,
        opaque: true,
        transition: Transition.fade,
      ),
    ];
  }

  static CallController get controller => Get.find<CallController>();

  /// Gates Android permissions needed for **killed / background** incoming calls.
  ///
  /// Must run after [runApp] when an Activity exists (host calls from Home).
  ///
  /// **1. POST_NOTIFICATIONS (Android 13+)** — system Allow/Deny dialog.
  /// **2. Full-screen intent (Android 14+ only)** — in-app explain dialog first;
  /// Settings opens only when the user taps **Open Settings**.
  static Future<void> ensureAndroidCallPermissions() async {
    if (!Platform.isAndroid) {
      AgoraCallLogger.kill('COLD_START', 'call permissions skipped — not Android');
      return;
    }
    if (!_initialized) {
      AgoraCallLogger.kill(
        'COLD_START',
        'call permissions skipped — AgoraCalling not initialized yet',
      );
      return;
    }
    final hostUi = Get.find<AgoraCallingConfig>().ensureCallPermissionsUi;
    if (hostUi == null) {
      AgoraCallLogger.kill('COLD_START', 'call permissions skipped — no host UI');
      return;
    }
    AgoraCallLogger.kill('COLD_START', 'call permissions — host UI');
    await hostUi();
  }

  /// Whether Android full-screen incoming-call intent is allowed (14+).
  static Future<bool> isFullScreenIntentGranted() {
    return FullScreenCallPermissionPrompt.isGranted();
  }

  /// Opens the system screen to enable full-screen notifications for calls.
  static Future<void> openFullScreenIntentSettings() {
    return FullScreenCallPermissionPrompt.openSettings();
  }

  static Future<void> registerVoipToken(String token) async {
    if (!_initialized) {
      AgoraCallLogger.d('[AGORA_API] registerVoipToken skipped — package not yet '
          'initialized (call AgoraCalling.init first)');
      return;
    }
    if (token.isEmpty) {
      AgoraCallLogger.d('[AGORA_API] registerVoipToken skipped — empty token');
      return;
    }
    final api = Get.find<CallApiService>();
    final cfg = Get.find<AgoraCallingConfig>();
    AgoraCallLogger.d('[AGORA_API] registerVoipToken len=${token.length} '
        'prefix=${token.substring(0, token.length < 8 ? token.length : 8)}…');
    try {
      await api.registerVoipToken(token);
      AgoraCallLogger.d('[AGORA_API] registerVoipToken OK — backend should now '
          'have a VoIP token for this user');
    } catch (e, st) {
      AgoraCallLogger.d('[AGORA_API] registerVoipToken FAILED — backend will not '
          'have a VoIP token, iOS incoming calls in background/killed state '
          'WILL NOT ring. error=$e\n$st');
    }
    final hook = cfg.onVoipTokenChanged;
    if (hook != null) {
      try {
        await hook(token);
      } catch (_) {}
    }
  }

  static void dispatchExternalIncomingCall(Map<String, dynamic> data) {
    if (!_initialized) return;
    final notif = Get.find<AgoraCallingNotificationService>();
    notif.injectExternalIncomingCall(data);
  }
}
