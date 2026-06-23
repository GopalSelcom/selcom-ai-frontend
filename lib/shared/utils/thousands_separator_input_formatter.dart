import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input with thousands separators (e.g. `5000` → `5,000`).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) {
      return oldValue;
    }

    final formatted = _formatter.format(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String formatDigits(String digits) {
    final parsed = int.tryParse(digits.replaceAll(RegExp(r'\D'), ''));
    if (parsed == null) return '';
    return _formatter.format(parsed);
  }
}
