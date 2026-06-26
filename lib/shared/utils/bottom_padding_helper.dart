import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/config/general_config_controller.dart';

GeneralConfigController get generalConfigController =>
    Get.find<GeneralConfigController>();

SizedBox getSafeBottomBox(BuildContext context) {
  return SizedBox(
    height: generalConfigController.needBottomSpacing
        ? MediaQuery.paddingOf(context).bottom
        : 0,
  );
}

double getComputedBottomPadding(
  BuildContext context, {
  double? defaultPadding,
}) {
  final double bottomPadding = MediaQuery.paddingOf(context).bottom;
  final double defaultVal = defaultPadding ?? 16.h;

  if (bottomPadding > 0) {
    if (GetPlatform.isIOS) {
      return 0.0;
    } else {
      print(generalConfigController.needBottomSpacing);
      return generalConfigController.needBottomSpacing ? bottomPadding : 8.h;
    }
  } else {
    return defaultVal;
  }
}
