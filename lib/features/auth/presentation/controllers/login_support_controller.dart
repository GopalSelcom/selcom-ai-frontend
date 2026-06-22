import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/app_reason_picker_bottom_sheet.dart';
import '../../data/models/support_models.dart';
import '../../domain/repositories/support_repository.dart';

class LoginSupportController extends GetxController {
  LoginSupportController({required this.supportRepository});

  final SupportRepository supportRepository;

  static const _loginReasonValues = {
    'forgot_email',
    'forgot_password',
    'account_recovery',
    'login_issue',
    'app_bug',
    'other',
  };

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final reasons = <SupportReasonModel>[].obs;
  final selectedReasonLabel = ''.obs;
  final selectedReasonValue = ''.obs;
  final selectedCountryIso = 'TZ'.obs;
  final phoneFieldResetVersion = 0.obs;
  final canSubmit = false.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final messageController = TextEditingController();

  String get reasonDisplayText => selectedReasonValue.value.isEmpty
      ? AppStrings.selectAReason.tr
      : selectedReasonLabel.value;

  CountryData get selectedCountry =>
      Countries.findByIsoCode(selectedCountryIso.value);

  @override
  void onInit() {
    super.onInit();
    fetchReasons();
    nameController.addListener(_updateCanSubmit);
    emailController.addListener(_updateCanSubmit);
    phoneController.addListener(_updateCanSubmit);
    messageController.addListener(_updateCanSubmit);
  }

  Future<void> fetchReasons() async {
    isLoading.value = true;

    final result = await supportRepository.getSupportReasons();

    result.fold(
      (failure) => AppDialogs.showErrorDialog(message: failure.message),
      (data) {
        final filtered = data.reasons
            .where((r) => _loginReasonValues.contains(r.value))
            .toList(growable: false);
        reasons.assignAll(
          filtered.isNotEmpty ? filtered : data.reasons,
        );
      },
    );

    isLoading.value = false;
  }

  void onPhoneCountrySelected(CountryData country) {
    if (country.code == selectedCountryIso.value) return;
    selectedCountryIso.value = country.code;
    phoneController.clear();
    phoneFieldResetVersion.value++;
    _updateCanSubmit();
  }

  void setSelectedReason(SupportReasonModel reason) {
    selectedReasonLabel.value = reason.label;
    selectedReasonValue.value = reason.value;
    _updateCanSubmit();
  }

  void openReasonPicker() {
    AppReasonPickerBottomSheet.show(
      content: Obx(() {
        return AppReasonPickerBottomSheet(
          options: [
            for (final reason in reasons)
              AppReasonPickerOption(
                label: reason.label,
                value: reason.value,
              ),
          ],
          selectedValue: selectedReasonValue.value,
          onSelected: (option) {
            final reason = reasons.firstWhere((r) => r.value == option.value);
            setSelectedReason(reason);
          },
        );
      }),
    );
  }

  void onFieldChanged(String _) => _updateCanSubmit();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  String? _resolvedContactEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) return null;
    return _emailRegex.hasMatch(email) ? email : null;
  }

  String? _resolvedContactPhone() {
    return PhoneNationalRules.e164DigitsOrNull(
      selectedCountryIso.value,
      phoneController.text,
    );
  }

  bool _hasInvalidEmail() {
    final email = emailController.text.trim();
    return email.isNotEmpty && !_emailRegex.hasMatch(email);
  }

  bool _hasInvalidPhone() {
    final raw = phoneController.text.trim();
    return raw.isNotEmpty && _resolvedContactPhone() == null;
  }

  bool _hasValidContact() {
    return _resolvedContactEmail() != null || _resolvedContactPhone() != null;
  }

  Future<void> submitTicket() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.nameIsRequired.tr);
      return;
    }

    if (_hasInvalidEmail()) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterAValidEmail.tr);
      return;
    }

    if (_hasInvalidPhone()) {
      AppDialogs.showErrorDialog(
        message: AppStrings.pleaseEnterAValidPhoneNumber.tr,
      );
      return;
    }

    if (!_hasValidContact()) {
      AppDialogs.showErrorDialog(
        message: AppStrings.pleaseProvideEmailOrPhone.tr,
      );
      return;
    }

    if (selectedReasonValue.value.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseSelectAReason.tr);
      return;
    }

    if (messageController.text.trim().isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterAMessage.tr);
      return;
    }

    if (isSubmitting.value) return;

    await Loader.withFlag(isSubmitting, () async {
      final result = await supportRepository.createSupportTicket(
        CreateSupportTicketRequestModel(
          reason: selectedReasonValue.value,
          description: messageController.text.trim(),
          contactEmail: _resolvedContactEmail() ?? '',
          contactPhone: _resolvedContactPhone() ?? '',
          contactName: name,
        ),
      );

      result.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (success) {
          var message = success.message;
          if (success.ticketNumber != null &&
              success.ticketNumber!.isNotEmpty) {
            message = message.isEmpty
                ? success.ticketNumber!
                : '$message\n${success.ticketNumber}';
          }
          Get.back<void>();
          AppDialogs.showSuccessDialog(
            message: message.isNotEmpty
                ? message
                : AppStrings.contactSupport.tr,
          );
        },
      );
    });
  }

  void _updateCanSubmit() {
    final hasName = nameController.text.trim().isNotEmpty;
    final hasReason = selectedReasonValue.value.isNotEmpty;
    final hasMessage = messageController.text.trim().isNotEmpty;
    canSubmit.value =
        hasName &&
        _hasValidContact() &&
        !_hasInvalidEmail() &&
        !_hasInvalidPhone() &&
        hasReason &&
        hasMessage;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
