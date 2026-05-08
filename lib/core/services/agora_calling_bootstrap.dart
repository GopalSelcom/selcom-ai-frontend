import 'package:agora_calling_package/agora_calling_package.dart';

import '../config/app_config.dart';
import '../network/headers.dart';

/// Wires `agora_calling_package` for the Selcom Go (rider) app.
///
/// All endpoints + auth shape come from the brain doc
/// `brain/docs/AGORA-FRONTEND-GUIDE.md`. The driver app uses a different
/// bootstrap (different paths, `access_token` header, `localRole.driver`).
class AgoraCallingBootstrap {
  AgoraCallingBootstrap._();

  /// Idempotent. Safe to call multiple times.
  static Future<void> init() async {
    await AgoraCalling.init(
      AgoraCallingConfig(
        appId: AppConfig.agoraAppId,
        baseUrl: AppConfig.baseUrl,
        getAuthHeaders: () async => commonHeaders(accessTokenRequired: true),
        localRole: CallParticipantRole.rider,
        appName: 'Selcom Go',
        endpoints: CallEndpoints(
          tokenPath: (rideId) => '/v4/go/rides/$rideId/call/token',
          cancelPath: (rideId) => '/v4/go/rides/$rideId/call/cancel',
          voipTokenPath: '/v4/go/user/voip-token',
        ),
        // Rider only ever receives calls from drivers; this default keeps the
        // CallKit / heads-up surface neutral when `caller_name` is missing.
        peerNameResolver: (_) => 'Your Driver',
      ),
    );
  }
}
