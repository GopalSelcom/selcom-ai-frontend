import '../../vehicle_type_model.dart';

class VehicleTypesResponseModel {
  final int? statusCode;
  final String? message;
  final VehicleTypesData? data;

  VehicleTypesResponseModel({this.statusCode, this.message, this.data});

  factory VehicleTypesResponseModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypesResponseModel(
      statusCode: json['status_code'],
      message: json['message'],
      data: json['data'] != null ? VehicleTypesData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;
}

class VehicleTypesData {
  final List<VehicleTypeModel>? vehicleTypes;

  VehicleTypesData({this.vehicleTypes});

  factory VehicleTypesData.fromJson(Map<String, dynamic> json) {
    return VehicleTypesData(
      vehicleTypes: json['vehicle_types'] != null
          ? (json['vehicle_types'] as List)
              .map((v) => VehicleTypeModel.fromJson(v))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_types': vehicleTypes?.map((v) => v.toJson()).toList(),
    };
  }
}
