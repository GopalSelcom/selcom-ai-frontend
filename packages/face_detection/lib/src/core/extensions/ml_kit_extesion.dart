// import 'package:m7_livelyness_detection/index.dart';

// extension MLKitUtils on AnalysisImage {
//   InputImage toInputImage() {
//     final planeData =
//         when(nv21: (img) => img.planes, bgra8888: (img) => img.planes)?.map(
//       (plane) {
//         return InputImagePlaneMetadata(
//           bytesPerRow: plane.bytesPerRow,
//           height: height,
//           width: width,
//         );
//       },
//     ).toList();

//     return when(nv21: (image) {
//       return InputImage.fromBytes(
//         bytes: image.bytes,
//         inputImageData: InputImageData(
//           imageRotation: inputImageRotation,
//           inputImageFormat: InputImageFormat.nv21,
//           planeData: planeData,
//           size: image.size,
//         ),
//       );
//     }, bgra8888: (image) {
//       final inputImageData = InputImageData(
//         size: size,
//         // FIXME: seems to be ignored on iOS...
//         imageRotation: inputImageRotation,
//         inputImageFormat: inputImageFormat,
//         planeData: planeData,
//       );

//       return InputImage.fromBytes(
//         bytes: image.bytes,
//         inputImageData: inputImageData,
//       );
//     })!;
//   }

//   InputImageRotation get inputImageRotation =>
//       InputImageRotation.values.byName(rotation.name);

//   InputImageFormat get inputImageFormat {
//     switch (format) {
//       case InputAnalysisImageFormat.bgra8888:
//         return InputImageFormat.bgra8888;
//       case InputAnalysisImageFormat.nv21:
//         return InputImageFormat.nv21;
//       default:
//         return InputImageFormat.yuv420;
//     }
//   }
// }

// import 'package:m7_livelyness_detection/index.dart';

// extension MLKitUtils on AnalysisImage {
//   InputImage toInputImage() {
//     List<ImagePlane>? planeData =
//         when(nv21: (img) => img.planes, bgra8888: (img) => img.planes)?.map(
//       (plane) {
//         return ImagePlane(
//           bytesPerRow: plane.bytesPerRow,
//           bytes: plane.bytes,
//           bytesPerPixel: plane.bytesPerRow,
//           height: height,
//           width: width,
//         );
//       },
//     ).toList();

//     return when(nv21: (image) {
//       return InputImage.fromBytes(
//         bytes: image.bytes,
//         metadata: InputImageMetadata(
//           rotation: inputImageRotation,
//           format: InputImageFormat.nv21,
//           bytesPerRow: planeData![0].bytesPerRow,
//           size: image.size,
//         ),
//       );
//     }, bgra8888: (image) {
//       final inputImageData = InputImageMetadata(
//         size: size,
//         rotation: inputImageRotation,
//         format: inputImageFormat,
//         bytesPerRow: planeData![0].bytesPerRow,
//       );

//       return InputImage.fromBytes(
//         bytes: image.bytes,
//         metadata: inputImageData,
//       );
//     })!;
//   }

//   InputImageRotation get inputImageRotation =>
//       InputImageRotation.values.byName(rotation.name);

//   InputImageFormat get inputImageFormat {
//     switch (format) {
//       case InputAnalysisImageFormat.bgra8888:
//         return InputImageFormat.bgra8888;
//       case InputAnalysisImageFormat.nv21:
//         return InputImageFormat.nv21;
//       default:
//         return InputImageFormat.yuv420;
//     }
//   }
// }

import 'package:m7_livelyness_detection/index.dart';

extension MLKitUtils on AnalysisImage {
  InputImage toInputImage() {
    final planeData =
        when(nv21: (img) => img.planes, bgra8888: (img) => img.planes)?.map(
      (plane) {
        return InputImageMetadata(
          size: Size(
            plane.width?.toDouble() ?? 0,
            plane.height?.toDouble() ?? 0,
          ),
          rotation: inputImageRotation,
          format: inputImageFormat,
          bytesPerRow: plane.bytesPerRow,
        );
      },
    ).toList();

    return when(
      nv21: (image) {
        return InputImage.fromBytes(
          bytes: image.bytes,
          metadata: InputImageMetadata(
            size: size,
            rotation: inputImageRotation,
            format: inputImageFormat,
            bytesPerRow: planeData!.first.bytesPerRow,
          ),
          // inputImageData: InputImageData(
          //   imageRotation: inputImageRotation,
          //   inputImageFormat: InputImageFormat.nv21,
          //   planeData: planeData,
          //   size: image.size,
          // ),
        );
      },
      bgra8888: (image) {
        final inputImageData = InputImageMetadata(
          size: size,
          rotation: inputImageRotation,
          format: inputImageFormat,
          bytesPerRow: planeData!.first.bytesPerRow,
        );

        return InputImage.fromBytes(
          bytes: image.bytes,
          metadata: inputImageData,
        );
      },
    )!;
  }

  InputImageRotation get inputImageRotation =>
      InputImageRotation.values.byName(rotation.name);

  InputImageFormat get inputImageFormat {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}
