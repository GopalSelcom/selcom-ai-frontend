class CountriesModel {
  int? statusCode;
  String? message;
  List<CountriesResponse>? response;

  CountriesModel({this.statusCode, this.message, this.response});

  CountriesModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'];
    message = json['message'];
    if (json['response'] != null) {
      response = <CountriesResponse>[];
      json['response'].forEach((v) {
        response!.add(new CountriesResponse.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status_code'] = this.statusCode;
    data['message'] = this.message;
    data['response'] = this.response!.map((v) => v.toJson()).toList();
    return data;
  }
}

class CountriesResponse {
  String? isActive;
  String? isTopPositioned;
  String? capital;
  String? citizenship;
  String? currencyName;
  String? currencyCode;
  String? currencySubUnit;
  String? currencySymbol;
  String? iso3Code;
  String? iso2Code;
  String? phoneCode;
  String? regionCode;
  String? subRegionCode;
  String? flag;
  String? sId;
  String? id;
  String? name;
  String? fullName;

  bool isSelected = false;

  CountriesResponse({
    this.isActive,
    this.isTopPositioned,
    this.capital,
    this.citizenship,
    this.currencyName,
    this.currencyCode,
    this.currencySubUnit,
    this.currencySymbol,
    this.iso3Code,
    this.iso2Code,
    this.phoneCode,
    this.regionCode,
    this.subRegionCode,
    this.flag,
    this.sId,
    this.id,
    this.name,
    this.fullName,
  });

  CountriesResponse.fromJson(Map<String, dynamic> json) {
    isActive = json['is_active'];
    isTopPositioned = json['is_top_positioned'];
    capital = json['capital'];
    citizenship = json['citizenship'];
    currencyName = json['currency_name'];
    currencyCode = json['currency_code'];
    currencySubUnit = json['currency_sub_unit'];
    currencySymbol = json['currency_symbol'];
    iso3Code = json['iso3_code'];
    iso2Code = json['iso2_code'];
    phoneCode = json['phone_code'];
    regionCode = json['region_code'];
    subRegionCode = json['sub_region_code'];
    flag = json['flag'];
    sId = json['_id'];
    id = json['id'];
    name = json['name'];
    fullName = json['full_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['is_active'] = this.isActive;
    data['is_top_positioned'] = this.isTopPositioned;
    data['capital'] = this.capital;
    data['citizenship'] = this.citizenship;
    data['currency_name'] = this.currencyName;
    data['currency_code'] = this.currencyCode;
    data['currency_sub_unit'] = this.currencySubUnit;
    data['currency_symbol'] = this.currencySymbol;
    data['iso3_code'] = this.iso3Code;
    data['iso2_code'] = this.iso2Code;
    data['phone_code'] = this.phoneCode;
    data['region_code'] = this.regionCode;
    data['sub_region_code'] = this.subRegionCode;
    data['flag'] = this.flag;
    data['_id'] = this.sId;
    data['id'] = this.id;
    data['name'] = this.name;
    data['full_name'] = this.fullName;
    return data;
  }
}
