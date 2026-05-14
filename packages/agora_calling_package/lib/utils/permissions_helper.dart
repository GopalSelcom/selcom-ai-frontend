import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Outcome of the gate. UI uses this to decide whether to show an "Open
/// Settings" dialog or proceed.
enum PermissionOutcome { granted, denied, permanentlyDenied }

/// Permissions required for an audio call.
class PermissionsHelper {
  PermissionsHelper._();

  /// Requests microphone permission. Safe to call repeatedly.
  static Future<PermissionOutcome> ensureMicrophone() async {
    final current = await Permission.microphone.status;
    if (current.isGranted) return PermissionOutcome.granted;
    if (current.isPermanentlyDenied || current.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    final result = await Permission.microphone.request();
    if (result.isGranted) return PermissionOutcome.granted;
    if (result.isPermanentlyDenied || result.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    return PermissionOutcome.denied;
  }

  /// Requests POST_NOTIFICATIONS on Android 13+ (no-op on older Android / iOS).
  static Future<PermissionOutcome> ensureNotifications() async {
    if (!Platform.isAndroid) return PermissionOutcome.granted;
    final status = await Permission.notification.status;
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    final result = await Permission.notification.request();
    if (result.isGranted) return PermissionOutcome.granted;
    if (result.isPermanentlyDenied || result.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    return PermissionOutcome.denied;
  }

  /// Wrapper for `permission_handler.openAppSettings`.
  static Future<bool> openSettings() => openAppSettings();
}
