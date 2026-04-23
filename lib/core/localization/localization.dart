import 'package:flutter/material.dart';

import 'package:selcom_rides_frontend/core/services/storage_service.dart';
import 'package:selcom_rides_frontend/main.dart';

class Localization {
  static Localization? _instance;

  Localization._internal();

  static Localization get instance {
    _instance ??= Localization._internal();
    return _instance!;
  }

  Locale? currentLanguage;

  Future<Locale> setLocale(String languageCode) async {
    await StorageService().write(StorageKeys.preferredLanguage, languageCode);
    return _locale(languageCode);
  }

  Future<Locale> getLocale() async {
    final preferredLanguage = await StorageService().read(
      StorageKeys.preferredLanguage,
    );
    return _locale(preferredLanguage ?? 'en');
  }

  Locale _locale(String languageCode) {
    if (languageCode.isNotEmpty) {
      return Locale(languageCode, '');
    }
    return const Locale('en', '');
  }

  Future<void> changeLanguage(
    BuildContext context,
    String selectedLanguageCode,
  ) async {
    final locale = await setLocale(selectedLanguageCode);
    if (context.mounted) {
      MyApp.setLocale(context, locale);
    }
  }
}
