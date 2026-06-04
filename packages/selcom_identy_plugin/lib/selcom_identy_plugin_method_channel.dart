import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'selcom_identy_plugin_platform_interface.dart';

/// An implementation of [SelcomIdentyPluginPlatform] that uses method channels.
class MethodChannelSelcomIdentyPlugin extends SelcomIdentyPluginPlatform {
  @visibleForTesting
  final MethodChannel channel = const MethodChannel('selcom_identy_plugin');
  bool isLeftHandSelected = false;

  @override
  Future<dynamic> enrollFinger({required Map<String, dynamic> data}) async {
    try {
      isLeftHandSelected = data["leftHandSelected"];
      var result = await channel.invokeMethod('enrollFinger', data);
      if (result != null &&
          result != "" &&
          result != "null" &&
          result != "500" &&
          !result.toString().contains("IDENTY_ERROR")) {
        if (result.runtimeType == String) {
          return result = convertIdentyResponseToJson(jsonDecode(result));
        } else {
          return result;
        }
      } else {
        return result;
      }
    } on PlatformException catch (e) {
      log("SelcomIdentyPluginPlatform : Failed to call native method: '${e.message}'.");
    }
  }

  Map<String, dynamic> convertIdentyResponseToJson(
      Map<String, dynamic> originalJson) {
    Map<String, dynamic> convertedData = {};

    // Define the order of fingers to ensure sorting
    List<String> orderedFingers = ["finger1", "finger2", "finger3", "finger4"];

    // Map each finger key in the original JSON to the fixed positions
    Map<String, String> fingerMapping = {
      "rightindex": "finger1",
      "rightmiddle": "finger2",
      "rightring": "finger3",
      "rightlittle": "finger4",
      "leftindex": "finger1",
      "leftmiddle": "finger2",
      "leftring": "finger3",
      "leftlittle": "finger4"
    };

    // Temporary map to store the fingers in the converted format
    Map<String, dynamic> tempData = {};

    // Loop through the original JSON and add only present fingers to tempData
    originalJson["data"].forEach((key, value) {
      if (fingerMapping.containsKey(key)) {
        String fingerPosition = fingerMapping[key]!;
        tempData[fingerPosition] = {
          "hand": isLeftHandSelected ? "left" : "right",
          "finger": value["finger"].toLowerCase(),
          "WSQ": Platform.isAndroid
              ? value["templates"]["WSQ"]["DEFAULT"]
              : value["templates"]["WSQ"][0]["DEFAULT"]
        };
      }
    });

    // Ensure the final data is ordered according to the specified order
    for (String finger in orderedFingers) {
      if (tempData.containsKey(finger)) {
        convertedData[finger] = tempData[finger];
      }
    }

    // Return the final JSON structure with ordered fingers
    return {
      "data": convertedData,
      "hand_type": isLeftHandSelected ? "left" : "right"
    };
  }
}
