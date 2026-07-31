/// Helpers for `GET /go/rides/active` (multi-ride list on Home).
///
/// Used by book-for-other pickup flow — see `docs/flows/book-for-other-pickup-flow.md`.
///
/// Booking limits (also enforced in `VehicleSelectionController._guardActiveRideLimits`):
/// - Self: max one active ride (`is_booked_for_other == false`).
/// - Book for other: max `settings.features.book_for_other.max_active` concurrent rides
///   (self ride is **not** counted toward `max_active`).
library;

import '../../core/data/models/responses/rides/active_ride_response.dart'
    as active_ride_api;
import '../../core/data/models/ride_model.dart';

/// Parses active rides from `GET /go/rides/active` using full ride payloads.
List<RideModel> parseActiveRidesFromResponse(
  active_ride_api.ActiveRideData? data,
) {
  if (data == null) return const [];

  final fromList = data.rides;
  if (fromList != null && fromList.isNotEmpty) {
    return sortActiveRides(
      fromList
          .where((entry) => entry.ride != null)
          .map((entry) {
            final rideMap = entry.ride!.toMap();
            // Entry-level cancel_info / no_show (siblings of `ride`) win over
            // any nested copies so cold-start hydration matches the socket shape.
            if (entry.cancelInfo != null) {
              rideMap['cancel_info'] = entry.cancelInfo!.toJson();
            }
            if (entry.noShow != null) {
              rideMap['no_show'] = entry.noShow!.toJson();
            } else if (!rideMap.containsKey('no_show')) {
              rideMap['no_show'] = null;
            }
            if (entry.routeDeviation != null) {
              rideMap['route_deviation'] = entry.routeDeviation!.toJson();
            }
            return RideModel.fromJson(rideMap);
          })
          .toList(growable: false),
    );
  }

  final parsed = <RideModel>[];
  final primary = data.ride;
  if (primary != null) {
    parsed.add(RideModel.fromJson(primary.toMap()));
  }

  final extras = data.additionalRides;
  if (extras != null) {
    for (final ride in extras) {
      parsed.add(RideModel.fromJson(ride.toMap()));
    }
  }

  return sortActiveRides(parsed);
}

/// Self rides first, then rides booked for someone else.
List<RideModel> sortActiveRides(List<RideModel> rides) {
  final sorted = [...rides];
  sorted.sort((a, b) {
    if (a.isBookedForOther == b.isBookedForOther) return 0;
    return a.isBookedForOther ? 1 : -1;
  });
  return sorted;
}

int countBookedForOtherRides(List<RideModel> rides) =>
    rides.where((ride) => ride.isBookedForOther).length;

bool hasSelfActiveRide(List<RideModel> rides) =>
    rides.any((ride) => !ride.isBookedForOther);
