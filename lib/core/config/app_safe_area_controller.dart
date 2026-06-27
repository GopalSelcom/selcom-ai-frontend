/// Central configuration for adaptive bottom safe area behavior.
///
/// Set [forceIosStyle] at app start for testing or QA overrides.
class AppSafeAreaController {
  AppSafeAreaController._();

  static final AppSafeAreaController instance = AppSafeAreaController._();

  /// When true, applies fixed iOS-style bottom spacing globally.
  bool forceIosStyle = false;
}
