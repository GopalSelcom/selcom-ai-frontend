import 'package:flutter/material.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_config.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_failure.dart';
import 'package:passport_mrz_capture/src/models/passport_mrz_capture_success.dart';
import 'package:passport_mrz_capture/src/ui/passport_mrz_capture_screen.dart';

/// Opens the passport MRZ camera screen and invokes [onSuccess] or [onFailure].
class PassportMrzCapture {
  PassportMrzCapture._();

  static Future<void> capture({
    required BuildContext context,
    PassportMrzCaptureConfig config = const PassportMrzCaptureConfig(),
    required void Function(PassportMrzCaptureSuccess success) onSuccess,
    required void Function(PassportMrzCaptureFailure failure) onFailure,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PassportMrzCaptureScreen(
          config: config,
          onSuccess: onSuccess,
          onFailure: onFailure,
        ),
      ),
    );
  }
}
