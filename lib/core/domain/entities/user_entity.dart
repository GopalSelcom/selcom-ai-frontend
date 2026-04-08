class UserEntity {
  final String id;
  final String? countryCode;
  final int? mobileNumber;
  final String? emailId;
  final String? image;
  final String? dob;
  final String? selectedLanguage;
  final String? activeToken;
  final String? accessToken;
  final int? isVerify;
  final int? isBlocked;
  final int? personId;
  final String? tin;
  final String? tinNumber;
  final String? nidaNumber;
  final double? lat;
  final double? lng;
  final int? pushNotification;
  final int? smsNotification;
  final int? emailNotification;
  final int? subscribeForNewsletter;
  final int? totalOrders;
  final bool? isCodEnable;
  final bool? isEmailOtpVerify;
  final String? appUuid;
  final int? accountNumber;
  final String? uniqueId;

  const UserEntity({
    required this.id,
    this.countryCode,
    this.mobileNumber,
    this.emailId,
    this.image,
    this.dob,
    this.selectedLanguage,
    this.activeToken,
    this.accessToken,
    this.isVerify,
    this.isBlocked,
    this.personId,
    this.tin,
    this.tinNumber,
    this.nidaNumber,
    this.lat,
    this.lng,
    this.pushNotification,
    this.smsNotification,
    this.emailNotification,
    this.subscribeForNewsletter,
    this.totalOrders,
    this.isCodEnable,
    this.isEmailOtpVerify,
    this.appUuid,
    this.accountNumber,
    this.uniqueId,
  });
}
