import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'controllers/call_controller.dart';
import 'models/agora_config.dart';
import 'services/agora_service.dart';
import 'services/call_api_service.dart';
import 'services/notification_service.dart';
import 'ui/screens/active_call_screen.dart';
import 'ui/screens/incoming_call_screen.dart';

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
    if (_initialized) return;
    _initialized = true;

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

    // Subscribe FIRST — see the doc-comment above for the rationale.
    await controller.bootstrap();
    await notif.initialize();
  }

  /// Routes the host app must register on its `GetMaterialApp.getPages`.
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

  /// Registers the iOS PushKit VoIP token with the backend (PATCH to the
  /// configured `voipTokenPath`). Idempotent — host can call repeatedly.
  ///
  /// Host apps wire their PushKit `didUpdate credentials` delegate to forward
  /// the token here. See `brain/docs/AGORA-FRONTEND-GUIDE.md` § 6.5.
  static Future<void> registerVoipToken(String token) async {
    if (!_initialized) {
      if (kDebugMode) {
        debugPrint('[AGORA_API] registerVoipToken skipped — package not yet '
            'initialized (call AgoraCalling.init first)');
      }
      return;
    }
    if (token.isEmpty) {
      if (kDebugMode) {
        debugPrint('[AGORA_API] registerVoipToken skipped — empty token');
      }
      return;
    }
    final api = Get.find<CallApiService>();
    final cfg = Get.find<AgoraCallingConfig>();
    if (kDebugMode) {
      debugPrint('[AGORA_API] registerVoipToken len=${token.length} '
          'prefix=${token.substring(0, token.length < 8 ? token.length : 8)}…');
    }
    try {
      await api.registerVoipToken(token);
      if (kDebugMode) {
        debugPrint('[AGORA_API] registerVoipToken OK — backend should now '
            'have a VoIP token for this user');
      }
    } catch (e, st) {
      // Don't rethrow — the host can retry on the next boot — but DO log
      // loudly so a missing token registration doesn't silently break iOS
      // incoming calls (the most common cause of "no ring on iOS").
      if (kDebugMode) {
        debugPrint('[AGORA_API] registerVoipToken FAILED — backend will not '
            'have a VoIP token, iOS incoming calls in background/killed state '
            'WILL NOT ring. error=$e\n$st');
      }
    }
    final hook = cfg.onVoipTokenChanged;
    if (hook != null) {
      try {
        await hook(token);
      } catch (_) {}
    }
  }

  /// Convenience: forwards an externally-received `incoming_call` payload
  /// (e.g. from the host app's iOS PushKit bridge) into the package as if it
  /// arrived via FCM. Use this only when bypassing the FCM listener path.
  static void dispatchExternalIncomingCall(Map<String, dynamic> data) {
    if (!_initialized) return;
    final notif = Get.find<AgoraCallingNotificationService>();
    notif.injectExternalIncomingCall(data);
  }
}
