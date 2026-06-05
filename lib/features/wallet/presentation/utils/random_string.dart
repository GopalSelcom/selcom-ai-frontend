import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/error_reporting/error_reporter.dart';

String generateRandomString({String? msg}) {
  math.Random random = math.Random();
  String result = '';

  for (int i = 0; i < 10; i++) {
    // Generate a random number between 0 and 9 and convert it to a string
    int randomNumber = random.nextInt(10);
    result += randomNumber.toString();
  }

  debugPrint("$msg ------> $result");
  return result;
}

String getInitials(String name) {
  // Split the name by space and filter out any empty strings
  List<String> nameParts = name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .toList();

  // Extract the first character of each part
  List<String> initials = nameParts
      .map((part) => part[0].toUpperCase())
      .toList();

  // Combine the initials into a single string and limit to a maximum of three initials
  return initials.take(3).join('');
}

String generateUniqueIDFromText(String text) {
  // Convert the ticket number to bytes
  Uint8List bytes = utf8.encode(text);

  // Generate a hash from the bytes
  Digest hash = sha256.convert(bytes);

  // Convert the hash to a hexadecimal string
  return hash.toString();
}

({String date, String time}) extractDateAndTime(String input) {
  try {
    final dt = DateTime.parse(input);

    final dateFinal = DateFormat(
      "MMM dd, yyyy",
    ).format(dt); // e.g. Nov 14, 2023
    final timeFinal = DateFormat("h:mm a").format(dt); // e.g. 7:20 PM

    return (date: dateFinal, time: timeFinal);
  } catch (e, stackTrace) {
    ErrorReporter.instance.report(
      error: e,
      stackTrace: stackTrace,
      customMessage: "RandomString.extractDateAndTime failed",
      extraData: [{"input": input}],
    );

    return (date: "", time: "");
  }
}

String convertToISO8601(String inputDate) {
  try {
    // Parse the input date
    DateTime parsedDate =
        DateTime.tryParse(inputDate.replaceAll(' ', 'T')) ?? DateTime.now();

    // Format the date to ISO 8601 without the offset
    String formattedDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(parsedDate) + ".52";

    return formattedDate;
  } catch (e, stackTrace) {
    ErrorReporter.instance.report(
      error: e,
      stackTrace: stackTrace,
      customMessage: "RandomString.convertToISO8601 failed",
      extraData: [{"inputDate": inputDate}],
    );

    debugPrint("convertToISO8601Format Exception: $e");
  }

  String formattedDate =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(DateTime.now()) + ".52";

  return formattedDate;
}

String abbreviateCityName(String cityName) {
  // Remove spaces and make the city name lowercase
  String name = cityName.replaceAll(' ', '').toLowerCase();

  // If the name is shorter than or equal to 3 characters, return it as is
  if (name.length <= 3) {
    return name;
  }

  // Otherwise, return the first three characters
  return name.substring(0, 3).toUpperCase();
}
