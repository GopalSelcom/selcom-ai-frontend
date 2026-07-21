import 'dart:convert';

class FirebaseLoginResponseModel {
  int? statusCode;
  String? message;
  FirebaseLoginResponse? data;

  FirebaseLoginResponseModel({
    this.statusCode,
    this.message,
    this.data,
  });

  factory FirebaseLoginResponseModel.fromRawJson(String str) => FirebaseLoginResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FirebaseLoginResponseModel.fromJson(Map<String, dynamic> json) => FirebaseLoginResponseModel(
    statusCode: json["status_code"],
    message: json["message"],
    data: json["data"] == null ? null : FirebaseLoginResponse.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class FirebaseLoginResponse {
  String? accessToken;
  String? newRefreshToken;
  User? user;
  bool? isNewUser;
  String? walletStatus;
  bool? walletStatusFlag;
  bool? needsPhone;
  String? name;
  String? email;
  bool? needsName;

  FirebaseLoginResponse({
    this.accessToken,
    this.newRefreshToken,
    this.user,
    this.isNewUser,
    this.walletStatus,
    this.walletStatusFlag,
    this.needsPhone,
    this.name,
    this.email,
    this.needsName,
  });

  factory FirebaseLoginResponse.fromRawJson(String str) => FirebaseLoginResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FirebaseLoginResponse.fromJson(Map<String, dynamic> json) => FirebaseLoginResponse(
    accessToken: json["accessToken"],
    newRefreshToken: json["newRefreshToken"],
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    isNewUser: json["is_new_user"],
    walletStatus: json["wallet_status"],
    walletStatusFlag: json["wallet_status_flag"],
    needsPhone: json["needs_phone"],
    name: json["name"],
    email: json["email"],
    needsName: json["needs_name"],
  );

  Map<String, dynamic> toJson() => {
    "accessToken": accessToken,
    "newRefreshToken": newRefreshToken,
    "user": user?.toJson(),
    "is_new_user": isNewUser,
    "wallet_status": walletStatus,
    "wallet_status_flag": walletStatusFlag,
    "needs_phone": needsPhone,
    "name": name,
    "email": email,
    "needs_name": needsName,
  };
}

class User {
  String? id;
  String? name;
  String? emailId;
  int? mobileNumber;
  String? countryCode;
  String? image;
  int? isVerify;
  String? firebaseUid;

  User({
    this.id,
    this.name,
    this.emailId,
    this.mobileNumber,
    this.countryCode,
    this.image,
    this.isVerify,
    this.firebaseUid,
  });

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["_id"],
    name: json["name"],
    emailId: json["emailId"],
    mobileNumber: json["mobile_number"],
    countryCode: json["country_code"],
    image: json["image"],
    isVerify: json["is_verify"],
    firebaseUid: json["firebase_uid"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "emailId": emailId,
    "mobile_number": mobileNumber,
    "country_code": countryCode,
    "image": image,
    "is_verify": isVerify,
    "firebase_uid": firebaseUid,
  };
}
