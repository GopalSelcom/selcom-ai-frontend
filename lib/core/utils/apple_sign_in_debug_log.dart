import 'package:flutter/foundation.dart';

/// Debug-only Apple Sign-In tracing. Never log email, names, tokens, or nonces.
void appleSignInDebugLog(
  String step, {
  Map<String, Object?> metadata = const {},
}) {
  if (!kDebugMode) return;

  if (metadata.isEmpty) {
    debugPrint('[AppleSignIn] $step');
    return;
  }

  final details = metadata.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}')
      .join(' ');

  debugPrint('[AppleSignIn] $step | $details');
}
