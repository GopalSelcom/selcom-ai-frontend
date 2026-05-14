/// Response envelope for `POST go/promo/validate`.
class PromoValidateData {
  final String code;
  final String type;
  final int discountValue;
  final int discountAmount;
  final int discountedFare;
  final String? description;

  const PromoValidateData({
    required this.code,
    required this.type,
    required this.discountValue,
    required this.discountAmount,
    required this.discountedFare,
    this.description,
  });

  factory PromoValidateData.fromJson(Map<String, dynamic> json) {
    return PromoValidateData(
      code: (json['code'] ?? '').toString().trim().toUpperCase(),
      type: (json['type'] ?? '').toString(),
      discountValue: (json['discount_value'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      discountedFare: (json['discounted_fare'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
    );
  }
}

class PromoValidateResponse {
  final int? httpStatus;
  final int? statusCode;
  final String? message;
  final String? errorCode;
  final PromoValidateData? data;

  const PromoValidateResponse({
    this.httpStatus,
    this.statusCode,
    this.message,
    this.errorCode,
    this.data,
  });

  bool get isSuccess =>
      (statusCode ?? httpStatus) == 200 && data != null;

  factory PromoValidateResponse.fromHttpResponse({
    required int? httpStatus,
    required dynamic body,
  }) {
    if (body is! Map) {
      return PromoValidateResponse(
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
    PromoValidateData? data;
    if (dataRaw is Map) {
      data = PromoValidateData.fromJson(
        dataRaw is Map<String, dynamic>
            ? dataRaw
            : Map<String, dynamic>.from(dataRaw),
      );
    }
    return PromoValidateResponse(
      httpStatus: httpStatus,
      statusCode: statusCode,
      message: map['message']?.toString(),
      errorCode: map['error_code']?.toString(),
      data: data,
    );
  }
}
