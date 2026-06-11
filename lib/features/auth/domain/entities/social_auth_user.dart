class SocialAuthUser {
  const SocialAuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.isNewUser = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isNewUser;
}
