/// Backend-owned no-show wait banner (`no_show` object on status / active rides).
///
/// Distinct from the terminal cancel flag `no_show: true` on a cancelled status
/// event — that boolean is handled on [EventRiderStatusUpdateResponse.isNoShowCancellation].
///
/// Title/subtitle/fee are pre-rendered; countdown uses absolute [fireAt] only.
class RideNoShowInfoModel {
  final DateTime fireAt;
  final int waitMinutes;
  final int fee;
  final String title;
  final String subtitle;

  const RideNoShowInfoModel({
    required this.fireAt,
    required this.waitMinutes,
    required this.fee,
    required this.title,
    required this.subtitle,
  });

  factory RideNoShowInfoModel.fromJson(Map<String, dynamic> json) {
    final fireAtRaw = json['fire_at']?.toString();
    final fireAt =
        DateTime.tryParse(fireAtRaw ?? '')?.toUtc() ??
        DateTime.now().toUtc();

    return RideNoShowInfoModel(
      fireAt: fireAt,
      waitMinutes: (json['wait_minutes'] as num?)?.toInt() ?? 0,
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString().trim() ?? '',
      subtitle: json['subtitle']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'fire_at': fireAt.toIso8601String(),
    'wait_minutes': waitMinutes,
    'fee': fee,
    'title': title,
    'subtitle': subtitle,
  };

  /// Remaining time until [fireAt]; never negative.
  Duration remainingAt([DateTime? nowUtc]) {
    final now = (nowUtc ?? DateTime.now().toUtc());
    final remaining = fireAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String formatRemainingMmSs([DateTime? nowUtc]) {
    final remaining = remainingAt(nowUtc);
    final totalSeconds = remaining.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Prefer [primary] timing/fees; keep non-empty title/subtitle from [fallback]
  /// when primary omits them (ride-details payload often has no copy).
  RideNoShowInfoModel mergingDisplayFrom(RideNoShowInfoModel? fallback) {
    if (fallback == null) return this;
    return RideNoShowInfoModel(
      fireAt: fireAt,
      waitMinutes: waitMinutes > 0 ? waitMinutes : fallback.waitMinutes,
      fee: fee > 0 ? fee : fallback.fee,
      title: title.isNotEmpty ? title : fallback.title,
      subtitle: subtitle.isNotEmpty ? subtitle : fallback.subtitle,
    );
  }
}

/// Prefer [primary] when present; otherwise [fallback].
/// When both exist, [primary] wins on timing and [fallback] fills blank copy.
RideNoShowInfoModel? mergeRideNoShowInfo(
  RideNoShowInfoModel? primary,
  RideNoShowInfoModel? fallback,
) {
  if (primary == null) return fallback;
  return primary.mergingDisplayFrom(fallback);
}

/// Parses waiting `no_show` object; returns null for absent / non-map values
/// (including the terminal boolean `true` and fired/completed objects).
RideNoShowInfoModel? rideNoShowInfoFromJson(dynamic raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final status = map['status']?.toString().trim().toLowerCase() ?? '';
  if (status == 'fired' ||
      status == 'completed' ||
      status == 'captured' ||
      status == 'cancelled') {
    return null;
  }
  final fireAtRaw = map['fire_at']?.toString().trim() ?? '';
  if (fireAtRaw.isEmpty || DateTime.tryParse(fireAtRaw) == null) {
    return null;
  }
  return RideNoShowInfoModel.fromJson(map);
}
