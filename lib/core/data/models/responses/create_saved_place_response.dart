import '../user_profile_models.dart';

/// Envelope for `POST go/user/saved-places/from-recent`.
/// Creates a saved place (favourite by default). Success → refetch list on client.
/// See `docs/SAVED-PLACES-FLOW.md`.
class CreateSavedPlaceResponseModel {
  final int? statusCode;
  final String? message;
  final CreateSavedPlaceData? data;

  CreateSavedPlaceResponseModel({this.statusCode, this.message, this.data});

  factory CreateSavedPlaceResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateSavedPlaceResponseModel(
      statusCode: (json['status_code'] as num?)?.toInt(),
      message: json['message']?.toString(),
      data: json['data'] != null
          ? CreateSavedPlaceData.fromJson(
              json['data'] is Map<String, dynamic>
                  ? json['data'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;
}

class CreateSavedPlaceData {
  final SavedPlaceModel? place;

  CreateSavedPlaceData({this.place});

  factory CreateSavedPlaceData.fromJson(Map<String, dynamic> json) {
    return CreateSavedPlaceData(
      place: json['place'] != null
          ? SavedPlaceModel.fromJson(
              json['place'] is Map<String, dynamic>
                  ? json['place'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['place'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'place': place?.toJson()};
  }
}
