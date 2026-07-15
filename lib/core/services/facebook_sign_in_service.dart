import 'dart:io' show Platform;

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

class FacebookSignInService {
  Future<FacebookSignInResult> signIn() async {
    try {
      // Firebase Limited Login requires a nonce: send SHA-256 to Facebook, keep
      // the raw value for [OAuthCredential.rawNonce] when building the credential.
      final rawNonce = generateAppleSignInNonce();
      final hashedNonce = sha256ofString(rawNonce);

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
        loginBehavior: LoginBehavior.nativeWithFallback,
        loginTracking: _loginTracking,
        nonce: hashedNonce,
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

  /// iOS returns a [LimitedToken] (OIDC JWT) under Limited Login / ATT;
  /// Android keeps classic Graph API access tokens.
  LoginTracking get _loginTracking {
    if (!kIsWeb && Platform.isIOS) {
      return LoginTracking.limited;
    }
    return LoginTracking.enabled;
  }
}
