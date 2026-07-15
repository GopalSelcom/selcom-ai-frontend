import 'dart:convert';

class SpLinkResponse {
  int? statusCode;
  String? message;
  LinkData? data;

  SpLinkResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory SpLinkResponse.fromRawJson(String str) => SpLinkResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SpLinkResponse.fromJson(Map<String, dynamic> json) => SpLinkResponse(
    statusCode: json["status_code"],
    message: json["message"],
    data: json["data"] == null ? null : LinkData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class LinkData {
  String? linkId;
  String? status;
  bool? isNewRequest;

  LinkData({
    this.linkId,
    this.status,
    this.isNewRequest,
  });

  factory LinkData.fromRawJson(String str) => LinkData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory LinkData.fromJson(Map<String, dynamic> json) => LinkData(
    linkId: json["link_id"],
    status: json["status"],
    isNewRequest: json["is_new_request"],
  );

  Map<String, dynamic> toJson() => {
    "link_id": linkId,
    "status": status,
    "is_new_request": isNewRequest,
  };
}
