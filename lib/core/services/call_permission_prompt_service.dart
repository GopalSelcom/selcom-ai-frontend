import 'dart:async';
import 'dart:io';

import 'package:agora_calling_package/agora_calling.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../localization/app_strings.dart';
import '../../shared/utils/app_dialogs.dart';

/// Android in-app prompts for call notification (settings) and full-screen intent.
///
/// Invoked by [NotificationService.runHomePermissionFlow] after the system
/// notification sheet has been shown or skipped.
class CallPermissionPromptService {
  CallPermissionPromptService._();

  static Future<void> ensureAndroidCallPermissions() async {
    if (!Platform.isAndroid) return;

    if (!await waitUntilUiReady()) return;

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await _showPermissionDialog(
        message: AppStrings.callNotificationPermissionMsg.tr,
        forCallNotification: true,
        onOpenSettings: openAppSettings,
      );
    }

    if (!await waitUntilUiReady()) return;

    final fullScreenGranted = await AgoraCalling.isFullScreenIntentGranted();
    /*if (!fullScreenGranted) {
      await _showPermissionDialog(
        message: AppStrings.callFullScreenPermissionMsg.tr,
        forCallFullScreen: true,
        onOpenSettings: AgoraCalling.openFullScreenIntentSettings,
      );
    }*/
  }

  /// Waits until overlay context exists and no modal is open.
  static Future<bool> waitUntilUiReady() async {
    for (var i = 0; i < 150; i++) {
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

  static Future<void> _showPermissionDialog({
    required String message,
    bool forCallNotification = false,
    bool forCallFullScreen = false,
    required Future<void> Function() onOpenSettings,
  }) async {
    if (!await waitUntilUiReady()) return;

    var openedSettings = false;
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

    try {
      await AppDialogs.showPermissionDialog(
        title: AppStrings.notification,
        message: message,
        icon: forCallFullScreen
            ? Icons.fullscreen
            : Icons.notifications_active_outlined,
        onOpenSettings: () {
          checkingPermission = true;
          openedSettings = true;
          unawaited(onOpenSettings());
        },
      );

      if (openedSettings) {
        await _waitForAppResume();
      }
    } finally {
      WidgetsBinding.instance.removeObserver(observer);
    }

    await waitUntilUiReady();
  }

  static Future<void> _waitForAppResume() async {
    final completer = Completer<void>();
    late final _PermissionResumeObserver observer;
    observer = _PermissionResumeObserver(() async {
      if (!completer.isCompleted) completer.complete();
      WidgetsBinding.instance.removeObserver(observer);
    });
    WidgetsBinding.instance.addObserver(observer);
    await completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        WidgetsBinding.instance.removeObserver(observer);
      },
    );
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
