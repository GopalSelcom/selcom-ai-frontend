import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:passport_mrz_capture/src/processing/passport_image_cropper.dart';

/// Parameters for [processPassportCapture] (must be simple for [compute]).
class CaptureProcessRequest {
  const CaptureProcessRequest({
    required this.sourceImagePath,
    required this.placeholderOutputPath,
    required this.mrzOutputPath,
    required this.screenWidth,
    required this.screenHeight,
    required this.previewDisplayWidth,
    required this.previewDisplayHeight,
    this.maxProcessingEdge = 2400,
  });

  final String sourceImagePath;
  final String placeholderOutputPath;
  final String mrzOutputPath;
  final double screenWidth;
  final double screenHeight;
  final double previewDisplayWidth;
  final double previewDisplayHeight;
  final int maxProcessingEdge;
}

class CaptureProcessResult {
  const CaptureProcessResult({
    this.placeholderPath,
    this.mrzPath,
  });

  final String? placeholderPath;
  final String? mrzPath;

  bool get ok => placeholderPath != null && mrzPath != null;
}

img.Image _downscaleIfNeeded(img.Image source, int maxEdge) {
  final longest = source.width > source.height ? source.width : source.height;
  if (longest <= maxEdge) return source;
  final scale = maxEdge / longest;
  return img.copyResize(
    source,
    width: (source.width * scale).round(),
    height: (source.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );
}

/// Decode, orient, crop placeholder + MRZ, and write JPEGs off the UI thread.
Future<CaptureProcessResult> processPassportCapture(
  CaptureProcessRequest request,
) async {
  try {
    final bytes = await File(request.sourceImagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const CaptureProcessResult();
    }

    final oriented = img.bakeOrientation(decoded);
    final scaled = _downscaleIfNeeded(oriented, request.maxProcessingEdge);

    final screenSize = Size(request.screenWidth, request.screenHeight);
    final previewDisplaySize = Size(
      request.previewDisplayWidth,
      request.previewDisplayHeight,
    );

    final placeholderImage = PassportImageCropper.cropPlaceholderInMemory(
      oriented: scaled,
      screenSize: screenSize,
      previewDisplaySize: previewDisplaySize,
    );
    if (placeholderImage == null) {
      return const CaptureProcessResult();
    }

    final placeholderFile = await PassportImageCropper.writeJpeg(
      placeholderImage,
      request.placeholderOutputPath,
      // quality: 88,
    );
    if (placeholderFile == null) {
      return const CaptureProcessResult();
    }

    final mrzFile = await PassportImageCropper.cropMrzFromPlaceholderImage(
      placeholderImage: placeholderImage,
      outputPath: request.mrzOutputPath,
      screenSize: screenSize,
    );
    if (mrzFile == null) {
      return const CaptureProcessResult();
    }

    return CaptureProcessResult(
      placeholderPath: placeholderFile.path,
      mrzPath: mrzFile.path,
    );
  } catch (e, st) {
    debugPrint('processPassportCapture failed: $e\n$st');
    return const CaptureProcessResult();
  }
}

/// Runs [processPassportCapture] in a background isolate.
Future<CaptureProcessResult> processPassportCaptureOffMain(
  CaptureProcessRequest request,
) {
  return compute(processPassportCapture, request);
}
