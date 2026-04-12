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
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      if ((i == 2 || i == 5) && i != number.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }
}
