import 'dart:convert';

/// Models for `GET go/user/saved-places`.
///
/// There is no separate favourites endpoint in the app: `data.saved_places` is the
/// single source of truth. Empty list is valid: `saved_places: []`.
/// See `docs/SAVED-PLACES-FLOW.md`.
class SavedPlacesResponse {
  int? statusCode;
  SavedPlacesData? data;

  SavedPlacesResponse({this.statusCode, this.data});

  factory SavedPlacesResponse.fromJson(String str) =>
      SavedPlacesResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SavedPlacesResponse.fromMap(Map<String, dynamic> json) =>
      SavedPlacesResponse(
        statusCode: json["status_code"],
        data: json["data"] == null
            ? null
            : SavedPlacesData.fromMap(
                json["data"] is Map<String, dynamic>
                    ? json["data"] as Map<String, dynamic>
                    : Map<String, dynamic>.from(json["data"] as Map),
              ),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

class SavedPlacesData {
  List<SavedPlace>? savedPlaces;

  SavedPlacesData({this.savedPlaces});

  factory SavedPlacesData.fromJson(String str) =>
      SavedPlacesData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SavedPlacesData.fromMap(Map<String, dynamic> json) => SavedPlacesData(
    savedPlaces: json["saved_places"] == null
        ? []
        : List<SavedPlace>.from(
            (json["saved_places"] as List).map(
              (x) => SavedPlace.fromMap(
                x is Map<String, dynamic>
                    ? x
                    : Map<String, dynamic>.from(x as Map),
              ),
            ),
          ),
  );

  Map<String, dynamic> toMap() => {
    "saved_places": savedPlaces == null
        ? []
        : List<dynamic>.from(savedPlaces!.map((x) => x.toMap())),
  };
}

/// Saved place row from `data.saved_places`.
/// Backend sets `is_favourite: true` for all saved places; UI uses list membership.
class SavedPlace {
  SavedPlaceLocation? location;
  bool? isFavourite;
  String? id;
  String? label;
  String? userId;
  int? v;
  String? address;
  String? createdAt;
  double? lat;
  double? lng;
  String? name;
  String? updatedAt;

  SavedPlace({
    this.location,
    this.isFavourite,
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
  });

  factory SavedPlace.fromJson(String str) =>
      SavedPlace.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SavedPlace.fromMap(Map<String, dynamic> json) => SavedPlace(
    location: json["location"] == null
        ? null
        : SavedPlaceLocation.fromMap(
            json["location"] is Map<String, dynamic>
                ? json["location"] as Map<String, dynamic>
                : Map<String, dynamic>.from(json["location"] as Map),
          ),
    isFavourite: json["is_favourite"],
    id: json["_id"]?.toString(),
    label: json["label"]?.toString(),
    userId: json["user_id"]?.toString(),
    v: json["__v"],
    address: json["address"]?.toString(),
    createdAt: json["createdAt"]?.toString(),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    name: json["name"]?.toString(),
    updatedAt: json["updatedAt"]?.toString(),
  );

  Map<String, dynamic> toMap() => {
    "location": location?.toMap(),
    "is_favourite": isFavourite,
    "_id": id,
    "label": label,
    "user_id": userId,
    "__v": v,
    "address": address,
    "createdAt": createdAt,
    "lat": lat,
    "lng": lng,
    "name": name,
    "updatedAt": updatedAt,
  };
}

/// GeoJSON-style point on a saved place (`location`).
/// Named distinctly to avoid clashing with other API `Location` classes.
class SavedPlaceLocation {
  String? type;
  List<double>? coordinates;

  SavedPlaceLocation({this.type, this.coordinates});

  factory SavedPlaceLocation.fromJson(String str) =>
      SavedPlaceLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SavedPlaceLocation.fromMap(Map<String, dynamic> json) =>
      SavedPlaceLocation(
        type: json["type"]?.toString(),
        coordinates: json["coordinates"] == null
            ? []
            : List<double>.from(
                (json["coordinates"] as List).map((x) => x?.toDouble()),
              ),
      );

  Map<String, dynamic> toMap() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}
