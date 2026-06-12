import '../../domain/entities/wallet_transaction_entity.dart';

class GoCardStatementResponseModel {
  GoCardStatementResponseModel({
    this.statusCode,
    this.message,
    this.response,
  });

  final int? statusCode;
  final String? message;
  final GoCardStatementData? response;

  factory GoCardStatementResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['response'];
    return GoCardStatementResponseModel(
      statusCode: json['status_code'] as int?,
      message: json['message']?.toString(),
      response: payload is Map<String, dynamic>
          ? GoCardStatementData.fromJson(payload)
          : null,
    );
  }

  bool get isSuccess => statusCode == 200 && response != null;
}

class GoCardStatementData {
  GoCardStatementData({
    this.result,
    this.resultCode,
    this.pan,
    this.currency,
    this.records,
    this.transactions = const [],
  });

  final String? result;
  final String? resultCode;
  final String? pan;
  final String? currency;
  final int? records;
  final List<GoCardStatementTransaction> transactions;

  factory GoCardStatementData.fromJson(Map<String, dynamic> json) {
    final rows = json['data'] ?? json['transactions'];
    return GoCardStatementData(
      result: json['result']?.toString(),
      resultCode: json['resultcode']?.toString(),
      pan: json['pan']?.toString(),
      currency: json['currency']?.toString(),
      records: json['records'] is num ? (json['records'] as num).toInt() : null,
      transactions: rows is List
          ? rows
                .whereType<Map>()
                .map(
                  (row) => GoCardStatementTransaction.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  List<WalletTransactionEntity> toEntities() {
    final code = currency?.trim().isNotEmpty == true ? currency!.trim() : 'TZS';
    return transactions
        .map((transaction) => transaction.toEntity(currency: code))
        .whereType<WalletTransactionEntity>()
        .toList(growable: false);
  }
}

class GoCardStatementTransaction {
  GoCardStatementTransaction({
    this.date,
    this.type,
    this.amount,
    this.reference,
    this.transId,
    this.merchant,
    this.comment,
    this.utilityCode,
  });

  final String? date;
  final String? type;
  final String? amount;
  final String? reference;
  final String? transId;
  final String? merchant;
  final String? comment;
  final String? utilityCode;

  factory GoCardStatementTransaction.fromJson(Map<String, dynamic> json) {
    return GoCardStatementTransaction(
      date: json['fulltimestamp']?.toString() ?? json['date']?.toString(),
      type: json['transtype']?.toString() ?? json['type']?.toString(),
      amount: json['amount']?.toString(),
      reference: json['reference']?.toString(),
      transId: json['transid']?.toString(),
      merchant: json['merchant']?.toString(),
      comment: json['comment']?.toString(),
      utilityCode: json['utilitycode']?.toString(),
    );
  }

  WalletTransactionEntity? toEntity({required String currency}) {
    final parsedDate = _parseStatementDate(date);
    if (parsedDate == null) return null;

    final normalizedType = (type ?? '').trim().toUpperCase();
    final isCredit = normalizedType == 'CREDIT';
    final merchantLabel = merchant?.trim();
    final utilityLabel = utilityCode?.trim();
    final commentLabel = comment?.trim().isNotEmpty == true
        ? comment!.trim()
        : utilityLabel;
    final parsedAmount = double.tryParse((amount ?? '').trim()) ?? 0;

    final merchantName = isCredit
        ? (commentLabel?.isNotEmpty == true
              ? commentLabel!
              : (merchantLabel?.isNotEmpty == true ? merchantLabel! : 'Credit'))
        : (merchantLabel?.isNotEmpty == true
              ? merchantLabel!
              : (commentLabel?.isNotEmpty == true ? commentLabel! : 'Debit'));

    final categoryLabel = isCredit
        ? (commentLabel?.isNotEmpty == true
              ? 'Credit - $commentLabel'
              : 'Credit')
        : (merchantLabel?.isNotEmpty == true
              ? 'Debit - $merchantLabel'
              : (commentLabel?.isNotEmpty == true
                    ? 'Debit - $commentLabel'
                    : 'Debit'));

    final id = transId?.trim().isNotEmpty == true
        ? transId!.trim()
        : reference?.trim().isNotEmpty == true
        ? reference!.trim()
        : '${date}_${normalizedType}_$parsedAmount';

    return WalletTransactionEntity(
      id: id,
      merchantName: merchantName,
      categoryLabel: categoryLabel,
      amount: parsedAmount,
      isCredit: isCredit,
      createdAt: parsedDate,
      currency: currency,
    );
  }

  static DateTime? _parseStatementDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }
}
