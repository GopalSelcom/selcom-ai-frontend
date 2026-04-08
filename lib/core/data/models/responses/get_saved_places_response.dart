// To parse this JSON data, do
//
//     final getSavedPlacesResponseModel = getSavedPlacesResponseModelFromJson(jsonString);

import 'dart:convert';

GetSavedPlacesResponseModel getSavedPlacesResponseModelFromJson(String str) => GetSavedPlacesResponseModel.fromJson(json.decode(str));

String getSavedPlacesResponseModelToJson(GetSavedPlacesResponseModel data) => json.encode(data.toJson());

class GetSavedPlacesResponseModel {
  int? statusCode;
  Data? data;

  GetSavedPlacesResponseModel({
    this.statusCode,
    this.data,
  });

  GetSavedPlacesResponseModel copyWith({
    int? statusCode,
    Data? data,
  }) =>
      GetSavedPlacesResponseModel(
        statusCode: statusCode ?? this.statusCode,
        data: data ?? this.data,
      );

  factory GetSavedPlacesResponseModel.fromJson(Map<String, dynamic> json) => GetSavedPlacesResponseModel(
    statusCode: json["status_code"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "data": data?.toJson(),
  };
}

class Data {
  List<SavedPlace>? savedPlaces;

  Data({
    this.savedPlaces,
  });

  Data copyWith({
    List<SavedPlace>? savedPlaces,
  }) =>
      Data(
        savedPlaces: savedPlaces ?? this.savedPlaces,
      );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    savedPlaces: json["saved_places"] == null ? [] : List<SavedPlace>.from(json["saved_places"]!.map((x) => SavedPlace.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "saved_places": savedPlaces == null ? [] : List<dynamic>.from(savedPlaces!.map((x) => x.toJson())),
  };
}

class SavedPlace {
  Location? location;
  String? id;
  String? label;
  String? userId;
  int? v;
  String? address;
  DateTime? createdAt;
  double? lat;
  double? lng;
  String? name;
  DateTime? updatedAt;

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
  });

  SavedPlace copyWith({
    Location? location,
    String? id,
    String? label,
    String? userId,
    int? v,
    String? address,
    DateTime? createdAt,
    double? lat,
    double? lng,
    String? name,
    DateTime? updatedAt,
  }) =>
      SavedPlace(
        location: location ?? this.location,
        id: id ?? this.id,
        label: label ?? this.label,
        userId: userId ?? this.userId,
        v: v ?? this.v,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        name: name ?? this.name,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
    location: json["location"] == null ? null : Location.fromJson(json["location"]),
    id: json["_id"],
    label: json["label"],
    userId: json["user_id"],
    v: json["__v"],
    address: json["address"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    name: json["name"],
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "_id": id,
    "label": label,
    "user_id": userId,
    "__v": v,
    "address": address,
    "createdAt": createdAt?.toIso8601String(),
    "lat": lat,
    "lng": lng,
    "name": name,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({
    this.type,
    this.coordinates,
  });

  Location copyWith({
    String? type,
    List<double>? coordinates,
  }) =>
      Location(
        type: type ?? this.type,
        coordinates: coordinates ?? this.coordinates,
      );

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: json["type"],
    coordinates: json["coordinates"] == null ? [] : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "coordinates": coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}
