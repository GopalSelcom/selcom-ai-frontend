class GoInitCardSessionResponseModel {
  final int statusCode;
  final String message;
  final String url;
  final String transId;
  final dynamic data; // Contains Selcom session parameters

  GoInitCardSessionResponseModel({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.transId,
    required this.data,
  });

  factory GoInitCardSessionResponseModel.fromJson(Map<String, dynamic> json) {
    return GoInitCardSessionResponseModel(
      statusCode: json['status_code'] as int? ?? json['status'] as int? ?? 0,
      message: json['message']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      transId: json['transid']?.toString() ?? json['transId']?.toString() ?? '',
      data: json['data'],
    );
  }
}
