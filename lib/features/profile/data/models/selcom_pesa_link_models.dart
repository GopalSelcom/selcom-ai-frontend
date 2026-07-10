import '../../domain/entities/selcom_pesa_linked_account_entity.dart';
import 'dart:convert';

class SelcomPesaSendLinkRequest {
  const SelcomPesaSendLinkRequest({
    required this.spCountryCode,
    required this.spMobileNumber,
  });

  final String spCountryCode;
  final String spMobileNumber;

  Map<String, dynamic> toJson() => {
    'sp_country_code': spCountryCode.trim(),
    'sp_mobile_number': spMobileNumber.trim(),
  };
}

class SelcomPesaRequestUnlinkRequest {
  const SelcomPesaRequestUnlinkRequest({required this.spMobileNumber});

  final String spMobileNumber;

  Map<String, dynamic> toJson() => {
    'sp_mobile_number': spMobileNumber.trim(),
  };
}

class SelcomPesaSetDefaultRequest {
  const SelcomPesaSetDefaultRequest({required this.spMobileNumber});

  final String spMobileNumber;

  Map<String, dynamic> toJson() => {
    'sp_mobile_number': spMobileNumber.trim(),
  };
}

class SelcomPesaMainBalanceRequest {
  const SelcomPesaMainBalanceRequest({
    this.mobileNumber,
    this.countryCode,
  });

  final String? mobileNumber;
  final String? countryCode;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    final phone = mobileNumber?.trim() ?? '';
    final code = countryCode?.trim() ?? '';
    if (phone.isNotEmpty) {
      json['mobile_number'] = phone;
    }
    if (code.isNotEmpty) {
      json['country_code'] = code;
    }
    return json;
  }
}





SelcomPesaLinkedAccountsResult selcomPesaLinkedAccountsResultFromJson(String str) => SelcomPesaLinkedAccountsResult.fromJson(json.decode(str));

String selcomPesaLinkedAccountsResultToJson(SelcomPesaLinkedAccountsResult data) => json.encode(data.toJson());

class SelcomPesaLinkedAccountsResult {
  int? statusCode;
  String? message;
  Data? data;

  SelcomPesaLinkedAccountsResult({
    this.statusCode,
    this.message,
    this.data,
  });

  SelcomPesaLinkedAccountsResult copyWith({
    int? statusCode,
    String? message,
    Data? data,
  }) =>
      SelcomPesaLinkedAccountsResult(
        statusCode: statusCode ?? this.statusCode,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory SelcomPesaLinkedAccountsResult.fromJson(Map<String, dynamic> json) => SelcomPesaLinkedAccountsResult(
    statusCode: json["status_code"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  int? count;
  List<Account>? accounts;

  Data({
    this.count,
    this.accounts,
  });

  Data copyWith({
    int? count,
    List<Account>? accounts,
  }) =>
      Data(
        count: count ?? this.count,
        accounts: accounts ?? this.accounts,
      );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    count: json["count"],
    accounts: json["accounts"] == null ? [] : List<Account>.from(json["accounts"]!.map((x) => Account.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "count": count,
    "accounts": accounts == null ? [] : List<dynamic>.from(accounts!.map((x) => x.toJson())),
  };
}

class Account {
  String? userId;
  String? spCountryCode;
  String? spMobileNumber;
  String? goCountryCode;
  String? goMobileNumber;
  String? senderName;
  String? channel;
  String? appLogo;
  String? deviceType;
  String? languageCode;
  String? requestId;
  String? status;
  String? result;
  String? resultCode;
  String? resultMessage;
  DateTime? linkedOn;
  dynamic unlinkedOn;
  String? id;
  DateTime? createdOn;
  DateTime? updatedOn;
  int? v;
  bool? isActive;
  bool? isDefault;

  Account({
    this.userId,
    this.spCountryCode,
    this.spMobileNumber,
    this.goCountryCode,
    this.goMobileNumber,
    this.senderName,
    this.channel,
    this.appLogo,
    this.deviceType,
    this.languageCode,
    this.requestId,
    this.status,
    this.result,
    this.resultCode,
    this.resultMessage,
    this.linkedOn,
    this.unlinkedOn,
    this.id,
    this.createdOn,
    this.updatedOn,
    this.isActive,
    this.isDefault,
    this.v,
  });

  Account copyWith({
    String? userId,
    String? spCountryCode,
    String? spMobileNumber,
    String? goCountryCode,
    String? goMobileNumber,
    String? senderName,
    String? channel,
    String? appLogo,
    String? deviceType,
    String? languageCode,
    String? requestId,
    String? status,
    String? result,
    String? resultCode,
    String? resultMessage,
    DateTime? linkedOn,
    dynamic unlinkedOn,
    String? id,
    DateTime? createdOn,
    DateTime? updatedOn,
    bool? isActive,
    bool? isDefault,
    int? v,
  }) =>
      Account(
        userId: userId ?? this.userId,
        spCountryCode: spCountryCode ?? this.spCountryCode,
        spMobileNumber: spMobileNumber ?? this.spMobileNumber,
        goCountryCode: goCountryCode ?? this.goCountryCode,
        goMobileNumber: goMobileNumber ?? this.goMobileNumber,
        senderName: senderName ?? this.senderName,
        channel: channel ?? this.channel,
        appLogo: appLogo ?? this.appLogo,
        deviceType: deviceType ?? this.deviceType,
        languageCode: languageCode ?? this.languageCode,
        requestId: requestId ?? this.requestId,
        status: status ?? this.status,
        result: result ?? this.result,
        resultCode: resultCode ?? this.resultCode,
        resultMessage: resultMessage ?? this.resultMessage,
        linkedOn: linkedOn ?? this.linkedOn,
        unlinkedOn: unlinkedOn ?? this.unlinkedOn,
        id: id ?? this.id,
        createdOn: createdOn ?? this.createdOn,
        updatedOn: updatedOn ?? this.updatedOn,
        v: v ?? this.v,
        isActive: isActive??this.isActive,
        isDefault: isDefault??this.isDefault,
      );

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    userId: json["user_id"],
    spCountryCode: json["sp_country_code"],
    spMobileNumber: json["sp_mobile_number"],
    goCountryCode: json["go_country_code"],
    goMobileNumber: json["go_mobile_number"],
    senderName: json["sender_name"],
    channel: json["channel"],
    appLogo: json["app_logo"],
    deviceType: json["device_type"],
    languageCode: json["language_code"],
    requestId: json["request_id"],
    status: json["status"],
    result: json["result"],
    resultCode: json["result_code"],
    resultMessage: json["result_message"],
    linkedOn: json["linked_on"] == null ? null : DateTime.parse(json["linked_on"]),
    unlinkedOn: json["unlinked_on"],
    id: json["_id"],
    createdOn: json["created_on"] == null ? null : DateTime.parse(json["created_on"]),
    updatedOn: json["updated_on"] == null ? null : DateTime.parse(json["updated_on"]),
    isActive: json['is_active'],
    isDefault: json['is_default'],
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "sp_country_code": spCountryCode,
    "sp_mobile_number": spMobileNumber,
    "go_country_code": goCountryCode,
    "go_mobile_number": goMobileNumber,
    "sender_name": senderName,
    "channel": channel,
    "app_logo": appLogo,
    "device_type": deviceType,
    "language_code": languageCode,
    "request_id": requestId,
    "status": status,
    "result": result,
    "result_code": resultCode,
    "result_message": resultMessage,
    "linked_on": linkedOn?.toIso8601String(),
    "unlinked_on": unlinkedOn,
    "_id": id,
    "created_on": createdOn?.toIso8601String(),
    "updated_on": updatedOn?.toIso8601String(),
    'is_active': isActive,
    'is_default': isDefault,
    "__v": v,
  };
}

