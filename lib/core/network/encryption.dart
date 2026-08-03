import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-CBC encrypt (Base64). Used by dynamic certificate pinning.
String onlyAesEncryption({
  required String data,
  required String keyInString,
  required String ivInString,
}) {
  final key = enc.Key.fromUtf8(keyInString);
  final iv = enc.IV.fromUtf8(ivInString);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  return encrypter.encrypt(data, iv: iv).base64;
}

/// AES-256-CBC decrypt from Base64. Used by dynamic certificate pinning.
String aesDecrypt({
  required String data,
  required String keyInString,
  required String ivInString,
}) {
  final sanitized = data.replaceAll('"', '');
  final key = enc.Key.fromUtf8(keyInString);
  final iv = enc.IV.fromUtf8(ivInString);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  return encrypter.decrypt64(sanitized, iv: iv);
}
