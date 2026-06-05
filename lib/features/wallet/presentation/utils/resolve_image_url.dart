import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/services/error_reporting/error_reporter.dart';


Future<String> resolveImageUrl(String? imagePath) async {
  if (imagePath == null || imagePath.isEmpty) {
    return "";
  }

  // If already a URL, return directly
  if (imagePath.startsWith("http")) {
    return imagePath;
  }

  // Otherwise, decrypt after extracting part after `.com`
  //todo return await decryptBackendResponse(encryptedData: imagePath);
  return "";
}

Future<String> fileToBase64(String filePath) async {
  try {
    File file = File(filePath);
    Uint8List fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  } catch (e, stackTrace) {
    ErrorReporter.instance.report(
      error: e,
      stackTrace: stackTrace,
      customMessage: "Error converting file to Base64",
      extraData: [{"filePath": filePath}],
    );
    debugPrint("Error converting file to Base64: $e");
    return "";
  }
}
