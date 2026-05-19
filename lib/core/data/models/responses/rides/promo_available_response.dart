/// Response envelope for `GET go/promo/available`.
class AvailablePromoItem {
  final String id;
  final String code;
  final String type;
  final int discountValue;
  final int? maxDiscountAmount;
  final int minRideAmount;
  final List<String> applicableVehicleTypes;
  final DateTime? validUntil;
  final String description;

  const AvailablePromoItem({
    required this.id,
    required this.code,
    required this.type,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.minRideAmount,
    required this.applicableVehicleTypes,
    this.validUntil,
    required this.description,
  });

  factory AvailablePromoItem.fromJson(Map<String, dynamic> json) {
    final vehicleRaw = json['applicable_vehicle_types'];
    final vehicles = <String>[];
    if (vehicleRaw is List) {
      for (final v in vehicleRaw) {
        final s = v?.toString().trim();
        if (s != null && s.isNotEmpty) vehicles.add(s);
      }
    }

    DateTime? validUntil;
    final untilRaw = json['valid_until'];
    if (untilRaw != null) {
      validUntil = DateTime.tryParse(untilRaw.toString());
    }

    return AvailablePromoItem(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString().trim().toUpperCase(),
      type: (json['type'] ?? '').toString(),
      discountValue: (json['discount_value'] as num?)?.toInt() ?? 0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toInt(),
      minRideAmount: (json['min_ride_amount'] as num?)?.toInt() ?? 0,
      applicableVehicleTypes: vehicles,
      validUntil: validUntil,
      description: (json['description'] ?? '').toString().trim(),
    );
  }
}

class PromoAvailableData {
  final List<AvailablePromoItem> promos;
  final int total;

  const PromoAvailableData({
    required this.promos,
    required this.total,
  });

  factory PromoAvailableData.fromJson(Map<String, dynamic> json) {
    final raw = json['promos'];
    final list = <AvailablePromoItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(
            AvailablePromoItem.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }
    return PromoAvailableData(
      promos: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
    );
  }
}

class PromoAvailableResponse {
  final int? httpStatus;
  final int? statusCode;
  final String? message;
  final PromoAvailableData? data;

  const PromoAvailableResponse({
    this.httpStatus,
    this.statusCode,
    this.message,
    this.data,
  });

  bool get isSuccess => (statusCode ?? httpStatus) == 200 && data != null;

  factory PromoAvailableResponse.fromHttpResponse({
    required int? httpStatus,
    required dynamic body,
  }) {
    if (body is! Map) {
      return PromoAvailableResponse(
        httpStatus: httpStatus,
        message: 'Invalid response',
      );
    }
    final map = Map<String, dynamic>.from(body);
    final scRaw = map['status_code'];
    final statusCode = switch (scRaw) {
      null => httpStatus,
      final int i => i,
      final num n => n.toInt(),
      final String s => int.tryParse(s.trim()),
      _ => int.tryParse(scRaw.toString()),
    };
    final dataRaw = map['data'];
    PromoAvailableData? data;
    if (dataRaw is Map) {
      data = PromoAvailableData.fromJson(
        dataRaw is Map<String, dynamic>
            ? dataRaw
            : Map<String, dynamic>.from(dataRaw),
      );
    }
    return PromoAvailableResponse(
      httpStatus: httpStatus,
      statusCode: statusCode,
      message: map['message']?.toString(),
      data: data,
    );
  }
}
