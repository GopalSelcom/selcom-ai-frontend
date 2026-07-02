/// Tanzanian national number for Selcom Pesa when country code is sent
/// separately. Strips `+255` / `255` / trunk `0` so `711410410` is sent as-is.
String normalizeTzMobileForSelcomPesa(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  if (digits.startsWith('255') && digits.length > 9) {
    digits = digits.substring(3);
  }
  if (digits.startsWith('0') && digits.length >= 10) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Canonical 9-digit NSN for comparing user input with API values that may
/// return either `711410410` or `0711410410`.
String canonicalTzMobileDigits(String raw) => normalizeTzMobileForSelcomPesa(raw);
