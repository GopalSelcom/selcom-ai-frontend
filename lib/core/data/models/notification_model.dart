import 'dart:convert';

/// TODO: Update model based on actual API response
NotificationResponseModel notificationModelFromJson(String str) =>
    NotificationResponseModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationResponseModel data) =>
    json.encode(data.toJson());

class NotificationResponseModel {
  int? statusCode;
  String? message;
  List<NotificationModel>? response;
  int? totalRecords;
  int? recordPerPage;

  NotificationResponseModel({
    this.statusCode,
    this.message,
    this.response,
    this.totalRecords,
    this.recordPerPage,
  });

  NotificationResponseModel copyWith({
    int? statusCode,
    String? message,
    List<NotificationModel>? response,
    int? totalRecords,
    int? recordPerPage,
  }) => NotificationResponseModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
    totalRecords: totalRecords ?? this.totalRecords,
    recordPerPage: recordPerPage ?? this.recordPerPage,
  );

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      NotificationResponseModel(
        statusCode: json["status_code"],
        message: json["message"],
        response: json["response"] == null
            ? []
            : List<NotificationModel>.from(
                json["response"]!.map((x) => NotificationModel.fromJson(x)),
              ),
        totalRecords: json["total_records"],
        recordPerPage: json["record_per_page"],
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response == null
        ? []
        : List<dynamic>.from(response!.map((x) => x.toJson())),
    "total_records": totalRecords,
    "record_per_page": recordPerPage,
  };
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final String timestamp;
  final int? type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      timestamp: json['timestamp'] ?? '',
      type: json['type'] ?? 0,
    );
  }

  /// TODO: Update based on API response
  Map<String, dynamic> toJson() => {
    "_id": id,
    "title": title,
    "message": message,
    "is_read": isRead,
    "timestamp": timestamp,
    "type": type,
  };
}
