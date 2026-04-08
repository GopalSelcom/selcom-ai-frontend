import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.user,
    required super.accessToken,
    required super.refreshToken,
    required super.isUserAlreadyRegistered,
    required super.isUserAddressAdded,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Determine if we're looking at the top-level API response or the data object
    final data = json.containsKey('response') ? json['response'] : json;

    return AuthModel(
      user: UserModel.fromJson(data['user'] ?? {}),
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
      isUserAlreadyRegistered: data['is_user_already_registered'] ?? false,
      isUserAddressAdded: data['is_user_address_added'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'is_user_already_registered': isUserAlreadyRegistered,
      'is_user_address_added': isUserAddressAdded,
    };
  }
}

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
    
    // New Fields
    super.emailId,
    super.tin,
    super.tinNumber,
    super.nidaNumber,
    super.dob,
    super.image,
    super.selectedLanguage,
    super.personId,
    super.lat,
    super.lng,
    super.pushNotification,
    super.emailNotification,
    super.smsNotification,
    super.subscribeForNewsletter,
    super.totalOrders,
    super.isCodEnable,
    super.appReferalCode,
    super.isEmailOtpVerify,
    super.activeToken,
    super.accountNumber,
    super.appUuid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['location']?['coordinates'] as List?;
    
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] is int 
          ? json['mobile_number'] 
          : int.tryParse(json['mobile_number']?.toString() ?? '0') ?? 0,
      countryCode: json['country_code'] ?? '',
      email: json['email'] ?? json['emailId'],
      imageUrl: json['image_url'] ?? json['image'],
      deviceToken: json['device_token'],
      deviceType: json['device_type'] is int 
          ? json['device_type'] 
          : int.tryParse(json['device_type']?.toString() ?? '1') ?? 1,
      accessToken: json['accessToken'] ?? json['activeToken'],
      isVerified: json['is_verify'] == 1 || json['is_verified'] == 1 || json['is_verify'] == true,
      isBlocked: json['is_blocked'] == 1 || json['is_blocked'] == true,
      
      // New mappings
      emailId: json['emailId'],
      tin: json['tin'],
      tinNumber: json['tin_number'],
      nidaNumber: json['nida_number'],
      dob: json['dob'],
      image: json['image'],
      selectedLanguage: json['selected_language'],
      personId: json['person_id'],
      lat: (coordinates != null && coordinates.length > 1) ? coordinates[1].toDouble() : null,
      lng: (coordinates != null && coordinates.isNotEmpty) ? coordinates[0].toDouble() : null,
      pushNotification: json['push_notification'],
      emailNotification: json['email_notification'],
      smsNotification: json['sms_notification'],
      subscribeForNewsletter: json['subscribe_for_newsletter'],
      totalOrders: json['total_orders'],
      isCodEnable: json['is_cod_enable'],
      appReferalCode: json['app_referal_code'],
      isEmailOtpVerify: json['is_email_otp_verify'],
      activeToken: json['activeToken'],
      accountNumber: json['account_number'],
      appUuid: json['app_uuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'mobile_number': mobileNumber,
      'country_code': countryCode,
      'emailId': emailId,
      'image': image,
      'device_token': deviceToken,
      'device_type': deviceType,
      'activeToken': activeToken,
      'is_verify': isVerified ? 1 : 0,
      'is_blocked': isBlocked ? 1 : 0,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
      // ... other fields can be added if needed for persistence
    };
  }
}
