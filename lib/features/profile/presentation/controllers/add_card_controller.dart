import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';

class AddCardController extends GetxController {
  final WalletRepository _walletRepository;

  AddCardController({
    WalletRepository? walletRepository,
  }) : _walletRepository = walletRepository ?? sl<WalletRepository>();

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
  final selectedCountry = Rxn<CountryData>();
  final selectedState = RxnString();

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

  void selectCountry(CountryData country) {
    if (selectedCountry.value?.code != country.code) {
      selectedCountry.value = country;
      selectedState.value = null; // Clear selected state on country change
      stateError.value = null;
    }
    countryError.value = null;
    onFieldChanged();
  }

  void selectState(String state) {
    selectedState.value = state;
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
    String mobileNumber = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (mobileNumber.startsWith('0')) {
      mobileNumber = mobileNumber.substring(1);
    }
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final city = cityController.text.trim();
    final state = selectedState.value;
    final country = selectedCountry.value?.code;

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
          // Extract session data map
          final sessionData = response.data;
          Map<String, dynamic> sessionMap = {};
          if (sessionData is Map<String, dynamic>) {
            sessionMap = sessionData;
          } else if (sessionData is List && sessionData.isNotEmpty) {
            final first = sessionData.first;
            if (first is Map) {
              sessionMap = Map<String, dynamic>.from(first);
            }
          }

          // Build hidden inputs dynamically from backend signature fields
          final StringBuffer formInputs = StringBuffer();
          sessionMap.forEach((key, value) {
            formInputs.write('<input type="hidden" name="$key" value="$value" />\n');
          });

          // Detect card brand
          String cardType = '001'; // Default: Visa
          if (cardNo.startsWith('4')) {
            cardType = '001'; // Visa
          } else if (cardNo.startsWith('5')) {
            cardType = '002'; // Mastercard
          } else if (cardNo.startsWith('3')) {
            cardType = '003'; // Amex
          }

          final parts = expiry.split('/');
          final month = parts.isNotEmpty ? parts[0] : '';
          final year = parts.length > 1 ? parts[1] : '';
          final fullYear = year.isNotEmpty ? '20$year' : '';
          final expiryDate = '$month-$fullYear'; // format MM-YYYY

          // Append user card inputs
          formInputs.write('<input type="hidden" name="card_number" value="$cardNo" />\n');
          formInputs.write('<input type="hidden" name="card_type" value="$cardType" />\n');
          formInputs.write('<input type="hidden" name="card_expiry_date" value="$expiryDate" />\n');
          formInputs.write('<input type="hidden" name="card_cvn" value="$cvv" />\n');

          final htmlData = '''
<html>
<body onload="document.forms[0].submit()">
  <form method="POST" action="https://secureacceptance.cybersource.com/silent/pay">
    $formInputs
  </form>
</body>
</html>
''';

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
    } else if (cardNumber.length != 16) {
      cardNumberError.value = 'Card Number must be 16 digits';
      isValid = false;
    }

    if (expiry.isEmpty) {
      expiryError.value = 'Expiry is required';
      isValid = false;
    } else if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      expiryError.value = 'Use MM/YY format';
      isValid = false;
    } else {
      final month = int.tryParse(expiry.substring(0, 2)) ?? 0;
      if (month < 1 || month > 12) {
        expiryError.value = 'Invalid month';
        isValid = false;
      }
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

    if (selectedCountry.value != null && selectedState.value == null) {
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
        phoneError.value = 'Invalid phone number for ${selectedPhoneCountry.value.name}';
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
    if (cardNumber.length != 16 || !RegExp(r'^\d{16}$').hasMatch(cardNumber)) {
      return false;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;
    final month = int.tryParse(expiry.substring(0, 2)) ?? 0;
    if (month < 1 || month > 12) return false;
    if (!RegExp(r'^\d{3}$').hasMatch(cvv)) return false;

    if (selectedCountry.value == null) return false;
    if (selectedState.value == null) return false;
    if (phone.isEmpty) return false;
    
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final phoneIso = selectedPhoneCountry.value.code;
    if (!PhoneNationalRules.isCompleteValidNational(phoneIso, phoneDigits)) {
      return false;
    }

    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return false;
    }
    if (address.isEmpty) return false;
    if (city.isEmpty) return false;

    return true;
  }
}
