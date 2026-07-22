import 'dart:convert';

import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.lat,
    required super.lng,
    required super.address,
  });

  factory LocationModel.fromRawJson(String str) =>
      LocationModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    lat: (json['lat'] ?? 0.0).toDouble(),
    lng: (json['lng'] ?? 0.0).toDouble(),
    address: json['address'] ?? '',
  );

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'address': address};
}
