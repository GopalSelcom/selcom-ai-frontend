import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/grouped_phone_number_formatter.dart';
import '../../../../shared/utils/phone_contact_import.dart';
import '../../../../shared/utils/phone_national_rules.dart';

enum BookingMode { self, other }

enum BookingFlowStep { choice, details }

class BookingForSomeoneElseFlowController extends GetxController {
  BookingForSomeoneElseFlowController({
    BookingFlowStep initialStep = BookingFlowStep.choice,
    this.showSelfOption = true,
    this.showOtherOption = true,
  }) : currentStep = initialStep.obs;

  /// When false, choice step hides "For me" (active self ride case).
  final bool showSelfOption;

  /// When false, choice step hides "For someone else".
  final bool showOtherOption;
  final Rx<BookingFlowStep> currentStep;
  final nameError = RxnString();
  final phoneError = RxnString();
  final selectedCountry = Rx<CountryData>(Countries.findByIsoCode('TZ'));
  final phoneFieldKey = 0.obs;
  final canConfirm = false.obs;

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  TextEditingController? _nameController;
  TextEditingController? _phoneController;

  String? get sheetTitle {
    switch (currentStep.value) {
      case BookingFlowStep.choice:
        return AppStrings.bookingForSomeoneElsePrompt.tr;
      case BookingFlowStep.details:
        return AppStrings.passengerDetailsTitle.tr;
    }
  }

  String? get sheetSubtitle {
    switch (currentStep.value) {
      case BookingFlowStep.choice:
        return AppStrings.bookingForSomeoneElseSubtitle.tr;
      case BookingFlowStep.details:
        return AppStrings.notificationPhoneSubtitle.tr;
    }
  }

  void bindDetailFields({
    required TextEditingController name,
    required TextEditingController phone,
  }) {
    _nameController = name;
    _phoneController = phone;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCanConfirm());
  }

  void unbindDetailFields() {
    _nameController = null;
    _phoneController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      canConfirm.value = false;
    });
  }

  void goToDetailsStep() {
    currentStep.value = BookingFlowStep.details;
  }

  void confirmSelfBooking() {
    Get.back<Map<String, dynamic>>(result: {'mode': BookingMode.self});
  }

  void onFieldsChanged() {
    nameError.value = null;
    phoneError.value = null;
    _refreshCanConfirm();
  }

  void onCountrySelected(CountryData country) {
    if (selectedCountry.value.code == country.code) return;
    final phone = _phoneController;
    final existingDigits =
        phone?.text.replaceAll(RegExp(r'\D'), '') ?? '';
    selectedCountry.value = country;
    if (phone != null) {
      phone.text = existingDigits.isEmpty
          ? ''
          : GroupedPhoneNumberFormatter.formatDigits(
              existingDigits,
              country.format,
            );
    }
    phoneFieldKey.value++;
    phoneError.value = null;
    _refreshCanConfirm();
  }

  void _refreshCanConfirm() {
    if (_nameController == null || _phoneController == null) return;
    final name = _nameController!.text.trim();
    final phoneDigits =
        _phoneController!.text.replaceAll(RegExp(r'\D'), '');
    final next = name.isNotEmpty &&
        PhoneNationalRules.isCompleteValidNational(
          selectedCountry.value.code,
          phoneDigits,
        );
    if (canConfirm.value != next) {
      canConfirm.value = next;
    }
  }

  Future<void> pickContact() async {
    try {
      if (GetPlatform.isAndroid) {
        final status = await Permission.contacts.status;
        if (status.isPermanentlyDenied) {
          AppDialogs.showPermissionDialog(
            title: AppStrings.contactsPermission.tr,
            message: AppStrings.contactsAccessNeeded.tr,
            onOpenSettings: () => openAppSettings(),
            icon: Icons.contacts_outlined,
            secondaryIcon: Icons.contacts,
          );
          return;
        } else if (!status.isGranted) {
          final requestStatus = await Permission.contacts.request();
          if (!requestStatus.isGranted) {
            return;
          }
        }
      }

      final contact = await _contactPicker.selectContact();
      if (contact == null) return;

      final name = contact.fullName ?? '';
      final numbers = contact.phoneNumbers ?? [];
      if (numbers.isEmpty) {
        AppDialogs.showErrorDialog(
          message: 'No phone number found for this contact',
        );
        return;
      }

      final parsed = PhoneContactImport.parse(numbers.first);
      final nameController = _nameController;
      final phoneController = _phoneController;
      if (nameController == null || phoneController == null) return;

      if (name.isNotEmpty) {
        nameController.text = name;
      }
      selectedCountry.value = parsed.country ?? Countries.findByIsoCode('TZ');
      phoneController.text = parsed.formattedNational;
      if (parsed.country != null) {
        phoneFieldKey.value++;
      }
      nameError.value = null;
      phoneError.value = null;
      _refreshCanConfirm();
    } catch (e) {
      AppLogger.e('Error picking contact', tag: 'BookingForSomeoneElse', error: e);
    }
  }

  void onConfirmPressed() {
    final nameController = _nameController;
    final phoneController = _phoneController;
    if (nameController == null || phoneController == null) return;

    final trimmedName = nameController.text.trim();
    if (trimmedName.isEmpty) {
      nameError.value = AppStrings.nameIsRequired.tr;
      return;
    }

    final e164 = PhoneNationalRules.e164DigitsOrNull(
      selectedCountry.value.code,
      phoneController.text,
    );
    if (e164 == null) {
      phoneError.value = phoneController.text.trim().isEmpty
          ? AppStrings.notificationPhoneRequired.tr
          : AppStrings.pleaseEnterAValidPhoneNumber.tr;
      return;
    }

    Get.back<Map<String, dynamic>>(result: {
      'mode': BookingMode.other,
      'name': trimmedName,
      'phone': e164,
    });
  }
}
