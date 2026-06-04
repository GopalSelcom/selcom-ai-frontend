import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as cropper;

class FaceCropper {
  static const _maxFaceDetectEdge = 1920;

  /// Detects the face in the passport placeholder image, crops it, and saves JPEG.
  static Future<File?> cropFace(File imageFile, String outputPath) async {
    try {
      cropper.Image? documentImage =
          cropper.decodeImage(await imageFile.readAsBytes());
      if (documentImage == null) return null;
      documentImage = cropper.bakeOrientation(documentImage);

      final longest = documentImage.width > documentImage.height
          ? documentImage.width
          : documentImage.height;
      if (longest > _maxFaceDetectEdge) {
        final scale = _maxFaceDetectEdge / longest;
        documentImage = cropper.copyResize(
          documentImage,
          width: (documentImage.width * scale).round(),
          height: (documentImage.height * scale).round(),
          interpolation: cropper.Interpolation.linear,
        );
      }

      final tempDir = imageFile.parent;
      final bakedFile = File(
        '${tempDir.path}/temp_baked_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await bakedFile.writeAsBytes(cropper.encodePng(documentImage));

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      List<Face> faces = [];
      cropper.Image currentImage = documentImage;
      File currentFile = bakedFile;

      for (var i = 0; i < 4; i++) {
        faces = await faceDetector.processImage(
          InputImage.fromFile(currentFile),
        );
        if (faces.isNotEmpty) break;

        currentImage = cropper.copyRotate(currentImage, angle: 90);
        await currentFile.writeAsBytes(cropper.encodePng(currentImage));
      }

      await faceDetector.close();

      if (faces.isEmpty) {
        if (await bakedFile.exists()) await bakedFile.delete();
        return null;
      }

      final rawX = faces.first.boundingBox.left.toInt();
      final rawY = faces.first.boundingBox.top.toInt();
      final rawW = faces.first.boundingBox.width.toInt();
      final rawH = faces.first.boundingBox.height.toInt();

      final paddingX = (rawW * 0.30).toInt();
      final paddingY = (rawH * 0.30).toInt();

      final targetX = rawX - paddingX;
      final targetY = rawY - paddingY;
      final targetW = rawW + (paddingX * 2);
      final targetH = rawH + (paddingY * 2);

      final x = targetX.clamp(0, currentImage.width - 1);
      final y = targetY.clamp(0, currentImage.height - 1);
      final w = targetW.clamp(1, currentImage.width - x);
      final h = targetH.clamp(1, currentImage.height - y);

      final userFaceImage = cropper.copyCrop(
        currentImage,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      final jpgPath = outputPath.endsWith('.jpg')
          ? outputPath
          : outputPath.replaceAll(
              RegExp(r'\.(png|jpeg)$', caseSensitive: false),
              '.jpg',
            );
      final out = File(jpgPath);
      await out.writeAsBytes(cropper.encodeJpg(userFaceImage, quality: 90));

      if (await bakedFile.exists()) await bakedFile.delete();
      return out;
    } catch (e) {
      debugPrint('FaceCropper: $e');
      return null;
    }
  }
}
