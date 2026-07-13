import '../../../../core/data/models/user_model.dart';

/// Envelope for `GET go/user/profile`.
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

/// `data` object for profile GET and edit_profile (no `_id` in API).
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

  /// Profile APIs omit user id — pass login session id when merging after edit.
  UserModel toUserModel({String? preserveUserId}) {
    return UserModel(
      id: preserveUserId ?? '',
      name: name,
      image: profileImage,
      mobileNumber: int.tryParse(number),
      countryCode: countryCode,
      emailId: email,
      goAvgRating: userRating,
    );
  }
}
