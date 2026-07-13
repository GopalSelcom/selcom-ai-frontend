import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

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

class _FacebookLoginRequest {
  const _FacebookLoginRequest({
    required this.permissions,
    required this.loginTracking,
    this.hashedNonce,
  });

  final List<String> permissions;
  final LoginTracking loginTracking;
  final String? hashedNonce;
}

class FacebookSignInService {
  Future<FacebookSignInResult> signIn() async {
    try {
      // Keep raw nonce for Firebase Limited Login; pass SHA-256 to Facebook only
      // when iOS uses LoginTracking.limited.
      final rawNonce = generateAppleSignInNonce();
      final hashedNonce = sha256ofString(rawNonce);
      final request = await _buildLoginRequest(hashedNonce);

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: request.permissions,
        loginBehavior: LoginBehavior.nativeWithFallback,
        loginTracking: request.loginTracking,
        nonce: request.hashedNonce,
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken;
          if (accessToken == null) {
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
          throw const FacebookSignInServiceException(
            FacebookSignInErrorType.cancelled,
          );
        case LoginStatus.failed:
          throw FacebookSignInServiceException(
            FacebookSignInErrorType.failed,
            result.message,
          );
        default:
          throw const FacebookSignInServiceException(
            FacebookSignInErrorType.unknown,
          );
      }
    } catch (e) {
      if (e is FacebookSignInServiceException) rethrow;
      throw FacebookSignInServiceException(
        FacebookSignInErrorType.unknown,
        e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }

  Future<_FacebookLoginRequest> _buildLoginRequest(String hashedNonce) async {
    if (!kIsWeb && Platform.isIOS) {
      return _iosLoginRequest(hashedNonce);
    }

    return const _FacebookLoginRequest(
      permissions: ['email', 'public_profile'],
      loginTracking: LoginTracking.enabled,
    );
  }

  /// ATT authorized → classic login (may open Facebook app).
  /// ATT denied → limited login (in-app sheet + nonce for Firebase OIDC).
  Future<_FacebookLoginRequest> _iosLoginRequest(String hashedNonce) async {
    var status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      status = await AppTrackingTransparency.requestTrackingAuthorization();
    }

    final useLimitedLogin = status != TrackingStatus.authorized;
    if (useLimitedLogin) {
      return _FacebookLoginRequest(
        permissions: const ['email'],
        loginTracking: LoginTracking.limited,
        hashedNonce: hashedNonce,
      );
    }

    return const _FacebookLoginRequest(
      permissions: ['email', 'public_profile'],
      loginTracking: LoginTracking.enabled,
    );
  }
}
