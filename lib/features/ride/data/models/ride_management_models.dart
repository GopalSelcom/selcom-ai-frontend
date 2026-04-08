class BookingResponseModel {
  final String id;
  final String status;
  final int pinCode;
  final int fare;
  final String currency;

  BookingResponseModel({
    required this.id,
    required this.status,
    required this.pinCode,
    required this.fare,
    required this.currency,
  });

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    return BookingResponseModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      pinCode: (json['pin_code'] is int) ? json['pin_code'] : int.parse(json['pin_code'].toString()),
      fare: (json['fare'] is int) ? json['fare'] : int.parse(json['fare'].toString()),
      currency: json['currency'] ?? 'TZS',
    );
  }
}

class RecentDestinationModel {
  final String address;
  final double lat;
  final double lng;
  final DateTime timestamp;

  RecentDestinationModel({
    required this.address,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory RecentDestinationModel.fromJson(Map<String, dynamic> json) {
    final coords = json['location']?['coordinates'] as List?;
    return RecentDestinationModel(
      address: json['address'] ?? '',
      lat: (coords != null && coords.length > 1) ? coords[1].toDouble() : 0.0,
      lng: (coords != null && coords.isNotEmpty) ? coords[0].toDouble() : 0.0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ReceiptModel {
  final String rideId;
  final int fare;
  final int discount;
  final int tax;
  final int total;
  final String currency;
  final String paymentMethod;

  ReceiptModel({
    required this.rideId,
    required this.fare,
    required this.discount,
    required this.tax,
    required this.total,
    required this.currency,
    required this.paymentMethod,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      rideId: json['ride_id'] ?? '',
      fare: json['fare'] ?? 0,
      discount: json['discount'] ?? 0,
      tax: json['tax'] ?? 0,
      total: json['total'] ?? 0,
      currency: json['currency'] ?? 'TZS',
      paymentMethod: json['payment_method'] ?? '',
    );
  }
}
