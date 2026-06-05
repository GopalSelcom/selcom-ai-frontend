import 'dart:convert';

NidaCardModel nidaCardModelFromJson(String str) =>
    NidaCardModel.fromJson(json.decode(str));

String nidaCardModelToJson(NidaCardModel data) => json.encode(data.toJson());

class NidaCardModel {
  String? nidaCardNumber;
  String? firstName;
  String? lastName;
  String? dob;
  String? sex;
  String? expiry;
  String? nation;

  NidaCardModel({
    this.nidaCardNumber,
    this.firstName,
    this.lastName,
    this.dob,
    this.sex,
    this.expiry,
    this.nation,
  });

  NidaCardModel copyWith({
    String? nidaCardNumber,
    String? firstName,
    String? lastName,
    String? dob,
    String? sex,
    String? expiry,
    String? nation,
  }) => NidaCardModel(
    nidaCardNumber: nidaCardNumber ?? this.nidaCardNumber,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    dob: dob ?? this.dob,
    sex: sex ?? this.sex,
    expiry: expiry ?? this.expiry,
    nation: nation ?? this.nation,
  );

  factory NidaCardModel.fromJson(Map<String, dynamic> json) => NidaCardModel(
    nidaCardNumber: json["nida_card_number"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    dob: json["dob"],
    sex: json["sex"],
    expiry: json["expiry"],
    nation: json["nation"],
  );

  Map<String, dynamic> toJson() => {
    "nida_card_number": nidaCardNumber,
    "first_name": firstName,
    "last_name": lastName,
    "dob": dob,
    "sex": sex,
    "expiry": expiry,
    "nation": nation,
  };
}
