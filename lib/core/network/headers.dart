import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/storage_service.dart';
import 'api_constants.dart';

/// Builds the common headers map required by every API request.
///
/// Usage:
/// ```dart
/// final headers = await commonHeaders(accessTokenRequired: true);
/// ```
Future<Map<String, String>> commonHeaders({
  required bool accessTokenRequired,
  bool contentTypeEnabled = true,
  bool deviceTokenRequired = true,
  String? refreshToken,
  double? latitude,
  double? longitude,
}) async {
  final Map<String, String> headers = {};
  final deviceInfo = DeviceInfoPlugin();

  // ── Content-Type ──
  if (contentTypeEnabled) {
    headers[HttpHeaders.contentTypeHeader] = Params.applicationJson;
  }

  // ── Location ──
  headers[Params.latitude] = (latitude ?? -6.8109207).toString();
  headers[Params.longitude] = (longitude ?? 39.2860629).toString();

  // ── Language ──
  headers[Params.language] = "en";

  // ── Platform ──
  headers[Params.deviceType] = Platform.isAndroid ? "1" : "2";

  // ── Device UUID ──
  String? appUuid;
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    appUuid = androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    appUuid = iosInfo.identifierForVendor;
  }
  headers[Params.appUuid] = appUuid ?? 'unknown';

  // ── Device Token (FCM) ──
  if (deviceTokenRequired) {
    try {
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      headers[Params.deviceToken] = fcmToken ?? "123";
    } catch (_) {
      headers[Params.deviceToken] = "123";
    }
  } else {
    headers[Params.deviceToken] = "123";
  }

  // ── Encryption ──
  headers[Params.encryptionDisabled] = "true";

  // ── Authorization ──
  if (accessTokenRequired) {
    String authToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      authToken = refreshToken;
    } else {
      authToken =
          await StorageService().read(StorageKeys.authorizationToken) ?? "";
    }
    headers[Params.authorization] = "Bearer $authToken";
  } else {
    headers[Params.authorization] = "";
  }

  // ── Access Token ──
  final accessToken = await StorageService().read(StorageKeys.accessToken);
  if (accessToken != null) {
    headers[Params.accessToken] = accessToken;
  }

  // ── App Metadata ──
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    headers['app_version'] = packageInfo.version;
    headers['app_build_number'] = packageInfo.buildNumber;
  } catch (_) {
    // Package info might not be ready
  }

  return headers;
}
