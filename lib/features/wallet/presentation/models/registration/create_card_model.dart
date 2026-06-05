import 'dart:convert';

CreateCardModel createCardModelFromJson(String str) =>
    CreateCardModel.fromJson(json.decode(str));

String createCardModelToJson(CreateCardModel data) =>
    json.encode(data.toJson());

class CreateCardModel {
  int? statusCode;
  String? message;
  Response? response;

  CreateCardModel({this.statusCode, this.message, this.response});

  CreateCardModel copyWith({
    int? statusCode,
    String? message,
    Response? response,
  }) => CreateCardModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory CreateCardModel.fromJson(Map<String, dynamic> json) =>
      CreateCardModel(
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
  String? reference;
  String? transid;
  String? resultcode;
  String? result;
  String? message;
  List<Datum>? data;

  Response({
    this.reference,
    this.transid,
    this.resultcode,
    this.result,
    this.message,
    this.data,
  });

  Response copyWith({
    String? reference,
    String? transid,
    String? resultcode,
    String? result,
    String? message,
    List<Datum>? data,
  }) => Response(
    reference: reference ?? this.reference,
    transid: transid ?? this.transid,
    resultcode: resultcode ?? this.resultcode,
    result: result ?? this.result,
    message: message ?? this.message,
    data: data ?? this.data,
  );

  factory Response.fromJson(Map<String, dynamic> json) => Response(
    reference: json["reference"],
    transid: json["transid"],
    resultcode: json["resultcode"],
    result: json["result"],
    message: json["message"],
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "reference": reference,
    "transid": transid,
    "resultcode": resultcode,
    "result": result,
    "message": message,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  int? cardId;
  String? maskedCard;
  String? vcnUrl;

  Datum({this.cardId, this.maskedCard, this.vcnUrl});

  Datum copyWith({int? cardId, String? maskedCard, String? vcnUrl}) => Datum(
    cardId: cardId ?? this.cardId,
    maskedCard: maskedCard ?? this.maskedCard,
    vcnUrl: vcnUrl ?? this.vcnUrl,
  );

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    cardId: json["card_id"],
    maskedCard: json["masked_card"],
    vcnUrl: json["vcn_url"],
  );

  Map<String, dynamic> toJson() => {
    "card_id": cardId,
    "masked_card": maskedCard,
    "vcn_url": vcnUrl,
  };
}
