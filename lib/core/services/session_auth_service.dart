import '../utils/app_logger.dart';
import 'storage_service.dart';

/// Keeps auth tokens warm for Agora call-signaling when the app wakes from a
/// killed/background state.
///
/// CallKit Accept can fire before splash restores the session. Preloading in
/// [main] and calling [ensureAccessTokenLoaded] from the Agora auth-header
/// wrapper mirrors the driver-app fix in
/// `delivery_agent_app/docs/AGORA_CALLING_BACKGROUND_FIX.md`.
class SessionAuthService {
  SessionAuthService._();

  static final SessionAuthService instance = SessionAuthService._();

  String? _accessToken;

  /// Reads saved tokens from secure storage during startup, before
  /// [AgoraCallingBootstrap.init], so background Accept can mint RTC tokens.
  Future<void> preloadFromStorage() async {
    final storage = StorageService();
    _accessToken = await storage.readAccessToken();
    AppLogger.d(
      '[USER_AUTH] preloadFromStorage: '
      'access_token=${_tokenDebugLabel(_accessToken)}',
      tag: 'USER_AUTH',
    );
  }

  /// Reloads tokens from disk when the in-memory cache is still empty.
  Future<void> ensureAccessTokenLoaded() async {
    if ((_accessToken ?? '').trim().isNotEmpty) return;

    await preloadFromStorage();
    AppLogger.d(
      '[USER_AUTH] ensureAccessTokenLoaded after storage read: '
      'access_token=${_tokenDebugLabel(_accessToken)}',
      tag: 'USER_AUTH',
    );
  }

  /// Drops the in-memory JWT cache after [StorageService.deleteAll].
  ///
  /// Without this, Agora/auth helpers could still read a stale token until
  /// process restart even though Hive was cleared.
  void clearInMemorySession() {
    _accessToken = null;
    AppLogger.d(
      '[USER_AUTH] clearInMemorySession: access_token cleared',
      tag: 'USER_AUTH',
    );
  }

  static String _tokenDebugLabel(String? token) {
    final t = token?.trim() ?? '';
    if (t.isEmpty) return 'present=false len=0';
    final prefixLen = t.length < 8 ? t.length : 8;
    return 'present=true len=${t.length} prefix=${t.substring(0, prefixLen)}…';
  }
}
