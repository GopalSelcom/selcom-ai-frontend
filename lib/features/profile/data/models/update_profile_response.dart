import 'dart:convert';

import '../../../../core/data/models/user_model.dart';
import '../cache/user_profile_cache.dart';

/// Envelope for `edit_profile` / update profile.
class UpdateProfileResponse {
  int? statusCode;
  String? message;
  UpdateProfileData? data;

  UpdateProfileResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory UpdateProfileResponse.fromJson(String str) =>
      UpdateProfileResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UpdateProfileResponse.fromMap(Map<String, dynamic> json) {
    final rawData = json["data"];
    Map<String, dynamic>? dataMap;
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    }
    return UpdateProfileResponse(
      statusCode: json["status_code"],
      message: json["message"],
      data: dataMap == null ? null : UpdateProfileData.fromMap(dataMap),
    );
  }

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };

  UserModel? toUserModel({String? preserveUserId}) {
    return data?.toUserModel(preserveUserId: preserveUserId);
  }
}

class UpdateProfileData {
  String? profileImage;
  String? number;
  String? countryCode;
  num? userRating;
  String? email;
  String? name;

  UpdateProfileData({
    this.profileImage,
    this.number,
    this.countryCode,
    this.userRating,
    this.email,
    this.name,
  });

  factory UpdateProfileData.fromJson(String str) =>
      UpdateProfileData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UpdateProfileData.fromMap(Map<String, dynamic> json) =>
      UpdateProfileData(
        profileImage: json["profile_image"]?.toString(),
        number: json["number"]?.toString(),
        countryCode: json["country_code"]?.toString(),
        userRating: json["user_rating"],
        email: json["email"]?.toString(),
        name: json["name"]?.toString(),
      );

  Map<String, dynamic> toMap() => {
    "profile_image": profileImage,
    "number": number,
    "country_code": countryCode,
    "user_rating": userRating,
    "email": email,
    "name": name,
  };

  UserModel toUserModel({String? preserveUserId}) {
    final existingUser = UserProfileCache.user;
    final fallbackId = (preserveUserId != null && preserveUserId.isNotEmpty)
        ? preserveUserId
        : (existingUser?.id ?? '');

    final parsedNumber = number == null || number!.trim().isEmpty
        ? null
        : int.tryParse(number!.trim());

    return UserModel(
      id: fallbackId,
      name: name ?? existingUser?.name,
      emailId: email ?? existingUser?.emailId,
      mobileNumber: parsedNumber ?? existingUser?.mobileNumber,
      countryCode: countryCode ?? existingUser?.countryCode,
      image: profileImage ?? existingUser?.image,
      goAvgRating: userRating ?? existingUser?.goAvgRating,
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
