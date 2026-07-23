import 'dart:convert';

class RecentDestinationsResponse {
  int? statusCode;
  RecentDestinationsData? data;

  RecentDestinationsResponse({this.statusCode, this.data});

  factory RecentDestinationsResponse.fromJson(String str) =>
      RecentDestinationsResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RecentDestinationsResponse.fromMap(Map<String, dynamic> json) =>
      RecentDestinationsResponse(
        statusCode: json["status_code"],
        data: json["data"] == null
            ? null
            : RecentDestinationsData.fromMap(
                Map<String, dynamic>.from(json["data"] as Map),
              ),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

class RecentDestinationsData {
  List<Destination>? destinations;

  RecentDestinationsData({this.destinations});

  factory RecentDestinationsData.fromJson(String str) =>
      RecentDestinationsData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RecentDestinationsData.fromMap(Map<String, dynamic> json) =>
      RecentDestinationsData(
        destinations: json["destinations"] == null
            ? []
            : List<Destination>.from(
                json["destinations"]!.map(
                  (x) =>
                      Destination.fromMap(Map<String, dynamic>.from(x as Map)),
                ),
              ),
      );

  Map<String, dynamic> toMap() => {
    "destinations": destinations == null
        ? []
        : List<dynamic>.from(destinations!.map((x) => x.toMap())),
  };
}

class Destination {
  String? address;
  double? lat;
  double? lng;
  String? lastUsed;

  Destination({this.address, this.lat, this.lng, this.lastUsed});

  factory Destination.fromJson(String str) =>
      Destination.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Destination.fromMap(Map<String, dynamic> json) => Destination(
    address: json["address"],
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    lastUsed: json["last_used"],
  );

  Map<String, dynamic> toMap() => {
    "address": address,
    "lat": lat,
    "lng": lng,
    "last_used": lastUsed,
  };
}
