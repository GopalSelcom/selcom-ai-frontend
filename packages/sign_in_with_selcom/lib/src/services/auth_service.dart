import 'dart:async';
import 'dart:developer' as developer;
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/auth_config.dart';
import '../models/auth_result.dart';

/// Service managing the App-to-App deep linking authentication flow.
///
/// Encapsulates URL launching, deep link stream listeners, extraction of URL parameters,
/// and resource cleanup.
class SelcomAuthService {
  /// Internal constructor. Marked visible for testing to allow subclassing and testing.
  @visibleForTesting
  SelcomAuthService.internal({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks() {
    _initDeepLinkListener();
  }

  static SelcomAuthService? _instance;

  /// Retrieves the active singleton instance.
  static SelcomAuthService get instance => _instance ??= SelcomAuthService.internal();

  /// Sets a mock or custom instance of [SelcomAuthService] for unit testing.
  @visibleForTesting
  static void setMockInstance(SelcomAuthService mockInstance) {
    _instance = mockInstance;
  }

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<SelcomAuthResult> _resultController = StreamController<SelcomAuthResult>.broadcast();

  /// Stream of all authentication results parsed from incoming deep links.
  Stream<SelcomAuthResult> get authResults => _resultController.stream;

  SelcomAuthConfig? _activeConfig;
  Uri? _pendingUri;

  /// Initializes the persistent deep link listeners.
  void _initDeepLinkListener() {
    developer.log('[SelcomAuthService] Initializing persistent deep-link listeners.', name: 'selcom_id_auth');

    // 1. Listen to dynamic incoming deep links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        developer.log('[SelcomAuthService] Stream callback received dynamic URI: $uri', name: 'selcom_id_auth');
        _handleIncomingUri(uri);
      },
      onError: (Object err) {
        developer.log('[SelcomAuthService] Stream callback error: $err', name: 'selcom_id_auth');
        _emitResult(SelcomAuthResult.failure('Deep link stream error: ${err.toString()}'));
      },
      cancelOnError: false,
    );

    // 2. Handle initial link (in case the OS terminated the client app)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        developer.log('[SelcomAuthService] getInitialLink received URI: $uri', name: 'selcom_id_auth');
        _handleIncomingUri(uri);
      } else {
        developer.log('[SelcomAuthService] getInitialLink returned null.', name: 'selcom_id_auth');
      }
    }).catchError((Object err) {
      developer.log('[SelcomAuthService] getInitialLink error: $err', name: 'selcom_id_auth');
    });
  }

  /// Registers the authentication configuration.
  ///
  /// This configures the redirect scheme to match against and automatically
  /// processes any cached/pending deep link that matches the scheme.
  void registerConfig(SelcomAuthConfig config) {
    developer.log('[SelcomAuthService] registerConfig called with redirectScheme: ${config.redirectScheme}', name: 'selcom_id_auth');
    _activeConfig = config;

    final pending = _pendingUri;
    if (pending != null) {
      developer.log('[SelcomAuthService] Checking pending URI against registered config: $pending', name: 'selcom_id_auth');
      if (pending.scheme.toLowerCase() == config.redirectScheme.toLowerCase()) {
        _pendingUri = null;
        developer.log('[SelcomAuthService] Pending URI matches registered scheme. Processing...', name: 'selcom_id_auth');
        scheduleMicrotask(() {
          _processUri(pending, config);
        });
      } else {
        developer.log('[SelcomAuthService] Pending URI scheme does not match registered scheme. Clearing cache.', name: 'selcom_id_auth');
        _pendingUri = null;
      }
    }
  }

  /// Launches the Selcom ID Main App to start the App-to-App authentication flow.
  ///
  /// Registers the config, checks for matching pending URIs, and triggers the app launch.
  /// Returns a stream of [SelcomAuthResult] for backward compatibility.
  Stream<SelcomAuthResult> startAuthFlow(SelcomAuthConfig config) {
    developer.log('[SelcomAuthService] startAuthFlow called for clientId: ${config.clientId}', name: 'selcom_id_auth');
    registerConfig(config);

    // Launch Selcom ID App
    _launchSelcomApp(config);

    return _resultController.stream;
  }

  /// Cancels the active authentication flow and notifies subscribers with a cancelled result.
  void cancelAuthFlow() {
    developer.log('[SelcomAuthService] cancelAuthFlow called.', name: 'selcom_id_auth');
    _emitResult(SelcomAuthResult.cancelled());
  }

  /// Dispatches the result to listeners and resets the active configuration.
  void _emitResult(SelcomAuthResult result) {
    developer.log('[SelcomAuthService] Emitting auth result: $result', name: 'selcom_id_auth');
    if (!_resultController.isClosed) {
      _resultController.add(result);
    }
    _activeConfig = null;
  }

  /// Triggers the launch of the Selcom ID Main App with configured URI parameters.
  ///
  /// If launching fails (e.g. app is not installed or scheme is not registered),
  /// emits a [SelcomAuthResult.failure] with message `'AppNotInstalled'`.
  Future<void> _launchSelcomApp(SelcomAuthConfig config) async {
    final uri = config.authUri;
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _emitResult(SelcomAuthResult.failure('AppNotInstalled'));
      }
    } catch (e) {
      developer.log('[SelcomAuthService] Failed to launch Selcom ID main app: $e', name: 'selcom_id_auth');
      _emitResult(SelcomAuthResult.failure('AppNotInstalled'));
    }
  }

  /// Checks whether the Selcom ID main app can be launched via deep linking.
  ///
  /// Notice: For iOS 9+ and Android 11+, the scheme must be declared in LSApplicationQueriesSchemes/Queries
  /// or this will return `false`.
  Future<bool> isSelcomAppInstalled(SelcomAuthConfig config) async {
    try {
      return await canLaunchUrl(config.authUri);
    } catch (_) {
      return false;
    }
  }

  /// Directs the device to the platform-specific store page for the Selcom ID app.
  ///
  /// Returns `true` if redirect succeeded, `false` otherwise.
  Future<bool> openAppStore(SelcomAuthConfig config, {required bool isAndroid}) async {
    final uri = isAndroid ? config.playStoreUri : config.appStoreUri;
    try {
      bool success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // Web store URL fallback for Android if market scheme is unsupported (e.g. emulators)
      if (!success && isAndroid) {
        success = await launchUrl(
          config.playStoreWebUri,
          mode: LaunchMode.externalApplication,
        );
      }
      return success;
    } catch (e) {
      developer.log('[SelcomAuthService] Error launching store redirect: $e', name: 'selcom_id_auth');
      if (isAndroid) {
        try {
          return await launchUrl(
            config.playStoreWebUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {}
      }
      return false;
    }
  }

  /// Processes a single captured deep link URI.
  ///
  /// If config is active, processes the URI immediately. Otherwise caches it.
  void _handleIncomingUri(Uri uri) {
    final config = _activeConfig;
    if (config == null) {
      developer.log('[SelcomAuthService] No active auth config. Caching URI: $uri', name: 'selcom_id_auth');
      _pendingUri = uri;
      return;
    }

    _processUri(uri, config);
  }

  /// Parses a deep link URI based on the active config.
  void _processUri(Uri uri, SelcomAuthConfig config) {
    developer.log('[SelcomAuthService] Processing URI: $uri against redirectScheme: ${config.redirectScheme}', name: 'selcom_id_auth');
    
    if (uri.scheme.toLowerCase() != config.redirectScheme.toLowerCase()) {
      developer.log('[SelcomAuthService] Scheme mismatch. Ignoring.', name: 'selcom_id_auth');
      return;
    }

    final path = uri.host.toLowerCase();
    developer.log('[SelcomAuthService] Extracted path: $path', name: 'selcom_id_auth');

    if (path == 'success') {
      final data = uri.queryParameters['data'];
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];

      developer.log('[SelcomAuthService] Extracted parameters - data: $data, token: $token, error: $error', name: 'selcom_id_auth');

      if (data != null && data.isNotEmpty) {
        try {
          final decodedData = Uri.decodeComponent(data);
          developer.log('[SelcomAuthService] Successfully decoded data parameter.', name: 'selcom_id_auth');
          _emitResult(SelcomAuthResult.success(decodedData));
        } catch (e) {
          developer.log('[SelcomAuthService] Failed to decode data parameter: $e', name: 'selcom_id_auth');
          _emitResult(SelcomAuthResult.failure('Failed to decode data: $e'));
        }
      } else if (token != null && token.isNotEmpty) {
        _emitResult(SelcomAuthResult.success(token));
      } else if (error != null && error.isNotEmpty) {
        _emitResult(SelcomAuthResult.failure(error));
      } else {
        _emitResult(SelcomAuthResult.failure('Callback received but no data or token parameter found.'));
      }
    } else if (path == 'error') {
      final error = uri.queryParameters['error'] ?? uri.queryParameters['message'] ?? 'Authentication failed';
      _emitResult(SelcomAuthResult.failure(error));
    } else if (path == 'cancel' || path == 'cancelled') {
      _emitResult(SelcomAuthResult.cancelled());
    } else {
      developer.log('[SelcomAuthService] Unknown path "$path". Ignoring.', name: 'selcom_id_auth');
    }
  }

  /// Cleans up any resources.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    if (!_resultController.isClosed) {
      _resultController.close();
    }
  }
}
