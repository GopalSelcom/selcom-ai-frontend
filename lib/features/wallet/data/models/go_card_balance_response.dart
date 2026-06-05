import '../../domain/entities/wallet_card_balance_entity.dart';

class GoCardBalanceResponseModel {
  GoCardBalanceResponseModel({
    this.statusCode,
    this.message,
    this.response,
  });

  final int? statusCode;
  final String? message;
  final GoCardBalanceData? response;

  factory GoCardBalanceResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['response'];
    return GoCardBalanceResponseModel(
      statusCode: json['status_code'] as int?,
      message: json['message']?.toString(),
      response: payload is Map<String, dynamic>
          ? GoCardBalanceData.fromJson(payload)
          : null,
    );
  }

  bool get isSuccess => statusCode == 200 && response != null;
}

class GoCardBalanceData {
  GoCardBalanceData({
    this.result,
    this.resultCode,
    this.pan,
    this.currency,
    this.available,
    this.reserved,
  });

  final String? result;
  final String? resultCode;
  final String? pan;
  final String? currency;
  final String? available;
  final String? reserved;

  factory GoCardBalanceData.fromJson(Map<String, dynamic> json) {
    return GoCardBalanceData(
      result: json['result']?.toString(),
      resultCode: json['resultcode']?.toString(),
      pan: json['pan']?.toString(),
      currency: json['currency']?.toString(),
      available: json['available']?.toString(),
      reserved: json['reserved']?.toString(),
    );
  }

  WalletCardBalanceEntity toEntity() {
    return WalletCardBalanceEntity(
      available: _parseAmount(available),
      reserved: _parseAmount(reserved),
      currency: currency?.trim().isNotEmpty == true ? currency!.trim() : 'TZS',
      pan: pan?.trim() ?? '',
    );
  }

  static double _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.trim()) ?? 0;
  }
}
