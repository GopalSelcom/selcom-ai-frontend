/// Backend-owned partial-charge state when a driver ends a trip mid-ride.
enum MidRideCaptureStatus {
  scheduled,
  captured,
  disputed,
  released,
  waived,
}

MidRideCaptureStatus? midRideCaptureStatusFromApi(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final normalized = raw.trim().toLowerCase();
  return MidRideCaptureStatus.values.cast<MidRideCaptureStatus?>().firstWhere(
    (e) => e?.name == normalized,
    orElse: () => null,
  );
}

class MidRideCancelModel {
  final String? reason;
  final String? reasonText;
  final String? message;
  final double? distanceCoveredKm;
  final int? partialFare;
  final int? capturedAmount;
  final int? netRefund;
  final int? releasedAmount;
  final DateTime? captureAt;
  final DateTime? disputeDeadline;
  final bool canDispute;
  final MidRideCaptureStatus? captureStatus;

  const MidRideCancelModel({
    this.reason,
    this.reasonText,
    this.message,
    this.distanceCoveredKm,
    this.partialFare,
    this.capturedAmount,
    this.netRefund,
    this.releasedAmount,
    this.captureAt,
    this.disputeDeadline,
    this.canDispute = false,
    this.captureStatus,
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

  bool get isDriverMidRideCancel => captureStatus != null || partialFare != null;

  int get displayChargeAmount =>
      capturedAmount ?? partialFare ?? 0;

  bool get needsLiveChargeScreen {
    switch (captureStatus) {
      case MidRideCaptureStatus.scheduled:
      case MidRideCaptureStatus.disputed:
        return true;
      case MidRideCaptureStatus.captured:
      case MidRideCaptureStatus.released:
      case MidRideCaptureStatus.waived:
        return false;
      case null:
        return canDispute && (partialFare ?? 0) > 0;
    }
  }

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
