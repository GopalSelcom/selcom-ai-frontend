import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/features/profile/presentation/screens/profile_screen.dart';
import '../../routes/app_routes.dart';

class DeepLinkManager {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void initializeDeepLinks() async {
    // 1. Handle link when app is opened from a cold start (completely closed)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleRouting(initialLink);
      }
    } catch (e) {
      debugPrint("Failed to get initial deep link: $e");
    }

    // 2. Handle link when app is already open in the background
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleRouting(uri);
      },
      onError: (err) {
        debugPrint("Stream error: $err");
      },
    );
  }

  void _handleRouting(Uri uri) {
    debugPrint("Intercepted deep link URL: $uri");

    // // Parse the path (e.g., /pay or /profile)
    // String path = uri.path;
    //
    // // Read query parameters (e.g., ?transaction_id=123)
    // Map<String, String> params = uri.queryParameters;
    // Get.to(() => ProfileScreen());
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
