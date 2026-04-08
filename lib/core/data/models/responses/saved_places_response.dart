import '../user_profile_models.dart';

class SavedPlacesResponseModel {
  final int? statusCode;
  final String? message;
  final SavedPlacesData? data;

  SavedPlacesResponseModel({this.statusCode, this.message, this.data});

  factory SavedPlacesResponseModel.fromJson(Map<String, dynamic> json) {
    return SavedPlacesResponseModel(
      statusCode: json['status_code'],
      message: json['message'],
      data: json['data'] != null
          ? SavedPlacesData.fromJson(json['data'])
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

class SavedPlacesData {
  final List<SavedPlaceModel>? savedPlaces;

  SavedPlacesData({this.savedPlaces});

  factory SavedPlacesData.fromJson(Map<String, dynamic> json) {
    return SavedPlacesData(
      savedPlaces: json['saved_places'] != null
          ? (json['saved_places'] as List)
                .map((v) => SavedPlaceModel.fromJson(v))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'saved_places': savedPlaces?.map((v) => v.toJson()).toList()};
  }
}
