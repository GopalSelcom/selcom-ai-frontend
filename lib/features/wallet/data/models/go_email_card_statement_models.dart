import '../../domain/entities/wallet_statement_email_result.dart';

class EmailCardStatementRequest {
  const EmailCardStatementRequest({
    required this.email,
    required this.startDate,
    required this.endDate,
    required this.currency,
  });

  final String email;
  final String startDate;
  final String endDate;
  final String currency;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'startdate': startDate,
    'enddate': endDate,
    'currency': currency,
  };
}

class GoEmailCardStatementResponseModel {
  GoEmailCardStatementResponseModel({
    this.statusCode,
    this.message,
    this.response,
  });

  final int? statusCode;
  final String? message;
  final GoEmailCardStatementData? response;

  factory GoEmailCardStatementResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final payload = json['response'];
    return GoEmailCardStatementResponseModel(
      statusCode: json['status_code'] as int?,
      message: json['message']?.toString(),
      response: payload is Map<String, dynamic>
          ? GoEmailCardStatementData.fromJson(payload)
          : null,
    );
  }

  bool get isSuccess => statusCode == 200 && response != null;
}

class GoEmailCardStatementData {
  GoEmailCardStatementData({
    this.email,
    this.startDate,
    this.endDate,
    this.records,
    this.pdfBytes,
    this.rangeCapped = false,
  });

  final String? email;
  final String? startDate;
  final String? endDate;
  final int? records;
  final int? pdfBytes;
  final bool rangeCapped;

  factory GoEmailCardStatementData.fromJson(Map<String, dynamic> json) {
    return GoEmailCardStatementData(
      email: json['email']?.toString(),
      startDate: json['startdate']?.toString(),
      endDate: json['enddate']?.toString(),
      records: _parseInt(json['records']),
      pdfBytes: _parseInt(json['pdf_bytes']),
      rangeCapped: json['range_capped'] == true,
    );
  }

  WalletStatementEmailResult toEntity({required String fallbackMessage}) {
    return WalletStatementEmailResult(
      message: fallbackMessage.trim(),
      email: email?.trim() ?? '',
      startDate: startDate,
      endDate: endDate,
      records: records ?? 0,
      rangeCapped: rangeCapped,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
