# passport_mrz_capture

Reusable passport data-page camera capture with MRZ band OCR (TD3).

## Usage

```dart
import 'package:passport_mrz_capture/passport_mrz_capture.dart';

PassportMrzCapture.capture(
  context: context,
  config: const PassportMrzCaptureConfig(
    screenTitle: 'Scan passport',
    includeFaceImage: true,
    includeMrzCropInResult: true, // e.g. kDebugMode
  ),
  onSuccess: (PassportMrzCaptureSuccess success) {
    // success.data — parsed MRZ fields
    // success.passportPageImage, success.faceImage, success.mrzCroppedImage
  },
  onFailure: (PassportMrzCaptureFailure failure) {
    // failure.code — PassportMrzCaptureErrorCode
    // failure.message
  },
);
```

## Host app (selcom_auth)

See `lib/features/register/passport_scan/passport_camera_host.dart`.
