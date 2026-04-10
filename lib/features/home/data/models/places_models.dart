// To parse this JSON data, do
//
//     final autocompletePredictionModel = autocompletePredictionModelFromJson(jsonString);

import 'dart:convert';

AutocompletePredictionModel autocompletePredictionModelFromJson(String str) => AutocompletePredictionModel.fromJson(json.decode(str));

String autocompletePredictionModelToJson(AutocompletePredictionModel data) => json.encode(data.toJson());

class AutocompletePredictionModel {
  int? statusCode;
  Data? data;

  AutocompletePredictionModel({
    this.statusCode,
    this.data,
  });

  factory AutocompletePredictionModel.fromJson(Map<String, dynamic> json) => AutocompletePredictionModel(
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

  Data({
    this.predictions,
    this.status,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    predictions: json["predictions"] == null ? [] : List<Prediction>.from(json["predictions"]!.map((x) => Prediction.fromJson(x))),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "predictions": predictions == null ? [] : List<dynamic>.from(predictions!.map((x) => x.toJson())),
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
    matchedSubstrings: json["matched_substrings"] == null ? [] : List<MatchedSubstring>.from(json["matched_substrings"]!.map((x) => MatchedSubstring.fromJson(x))),
    placeId: json["place_id"],
    reference: json["reference"],
    structuredFormatting: json["structured_formatting"] == null ? null : StructuredFormatting.fromJson(json["structured_formatting"]),
    terms: json["terms"] == null ? [] : List<Term>.from(json["terms"]!.map((x) => Term.fromJson(x))),
    types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "description": description,
    "matched_substrings": matchedSubstrings == null ? [] : List<dynamic>.from(matchedSubstrings!.map((x) => x.toJson())),
    "place_id": placeId,
    "reference": reference,
    "structured_formatting": structuredFormatting?.toJson(),
    "terms": terms == null ? [] : List<dynamic>.from(terms!.map((x) => x.toJson())),
    "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
  };
}

class MatchedSubstring {
  int? length;
  int? offset;

  MatchedSubstring({
    this.length,
    this.offset,
  });

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) => MatchedSubstring(
    length: json["length"],
    offset: json["offset"],
  );

  Map<String, dynamic> toJson() => {
    "length": length,
    "offset": offset,
  };
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

  factory StructuredFormatting.fromJson(Map<String, dynamic> json) => StructuredFormatting(
    mainText: json["main_text"],
    mainTextMatchedSubstrings: json["main_text_matched_substrings"] == null ? [] : List<MatchedSubstring>.from(json["main_text_matched_substrings"]!.map((x) => MatchedSubstring.fromJson(x))),
    secondaryText: json["secondary_text"],
  );

  Map<String, dynamic> toJson() => {
    "main_text": mainText,
    "main_text_matched_substrings": mainTextMatchedSubstrings == null ? [] : List<dynamic>.from(mainTextMatchedSubstrings!.map((x) => x.toJson())),
    "secondary_text": secondaryText,
  };
}

class Term {
  int? offset;
  String? value;

  Term({
    this.offset,
    this.value,
  });

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    offset: json["offset"],
    value: json["value"],
  );

  Map<String, dynamic> toJson() => {
    "offset": offset,
    "value": value,
  };
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
