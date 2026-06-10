import 'dart:async';
import 'dart:io';

import 'package:agora_calling_package/agora_calling.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../localization/app_strings.dart';
import '../../shared/utils/app_dialogs.dart';

/// Android call permissions for incoming driver calls (notification + full-screen).
///
/// Mirrors delivery_agent_app `CallPermissionPromptService` — prompts run
/// from [HomeController] after login when the user reaches Home.
class CallPermissionPromptService {
  CallPermissionPromptService._();

  static Future<void> ensureAndroidCallPermissions() async {
    if (!Platform.isAndroid) return;

    if (!await _waitUntilUiReady()) return;

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await _showPermissionDialog(
        message: AppStrings.callNotificationPermissionMsg.tr,
        forCallNotification: true,
        onOpenSettings: openAppSettings,
      );
    }

    if (!await _waitUntilUiReady()) return;

    final fullScreenGranted = await AgoraCalling.isFullScreenIntentGranted();
    if (!fullScreenGranted) {
      await _showPermissionDialog(
        message: AppStrings.callFullScreenPermissionMsg.tr,
        forCallFullScreen: true,
        onOpenSettings: AgoraCalling.openFullScreenIntentSettings,
      );
    }
  }

  static Future<void> _showPermissionDialog({
    required String message,
    bool forCallNotification = false,
    bool forCallFullScreen = false,
    required Future<void> Function() onOpenSettings,
  }) async {
    if (Get.isDialogOpen ?? false) return;

    var checkingPermission = false;
    final observer = _PermissionResumeObserver(() async {
      if (!checkingPermission) return;
      checkingPermission = false;
      if (forCallNotification && await Permission.notification.isGranted) {
        if (Get.isDialogOpen ?? false) Get.back();
        return;
      }
      if (forCallFullScreen && await AgoraCalling.isFullScreenIntentGranted()) {
        if (Get.isDialogOpen ?? false) Get.back();
      }
    });
    WidgetsBinding.instance.addObserver(observer);

    AppDialogs.showPermissionDialog(
      title: AppStrings.notification,
      message: message,
      icon: forCallFullScreen
          ? Icons.fullscreen
          : Icons.notifications_active_outlined,
      onOpenSettings: () {
        checkingPermission = true;
        unawaited(onOpenSettings());
      },
    );

    // Clean up observer when dialog closes (poll briefly after show).
    unawaited(Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!(Get.isDialogOpen ?? false)) {
        WidgetsBinding.instance.removeObserver(observer);
      }
    }));
  }

  static Future<bool> _waitUntilUiReady() async {
    for (var i = 0; i < 100; i++) {
      final hasContext =
          Get.overlayContext != null ||
          Get.context != null ||
          Get.key.currentContext != null;
      final dialogOpen = Get.isDialogOpen ?? false;
      if (hasContext && !dialogOpen) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return Get.overlayContext != null || Get.context != null;
  }
}

class _PermissionResumeObserver with WidgetsBindingObserver {
  _PermissionResumeObserver(this._onResumed);
  final Future<void> Function() _onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }
}
