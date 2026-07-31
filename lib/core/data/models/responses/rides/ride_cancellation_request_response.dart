import '../../ride_route_deviation_model.dart';

/// `POST /go/rides/:id/cancellation-request` success payload (`data`).
class RideCancellationRequestResponseData {
  final String ticketId;
  final String ticketNumber;
  final String status;
  final bool alreadyRequested;

  const RideCancellationRequestResponseData({
    required this.ticketId,
    required this.ticketNumber,
    required this.status,
    required this.alreadyRequested,
  });

  factory RideCancellationRequestResponseData.fromJson(
    Map<String, dynamic> json,
  ) {
    return RideCancellationRequestResponseData(
      ticketId: json['ticket_id']?.toString().trim() ?? '',
      ticketNumber: json['ticket_number']?.toString().trim() ?? '',
      status: json['status']?.toString().trim().toLowerCase() ?? 'pending',
      alreadyRequested: json['already_requested'] == true,
    );
  }
}

/// Socket `ride:cancellation_request_update` (CC declined).
class RideCancellationRequestUpdatePayload {
  final String? rideId;
  final String ticketId;
  final String ticketNumber;
  final String status;
  final String? note;

  const RideCancellationRequestUpdatePayload({
    this.rideId,
    required this.ticketId,
    required this.ticketNumber,
    required this.status,
    this.note,
  });

  factory RideCancellationRequestUpdatePayload.fromJson(
    Map<String, dynamic> json,
  ) {
    return RideCancellationRequestUpdatePayload(
      rideId: json['ride_id']?.toString(),
      ticketId: json['ticket_id']?.toString().trim() ?? '',
      ticketNumber: json['ticket_number']?.toString().trim() ?? '',
      status: json['status']?.toString().trim().toLowerCase() ?? '',
      note: json['note']?.toString().trim(),
    );
  }
}

/// Socket `ride:route_deviation` — same banner fields as REST `route_deviation`.
class RideRouteDeviationSocketPayload {
  final String? rideId;
  final RideRouteDeviationModel deviation;

  const RideRouteDeviationSocketPayload({
    this.rideId,
    required this.deviation,
  });

  factory RideRouteDeviationSocketPayload.fromJson(Map<String, dynamic> json) {
    return RideRouteDeviationSocketPayload(
      rideId: json['ride_id']?.toString(),
      deviation: RideRouteDeviationModel.fromJson(json),
    );
  }
}
