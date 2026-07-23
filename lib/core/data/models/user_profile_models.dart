/// Saved place in `POST from-recent` response `data.place`.
/// List screens use [SavedPlace] from [SavedPlacesResponse] instead.
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
  final bool? isFavourite;
  final SavedPlaceGeoLocation? location;

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
    this.isFavourite,
    this.location,
  });

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    SavedPlaceGeoLocation? location;
    List? coords;
    if (rawLocation is Map) {
      location = SavedPlaceGeoLocation.fromJson(
        Map<String, dynamic>.from(rawLocation),
      );
      coords = location.coordinates;
    }

    return SavedPlaceModel(
      id: json['_id']?.toString(),
      userId: json['user_id']?.toString(),
      label: json['label']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      placeId: json['place_id']?.toString(),
      lat:
          (json['lat'] as num?)?.toDouble() ??
          (coords != null && coords.length > 1
              ? (coords[1] as num).toDouble()
              : 0.0),
      lng:
          (json['lng'] as num?)?.toDouble() ??
          (coords != null && coords.isNotEmpty
              ? (coords[0] as num).toDouble()
              : 0.0),
      v: (json['__v'] as num?)?.toInt(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isFavourite:
          json['is_favourite'] as bool? ?? json['isFavourite'] as bool?,
      location: location,
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
      'location': location?.toJson() ??
          {
            'type': 'Point',
            'coordinates': [lng, lat],
          },
      '__v': v,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'is_favourite': isFavourite,
    };
  }
}

class SavedPlaceGeoLocation {
  final String? type;
  final List<double>? coordinates;

  const SavedPlaceGeoLocation({this.type, this.coordinates});

  factory SavedPlaceGeoLocation.fromJson(Map<String, dynamic> json) =>
      SavedPlaceGeoLocation(
        type: json['type']?.toString(),
        coordinates: json['coordinates'] == null
            ? null
            : List<double>.from(
                (json['coordinates'] as List).map(
                  (x) => (x as num).toDouble(),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };
}
