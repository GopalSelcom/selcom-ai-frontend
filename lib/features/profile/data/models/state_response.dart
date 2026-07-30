class SelectStateModel {
  int? statusCode;
  String? message;
  List<StateResponse>? response;

  SelectStateModel({this.statusCode, this.message, this.response});

  SelectStateModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'];
    message = json['message'];
    if (json['response'] != null) {
      response = <StateResponse>[];
      json['response'].forEach((v) {
        response!.add(StateResponse.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status_code'] = statusCode;
    data['message'] = message;
    data['response'] = response!.map((v) => v.toJson()).toList();
    return data;
  }
}

class StateResponse {
  String? isActive;
  String? isTopPositioned;
  String? countryId;
  String? sId;
  String? id;
  String? name;
  String? timezoneId;

  bool isSelected = false;

  StateResponse({
    this.isActive,
    this.isTopPositioned,
    this.countryId,
    this.sId,
    this.id,
    this.name,
    this.timezoneId,
  });

  StateResponse.fromJson(Map<String, dynamic> json) {
    isActive = json['is_active'];
    isTopPositioned = json['is_top_positioned'];
    countryId = json['country_id'];
    sId = json['_id'];
    id = json['id'];
    name = json['name'];
    timezoneId = json['timezone_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_active'] = isActive;
    data['is_top_positioned'] = isTopPositioned;
    data['country_id'] = countryId;
    data['_id'] = sId;
    data['id'] = id;
    data['name'] = name;
    data['timezone_id'] = timezoneId;
    return data;
  }
}
