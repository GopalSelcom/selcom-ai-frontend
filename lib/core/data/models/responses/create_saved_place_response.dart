import 'dart:convert';

import 'get_saved_places_response.dart';

/// Envelope for `POST go/user/saved-places/from-recent`.
/// Creates a saved place (favourite by default). Success → refetch list on client.
/// See `docs/SAVED-PLACES-FLOW.md`.
class CreateSavedPlaceFromRecentResponse {
  int? statusCode;
  String? message;
  CreateSavedPlaceFromRecentData? data;

  CreateSavedPlaceFromRecentResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory CreateSavedPlaceFromRecentResponse.fromJson(String str) =>
      CreateSavedPlaceFromRecentResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CreateSavedPlaceFromRecentResponse.fromMap(
    Map<String, dynamic> json,
  ) => CreateSavedPlaceFromRecentResponse(
    statusCode: json["status_code"],
    message: json["message"]?.toString(),
    data: json["data"] == null
        ? null
        : CreateSavedPlaceFromRecentData.fromMap(
            json["data"] is Map<String, dynamic>
                ? json["data"] as Map<String, dynamic>
                : Map<String, dynamic>.from(json["data"] as Map),
          ),
  );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };

  bool get isSuccess => statusCode == 200;
}

class CreateSavedPlaceFromRecentData {
  /// Same shape as list items from `GET go/user/saved-places`.
  SavedPlace? place;

  CreateSavedPlaceFromRecentData({this.place});

  factory CreateSavedPlaceFromRecentData.fromJson(String str) =>
      CreateSavedPlaceFromRecentData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CreateSavedPlaceFromRecentData.fromMap(Map<String, dynamic> json) =>
      CreateSavedPlaceFromRecentData(
        place: json["place"] == null
            ? null
            : SavedPlace.fromMap(
                json["place"] is Map<String, dynamic>
                    ? json["place"] as Map<String, dynamic>
                    : Map<String, dynamic>.from(json["place"] as Map),
              ),
      );

  Map<String, dynamic> toMap() => {
    "place": place?.toMap(),
  };
}
