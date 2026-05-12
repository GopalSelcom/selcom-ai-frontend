import 'package:get/get.dart';

/// Copy helpers for saved-place confirmation UI (grammar-aware).
class SavedPlaceConfirmationCopy {
  SavedPlaceConfirmationCopy._();

  /// For templates like "… as @phrase?" — English uses **a/an** + label; other
  /// locales receive the raw label until translations embed grammar differently.
  static String phraseAsIndefiniteNoun(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return trimmed;
    final code = Get.locale?.languageCode ?? 'en';
    if (code != 'en') return trimmed;
    final first = trimmed.substring(0, 1).toLowerCase();
    const vowels = {'a', 'e', 'i', 'o', 'u'};
    final article = vowels.contains(first) ? 'an' : 'a';
    return '$article $trimmed';
  }
}
