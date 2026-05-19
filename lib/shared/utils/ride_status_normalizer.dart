// Ride status helpers — use everywhere socket/API status is compared or switched on.
//
// Backend and sockets may send camelCase (`driverAssigned`), enum prefixes
// (`RideStatus.driverArriving`), or snake_case. Always normalize first so UI
// labels and navigation stay in sync.

/// Converts any ride status string to snake_case lowercase.
///
/// Examples: `driverAssigned` → `driver_assigned`,
/// `RideStatus.driverArriving` → `driver_arriving`.
String normalizeRideStatusString(String? raw) {  final status = (raw ?? '').toString().trim();
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

/// True while the passenger is still waiting for a driver match.
bool isRideSearchingStatus(String normalized) {
  return normalized.isEmpty || normalized == 'searching';
}

/// Driver accepted through arrival at pickup (trip has not started yet).
bool isDriverPickupEnRouteStatus(String normalized) {  return normalized == 'driver_assigned' ||
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