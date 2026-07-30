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
        response!.add(CountriesResponse.fromJson(v));
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_active'] = isActive;
    data['is_top_positioned'] = isTopPositioned;
    data['capital'] = capital;
    data['citizenship'] = citizenship;
    data['currency_name'] = currencyName;
    data['currency_code'] = currencyCode;
    data['currency_sub_unit'] = currencySubUnit;
    data['currency_symbol'] = currencySymbol;
    data['iso3_code'] = iso3Code;
    data['iso2_code'] = iso2Code;
    data['phone_code'] = phoneCode;
    data['region_code'] = regionCode;
    data['sub_region_code'] = subRegionCode;
    data['flag'] = flag;
    data['_id'] = sId;
    data['id'] = id;
    data['name'] = name;
    data['full_name'] = fullName;
    return data;
  }
}
