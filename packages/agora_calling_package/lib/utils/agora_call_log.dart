import 'dart:developer' as developer;
import 'dart:io';

/// Optional sink (e.g. Firebase Crashlytics) — register per isolate in
/// [main] and in the FCM background handler (isolates do not share memory).
typedef AgoraLogSink = void Function(String message);

AgoraLogSink? agoraLogSink;

/// Register a release-safe log sink for the **current** isolate.
void registerAgoraLogSink(AgoraLogSink? sink) {
  agoraLogSink = sink;
}

/// Always-on diagnostics for in-app calling (debug and release builds).
///
/// Release note: Flutter prints to logcat tag `flutter`, not your app tag.
/// Filter with: `adb logcat -s flutter` or `adb logcat | findstr KILL_CALL`
@pragma('vm:entry-point')
void agoraCallLog(String message) {
  final line = message.trim();
  developer.log(line, name: 'AGORA_CALL');
  // Multiple sinks — some OEM log viewers only show one of these.
  // ignore: avoid_print
  print(line);
  // ignore: avoid_print
  print('AGORA_CALL $line');
  try {
    stderr.writeln(line);
    stderr.writeln('AGORA_CALL $line');
  } catch (_) {}
  try {
    agoraLogSink?.call(line);
  } catch (_) {}
}

/// Killed / background-isolate diagnostics — grep logcat with `KILL_CALL`.
///
/// Stages: `FCM_BG`, `CALLKIT`, `COLD_START`, `ACCEPT`, `VOIP`.
@pragma('vm:entry-point')
void killStateCallLog(String stage, String message) {
  agoraCallLog('[KILL_CALL][$stage] $message');
  if (Platform.isAndroid) {
    // Extra tag line — easier to spot in noisy logcat buffers.
    agoraCallLog('[KILL_CALL][ANDROID][$stage] $message');
  }
}
