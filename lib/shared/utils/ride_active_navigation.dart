import 'package:get/get.dart';

import '../../core/data/models/ride_model.dart';
import '../../core/domain/entities/ride_entity.dart';
import '../../core/routes/app_routes.dart';
import 'map_route_marker_utils.dart';
import 'mid_ride_cancel_navigation.dart';
import 'ride_status_normalizer.dart';

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

/// True when the ride has an assigned driver (id or snapshot).
bool rideHasAssignedDriver(RideModel ride) {
  final driverId = ride.driverId?.trim() ?? '';
  if (driverId.isNotEmpty) return true;
  final driver = ride.driverSnapshot;
  if (driver == null) return false;
  return driver.name.trim().isNotEmpty || driver.phone.trim().isNotEmpty;
}

bool _isRideTripStartedOrLater(String normalized) {
  switch (normalized) {
    case 'ride_started':
    case 'ride_in_progress':
    case 'near_destination':
    case 'completed':
    case 'ride_completed':
      return true;
    default:
      return false;
  }
}

/// Ongoing rides still searching for a driver belong on SCR-10, not driver-accepted.
bool shouldOpenFindingDriverForRide(RideModel ride) {
  final normalized = normalizeRideStatusString(
    rideStatusToApiValue(ride.status),
  );
  if (isRideSearchingStatus(normalized)) return true;
  if (rideHasAssignedDriver(ride)) return false;
  return !_isRideTripStartedOrLater(normalized);
}

Map<String, dynamic> findingDriverArgumentsFromRide(RideModel ride) {
  final vehicleType =
      ride.vehicleSnapshot?.vehicleType.trim() ??
      ride.vehicleKey?.trim() ??
      ride.vehicleDisplayName?.trim() ??
      '';

  return {
    'rideId': ride.id,
    if (vehicleType.isNotEmpty) 'vehicleType': vehicleType,
    'pickupLat': ride.pickup.lat,
    'pickupLng': ride.pickup.lng,
    'pickupAddress': ride.pickup.address,
    'destinationLat': ride.destination.lat,
    'destinationLng': ride.destination.lng,
    'destinationAddress': ride.destination.address,
    'destinations': routeDestinationsPayloadFromRide(ride),
    'fareBreakdown': ride.fareBreakdown == null
        ? null
        : {
            'ride_charge': ride.fareBreakdown!.rideCharge,
            'booking_fee': ride.fareBreakdown!.bookingFee,
            'total_amount': ride.fareBreakdown!.totalAmount,
          },
    'isBookedForOther': ride.isBookedForOther,
    if (ride.passengerName != null) 'passengerName': ride.passengerName,
    if (ride.passengerPhone != null) 'passengerPhone': ride.passengerPhone,
    if (ride.cancelTime != null) 'cancel_time': ride.cancelTime,
    if (ride.searchStartedAt != null)
      'search_started_at': ride.searchStartedAt!.toIso8601String(),
  };
}

void navigateToFindingDriverForRide(RideModel ride, {bool replace = false}) {
  final args = findingDriverArgumentsFromRide(ride);
  if (replace) {
    Get.offNamed(AppRoutes.findingDriver, arguments: args);
  } else {
    Get.toNamed(AppRoutes.findingDriver, arguments: args);
  }
}

/// Routes to finding-driver (searching / no driver) or driver-accepted (assigned+).
void navigateToOngoingRide(
  RideModel ride, {
  bool replace = false,
  Map<String, dynamic>? pendingIncomingCallPayload,
}) {
  if (shouldOpenFindingDriverForRide(ride)) {
    navigateToFindingDriverForRide(ride, replace: replace);
    return;
  }
  if (rideNeedsMidRideCancelScreen(ride)) {
    final block = ride.midRideCancel;
    if (block != null) {
      showMidRideDriverCancelledDialog(
        rideId: ride.id,
        cancel: block,
        navigateHomeOnDismiss: replace,
      );
      return;
    }
  }
  navigateToDriverAcceptedForRide(
    ride,
    pendingIncomingCallPayload: pendingIncomingCallPayload,
    replace: replace,
  );
}

/// Same navigation payload as [HomeController.openActiveRide].
///
/// When [pendingIncomingCallPayload] is set (e.g. FCM `type=incoming_call`),
/// [DriverAcceptedController] shows the in-app incoming-call UI after signaling loads.
void navigateToDriverAcceptedForRide(
  RideModel rideValue, {
  Map<String, dynamic>? pendingIncomingCallPayload,
  bool replace = false,
}) {
  final driver = rideValue.driverSnapshot;
  final vehicle = rideValue.vehicleSnapshot;

  final arguments = {
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
    };

  if (replace) {
    Get.offNamed(AppRoutes.driverAccepted, arguments: arguments);
  } else {
    Get.toNamed(AppRoutes.driverAccepted, arguments: arguments);
  }
}
