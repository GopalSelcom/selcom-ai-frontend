import '../../domain/entities/ride_rating_tag_entity.dart';

class RideRatingTagModel extends RideRatingTagEntity {
  const RideRatingTagModel({
    required super.key,
    required super.label,
    required super.order,
  });

  factory RideRatingTagModel.fromJson(Map<String, dynamic> json) {
    return RideRatingTagModel(
      key: (json['key'] as String?)?.trim() ?? '',
      label: (json['label'] as String?)?.trim() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
