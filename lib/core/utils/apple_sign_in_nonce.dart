import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates a cryptographically secure nonce for Apple Sign-In.
///
/// Firebase expects the SHA-256 hash of this value to be sent to Apple, while
/// the raw nonce is passed to [OAuthProvider.credential].
String generateAppleSignInNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

/// Returns the SHA-256 hex digest of [input] for Apple's nonce parameter.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}
