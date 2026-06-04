import 'package:flutter/material.dart';
enum PassportScanHint {
  placeInFrame,
  moveCloser,
  alignMrz,
  poorLighting,
  outOfFocus,
  holdSteady,
  scanning,
  detected,
}

extension PassportScanHintX on PassportScanHint {
  String get message {
    switch (this) {
      case PassportScanHint.placeInFrame:
        return 'Place the passport in the frame and align both MRZ lines in the blue band';
      case PassportScanHint.moveCloser:
        return 'Move closer so the passport fills the frame';
      case PassportScanHint.alignMrz:
        return 'Tilt the passport so both MRZ lines sit in the highlighted band';
      case PassportScanHint.poorLighting:
        return 'Improve lighting — avoid shadows and glare on the page';
      case PassportScanHint.outOfFocus:
        return 'Hold steady — the image is blurry';
      case PassportScanHint.holdSteady:
        return 'Looks good — tap the capture button';
      case PassportScanHint.scanning:
        return 'Extracting passport details…';
      case PassportScanHint.detected:
        return 'Done';
    }
  }

  Color get borderColor {
    switch (this) {
      case PassportScanHint.placeInFrame:
        return Colors.white;
      case PassportScanHint.moveCloser:
        return const Color(0xFFFFB74D);
      case PassportScanHint.alignMrz:
        return const Color(0xFF81D4FA);
      case PassportScanHint.poorLighting:
        return const Color(0xFFFFCC80);
      case PassportScanHint.outOfFocus:
        return const Color(0xFFCE93D8);
      case PassportScanHint.holdSteady:
      case PassportScanHint.scanning:
        return const Color(0xFFA5D6A7);
      case PassportScanHint.detected:
        return const Color(0xFF69F0AE);
    }
  }
}

/// ISO/IEC 7810 ID-3 passport aspect ratio (125 × 88 mm).
class PassportGuideLayout {
  static const aspectRatio = 125.0 / 88.0;

  /// MRZ highlight band (overlay + OCR crop share these).
  static const mrzBandHeightFraction = 0.20;
  static const mrzBandBottomInsetFraction = 0.04;

  static Rect rectFor(Size size) {
    final w = size.width * 0.88;
    final h = w / aspectRatio;
    final topShift = size.height * 0.08;
    return Rect.fromLTWH(
      (size.width - w) / 2,
      ((size.height - h) / 2) - topShift,
      w,
      h,
    );
  }

  // --- NEW OCR IMPLEMENTATION ---
  /// [CameraPreview] letterboxed size on screen (AspectRatio + Center).
  static Size previewDisplaySize({
    required Size screenSize,
    required double cameraAspectRatio,
    required bool isPortrait,
  }) {
    final displayWOverH =
        isPortrait ? (1 / cameraAspectRatio) : cameraAspectRatio;
    final screenAspect = screenSize.width / screenSize.height;
    if (displayWOverH > screenAspect) {
      final w = screenSize.width;
      return Size(w, w / displayWOverH);
    }
    final h = screenSize.height;
    return Size(h * displayWOverH, h);
  }

  // --- NEW OCR IMPLEMENTATION ---
  /// Maps on-screen placeholder rect into baked capture pixels.
  static Rect? mapScreenRectToImage({
    required Rect screenRect,
    required Size screenSize,
    required Size imageSize,
    required Size previewDisplaySize,
  }) {
    if (previewDisplaySize.width <= 0 || previewDisplaySize.height <= 0) {
      return null;
    }

    final offsetX = (screenSize.width - previewDisplaySize.width) / 2;
    final offsetY = (screenSize.height - previewDisplaySize.height) / 2;
    final renderW = previewDisplaySize.width;
    final renderH = previewDisplaySize.height;

    double norm(double coord, double offset, double dim) =>
        ((coord - offset) / dim).clamp(0.0, 1.0);

    final left = norm(screenRect.left, offsetX, renderW);
    final top = norm(screenRect.top, offsetY, renderH);
    final right = norm(screenRect.right, offsetX, renderW);
    final bottom = norm(screenRect.bottom, offsetY, renderH);

    if (right <= left + 0.05 || bottom <= top + 0.05) return null;

    return Rect.fromLTRB(
      left * imageSize.width,
      top * imageSize.height,
      right * imageSize.width,
      bottom * imageSize.height,
    );
  }

  // --- NEW OCR IMPLEMENTATION ---
  static Rect? placeholderRectOnCapture({
    required Size screenSize,
    required Size imageSize,
    required Size previewDisplaySize,
  }) {
    return mapScreenRectToImage(
      screenRect: rectFor(screenSize),
      screenSize: screenSize,
      imageSize: imageSize,
      previewDisplaySize: previewDisplaySize,
    );
  }

  // --- NEW OCR IMPLEMENTATION ---
  /// MRZ band inside the deflated passport guide (matches overlay painter).
  static Rect mrzBandRectInInner(Rect inner) {
    final h = inner.height * mrzBandHeightFraction;
    final top = inner.bottom -
        inner.height * (mrzBandBottomInsetFraction + mrzBandHeightFraction);
    return Rect.fromLTWH(inner.left, top, inner.width, h);
  }

  // --- NEW OCR IMPLEMENTATION ---
  /// MRZ band in guide-local coords (matches [_PassportGuideOverlayPainter]).
  static Rect mrzBandRectInGuideLocal(Size screenSize) {
    const inset = 18.0;
    final guide = rectFor(screenSize);
    final inner = guide.deflate(inset);
    final band = mrzBandRectInInner(inner);
    return Rect.fromLTWH(
      band.left - guide.left,
      band.top - guide.top,
      band.width,
      band.height,
    );
  }
}
