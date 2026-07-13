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
      // One nonce per sign-in attempt; Firebase Limited Login requires the raw
      // value to match the SHA-256 hash sent to Facebook on limited flows.
      final rawNonce = generateAppleSignInNonce();
      final hashedNonce = sha256ofString(rawNonce);

      if (!kIsWeb && Platform.isIOS) {
        return _signInIos(rawNonce: rawNonce, hashedNonce: hashedNonce);
      }

      return _loginAndMap(
        request: const _FacebookLoginRequest(
          permissions: ['email', 'public_profile'],
          loginTracking: LoginTracking.enabled,
        ),
        rawNonce: rawNonce,
      );
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

  /// iOS: ATT denied → limited login. ATT allowed → classic first, then limited
  /// fallback when Facebook still returns a [LimitedToken] or classic login fails.
  Future<FacebookSignInResult> _signInIos({
    required String rawNonce,
    required String hashedNonce,
  }) async {
    final primaryRequest = await _iosPrimaryLoginRequest(hashedNonce);

    if (primaryRequest.loginTracking == LoginTracking.limited) {
      return _loginAndMap(request: primaryRequest, rawNonce: rawNonce);
    }

    final classicResult = await _performLogin(primaryRequest);
    if (classicResult.status == LoginStatus.cancelled) {
      throw const FacebookSignInServiceException(
        FacebookSignInErrorType.cancelled,
      );
    }

    final classicToken = classicResult.accessToken;
    if (classicResult.status == LoginStatus.success &&
        classicToken != null &&
        classicToken.type == AccessTokenType.classic) {
      return FacebookSignInResult(
        accessToken: classicToken,
        rawNonce: rawNonce,
      );
    }

    // ATT allowed but Facebook returned LimitedToken without nonce, or classic
    // login failed — retry limited login with the same nonce for Firebase OIDC.
    await FacebookAuth.instance.logOut();
    return _loginAndMap(
      request: _iosLimitedLoginRequest(hashedNonce),
      rawNonce: rawNonce,
    );
  }

  Future<LoginResult> _performLogin(_FacebookLoginRequest request) {
    return FacebookAuth.instance.login(
      permissions: request.permissions,
      loginBehavior: LoginBehavior.nativeWithFallback,
      loginTracking: request.loginTracking,
      nonce: request.hashedNonce,
    );
  }

  Future<FacebookSignInResult> _loginAndMap({
    required _FacebookLoginRequest request,
    required String rawNonce,
  }) async {
    final result = await _performLogin(request);

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
  }

  /// ATT authorized → try classic login first (may open Facebook app).
  /// ATT denied/restricted → limited login only.
  Future<_FacebookLoginRequest> _iosPrimaryLoginRequest(
    String hashedNonce,
  ) async {
    final status = await _resolveAttStatus();
    if (status != TrackingStatus.authorized) {
      return _iosLimitedLoginRequest(hashedNonce);
    }

    return const _FacebookLoginRequest(
      permissions: ['email', 'public_profile'],
      loginTracking: LoginTracking.enabled,
    );
  }

  _FacebookLoginRequest _iosLimitedLoginRequest(String hashedNonce) {
    return _FacebookLoginRequest(
      permissions: const ['email'],
      loginTracking: LoginTracking.limited,
      hashedNonce: hashedNonce,
    );
  }

  Future<TrackingStatus> _resolveAttStatus() async {
    var status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      status = await AppTrackingTransparency.requestTrackingAuthorization();
    }
    return status;
  }
}
