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

class MidRideCancelEntity {
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

  const MidRideCancelEntity({
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
}
