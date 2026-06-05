// To parse this JSON data, do
//
//     final userAddCardDetailModel = userAddCardDetailModelFromJson(jsonString);

import 'dart:convert';

UserAddCardDetailModel userAddCardDetailModelFromJson(String str) =>
    UserAddCardDetailModel.fromJson(json.decode(str));

String userAddCardDetailModelToJson(UserAddCardDetailModel data) =>
    json.encode(data.toJson());

class UserAddCardDetailModel {
  int? statusCode;
  String? message;
  UserAddCardDetailResponse? response;

  UserAddCardDetailModel({this.statusCode, this.message, this.response});

  UserAddCardDetailModel copyWith({
    int? statusCode,
    String? message,
    UserAddCardDetailResponse? response,
  }) => UserAddCardDetailModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory UserAddCardDetailModel.fromJson(Map<String, dynamic> json) =>
      UserAddCardDetailModel(
        statusCode: json["status_code"],
        message: json["message"],
        response: json["response"] == null
            ? null
            : UserAddCardDetailResponse.fromJson(json["response"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}

class UserAddCardDetailResponse {
  String? id;
  String? userId;
  String? clientId;
  String? accountNo;
  String? cardNumber;
  String? serialNumber;
  String? cardId;
  String? expiry;
  int? status;
  DateTime? createdOn;
  String? selfieImage;
  String? maskedCard;
  String? firstName;
  String? lastName;
  String? address;
  String? city;
  String? gender;
  String? dob;
  String? nidaNumberExact;
  int? v;
  int? limitAmount;
  String? passportNumber;

  UserAddCardDetailResponse({
    this.id,
    this.userId,
    this.clientId,
    this.accountNo,
    this.cardNumber,
    this.serialNumber,
    this.cardId,
    this.expiry,
    this.status,
    this.createdOn,
    this.selfieImage,
    this.maskedCard,
    this.firstName,
    this.lastName,
    this.address,
    this.city,
    this.gender,
    this.dob,
    this.nidaNumberExact,
    this.v,
    this.limitAmount,
    this.passportNumber,
  });

  UserAddCardDetailResponse copyWith({
    String? id,
    String? userId,
    String? clientId,
    String? accountNo,
    String? cardNumber,
    String? serialNumber,
    String? cardId,
    String? expiry,
    int? status,
    DateTime? createdOn,
    String? selfieImage,
    String? maskedCard,
    String? firstName,
    String? lastName,
    String? address,
    String? city,
    String? gender,
    String? dob,
    String? nidaNumberExact,
    int? v,
    int? limitAmount,
    String? passportNumber,
  }) => UserAddCardDetailResponse(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    clientId: clientId ?? this.clientId,
    accountNo: accountNo ?? this.accountNo,
    cardNumber: cardNumber ?? this.cardNumber,
    serialNumber: serialNumber ?? this.serialNumber,
    cardId: cardId ?? this.cardId,
    expiry: expiry ?? this.expiry,
    status: status ?? this.status,
    createdOn: createdOn ?? this.createdOn,
    selfieImage: selfieImage ?? this.selfieImage,
    maskedCard: maskedCard ?? this.maskedCard,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    address: address ?? this.address,
    city: city ?? this.city,
    gender: gender ?? this.gender,
    dob: dob ?? this.dob,
    nidaNumberExact: nidaNumberExact ?? this.nidaNumberExact,
    v: v ?? this.v,
    limitAmount: limitAmount ?? this.limitAmount,
    passportNumber: passportNumber ?? this.passportNumber,
  );

  factory UserAddCardDetailResponse.fromJson(Map<String, dynamic> json) =>
      UserAddCardDetailResponse(
        id: json["_id"],
        userId: json["user_id"],
        clientId: json["client_id"],
        accountNo: json["account_no"],
        cardNumber: json["card_number"],
        serialNumber: json["serial_number"],
        cardId: json["card_id"],
        expiry: json["expiry"],
        status: json["status"],
        createdOn: json["created_on"] == null
            ? null
            : DateTime.parse(json["created_on"]),
        selfieImage: json["selfie_image"],
        maskedCard: json["masked_card"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        address: json["address"],
        city: json["city"],
        gender: json["gender"],
        dob: json["dob"],
        nidaNumberExact: json["nida_number_exact"],
        v: json["__v"],
        limitAmount: json["limit_amount"],
        passportNumber: json["passport_number"],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "user_id": userId,
    "client_id": clientId,
    "account_no": accountNo,
    "card_number": cardNumber,
    "serial_number": serialNumber,
    "card_id": cardId,
    "expiry": expiry,
    "status": status,
    "created_on": createdOn?.toIso8601String(),
    "selfie_image": selfieImage,
    "masked_card": maskedCard,
    "first_name": firstName,
    "last_name": lastName,
    "address": address,
    "city": city,
    "gender": gender,
    "dob": dob,
    "nida_number_exact": nidaNumberExact,
    "__v": v,
    "limit_amount": limitAmount,
    "passport_number": passportNumber,
  };
}
