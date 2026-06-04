import 'dart:math' as math;
import 'dart:typed_data';

/// Lightweight camera-frame metrics (runs in a background isolate).
class PassportFrameMetrics {
  const PassportFrameMetrics({
    required this.meanLuma,
    required this.sharpness,
    required this.bottomContrast,
    required this.fillRatio,
  });

  final double meanLuma;
  final double sharpness;
  final double bottomContrast;
  final double fillRatio;
}

/// Grayscale downsample (one luma byte per pixel).
class PassportFrameSample {
  const PassportFrameSample({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}

PassportFrameMetrics analyzePassportFrame(PassportFrameSample sample) {
  final w = sample.width;
  final h = sample.height;
  final gray = Float32List(w * h);
  for (var i = 0; i < gray.length; i++) {
    gray[i] = sample.bytes[i].toDouble();
  }

  var sum = 0.0;
  for (final v in gray) {
    sum += v;
  }
  final meanLuma = sum / gray.length;
  final sharpness = _laplacianVariance(gray, w, h);

  final bottomStart = (h * 0.62).floor();
  var bottomSum = 0.0;
  var bottomCount = 0;
  for (var y = bottomStart; y < h; y++) {
    for (var x = 0; x < w; x++) {
      bottomSum += gray[y * w + x];
      bottomCount++;
    }
  }
  final bottomMean = bottomSum / bottomCount;

  var bottomVar = 0.0;
  for (var y = bottomStart; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final d = gray[y * w + x] - bottomMean;
      bottomVar += d * d;
    }
  }
  final bottomContrast = math.sqrt(bottomVar / bottomCount);

  final innerLeft = (w * 0.12).floor();
  final innerRight = (w * 0.88).floor();
  final innerTop = (h * 0.18).floor();
  final innerBottom = (h * 0.82).floor();

  var edgeCount = 0;
  var innerPixels = 0;
  for (var y = innerTop; y < innerBottom; y++) {
    for (var x = innerLeft; x < innerRight; x++) {
      innerPixels++;
      final c = gray[y * w + x];
      final r = x + 1 < innerRight ? gray[y * w + x + 1] : c;
      final d = y + 1 < innerBottom ? gray[(y + 1) * w + x] : c;
      if ((c - r).abs() > 18 || (c - d).abs() > 18) edgeCount++;
    }
  }
  final fillRatio = edgeCount / innerPixels;

  return PassportFrameMetrics(
    meanLuma: meanLuma,
    sharpness: sharpness,
    bottomContrast: bottomContrast,
    fillRatio: fillRatio,
  );
}

double _laplacianVariance(Float32List gray, int w, int h) {
  var sum = 0.0;
  var sumSq = 0.0;
  var n = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final c = gray[y * w + x];
      final lap = -4 * c +
          gray[y * w + (x - 1)] +
          gray[y * w + (x + 1)] +
          gray[(y - 1) * w + x] +
          gray[(y + 1) * w + x];
      sum += lap;
      sumSq += lap * lap;
      n++;
    }
  }
  if (n == 0) return 0;
  final mean = sum / n;
  return (sumSq / n) - (mean * mean);
}
