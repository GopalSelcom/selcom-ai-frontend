/// Tanzania registration display: **`T 123 ABC`** (letter / 3 digits / 3 letters).
class TanzaniaLicensePlateFormatter {
  TanzaniaLicensePlateFormatter._();

  /// Normalizes API values like `T123ABC`, `T12 3ABC`, `t 123 abc` to **`T 123 ABC`**.
  /// Unknown shapes fall back to [raw] trimmed.
  static String formatDisplay(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final compact = trimmed.replaceAll(RegExp(r'[\s\-]+'), '').toUpperCase();

    final tDigitsLetters = RegExp(r'^T(\d{3})([A-Z]{3})$');
    var m = tDigitsLetters.firstMatch(compact);
    if (m != null) {
      return 'T ${m[1]} ${m[2]}';
    }

    final letterDigitsLetters = RegExp(r'^([A-Z])(\d{3})([A-Z]{3})$');
    m = letterDigitsLetters.firstMatch(compact);
    if (m != null) {
      return '${m[1]} ${m[2]} ${m[3]}';
    }

    final digitsLettersNoT = RegExp(r'^(\d{3})([A-Z]{3})$');
    m = digitsLettersNoT.firstMatch(compact);
    if (m != null) {
      return 'T ${m[1]} ${m[2]}';
    }

    return trimmed;
  }
}
