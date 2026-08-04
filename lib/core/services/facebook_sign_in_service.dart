import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';
import '../utils/apple_sign_in_nonce.dart';

enum FacebookSignInErrorType { cancelled, failed, unknown }

class FacebookSignInServiceException implements Exception {
  const FacebookSignInServiceException(this.type, [this.message]);

  final FacebookSignInErrorType type;
  final String? message;
}

/// Facebook login payload for Firebase auth.
///
/// [rawNonce] must be the unhashed value passed to Firebase when the token is
/// a [LimitedToken] OIDC JWT (iOS Limited Login).
class FacebookSignInResult {
  const FacebookSignInResult({
    required this.accessToken,
    required this.rawNonce,
  });

  final AccessToken accessToken;
  final String rawNonce;
}

class FacebookSignInService {
  static const _logTag = 'FacebookSignIn';

  Future<FacebookSignInResult> signIn() async {
    try {
      // Firebase Limited Login requires a nonce: send SHA-256 to Facebook, keep
      // the raw value for [OAuthCredential.rawNonce] when building the credential.
      final rawNonce = generateAppleSignInNonce();
      final hashedNonce = sha256ofString(rawNonce);
      final loginTracking = await _resolveLoginTracking();

      // Never log tokens/nonces. Use these lines with iOS [FB_LOGIN_NATIVE] to
      // diagnose native SSO handoff (callback missing => handoff failed).
      AppLogger.d(
        'login_start | platform=${kIsWeb ? 'web' : Platform.operatingSystem} '
        'tracking=${loginTracking.name} behavior=${_loginBehavior.name}',
        tag: _logTag,
      );

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: const ['public_profile', 'email'],
        // Native Facebook app when installed + classic tracking; otherwise web.
        loginBehavior: _loginBehavior,
        loginTracking: loginTracking,
        nonce: hashedNonce,
      );

      AppLogger.d(
        'login_result | status=${result.status.name} message=${result.message} '
        'tokenType=${result.accessToken?.type.name} '
        'tokenNull=${result.accessToken == null}',
        tag: _logTag,
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken;
          if (accessToken == null) {
            AppLogger.d('login_failed_null_token', tag: _logTag);
            throw const FacebookSignInServiceException(
              FacebookSignInErrorType.failed,
              'Access token is null.',
            );
          }
          return FacebookSignInResult(
            accessToken: accessToken,
            rawNonce: rawNonce,
          );
        case LoginStatus.cancelled:
          AppLogger.d(
            'login_cancelled | If ATT granted and no iOS [FB_LOGIN_NATIVE] '
            'openURL, native SSO handoff likely never returned.',
            tag: _logTag,
          );
          throw const FacebookSignInServiceException(
            FacebookSignInErrorType.cancelled,
          );
        case LoginStatus.failed:
          AppLogger.d(
            'login_failed | sdkMessage=${result.message} | If ATT granted, '
            'tracking=enabled, and no iOS [FB_LOGIN_NATIVE] openURL, treat as '
            'native SSO handoff failure (not missing Meta Login setup).',
            tag: _logTag,
          );
          throw FacebookSignInServiceException(
            FacebookSignInErrorType.failed,
            result.message,
          );
        default:
          AppLogger.d(
            'login_unknown_status | status=${result.status.name}',
            tag: _logTag,
          );
          throw const FacebookSignInServiceException(
            FacebookSignInErrorType.unknown,
          );
      }
    } catch (e) {
      if (e is FacebookSignInServiceException) rethrow;
      AppLogger.d(
        'login_exception | type=${e.runtimeType}',
        tag: _logTag,
      );
      throw FacebookSignInServiceException(
        FacebookSignInErrorType.unknown,
        e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }

  LoginBehavior get _loginBehavior => LoginBehavior.nativeWithFallback;

  /// iOS: classic tracking (native Facebook app) when ATT is granted; Limited
  /// Login (web / OIDC JWT) when ATT is denied or unavailable. Android keeps
  /// classic Graph API access tokens.
  Future<LoginTracking> _resolveLoginTracking() async {
    if (kIsWeb || !Platform.isIOS) {
      AppLogger.d(
        'tracking_resolved | platform=${kIsWeb ? 'web' : Platform.operatingSystem} '
        'tracking=${LoginTracking.enabled.name} att=n/a',
        tag: _logTag,
      );
      return LoginTracking.enabled;
    }

    var status = await Permission.appTrackingTransparency.status;
    AppLogger.d('att_status | status=${status.name}', tag: _logTag);
    if (status.isDenied) {
      status = await Permission.appTrackingTransparency.request();
      AppLogger.d('att_after_request | status=${status.name}', tag: _logTag);
    }

    final tracking =
        status.isGranted ? LoginTracking.enabled : LoginTracking.limited;
    AppLogger.d(
      'tracking_resolved | platform=ios att=${status.name} '
      'tracking=${tracking.name}',
      tag: _logTag,
    );
    return tracking;
  }
}
