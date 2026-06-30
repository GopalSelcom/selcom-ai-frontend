import '../../../../core/data/models/mid_ride_cancel_model.dart';
import '../../../../core/domain/entities/mid_ride_cancel_entity.dart';

class RideDriverCancelledPayload {
  final String rideId;
  final String? reason;
  final String? reasonText;
  final double? distanceCoveredKm;
  final int? partialFare;
  final DateTime? captureAt;
  final DateTime? disputeDeadline;
  final bool canDispute;

  const RideDriverCancelledPayload({
    required this.rideId,
    this.reason,
    this.reasonText,
    this.distanceCoveredKm,
    this.partialFare,
    this.captureAt,
    this.disputeDeadline,
    this.canDispute = false,
  });

  factory RideDriverCancelledPayload.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString())?.toUtc();
    }

    return RideDriverCancelledPayload(
      rideId: (json['ride_id'] ?? json['rideId'] ?? '').toString(),
      reason: json['reason']?.toString(),
      reasonText: json['reason_text']?.toString(),
      distanceCoveredKm: (json['distance_covered_km'] as num?)?.toDouble(),
      partialFare: (json['partial_fare'] as num?)?.toInt(),
      captureAt: parseTime(json['capture_at']),
      disputeDeadline: parseTime(json['dispute_deadline']),
      canDispute: json['can_dispute'] == true,
    );
  }

  MidRideCancelModel toMidRideCancelModel() {
    return MidRideCancelModel(
      reason: reason,
      reasonText: reasonText,
      distanceCoveredKm: distanceCoveredKm,
      partialFare: partialFare,
      captureAt: captureAt,
      disputeDeadline: disputeDeadline,
      canDispute: canDispute,
      captureStatus: MidRideCaptureStatus.scheduled,
    );
  }
}

class RideChargeSettledPayload {
  final String rideId;
  final int? capturedAmount;
  final int? netRefund;

  const RideChargeSettledPayload({
    required this.rideId,
    this.capturedAmount,
    this.netRefund,
  });

  factory RideChargeSettledPayload.fromJson(Map<String, dynamic> json) {
    return RideChargeSettledPayload(
      rideId: (json['ride_id'] ?? json['rideId'] ?? '').toString(),
      capturedAmount: (json['captured_amount'] as num?)?.toInt(),
      netRefund: (json['net_refund'] as num?)?.toInt(),
    );
  }
}

class RideChargeDisputedPayload {
  final String rideId;
  final int? releasedAmount;

  const RideChargeDisputedPayload({
    required this.rideId,
    this.releasedAmount,
  });

  factory RideChargeDisputedPayload.fromJson(Map<String, dynamic> json) {
    return RideChargeDisputedPayload(
      rideId: (json['ride_id'] ?? json['rideId'] ?? '').toString(),
      releasedAmount: (json['released_amount'] as num?)?.toInt(),
    );
  }
}

class DisputeChargeResult {
  final int releasedAmount;
  final String status;

  const DisputeChargeResult({
    required this.releasedAmount,
    required this.status,
  });

  factory DisputeChargeResult.fromJson(Map<String, dynamic> json) {
    return DisputeChargeResult(
      releasedAmount: (json['released_amount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'disputed',
    );
  }
}
