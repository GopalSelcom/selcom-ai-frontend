import '../../domain/entities/selcom_pesa_linked_account_entity.dart';

class SelcomPesaSendLinkRequest {
  const SelcomPesaSendLinkRequest({
    required this.spCountryCode,
    required this.spMobileNumber,
  });

  final String spCountryCode;
  final String spMobileNumber;

  Map<String, dynamic> toJson() => {
    'sp_country_code': spCountryCode.trim(),
    'sp_mobile_number': spMobileNumber.trim(),
  };
}

class SelcomPesaMainBalanceRequest {
  const SelcomPesaMainBalanceRequest({
    this.mobileNumber,
    this.countryCode,
  });

  final String? mobileNumber;
  final String? countryCode;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    final phone = mobileNumber?.trim() ?? '';
    final code = countryCode?.trim() ?? '';
    if (phone.isNotEmpty) {
      json['mobile_number'] = phone;
    }
    if (code.isNotEmpty) {
      json['country_code'] = code;
    }
    return json;
  }
}

class SelcomPesaLinkedAccountsResult {
  const SelcomPesaLinkedAccountsResult({
    required this.count,
    required this.accounts,
  });

  final int count;
  final List<SelcomPesaLinkedAccountEntity> accounts;

  factory SelcomPesaLinkedAccountsResult.fromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawAccounts = map['accounts'];
    final accounts = <SelcomPesaLinkedAccountEntity>[];
    if (rawAccounts is List) {
      for (final item in rawAccounts) {
        if (item is Map<String, dynamic>) {
          accounts.add(SelcomPesaLinkedAccountEntityMapper.fromJson(item));
        } else if (item is Map) {
          accounts.add(
            SelcomPesaLinkedAccountEntityMapper.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final countValue = map['count'];
    return SelcomPesaLinkedAccountsResult(
      count: countValue is int ? countValue : accounts.length,
      accounts: accounts,
    );
  }
}

class SelcomPesaMainBalanceResult {
  const SelcomPesaMainBalanceResult({
    required this.balance,
    required this.currency,
    this.raw = const {},
  });

  final double balance;
  final String currency;
  final Map<String, dynamic> raw;

  factory SelcomPesaMainBalanceResult.fromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map<String, dynamic>
        ? data
        : data is Map
        ? Map<String, dynamic>.from(data)
        : const <String, dynamic>{};

    return SelcomPesaMainBalanceResult(
      balance: _readBalance(map),
      currency: _readString(map, const [
        'currency',
        'currency_code',
        'ccy',
      ]),
      raw: map,
    );
  }

  static double _readBalance(Map<String, dynamic> map) {
    for (final key in const [
      'balance',
      'main_balance',
      'available_balance',
      'available',
      'amount',
    ]) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '').trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static String _readString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = 'TZS',
  }) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }
}

abstract final class SelcomPesaLinkedAccountEntityMapper {
  static SelcomPesaLinkedAccountEntity fromJson(Map<String, dynamic> json) {
    return SelcomPesaLinkedAccountEntity(
      id: _readString(json, const ['id', '_id', 'link_id', 'account_id']),
      status: SelcomPesaLinkStatus.fromApi(
        _readString(json, const ['status', 'link_status']),
      ),
      countryCode: _readString(
        json,
        const ['sp_country_code', 'country_code'],
        fallback: '255',
      ),
      mobileNumber: _readString(
        json,
        const ['sp_mobile_number', 'mobile_number'],
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }
}
