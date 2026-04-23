import 'dart:convert';

NotificationResponseModel notificationModelFromJson(String str) =>
    NotificationResponseModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationResponseModel data) =>
    json.encode(data.toJson());

class NotificationResponseModel {
  final int? statusCode;
  final String? message;
  final NotificationPayloadModel? data;

  NotificationResponseModel({this.statusCode, this.message, this.data});

  NotificationResponseModel copyWith({
    int? statusCode,
    String? message,
    NotificationPayloadModel? data,
  }) => NotificationResponseModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    data: data ?? this.data,
  );

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) =>
      NotificationResponseModel(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : NotificationPayloadModel.fromJson(
                Map<String, dynamic>.from(json["data"]),
              ),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class NotificationPayloadModel {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final NotificationPaginationModel? pagination;

  NotificationPayloadModel({
    required this.notifications,
    required this.unreadCount,
    this.pagination,
  });

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) {
    final rawNotifications = json["notifications"];
    final parsedNotifications = rawNotifications is List
        ? rawNotifications
              .map(
                (item) => NotificationModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <NotificationModel>[];

    return NotificationPayloadModel(
      notifications: parsedNotifications,
      unreadCount: json["unread_count"] is int ? json["unread_count"] : 0,
      pagination: json["pagination"] == null
          ? null
          : NotificationPaginationModel.fromJson(
              Map<String, dynamic>.from(json["pagination"]),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    "notifications": notifications.map((x) => x.toJson()).toList(),
    "unread_count": unreadCount,
    "pagination": pagination?.toJson(),
  };
}

class NotificationPaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  NotificationPaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory NotificationPaginationModel.fromJson(Map<String, dynamic> json) {
    return NotificationPaginationModel(
      page: json["page"] is int ? json["page"] : 1,
      limit: json["limit"] is int ? json["limit"] : 20,
      total: json["total"] is int ? json["total"] : 0,
      totalPages: json["total_pages"] is int ? json["total_pages"] : 1,
    );
  }

  Map<String, dynamic> toJson() => {
    "page": page,
    "limit": limit,
    "total": total,
    "total_pages": totalPages,
  };
}

class NotificationModel {
  final String id;
  final String text;
  final String createdOn;
  final bool isRead;
  final bool isMarketing;
  final String url;
  final String? rideId;
  final String? orderId;
  final int? type;

  NotificationModel({
    required this.id,
    required this.text,
    required this.createdOn,
    required this.isRead,
    required this.isMarketing,
    required this.url,
    required this.rideId,
    required this.orderId,
    this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      text: json['text'] ?? json['message'] ?? '',
      createdOn: json['created_on'] ?? json['timestamp'] ?? '',
      isRead: json['is_read'] ?? false,
      isMarketing: json['is_marketing'] ?? false,
      url: json['url'] ?? '',
      rideId: json['ride_id']?.toString(),
      orderId: json['order_id']?.toString(),
      type: json['type'] ?? 0,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? text,
    String? createdOn,
    bool? isRead,
    bool? isMarketing,
    String? url,
    String? rideId,
    String? orderId,
    int? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      text: text ?? this.text,
      createdOn: createdOn ?? this.createdOn,
      isRead: isRead ?? this.isRead,
      isMarketing: isMarketing ?? this.isMarketing,
      url: url ?? this.url,
      rideId: rideId ?? this.rideId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "text": text,
    "created_on": createdOn,
    "is_read": isRead,
    "is_marketing": isMarketing,
    "url": url,
    "ride_id": rideId,
    "order_id": orderId,
    "type": type,
  };
}

class FCMNotificationData {
  final String? status;
  final String? rideId;
  final String? title;
  final String? body;
  final bool? sound;
  final int? type;
  final String? clickAction;

  // 🚗 Ride Tracking Telemetry
  final String? driverName;
  final String? vehicleName;
  final String? plateNumber;
  final String? driverAvatarUrl;
  final double? etaSeconds;
  final bool? isCompleted;
  final bool? isRiderDelivering;
  final int? step;
  final int? totalSteps;
  final String? pickupDistance;
  final String? deliveryDistance;

  FCMNotificationData({
    this.status,
    this.rideId,
    this.title,
    this.body,
    this.sound,
    this.type,
    this.clickAction,
    this.driverName,
    this.vehicleName,
    this.plateNumber,
    this.driverAvatarUrl,
    this.etaSeconds,
    this.isCompleted,
    this.isRiderDelivering,
    this.step,
    this.totalSteps,
    this.pickupDistance,
    this.deliveryDistance,
  });

  factory FCMNotificationData.fromJson(Map<String, dynamic> json) {
    return FCMNotificationData(
      status: json['status']?.toString(),
      rideId: json['ride_id']?.toString() ?? json['order_id']?.toString(),
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      sound: json['sound']?.toString() == 'true',
      type: int.tryParse(json['type']?.toString() ?? ''),
      clickAction: json['click_action']?.toString(),

      // Parse Telemetry
      driverName: json['driver_name']?.toString(),
      vehicleName: json['vehicle_name']?.toString(),
      plateNumber: json['plate_number']?.toString(),
      driverAvatarUrl: json['driver_avatar_url']?.toString(),
      etaSeconds: double.tryParse(json['eta_seconds']?.toString() ?? ''),
      isCompleted:
          json['is_completed']?.toString() == 'true' ||
          json['is_completed']?.toString() == '1',
      isRiderDelivering:
          json['is_rider_delivering']?.toString() == 'true' ||
          json['is_rider_delivering']?.toString() == '1',
      step: int.tryParse(json['step']?.toString() ?? ''),
      totalSteps: int.tryParse(json['total_steps']?.toString() ?? ''),
      pickupDistance: json['pickup_distance']?.toString(),
      deliveryDistance: json['delivery_distance']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'ride_id': rideId,
    'title': title,
    'body': body,
    'sound': sound,
    'type': type,
    'click_action': clickAction,
    'driver_name': driverName,
    'vehicle_name': vehicleName,
    'plate_number': plateNumber,
    'driver_avatar_url': driverAvatarUrl,
    'eta_seconds': etaSeconds,
    'is_completed': isCompleted,
    'is_rider_delivering': isRiderDelivering,
    'step': step,
    'total_steps': totalSteps,
    'pickup_distance': pickupDistance,
    'delivery_distance': deliveryDistance,
  };
}
