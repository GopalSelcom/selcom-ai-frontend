import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utils/apple_sign_in_debug_log.dart';

enum AppleSignInErrorType {
  cancelled,
  notHandled,
  notInteractive,
  failed,
  unknown,
}

class AppleSignInServiceException implements Exception {
  const AppleSignInServiceException(this.type);

  final AppleSignInErrorType type;
}

/// Wraps the native Apple authorization sheet and returns credentials
/// for Firebase OAuth exchange.
class AppleSignInService {
  /// Requests Apple ID credentials using a SHA-256 hashed [nonce].
  Future<AuthorizationCredentialAppleID> getCredential({
    required String nonce,
  }) async {
    try {
      appleSignInDebugLog('requesting_apple_credential');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      appleSignInDebugLog(
        'apple_credential_received',
        metadata: {
          'hasUserIdentifier': _hasValue(credential.userIdentifier),
          'hasIdentityToken': _hasValue(credential.identityToken),
          'hasEmail': _hasValue(credential.email),
          'hasGivenName': _hasValue(credential.givenName),
          'hasFamilyName': _hasValue(credential.familyName),
        },
      );
      return credential;
    } on SignInWithAppleAuthorizationException catch (e) {
      appleSignInDebugLog(
        'apple_authorization_failed',
        metadata: {
          'authorizationErrorCode': e.code.name,
          'mappedType': _mapAuthorizationCode(e.code).name,
        },
      );
      throw AppleSignInServiceException(_mapAuthorizationCode(e.code));
    } catch (e) {
      appleSignInDebugLog(
        'apple_credential_unexpected_error',
        metadata: {'errorType': e.runtimeType.toString()},
      );
      throw const AppleSignInServiceException(AppleSignInErrorType.unknown);
    }
  }

  AppleSignInErrorType _mapAuthorizationCode(
    AuthorizationErrorCode code,
  ) {
    switch (code) {
      case AuthorizationErrorCode.canceled:
        return AppleSignInErrorType.cancelled;
      case AuthorizationErrorCode.notHandled:
        return AppleSignInErrorType.notHandled;
      case AuthorizationErrorCode.notInteractive:
        return AppleSignInErrorType.notInteractive;
      case AuthorizationErrorCode.failed:
        return AppleSignInErrorType.failed;
      case AuthorizationErrorCode.unknown:
      case AuthorizationErrorCode.invalidResponse:
      case AuthorizationErrorCode.credentialImport:
      case AuthorizationErrorCode.credentialExport:
      case AuthorizationErrorCode.matchedExcludedCredential:
        return AppleSignInErrorType.unknown;
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
