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

/// Wallet card balance payload from `go_wallet/go_card_balance`.
class GoCardBalanceData {
  GoCardBalanceData({
    this.result,
    this.resultCode,
    this.pan,
    this.name,
    this.phone,
    this.cardNumber,
    this.accountType,
    this.dealer,
    this.group,
    this.records,
    this.data = const [],
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
  final String? dealer;
  final String? group;
  final int? records;
  final List<GoCardBalanceLineItem> data;

  /// Flattened from the primary ACTIVE balance line for legacy callers.
  final String? currency;
  final String? available;
  final String? reserved;
  final String? balance;
  final String? status;

  factory GoCardBalanceData.fromJson(Map<String, dynamic> json) {
    final lines = _parseBalanceLines(json['data']);
    final line = _primaryBalanceLine(lines);

    return GoCardBalanceData(
      result: json['result']?.toString(),
      resultCode: json['resultcode']?.toString(),
      pan: json['pan']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      cardNumber: json['card_number']?.toString(),
      accountType: json['account_type']?.toString(),
      dealer: json['dealer']?.toString(),
      group: json['group']?.toString(),
      records: _parseInt(json['records']),
      data: lines,
      currency: line?.currency ?? json['currency']?.toString(),
      available: line?.available ?? json['available']?.toString(),
      reserved: line?.reserved ?? json['reserved']?.toString(),
      balance: line?.balance ?? json['balance']?.toString(),
      status: line?.status ?? json['status']?.toString(),
    );
  }

  bool get isSuccessful {
    final normalizedResult = result?.trim().toUpperCase();
    if (normalizedResult == 'SUCCESS') return true;
    return resultCode?.trim() == '000';
  }

  WalletCardBalanceEntity toEntity() {
    final primary = primaryBalanceLine;
    final availableAmount = _parseAmount(primary?.available ?? available);
    final balanceAmount = _parseAmount(primary?.balance ?? balance);
    final hasAvailableField = (primary?.available ?? available)
            ?.trim()
            .isNotEmpty ==
        true;
    return WalletCardBalanceEntity(
      available: hasAvailableField ? availableAmount : balanceAmount,
      reserved: _parseAmount(primary?.reserved ?? reserved),
      currency: (primary?.currency ?? currency)?.trim().isNotEmpty == true
          ? (primary?.currency ?? currency)!.trim()
          : 'TZS',
      pan: pan?.trim() ?? '',
      holderName: name?.trim().isNotEmpty == true ? name!.trim() : null,
    );
  }

  GoCardBalanceLineItem? get primaryBalanceLine => _primaryBalanceLine(data);

  static List<GoCardBalanceLineItem> _parseBalanceLines(dynamic raw) {
    if (raw is! List) return const [];

    final lines = <GoCardBalanceLineItem>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      lines.add(GoCardBalanceLineItem.fromJson(item));
    }
    return lines;
  }

  static GoCardBalanceLineItem? _primaryBalanceLine(
    List<GoCardBalanceLineItem> lines,
  ) {
    if (lines.isEmpty) return null;

    for (final item in lines) {
      if (item.status?.trim().toUpperCase() == 'ACTIVE') {
        return item;
      }
    }
    return lines.first;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.trim()) ?? 0;
  }
}

class GoCardBalanceLineItem {
  const GoCardBalanceLineItem({
    this.id,
    this.currency,
    this.balance,
    this.reserved,
    this.available,
    this.status,
  });

  final int? id;
  final String? currency;
  final String? balance;
  final String? reserved;
  final String? available;
  final String? status;

  factory GoCardBalanceLineItem.fromJson(Map<String, dynamic> json) {
    return GoCardBalanceLineItem(
      id: GoCardBalanceData._parseInt(json['id']),
      currency: json['currency']?.toString(),
      balance: _amountAsString(json['balance']),
      reserved: _amountAsString(json['reserved']),
      available: _amountAsString(json['available']),
      status: json['status']?.toString(),
    );
  }

  static String? _amountAsString(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toString();
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
