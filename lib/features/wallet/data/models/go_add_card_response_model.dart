class GoAddCardResponseModel {
  final int statusCode;
  final String message;
  final String url;
  final String transId;

  GoAddCardResponseModel({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.transId,
  });

  factory GoAddCardResponseModel.fromJson(Map<String, dynamic> json) {
    return GoAddCardResponseModel(
      statusCode: json['status_code'] as int? ?? json['status'] as int? ?? 0,
      message: json['message']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      transId: json['transid']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'message': message,
      'url': url,
      'transid': transId,
    };
  }

  bool get isCardExists => message.trim().toLowerCase() == 'cardexists';
}
