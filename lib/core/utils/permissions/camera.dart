import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selcom_rides_frontend/shared/utils/app_dialogs.dart';

import '../../services/error_reporting/error_reporter.dart';


class CameraService extends GetxController {
  static CameraService? _instance;

  CameraService._internal();

  static CameraService get instance {
    _instance ??= CameraService._internal();
    return _instance!;
  }

  bool isDialogOpen = false;

  RxBool _status = false.obs;

  RxBool get status => _status;

  Future<bool> checkPermission({bool force = false, }) async {
    try {
      PermissionStatus status = await Permission.camera.status;
      if (status.isGranted) {
        _status(true);
        return true;
      } else {
        _status(false);
        return false;
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "CameraService.checkPermission failed",
      );

      debugPrint("CameraService.checkPermission Exception: $e");
    }

    _status(false);
    return false;
  }

  Future<bool> requestPermission({bool force = false, }) async {
    bool result = await checkPermission(force: force);

    if (result) {
      _status(true);
      return true;
    }

    try {
      PermissionStatus status = await Permission.camera.request();
      if (status.isGranted) {
        _status(true);
        return true;
      } else {
        if (force) {
          await _CameraUtils.dialog();
        }
        _status(false);
        return false;
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "CameraService.requestPermission failed",
      );

      debugPrint("CameraService.requestPermission Exception: $e");
    }

    _status(false);
    return false;
  }
}

class _CameraUtils {
  static Future<void> dialog() async {
    if (!CameraService.instance.isDialogOpen) {
      CameraService.instance.isDialogOpen = true;
       AppDialogs.showErrorDialog(
        message: "Camera permission is required to use this feature. Please enable the permission in settings.",
        buttonText: "Open App Settings",
        onConfirm: () async {
          Get.back();
          await Geolocator.openAppSettings();
        },
      );
    }
    CameraService.instance.isDialogOpen = false;
  }
}
