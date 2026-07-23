class CheckBookModeResult {
  final bool showBookForOtherOption;
  final double? distanceKm;
  final double thresholdKm;

  const CheckBookModeResult({
    required this.showBookForOtherOption,
    required this.distanceKm,
    required this.thresholdKm,
  });

  factory CheckBookModeResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return CheckBookModeResult(
      showBookForOtherOption:
          data['show_book_for_other_option'] as bool? ?? false,
      distanceKm: (data['distance_km'] as num?)?.toDouble(),
      thresholdKm: (data['threshold_km'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
