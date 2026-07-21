// Ride status helpers — use everywhere socket/API status is compared or switched on.
//
// Backend and sockets may send camelCase (`driverAssigned`), enum prefixes
// (`RideStatus.driverArriving`), or snake_case. Always normalize first so UI
// labels and navigation stay in sync.

import '../../core/domain/entities/ride_entity.dart';

/// Converts any ride status string to snake_case lowercase.
///
/// Examples: `driverAssigned` → `driver_assigned`,
/// `RideStatus.driverArriving` → `driver_arriving`.
String normalizeRideStatusString(String? raw) {
  final status = (raw ?? '').toString().trim();
  if (status.isEmpty) return '';

  final canonical = status
      .replaceAll('ridestatus.', '')
      .replaceAll('RideStatus.', '')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m.group(1)}_${m.group(2)}',
      )
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  return canonical.toLowerCase();
}

/// Parses a status object (String or RideStatus) into a canonical [RideStatus] enum.
RideStatus parseRideStatus(Object? raw) {
  if (raw is RideStatus) return raw;
  final normalized = normalizeRideStatusString(raw?.toString());
  switch (normalized) {
    case 'searching':
      return RideStatus.searching;
    case 'driver_assigned':
    case 'accepted':
      return RideStatus.driverAssigned;
    case 'driver_arriving':
      return RideStatus.driverArriving;
    case 'driver_arrived':
      return RideStatus.driverArrived;
    case 'ride_started':
      return RideStatus.rideStarted;
    case 'ride_in_progress':
      return RideStatus.rideInProgress;
    case 'near_destination':
      return RideStatus.nearDestination;
    case 'ride_completed':
    case 'completed':
      return RideStatus.rideCompleted;
    case 'cancelled':
    case 'canceled':
      return RideStatus.cancelled;
    case 'no_driver_found':
      return RideStatus.noDriverFound;
    default:
      return RideStatus.searching;
  }
}

/// True while the passenger is still waiting for a driver match.
bool isRideSearchingStatus(String normalized) {
  return normalized.isEmpty || normalized == 'searching';
}

/// Driver accepted through arrival at pickup (trip has not started yet).
bool isDriverPickupEnRouteStatus(String normalized) {
  return normalized == 'driver_assigned' ||
      normalized == 'accepted' ||
      normalized == 'driver_arriving' ||
      normalized == 'driver_arrived' ||
      normalized == 'driver_en_route' ||
      normalized == 'en_route';
}

/// When true, [FindingDriverController] should navigate to driver-accepted.
bool shouldLeaveFindingDriverForPickup(String normalized) {
  return isDriverPickupEnRouteStatus(normalized);
}

/// Ride chaining: assigned pickup phase can revert to [searching] when the chain breaks.
bool shouldRevertToFindingDriverFromPickup(String previousNormalized) {
  return isDriverPickupEnRouteStatus(previousNormalized);
}
