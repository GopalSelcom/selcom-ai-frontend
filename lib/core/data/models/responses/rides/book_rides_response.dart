// To parse this JSON data, do
//
//     final bookRideResponse = bookRideResponseFromJson(jsonString);

import 'dart:convert';

BookRideResponse bookRideResponseFromJson(String str) => BookRideResponse.fromJson(json.decode(str));

String bookRideResponseToJson(BookRideResponse data) => json.encode(data.toJson());

class BookRideResponse {
  int? statusCode;
  String? message;
  Data? data;

  BookRideResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  BookRideResponse copyWith({
    int? statusCode,
    String? message,
    Data? data,
  }) =>
      BookRideResponse(
        statusCode: statusCode ?? this.statusCode,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory BookRideResponse.fromJson(Map<String, dynamic> json) => BookRideResponse(
    statusCode: json["status_code"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  String? id;
  String? status;
  int? pinCode;
  int? fare;
  String? currency;

  Data({
    this.id,
    this.status,
    this.pinCode,
    this.fare,
    this.currency,
  });

  Data copyWith({
    String? id,
    String? status,
    int? pinCode,
    int? fare,
    String? currency,
  }) =>
      Data(
        id: id ?? this.id,
        status: status ?? this.status,
        pinCode: pinCode ?? this.pinCode,
        fare: fare ?? this.fare,
        currency: currency ?? this.currency,
      );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["_id"],
    status: json["status"],
    pinCode: json["pin_code"],
    fare: json["fare"],
    currency: json["currency"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "status": status,
    "pin_code": pinCode,
    "fare": fare,
    "currency": currency,
  };
}
