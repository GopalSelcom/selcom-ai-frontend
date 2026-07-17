import 'dart:convert';

class GoWalletCardModel {
  String? reference;
  String? resultcode;
  String? result;
  String? message;
  List<Datum>? data;

  GoWalletCardModel({
    this.reference,
    this.resultcode,
    this.result,
    this.message,
    this.data,
  });

  factory GoWalletCardModel.fromRawJson(String str) =>
      GoWalletCardModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GoWalletCardModel.fromJson(Map<String, dynamic> json) =>
      GoWalletCardModel(
        reference: json["reference"]?.toString(),
        resultcode: json["resultcode"]?.toString(),
        result: json["result"]?.toString(),
        message: json["message"]?.toString(),
        data: json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "reference": reference,
        "resultcode": resultcode,
        "result": result,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class Datum {
  int? id;
  String? maskedCard;
  DateTime? creationDate;
  String? cardToken;
  String? name;
  String? cardType;

  Datum({
    this.id,
    this.maskedCard,
    this.creationDate,
    this.cardToken,
    this.name,
    this.cardType,
  });

  factory Datum.fromRawJson(String str) => Datum.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        id: json["id"] as int?,
        maskedCard: json["masked_card"]?.toString(),
        creationDate: json["creation_date"] == null
            ? null
            : DateTime.tryParse(json["creation_date"].toString()),
        cardToken: json["card_token"]?.toString(),
        name: json["name"]?.toString(),
        cardType: json["card_type"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "masked_card": maskedCard,
        "creation_date": creationDate?.toIso8601String(),
        "card_token": cardToken,
        "name": name,
        "card_type": cardType,
      };
}
