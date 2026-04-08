import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.mobileNumber,
    required super.countryCode,
    super.email,
    super.imageUrl,
    super.deviceToken,
    super.deviceType,
    super.accessToken,
    required super.isVerified,
    required super.isBlocked,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] ?? 0,
      countryCode: json['country_code'] ?? '',
      email: json['email'],
      imageUrl: json['image'],
      deviceToken: json['device_token'],
      deviceType: json['device_type'],
      accessToken: json['access_token'],
      isVerified: json['is_verify'] == 1,
      isBlocked: json['is_blocked'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'mobile_number': mobileNumber,
      'country_code': countryCode,
      'email': email,
      'image': imageUrl,
      'device_token': deviceToken,
      'device_type': deviceType,
      'access_token': accessToken,
      'is_verify': isVerified ? 1 : 0,
      'is_blocked': isBlocked ? 1 : 0,
    };
  }
}
