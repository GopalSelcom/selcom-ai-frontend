// To parse this JSON data, do
//
//     final goCardBalanceResponseModel = goCardBalanceResponseModelFromJson(jsonString);

import 'dart:convert';

GoCardBalanceResponseModel goCardBalanceResponseModelFromJson(String str) => GoCardBalanceResponseModel.fromJson(json.decode(str));

String goCardBalanceResponseModelToJson(GoCardBalanceResponseModel data) => json.encode(data.toJson());

class GoCardBalanceResponseModel {
  int? statusCode;
  String? message;
  BalanceResponse? response;

  GoCardBalanceResponseModel({
    this.statusCode,
    this.message,
    this.response,
  });

  GoCardBalanceResponseModel copyWith({
    int? statusCode,
    String? message,
    BalanceResponse? response,
  }) =>
      GoCardBalanceResponseModel(
        statusCode: statusCode ?? this.statusCode,
        message: message ?? this.message,
        response: response ?? this.response,
      );

  factory GoCardBalanceResponseModel.fromJson(Map<String, dynamic> json) => GoCardBalanceResponseModel(
    statusCode: json["status_code"],
    message: json["message"],
    response: json["response"] == null ? null : BalanceResponse.fromJson(json["response"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}

class BalanceResponse {
  String? result;
  String? resultcode;
  String? pan;
  String? name;
  String? phone;
  String? cardNumber;
  String? accountType;
  String? dealer;
  String? group;
  int? records;
  List<BalanceDatum>? data;

  BalanceResponse({
    this.result,
    this.resultcode,
    this.pan,
    this.name,
    this.phone,
    this.cardNumber,
    this.accountType,
    this.dealer,
    this.group,
    this.records,
    this.data,
  });

  BalanceResponse copyWith({
    String? result,
    String? resultcode,
    String? pan,
    String? name,
    String? phone,
    String? cardNumber,
    String? accountType,
    String? dealer,
    String? group,
    int? records,
    List<BalanceDatum>? data,
  }) =>
      BalanceResponse(
        result: result ?? this.result,
        resultcode: resultcode ?? this.resultcode,
        pan: pan ?? this.pan,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        cardNumber: cardNumber ?? this.cardNumber,
        accountType: accountType ?? this.accountType,
        dealer: dealer ?? this.dealer,
        group: group ?? this.group,
        records: records ?? this.records,
        data: data ?? this.data,
      );

  factory BalanceResponse.fromJson(Map<String, dynamic> json) => BalanceResponse(
    result: json["result"],
    resultcode: json["resultcode"],
    pan: json["pan"],
    name: json["name"],
    phone: json["phone"],
    cardNumber: json["card_number"],
    accountType: json["account_type"],
    dealer: json["dealer"],
    group: json["group"],
    records: json["records"],
    data: json["data"] == null ? [] : List<BalanceDatum>.from(json["data"]!.map((x) => BalanceDatum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": result,
    "resultcode": resultcode,
    "pan": pan,
    "name": name,
    "phone": phone,
    "card_number": cardNumber,
    "account_type": accountType,
    "dealer": dealer,
    "group": group,
    "records": records,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class BalanceDatum {
  int? id;
  String? currency;
  int? balance;
  int? reserved;
  int? available;
  String? status;

  BalanceDatum({
    this.id,
    this.currency,
    this.balance,
    this.reserved,
    this.available,
    this.status,
  });

  BalanceDatum copyWith({
    int? id,
    String? currency,
    int? balance,
    int? reserved,
    int? available,
    String? status,
  }) =>
      BalanceDatum(
        id: id ?? this.id,
        currency: currency ?? this.currency,
        balance: balance ?? this.balance,
        reserved: reserved ?? this.reserved,
        available: available ?? this.available,
        status: status ?? this.status,
      );

  factory BalanceDatum.fromJson(Map<String, dynamic> json) => BalanceDatum(
    id: json["id"],
    currency: json["currency"],
    balance: json["balance"],
    reserved: json["reserved"],
    available: json["available"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "currency": currency,
    "balance": balance,
    "reserved": reserved,
    "available": available,
    "status": status,
  };
}

extension GoCardBalanceResponseModelX on GoCardBalanceResponseModel {
  bool get isSuccess => statusCode == 200 && response != null;

  BalanceDatum? get _firstDatum =>
      response?.data?.isNotEmpty == true ? response!.data!.first : null;

  int get availableBalance =>
      _firstDatum?.available ?? _firstDatum?.balance ?? 0;
  int get reservedBalance => _firstDatum?.reserved ?? 0;
  String get currency =>
      _firstDatum?.currency?.trim().isNotEmpty == true
          ? _firstDatum!.currency!.trim()
          : 'TZS';
  String get pan =>
      response?.pan?.trim().isNotEmpty == true
          ? response!.pan!.trim()
          : response?.cardNumber?.trim() ?? '';
  String get holderName => response?.name?.trim() ?? '';
}
