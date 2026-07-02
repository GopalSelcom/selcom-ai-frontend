import 'app_logger.dart';

/// Apple Sign-In tracing. Never log email, names, tokens, or nonces.
void appleSignInDebugLog(
  String step, {
  Map<String, Object?> metadata = const {},
}) {
  if (metadata.isEmpty) {
    AppLogger.d(step, tag: 'AppleSignIn');
    return;
  }

  final details = metadata.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}')
      .join(' ');

  AppLogger.d('$step | $details', tag: 'AppleSignIn');
}
