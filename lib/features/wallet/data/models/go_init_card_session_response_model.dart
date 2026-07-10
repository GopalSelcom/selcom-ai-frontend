
// To parse this JSON data, do
//
//     final initSessionCardModel = initSessionCardModelFromJson(jsonString);

import 'dart:convert';

InitSessionCardModel initSessionCardModelFromJson(String str) =>
    InitSessionCardModel.fromJson(json.decode(str));

String initSessionCardModelToJson(InitSessionCardModel data) =>
    json.encode(data.toJson());

class InitSessionCardModel {
  InitSessionCardModel({
    this.statusCode,
    this.message,
    this.url,
    this.transid,
    this.data,
  });

  int? statusCode;
  String? message;
  String? url;
  String? transid;
  List<Datum>? data;

  InitSessionCardModel copyWith({
    int? statusCode,
    String? message,
    String? url,
    String? transid,
    List<Datum>? data,
  }) =>
      InitSessionCardModel(
        statusCode: statusCode ?? this.statusCode,
        message: message ?? this.message,
        url: url ?? this.url,
        transid: transid ?? this.transid,
        data: data ?? this.data,
      );

  factory InitSessionCardModel.fromJson(Map<String, dynamic> json) =>
      InitSessionCardModel(
        statusCode: json["status_code"],
        message: json["message"],
        url: json["url"],
        transid: json["transid"],
        data: json["data"] != null
            ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "url": url,
    "transid": transid,
    "data": List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  Datum({
    this.billToEmail,
    this.billToForename,
    this.billToSurname,
    this.referenceNumber,
    this.billToAddressLine1,
    this.billToAddressState,
    this.billToAddressPostalCode,
    this.billToAddressCountry,
    this.billToAddressCity,
    this.amount,
    this.billToPhone,
    this.transactionUuid,
    this.signedFieldNames,
    this.accessKey,
    this.profileId,
    this.unsignedFieldNames,
    this.signedDateTime,
    this.locale,
    this.transactionType,
    this.currency,
    this.paymentMethod,
    this.signature,
  });

  String? billToEmail;
  String? billToForename;
  String? billToSurname;
  String? referenceNumber;
  String? billToAddressLine1;
  String? billToAddressState;
  String? billToAddressPostalCode;
  String? billToAddressCountry;
  String? billToAddressCity;
  String? amount;
  String? billToPhone;
  int? transactionUuid;
  String? signedFieldNames;
  String? accessKey;
  String? profileId;
  String? unsignedFieldNames;
  String? signedDateTime;
  String? locale;
  String? transactionType;
  String? currency;
  String? paymentMethod;
  String? signature;

  Datum copyWith({
    String? billToEmail,
    String? billToForename,
    String? billToSurname,
    String? referenceNumber,
    String? billToAddressLine1,
    String? billToAddressState,
    String? billToAddressPostalCode,
    String? billToAddressCountry,
    String? billToAddressCity,
    String? amount,
    String? billToPhone,
    int? transactionUuid,
    String? signedFieldNames,
    String? accessKey,
    String? profileId,
    String? unsignedFieldNames,
    String? signedDateTime,
    String? locale,
    String? transactionType,
    String? currency,
    String? paymentMethod,
    String? signature,
  }) =>
      Datum(
        billToEmail: billToEmail ?? this.billToEmail,
        billToForename: billToForename ?? this.billToForename,
        billToSurname: billToSurname ?? this.billToSurname,
        referenceNumber: referenceNumber ?? this.referenceNumber,
        billToAddressLine1: billToAddressLine1 ?? this.billToAddressLine1,
        billToAddressState: billToAddressState ?? this.billToAddressState,
        billToAddressPostalCode:
        billToAddressPostalCode ?? this.billToAddressPostalCode,
        billToAddressCountry: billToAddressCountry ?? this.billToAddressCountry,
        billToAddressCity: billToAddressCity ?? this.billToAddressCity,
        amount: amount ?? this.amount,
        billToPhone: billToPhone ?? this.billToPhone,
        transactionUuid: transactionUuid ?? this.transactionUuid,
        signedFieldNames: signedFieldNames ?? this.signedFieldNames,
        accessKey: accessKey ?? this.accessKey,
        profileId: profileId ?? this.profileId,
        unsignedFieldNames: unsignedFieldNames ?? this.unsignedFieldNames,
        signedDateTime: signedDateTime ?? this.signedDateTime,
        locale: locale ?? this.locale,
        transactionType: transactionType ?? this.transactionType,
        currency: currency ?? this.currency,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        signature: signature ?? this.signature,
      );

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    billToEmail: json["bill_to_email"],
    billToForename: json["bill_to_forename"],
    billToSurname: json["bill_to_surname"],
    referenceNumber: json["reference_number"],
    billToAddressLine1: json["bill_to_address_line1"],
    billToAddressState: json["bill_to_address_state"],
    billToAddressPostalCode: json["bill_to_address_postal_code"],
    billToAddressCountry: json["bill_to_address_country"],
    billToAddressCity: json["bill_to_address_city"],
    amount: json["amount"],
    billToPhone: json["bill_to_phone"],
    transactionUuid: json["transaction_uuid"],
    signedFieldNames: json["signed_field_names"],
    accessKey: json["access_key"],
    profileId: json["profile_id"],
    unsignedFieldNames: json["unsigned_field_names"],
    signedDateTime: json["signed_date_time"],
    locale: json["locale"],
    transactionType: json["transaction_type"],
    currency: json["currency"],
    paymentMethod: json["payment_method"],
    signature: json["signature"],
  );

  Map<String, dynamic> toJson() => {
    "bill_to_email": billToEmail,
    "bill_to_forename": billToForename,
    "bill_to_surname": billToSurname,
    "reference_number": referenceNumber,
    "bill_to_address_line1": billToAddressLine1,
    "bill_to_address_state": billToAddressState,
    "bill_to_address_postal_code": billToAddressPostalCode,
    "bill_to_address_country": billToAddressCountry,
    "bill_to_address_city": billToAddressCity,
    "amount": amount,
    "bill_to_phone": billToPhone,
    "transaction_uuid": transactionUuid,
    "signed_field_names": signedFieldNames,
    "access_key": accessKey,
    "profile_id": profileId,
    "unsigned_field_names": unsignedFieldNames,
    "signed_date_time": signedDateTime,
    "locale": locale,
    "transaction_type": transactionType,
    "currency": currency,
    "payment_method": paymentMethod,
    "signature": signature,
  };
}
