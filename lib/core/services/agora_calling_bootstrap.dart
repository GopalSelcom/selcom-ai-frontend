import 'package:agora_calling_package/agora_calling_package.dart';

import '../config/app_config.dart';
import '../network/api_constants.dart';
import '../network/headers.dart';
import '../utils/app_logger.dart';
import 'call_permission_prompt_service.dart';
import 'session_auth_service.dart';

/// Wires `agora_calling_package` for the Selcom Go (rider) app.
///
/// All endpoints + auth shape come from the brain doc
/// `brain/docs/AGORA-FRONTEND-GUIDE.md`. The driver app uses a different
/// bootstrap (different paths, `access_token` header, `localRole.driver`).
class AgoraCallingBootstrap {
  AgoraCallingBootstrap._();

  /// Keep these aligned with the values passed from the FCM background isolate.
  static const String fcmBackgroundCallKitAppName = 'Selcom Go';
  static const String iosCallKitIconName = '';
  static const String callKitCallIdNamespace = 'agora-call:';

  /// Idempotent. Safe to call multiple times.
  static Future<void> init() async {
    await AgoraCalling.init(
      AgoraCallingConfig(
        appId: AppConfig.agoraAppId,
        baseUrl: AppConfig.apiHost,
        // Do not pass bare `commonHeaders` — ensure session is loaded from
        // secure storage first (killed-state CallKit Accept can fire before
        // splash). See delivery_agent_app/docs/AGORA_CALLING_BACKGROUND_FIX.md.
        getAuthHeaders: _authHeadersForCalling,
        localRole: CallParticipantRole.rider,
        appName: fcmBackgroundCallKitAppName,
        iosCallKitIconName: iosCallKitIconName,
        callKitCallIdNamespace: callKitCallIdNamespace,
        callerRingbackAsset: 'assets/sound/ringback.mp3',
        ensureCallPermissionsUi:
            CallPermissionPromptService.ensureAndroidCallPermissions,
        endpoints: CallEndpoints(
          tokenPath: (rideId) =>
              '${AppConfig.apiPathPrefix}/v4/go/rides/$rideId/call/token',
          cancelPath: (rideId) =>
              '${AppConfig.apiPathPrefix}/v4/go/rides/$rideId/call/cancel',
          voipTokenPath: '${AppConfig.apiPathPrefix}/v4/go/user/voip-token',
        ),
        // Rider only ever receives calls from drivers; this default keeps the
        // CallKit / heads-up surface neutral when `caller_name` is missing.
        peerNameResolver: (_) => 'Your Rider',
      ),
    );
  }

  /// Ensures saved auth is readable, then returns normal API headers.
  static Future<Map<String, String>> _authHeadersForCalling() async {
    await SessionAuthService.instance.ensureAccessTokenLoaded();
    final headers = await commonHeaders(accessTokenRequired: true);
    AppLogger.d(
      '[AGORA_AUTH] getAuthHeaders '
      'access_token=${_tokenDebugLabel(headers[Params.accessToken] ?? '')} '
      'authorization=${_tokenDebugLabel(_stripBearer(headers[Params.authorization] ?? ''))}',
      tag: 'AGORA_AUTH',
    );
    return headers;
  }

  static String _stripBearer(String value) {
    const prefix = 'Bearer ';
    if (value.startsWith(prefix)) {
      return value.substring(prefix.length);
    }
    return value;
  }

  static String _tokenDebugLabel(String token) {
    final t = token.trim();
    if (t.isEmpty) return 'present=false len=0';
    final prefixLen = t.length < 8 ? t.length : 8;
    return 'present=true len=${t.length} prefix=${t.substring(0, prefixLen)}…';
  }
}
