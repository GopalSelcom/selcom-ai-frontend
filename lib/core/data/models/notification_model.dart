// To parse this JSON data, do
//
//     final notificationPayloadModel = notificationPayloadModelFromJson(jsonString);

import 'dart:convert';

NotificationPayloadModel notificationPayloadModelFromJson(String str) => NotificationPayloadModel.fromJson(json.decode(str));

String notificationPayloadModelToJson(NotificationPayloadModel data) => json.encode(data.toJson());

class NotificationPayloadModel {
  int? statusCode;
  String? message;
  Data? data;

  NotificationPayloadModel({
    this.statusCode,
    this.message,
    this.data,
  });

  NotificationPayloadModel copyWith({
    int? statusCode,
    String? message,
    Data? data,
  }) =>
      NotificationPayloadModel(
        statusCode: statusCode ?? this.statusCode,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) => NotificationPayloadModel(
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
  List<Notification>? notifications;
  int? unreadCount;
  Pagination? pagination;

  Data({
    this.notifications,
    this.unreadCount,
    this.pagination,
  });

  Data copyWith({
    List<Notification>? notifications,
    int? unreadCount,
    Pagination? pagination,
  }) =>
      Data(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        pagination: pagination ?? this.pagination,
      );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    notifications: json["notifications"] == null ? [] : List<Notification>.from(json["notifications"]!.map((x) => Notification.fromJson(x))),
    unreadCount: json["unread_count"],
    pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]),
  );

  Map<String, dynamic> toJson() => {
    "notifications": notifications == null ? [] : List<dynamic>.from(notifications!.map((x) => x.toJson())),
    "unread_count": unreadCount,
    "pagination": pagination?.toJson(),
  };
}

class Notification {
  String? id;
  DateTime? createdOn;
  bool? isMarketing;
  String? url;
  bool? isRead;
  String? rideId;
  int? type;
  String? orderId;
  String? text;

  Notification({
    this.id,
    this.createdOn,
    this.isMarketing,
    this.url,
    this.isRead,
    this.rideId,
    this.type,
    this.orderId,
    this.text,
  });

  Notification copyWith({
    String? id,
    DateTime? createdOn,
    bool? isMarketing,
    String? url,
    bool? isRead,
    String? rideId,
    int? type,
    String? orderId,
    String? text,
  }) =>
      Notification(
        id: id ?? this.id,
        createdOn: createdOn ?? this.createdOn,
        isMarketing: isMarketing ?? this.isMarketing,
        url: url ?? this.url,
        isRead: isRead ?? this.isRead,
        rideId: rideId ?? this.rideId,
        type: type ?? this.type,
        orderId: orderId ?? this.orderId,
        text: text ?? this.text,
      );

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    id: json["_id"],
    createdOn: json["created_on"] == null ? null : DateTime.parse(json["created_on"]),
    isMarketing: json["is_marketing"],
    url: json["url"],
    isRead: json["is_read"],
    rideId: json["ride_id"],
    type: json["type"],
    orderId: json["order_id"],
    text: json["text"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "created_on": createdOn?.toIso8601String(),
    "is_marketing": isMarketing,
    "url": url,
    "is_read": isRead,
    "ride_id":rideId,
    "type": type,
    "order_id": orderId,
    "text": text,
  };
}



class Pagination {
  int? page;
  int? limit;
  int? total;
  int? totalPages;

  Pagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
  });

  Pagination copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) =>
      Pagination(
        page: page ?? this.page,
        limit: limit ?? this.limit,
        total: total ?? this.total,
        totalPages: totalPages ?? this.totalPages,
      );

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json["page"],
    limit: json["limit"],
    total: json["total"],
    totalPages: json["total_pages"],
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "limit": limit,
    "total": total,
    "total_pages": totalPages,
  };
}

class FCMNotificationData {
  final String? rideId;
  final String? orderId;
  final String? status;
  final String? title;
  final String? body;
  final String? type;
  final String? driverName;
  final String? vehicleName;
  final String? plateNumber;
  final double? etaSeconds;
  final String? deviationMeters;
  final String? cancelledBy;
  final String? chargeAmount;

  FCMNotificationData({
    this.rideId,
    this.orderId,
    this.status,
    this.title,
    this.body,
    this.type,
    this.driverName,
    this.vehicleName,
    this.plateNumber,
    this.etaSeconds,
    this.deviationMeters,
    this.cancelledBy,
    this.chargeAmount,
  });

  factory FCMNotificationData.fromJson(Map<String, dynamic> json) {
    double? parseEta(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return FCMNotificationData(
      rideId: json['ride_id']?.toString() ?? json['rideId']?.toString(),
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      status: json['status']?.toString(),
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      type: json['type']?.toString(),
      driverName: json['driver_name']?.toString() ?? json['driverName']?.toString(),
      vehicleName: json['vehicle_name']?.toString() ?? json['vehicleName']?.toString(),
      plateNumber: json['plate_number']?.toString() ?? json['plateNumber']?.toString(),
      etaSeconds: parseEta(json['eta_seconds'] ?? json['etaSeconds']),
      deviationMeters: json['deviation_meters']?.toString(),
      cancelledBy: json['cancelled_by']?.toString(),
      chargeAmount: json['charge_amount']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (rideId != null) 'ride_id': rideId,
        if (orderId != null) 'order_id': orderId,
        if (status != null) 'status': status,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (type != null) 'type': type,
        if (driverName != null) 'driver_name': driverName,
        if (vehicleName != null) 'vehicle_name': vehicleName,
        if (plateNumber != null) 'plate_number': plateNumber,
        if (etaSeconds != null) 'eta_seconds': etaSeconds,
        if (deviationMeters != null) 'deviation_meters': deviationMeters,
        if (cancelledBy != null) 'cancelled_by': cancelledBy,
        if (chargeAmount != null) 'charge_amount': chargeAmount,
      };
}


