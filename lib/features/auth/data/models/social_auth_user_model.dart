import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/social_auth_user.dart';

class SocialAuthUserModel extends SocialAuthUser {
  const SocialAuthUserModel({
    required super.uid,
    super.email,
    super.displayName,
    super.photoURL,
    super.isNewUser,
  });

  factory SocialAuthUserModel.fromFirebaseUser({
    required User user,
    required bool isNewUser,
    String? emailOverride,
    String? displayNameOverride,
  }) {
    return SocialAuthUserModel(
      uid: user.uid,
      email: emailOverride ?? user.email,
      displayName: displayNameOverride ?? user.displayName,
      photoURL: user.photoURL,
      isNewUser: isNewUser,
    );
  }
}
