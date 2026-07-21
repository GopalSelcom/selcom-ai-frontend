/// Configuration class for the Selcom ID App-to-App SSO workflow.
///
/// Contains client credentials, redirection settings, and custom store configurations.
class SelcomAuthConfig {
  /// Unique client identifier provided by Selcom.
  final String clientId;

  /// The custom URI scheme that the third-party app uses to receive
  /// deep links (e.g., `zomato`, `myapp`).
  ///
  /// Do not include `://` in the scheme name (e.g., use `'zomato'` instead of `'zomato://'`).
  final String redirectScheme;

  /// Additional parameters to pass during authorization.
  ///
  /// Useful for specifying state, scopes, flow flags, etc.
  final Map<String, String>? additionalParams;

  /// The custom scheme used by the Selcom ID main app.
  /// Defaults to `'selcomid'`.
  final String selcomAppScheme;

  /// Play Store package name for the Selcom ID app.
  /// Defaults to `'com.selcom.id'`.
  final String androidPackageName;

  /// App Store ID for the Selcom ID app.
  /// Defaults to `'1234567890'`.
  final String iosAppStoreId;

  const SelcomAuthConfig({
    required this.clientId,
    required this.redirectScheme,
    this.additionalParams,
    this.selcomAppScheme = 'selcomid',
    this.androidPackageName = 'com.selcom.id',
    this.iosAppStoreId = '1234567890',
  });

  /// Builds the URL used to launch the Selcom ID main app.
  ///
  /// Appends [clientId], [redirectScheme], and [additionalParams] as secure query params.
  Uri get authUri {
    final queryParameters = <String, String>{
      'client_id': clientId,
      'redirect_scheme': redirectScheme,
      ...?additionalParams,
    };

    return Uri(
      scheme: selcomAppScheme,
      host: 'auth',
      queryParameters: queryParameters,
    );
  }

  /// The Play Store link for Android devices.
  Uri get playStoreUri => Uri.parse('market://details?id=$androidPackageName');

  /// Fallback web Play Store link if market:// details scheme fails.
  Uri get playStoreWebUri => Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName');

  /// The App Store link for iOS devices.
  Uri get appStoreUri => Uri.parse('https://apps.apple.com/app/selcom-id/id$iosAppStoreId');
}
