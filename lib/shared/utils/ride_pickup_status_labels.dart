import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import 'ride_status_normalizer.dart';

/// Passenger-facing copy for the pickup phase (before [ride_started]).
///
/// Expected progression (see also [normalizeRideStatusString]):
/// `searching` → `driver_assigned` → `driver_arriving` → `driver_arrived`.
///
/// [normalizedStatus] must already be normalized — do not pass raw socket strings.
abstract final class RidePickupStatusLabels {
  RidePickupStatusLabels._();

  /// Main headline (finding-driver sheet + driver-accepted map title fallback).
  static String titleFor(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'searching':
        return AppStrings.searchingForDriver.tr;
      // Backend may send `accepted` as an alias for `driver_assigned`.
      case 'driver_assigned':
      case 'accepted':
        return AppStrings.driverHasAcceptedYourRide.tr;
      case 'driver_arriving':
      case 'driver_en_route':
      case 'en_route':
        return AppStrings.driverEnRoute.tr;
      case 'driver_arrived':
        return AppStrings.driverArrived.tr;      default:
        return isRideSearchingStatus(normalizedStatus)
            ? AppStrings.findingYourDriver.tr
            : AppStrings.driverIsHeadingToYourLocation.tr;
    }
  }

  /// Supporting line under the headline.
  static String descriptionFor(String normalizedStatus) {    switch (normalizedStatus) {
      case 'searching':
        return AppStrings.findingDriverDefaultDescription.tr;
      case 'driver_assigned':
      case 'accepted':
        return AppStrings.driverAssignedDescription.tr;
      case 'driver_arriving':
      case 'driver_en_route':
      case 'en_route':
        return AppStrings.driverIsHeadingToPickup.tr;
      case 'driver_arrived':
        return AppStrings.driverArrivedDescription.tr;
      default:
        return isRideSearchingStatus(normalizedStatus)
            ? AppStrings.findingDriverDefaultDescription.tr
            : AppStrings.driverIsHeadingToPickup.tr;
    }
  }
}
