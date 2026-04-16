//sky_engine/lib/ui/painting.dart
import 'package:m7_livelyness_detection/index.dart';

class M7FaceDetectorPainter extends CustomPainter {
  M7FaceDetectorPainter(
    this.face,
    this.absoluteImageSize,
    this.rotation,
  );

  final Face face;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = M7LivelynessDetection.instance.contourLineWidth ?? 1.0
      ..color = M7LivelynessDetection.instance.contourLineColor ??
          const Color(0xffab48e0);

    final List<Point<int>> faceEdges =
        face.contours[FaceContourType.face]?.points ?? [];

    //* MARK: - Left Side
    //? =========================================================
    final List<Point<int>> leftEyebrowBottom =
        face.contours[FaceContourType.leftEyebrowBottom]?.points ?? [];
    final List<Point<int>> leftEyebrowTop =
        face.contours[FaceContourType.leftEyebrowTop]?.points ?? [];
    final List<Point<int>> leftEye =
        face.contours[FaceContourType.leftEye]?.points ?? [];
    final List<Point<int>> leftCheek =
        face.contours[FaceContourType.leftCheek]?.points ?? [];

    //* MARK: - Right Side
    //? =========================================================
    final List<Point<int>> rightEyebrowTop =
        face.contours[FaceContourType.rightEyebrowTop]?.points ?? [];
    final List<Point<int>> rightEyebrowBottom =
        face.contours[FaceContourType.rightEyebrowBottom]?.points ?? [];
    final List<Point<int>> rightEye =
        face.contours[FaceContourType.rightEye]?.points ?? [];
    final List<Point<int>> rightCheek =
        face.contours[FaceContourType.rightCheek]?.points ?? [];

    //* MARK: - Nose
    //? =========================================================
    final List<Point<int>> noseBottom =
        face.contours[FaceContourType.noseBottom]?.points ?? [];
    final List<Point<int>> noseBridge =
        face.contours[FaceContourType.noseBridge]?.points ?? [];

    //* MARK: - Lips
    //? =========================================================
    final List<Point<int>> upperLipTop =
        face.contours[FaceContourType.upperLipTop]?.points ?? [];
    final List<Point<int>> upperLipBottom =
        face.contours[FaceContourType.upperLipBottom]?.points ?? [];

    final List<Point<int>> lowerLipTop =
        face.contours[FaceContourType.lowerLipTop]?.points ?? [];
    final List<Point<int>> lowerLipBottom =
        face.contours[FaceContourType.lowerLipBottom]?.points ?? [];

    // final List<Point<int>> rightEyebrowTopR = rightEyebrowTop.reversed.toList();
    // final List<Point<int>> rightEyeTop = rightEye.toList();
    // final List<Point<int>> faceEdges1 = faceEdges.toList();
    // final List<Point<int>> noseBridge1 = noseBridge.toList();
    // final List<Point<int>> leftEyeTop = leftEye.toList();
    // final List<Point<int>> noseBottom1 = noseBottom.toList();
    // final List<Point<int>> upperLipTop1 = upperLipTop.toList();
    // final List<Point<int>> lowerLipBottom1 = lowerLipBottom.toList();
    // final List<Point<int>> leftCheek1 = leftCheek.toList();
    // final List<Point<int>> rightCheek1 = rightCheek.toList();
    // final List<Point<int>> leftEyebrowTop1 = leftEyebrowTop.toList();
    // final List<Point<int>> rightEyebrowTop1 = rightEyebrowTop.toList();
    // final List<Point<int>> rightEyebrowBottom1 = rightEyebrowBottom.toList();
    // final List<Point<int>> leftEyebrowBottom1 = leftEyebrowBottom.toList();

    void paintContour(FaceContourType type) {
      final faceContour = face.contours[type];
      // if (faceContour?.points != null && (type == FaceContourType.face) ||
      //         (type == FaceContourType.leftEye) ||
      //         (type == FaceContourType.rightEye) ||
      //         (type == FaceContourType.noseBridge) ||
      //         // (type == FaceContourType.noseBottom) ||
      //         (type == FaceContourType.upperLipTop) ||
      //         (type == FaceContourType.lowerLipBottom) ||
      //         (type == FaceContourType.leftEyebrowBottom) ||
      //         (type == FaceContourType.rightEyebrowBottom)
      //     //  ||
      //     // (type == FaceContourType.leftEyebrowTop) ||
      //     // (type == FaceContourType.rightEyebrowTop)
      //     ) {
      //   for (var i = 0; i < faceContour!.points.length; i++) {
      //     final Point<int> p1 = faceContour.points[i];
      //     if (i + 1 < faceContour.points.length) {
      //       final Point<int> p2 = faceContour.points[i + 1];
      //       canvas.drawLine(
      //         Offset(
      //           M7MathHelper.instance.translateX(
      //             p1.x.toDouble(),
      //             rotation,
      //             size,
      //             absoluteImageSize,
      //           ),
      //           M7MathHelper.instance.translateY(
      //             p1.y.toDouble(),
      //             rotation,
      //             size,
      //             absoluteImageSize,
      //           ),
      //         ),
      //         Offset(
      //           M7MathHelper.instance.translateX(
      //             p2.x.toDouble(),
      //             rotation,
      //             size,
      //             absoluteImageSize,
      //           ),
      //           M7MathHelper.instance.translateY(
      //             p2.y.toDouble(),
      //             rotation,
      //             size,
      //             absoluteImageSize,
      //           ),
      //         ),
      //         paint,
      //       );
      //     }
      //   }
      //   for (final Point point in faceContour.points) {
      //     canvas.drawCircle(
      //       Offset(
      //         M7MathHelper.instance.translateX(
      //           point.x.toDouble(),
      //           rotation,
      //           size,
      //           absoluteImageSize,
      //         ),
      //         M7MathHelper.instance.translateY(
      //           point.y.toDouble(),
      //           rotation,
      //           size,
      //           absoluteImageSize,
      //         ),
      //       ),
      //       1,
      //       paint,
      //     );
      //   }
      // }
    }

    // for (var i = 1; i < rightEyebrowTop1.length; i++) {
    //   final Point<int> p1 = rightEyebrowTop1[i];
    //   if (i + 1 < rightEyebrowTop1.length) {
    //     final Point<int> p2 = rightEyebrowTop1[i + 1];
    //     canvas.drawLine(
    //       Offset(
    //         M7MathHelper.instance.translateX(
    //           p1.x.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //         M7MathHelper.instance.translateY(
    //           p1.y.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //       ),
    //       Offset(
    //         M7MathHelper.instance.translateX(
    //           p2.x.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //         M7MathHelper.instance.translateY(
    //           p2.y.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //       ),
    //       paint,
    //     );
    //   }
    // }
    // for (var i = 1; i < leftEyebrowTop1.length; i++) {
    //   final Point<int> p1 = leftEyebrowTop1[i];
    //   if (i + 1 < leftEyebrowTop1.length) {
    //     final Point<int> p2 = leftEyebrowTop1[i + 1];
    //     canvas.drawLine(
    //       Offset(
    //         M7MathHelper.instance.translateX(
    //           p1.x.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //         M7MathHelper.instance.translateY(
    //           p1.y.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //       ),
    //       Offset(
    //         M7MathHelper.instance.translateX(
    //           p2.x.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //         M7MathHelper.instance.translateY(
    //           p2.y.toDouble(),
    //           rotation,
    //           size,
    //           absoluteImageSize,
    //         ),
    //       ),
    //       paint,
    //     );
    //   }
    // }

    // for (var i = 0; i < rightEyebrowTopR.length; i++) {

    //   canvas.drawLine(
    //     Offset(
    //       M7MathHelper.instance.translateX(
    //         p42.x.toDouble(),
    //         rotation,
    //         size,
    //         absoluteImageSize,
    //       ),
    //       M7MathHelper.instance.translateY(
    //         p42.y.toDouble(),
    //         rotation,
    //         size,
    //         absoluteImageSize,
    //       ),
    //     ),
    //     Offset(
    //       M7MathHelper.instance.translateX(
    //         p41.x.toDouble(),
    //         rotation,
    //         size,
    //         absoluteImageSize,
    //       ),
    //       M7MathHelper.instance.translateY(
    //         p41.y.toDouble(),
    //         rotation,
    //         size,
    //         absoluteImageSize,
    //       ),
    //     ),
    //     paint,
    //   );
    // }

    final Point<int> faceEdges0 = faceEdges[0];
    final Point<int> faceEdges34 = faceEdges[34];
    final Point<int> faceEdges32 = faceEdges[32];
    final Point<int> faceEdges30 = faceEdges[30];
    final Point<int> faceEdges28 = faceEdges[28];
    final Point<int> faceEdges26 = faceEdges[26];
    final Point<int> faceEdges23 = faceEdges[23];
    final Point<int> faceEdges18 = faceEdges[18];
    final Point<int> faceEdges13 = faceEdges[13];
    final Point<int> faceEdges10 = faceEdges[10];
    final Point<int> faceEdges8 = faceEdges[8];
    final Point<int> faceEdges6 = faceEdges[6];
    final Point<int> faceEdges4 = faceEdges[4];
    final Point<int> faceEdges2 = faceEdges[2];
    final Point<int> rightCheek0 = rightCheek[0];
    final Point<int> leftCheek0 = leftCheek[0];
    final Point<int> leftEye0 = leftEye[0];
    final Point<int> leftEye4 = leftEye[4];
    final Point<int> leftEye8 = leftEye[8];
    final Point<int> leftEye12 = leftEye[12];
    final Point<int> rightEye0 = rightEye[0];
    final Point<int> rightEye4 = rightEye[4];
    final Point<int> rightEye8 = rightEye[8];
    final Point<int> rightEye12 = rightEye[12];
    final Point<int> upperLipTop0 = upperLipTop[0];
    final Point<int> upperLipTop10 = upperLipTop[10];
    final Point<int> upperLipTop5 = upperLipTop[5];
    final Point<int> upperLipTop6 = upperLipTop[6];
    final Point<int> upperLipTop4 = upperLipTop[4];
    final Point<int> lowerLipBottom4 = lowerLipBottom[4];
    final Point<int> noseBottom0 = noseBottom[0];
    final Point<int> noseBottom1 = noseBottom[1];
    final Point<int> noseBottom2 = noseBottom[2];
    final Point<int> noseBridge0 = noseBridge[0];
    final Point<int> noseBridge1 = noseBridge[1];
    final Point<int> leftEyebrowBottom2 = leftEyebrowBottom[2];
    final Point<int> leftEyebrowBottom4 = leftEyebrowBottom[4];
    final Point<int> leftEyebrowBottom0 = leftEyebrowBottom[0];
    final Point<int> rightEyebrowBottom2 = rightEyebrowBottom[2];
    final Point<int> rightEyebrowBottom4 = rightEyebrowBottom[4];
    final Point<int> rightEyebrowBottom0 = rightEyebrowBottom[0];

// lips
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop5.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop5.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop5.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop5.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          lowerLipBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          lowerLipBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges23.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges23.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges23.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges23.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges26.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges26.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges13.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges13.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          lowerLipBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          lowerLipBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges13.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges13.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          lowerLipBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          lowerLipBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges18.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges18.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          lowerLipBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          lowerLipBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          lowerLipBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          lowerLipBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//nose to other points
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge1.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge1.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge1.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge1.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge1.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge1.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//right eyebrow and from right eyebrow to other points
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//left eyebrow and from left eyebrow to other points
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges30.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges30.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges34.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges34.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges34.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges34.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//right eye and other points for it
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEye12.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye12.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEye12.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye12.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEye4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEye4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//left eye and other points for it
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBridge0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBridge0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEyebrowBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEyebrowBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges30.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges30.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges28.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges28.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEye12.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye12.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEye12.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye12.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEye4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEye4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//right cheeks to other points
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEye8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          rightEye12.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightEye12.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          rightCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          rightCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//left cheeks to other points
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          noseBottom0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          noseBottom0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEye0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          leftEye12.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftEye12.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          upperLipTop0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          upperLipTop0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges26.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges26.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          leftCheek0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          leftCheek0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges28.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges28.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

//faceline
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges30.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges30.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges32.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges32.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges32.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges32.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges32.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges32.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges32.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges32.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges34.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges34.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges4.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges4.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges2.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges2.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges6.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges6.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges8.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges8.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges10.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges10.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges13.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges13.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges18.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges18.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges13.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges13.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges18.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges18.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges23.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges23.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges26.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges26.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges23.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges23.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges26.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges26.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges28.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges28.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges30.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges30.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges28.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges28.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges0.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges0.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      Offset(
        M7MathHelper.instance.translateX(
          faceEdges34.x.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
        M7MathHelper.instance.translateY(
          faceEdges34.y.toDouble(),
          rotation,
          size,
          absoluteImageSize,
        ),
      ),
      paint,
    );

    paintContour(FaceContourType.face);
    paintContour(FaceContourType.leftEyebrowTop);
    paintContour(FaceContourType.leftEyebrowBottom);
    paintContour(FaceContourType.rightEyebrowTop);
    paintContour(FaceContourType.rightEyebrowBottom);
    paintContour(FaceContourType.leftEye);
    paintContour(FaceContourType.rightEye);
    paintContour(FaceContourType.upperLipTop);
    paintContour(FaceContourType.upperLipBottom);
    paintContour(FaceContourType.lowerLipTop);
    paintContour(FaceContourType.lowerLipBottom);
    paintContour(FaceContourType.noseBridge);
    paintContour(FaceContourType.noseBottom);
    paintContour(FaceContourType.leftCheek);
    paintContour(FaceContourType.rightCheek);
  }

  @override
  bool shouldRepaint(M7FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.face != face;
  }
}
