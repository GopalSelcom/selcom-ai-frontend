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

  bool get isSuccess =>
      statusCode == 200 && response != null && response!.isSuccessful;
}

class GoCardBalanceData {
  GoCardBalanceData({
    this.result,
    this.resultCode,
    this.pan,
    this.name,
    this.phone,
    this.cardNumber,
    this.accountType,
    this.currency,
    this.available,
    this.reserved,
    this.balance,
    this.status,
  });

  final String? result;
  final String? resultCode;
  final String? pan;
  final String? name;
  final String? phone;
  final String? cardNumber;
  final String? accountType;
  final String? currency;
  final String? available;
  final String? reserved;
  final String? balance;
  final String? status;

  factory GoCardBalanceData.fromJson(Map<String, dynamic> json) {
    final line = _primaryBalanceLine(json);

    return GoCardBalanceData(
      result: json['result']?.toString(),
      resultCode: json['resultcode']?.toString(),
      pan: json['pan']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      cardNumber: json['card_number']?.toString(),
      accountType: json['account_type']?.toString(),
      currency: _stringOrNull(line?['currency']) ?? json['currency']?.toString(),
      available:
          _amountAsString(line?['available']) ?? json['available']?.toString(),
      reserved:
          _amountAsString(line?['reserved']) ?? json['reserved']?.toString(),
      balance: _amountAsString(line?['balance']) ?? json['balance']?.toString(),
      status: line?['status']?.toString() ?? json['status']?.toString(),
    );
  }

  bool get isSuccessful {
    final normalizedResult = result?.trim().toUpperCase();
    if (normalizedResult == 'SUCCESS') return true;
    return resultCode?.trim() == '000';
  }

  WalletCardBalanceEntity toEntity() {
    final availableAmount = _parseAmount(available);
    final balanceAmount = _parseAmount(balance);
    return WalletCardBalanceEntity(
      available: availableAmount > 0 ? availableAmount : balanceAmount,
      reserved: _parseAmount(reserved),
      currency: currency?.trim().isNotEmpty == true ? currency!.trim() : 'TZS',
      pan: pan?.trim() ?? '',
      holderName: name?.trim().isNotEmpty == true ? name!.trim() : null,
    );
  }

  static Map<String, dynamic>? _primaryBalanceLine(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List || data.isEmpty) return null;

    Map<String, dynamic>? first;
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      first ??= item;
      final status = item['status']?.toString().trim().toUpperCase();
      if (status == 'ACTIVE') {
        return item;
      }
    }
    return first;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _amountAsString(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toString();
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.trim()) ?? 0;
  }
}
