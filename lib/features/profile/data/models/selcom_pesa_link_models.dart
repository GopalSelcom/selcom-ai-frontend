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

class SelcomPesaRequestUnlinkRequest {
  const SelcomPesaRequestUnlinkRequest({required this.spMobileNumber});

  final String spMobileNumber;

  Map<String, dynamic> toJson() => {
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
    final data = _asMap(json['data']);
    final spResponse = _asMap(data['sp_response']);
    final balanceSource = spResponse.isNotEmpty
        ? _asMap(spResponse['data'])
        : data;
    final source = balanceSource.isNotEmpty ? balanceSource : data;

    return SelcomPesaMainBalanceResult(
      balance: _readBalance(source),
      currency: _readString(source, const [
        'currency',
        'currency_code',
        'ccy',
      ]),
      raw: data,
    );
  }

  /// When envelope `status_code` is 200 but SP payload reports failure.
  static String? spResponseErrorMessage(Map<String, dynamic> envelope) {
    final spResponse = _asMap(_asMap(envelope['data'])['sp_response']);
    if (spResponse.isEmpty) return null;
    if (spResponse['success'] == true) return null;

    final message = spResponse['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    return null;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
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
