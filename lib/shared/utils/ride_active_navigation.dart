import 'package:get/get.dart';

import '../../core/data/models/ride_model.dart';
import '../../core/domain/entities/ride_entity.dart';
import '../../core/routes/app_routes.dart';
import 'map_route_marker_utils.dart';

/// Terminal / inactive rides — show details sheet instead of live ride UI.
bool rideStatusIsOngoingActive(RideStatus status) {
  switch (status) {
    case RideStatus.rideCompleted:
    case RideStatus.cancelled:
    case RideStatus.noDriverFound:
      return false;
    default:
      return true;
  }
}

String rideStatusToApiValue(RideStatus status) {
  final name = status.name;
  final withUnderscores = name.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (m) => '${m.group(1)}_${m.group(2)}',
  );
  return withUnderscores.toLowerCase();
}

List<Map<String, dynamic>> routeDestinationsPayloadFromRide(RideModel ride) {
  final destination = {
    'lat': ride.destination.lat,
    'lng': ride.destination.lng,
    'address': ride.destination.address,
  };

  if (!ride.isMultiStop && ride.stops.isEmpty) {
    return [destination];
  }

  final intermediates = ride.stops
      .where(
        (stop) =>
            !MapRouteMarkerUtils.stopMatchesDestination(
              stopLat: stop.lat,
              stopLng: stop.lng,
              stopAddress: stop.address,
              destinationLat: ride.destination.lat,
              destinationLng: ride.destination.lng,
              destinationAddress: ride.destination.address,
            ) &&
            !MapRouteMarkerUtils.stopMatchesPickup(
              stopLat: stop.lat,
              stopLng: stop.lng,
              stopAddress: stop.address,
              pickupLat: ride.pickup.lat,
              pickupLng: ride.pickup.lng,
              pickupAddress: ride.pickup.address,
            ),
      )
      .toList()
    ..sort((a, b) => a.index.compareTo(b.index));

  final deduped = MapRouteMarkerUtils.dedupeByLocation(
    items: intermediates,
    lat: (stop) => stop.lat,
    lng: (stop) => stop.lng,
    address: (stop) => stop.address,
  );

  if (deduped.isEmpty) {
    return [destination];
  }

  return [
    ...deduped.map(
      (stop) => {
        'lat': stop.lat,
        'lng': stop.lng,
        'address': stop.address,
      },
    ),
    destination,
  ];
}

/// Same navigation payload as [HomeController.openActiveRide].
///
/// When [pendingIncomingCallPayload] is set (e.g. FCM `type=incoming_call`),
/// [DriverAcceptedController] shows the in-app incoming-call UI after signaling loads.
void navigateToDriverAcceptedForRide(
  RideModel rideValue, {
  Map<String, dynamic>? pendingIncomingCallPayload,
}) {
  final driver = rideValue.driverSnapshot;
  final vehicle = rideValue.vehicleSnapshot;

  Get.toNamed(
    AppRoutes.driverAccepted,
    arguments: {
      'rideId': rideValue.id,
      'pickupLat': rideValue.pickup.lat,
      'pickupLng': rideValue.pickup.lng,
      'pickupAddress': rideValue.pickup.address,
      'destinationLat': rideValue.destination.lat,
      'destinationLng': rideValue.destination.lng,
      'destinationAddress': rideValue.destination.address,
      'destinations': routeDestinationsPayloadFromRide(rideValue),
      'statusPayload': {
        'ride_id': rideValue.id,
        'status': rideStatusToApiValue(rideValue.status),
        'pin_code': rideValue.pinCode,
        'pin_required': rideValue.pinRequired,
        'driver_snapshot': driver == null
            ? null
            : {
                'name': driver.name,
                'phone': driver.phone,
                'avatar_url': driver.avatarUrl,
                if (driver is DriverSnapshotModel)
                  'vehicle_color': driver.vehicleColor,
                if (driver is DriverSnapshotModel)
                  'vehicle_model': driver.vehicleModel,
                if (driver is DriverSnapshotModel)
                  'vehicle_registration_number':
                      driver.vehicleRegistrationNumber,
                if (driver is DriverSnapshotModel)
                  'vehicle_type': driver.vehicleType,
                if (driver is DriverSnapshotModel)
                  'verification_code': driver.verificationCode,
              },
        'vehicle_snapshot': vehicle == null
            ? null
            : {
                'vehicle_type': vehicle.vehicleType,
                'vehicle_name': vehicle.vehicleModel,
                'display_name': vehicle.vehicleType,
              },
      },
      'fareBreakdown': rideValue.fareBreakdown == null
          ? null
          : {
              'ride_charge': rideValue.fareBreakdown!.rideCharge,
              'booking_fee': rideValue.fareBreakdown!.bookingFee,
              'total_amount': rideValue.fareBreakdown!.totalAmount,
            },
      if (pendingIncomingCallPayload != null)
        'pendingIncomingCallPayload': pendingIncomingCallPayload,
    },
  );
}
