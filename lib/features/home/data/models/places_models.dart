class AutocompletePredictionModel {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  AutocompletePredictionModel({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory AutocompletePredictionModel.fromJson(Map<String, dynamic> json) {
    return AutocompletePredictionModel(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class ReverseGeocodeModel {
  final String address;
  final double lat;
  final double lng;

  ReverseGeocodeModel({
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory ReverseGeocodeModel.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeModel(
      address: json['address'] ?? json['formatted_address'] ?? '',
      lat: (json['location']?['lat'] ?? 0.0).toDouble(),
      lng: (json['location']?['lng'] ?? 0.0).toDouble(),
    );
  }
}
