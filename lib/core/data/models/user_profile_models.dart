class SavedPlaceModel {
  final String? id;
  final String label;
  final String name;
  final String placeId;
  final double lat;
  final double lng;

  SavedPlaceModel({
    this.id,
    required this.label,
    required this.name,
    required this.placeId,
    required this.lat,
    required this.lng,
  });

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    final coords = json['location']?['coordinates'] as List?;
    return SavedPlaceModel(
      id: json['_id'],
      label: json['label'] ?? '',
      name: json['name'] ?? '',
      placeId: json['place_id'] ?? '',
      lat: (coords != null && coords.length > 1) ? coords[1].toDouble() : 0.0,
      lng: (coords != null && coords.isNotEmpty) ? coords[0].toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'name': name,
      'place_id': placeId,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
    };
  }
}

class WalletBalanceModel {
  final double balance;
  final String currency;

  WalletBalanceModel({
    required this.balance,
    required this.currency,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      balance: (json['balance'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'TZS',
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
