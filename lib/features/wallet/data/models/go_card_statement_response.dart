import 'dart:convert';

class GoCardStatementResponseModel {
  int? statusCode;
  String? message;
  Response? response;

  GoCardStatementResponseModel({this.statusCode, this.message, this.response});

  factory GoCardStatementResponseModel.fromRawJson(String str) =>
      GoCardStatementResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GoCardStatementResponseModel.fromJson(Map<String, dynamic> json) =>
      GoCardStatementResponseModel(
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
  String? result;
  String? pan;
  String? currency;
  int? balance;
  String? name;
  DateTime? startdate;
  DateTime? enddate;
  int? records;
  List<Datum>? data;

  Response({
    this.result,
    this.pan,
    this.currency,
    this.balance,
    this.name,
    this.startdate,
    this.enddate,
    this.records,
    this.data,
  });

  factory Response.fromRawJson(String str) =>
      Response.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Response.fromJson(Map<String, dynamic> json) => Response(
    result: json["result"],
    pan: json["pan"],
    currency: json["currency"],
    balance: json["balance"],
    name: json["name"],
    startdate: json["startdate"] == null
        ? null
        : DateTime.parse(json["startdate"]),
    enddate: json["enddate"] == null ? null : DateTime.parse(json["enddate"]),
    records: json["records"],
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "result": result,
    "pan": pan,
    "currency": currency,
    "balance": balance,
    "name": name,
    "startdate": startdate == null
        ? null
        : "${startdate!.year.toString().padLeft(4, '0')}-${startdate!.month.toString().padLeft(2, '0')}-${startdate!.day.toString().padLeft(2, '0')}",
    "enddate": enddate == null
        ? null
        : "${enddate!.year.toString().padLeft(4, '0')}-${enddate!.month.toString().padLeft(2, '0')}-${enddate!.day.toString().padLeft(2, '0')}",
    "records": records,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  int? id;
  String? fulltimestamp;
  String? transid;
  String? reference;
  String? currency;
  String? amount;
  String? charge;
  String? obal;
  String? cbal;
  String? transtype;
  String? utilitycode;

  Datum({
    this.id,
    this.fulltimestamp,
    this.transid,
    this.reference,
    this.currency,
    this.amount,
    this.charge,
    this.obal,
    this.cbal,
    this.transtype,
    this.utilitycode,
  });

  factory Datum.fromRawJson(String str) => Datum.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    fulltimestamp: json["fulltimestamp"],
    transid: json["transid"],
    reference: json["reference"],
    currency: json["currency"],
    amount: json["amount"],
    charge: json["charge"],
    obal: json["obal"],
    cbal: json["cbal"],
    transtype: json["transtype"],
    utilitycode: json["utilitycode"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fulltimestamp": fulltimestamp,
    "transid": transid,
    "reference": reference,
    "currency": currency,
    "amount": amount,
    "charge": charge,
    "obal": obal,
    "cbal": cbal,
    "transtype": transtype,
    "utilitycode": utilitycode,
  };
}
