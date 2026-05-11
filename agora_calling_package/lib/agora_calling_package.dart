/// Public API for `agora_calling_package`.
///
/// Audio-only Agora calling, ride-scoped, GetX-based. Designed to be imported
/// into the Selcom Go (rider) and Delivery Agent (driver) apps with the same
/// surface — only the `CallEndpoints` / `localRole` differ per host.
///
/// Aligned with `brain/docs/AGORA-FRONTEND-GUIDE.md`.
///
/// Quick start (rider app):
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> firebaseBg(RemoteMessage m) async {
///   await Firebase.initializeApp();
///   await AgoraCallingNotificationService.firebaseBackgroundHandler(
///     m,
///     iosCallKitIconName: 'CallKitLogo', // asset in ios/Runner/Assets.xcassets
///     callKitCallIdNamespace: 'agora-call:',
///     backgroundCallKitAppName: 'My App', // same as AgoraCallingConfig.appName
///   );
/// }
/// FirebaseMessaging.onBackgroundMessage(firebaseBg);
///
/// await AgoraCalling.init(AgoraCallingConfig(
///   appId: AppConfig.agoraAppId,
///   baseUrl: AppConfig.baseUrl,
///   getAuthHeaders: () async => commonHeaders(accessTokenRequired: true),
///   localRole: CallParticipantRole.rider,
///   appName: 'My App',
///   iosCallKitIconName: 'CallKitLogo',
///   callKitCallIdNamespace: 'agora-call:',
///   endpoints: const CallEndpoints(
///     tokenPath:     riderTokenPath,    // (id) => '/v4/go/rides/$id/call/token'
///     cancelPath:    riderCancelPath,   // (id) => '/v4/go/rides/$id/call/cancel'
///     voipTokenPath: '/v4/go/user/voip-token',
///   ),
/// ));
///
/// // Outgoing
/// await AgoraCalling.controller.placeCall(
///   rideId: ride.id,
///   peerDisplayName: ride.driver.name,
/// );
/// ```
library agora_calling_package;

// Models
export 'models/agora_config.dart';
export 'models/call_model.dart';

// Services (kept exported so host apps can extend if needed)
export 'services/agora_service.dart';
export 'services/call_api_service.dart';
export 'services/notification_service.dart';

// Controllers
export 'controllers/call_controller.dart';

// UI
export 'ui/screens/incoming_call_screen.dart';
export 'ui/screens/active_call_screen.dart';
export 'ui/widgets/call_button.dart';
export 'ui/widgets/call_controls.dart';

// Utils
export 'utils/permissions_helper.dart';
export 'utils/audio_helper.dart';
export 'utils/constants.dart';

// Facade
export 'agora_calling.dart';
