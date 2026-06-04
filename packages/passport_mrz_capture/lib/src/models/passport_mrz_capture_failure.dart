import 'passport_mrz_capture_error_code.dart';

class PassportMrzCaptureFailure {
  const PassportMrzCaptureFailure({
    required this.code,
    required this.message,
  });

  final PassportMrzCaptureErrorCode code;
  final String message;
}
