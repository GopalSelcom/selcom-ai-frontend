import 'dart:io';

import 'passport_mrz_parsed_data.dart';

class PassportMrzCaptureSuccess {
  const PassportMrzCaptureSuccess({
    required this.data,
    required this.passportPageImage,
    this.faceImage,
    this.mrzCroppedImage,
  });

  final PassportMrzParsedData data;
  final File passportPageImage;
  final File? faceImage;
  final File? mrzCroppedImage;
}
