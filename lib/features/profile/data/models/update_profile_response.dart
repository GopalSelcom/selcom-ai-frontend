import '../../../../core/data/models/user_model.dart';
import '../cache/user_profile_cache.dart';

class UserProfileUpdateResponse {
  final int? statusCode;
  final String? message;
  final UserData? data;

  UserProfileUpdateResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory UserProfileUpdateResponse.fromJson(Map<String, dynamic> json) =>
      UserProfileUpdateResponse(
        statusCode: json['status_code'] as int?,
        message: json['message'] as String?,
        data: json['data'] == null ? null : UserData.fromJson(json['data']),
      );

  Map<String, dynamic> toJson() => {
        'status_code': statusCode,
        'message': message,
        'data': data?.toJson(),
      };

  UserModel? toUserModel({String? preserveUserId}) {
    return data?.toUserModel(preserveUserId: preserveUserId);
  }
}

class UserData {
  final String? profileImage;
  final int? number;
  final String? countryCode;
  final int? userRating;
  final String? email;
  final String? name;

  UserData({
    this.profileImage,
    this.number,
    this.countryCode,
    this.userRating,
    this.email,
    this.name,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        profileImage: json['profile_image'] as String?,
        number: json['number'] is int
            ? json['number'] as int
            : int.tryParse(json['number']?.toString() ?? ''),
        countryCode: json['country_code'] as String?,
        userRating: json['user_rating'] is int
            ? json['user_rating'] as int
            : (json['user_rating'] as num?)?.toInt(),
        email: json['email'] as String?,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'profile_image': profileImage,
        'number': number,
        'country_code': countryCode,
        'user_rating': userRating,
        'email': email,
        'name': name,
      };

  UserModel toUserModel({String? preserveUserId}) {
    final existingUser = UserProfileCache.user;
    final fallbackId = (preserveUserId != null && preserveUserId.isNotEmpty)
        ? preserveUserId
        : (existingUser?.id ?? '');

    return UserModel(
      id: fallbackId,
      name: name ?? existingUser?.name,
      emailId: email ?? existingUser?.emailId,
      mobileNumber: number ?? existingUser?.mobileNumber,
      countryCode: countryCode ?? existingUser?.countryCode,
      image: profileImage ?? existingUser?.image,
      goAvgRating: userRating != null ? userRating!.toDouble() : existingUser?.goAvgRating,
      accessToken: existingUser?.accessToken,
      activeToken: existingUser?.activeToken,
      accountNumber: existingUser?.accountNumber,
      dob: existingUser?.dob,
      firebaseUid: existingUser?.firebaseUid,
      isBlocked: existingUser?.isBlocked,
      isVerify: existingUser?.isVerify,
      nidaNumber: existingUser?.nidaNumber,
    );
  }
}
