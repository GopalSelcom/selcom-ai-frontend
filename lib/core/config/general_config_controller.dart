import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_android_navigation_mode/flutter_android_navigation_mode.dart';
import 'package:get/get.dart';

class GeneralConfigController extends GetxController {
  static GeneralConfigController get to => Get.find();

  final _needBottomSpacing = false.obs;

  bool get needBottomSpacing => _needBottomSpacing.value;

  set needBottomSpacing(bool value) => _needBottomSpacing.value = value;

  @override
  void onInit() {
    super.onInit();
    getBottomSpacing();
  }

  Future<void> getBottomSpacing() async {
    DeviceNavigationMode navigationMode = DeviceNavigationMode.none;
    if (Platform.isAndroid) {
      try {
        final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
        // Check if Android SDK version is 35 or above (Android 15+)
        if (androidDeviceInfo.version.sdkInt >= 35) {
          navigationMode = await AndroidNavigationMode.getNavigationMode;
          if (navigationMode != DeviceNavigationMode.fullScreenGesture) {
            needBottomSpacing = true;
          } else {
            needBottomSpacing = false;
          }
        } else {
          needBottomSpacing = false;
        }
      } catch (e) {
        log("Error getting navigation mode: $e");
        needBottomSpacing = false;
      }
    } else {
      needBottomSpacing = false;
    }
    log(
      "needBottomSpacing ==> $needBottomSpacing || navigationMode ==> $navigationMode",
    );
  }
}
