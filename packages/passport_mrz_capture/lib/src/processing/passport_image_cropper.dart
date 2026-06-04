import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:passport_mrz_capture/src/layout/passport_guide_layout.dart';

class PassportImageCropper {
  static img.Image? copyCropRect(img.Image source, Rect rect) {
    final x = rect.left.round().clamp(0, source.width - 1);
    final y = rect.top.round().clamp(0, source.height - 1);
    final w = rect.width.round().clamp(1, source.width - x);
    final h = rect.height.round().clamp(1, source.height - y);
    if (w < 40 || h < 20) return null;
    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  static Future<File?> cropPlaceholderFromCapture({
    required img.Image oriented,
    required String outputPath,
    required Size screenSize,
    required Size previewDisplaySize,
    int jpegQuality = 88,
  }) async {
    final imageSize =
        Size(oriented.width.toDouble(), oriented.height.toDouble());
    final placeholderRect = PassportGuideLayout.placeholderRectOnCapture(
      screenSize: screenSize,
      imageSize: imageSize,
      previewDisplaySize: previewDisplaySize,
    );
    if (placeholderRect == null) return null;

    final cropped = copyCropRect(oriented, placeholderRect);
    if (cropped == null) return null;

    return writeJpeg(cropped, outputPath, quality: jpegQuality);
  }

  static Future<File?> writeJpeg(
    img.Image image,
    String outputPath, {
    int quality = 88,
  }) async {
    final out = File(outputPath);
    await out.writeAsBytes(img.encodeJpg(image, quality: quality));
    return out;
  }

  /// In-memory passport page crop (same region as on-screen placeholder).
  static img.Image? cropPlaceholderInMemory({
    required img.Image oriented,
    required Size screenSize,
    required Size previewDisplaySize,
  }) {
    final imageSize =
        Size(oriented.width.toDouble(), oriented.height.toDouble());
    final placeholderRect = PassportGuideLayout.placeholderRectOnCapture(
      screenSize: screenSize,
      imageSize: imageSize,
      previewDisplaySize: previewDisplaySize,
    );
    if (placeholderRect == null) return null;
    return copyCropRect(oriented, placeholderRect);
  }

  /// MRZ band crop from the **placeholder/passport page** image (not full camera frame).
  static Future<File?> cropMrzFromPlaceholderImage({
    required img.Image placeholderImage,
    required String outputPath,
    required Size screenSize,
    int jpegQuality = 92,
  }) async {
    final guide = PassportGuideLayout.rectFor(screenSize);
    if (guide.width <= 0 || guide.height <= 0) return null;

    final local = PassportGuideLayout.mrzBandRectInGuideLocal(screenSize);
    final sx = placeholderImage.width / guide.width;
    final sy = placeholderImage.height / guide.height;
    var mrzRect = Rect.fromLTWH(
      local.left * sx,
      local.top * sy,
      local.width * sx,
      local.height * sy,
    );
    final padY = mrzRect.height * 0.08;
    mrzRect = Rect.fromLTWH(
      mrzRect.left,
      (mrzRect.top - padY).clamp(0.0, placeholderImage.height.toDouble() - 1),
      mrzRect.width,
      (mrzRect.height + 2 * padY)
          .clamp(1.0, placeholderImage.height.toDouble()),
    );

    final cropped = copyCropRect(placeholderImage, mrzRect);
    if (cropped == null) return null;

    return writeJpeg(cropped, outputPath, quality: jpegQuality);
  }

  static Future<File?> cropMrzFromPlaceholderFile({
    required File placeholderFile,
    required String outputPath,
    required Size screenSize,
  }) async {
    final decoded = img.decodeImage(await placeholderFile.readAsBytes());
    if (decoded == null) return null;
    return cropMrzFromPlaceholderImage(
      placeholderImage: decoded,
      outputPath: outputPath,
      screenSize: screenSize,
    );
  }
}
