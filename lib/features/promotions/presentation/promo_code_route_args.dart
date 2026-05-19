/// Route arguments for [AppRoutes.promotions] from vehicle selection.
class PromoCodeRouteArgs {
  const PromoCodeRouteArgs({
    required this.vehicleTypeId,
    required this.fareEstimate,
    this.appliedCode = '',
  });

  final String vehicleTypeId;
  final int fareEstimate;
  final String appliedCode;

  Map<String, dynamic> toMap() => {
    'from_ride_booking': true,
    'vehicle_type_id': vehicleTypeId,
    'fare_estimate': fareEstimate,
    'applied_code': appliedCode,
  };

  static PromoCodeRouteArgs? tryFrom(dynamic arguments) {
    if (arguments is! Map) return null;
    final fromRide = arguments['from_ride_booking'] == true;
    if (!fromRide) return null;
    final vid = (arguments['vehicle_type_id'] ?? arguments['vehicleTypeId'])
        ?.toString()
        .trim();
    if (vid == null || vid.isEmpty) return null;
    final fareRaw = arguments['fare_estimate'] ?? arguments['fareEstimate'];
    final fare = fareRaw is num ? fareRaw.toInt() : int.tryParse('$fareRaw') ?? 0;
    final applied =
        (arguments['applied_code'] ?? arguments['appliedCode'])?.toString() ??
        '';
    return PromoCodeRouteArgs(
      vehicleTypeId: vid,
      fareEstimate: fare,
      appliedCode: applied,
    );
  }
}

/// Result when a promo was validated and applied from the ride flow.
class PromocodeApplyResult {
  const PromocodeApplyResult({required this.code});

  final String code;

  Map<String, dynamic> toMap() => {'code': code};
}
