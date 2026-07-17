/// Converts book/active ride API `cancel_time` (milliseconds) to the driver-search
/// countdown length in whole seconds.
int driverSearchTimeoutSecondsFromCancelTimeMillis(
  dynamic rawCancelTime, {
  int defaultSeconds = 540,
  int minSeconds = 60,
  int maxSeconds = 3600,
}) {
  int? ms;
  if (rawCancelTime is int) {
    ms = rawCancelTime;
  } else if (rawCancelTime is num) {
    ms = rawCancelTime.toInt();
  }
  if (ms == null || ms <= 0) return defaultSeconds;
  final seconds = (ms / 1000).round();
  return seconds.clamp(minSeconds, maxSeconds);
}

DateTime? parseDriverSearchStartedAt(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim());
  }
  return null;
}

/// Remaining driver-search seconds from wall-clock elapsed time since search began.
int driverSearchRemainingSeconds({
  required int timeoutSeconds,
  DateTime? searchStartedAt,
  DateTime? fallbackStartAt,
  DateTime? now,
}) {
  final start = searchStartedAt ?? fallbackStartAt;
  if (start == null) return timeoutSeconds;
  final elapsed = (now ?? DateTime.now()).difference(start).inSeconds;
  return (timeoutSeconds - elapsed).clamp(0, timeoutSeconds);
}
