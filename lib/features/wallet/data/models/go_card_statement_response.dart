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
    this.transactions = const [],
  });

  final String? result;
  final String? resultCode;
  final String? pan;
  final String? currency;
  final List<GoCardStatementTransaction> transactions;

  factory GoCardStatementData.fromJson(Map<String, dynamic> json) {
    final rows = json['transactions'];
    return GoCardStatementData(
      result: json['result']?.toString(),
      resultCode: json['resultcode']?.toString(),
      pan: json['pan']?.toString(),
      currency: json['currency']?.toString(),
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
    return transactions
        .map((transaction) => transaction.toEntity())
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
    this.merchant,
    this.comment,
  });

  final String? date;
  final String? type;
  final String? amount;
  final String? reference;
  final String? merchant;
  final String? comment;

  factory GoCardStatementTransaction.fromJson(Map<String, dynamic> json) {
    return GoCardStatementTransaction(
      date: json['date']?.toString(),
      type: json['type']?.toString(),
      amount: json['amount']?.toString(),
      reference: json['reference']?.toString(),
      merchant: json['merchant']?.toString(),
      comment: json['comment']?.toString(),
    );
  }

  WalletTransactionEntity? toEntity() {
    final parsedDate = DateTime.tryParse(date ?? '');
    if (parsedDate == null) return null;

    final normalizedType = (type ?? '').trim().toUpperCase();
    final isCredit = normalizedType == 'CREDIT';
    final merchantLabel = merchant?.trim();
    final commentLabel = comment?.trim();
    final parsedAmount = double.tryParse((amount ?? '').trim()) ?? 0;

    final merchantName = isCredit
        ? (commentLabel?.isNotEmpty == true
              ? commentLabel!
              : (merchantLabel?.isNotEmpty == true ? merchantLabel! : 'Credit'))
        : (merchantLabel?.isNotEmpty == true ? merchantLabel! : 'Debit');

    final categoryLabel = isCredit
        ? (commentLabel?.isNotEmpty == true
              ? 'Credit - $commentLabel'
              : 'Credit')
        : (merchantLabel?.isNotEmpty == true
              ? 'Debit - $merchantLabel'
              : 'Debit');

    final id =
        reference?.trim().isNotEmpty == true
            ? reference!.trim()
            : '${date}_${normalizedType}_$parsedAmount';

    return WalletTransactionEntity(
      id: id,
      merchantName: merchantName,
      categoryLabel: categoryLabel,
      amount: parsedAmount,
      isCredit: isCredit,
      createdAt: parsedDate,
    );
  }
}
