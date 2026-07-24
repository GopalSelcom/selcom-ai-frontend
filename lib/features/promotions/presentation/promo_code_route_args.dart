/// Route arguments for [AppRoutes.promotions] from vehicle selection.
class PromoCodeRouteArgs {
  const PromoCodeRouteArgs({
    required this.fareEstimate,
    this.vehicleTypeId = '',
    this.appliedCode = '',
    this.bookAny = false,
  });

  final String vehicleTypeId;
  final int fareEstimate;
  final String appliedCode;
  final bool bookAny;

  Map<String, dynamic> toMap() => {
    'from_ride_booking': true,
    'vehicle_type_id': vehicleTypeId,
    'fare_estimate': fareEstimate,
    'applied_code': appliedCode,
    if (bookAny) 'book_any': true,
  };

  static PromoCodeRouteArgs? tryFrom(dynamic arguments) {
    if (arguments is! Map) return null;
    final fromRide = arguments['from_ride_booking'] == true;
    if (!fromRide) return null;
    final bookAny = arguments['book_any'] == true;
    final vid = (arguments['vehicle_type_id'] ?? arguments['vehicleTypeId'])
        ?.toString()
        .trim();
    if (!bookAny && (vid == null || vid.isEmpty)) return null;
    final fareRaw = arguments['fare_estimate'] ?? arguments['fareEstimate'];
    final fare = fareRaw is num
        ? fareRaw.toInt()
        : int.tryParse('$fareRaw') ?? 0;
    final applied =
        (arguments['applied_code'] ?? arguments['appliedCode'])?.toString() ??
        '';
    return PromoCodeRouteArgs(
      vehicleTypeId: vid ?? '',
      fareEstimate: fare,
      appliedCode: applied,
      bookAny: bookAny,
    );
  }
}

/// Result when a promo was validated and applied from the ride flow.
class PromoCodeApplyResult {
  const PromoCodeApplyResult({
    required this.code,
    required this.vehicleTypeId,
    required this.discountedFare,
    required this.discountAmount,
    this.isAutoApply = false,
    this.isCashback = false,
  });

  final String code;
  final String vehicleTypeId;
  final int discountedFare;
  final int discountAmount;
  final bool isAutoApply;
  final bool isCashback;

  Map<String, dynamic> toMap() => {
    'code': code,
    'vehicle_type_id': vehicleTypeId,
    'discounted_fare': discountedFare,
    'discount_amount': discountAmount,
    'is_auto_apply': isAutoApply,
    'is_cashback': isCashback,
  };

  static PromoCodeApplyResult? tryFrom(dynamic result) {
    if (result is! Map) return null;
    final map = result is Map<String, dynamic>
        ? result
        : Map<String, dynamic>.from(result);
    final code = map['code']?.toString().trim().toUpperCase();
    if (code == null || code.isEmpty) return null;
    final vehicleTypeId =
        (map['vehicle_type_id'] ?? map['vehicleTypeId'])?.toString().trim() ??
        '';
    if (vehicleTypeId.isEmpty) return null;
    final discountedRaw = map['discounted_fare'] ?? map['discountedFare'];
    final discountRaw = map['discount_amount'] ?? map['discountAmount'];
    final discountedFare = discountedRaw is num
        ? discountedRaw.toInt()
        : int.tryParse('$discountedRaw');
    final discountAmount = discountRaw is num
        ? discountRaw.toInt()
        : int.tryParse('$discountRaw');
    if (discountedFare == null || discountAmount == null) return null;
    return PromoCodeApplyResult(
      code: code,
      vehicleTypeId: vehicleTypeId,
      discountedFare: discountedFare,
      discountAmount: discountAmount,
      isAutoApply: map['is_auto_apply'] == true || map['isAutoApply'] == true,
      isCashback: map['is_cashback'] == true || map['isCashback'] == true,
    );
  }
}
