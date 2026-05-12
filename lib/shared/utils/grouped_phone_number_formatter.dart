import 'package:flutter/services.dart';

/// Same approach as `duka_direct_4_flutter` / [PhoneNumberFormatter]: inserts spaces
/// between digit groups using [format], e.g. `[3, 3, 3]` → `712 345 678`.
class GroupedPhoneNumberFormatter extends TextInputFormatter {
  GroupedPhoneNumberFormatter({required this.format});

  final List<int> format;

  /// National-style grouping for hints / API helpers (digits only in, spaced out).
  static String formatDigits(String digitsOnly, List<int> format) {
    final text = digitsOnly.replaceAll(RegExp(r'\D'), '');
    if (text.isEmpty || format.isEmpty) return text;
    if (text.length <= format[0]) return text;

    final buffer = StringBuffer();
    var digitIndex = 0;
    var formatIndex = 0;

    while (digitIndex < text.length && formatIndex < format.length) {
      final groupSize = format[formatIndex];
      final endIndex = digitIndex + groupSize;

      for (var i = digitIndex; i < endIndex && i < text.length; i++) {
        buffer.write(text[i]);
      }

      digitIndex = endIndex;
      formatIndex++;

      if (digitIndex < text.length && formatIndex < format.length) {
        buffer.write(' ');
      }
    }

    while (digitIndex < text.length) {
      buffer.write(text[digitIndex]);
      digitIndex++;
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = formatDigits(digitsOnly, format);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
