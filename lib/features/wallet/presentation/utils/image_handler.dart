import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ImageHandler {
  Future<File> saveImageFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    // Get the temporary directory of the device
    final directory = await getTemporaryDirectory();

    // Create the path for the image file
    final imagePath = '${directory.path}/$fileName';

    // Create the file and write the bytes to it
    final file = File(imagePath);
    return await file.writeAsBytes(bytes);
  }

  Future<File> decodeAndSaveImage({
    required String base64String,
    required String fileName,
  }) async {
    // Decode the Base64 string to Uint8List
    Uint8List bytes = base64.decode(base64String);

    // Save the bytes to an image file
    return await saveImageFile(bytes: bytes, fileName: fileName);
  }
}