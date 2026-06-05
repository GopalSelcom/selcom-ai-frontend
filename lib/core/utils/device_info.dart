import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:selcom_rides_frontend/core/services/storage_service.dart';

import '../services/error_reporting/error_reporter.dart';

class DeviceInfo {
  static final DeviceInfo _instance = DeviceInfo._internal();

  factory DeviceInfo() => _instance;

  DeviceInfo._internal();

  late AndroidDeviceInfo _android;
  late IosDeviceInfo _ios;

  AndroidDeviceInfo? get android => Platform.isAndroid ? _android : null;

  IosDeviceInfo? get ios => Platform.isIOS ? _ios : null;

  late String _token;
  late String _udid;

  String get token => _token;

  String get udid => _udid;

  bool get isPhysicalDevice {
    if (Platform.isAndroid) return android?.isPhysicalDevice ?? false;
    if (Platform.isIOS) return ios?.isPhysicalDevice ?? false;
    return false;
  }

  Future<void> get() async {
    if (Platform.isAndroid) {
      _android = await DeviceInfoPlugin().androidInfo;
    } else if (Platform.isIOS) {
      _ios = await DeviceInfoPlugin().iosInfo;
    }

    _token = await getToken(freshToken: true, recursive: false);
    _udid = await getUdid();

    // Setup token refresh listener once
    _setupTokenRefreshListener();
  }

  /// Listen for FCM token updates and sync with local storage
  void _setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) {
          _token = newToken;
          debugPrint("DeviceInfo: FCM token refreshed and updated: $newToken");

          // Also update in local storage
          StorageService().write(StorageKeys.fcmToken, newToken);
        })
        .onError((error) {
          debugPrint("Error in token refresh listener: $error");
        });
  }

  Future<String> _getFreshToken({
    required bool freshToken,
    required bool recursive,
  }) async {
    try {
      // On iOS, use getToken() instead of getAPNSToken()
      // getToken() internally waits for APNS token and returns FCM token
      String? freshDeviceToken = await FirebaseMessaging.instance.getToken();

      debugPrint("FCM token received: $freshDeviceToken");

      if (freshDeviceToken?.isNotEmpty ?? false) {
        await StorageService().write(
          StorageKeys.fcmToken,
          freshDeviceToken ?? "",
        );
        return freshDeviceToken ?? "";
      } else {
        if (recursive) {
          return await _getFreshToken(
            recursive: recursive,
            freshToken: freshToken,
          );
        } else {
          return "";
        }
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "DeviceInfo._getFreshToken failed",
        extraData: [
          {"freshToken": freshToken, "recursive": recursive},
        ],
      );

      // Check if it's an APNS token error on iOS
      if (e.toString().contains('APNS token has not been received') ||
          e.toString().contains('apns-token-not-set')) {
        debugPrint(
          "APNS token not ready yet on iOS - will retry in background",
        );
        // Silent fail for APNS token not set - this is expected on iOS
        // Will retry in background or use cached token
        return "";
      }

      // Log other errors
      debugPrint("getDeviceToken Exception: $e");

      if (recursive) {
        return await _getFreshToken(
          freshToken: freshToken,
          recursive: recursive,
        );
      } else {
        return "";
      }
    }
  }

  Future<String> _getLocalToken() async {
    var localToken = await StorageService().read(StorageKeys.fcmToken);

    localToken = localToken ?? "";

    _token = localToken;

    return localToken;
  }

  Future<String> getToken({
    required bool freshToken,
    required bool recursive,
  }) async {
    String deviceToken = "";

    if (freshToken) {
      deviceToken = await _getFreshToken(
        recursive: recursive,
        freshToken: freshToken,
      );
      if (deviceToken.isEmpty) {
        deviceToken = await _getLocalToken();
      }
    } else {
      deviceToken = await _getLocalToken();
      if (deviceToken.isEmpty) {
        deviceToken = await _getFreshToken(
          recursive: recursive,
          freshToken: freshToken,
        );
      }
    }

    _token = deviceToken;

    return deviceToken;
  }

  Future<String> getUdid() async {
    try {
      String? localIdentifier = await StorageService().read(
        StorageKeys.uniqueDeviceId,
      );

      if (localIdentifier?.isNotEmpty ?? false) return localIdentifier!;

      String identifier = "";
      if (Platform.isAndroid) {
        identifier = await AndroidId().getId() ?? "";
      } else if (Platform.isIOS) {
        identifier = ios?.identifierForVendor ?? "";
      }

      if (identifier.isNotEmpty) {
        await StorageService().write(StorageKeys.uniqueDeviceId, identifier);
      }

      debugPrint("UDID $identifier");
      return identifier;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "DeviceInfo.getUdid failed",
      );

      debugPrint('Failed to get UDID: $e');
      return "";
    }
  }

  /// Retry getting the FCM token after app initialization
  /// Call this after NotificationSetup().initialize() completes
  /// This runs in the background and won't block app startup
  Future<void> retryGetToken() async {
    // Wait for APNS token to be registered (iOS needs time)
    if (Platform.isIOS) {
      debugPrint("Starting background FCM token fetch on iOS...");

      // Try multiple times with longer delays for APNS token registration
      final delays = [3, 5, 8, 10, 15]; // seconds between retries

      for (int i = 0; i < delays.length; i++) {
        await Future.delayed(Duration(seconds: delays[i]));

        try {
          // Check if APNS token is available first
          String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();

          if (apnsToken != null) {
            debugPrint("APNS token received: $apnsToken");

            // Now get FCM token
            String? freshDeviceToken = await FirebaseMessaging.instance
                .getToken();

            if (freshDeviceToken?.isNotEmpty ?? false) {
              _token = freshDeviceToken!;
              await StorageService().write(
                StorageKeys.fcmToken,
                freshDeviceToken,
              );
              debugPrint(
                "FCM token retrieved successfully (attempt ${i + 1}): $freshDeviceToken",
              );
              return; // Success, exit early
            }
          } else {
            debugPrint("APNS token not available yet (attempt ${i + 1})");
          }
        } catch (e, stackTrace) {
          ErrorReporter.instance.report(
            error: e,
            stackTrace: stackTrace,
            customMessage: "DeviceInfo.retryGetToken (iOS) failed",
            extraData: [
              {"attempt": i + 1},
            ],
          );

          if (e.toString().contains('APNS token has not been received') ||
              e.toString().contains('apns-token-not-set')) {
            debugPrint("APNS token not ready yet (attempt ${i + 1})");
          } else {
            debugPrint(
              "Unexpected error getting FCM token (attempt ${i + 1}): $e",
            );
          }
        }
      }

      debugPrint(
        "FCM token not available after ${delays.length} retries. Will rely on token refresh listener.",
      );
    } else {
      // Android - single retry is usually sufficient
      await Future.delayed(const Duration(seconds: 1));
      try {
        String freshDeviceToken = await getToken(
          freshToken: true,
          recursive: false,
        );
        if (freshDeviceToken.isNotEmpty) {
          _token = freshDeviceToken;
          debugPrint("FCM token retrieved on Android: $freshDeviceToken");
        }
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(
          error: e,
          stackTrace: stackTrace,
          customMessage: "DeviceInfo.retryGetToken (Android) failed",
        );

        debugPrint("Error getting FCM token on Android: $e");
      }
    }
  }
}

String formatHHMMSS(int seconds) {
  int hours = (seconds / 3600).truncate();
  seconds = (seconds % 3600).truncate();
  int minutes = (seconds / 60).truncate();
  String hoursStr = (hours).toString().padLeft(2, '0');
  String minutesStr = (minutes).toString().padLeft(2, '0');
  String secondsStr = (seconds % 60).toString().padLeft(2, '0');
  if (hours == 0) {
    return "$minutesStr:$secondsStr";
  }
  return "$hoursStr:$minutesStr:$secondsStr";
}