import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/utils/apple_sign_in_debug_log.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  AuthCredential buildAppleCredential({
    required AuthorizationCredentialAppleID appleCredential,
    required String rawNonce,
  }) {
    final idToken = appleCredential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      appleSignInDebugLog(
        'firebase_credential_build_failed',
        metadata: {'reason': 'missing_identity_token'},
      );
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Missing Apple identity token.',
      );
    }

    appleSignInDebugLog('firebase_oauth_credential_built');
    return OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    appleSignInDebugLog('firebase_sign_in_with_credential_start');
    try {
      final result = await _firebaseAuth.signInWithCredential(credential);
      appleSignInDebugLog(
        'firebase_sign_in_with_credential_success',
        metadata: {
          'hasFirebaseUser': result.user != null,
          'isNewUser': result.additionalUserInfo?.isNewUser ?? false,
          'hasFirebaseEmail': _hasValue(result.user?.email),
          'hasFirebaseDisplayName': _hasValue(result.user?.displayName),
        },
      );
      return result;
    } on FirebaseAuthException catch (e) {
      appleSignInDebugLog(
        'firebase_sign_in_with_credential_failed',
        metadata: {'firebaseCode': e.code},
      );
      rethrow;
    }
  }

  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user to link.',
      );
    }
    appleSignInDebugLog('firebase_link_with_credential_start');
    try {
      final result = await user.linkWithCredential(credential);
      appleSignInDebugLog('firebase_link_with_credential_success');
      return result;
    } on FirebaseAuthException catch (e) {
      appleSignInDebugLog(
        'firebase_link_with_credential_failed',
        metadata: {'firebaseCode': e.code},
      );
      rethrow;
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
