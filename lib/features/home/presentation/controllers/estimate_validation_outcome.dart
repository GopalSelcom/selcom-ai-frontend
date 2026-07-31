import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';

/// Result of the home/location fare-estimate gate before booking navigation.
class EstimateValidationOutcome {
  const EstimateValidationOutcome._({
    required this.canProceed,
    this.errorMessage,
    this.errorCode,
    this.estimate,
    this.estimatedAt,
  });

  final bool canProceed;
  final String? errorMessage;
  final String? errorCode;

  /// Fare estimate returned by the validation call; passed to vehicle
  /// selection so the same route is not estimated twice.
  final FareEstimateResponse? estimate;
  final DateTime? estimatedAt;

  factory EstimateValidationOutcome.success({
    FareEstimateResponse? estimate,
  }) {
    return EstimateValidationOutcome._(
      canProceed: true,
      estimate: estimate,
      estimatedAt: estimate != null ? DateTime.now() : null,
    );
  }

  factory EstimateValidationOutcome.failure({
    required String message,
    String? errorCode,
  }) {
    return EstimateValidationOutcome._(
      canProceed: false,
      errorMessage: message,
      errorCode: errorCode,
    );
  }
}
