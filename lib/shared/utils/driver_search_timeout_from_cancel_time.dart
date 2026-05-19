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
