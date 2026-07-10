import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../data/models/country_response.dart';
import '../../data/models/state_model.dart';

class AddCardController extends GetxController {
  final WalletRepository _walletRepository;

  AddCardController({WalletRepository? walletRepository})
    : _walletRepository = walletRepository ?? sl<WalletRepository>();

  final cardHolderController = TextEditingController();
  final lastNameController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  // Billing address text controllers
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();

  final fullNameFocus = FocusNode();
  final lastNameFocus = FocusNode();
  final cardNumberFocus = FocusNode();
  final expiryFocus = FocusNode();
  final cvvFocus = FocusNode();

  // Billing address focus nodes
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final addressFocus = FocusNode();
  final cityFocus = FocusNode();

  final isCvvHidden = true.obs;
  final isSubmitting = false.obs;
  final canSubmitForm = false.obs;

  final fullNameError = RxnString();
  final lastNameError = RxnString();
  final cardNumberError = RxnString();
  final expiryError = RxnString();
  final cvvError = RxnString();

  // Country and State selection observers
  final selectedCountry = Rxn<CountriesResponse>();
  final selectedState = RxnString();
  final selectedStateResponse = Rxn<StateResponse>();

  final countriesList = <CountriesResponse>[].obs;
  final statesList = <StateResponse>[].obs;
  final isLoadingCountries = false.obs;
  final isLoadingStates = false.obs;
  final cachedStates = <String, List<StateResponse>>{}.obs;

  // Phone country selection and field reset version
  final selectedPhoneCountry = Countries.findByIsoCode('TZ').obs;
  final phoneFieldResetVersion = 0.obs;

  // Billing address errors
  final phoneError = RxnString();
  final emailError = RxnString();
  final addressError = RxnString();
  final cityError = RxnString();
  final countryError = RxnString();
  final stateError = RxnString();

  Future<void> fetchCountries() async {
    if (countriesList.isNotEmpty) return;
    isLoadingCountries.value = true;
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.common.countries,
          method: ApiMethod.post,
          body: {},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final countriesModel = CountriesModel.fromJson(data);
          countriesList.assignAll(countriesModel.response ?? []);
        }
      }
    } catch (e) {
      debugPrint("Error fetching countries: $e");
    } finally {
      isLoadingCountries.value = false;
    }
  }

  Future<void> fetchStates(String countryId) async {
    if (countryId.isEmpty) return;
    if (cachedStates.containsKey(countryId)) {
      statesList.assignAll(cachedStates[countryId]!);
      return;
    }
    isLoadingStates.value = true;
    statesList.clear();
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.common.stateByCountry,
          method: ApiMethod.post,
          body: {
            'country_id': countryId,
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final stateModel = SelectStateModel.fromJson(data);
          final fetchedList = stateModel.response ?? [];
          cachedStates[countryId] = fetchedList;
          statesList.assignAll(fetchedList);
        }
      }
    } catch (e) {
      debugPrint("Error fetching states: $e");
    } finally {
      isLoadingStates.value = false;
    }
  }

  @override
  void onClose() {
    cardHolderController.dispose();
    lastNameController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();

    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();

    fullNameFocus.dispose();
    lastNameFocus.dispose();
    cardNumberFocus.dispose();
    expiryFocus.dispose();
    cvvFocus.dispose();

    phoneFocus.dispose();
    emailFocus.dispose();
    addressFocus.dispose();
    cityFocus.dispose();

    super.onClose();
  }

  void toggleCvvVisibility() {
    isCvvHidden.value = !isCvvHidden.value;
  }

  void selectCountry(CountriesResponse country) {
    if (selectedCountry.value?.id != country.id) {
      selectedCountry.value = country;
      selectedState.value = null; // Clear selected state on country change
      selectedStateResponse.value = null;
      stateError.value = null;

      // Auto-update selected phone country based on phoneCode or iso2Code
      if (country.iso2Code != null && country.iso2Code!.isNotEmpty) {
        final phoneCountry = Countries.findByIsoCode(country.iso2Code);
        selectedPhoneCountry.value = phoneCountry;
        phoneController.clear();
        phoneFieldResetVersion.value++;
        phoneError.value = null;
      }
      
      // Fetch states for the new country
      fetchStates(country.id ?? '');
    }
    countryError.value = null;
    onFieldChanged();
  }

  void selectState(StateResponse state) {
    selectedStateResponse.value = state;
    selectedState.value = state.name;
    stateError.value = null;
    onFieldChanged();
  }

  void selectPhoneCountry(CountryData country) {
    if (selectedPhoneCountry.value.code != country.code) {
      selectedPhoneCountry.value = country;
      phoneController.clear();
      phoneFieldResetVersion.value++;
      phoneError.value = null;
      onFieldChanged();
    }
  }

  void onFieldChanged() {
    // Keep UX responsive by clearing stale field errors while typing.
    fullNameError.value = null;
    lastNameError.value = null;
    cardNumberError.value = null;
    expiryError.value = null;
    cvvError.value = null;

    phoneError.value = null;
    emailError.value = null;
    addressError.value = null;
    cityError.value = null;
    countryError.value = null;
    stateError.value = null;

    canSubmitForm.value = _isFormInputValidForVisibility();
  }

  void focusCardNumber() => cardNumberFocus.requestFocus();

  void focusExpiry() => expiryFocus.requestFocus();

  void focusCvv() => cvvFocus.requestFocus();

  Future<void> submitCard() async {
    if (isSubmitting.value) {
      return;
    }

    if (!_validateForm()) {
      canSubmitForm.value = _isFormInputValidForVisibility();
      return;
    }

    final args = Get.arguments as Map<String, dynamic>?;
    final int amount = args?['amount'] as int? ?? 100;

    final fname = cardHolderController.text.trim();
    final lname = lastNameController.text.trim();
    final cardNo = cardNumberController.text.replaceAll(' ', '');
    final cardBin = cardNo.length >= 6 ? cardNo.substring(0, 6) : '';
    final expiry = expiryController.text.trim();
    final cvv = cvvController.text.trim();

    final countryCode = selectedPhoneCountry.value.dialCode;
    String mobileNumber = phoneController.text.trim().replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (mobileNumber.startsWith('0')) {
      mobileNumber = mobileNumber.substring(1);
    }
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final city = cityController.text.trim();
    final state = selectedState.value;
    final country = selectedCountry.value?.iso2Code;

    await Loader.withFlag(isSubmitting, () async {
      final result = await _walletRepository.goInitCardSession(
        amount: amount,
        newCard: 0,
        email: email,
        mobileNumber: mobileNumber,
        countryCode: countryCode,
        cardBin: cardBin,
        fname: fname,
        lname: lname,
        address: address,
        city: city,
        state: state,
        country: country,
      );

      await result.fold(
        (failure) async {
          AppDialogs.showErrorDialog(message: failure.message);
        },
        (response) async {
          final String cardType = updateCardTypeImage(cardNo);

          final datum = response.data?.firstOrNull;
          if (datum == null) {
            AppDialogs.showErrorDialog(message: 'Invalid session response from server.');
            return;
          }

          final expiryParts = expiry.split('/');
          final expiryMonthRaw = expiryParts.isNotEmpty ? expiryParts[0] : '';
          final expiryMonth = expiryMonthRaw.padLeft(2, '0');
          final expiryYearRaw = expiryParts.length > 1 ? expiryParts[1] : '';
          final expiryYear = expiryYearRaw.length == 2 ? '20$expiryYearRaw' : expiryYearRaw;

          final htmlData = getHtmlCodes(
            cardNo,
            expiryMonth,
            expiryYear,
            cvv,
            cardType,
            datum.toJson(),
          );

          final success = await WebViewScreen.open<bool>(
            title: AppStrings.addNewCard.tr,
            htmlData: htmlData,
          );

          unawaited(WalletRefresh.afterBalanceChange());

          if (success == true) {
            AppDialogs.showSuccessDialog(
              message: AppStrings.yourCardHasBeenNaddedSuccessfully.tr,
              confirmLabel: AppStrings.ok,
              barrierDismissible: true,
            );
            Get.back<bool>(result: true);
          }
        },
      );
    });
    canSubmitForm.value = _isFormInputValidForVisibility();
  }

  String getHtmlCodes(
    String cardNumber,
    String expiryMonth,
    String expiryYear,
    String cvv,
    String cardType,
    Map<String, dynamic> sessionResponse,
  ) {
    String htmlCode = "";
    htmlCode = r'''
          <html>
            <body onload="document.f.submit();">
        ''';
    htmlCode +=
        "<form id=\"f\" name=\"f\" method=\"post\" action=\"${URLS.wallet.securepay}\">\n";
    sessionResponse.forEach((key, value) {
      htmlCode += "<input type=\"hidden\" name=\"$key\" value=\"$value\" />\n";
    });
    htmlCode +=
        "<input type=\"hidden\" name=\"${Params.CARD_NUMBER}\" value=\"$cardNumber\" />\n";
    htmlCode +=
        "<input type=\"hidden\" name=\"${Params.CARD_TYPE}\" value=\"$cardType\" />\n";
    htmlCode +=
        "<input type=\"hidden\" name=\"${Params.CARD_EXPIRY_DATE}\" value=\"$expiryMonth-$expiryYear\"/>\n";
    htmlCode +=
        "<input type=\"hidden\" name=\"${Params.CARD_CVN}\" value=\"$cvv\" />\n";
    htmlCode += r'''
              </form>
            </body>
          </html>
        ''';
    debugPrint("HTML Code == $htmlCode");
    return htmlCode;
  }

  String updateCardTypeImage(String cardNumber) {
    if (cardNumber.isNotEmpty) {
      CreditCardType type = detectCCType(cardNumber);
      if (type == CreditCardType.visa) {
        return CardType.VISA_CARD;
      } else if (type == CreditCardType.mastercard) {
        return CardType.MASTERCARD_CARD;
      } else if (type == CreditCardType.amex) {
        return CardType.AMEX_CARD;
      } else if (type == CreditCardType.unknown) {
        return "";
      } else {
        return "";
      }
    } else {
      return "";
    }
  }

  // This function determines the CC type based on the cardPatterns
  CreditCardType detectCCType(String ccNumStr) {
    CreditCardType cardType = CreditCardType.unknown;

    if (ccNumStr.isEmpty) {
      return cardType;
    }

    cardNumPatterns.forEach((CreditCardType type, Set<List<String>> patterns) {
      for (List<String> patternRange in patterns) {
        // Remove any spaces
        String ccPatternStr = ccNumStr.replaceAll(RegExp(r'\s+\b|\b\s'), '');
        int rangeLen = patternRange[0].length;
        // Trim the CC number str to match the pattern prefix length
        if (rangeLen < ccNumStr.length) {
          ccPatternStr = ccPatternStr.substring(0, rangeLen);
        }

        if (patternRange.length > 1) {
          // Convert the prefix range into numbers then make sure the
          // CC num is in the pattern range.
          // Because Strings don't have '>=' type operators
          int ccPrefixAsInt = int.parse(ccPatternStr);
          int startPatternPrefixAsInt = int.parse(patternRange[0]);
          int endPatternPrefixAsInt = int.parse(patternRange[1]);
          if (ccPrefixAsInt >= startPatternPrefixAsInt &&
              ccPrefixAsInt <= endPatternPrefixAsInt) {
            // Found a match
            cardType = type;
            break;
          }
        } else {
          // Just compare the single pattern prefix with the CC prefix
          if (ccPatternStr == patternRange[0]) {
            // Found a match
            cardType = type;
            break;
          }
        }
      }
    });

    return cardType;
  }

  bool validateCardNum(String input) {
    if (input.isEmpty) return false;
    final sanitized = input.replaceAll(RegExp(r'\D'), '');
    if (sanitized.length < 15) return false;

    int sum = 0;
    int length = sanitized.length;
    for (var i = 0; i < length; i++) {
      int digit = int.parse(sanitized[length - i - 1]);
      if (i % 2 == 1) {
        digit *= 2;
      }
      sum += digit > 9 ? (digit - 9) : digit;
    }
    return sum % 10 == 0;
  }

  bool validateExpiryDate(String value) {
    if (value.isEmpty || value.length < 5) return false;
    final parts = value.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]) ?? 0;
    final yearRaw = int.tryParse(parts[1]) ?? 0;

    if (month < 1 || month > 12) return false;

    final thisInstant = DateTime.now();
    final currentYear2Digit = thisInstant.year % 100;
    final currentMonth = thisInstant.month;

    if (yearRaw < currentYear2Digit) return false;
    if (yearRaw == currentYear2Digit && month < currentMonth) return false;

    return true;
  }

  bool _validateForm() {
    final firstName = cardHolderController.text.trim();
    final lastName = lastNameController.text.trim();
    final cardNumber = cardNumberController.text.replaceAll(' ', '');
    final expiry = expiryController.text.trim();
    final cvv = cvvController.text.trim();

    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final city = cityController.text.trim();

    fullNameError.value = null;
    lastNameError.value = null;
    cardNumberError.value = null;
    expiryError.value = null;
    cvvError.value = null;

    phoneError.value = null;
    emailError.value = null;
    addressError.value = null;
    cityError.value = null;
    countryError.value = null;
    stateError.value = null;

    bool isValid = true;

    if (firstName.isEmpty) {
      fullNameError.value = 'First Name is required';
      isValid = false;
    }

    if (lastName.isEmpty) {
      lastNameError.value = 'Last Name is required';
      isValid = false;
    }

    if (cardNumber.isEmpty) {
      cardNumberError.value = 'Card Number is required';
      isValid = false;
    } else if (!validateCardNum(cardNumber)) {
      cardNumberError.value = 'Enter a valid card number';
      isValid = false;
    }

    if (expiry.isEmpty) {
      expiryError.value = 'Expiry is required';
      isValid = false;
    } else if (!validateExpiryDate(expiry)) {
      expiryError.value = 'Enter a valid expiry date';
      isValid = false;
    }

    if (cvv.isEmpty) {
      cvvError.value = 'CVV is required';
      isValid = false;
    } else if (cvv.length != 3) {
      cvvError.value = 'CVV must be 3 digits';
      isValid = false;
    }

    if (selectedCountry.value == null) {
      countryError.value = 'Country is required';
      isValid = false;
    }

    if (selectedCountry.value != null &&
        statesList.isNotEmpty &&
        selectedStateResponse.value == null) {
      stateError.value = 'State is required';
      isValid = false;
    }

    if (phone.isEmpty) {
      phoneError.value = 'Phone Number is required';
      isValid = false;
    } else {
      final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
      final iso = selectedPhoneCountry.value.code;
      if (!PhoneNationalRules.isCompleteValidNational(iso, phoneDigits)) {
        phoneError.value =
            'Invalid phone number for ${selectedPhoneCountry.value.name}';
        isValid = false;
      }
    }

    if (email.isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      emailError.value = 'Enter a valid email';
      isValid = false;
    }

    if (address.isEmpty) {
      addressError.value = 'Address is required';
      isValid = false;
    }

    if (city.isEmpty) {
      cityError.value = 'City is required';
      isValid = false;
    }

    canSubmitForm.value = isValid;
    return isValid;
  }

  bool _isFormInputValidForVisibility() {
    final firstName = cardHolderController.text.trim();
    final lastName = lastNameController.text.trim();
    final cardNumber = cardNumberController.text.replaceAll(' ', '');
    final expiry = expiryController.text.trim();
    final cvv = cvvController.text.trim();

    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final city = cityController.text.trim();

    if (firstName.isEmpty) return false;
    if (lastName.isEmpty) return false;
    if (!validateCardNum(cardNumber)) return false;
    if (!validateExpiryDate(expiry)) return false;
    if (!RegExp(r'^\d{3}$').hasMatch(cvv)) return false;

    if (selectedCountry.value == null) return false;
    if (statesList.isNotEmpty && selectedStateResponse.value == null) {
      return false;
    }

    if (phone.isEmpty) return false;
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final phoneIso = selectedPhoneCountry.value.code;
    if (!PhoneNationalRules.isCompleteValidNational(phoneIso, phoneDigits)) {
      return false;
    }

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return false;
    }
    if (address.isEmpty) return false;
    if (city.isEmpty) return false;

    return true;
  }
}

enum CreditCardType { visa, amex, mastercard, unknown }

class CardType {
  static String VIRTUAL_CARD = "Virtual";
  static String PHYSICAL_CARD = "Physical";
  static String VISA_CARD = "001";
  static String MASTERCARD_CARD = "002";
  static String AMEX_CARD = "003";
}

const Map<CreditCardType, Set<List<String>>> cardNumPatterns = {
  CreditCardType.visa: {
    ['4'],
  },
  CreditCardType.amex: {
    ['34'],
    ['37'],
  },
  /*
  CreditCardType.discover: {
    ['6011'],
    ['622126', '622925'],
    ['644', '649'],
    ['65']
  },
*/
  CreditCardType.mastercard: {
    ['51', '55'],
    ['2221', '2229'],
    ['223', '229'],
    ['23', '26'],
    ['270', '271'],
    ['2720'],
  },
};
