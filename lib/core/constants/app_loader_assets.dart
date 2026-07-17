/// Lottie and image paths for global / inline loaders.
class AppLoaderAssets {
  AppLoaderAssets._();

  static const String _lotties = 'assets/lottie';

  static const String overlayLoaderLottie = '$_lotties/app_loader_overlay.json';

  /// Wallet / payment top-up success (ported from Duka Direct bill-pay success).
  static const String paymentSuccessLottie = '$_lotties/payment_success.json';
  static const String confettiLottie = '$_lotties/confetti.json';
}
