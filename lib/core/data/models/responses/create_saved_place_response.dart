import '../user_profile_models.dart';

class CreateSavedPlaceResponseModel {
  final int? statusCode;
  final String? message;
  final CreateSavedPlaceData? data;

  CreateSavedPlaceResponseModel({this.statusCode, this.message, this.data});

  factory CreateSavedPlaceResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateSavedPlaceResponseModel(
      statusCode: json['status_code'],
      message: json['message'],
      data: json['data'] != null
          ? CreateSavedPlaceData.fromJson(json['data'])
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
          ? SavedPlaceModel.fromJson(json['place'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'place': place?.toJson()};
  }
}
