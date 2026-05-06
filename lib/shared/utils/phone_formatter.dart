import 'package:flutter/services.dart';

class TanzaniaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // We expect text to be digits only due to FilteringTextInputFormatter.digitsOnly
    final formatted = formatString(text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String formatString(String number) {
    if (number.isEmpty) return '';
    final digits = number.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 2 || i == 5) && i != digits.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static String formatInternational(String number) {
    if (number.isEmpty) return '';
    String clean = number.replaceAll(RegExp(r'[\s+]'), '');
    if (clean.startsWith('255')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return '+255 ${formatString(clean)}';
  }
}
