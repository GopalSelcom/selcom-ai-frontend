import 'dart:convert';

/// Envelope for `GET go/review-tags`.
class ReviewTagsResponse {
  final int? statusCode;
  final String? message;
  final ReviewTagsData? data;

  const ReviewTagsResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory ReviewTagsResponse.fromRawJson(String str) =>
      ReviewTagsResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReviewTagsResponse.fromJson(Map<String, dynamic> json) =>
      ReviewTagsResponse(
        statusCode: json['status_code'] is num
            ? (json['status_code'] as num).toInt()
            : int.tryParse('${json['status_code'] ?? ''}'),
        message: json['message']?.toString(),
        data: json['data'] == null
            ? null
            : ReviewTagsData.fromJson(
                json['data'] is Map<String, dynamic>
                    ? json['data'] as Map<String, dynamic>
                    : Map<String, dynamic>.from(json['data'] as Map),
              ),
      );

  bool get isSuccess => statusCode == 200 && data != null;

  int? get rating => data?.rating;

  List<ReviewTagModel> get tags => data?.tags ?? const [];

  /// Active tags sorted by [ReviewTagModel.order].
  List<ReviewTagModel> get activeTags {
    final list = tags.where((t) => t.isActive == true).toList();
    list.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    return list;
  }

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'data': data?.toJson(),
  };
}

class ReviewTagsData {
  final int? rating;
  final List<ReviewTagModel>? tags;

  const ReviewTagsData({this.rating, this.tags});

  factory ReviewTagsData.fromRawJson(String str) =>
      ReviewTagsData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReviewTagsData.fromJson(Map<String, dynamic> json) {
    final raw = json['tags'];
    final list = <ReviewTagModel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(
            ReviewTagModel.fromJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }
    return ReviewTagsData(
      rating: (json['rating'] as num?)?.toInt(),
      tags: list,
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'tags': tags?.map((e) => e.toJson()).toList(),
  };
}

class ReviewTagModel {
  final bool? isActive;
  final int? order;
  final String? key;
  final String? label;

  const ReviewTagModel({
    this.isActive,
    this.order,
    this.key,
    this.label,
  });

  factory ReviewTagModel.fromRawJson(String str) =>
      ReviewTagModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReviewTagModel.fromJson(Map<String, dynamic> json) => ReviewTagModel(
    isActive: json['is_active'] as bool?,
    order: (json['order'] as num?)?.toInt(),
    key: json['key']?.toString().trim(),
    label: json['label']?.toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    'is_active': isActive,
    'order': order,
    'key': key,
    'label': label,
  };
}
