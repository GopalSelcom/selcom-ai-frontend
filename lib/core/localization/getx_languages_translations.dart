import 'package:get/get.dart';

import 'languages/language_en.dart';
import 'languages/language_sw.dart';

class GetxLanguagesTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': LanguageEn().values,
    'sw': LanguageSw().values,
  };
}
