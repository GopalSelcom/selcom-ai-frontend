import 'agora_rtc_join_credentials.dart';

/// Supplies RTC join credentials for a ride-scoped call.
///
/// Implementations live under `data/`. The host app wires one provider when
/// constructing [AgoraVoiceEngineService].
abstract class AgoraVoiceTokenProvider {
  Future<AgoraRtcJoinCredentials> fetchCredentials({required String rideId});
}
