import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:m7_livelyness_detection/index.dart';

class M7AndroidFaceDetectorPainter extends CustomPainter {
  final FaceDetectionModel model;
  final PreviewSize previewSize;
  final Rect previewRect;
  final bool isBackCamera;
  final Color? detectionColor;
  late DashedPathProperties _dashedPathProperties;

  M7AndroidFaceDetectorPainter({
    required this.model,
    required this.previewSize,
    required this.previewRect,
    required this.isBackCamera,
    this.detectionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _dashedPathProperties = DashedPathProperties(
      path: Path(),
      dashLength: 5.0,
      dashGapLength: 2.5,
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = M7LivelynessDetection.instance.contourLineWidth ?? 1.0
      ..color = M7LivelynessDetection.instance.contourLineColor ??
          const Color(0xffab48e0);
    // final croppedSize = model.croppedSize;
    final croppedSize = Size(512, 720);

    final ratioAnalysisToPreview = previewSize.width / croppedSize.width;

    bool flipXY = false;
    if (Platform.isAndroid) {
      // Symmetry for Android since native image analysis is not mirrored but preview is
      // It also handles device model.imagemodel.imageRotation
      switch (model.imageRotation) {
        case InputImageRotation.rotation0deg:
          if (isBackCamera) {
            flipXY = true;
            canvas.scale(-1, 1);
            canvas.translate(-size.width, 0);
          } else {
            flipXY = true;
            canvas.scale(-1, -1);
            canvas.translate(-size.width, -size.height);
          }
          break;
        case InputImageRotation.rotation90deg:
          if (isBackCamera) {
            // No changes
          } else {
            canvas.scale(1, -1);
            canvas.translate(0, -size.height);
          }
          break;
        case InputImageRotation.rotation180deg:
          if (isBackCamera) {
            flipXY = true;
            canvas.scale(1, -1);
            canvas.translate(0, -size.height);
          } else {
            flipXY = true;
          }
          break;
        default:
          // 270 or null
          if (isBackCamera) {
            canvas.scale(-1, -1);
            canvas.translate(-size.width, -size.height);
          } else {
            canvas.scale(-1, 1);
            canvas.translate(-size.width, 0);
          }
      }
    }

    // for (final Face face in model.faces) {
    //   Map<FaceContourType, Path> paths = {
    //     for (var fct in FaceContourType.values) fct: Path()
    //   };

    //   final List<Point<int>> faceEdges =
    //       face.contours[FaceContourType.face]?.points ?? [];

    //   //* MARK: - Left Side
    //   //? =========================================================
    //   final List<Point<int>> leftEyebrowBottom =
    //       face.contours[FaceContourType.leftEyebrowBottom]?.points ?? [];
    //   final List<Point<int>> leftEyebrowTop =
    //       face.contours[FaceContourType.leftEyebrowTop]?.points ?? [];
    //   final List<Point<int>> leftEye =
    //       face.contours[FaceContourType.leftEye]?.points ?? [];
    //   final List<Point<int>> leftCheek =
    //       face.contours[FaceContourType.leftCheek]?.points ?? [];

    //   //* MARK: - Right Side
    //   //? =========================================================
    //   final List<Point<int>> rightEyebrowTop =
    //       face.contours[FaceContourType.rightEyebrowTop]?.points ?? [];
    //   final List<Point<int>> rightEyebrowBottom =
    //       face.contours[FaceContourType.rightEyebrowBottom]?.points ?? [];
    //   final List<Point<int>> rightEye =
    //       face.contours[FaceContourType.rightEye]?.points ?? [];
    //   final List<Point<int>> rightCheek =
    //       face.contours[FaceContourType.rightCheek]?.points ?? [];

    //   //* MARK: - Nose
    //   //? =========================================================
    //   final List<Point<int>> noseBottom =
    //       face.contours[FaceContourType.noseBottom]?.points ?? [];
    //   final List<Point<int>> noseBridge =
    //       face.contours[FaceContourType.noseBridge]?.points ?? [];

    //   //* MARK: - Lips
    //   //? =========================================================
    //   final List<Point<int>> upperLipTop =
    //       face.contours[FaceContourType.upperLipTop]?.points ?? [];
    //   final List<Point<int>> upperLipBottom =
    //       face.contours[FaceContourType.upperLipBottom]?.points ?? [];

    //   final List<Point<int>> lowerLipTop =
    //       face.contours[FaceContourType.lowerLipTop]?.points ?? [];
    //   final List<Point<int>> lowerLipBottom =
    //       face.contours[FaceContourType.lowerLipBottom]?.points ?? [];

    //   final Point<int> faceEdges0 = faceEdges[0];
    //   final Point<int> faceEdges34 = faceEdges[34];
    //   final Point<int> faceEdges32 = faceEdges[32];
    //   final Point<int> faceEdges30 = faceEdges[30];
    //   final Point<int> faceEdges28 = faceEdges[28];
    //   final Point<int> faceEdges26 = faceEdges[26];
    //   final Point<int> faceEdges23 = faceEdges[23];
    //   final Point<int> faceEdges18 = faceEdges[18];
    //   final Point<int> faceEdges13 = faceEdges[13];
    //   final Point<int> faceEdges10 = faceEdges[10];
    //   final Point<int> faceEdges8 = faceEdges[8];
    //   final Point<int> faceEdges6 = faceEdges[6];
    //   final Point<int> faceEdges4 = faceEdges[4];
    //   final Point<int> faceEdges2 = faceEdges[2];
    //   final Point<int> rightCheek0 = rightCheek[0];
    //   final Point<int> leftCheek0 = leftCheek[0];
    //   final Point<int> leftEye0 = leftEye[0];
    //   final Point<int> leftEye4 = leftEye[4];
    //   final Point<int> leftEye8 = leftEye[8];
    //   final Point<int> leftEye12 = leftEye[12];
    //   final Point<int> rightEye0 = rightEye[0];
    //   final Point<int> rightEye4 = rightEye[4];
    //   final Point<int> rightEye8 = rightEye[8];
    //   final Point<int> rightEye12 = rightEye[12];
    //   final Point<int> upperLipTop0 = upperLipTop[0];
    //   final Point<int> upperLipTop10 = upperLipTop[10];
    //   final Point<int> upperLipTop5 = upperLipTop[5];
    //   final Point<int> upperLipTop6 = upperLipTop[6];
    //   final Point<int> upperLipTop4 = upperLipTop[4];
    //   final Point<int> lowerLipBottom4 = lowerLipBottom[4];
    //   final Point<int> noseBottom0 = noseBottom[0];
    //   final Point<int> noseBottom1 = noseBottom[1];
    //   final Point<int> noseBottom2 = noseBottom[2];
    //   final Point<int> noseBridge0 = noseBridge[0];
    //   final Point<int> noseBridge1 = noseBridge[1];
    //   final Point<int> leftEyebrowBottom2 = leftEyebrowBottom[2];
    //   final Point<int> leftEyebrowBottom4 = leftEyebrowBottom[4];
    //   final Point<int> leftEyebrowBottom0 = leftEyebrowBottom[0];
    //   final Point<int> rightEyebrowBottom2 = rightEyebrowBottom[2];
    //   final Point<int> rightEyebrowBottom4 = rightEyebrowBottom[4];
    //   final Point<int> rightEyebrowBottom0 = rightEyebrowBottom[0];

// Helper function to get a contour list or an empty list if missing
    List<Point<int>> safeGetContour(Face face, FaceContourType type) {
      return face.contours[type]?.points ?? [];
    }

// Helper function to get a point at a specific index with a default value
    Point<int> safeGetPoint(List<Point<int>> points, int index,
        {Point<int>? fallback}) {
      return (points.length > index)
          ? points[index]
          : (fallback ?? const Point<int>(0, 0));
    }

    for (final Face face in model.faces) {
      Map<FaceContourType, Path> paths = {
        for (var fct in FaceContourType.values) fct: Path()
      };
      // face.contours.forEach((contourType, faceContour) {
      //   if (faceContour != null) {
      //     paths[contourType]!.addPolygon(
      //         faceContour.points
      //             .map(
      //               (element) => _croppedPosition(
      //                 element,
      //                 croppedSize: croppedSize,
      //                 painterSize: size,
      //                 ratio: ratioAnalysisToPreview,
      //                 flipXY: flipXY,
      //               ),
      //             )
      //             .toList(),
      //         true);
      //     if (M7LivelynessDetection.instance.displayDots) {
      //       for (var element in faceContour.points) {
      //         canvas.drawCircle(
      //           _croppedPosition(
      //             element,
      //             croppedSize: croppedSize,
      //             painterSize: size,
      //             ratio: ratioAnalysisToPreview,
      //             flipXY: flipXY,
      //           ),
      //           4,
      //           Paint()
      //             ..color = detectionColor ??
      //                 M7LivelynessDetection.instance.contourDotColor ??
      //                 Colors.purple.shade800
      //             ..strokeWidth =
      //                 M7LivelynessDetection.instance.contourDotRadius ?? 2,
      //         );
      //       }
      //     }
      //   }
      // });
      // paths.removeWhere((key, value) => value.getBounds().isEmpty);
      // if (M7LivelynessDetection.instance.displayLines) {
      //   for (var p in paths.entries) {
      //     final Path finalPath = M7LivelynessDetection.instance.displayDash
      //         ? _getDashedPath(
      //             p.value,
      //             M7LivelynessDetection.instance.dashLength,
      //             M7LivelynessDetection.instance.dashGap,
      //           )
      //         : p.value;
      //     canvas.drawPath(
      //       finalPath,
      //       Paint()
      //         ..color = detectionColor ??
      //             M7LivelynessDetection.instance.contourLineColor ??
      //             Colors.white
      //         ..strokeWidth =
      //             M7LivelynessDetection.instance.contourLineWidth ?? 1.6
      //         ..style = PaintingStyle.stroke,
      //     );
      //   }
      // }

      // Face edges
      final List<Point<int>> faceEdges =
          safeGetContour(face, FaceContourType.face);

      // Left side
      final List<Point<int>> leftEyebrowBottom =
          safeGetContour(face, FaceContourType.leftEyebrowBottom);
      final List<Point<int>> leftEyebrowTop =
          safeGetContour(face, FaceContourType.leftEyebrowTop);
      final List<Point<int>> leftEye =
          safeGetContour(face, FaceContourType.leftEye);
      final List<Point<int>> leftCheek =
          safeGetContour(face, FaceContourType.leftCheek);

      // Right side
      final List<Point<int>> rightEyebrowTop =
          safeGetContour(face, FaceContourType.rightEyebrowTop);
      final List<Point<int>> rightEyebrowBottom =
          safeGetContour(face, FaceContourType.rightEyebrowBottom);
      final List<Point<int>> rightEye =
          safeGetContour(face, FaceContourType.rightEye);
      final List<Point<int>> rightCheek =
          safeGetContour(face, FaceContourType.rightCheek);

      // Nose
      final List<Point<int>> noseBottom =
          safeGetContour(face, FaceContourType.noseBottom);
      final List<Point<int>> noseBridge =
          safeGetContour(face, FaceContourType.noseBridge);

      // Lips
      final List<Point<int>> upperLipTop =
          safeGetContour(face, FaceContourType.upperLipTop);
      final List<Point<int>> upperLipBottom =
          safeGetContour(face, FaceContourType.upperLipBottom);
      final List<Point<int>> lowerLipTop =
          safeGetContour(face, FaceContourType.lowerLipTop);
      final List<Point<int>> lowerLipBottom =
          safeGetContour(face, FaceContourType.lowerLipBottom);

      // Safe access with default fallback (0,0) if missing
      final Point<int> faceEdges0 = safeGetPoint(faceEdges, 0);
      final Point<int> faceEdges34 = safeGetPoint(faceEdges, 34);
      final Point<int> faceEdges32 = safeGetPoint(faceEdges, 32);
      final Point<int> faceEdges30 = safeGetPoint(faceEdges, 30);
      final Point<int> faceEdges28 = safeGetPoint(faceEdges, 28);
      final Point<int> faceEdges26 = safeGetPoint(faceEdges, 26);
      final Point<int> faceEdges23 = safeGetPoint(faceEdges, 23);
      final Point<int> faceEdges18 = safeGetPoint(faceEdges, 18);
      final Point<int> faceEdges13 = safeGetPoint(faceEdges, 13);
      final Point<int> faceEdges10 = safeGetPoint(faceEdges, 10);
      final Point<int> faceEdges8 = safeGetPoint(faceEdges, 8);
      final Point<int> faceEdges6 = safeGetPoint(faceEdges, 6);
      final Point<int> faceEdges4 = safeGetPoint(faceEdges, 4);
      final Point<int> faceEdges2 = safeGetPoint(faceEdges, 2);

      final Point<int> rightCheek0 = safeGetPoint(rightCheek, 0);
      final Point<int> leftCheek0 = safeGetPoint(leftCheek, 0);

      final Point<int> leftEye0 = safeGetPoint(leftEye, 0);
      final Point<int> leftEye4 = safeGetPoint(leftEye, 4);
      final Point<int> leftEye8 = safeGetPoint(leftEye, 8);
      final Point<int> leftEye12 = safeGetPoint(leftEye, 12);

      final Point<int> rightEye0 = safeGetPoint(rightEye, 0);
      final Point<int> rightEye4 = safeGetPoint(rightEye, 4);
      final Point<int> rightEye8 = safeGetPoint(rightEye, 8);
      final Point<int> rightEye12 = safeGetPoint(rightEye, 12);

      final Point<int> upperLipTop0 = safeGetPoint(upperLipTop, 0);
      final Point<int> upperLipTop10 = safeGetPoint(upperLipTop, 10);
      final Point<int> upperLipTop5 = safeGetPoint(upperLipTop, 5);
      final Point<int> upperLipTop6 = safeGetPoint(upperLipTop, 6);
      final Point<int> upperLipTop4 = safeGetPoint(upperLipTop, 4);

      final Point<int> lowerLipBottom4 = safeGetPoint(lowerLipBottom, 4);

      final Point<int> noseBottom0 = safeGetPoint(noseBottom, 0);
      final Point<int> noseBottom1 = safeGetPoint(noseBottom, 1);
      final Point<int> noseBottom2 = safeGetPoint(noseBottom, 2);
      final Point<int> noseBridge0 = safeGetPoint(noseBridge, 0);
      final Point<int> noseBridge1 = safeGetPoint(noseBridge, 1);

      final Point<int> leftEyebrowBottom2 = safeGetPoint(leftEyebrowBottom, 2);
      final Point<int> leftEyebrowBottom4 = safeGetPoint(leftEyebrowBottom, 4);
      final Point<int> leftEyebrowBottom0 = safeGetPoint(leftEyebrowBottom, 0);

      final Point<int> rightEyebrowBottom2 =
          safeGetPoint(rightEyebrowBottom, 2);
      final Point<int> rightEyebrowBottom4 =
          safeGetPoint(rightEyebrowBottom, 4);
      final Point<int> rightEyebrowBottom0 =
          safeGetPoint(rightEyebrowBottom, 0);

      // Log missing values for debugging
      if (faceEdges0 == const Point<int>(0, 0))
        print("Warning: faceEdges[0] is missing");
      if (rightCheek0 == const Point<int>(0, 0))
        print("Warning: rightCheek[0] is missing");
      if (leftEye0 == const Point<int>(0, 0))
        print("Warning: leftEye[0] is missing");
      if (upperLipTop0 == const Point<int>(0, 0))
        print("Warning: upperLipTop[0] is missing");
      if (noseBottom0 == const Point<int>(0, 0))
        print("Warning: noseBottom[0] is missing");

// lips
      canvas.drawLine(
        _croppedPosition(
          upperLipTop4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          upperLipTop6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          upperLipTop4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop5,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          upperLipTop5,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          lowerLipBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges23,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges23,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          upperLipTop0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges26,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges13,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          lowerLipBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges13,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          lowerLipBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges18,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          lowerLipBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          lowerLipBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//nose to other points
      canvas.drawLine(
        _croppedPosition(
          noseBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBridge1,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBridge1,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          noseBridge1,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//right eyebrow and from right eyebrow to other points
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//left eyebrow and from left eyebrow to other points
      canvas.drawLine(
        _croppedPosition(
          leftEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEyebrowBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges30,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEyebrowBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges34,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges34,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//right eye and other points for it
      canvas.drawLine(
        _croppedPosition(
          rightEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEyebrowBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEye12,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEye12,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEye4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEye4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//left eye and other points for it
      canvas.drawLine(
        _croppedPosition(
          leftEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBridge0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEyebrowBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEyebrowBottom4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEyebrowBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges30,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges28,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEye12,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEye12,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEye4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEye4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//right cheeks to other points
      canvas.drawLine(
        _croppedPosition(
          rightCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBottom2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEye8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          rightEye12,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          rightCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//left cheeks to other points
      canvas.drawLine(
        _croppedPosition(
          leftCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          noseBottom0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEye0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          leftEye12,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          upperLipTop0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges26,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          leftCheek0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges28,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );

//faceline
      canvas.drawLine(
        _croppedPosition(
          faceEdges30,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges32,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges32,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges34,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges4,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges2,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges6,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges8,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges10,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges13,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges18,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges18,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges18,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges23,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges26,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges23,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges26,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges28,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges30,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges28,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges0,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges34,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
      canvas.drawLine(
        _croppedPosition(
          faceEdges18,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        _croppedPosition(
          faceEdges13,
          croppedSize: croppedSize,
          painterSize: size,
          ratio: ratioAnalysisToPreview,
          flipXY: flipXY,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(M7AndroidFaceDetectorPainter oldDelegate) {
    return oldDelegate.isBackCamera != isBackCamera ||
        oldDelegate.previewSize.width != previewSize.width ||
        oldDelegate.previewSize.height != previewSize.height ||
        oldDelegate.previewRect != previewRect ||
        oldDelegate.model != model;
  }

  Offset _croppedPosition(
    Point<int> element, {
    required Size croppedSize,
    required Size painterSize,
    required double ratio,
    required bool flipXY,
  }) {
    num imageDiffX;
    num imageDiffY;
    if (Platform.isIOS) {
      imageDiffX = model.absoluteImageSize.width - croppedSize.width;
      imageDiffY = model.absoluteImageSize.height - croppedSize.height;
    } else {
      imageDiffX = model.absoluteImageSize.height - croppedSize.width;
      imageDiffY = model.absoluteImageSize.width - croppedSize.height;
    }

    return (Offset(
              (flipXY ? element.y : element.x).toDouble() - (imageDiffX / 2),
              (flipXY ? element.x : element.y).toDouble() - (imageDiffY / 2),
            ) *
            ratio)
        .translate(
      (painterSize.width - (croppedSize.width * ratio)) / 2,
      (painterSize.height - (croppedSize.height * ratio)) / 2,
    );
  }

  Path _getDashedPath(
    Path originalPath,
    double dashLength,
    double dashGapLength,
  ) {
    final metricsIterator = originalPath.computeMetrics().iterator;
    while (metricsIterator.moveNext()) {
      final metric = metricsIterator.current;
      _dashedPathProperties.extractedPathLength = 0.0;
      while (_dashedPathProperties.extractedPathLength < metric.length) {
        if (_dashedPathProperties.addDashNext) {
          _dashedPathProperties.addDash(metric, dashLength);
        } else {
          _dashedPathProperties.addDashGap(metric, dashGapLength);
        }
      }
    }
    return _dashedPathProperties.path;
  }
}

class DashedPathProperties {
  double extractedPathLength;
  Path path;

  final double _dashLength;
  double _remainingDashLength;
  double _remainingDashGapLength;
  bool _previousWasDash;

  DashedPathProperties({
    required this.path,
    required double dashLength,
    required double dashGapLength,
  })  : assert(dashLength > 0.0, 'dashLength must be > 0.0'),
        assert(dashGapLength > 0.0, 'dashGapLength must be > 0.0'),
        _dashLength = dashLength,
        _remainingDashLength = dashLength,
        _remainingDashGapLength = dashGapLength,
        _previousWasDash = false,
        extractedPathLength = 0.0;

  bool get addDashNext {
    if (!_previousWasDash || _remainingDashLength != _dashLength) {
      return true;
    }
    return false;
  }

  void addDash(ui.PathMetric metric, double dashLength) {
    // Calculate lengths (actual + available)
    final end = _calculateLength(metric, _remainingDashLength);
    final availableEnd = _calculateLength(metric, dashLength);
    // Add path
    final pathSegment = metric.extractPath(extractedPathLength, end);
    path.addPath(pathSegment, Offset.zero);
    // Update
    final delta = _remainingDashLength - (end - extractedPathLength);
    _remainingDashLength = _updateRemainingLength(
      delta: delta,
      end: end,
      availableEnd: availableEnd,
      initialLength: dashLength,
    );
    extractedPathLength = end;
    _previousWasDash = true;
  }

  void addDashGap(ui.PathMetric metric, double dashGapLength) {
    // Calculate lengths (actual + available)
    final end = _calculateLength(metric, _remainingDashGapLength);
    final availableEnd = _calculateLength(metric, dashGapLength);
    // Move path's end point
    ui.Tangent tangent = metric.getTangentForOffset(end)!;
    path.moveTo(tangent.position.dx, tangent.position.dy);
    // Update
    final delta = end - extractedPathLength;
    _remainingDashGapLength = _updateRemainingLength(
      delta: delta,
      end: end,
      availableEnd: availableEnd,
      initialLength: dashGapLength,
    );
    extractedPathLength = end;
    _previousWasDash = false;
  }

  double _calculateLength(ui.PathMetric metric, double addedLength) {
    return math.min(extractedPathLength + addedLength, metric.length);
  }

  double _updateRemainingLength({
    required double delta,
    required double end,
    required double availableEnd,
    required double initialLength,
  }) {
    return (delta > 0 && availableEnd == end) ? delta : initialLength;
  }
}
