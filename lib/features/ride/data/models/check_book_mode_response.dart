import 'dart:convert';

/// Envelope for `GET go/check-book-mode`.
class CheckBookModeResponse {
  int? statusCode;
  CheckBookModeData? data;

  CheckBookModeResponse({this.statusCode, this.data});

  factory CheckBookModeResponse.fromJson(String str) =>
      CheckBookModeResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CheckBookModeResponse.fromMap(Map<String, dynamic> json) {
    final rawData = json["data"];
    Map<String, dynamic>? dataMap;
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    }
    return CheckBookModeResponse(
      statusCode: json["status_code"],
      data: dataMap == null ? null : CheckBookModeData.fromMap(dataMap),
    );
  }

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

/// `data` for check-book-mode.
class CheckBookModeData {
  bool? showBookForOtherOption;
  double? distanceKm;
  double? thresholdKm;

  CheckBookModeData({
    this.showBookForOtherOption,
    this.distanceKm,
    this.thresholdKm,
  });

  factory CheckBookModeData.fromJson(String str) =>
      CheckBookModeData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CheckBookModeData.fromMap(Map<String, dynamic> json) =>
      CheckBookModeData(
        showBookForOtherOption: json["show_book_for_other_option"],
        distanceKm: (json["distance_km"] as num?)?.toDouble(),
        thresholdKm: (json["threshold_km"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
    "show_book_for_other_option": showBookForOtherOption,
    "distance_km": distanceKm,
    "threshold_km": thresholdKm,
  };
}
