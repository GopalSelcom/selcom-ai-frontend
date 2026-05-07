// To parse this JSON data, do
//
//     final userProfileUpdateResponse = userProfileUpdateResponseFromJson(jsonString);

import 'dart:convert';

UserProfileUpdateResponse userProfileUpdateResponseFromJson(String str) =>
    UserProfileUpdateResponse.fromJson(json.decode(str));

String userProfileUpdateResponseToJson(UserProfileUpdateResponse data) =>
    json.encode(data.toJson());

class UserProfileUpdateResponse {
  int? statusCode;
  String? message;
  Response? response;

  UserProfileUpdateResponse({this.statusCode, this.message, this.response});

  factory UserProfileUpdateResponse.fromJson(Map<String, dynamic> json) =>
      UserProfileUpdateResponse(
        statusCode: json["status_code"],
        message: json["message"],
        response: json["response"] == null
            ? null
            : Response.fromJson(json["response"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}

class Response {
  Location? location;
  int? personId;
  String? emailId;
  String? tin;
  String? latitude;
  String? longitude;
  int? isVerify;
  int? mobileNumber;
  int? isBlocked;
  int? isGeneratePin;
  List<dynamic>? categoryList;
  List<dynamic>? brandList;
  List<dynamic>? recommndedList;
  List<dynamic>? offerList;
  List<dynamic>? bannerImage;
  String? image;
  String? dob;
  int? pushNotification;
  int? emailNotification;
  int? smsNotification;
  int? subscribeForNewsletter;
  String? selectedLanguage;
  int? totalOrders;
  String? id;
  String? name;
  String? countryCode;
  String? deviceToken;
  int? deviceType;
  String? accessToken;
  String? appUuid;
  int? accountNumber;
  int? v;
  String? tinNumber;
  String? appReferalCode;
  String? nidaNumber;
  dynamic businessDetailsObj;
  bool? isEmailOtpVerify;

  Response({
    this.location,
    this.personId,
    this.emailId,
    this.tin,
    this.latitude,
    this.longitude,
    this.isVerify,
    this.mobileNumber,
    this.isBlocked,
    this.isGeneratePin,
    this.categoryList,
    this.brandList,
    this.recommndedList,
    this.offerList,
    this.bannerImage,
    this.image,
    this.dob,
    this.pushNotification,
    this.emailNotification,
    this.smsNotification,
    this.subscribeForNewsletter,
    this.selectedLanguage,
    this.totalOrders,
    this.id,
    this.name,
    this.countryCode,
    this.deviceToken,
    this.deviceType,
    this.accessToken,
    this.appUuid,
    this.accountNumber,
    this.v,
    this.tinNumber,
    this.appReferalCode,
    this.nidaNumber,
    this.businessDetailsObj,
    this.isEmailOtpVerify,
  });

  factory Response.fromJson(Map<String, dynamic> json) => Response(
    location: json["location"] == null
        ? null
        : Location.fromJson(json["location"]),
    personId: json["person_id"],
    emailId: json["emailId"],
    tin: json["tin"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    isVerify: json["is_verify"],
    mobileNumber: json["mobile_number"],
    isBlocked: json["is_blocked"],
    isGeneratePin: json["is_generate_pin"],
    categoryList: json["categoryList"] == null
        ? []
        : List<dynamic>.from(json["categoryList"]!.map((x) => x)),
    brandList: json["brandList"] == null
        ? []
        : List<dynamic>.from(json["brandList"]!.map((x) => x)),
    recommndedList: json["recommndedList"] == null
        ? []
        : List<dynamic>.from(json["recommndedList"]!.map((x) => x)),
    offerList: json["offerList"] == null
        ? []
        : List<dynamic>.from(json["offerList"]!.map((x) => x)),
    bannerImage: json["bannerImage"] == null
        ? []
        : List<dynamic>.from(json["bannerImage"]!.map((x) => x)),
    image: json["image"],
    dob: json["dob"],
    pushNotification: json["push_notification"],
    emailNotification: json["email_notification"],
    smsNotification: json["sms_notification"],
    subscribeForNewsletter: json["subscribe_for_newsletter"],
    selectedLanguage: json["selected_language"],
    totalOrders: json["total_orders"],
    id: json["_id"],
    name: json["name"],
    countryCode: json["country_code"],
    deviceToken: json["device_token"],
    deviceType: json["device_type"],
    accessToken: json["access_token"],
    appUuid: json["app_uuid"],
    accountNumber: json["account_number"],
    v: json["__v"],
    tinNumber: json["tin_number"],
    appReferalCode: json["app_referal_code"],
    nidaNumber: json["nida_number"],
    businessDetailsObj: json["business_details_obj"],
    isEmailOtpVerify: json["is_email_otp_verify"],
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "person_id": personId,
    "emailId": emailId,
    "tin": tin,
    "latitude": latitude,
    "longitude": longitude,
    "is_verify": isVerify,
    "mobile_number": mobileNumber,
    "is_blocked": isBlocked,
    "is_generate_pin": isGeneratePin,
    "categoryList": categoryList == null
        ? []
        : List<dynamic>.from(categoryList!.map((x) => x)),
    "brandList": brandList == null
        ? []
        : List<dynamic>.from(brandList!.map((x) => x)),
    "recommndedList": recommndedList == null
        ? []
        : List<dynamic>.from(recommndedList!.map((x) => x)),
    "offerList": offerList == null
        ? []
        : List<dynamic>.from(offerList!.map((x) => x)),
    "bannerImage": bannerImage == null
        ? []
        : List<dynamic>.from(bannerImage!.map((x) => x)),
    "image": image,
    "dob": dob,
    "push_notification": pushNotification,
    "email_notification": emailNotification,
    "sms_notification": smsNotification,
    "subscribe_for_newsletter": subscribeForNewsletter,
    "selected_language": selectedLanguage,
    "total_orders": totalOrders,
    "_id": id,
    "name": name,
    "country_code": countryCode,
    "device_token": deviceToken,
    "device_type": deviceType,
    "access_token": accessToken,
    "app_uuid": appUuid,
    "account_number": accountNumber,
    "__v": v,
    "tin_number": tinNumber,
    "app_referal_code": appReferalCode,
    "nida_number": nidaNumber,
    "business_details_obj": businessDetailsObj,
    "is_email_otp_verify": isEmailOtpVerify,
  };
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: json["type"],
    coordinates: json["coordinates"] == null
        ? []
        : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}
