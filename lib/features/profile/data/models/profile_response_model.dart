import '../../../../core/data/models/user_model.dart';

class UserProfileResponseModel {
  final int statusCode;
  final String message;
  final UserProfileDataModel data;

  const UserProfileResponseModel({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory UserProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseModel(
      statusCode: (json['status_code'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      data: UserProfileDataModel.fromJson(
        Map<String, dynamic>.from((json['data'] as Map?) ?? const {}),
      ),
    );
  }
}

class UserProfileDataModel {
  final String profileImage;
  final String number;
  final String countryCode;
  final num userRating;
  final String email;
  final String name;

  const UserProfileDataModel({
    required this.profileImage,
    required this.number,
    required this.countryCode,
    required this.userRating,
    required this.email,
    required this.name,
  });

  factory UserProfileDataModel.fromJson(Map<String, dynamic> json) {
    return UserProfileDataModel(
      profileImage: json['profile_image']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? '',
      userRating: (json['user_rating'] as num?) ?? 0,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: '',
      name: name,
      image: profileImage,
      mobileNumber: int.tryParse(number),
      countryCode: countryCode,
      emailId: email,
      goAvgRating: userRating,
    );
  }
}
