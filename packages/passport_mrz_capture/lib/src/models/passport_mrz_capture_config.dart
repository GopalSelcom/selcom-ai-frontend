import 'package:flutter/material.dart';

class PassportMrzCaptureConfig {
  const PassportMrzCaptureConfig({
    this.screenTitle = 'Scan passports',
    this.includeFaceImage = true,
    this.includeMrzCropInResult = false,
    this.captureButtonColor,
    this.captureIconColor,
  });

  final String screenTitle;
  final bool includeFaceImage;
  final bool includeMrzCropInResult;
  final Color? captureButtonColor;
  final Color? captureIconColor;
}
