import 'dart:convert';

NotificationResponseModel notificationModelFromJson(String str) =>
    NotificationResponseModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationResponseModel data) =>
    json.encode(data.toJson());

class NotificationResponseModel {
  final int? statusCode;
  final String? message;
  final NotificationPayloadModel? data;

  NotificationResponseModel({
    this.statusCode,
    this.message,
    this.data,
  });

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
