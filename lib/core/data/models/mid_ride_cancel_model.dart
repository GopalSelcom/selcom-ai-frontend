import '../../domain/entities/mid_ride_cancel_entity.dart';

class MidRideCancelModel extends MidRideCancelEntity {
  const MidRideCancelModel({
    super.reason,
    super.reasonText,
    super.message,
    super.distanceCoveredKm,
    super.partialFare,
    super.capturedAmount,
    super.netRefund,
    super.releasedAmount,
    super.captureAt,
    super.disputeDeadline,
    super.canDispute = false,
    super.captureStatus,
  });

  factory MidRideCancelModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString())?.toUtc();
    }

    return MidRideCancelModel(
      reason: json['reason']?.toString(),
      reasonText: json['reason_text']?.toString(),
      message: json['message']?.toString(),
      distanceCoveredKm: (json['distance_covered_km'] as num?)?.toDouble(),
      partialFare: (json['partial_fare'] as num?)?.toInt(),
      capturedAmount: (json['captured_amount'] as num?)?.toInt(),
      netRefund: (json['net_refund'] as num?)?.toInt(),
      releasedAmount: (json['released_amount'] as num?)?.toInt(),
      captureAt: parseTime(json['capture_at']),
      disputeDeadline: parseTime(json['dispute_deadline']),
      canDispute: json['can_dispute'] == true,
      captureStatus: midRideCaptureStatusFromApi(
        json['capture_status']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'reason': reason,
    'reason_text': reasonText,
    'message': message,
    'distance_covered_km': distanceCoveredKm,
    'partial_fare': partialFare,
    'captured_amount': capturedAmount,
    'net_refund': netRefund,
    'released_amount': releasedAmount,
    'capture_at': captureAt?.toIso8601String(),
    'dispute_deadline': disputeDeadline?.toIso8601String(),
    'can_dispute': canDispute,
    'capture_status': captureStatus?.name,
  };

  MidRideCancelModel merge({
    String? reason,
    String? reasonText,
    String? message,
    double? distanceCoveredKm,
    int? partialFare,
    int? capturedAmount,
    int? netRefund,
    int? releasedAmount,
    DateTime? captureAt,
    DateTime? disputeDeadline,
    bool? canDispute,
    MidRideCaptureStatus? captureStatus,
  }) {
    return MidRideCancelModel(
      reason: reason ?? this.reason,
      reasonText: reasonText ?? this.reasonText,
      message: message ?? this.message,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      partialFare: partialFare ?? this.partialFare,
      capturedAmount: capturedAmount ?? this.capturedAmount,
      netRefund: netRefund ?? this.netRefund,
      releasedAmount: releasedAmount ?? this.releasedAmount,
      captureAt: captureAt ?? this.captureAt,
      disputeDeadline: disputeDeadline ?? this.disputeDeadline,
      canDispute: canDispute ?? this.canDispute,
      captureStatus: captureStatus ?? this.captureStatus,
    );
  }
}
