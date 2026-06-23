import 'package:get/get.dart';

import '../data/countries_phone_data.dart';

class PhoneCountryPickerController extends GetxController {
  PhoneCountryPickerController({this.selected});

  final CountryData? selected;
  final searchQuery = ''.obs;

  List<CountryData> get filteredCountries {
    final q = searchQuery.value.trim().toLowerCase();
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    if (q.isEmpty) return Countries.all;

    return Countries.all.where((country) {
      final dialNorm = country.dialCode.replaceAll('+', '');
      return country.name.toLowerCase().contains(q) ||
          country.dialCode.toLowerCase().contains(q) ||
          (qDigits.isNotEmpty && dialNorm.contains(qDigits)) ||
          country.code.toLowerCase().contains(q);
    }).toList();
  }

  void updateSearch(String value) {
    searchQuery.value = value;
  }
}
