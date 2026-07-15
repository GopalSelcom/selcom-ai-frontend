import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkManager {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void initializeDeepLinks() async {
    debugPrint("[NATIVE_DEEPLINK_LOG] initializeDeepLinks() called [PID: $pid] at [TIME: ${DateTime.now().toIso8601String()}]");

    // 1. Handle link when app is opened from a cold start (completely closed)
    try {
      debugPrint("[NATIVE_DEEPLINK_LOG] Awaiting getInitialLink()... [PID: $pid]");
      final initialLink = await _appLinks.getInitialLink();
      debugPrint("[NATIVE_DEEPLINK_LOG] getInitialLink() result: $initialLink [PID: $pid]");
      if (initialLink != null) {
        _handleRouting(initialLink, "getInitialLink (Cold Start)");
      }
    } catch (e) {
      debugPrint("[NATIVE_DEEPLINK_LOG] Failed to get initial deep link: $e [PID: $pid]");
    }

    // 2. Handle link when app is already open in the background
    debugPrint("[NATIVE_DEEPLINK_LOG] Listening to uriLinkStream... [PID: $pid]");
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint("[NATIVE_DEEPLINK_LOG] uriLinkStream event received: $uri [PID: $pid] at [TIME: ${DateTime.now().toIso8601String()}]");
        _handleRouting(uri, "uriLinkStream (Resumed/Foreground)");
      },
      onError: (err) {
        debugPrint("[NATIVE_DEEPLINK_LOG] uriLinkStream error: $err [PID: $pid]");
      },
    );
  }

  void _handleRouting(Uri uri, String source) {
    debugPrint("[NATIVE_DEEPLINK_LOG] Handling routing for: $uri from source: $source [PID: $pid]");

    // // Parse the path (e.g., /pay or /profile)
    // String path = uri.path;
    //
    // // Read query parameters (e.g., ?transaction_id=123)
    // Map<String, String> params = uri.queryParameters;
    // Get.to(() => ProfileScreen());
  }

  void dispose() {
    debugPrint("[NATIVE_DEEPLINK_LOG] DeepLinkManager disposed [PID: $pid]");
    _linkSubscription?.cancel();
  }
}
