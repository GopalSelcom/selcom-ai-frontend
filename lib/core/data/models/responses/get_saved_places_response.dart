/// Models for `GET go/user/saved-places`.
///
/// There is no separate favourites endpoint in the app: `data.saved_places` is the
/// single source of truth. Empty list is valid: `saved_places: []`.
/// See `docs/SAVED-PLACES-FLOW.md`.
class GetSavedPlacesResponseModel {
  final int? statusCode;
  final SavedPlacesData? data;

  GetSavedPlacesResponseModel({this.statusCode, this.data});

  factory GetSavedPlacesResponseModel.fromJson(Map<String, dynamic> json) =>
      GetSavedPlacesResponseModel(
        statusCode: (json['status_code'] as num?)?.toInt(),
        data: json['data'] == null
            ? null
            : SavedPlacesData.fromJson(
                json['data'] is Map<String, dynamic>
                    ? json['data'] as Map<String, dynamic>
                    : Map<String, dynamic>.from(json['data'] as Map),
              ),
      );

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'data': data?.toJson(),
  };
}

class SavedPlacesData {
  final List<SavedPlace> savedPlaces;

  SavedPlacesData({this.savedPlaces = const []});

  factory SavedPlacesData.fromJson(Map<String, dynamic> json) {
    // Only `saved_places` — not `favourite_places` (no favourites list API).
    final raw = json['saved_places'];
    if (raw is! List) return SavedPlacesData();
    return SavedPlacesData(
      savedPlaces: raw
          .whereType<Map>()
          .map((e) => SavedPlace.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'saved_places': savedPlaces.map((x) => x.toJson()).toList(),
  };
}

/// Saved place row from `data.saved_places`.
/// Backend sets `is_favourite: true` for all saved places; UI uses list membership.
class SavedPlace {
  final SavedPlaceLocation? location;
  final String? id;
  final String? label;
  final String? userId;
  final int? v;
  final String? address;
  final DateTime? createdAt;
  final double? lat;
  final double? lng;
  final String? name;
  final DateTime? updatedAt;
  final bool? isFavourite;

  SavedPlace({
    this.location,
    this.id,
    this.label,
    this.userId,
    this.v,
    this.address,
    this.createdAt,
    this.lat,
    this.lng,
    this.name,
    this.updatedAt,
    this.isFavourite,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    location: json['location'] == null
        ? null
        : SavedPlaceLocation.fromJson(
            json['location'] is Map<String, dynamic>
                ? json['location'] as Map<String, dynamic>
                : Map<String, dynamic>.from(json['location'] as Map),
          ),
    id: json['_id']?.toString(),
    label: json['label']?.toString(),
    userId: json['user_id']?.toString(),
    v: (json['__v'] as num?)?.toInt(),
    address: json['address']?.toString(),
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.tryParse(json['createdAt'].toString()),
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    name: json['name']?.toString(),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.tryParse(json['updatedAt'].toString()),
    isFavourite: json['is_favourite'] as bool? ?? json['isFavourite'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'location': location?.toJson(),
    '_id': id,
    'label': label,
    'user_id': userId,
    '__v': v,
    'address': address,
    'createdAt': createdAt?.toIso8601String(),
    'lat': lat,
    'lng': lng,
    'name': name,
    'updatedAt': updatedAt?.toIso8601String(),
    'is_favourite': isFavourite,
  };
}

class SavedPlaceLocation {
  final String? type;
  final List<double>? coordinates;

  SavedPlaceLocation({this.type, this.coordinates});

  factory SavedPlaceLocation.fromJson(Map<String, dynamic> json) =>
      SavedPlaceLocation(
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
