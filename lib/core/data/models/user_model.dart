import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.countryCode,
    super.mobileNumber,
    super.emailId,
    super.image,
    super.dob,
    super.selectedLanguage,
    super.activeToken,
    super.accessToken,
    super.isVerify,
    super.isBlocked,
    super.personId,
    super.tin,
    super.tinNumber,
    super.nidaNumber,
    super.lat,
    super.lng,
    super.pushNotification,
    super.smsNotification,
    super.emailNotification,
    super.subscribeForNewsletter,
    super.totalOrders,
    super.isCodEnable,
    super.isEmailOtpVerify,
    super.appUuid,
    super.accountNumber,
    super.uniqueId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['location']?['coordinates'] as List?;
    return UserModel(
      id: json['_id'] ?? '',
      countryCode: json['country_code'],
      mobileNumber: json['mobile_number'],
      emailId: json['emailId'],
      image: json['image'],
      dob: json['dob'],
      selectedLanguage: json['selected_language'],
      activeToken: json['activeToken'],
      accessToken: json['access_token'],
      isVerify: json['is_verify'],
      isBlocked: json['is_blocked'],
      personId: json['person_id'],
      tin: json['tin'],
      tinNumber: json['tin_number'],
      nidaNumber: json['nida_number'],
      lat: (coordinates != null && coordinates.length > 1)
          ? coordinates[1].toDouble()
          : 0.0,
      lng: (coordinates != null && coordinates.isNotEmpty)
          ? coordinates[0].toDouble()
          : 0.0,
      pushNotification: json['push_notification'],
      smsNotification: json['sms_notification'],
      emailNotification: json['email_notification'],
      subscribeForNewsletter: json['subscribe_for_newsletter'],
      totalOrders: json['total_orders'],
      isCodEnable: json['is_cod_enable'],
      isEmailOtpVerify: json['is_email_otp_verify'],
      appUuid: json['app_uuid'],
      accountNumber: json['account_number'],
      uniqueId: json['unique_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'country_code': countryCode,
      'mobile_number': mobileNumber,
      'emailId': emailId,
      'image': image,
      'dob': dob,
      'selected_language': selectedLanguage,
      'activeToken': activeToken,
      'access_token': accessToken,
      'is_verify': isVerify,
      'is_blocked': isBlocked,
      'person_id': personId,
      'tin': tin,
      'tin_number': tinNumber,
      'nida_number': nidaNumber,
      'location': {
        'type': 'Point',
        'coordinates': [lng, lat],
      },
      'push_notification': pushNotification,
      'sms_notification': smsNotification,
      'email_notification': emailNotification,
      'subscribe_for_newsletter': subscribeForNewsletter,
      'total_orders': totalOrders,
      'is_cod_enable': isCodEnable,
      'is_email_otp_verify': isEmailOtpVerify,
      'app_uuid': appUuid,
      'account_number': accountNumber,
      'unique_id': uniqueId,
    };
  }
}
