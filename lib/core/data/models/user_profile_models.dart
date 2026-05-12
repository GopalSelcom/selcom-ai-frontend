import '../../constants/currency_code.dart';

class SavedPlaceModel {
  final String? id;
  final String? userId;
  final String label;
  final String name;
  final String? address;
  final String? placeId;
  final double lat;
  final double lng;
  final int? v;
  final String? createdAt;
  final String? updatedAt;

  SavedPlaceModel({
    this.id,
    this.userId,
    required this.label,
    required this.name,
    this.address,
    this.placeId,
    required this.lat,
    required this.lng,
    this.v,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    final coords = json['location']?['coordinates'] as List?;
    return SavedPlaceModel(
      id: json['_id'],
      userId: json['user_id'],
      label: json['label'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      placeId: json['place_id'],
      lat:
          (json['lat'] ??
                  (coords != null && coords.length > 1 ? coords[1] : 0.0))
              .toDouble(),
      lng:
          (json['lng'] ??
                  (coords != null && coords.isNotEmpty ? coords[0] : 0.0))
              .toDouble(),
      v: json['__v'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'label': label,
      'name': name,
      'address': address,
      'place_id': placeId,
      'lat': lat,
      'lng': lng,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
      '__v': v,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WalletBalanceModel {
  final double balance;
  final String currency;

  WalletBalanceModel({required this.balance, required this.currency});

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      balance: (json['balance'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? CurrencyCode.tzs,
    );
  }
}

class PaymentMethodModel {
  final String id;
  final String label;
  final String type; // wallet, card
  final String? icon;

  PaymentMethodModel({
    required this.id,
    required this.label,
    required this.type,
    this.icon,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] ?? json['type'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? '',
      icon: json['icon'],
    );
  }
}
