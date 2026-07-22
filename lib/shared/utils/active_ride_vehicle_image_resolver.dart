import '../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../core/data/models/ride_model.dart';
import 'vehicle_image_utils.dart';

/// Home active-ride banner vehicle illustration.
///
/// - **Driver assigned:** use driver / vehicle snapshot type.
/// - **Searching + book any:** van (product default until a driver is matched).
/// - **Searching + specific type:** resolve booked type from ride fields or catalog id.
abstract final class ActiveRideVehicleImageResolver {
  /// Default illustration for [RideModel.isBookAny] before a driver is assigned.
  static const String bookAnySearchingTypeLabel = 'van';

  static String resolveAsset({
    required RideModel ride,
    Iterable<VehicleTypeModel>? vehicleTypeCatalog,
  }) {
    if (_hasAssignedDriver(ride)) {
      final assigned = _assignedVehicleTypeLabel(ride);
      if (assigned != null) {
        return VehicleImageUtils.imageAssetForVehicleType(assigned);
      }
    }

    if (ride.isBookAny) {
      return VehicleImageUtils.imageAssetForVehicleType(bookAnySearchingTypeLabel);
    }

    final booked = _bookedVehicleTypeLabel(ride, vehicleTypeCatalog);
    return VehicleImageUtils.imageAssetForVehicleType(booked ?? 'cab');
  }

  static bool _hasAssignedDriver(RideModel ride) {
    if ((ride.driverId ?? '').trim().isNotEmpty) return true;
    final driver = ride.driverSnapshot;
    return driver != null && driver.name.trim().isNotEmpty;
  }

  static String? _assignedVehicleTypeLabel(RideModel ride) {
    final driver = ride.driverSnapshot;
    if (driver is DriverSnapshotModel) {
      final fromDriver = driver.vehicleType?.trim();
      if (fromDriver != null && fromDriver.isNotEmpty) return fromDriver;
    }

    final fromSnapshot = ride.vehicleSnapshot?.vehicleType.trim();
    if (fromSnapshot != null && fromSnapshot.isNotEmpty) return fromSnapshot;

    return null;
  }

  static String? _bookedVehicleTypeLabel(
    RideModel ride,
    Iterable<VehicleTypeModel>? vehicleTypeCatalog,
  ) {
    final key = ride.vehicleKey?.trim();
    if (key != null && key.isNotEmpty) return key;

    final display = ride.vehicleDisplayName?.trim();
    if (display != null && display.isNotEmpty) return display;

    return catalogLabelForVehicleTypeId(
      ride.vehicleTypeId,
      vehicleTypeCatalog,
    );
  }

  /// Maps `vehicle_type_id` (Mongo id string) to catalog `name` / `key` for image lookup.
  static String? catalogLabelForVehicleTypeId(
    String vehicleTypeId,
    Iterable<VehicleTypeModel>? catalog,
  ) {
    final id = vehicleTypeId.trim();
    if (id.isEmpty || catalog == null) return null;

    for (final type in catalog) {
      if (type.id != id) continue;
      if (type.name.trim().isNotEmpty) return type.name.trim();
      if (type.key.trim().isNotEmpty) return type.key.trim();
      final display = type.displayName.trim();
      if (display.isNotEmpty) return display;
    }
    return null;
  }
}
