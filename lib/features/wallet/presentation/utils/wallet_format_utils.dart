import 'package:flutter/material.dart';

import '../../../../shared/utils/currency_formatter.dart';

/// Formats wallet account numbers in spaced groups (v4-style).
String formatWalletAccountNumber(String account, {int groupSize = 5}) {
  final clean = account.replaceAll(RegExp(r'\s+'), '');
  if (clean.isEmpty) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < clean.length; i++) {
    if (i > 0 && i % groupSize == 0) buffer.write(' ');
    buffer.write(clean[i]);
  }
  return buffer.toString();
}

/// Signed amount label for transaction rows (e.g. `-TZS 116`).
String formatWalletTransactionAmount({
  required double amount,
  required bool isCredit,
  required String currency,
}) {
  final sign = isCredit ? '+' : '-';
  final formatted = CurrencyFormatter.formatWithApiCurrency(
    amount.abs(),
    currency,
  );
  return '$sign$formatted';
}

/// Matches duka_direct_4_flutter [getFractionFromHeight] (safe area + offset).
double sheetFractionFromHeight(BuildContext context, double heightPx) {
  final mediaQuery = MediaQuery.of(context);
  final height = mediaQuery.size.height;
  final topPadding = mediaQuery.padding.top;
  final bottomPadding = mediaQuery.padding.bottom;
  final safeHeight = height - topPadding - bottomPadding;
  if (safeHeight <= 0) return 0.45;
  return (heightPx / safeHeight).clamp(0.0, 1.0) - 0.018;
}
