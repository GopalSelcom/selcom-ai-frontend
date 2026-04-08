class UserEntity {
  final String id;
  final String name;
  final int mobileNumber;
  final String countryCode;
  final String? email;
  final String? imageUrl;
  final String? deviceToken;
  final int? deviceType;
  final String? accessToken;
  final bool isVerified;
  final bool isBlocked;
  
  // New Fields from v4 Response
  final String? emailId;
  final String? tin;
  final String? tinNumber;
  final String? nidaNumber;
  final String? dob;
  final String? image;
  final String? selectedLanguage;
  final int? personId;
  final double? lat;
  final double? lng;
  final int? pushNotification;
  final int? emailNotification;
  final int? smsNotification;
  final int? subscribeForNewsletter;
  final int? totalOrders;
  final bool? isCodEnable;
  final String? appReferalCode;
  final bool? isEmailOtpVerify;
  final String? activeToken;
  final int? accountNumber;
  final String? appUuid;

  const UserEntity({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.countryCode,
    this.email,
    this.imageUrl,
    this.deviceToken,
    this.deviceType,
    this.accessToken,
    required this.isVerified,
    required this.isBlocked,
    
    // New Fields
    this.emailId,
    this.tin,
    this.tinNumber,
    this.nidaNumber,
    this.dob,
    this.image,
    this.selectedLanguage,
    this.personId,
    this.lat,
    this.lng,
    this.pushNotification,
    this.emailNotification,
    this.smsNotification,
    this.subscribeForNewsletter,
    this.totalOrders,
    this.isCodEnable,
    this.appReferalCode,
    this.isEmailOtpVerify,
    this.activeToken,
    this.accountNumber,
    this.appUuid,
  });
}
