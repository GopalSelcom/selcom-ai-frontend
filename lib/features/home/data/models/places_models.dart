// To parse this JSON data, do
//
//     final autocompletePredictionModel = autocompletePredictionModelFromJson(jsonString);

import 'dart:convert';

AutocompletePredictionModel autocompletePredictionModelFromJson(String str) =>
    AutocompletePredictionModel.fromJson(json.decode(str));

String autocompletePredictionModelToJson(AutocompletePredictionModel data) =>
    json.encode(data.toJson());

class AutocompletePredictionModel {
  int? statusCode;
  Data? data;

  AutocompletePredictionModel({this.statusCode, this.data});

  factory AutocompletePredictionModel.fromJson(Map<String, dynamic> json) =>
      AutocompletePredictionModel(
        statusCode: json["status_code"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "data": data?.toJson(),
  };
}

class Data {
  List<Prediction>? predictions;
  String? status;

  Data({this.predictions, this.status});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    predictions: json["predictions"] == null
        ? []
        : List<Prediction>.from(
            json["predictions"]!.map((x) => Prediction.fromJson(x)),
          ),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "predictions": predictions == null
        ? []
        : List<dynamic>.from(predictions!.map((x) => x.toJson())),
    "status": status,
  };
}

class Prediction {
  String? description;
  List<MatchedSubstring>? matchedSubstrings;
  String? placeId;
  String? reference;
  StructuredFormatting? structuredFormatting;
  List<Term>? terms;
  List<String>? types;

  Prediction({
    this.description,
    this.matchedSubstrings,
    this.placeId,
    this.reference,
    this.structuredFormatting,
    this.terms,
    this.types,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    description: json["description"],
    matchedSubstrings: json["matched_substrings"] == null
        ? []
        : List<MatchedSubstring>.from(
            json["matched_substrings"]!.map(
              (x) => MatchedSubstring.fromJson(x),
            ),
          ),
    placeId: json["place_id"],
    reference: json["reference"],
    structuredFormatting: json["structured_formatting"] == null
        ? null
        : StructuredFormatting.fromJson(json["structured_formatting"]),
    terms: json["terms"] == null
        ? []
        : List<Term>.from(json["terms"]!.map((x) => Term.fromJson(x))),
    types: json["types"] == null
        ? []
        : List<String>.from(json["types"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "description": description,
    "matched_substrings": matchedSubstrings == null
        ? []
        : List<dynamic>.from(matchedSubstrings!.map((x) => x.toJson())),
    "place_id": placeId,
    "reference": reference,
    "structured_formatting": structuredFormatting?.toJson(),
    "terms": terms == null
        ? []
        : List<dynamic>.from(terms!.map((x) => x.toJson())),
    "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
  };
}

class MatchedSubstring {
  int? length;
  int? offset;

  MatchedSubstring({this.length, this.offset});

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) =>
      MatchedSubstring(length: json["length"], offset: json["offset"]);

  Map<String, dynamic> toJson() => {"length": length, "offset": offset};
}

class StructuredFormatting {
  String? mainText;
  List<MatchedSubstring>? mainTextMatchedSubstrings;
  String? secondaryText;

  StructuredFormatting({
    this.mainText,
    this.mainTextMatchedSubstrings,
    this.secondaryText,
  });

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) =>
      StructuredFormatting(
        mainText: json["main_text"],
        mainTextMatchedSubstrings: json["main_text_matched_substrings"] == null
            ? []
            : List<MatchedSubstring>.from(
                json["main_text_matched_substrings"]!.map(
                  (x) => MatchedSubstring.fromJson(x),
                ),
              ),
        secondaryText: json["secondary_text"],
      );

  Map<String, dynamic> toJson() => {
    "main_text": mainText,
    "main_text_matched_substrings": mainTextMatchedSubstrings == null
        ? []
        : List<dynamic>.from(mainTextMatchedSubstrings!.map((x) => x.toJson())),
    "secondary_text": secondaryText,
  };
}

class Term {
  int? offset;
  String? value;

  Term({this.offset, this.value});

  factory Term.fromJson(Map<String, dynamic> json) =>
      Term(offset: json["offset"], value: json["value"]);

  Map<String, dynamic> toJson() => {"offset": offset, "value": value};
}

// To parse this JSON data, do
//
//     final reverseGeocodeModel = reverseGeocodeModelFromJson(jsonString);

ReverseGeocodeModel reverseGeocodeModelFromJson(String str) =>
    ReverseGeocodeModel.fromJson(json.decode(str));

String reverseGeocodeModelToJson(ReverseGeocodeModel data) =>
    json.encode(data.toJson());

class ReverseGeocodeModel {
  int? statusCode;
  DataReverse? data;

  ReverseGeocodeModel({this.statusCode, this.data});

  factory ReverseGeocodeModel.fromJson(Map<String, dynamic> json) =>
      ReverseGeocodeModel(
        statusCode: json["status_code"],
        data: json["data"] == null ? null : DataReverse.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "data": data?.toJson(),
  };
}

class DataReverse {
  PlusCode? plusCode;
  List<Result>? results;
  String? status;

  DataReverse({this.plusCode, this.results, this.status});

  factory DataReverse.fromJson(Map<String, dynamic> json) => DataReverse(
    plusCode: json["plus_code"] == null
        ? null
        : PlusCode.fromJson(json["plus_code"]),
    results: json["results"] == null
        ? []
        : List<Result>.from(json["results"]!.map((x) => Result.fromJson(x))),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "plus_code": plusCode?.toJson(),
    "results": results == null
        ? []
        : List<dynamic>.from(results!.map((x) => x.toJson())),
    "status": status,
  };
}

class PlusCode {
  String? compoundCode;
  String? globalCode;

  PlusCode({this.compoundCode, this.globalCode});

  factory PlusCode.fromJson(Map<String, dynamic> json) => PlusCode(
    compoundCode: json["compound_code"],
    globalCode: json["global_code"],
  );

  Map<String, dynamic> toJson() => {
    "compound_code": compoundCode,
    "global_code": globalCode,
  };
}

class Result {
  List<AddressComponent>? addressComponents;
  String? formattedAddress;
  Geometry? geometry;
  List<NavigationPoint>? navigationPoints;
  String? placeId;
  List<String>? types;
  PlusCode? plusCode;

  Result({
    this.addressComponents,
    this.formattedAddress,
    this.geometry,
    this.navigationPoints,
    this.placeId,
    this.types,
    this.plusCode,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    addressComponents: json["address_components"] == null
        ? []
        : List<AddressComponent>.from(
            json["address_components"]!.map(
              (x) => AddressComponent.fromJson(x),
            ),
          ),
    formattedAddress: json["formatted_address"],
    geometry: json["geometry"] == null
        ? null
        : Geometry.fromJson(json["geometry"]),
    navigationPoints: json["navigation_points"] == null
        ? []
        : List<NavigationPoint>.from(
            json["navigation_points"]!.map((x) => NavigationPoint.fromJson(x)),
          ),
    placeId: json["place_id"],
    types: json["types"] == null
        ? []
        : List<String>.from(json["types"]!.map((x) => x)),
    plusCode: json["plus_code"] == null
        ? null
        : PlusCode.fromJson(json["plus_code"]),
  );

  Map<String, dynamic> toJson() => {
    "address_components": addressComponents == null
        ? []
        : List<dynamic>.from(addressComponents!.map((x) => x.toJson())),
    "formatted_address": formattedAddress,
    "geometry": geometry?.toJson(),
    "navigation_points": navigationPoints == null
        ? []
        : List<dynamic>.from(navigationPoints!.map((x) => x.toJson())),
    "place_id": placeId,
    "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
    "plus_code": plusCode?.toJson(),
  };
}

class AddressComponent {
  String? longName;
  String? shortName;
  List<String>? types;

  AddressComponent({this.longName, this.shortName, this.types});

  factory AddressComponent.fromJson(Map<String, dynamic> json) =>
      AddressComponent(
        longName: json["long_name"],
        shortName: json["short_name"],
        types: json["types"] == null
            ? []
            : List<String>.from(json["types"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
    "long_name": longName,
    "short_name": shortName,
    "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
  };
}

class Geometry {
  Bounds? bounds;
  NortheastClass? location;
  LocationType? locationType;
  Bounds? viewport;

  Geometry({this.bounds, this.location, this.locationType, this.viewport});

  factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
    bounds: json["bounds"] == null ? null : Bounds.fromJson(json["bounds"]),
    location: json["location"] == null
        ? null
        : NortheastClass.fromJson(json["location"]),
    locationType:
        locationTypeValues.map[json["location_type"]] ??
        LocationType.APPROXIMATE,
    viewport: json["viewport"] == null
        ? null
        : Bounds.fromJson(json["viewport"]),
  );

  Map<String, dynamic> toJson() => {
    "bounds": bounds?.toJson(),
    "location": location?.toJson(),
    "location_type": locationTypeValues.reverse[locationType],
    "viewport": viewport?.toJson(),
  };
}

class Bounds {
  NortheastClass? northeast;
  NortheastClass? southwest;

  Bounds({this.northeast, this.southwest});

  factory Bounds.fromJson(Map<String, dynamic> json) => Bounds(
    northeast: json["northeast"] == null
        ? null
        : NortheastClass.fromJson(json["northeast"]),
    southwest: json["southwest"] == null
        ? null
        : NortheastClass.fromJson(json["southwest"]),
  );

  Map<String, dynamic> toJson() => {
    "northeast": northeast?.toJson(),
    "southwest": southwest?.toJson(),
  };
}

class NortheastClass {
  double? lat;
  double? lng;

  NortheastClass({this.lat, this.lng});

  factory NortheastClass.fromJson(Map<String, dynamic> json) => NortheastClass(
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {"lat": lat, "lng": lng};
}

enum LocationType { APPROXIMATE, GEOMETRIC_CENTER, ROOFTOP }

final locationTypeValues = EnumValues({
  "APPROXIMATE": LocationType.APPROXIMATE,
  "GEOMETRIC_CENTER": LocationType.GEOMETRIC_CENTER,
  "ROOFTOP": LocationType.ROOFTOP,
});

class NavigationPoint {
  NavigationPointLocation? location;

  NavigationPoint({this.location});

  factory NavigationPoint.fromJson(Map<String, dynamic> json) =>
      NavigationPoint(
        location: json["location"] == null
            ? null
            : NavigationPointLocation.fromJson(json["location"]),
      );

  Map<String, dynamic> toJson() => {"location": location?.toJson()};
}

class NavigationPointLocation {
  double? latitude;
  double? longitude;

  NavigationPointLocation({this.latitude, this.longitude});

  factory NavigationPointLocation.fromJson(Map<String, dynamic> json) =>
      NavigationPointLocation(
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
  };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
