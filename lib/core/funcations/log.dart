// ignore_for_file: unused_import, avoid_print

import 'dart:developer';
import 'package:flutter/foundation.dart';

enum ConsoleType { debug, release, both }

class LogHandler {
  static ConsoleType get consoleType => ConsoleType.debug;
}

void devLog(
  Object? message, {
  Object? error,
  StackTrace? stackTrace,
  String? name,
}) {
  switch (LogHandler.consoleType) {
    case ConsoleType.debug:
      if (kDebugMode) {
        // debug: use this for long text in the console.
        // e.g. api logs
        log(
          "[${_printCurrentTime()}] $message",
          error: error,
          stackTrace: stackTrace,
          name: name ?? "",
        );
      }
      break;
    case ConsoleType.release:
      if (name != null) {
        name = "[$name] ";
      } else {
        name = "";
      }
      // release: use this to log in release mode
      // it will not print the long logs
      print("[release] [${_printCurrentTime()}] $name$message");
      break;
    case ConsoleType.both:
      if (name != null) {
        name = "[$name] ";
      } else {
        name = "";
      }
      // release: use this to log in release mode
      // it will not print the long logs
      print("[debug&release] [${_printCurrentTime()}] $name$message");
      break;
  }
}

String _printCurrentTime() {
  DateTime now = DateTime.now();
  String formattedTime =
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}.'
      '${now.millisecond.toString().padLeft(3, '0')}:'
      '${now.microsecond.toString().padLeft(6, '0')}';
  return formattedTime;
}
