import 'package:flutter/services.dart';

/// Formats NIDA input as `########-#####-#####-##` (20 digits, 23 chars).
class NidaInputFormatter extends TextInputFormatter {
  static const _maxDigits = 20;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;
    final formatted = _format(clipped);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _format(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 8 || i == 13 || i == 18) b.write('-');
      b.write(digits[i]);
    }
    return b.toString();
  }
}

bool isValidNidaFormat(String value) => value.length == 23;
