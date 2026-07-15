import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Derives a 32-byte AES key from [password] via SHA-256.
///
/// Does not use platform secure storage — the same password must be supplied
/// every time the box is opened.
List<int> hiveEncryptionKeyFromPassword(String password) {
  return sha256.convert(utf8.encode(password)).bytes;
}

/// Opens (or returns) a Hive box encrypted with [HiveAesCipher].
///
/// The cipher key is SHA-256([password]). Callers must pass the same password
/// on every open. Prefer this helper over raw [Hive.openBox] for any box that
/// should be encrypted at rest.
///
/// If an existing on-disk box cannot be opened with this cipher (e.g. legacy
/// unencrypted data), the stale box is removed and a fresh encrypted box is
/// created.
Future<Box<E>> openSecureBox<E>(
  String name, {
  required String password,
}) async {
  if (Hive.isBoxOpen(name)) {
    return Hive.box<E>(name);
  }

  final cipher = HiveAesCipher(hiveEncryptionKeyFromPassword(password));

  try {
    return await Hive.openBox<E>(name, encryptionCipher: cipher);
  } catch (_) {
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox<E>(name, encryptionCipher: cipher);
  }
}
