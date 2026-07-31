/// Backend-owned route deviation banner (`route_deviation` on ride details /
/// active rides / socket).
///
/// Title, subtitle, and distance text are pre-rendered — render as-is.
/// Use [state] for banner tone (`off_route` vs `on_route`), not [flagged].
class RideCancellationRequestModel {
  final String ticketId;
  final String ticketNumber;
  final String status;
  final DateTime? requestedAt;
  final String? note;

  const RideCancellationRequestModel({
    required this.ticketId,
    required this.ticketNumber,
    required this.status,
    this.requestedAt,
    this.note,
  });

  factory RideCancellationRequestModel.fromJson(Map<String, dynamic> json) {
    final requestedRaw = json['requested_at']?.toString();
    return RideCancellationRequestModel(
      ticketId: json['ticket_id']?.toString().trim() ?? '',
      ticketNumber: json['ticket_number']?.toString().trim() ?? '',
      status: json['status']?.toString().trim().toLowerCase() ?? '',
      requestedAt: requestedRaw == null || requestedRaw.isEmpty
          ? null
          : DateTime.tryParse(requestedRaw)?.toUtc(),
      note: json['note']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ticket_id': ticketId,
    'ticket_number': ticketNumber,
    'status': status,
    if (requestedAt != null) 'requested_at': requestedAt!.toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  bool get isPending => status == 'pending';

  bool get isRejected => status == 'rejected';

  bool get isWithdrawn => status == 'withdrawn';

  bool get isApproved => status == 'approved';

  RideCancellationRequestModel copyWith({
    String? ticketId,
    String? ticketNumber,
    String? status,
    DateTime? requestedAt,
    String? note,
    bool clearNote = false,
  }) {
    return RideCancellationRequestModel(
      ticketId: ticketId ?? this.ticketId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}

class RideRouteDeviationModel {
  final bool flagged;
  final String state;
  final int deviationMeters;
  final String distanceText;
  final int alertCount;
  final int maxDeviationMeters;
  final DateTime? lastEventAt;
  final String title;
  final String subtitle;
  final bool canContactSupport;
  final bool canRequestCancellation;
  final RideCancellationRequestModel? cancellationRequest;

  /// Socket-only: `deviated` | `rejoined`. Used for de-dupe with [detectedAt].
  final String? event;

  /// Socket-only detection timestamp for de-dupe (`ride_id` + `detected_at`).
  final DateTime? detectedAt;

  const RideRouteDeviationModel({
    required this.flagged,
    required this.state,
    required this.deviationMeters,
    required this.distanceText,
    required this.alertCount,
    required this.maxDeviationMeters,
    this.lastEventAt,
    required this.title,
    required this.subtitle,
    required this.canContactSupport,
    required this.canRequestCancellation,
    this.cancellationRequest,
    this.event,
    this.detectedAt,
  });

  factory RideRouteDeviationModel.fromJson(Map<String, dynamic> json) {
    final lastRaw = json['last_event_at']?.toString();
    final detectedRaw = json['detected_at']?.toString();
    final cancellationRaw = json['cancellation_request'];
    final state = json['state']?.toString().trim().toLowerCase() ?? '';
    final event = json['event']?.toString().trim().toLowerCase();
    // Socket payloads omit `flagged`; REST keeps it true after first incident.
    final flagged = json['flagged'] == true ||
        state == 'off_route' ||
        state == 'on_route' ||
        event == 'deviated' ||
        event == 'rejoined';
    return RideRouteDeviationModel(
      flagged: flagged,
      state: state,
      deviationMeters: (json['deviation_meters'] as num?)?.toInt() ??
          int.tryParse(json['deviation_meters']?.toString() ?? '') ??
          0,
      distanceText: json['distance_text']?.toString().trim() ?? '',
      alertCount: (json['alert_count'] as num?)?.toInt() ?? 0,
      maxDeviationMeters:
          (json['max_deviation_meters'] as num?)?.toInt() ??
          (json['threshold_meters'] as num?)?.toInt() ??
          0,
      lastEventAt: lastRaw == null || lastRaw.isEmpty
          ? null
          : DateTime.tryParse(lastRaw)?.toUtc(),
      title: json['title']?.toString().trim() ?? '',
      subtitle: json['subtitle']?.toString().trim() ?? '',
      canContactSupport: json['can_contact_support'] != false,
      canRequestCancellation: json['can_request_cancellation'] == true,
      cancellationRequest: cancellationRaw is Map
          ? RideCancellationRequestModel.fromJson(
              Map<String, dynamic>.from(cancellationRaw),
            )
          : null,
      event: event,
      detectedAt: detectedRaw == null || detectedRaw.isEmpty
          ? null
          : DateTime.tryParse(detectedRaw)?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'flagged': flagged,
    'state': state,
    'deviation_meters': deviationMeters,
    'distance_text': distanceText,
    'alert_count': alertCount,
    'max_deviation_meters': maxDeviationMeters,
    if (lastEventAt != null) 'last_event_at': lastEventAt!.toIso8601String(),
    'title': title,
    'subtitle': subtitle,
    'can_contact_support': canContactSupport,
    'can_request_cancellation': canRequestCancellation,
    'cancellation_request': cancellationRequest?.toJson(),
    if (event != null) 'event': event,
    if (detectedAt != null) 'detected_at': detectedAt!.toIso8601String(),
  };

  bool get isOffRoute => state == 'off_route';

  bool get isOnRoute => state == 'on_route';

  /// Prefer newer socket fields; keep cancellation request / flags from [fallback]
  /// when the socket omits them.
  RideRouteDeviationModel mergingFrom(RideRouteDeviationModel? fallback) {
    if (fallback == null) return this;
    return RideRouteDeviationModel(
      flagged: flagged || fallback.flagged,
      state: state.isNotEmpty ? state : fallback.state,
      deviationMeters: deviationMeters > 0
          ? deviationMeters
          : fallback.deviationMeters,
      distanceText: distanceText.isNotEmpty
          ? distanceText
          : fallback.distanceText,
      alertCount: alertCount > 0 ? alertCount : fallback.alertCount,
      maxDeviationMeters: maxDeviationMeters > 0
          ? maxDeviationMeters
          : fallback.maxDeviationMeters,
      lastEventAt: lastEventAt ?? fallback.lastEventAt,
      title: title.isNotEmpty ? title : fallback.title,
      subtitle: subtitle.isNotEmpty ? subtitle : fallback.subtitle,
      canContactSupport: canContactSupport,
      canRequestCancellation: canRequestCancellation,
      cancellationRequest: cancellationRequest ?? fallback.cancellationRequest,
      event: event ?? fallback.event,
      detectedAt: detectedAt ?? fallback.detectedAt,
    );
  }

  RideRouteDeviationModel copyWith({
    bool? flagged,
    String? state,
    int? deviationMeters,
    String? distanceText,
    int? alertCount,
    int? maxDeviationMeters,
    DateTime? lastEventAt,
    String? title,
    String? subtitle,
    bool? canContactSupport,
    bool? canRequestCancellation,
    RideCancellationRequestModel? cancellationRequest,
    bool clearCancellationRequest = false,
    String? event,
    DateTime? detectedAt,
  }) {
    return RideRouteDeviationModel(
      flagged: flagged ?? this.flagged,
      state: state ?? this.state,
      deviationMeters: deviationMeters ?? this.deviationMeters,
      distanceText: distanceText ?? this.distanceText,
      alertCount: alertCount ?? this.alertCount,
      maxDeviationMeters: maxDeviationMeters ?? this.maxDeviationMeters,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      canContactSupport: canContactSupport ?? this.canContactSupport,
      canRequestCancellation:
          canRequestCancellation ?? this.canRequestCancellation,
      cancellationRequest: clearCancellationRequest
          ? null
          : (cancellationRequest ?? this.cancellationRequest),
      event: event ?? this.event,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }
}

/// Parses `route_deviation`; returns null when absent, non-map, or never flagged.
///
/// Backend may send an empty object with `flagged: false` instead of `null` —
/// that means no incident; do not show a banner.
RideRouteDeviationModel? rideRouteDeviationFromJson(dynamic raw) {
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  final model = RideRouteDeviationModel.fromJson(map);
  if (!model.flagged) return null;
  // Empty shell with flagged true but no usable state should not paint UI.
  if (!model.isOffRoute &&
      !model.isOnRoute &&
      model.cancellationRequest == null) {
    return null;
  }
  return model;
}
