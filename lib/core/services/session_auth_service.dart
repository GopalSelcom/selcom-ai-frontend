import 'package:flutter/foundation.dart';

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

  String? _authorizationToken;
  String? _accessToken;

  /// Reads saved tokens from secure storage during startup, before
  /// [AgoraCallingBootstrap.init], so background Accept can mint RTC tokens.
  Future<void> preloadFromStorage() async {
    final storage = StorageService();
    _authorizationToken = await storage.read(StorageKeys.authorizationToken);
    _accessToken = await storage.read(StorageKeys.accessToken);
    if (kDebugMode) {
      debugPrint(
        '[USER_AUTH] preloadFromStorage: '
        'authorization=${_tokenDebugLabel(_authorizationToken)} '
        'access_token=${_tokenDebugLabel(_accessToken)}',
      );
    }
  }

  /// Reloads tokens from disk when the in-memory cache is still empty.
  ///
  /// Rider headers use both `Authorization: Bearer …` and `access_token`; we
  /// treat either as a valid session for the early guard in `_acceptIncoming`.
  Future<void> ensureAccessTokenLoaded() async {
    final hasAuth = (_authorizationToken ?? '').trim().isNotEmpty;
    final hasAccess = (_accessToken ?? '').trim().isNotEmpty;
    if (hasAuth || hasAccess) return;

    await preloadFromStorage();
    if (kDebugMode) {
      debugPrint(
        '[USER_AUTH] ensureAccessTokenLoaded after storage read: '
        'authorization=${_tokenDebugLabel(_authorizationToken)} '
        'access_token=${_tokenDebugLabel(_accessToken)}',
      );
    }
  }

  static String _tokenDebugLabel(String? token) {
    final t = token?.trim() ?? '';
    if (t.isEmpty) return 'present=false len=0';
    final prefixLen = t.length < 8 ? t.length : 8;
    return 'present=true len=${t.length} prefix=${t.substring(0, prefixLen)}…';
  }
}
