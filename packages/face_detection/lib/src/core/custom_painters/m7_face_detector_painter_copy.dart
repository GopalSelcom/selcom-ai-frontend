// //sky_engine/lib/ui/painting.dart
// import 'package:m7_livelyness_detection/index.dart';

// class M7FaceDetectorPainter extends CustomPainter {
//   M7FaceDetectorPainter(
//     this.face,
//     this.absoluteImageSize,
//     this.rotation,
//   );

//   final Face face;
//   final Size absoluteImageSize;
//   final InputImageRotation rotation;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = M7LivelynessDetection.instance.contourLineWidth ?? 1.0
//       ..color = M7LivelynessDetection.instance.contourLineColor ??
//           const Color(0xffab48e0);

//     final List<Point<int>> faceEdges =
//         face.contours[FaceContourType.face]?.points ?? [];

//     //* MARK: - Left Side
//     //? =========================================================
//     final List<Point<int>> leftEyebrowBottom =
//         face.contours[FaceContourType.leftEyebrowBottom]?.points ?? [];
//     final List<Point<int>> leftEyebrowTop =
//         face.contours[FaceContourType.leftEyebrowTop]?.points ?? [];
//     final List<Point<int>> leftEye =
//         face.contours[FaceContourType.leftEye]?.points ?? [];
//     final List<Point<int>> leftCheek =
//         face.contours[FaceContourType.leftCheek]?.points ?? [];

//     //* MARK: - Right Side
//     //? =========================================================
//     final List<Point<int>> rightEyebrowTop =
//         face.contours[FaceContourType.rightEyebrowTop]?.points ?? [];
//     final List<Point<int>> rightEyebrowBottom =
//         face.contours[FaceContourType.rightEyebrowBottom]?.points ?? [];
//     final List<Point<int>> rightEye =
//         face.contours[FaceContourType.rightEye]?.points ?? [];
//     final List<Point<int>> rightCheek =
//         face.contours[FaceContourType.rightCheek]?.points ?? [];

//     //* MARK: - Nose
//     //? =========================================================
//     final List<Point<int>> noseBottom =
//         face.contours[FaceContourType.noseBottom]?.points ?? [];
//     final List<Point<int>> noseBridge =
//         face.contours[FaceContourType.noseBridge]?.points ?? [];

//     //* MARK: - Lips
//     //? =========================================================
//     final List<Point<int>> upperLipTop =
//         face.contours[FaceContourType.upperLipTop]?.points ?? [];
//     final List<Point<int>> upperLipBottom =
//         face.contours[FaceContourType.upperLipBottom]?.points ?? [];

//     final List<Point<int>> lowerLipTop =
//         face.contours[FaceContourType.lowerLipTop]?.points ?? [];
//     final List<Point<int>> lowerLipBottom =
//         face.contours[FaceContourType.lowerLipBottom]?.points ?? [];

//     final List<Point<int>> rightEyebrowTopR = rightEyebrowTop.reversed.toList();
//     // final List<Point<int>> rightEyebrowTopR2 = rightEyebrowTop.toList();
//     // final List<Point<int>> rightEyebrowBottomR =
//     //     rightEyebrowBottom.reversed.toList();
//     // final List<Point<int>> rightEyebrowBottomR2 = rightEyebrowBottom.toList();
//     final List<Point<int>> rightEyeTop = rightEye.toList();
//     final List<Point<int>> faceEdges1 = faceEdges.toList();
//     final List<Point<int>> noseBridge1 = noseBridge.toList();
//     final List<Point<int>> leftEyeTop = leftEye.toList();
//     final List<Point<int>> noseBottom1 = noseBottom.toList();
//     final List<Point<int>> upperLipTop1 = upperLipTop.toList();
//     final List<Point<int>> lowerLipBottom1 = lowerLipBottom.toList();
//     final List<Point<int>> leftCheek1 = leftCheek.toList();
//     final List<Point<int>> rightCheek1 = rightCheek.toList();
//     final List<Point<int>> leftEyebrowTop1 = leftEyebrowTop.toList();
//     final List<Point<int>> rightEyebrowTop1 = rightEyebrowTop.toList();
//     final List<Point<int>> rightEyebrowBottom1 = rightEyebrowBottom.toList();
//     final List<Point<int>> leftEyebrowBottom1 = leftEyebrowBottom.toList();
//     // final List<Point<int>> leftEyebrowTopR = leftEyebrowTop.reversed.toList();
//     // final List<Point<int>> leftEyebrowTopR2 = leftEyebrowTop.toList();
//     // final List<Point<int>> rightEyeBottom = rightEye.toList();

//     void paintContour(FaceContourType type) {
//       final faceContour = face.contours[type];
//       if (faceContour?.points != null && (type == FaceContourType.face) ||
//               (type == FaceContourType.leftEye) ||
//               (type == FaceContourType.rightEye) ||
//               (type == FaceContourType.noseBridge) ||
//               // (type == FaceContourType.noseBottom) ||
//               (type == FaceContourType.upperLipTop) ||
//               (type == FaceContourType.lowerLipBottom) ||
//               (type == FaceContourType.leftEyebrowBottom) ||
//               (type == FaceContourType.rightEyebrowBottom)
//           //  ||
//           // (type == FaceContourType.leftEyebrowTop) ||
//           // (type == FaceContourType.rightEyebrowTop)
//           ) {
//         for (var i = 0; i < faceContour!.points.length; i++) {
//           final Point<int> p1 = faceContour.points[i];
//           if (i + 1 < faceContour.points.length) {
//             final Point<int> p2 = faceContour.points[i + 1];
//             canvas.drawLine(
//               Offset(
//                 M7MathHelper.instance.translateX(
//                   p1.x.toDouble(),
//                   rotation,
//                   size,
//                   absoluteImageSize,
//                 ),
//                 M7MathHelper.instance.translateY(
//                   p1.y.toDouble(),
//                   rotation,
//                   size,
//                   absoluteImageSize,
//                 ),
//               ),
//               Offset(
//                 M7MathHelper.instance.translateX(
//                   p2.x.toDouble(),
//                   rotation,
//                   size,
//                   absoluteImageSize,
//                 ),
//                 M7MathHelper.instance.translateY(
//                   p2.y.toDouble(),
//                   rotation,
//                   size,
//                   absoluteImageSize,
//                 ),
//               ),
//               paint,
//             );
//           }
//         }
//         for (final Point point in faceContour.points) {
//           canvas.drawCircle(
//             Offset(
//               M7MathHelper.instance.translateX(
//                 point.x.toDouble(),
//                 rotation,
//                 size,
//                 absoluteImageSize,
//               ),
//               M7MathHelper.instance.translateY(
//                 point.y.toDouble(),
//                 rotation,
//                 size,
//                 absoluteImageSize,
//               ),
//             ),
//             1,
//             paint,
//           );
//         }
//       }
//     }

//     for (var i = 1; i < rightEyebrowTop1.length; i++) {
//       final Point<int> p1 = rightEyebrowTop1[i];
//       if (i + 1 < rightEyebrowTop1.length) {
//         final Point<int> p2 = rightEyebrowTop1[i + 1];
//         canvas.drawLine(
//           Offset(
//             M7MathHelper.instance.translateX(
//               p1.x.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//             M7MathHelper.instance.translateY(
//               p1.y.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//           ),
//           Offset(
//             M7MathHelper.instance.translateX(
//               p2.x.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//             M7MathHelper.instance.translateY(
//               p2.y.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//           ),
//           paint,
//         );
//       }
//     }
//     for (var i = 1; i < leftEyebrowTop1.length; i++) {
//       final Point<int> p1 = leftEyebrowTop1[i];
//       if (i + 1 < leftEyebrowTop1.length) {
//         final Point<int> p2 = leftEyebrowTop1[i + 1];
//         canvas.drawLine(
//           Offset(
//             M7MathHelper.instance.translateX(
//               p1.x.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//             M7MathHelper.instance.translateY(
//               p1.y.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//           ),
//           Offset(
//             M7MathHelper.instance.translateX(
//               p2.x.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//             M7MathHelper.instance.translateY(
//               p2.y.toDouble(),
//               rotation,
//               size,
//               absoluteImageSize,
//             ),
//           ),
//           paint,
//         );
//       }
//     }

//     for (var i = 0; i < rightEyebrowTopR.length; i++) {
//       final Point<int> p1 = rightEyeTop[0];
//       final Point<int> p2 = leftEyeTop[8];
//       final Point<int> p3 = noseBridge1[0];
//       final Point<int> p4 = noseBridge1[1];
//       final Point<int> p5 = noseBottom1[0];
//       final Point<int> p6 = noseBottom1[2];
//       final Point<int> p7 = upperLipTop1[0];
//       final Point<int> p8 = upperLipTop1[10];
//       final Point<int> p9 = lowerLipBottom1[0];
//       final Point<int> p10 = lowerLipBottom1[8];
//       final Point<int> p11 = leftCheek1[0];
//       final Point<int> p12 = rightCheek1[0];
//       final Point<int> p13 = rightEyeTop[8];
//       final Point<int> p14 = leftEyeTop[0];
//       final Point<int> p15 = rightEyebrowBottom1[4];
//       final Point<int> p19 = rightEyebrowTop1[4];
//       final Point<int> p16 = rightEyebrowBottom1[0];
//       final Point<int> p20 = rightEyebrowTop1[1];
//       final Point<int> p17 = leftEyebrowBottom1[4];
//       final Point<int> p21 = leftEyebrowTop1[4];
//       final Point<int> p18 = leftEyebrowBottom1[0];
//       final Point<int> p22 = leftEyebrowTop1[1];
//       final Point<int> p23 = faceEdges1[1];
//       final Point<int> p24 = faceEdges1[4];
//       final Point<int> p25 = faceEdges1[6];
//       final Point<int> p39 = faceEdges1[5];
//       final Point<int> p26 = faceEdges1[7];
//       final Point<int> p27 = faceEdges1[9];
//       final Point<int> p28 = faceEdges1[11];
//       final Point<int> p29 = faceEdges1[12];
//       final Point<int> p30 = faceEdges1[18];
//       final Point<int> p31 = faceEdges1[23];
//       final Point<int> p32 = faceEdges1[25];
//       final Point<int> p33 = faceEdges1[27];
//       final Point<int> p34 = faceEdges1[29];
//       final Point<int> p35 = faceEdges1[30];
//       final Point<int> p36 = faceEdges1[34];
//       final Point<int> p37 = lowerLipBottom1[6];
//       final Point<int> p38 = lowerLipBottom1[3];
//       final Point<int> p40 = faceEdges1[31];
//       final Point<int> p41 = faceEdges1[35];
//       final Point<int> p42 = faceEdges1[0];

//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p42.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p42.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p41.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p41.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p42.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p42.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p42.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p42.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p19.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p19.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p41.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p41.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p21.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p21.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p41.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p41.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p22.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p22.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p40.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p40.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p20.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p20.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p39.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p39.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p20.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p20.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p39.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p39.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p20.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p20.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p39.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p39.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );

//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p16.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p16.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p25.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p25.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p16.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p16.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p26.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p26.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p13.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p13.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p26.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p26.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p13.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p13.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p27.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p27.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p12.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p12.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p27.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p27.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p12.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p12.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p27.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p27.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p8.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p8.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p28.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p28.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p8.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p8.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p29.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p29.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p38.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p38.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p29.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p29.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p38.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p38.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p30.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p30.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p37.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p37.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p30.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p30.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p37.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p37.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p31.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p31.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p7.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p7.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p31.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p31.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p7.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p7.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p32.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p32.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p14.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p14.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p33.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p33.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p14.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p14.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p34.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p34.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p11.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p11.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p33.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p33.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p18.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p18.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p34.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p34.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p18.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p18.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p35.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p35.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p19.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p19.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p23.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p23.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p20.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p20.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p23.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p23.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p21.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p21.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p36.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p36.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p22.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p22.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p36.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p36.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p21.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p21.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p17.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p17.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p19.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p19.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p15.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p15.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p16.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p16.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p20.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p20.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p15.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p15.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p19.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p19.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p21.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p21.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p17.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p17.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p18.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p18.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p22.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p22.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p12.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p12.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p6.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p6.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p11.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p11.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p5.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p5.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p12.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p12.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p13.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p13.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p12.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p12.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
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
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p11.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p11.y.toDouble(),
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
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p11.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p11.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p14.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p14.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p6.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p6.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p8.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p8.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p5.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p5.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p7.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p7.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p6.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p6.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p5.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p5.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );

//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p4.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p4.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p5.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p5.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p4.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p4.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p6.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p6.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
//         Offset(
//           M7MathHelper.instance.translateX(
//             p4.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p4.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         Offset(
//           M7MathHelper.instance.translateX(
//             p6.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p6.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
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
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//       canvas.drawLine(
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
//         Offset(
//           M7MathHelper.instance.translateX(
//             p3.x.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//           M7MathHelper.instance.translateY(
//             p3.y.toDouble(),
//             rotation,
//             size,
//             absoluteImageSize,
//           ),
//         ),
//         paint,
//       );
//     }

//     paintContour(FaceContourType.face);
//     paintContour(FaceContourType.leftEyebrowTop);
//     paintContour(FaceContourType.leftEyebrowBottom);
//     paintContour(FaceContourType.rightEyebrowTop);
//     paintContour(FaceContourType.rightEyebrowBottom);
//     paintContour(FaceContourType.leftEye);
//     paintContour(FaceContourType.rightEye);
//     paintContour(FaceContourType.upperLipTop);
//     paintContour(FaceContourType.upperLipBottom);
//     paintContour(FaceContourType.lowerLipTop);
//     paintContour(FaceContourType.lowerLipBottom);
//     paintContour(FaceContourType.noseBridge);
//     paintContour(FaceContourType.noseBottom);
//     paintContour(FaceContourType.leftCheek);
//     paintContour(FaceContourType.rightCheek);
//   }

//   @override
//   bool shouldRepaint(M7FaceDetectorPainter oldDelegate) {
//     return oldDelegate.absoluteImageSize != absoluteImageSize ||
//         oldDelegate.face != face;
//   }
// }


// //! TODO: - Kept for future release
// //? =========================================================
// // class M7MeshPainter extends CustomPainter {
// //   M7MeshPainter(
// //     this.face,
// //     this.absoluteImageSize,
// //     this.rotation,
// //   );

// //   final Face face;
// //   final Size absoluteImageSize;
// //   final InputImageRotation rotation;

// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final Paint paint = Paint()
// //       ..style = PaintingStyle.stroke
// //       ..strokeWidth = 1.0
// //       ..color = const Color(0xffab48e0);

// //     final Paint paint2 = Paint()
// //       ..style = PaintingStyle.stroke
// //       ..strokeWidth = 2.0
// //       ..color = Colors.red;

// //     void paintContour(FaceContourType type) {
// //       final faceContour = face.contours[type];
// //       if (faceContour?.points != null) {
// //         for (final Point point in faceContour!.points) {
// //           canvas.drawCircle(
// //             Offset(
// //               M7MathHelper.instance.translateX(
// //                 point.x.toDouble(),
// //                 rotation,
// //                 size,
// //                 absoluteImageSize,
// //               ),
// //               M7MathHelper.instance.translateY(
// //                 point.y.toDouble(),
// //                 rotation,
// //                 size,
// //                 absoluteImageSize,
// //               ),
// //             ),
// //             1,
// //             paint,
// //           );
// //         }
// //       }
// //     }

// //     void dwarLine({
// //       required int px,
// //       required int py,
// //       required int qx,
// //       required int qy,
// //     }) {
// //       canvas.drawLine(
// //         Offset(
// //           M7MathHelper.instance.translateX(
// //             px.toDouble(),
// //             rotation,
// //             size,
// //             absoluteImageSize,
// //           ),
// //           M7MathHelper.instance.translateY(
// //             py.toDouble(),
// //             rotation,
// //             size,
// //             absoluteImageSize,
// //           ),
// //         ),
// //         Offset(
// //           M7MathHelper.instance.translateX(
// //             qx.toDouble(),
// //             rotation,
// //             size,
// //             absoluteImageSize,
// //           ),
// //           M7MathHelper.instance.translateY(
// //             qy.toDouble(),
// //             rotation,
// //             size,
// //             absoluteImageSize,
// //           ),
// //         ),
// //         paint2,
// //       );
// //     }

// //     final List<Point<int>> faceEdges =
// //         face.contours[FaceContourType.face]?.points ?? [];

// //     //* MARK: - Left Side
// //     //? =========================================================
// //     final List<Point<int>> leftEyebrowBottom =
// //         face.contours[FaceContourType.leftEyebrowBottom]?.points ?? [];
// //     final List<Point<int>> leftEyebrowTop =
// //         face.contours[FaceContourType.leftEyebrowTop]?.points ?? [];
// //     final List<Point<int>> leftEye =
// //         face.contours[FaceContourType.leftEye]?.points ?? [];
// //     final List<Point<int>> leftCheek =
// //         face.contours[FaceContourType.leftCheek]?.points ?? [];

// //     //* MARK: - Right Side
// //     //? =========================================================
// //     final List<Point<int>> rightEyebrowTop =
// //         face.contours[FaceContourType.rightEyebrowTop]?.points ?? [];
// //     final List<Point<int>> rightEyebrowBottom =
// //         face.contours[FaceContourType.rightEyebrowBottom]?.points ?? [];
// //     final List<Point<int>> rightEye =
// //         face.contours[FaceContourType.rightEye]?.points ?? [];
// //     final List<Point<int>> rightCheek =
// //         face.contours[FaceContourType.rightCheek]?.points ?? [];

// //     //* MARK: - Nose
// //     //? =========================================================
// //     final List<Point<int>> noseBottom =
// //         face.contours[FaceContourType.noseBottom]?.points ?? [];
// //     final List<Point<int>> noseBridge =
// //         face.contours[FaceContourType.noseBridge]?.points ?? [];

// //     //* MARK: - Lips
// //     //? =========================================================
// //     final List<Point<int>> upperLipTop =
// //         face.contours[FaceContourType.upperLipTop]?.points ?? [];
// //     final List<Point<int>> upperLipBottom =
// //         face.contours[FaceContourType.upperLipBottom]?.points ?? [];

// //     final List<Point<int>> lowerLipTop =
// //         face.contours[FaceContourType.lowerLipTop]?.points ?? [];
// //     final List<Point<int>> lowerLipBottom =
// //         face.contours[FaceContourType.lowerLipBottom]?.points ?? [];

// //     final List<List<Point<int>>> partitions = faceEdges.splitInChunks(
// //       chunkSize: faceEdges.length ~/ 4,
// //     );
// //     if (partitions.length != 4) {
// //       return;
// //     }

// //     //* MARK: - Top Right
// //     //? =========================================================
// //     final List<Point<int>> topRightFaceEdges = partitions[0];
// //     if (topRightFaceEdges.length == 9) {
// //       final List<Point<int>> rightEyebrowTopR =
// //           rightEyebrowTop.reversed.toList();
// //       for (var i = 0; i < rightEyebrowTopR.length; i++) {
// //         final p0 = rightEyebrowTopR[i];
// //         final p1 = topRightFaceEdges[i];
// //         dwarLine(
// //           px: p0.x,
// //           py: p0.y,
// //           qx: p1.x,
// //           qy: p1.y,
// //         );
// //       }
// //     }

// //     //* MARK: - Bottom Right
// //     //? =========================================================
// //     final List<Point<int>> bottomRightFaceEdges = partitions[1];
// //     if (bottomRightFaceEdges.length == 9) {
// //       final List<Point<int>> rightEyeBottom = rightEye
// //           .splitInChunks(
// //             chunkSize: rightEye.length ~/ 2,
// //           )
// //           .last;

// //       for (var i = 0; i < rightEyeBottom.length; i++) {
// //         final p0 = M7Utils.middlePoint(
// //           from: rightEyeBottom[i],
// //           to: bottomRightFaceEdges[i],
// //         );
// //         final p1 = bottomRightFaceEdges[i];
// //         dwarLine(
// //           px: p0.x,
// //           py: p0.y,
// //           qx: p1.x,
// //           qy: p1.y,
// //         );
// //         if (i != rightEye.length - 1) {
// //           final p2 = rightEyeBottom[i + 1];
// //           dwarLine(
// //             px: p0.x,
// //             py: p0.y,
// //             qx: p2.x,
// //             qy: p2.y,
// //           );
// //         }
// //       }
// //     }
// //   }

// //   @override
// //   bool shouldRepaint(M7MeshPainter oldDelegate) {
// //     return oldDelegate.absoluteImageSize != absoluteImageSize ||
// //         oldDelegate.face != face;
// //   }
// // }
