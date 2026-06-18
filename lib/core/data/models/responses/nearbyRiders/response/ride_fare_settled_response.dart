/// Book Any `ride:fare_settled` socket payload (lower vehicle assigned → funds released).
class RideFareSettledResponse {
  final String? rideId;
  final String? vehicleType;
  final String? vehicleName;
  final int? blockedAmount;
  final int? chargedAmount;
  final int? releasedAmount;
  final String? currency;
  final bool isBookAny;

  const RideFareSettledResponse({
    this.rideId,
    this.vehicleType,
    this.vehicleName,
    this.blockedAmount,
    this.chargedAmount,
    this.releasedAmount,
    this.currency,
    this.isBookAny = false,
  });

  factory RideFareSettledResponse.fromJson(Map<String, dynamic> json) {
    return RideFareSettledResponse(
      rideId: json['ride_id']?.toString() ?? json['rideId']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      vehicleName: json['vehicle_name']?.toString(),
      blockedAmount: _asInt(json['blocked_amount'] ?? json['blockedAmount']),
      chargedAmount: _asInt(
        json['charged_amount'] ?? json['chargedAmount'] ?? json['final_fare'],
      ),
      releasedAmount: _asInt(
        json['released_amount'] ??
            json['releasedAmount'] ??
            json['refund_amount'] ??
            json['refundAmount'],
      ),
      currency: json['currency']?.toString(),
      isBookAny: json['is_book_any'] == true,
    );
  }

  /// Dialog is shown only when this is true (no release → no popup).
  bool get hasReleasedFunds =>
      releasedAmount != null && releasedAmount! > 0;

  String get displayVehicleLabel {
    final name = (vehicleName ?? '').trim();
    if (name.isNotEmpty) return name;
    final type = (vehicleType ?? '').trim();
    if (type.isNotEmpty) return type;
    return '';
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
