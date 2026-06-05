import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/models/user_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../data/models/activate_wallet_request.dart';
import '../../domain/repositories/active_wallet_repository.dart';
import '../models/registration/client_success_model.dart';

class ActiveWalletFormController extends GetxController {
  ActiveWalletFormController({required ActiveWalletRepository activeWalletRepository})
    : _activeWalletRepository = activeWalletRepository;

  final ActiveWalletRepository _activeWalletRepository;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();

  final RxBool isSubmitEnabled = false.obs;
  final RxBool isSubmitting = false.obs;

  static final RegExp _dobPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _phonePattern = RegExp(r'^\d{9,15}$');
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void onInit() {
    super.onInit();
    _attachFieldListeners();
    _prefillFromUserProfile();
  }

  void _attachFieldListeners() {
    for (final controller in [
      nameController,
      dobController,
      phoneController,
      emailController,
      address1Controller,
      address2Controller,
    ]) {
      controller.addListener(_refreshSubmitEnabled);
    }
    _refreshSubmitEnabled();
  }

  Future<void> _prefillFromUserProfile() async {
    final rawUser = await StorageService().read(StorageKeys.user);
    if (rawUser == null || rawUser.isEmpty) return;

    final user = UserModel.fromJson(jsonDecode(rawUser));
    final fullName = (user.name ?? '').trim();
    if (fullName.isNotEmpty) {
      nameController.text = fullName;
    }

    final mobile = user.mobileNumber?.toString().replaceAll(RegExp(r'\D'), '') ??
        '';
    if (mobile.isNotEmpty) {
      phoneController.text = mobile;
    }

    final email = user.emailId?.trim() ?? '';
    if (email.isNotEmpty) {
      emailController.text = email;
    }

    final dob = user.dob?.trim() ?? '';
    if (dob.isNotEmpty) {
      final parsed = DateTime.tryParse(dob);
      if (parsed != null) {
        dobController.text = DateFormat('yyyy-MM-dd').format(parsed);
      } else if (_dobPattern.hasMatch(dob)) {
        dobController.text = dob;
      }
    }

    _refreshSubmitEnabled();
  }

  void _refreshSubmitEnabled() {
    isSubmitEnabled.value = _isFormValid(silent: true);
  }

  bool _isFormValid({bool silent = false}) {
    final name = nameController.text.trim();
    if (name.isEmpty || name.length > 120) {
      if (!silent) _showValidationError(AppStrings.nameIsRequired.tr);
      return false;
    }

    final dob = dobController.text.trim();
    if (!_dobPattern.hasMatch(dob)) {
      if (!silent) {
        _showValidationError(AppStrings.walletLinkDateOfBirth.tr);
      }
      return false;
    }

    final phone = _normalizedPhone();
    if (phone.isEmpty) {
      if (!silent) {
        _showValidationError(AppStrings.pleaseEnterYourPhoneNumber.tr);
      }
      return false;
    }
    if (!_phonePattern.hasMatch(phone)) {
      if (!silent) {
        _showValidationError(AppStrings.pleaseEnterAValidPhoneNumber.tr);
      }
      return false;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
      if (!silent) {
        _showValidationError(AppStrings.pleaseEnterAValidEmail.tr);
      }
      return false;
    }

    final address1 = address1Controller.text.trim();
    if (address1.isEmpty || address1.length > 120) {
      if (!silent) {
        _showValidationError(AppStrings.walletActiveAddress1.tr);
      }
      return false;
    }

    final address2 = address2Controller.text.trim();
    if (address2.isEmpty || address2.length > 120) {
      if (!silent) {
        _showValidationError(AppStrings.walletActiveAddress2.tr);
      }
      return false;
    }

    return true;
  }

  String _normalizedPhone() {
    return phoneController.text.replaceAll(RegExp(r'\D'), '');
  }

  void _showValidationError(String message) {
    AppDialogs.showErrorDialog(message: message);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> openDateOfBirthPicker() async {
    final maxDate = _dateOnly(DateTime.now());
    var pickedDate = dobController.text.isNotEmpty
        ? DateTime.tryParse(dobController.text) ?? maxDate
        : maxDate;
    pickedDate = _dateOnly(pickedDate);
    if (pickedDate.isAfter(maxDate)) {
      pickedDate = maxDate;
    }

    await Get.dialog<void>(
      Dialog(
        backgroundColor: AppColors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Brightness.light,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(
                color: AppColors.textHeading,
                fontSize: 18.sp,
              ),
            ),
          ),
          child: SizedBox(
            height: 280.h,
            child: Column(
              children: [
                SizedBox(
                  height: 220.h,
                  child: CupertinoDatePicker(
                    backgroundColor: AppColors.white,
                    mode: CupertinoDatePickerMode.date,
                    minimumYear: 1950,
                    initialDateTime: pickedDate,
                    maximumDate: maxDate,
                    dateOrder: DatePickerDateOrder.ymd,
                    onDateTimeChanged: (DateTime value) => pickedDate = value,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    dobController.text = DateFormat(
                      'yyyy-MM-dd',
                    ).format(pickedDate);
                    Get.back();
                  },
                  child: Text(
                    AppStrings.done.tr,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.walletColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    if (!_isFormValid()) return;
    if (isSubmitting.value) return;

    isSubmitting.value = true;
    Loader.instance.show();

    try {
      final response = await _activeWalletRepository.activateWallet(
        ActivateWalletRequest(
          name: nameController.text.trim(),
          dob: dobController.text.trim(),
          phone: _normalizedPhone(),
          email: emailController.text.trim(),
          address1: address1Controller.text.trim(),
          address2: address2Controller.text.trim(),
        ),
      );

      Loader.instance.hide();
      isSubmitting.value = false;

      if (_isActivationSuccess(response)) {
        AppDialogs.showSuccessDialog(
          message: response?.response?.message ??
              response?.message ??
              AppStrings.verificationSuccessful.tr,
          onConfirm: () => Get.back(result: true),
        );
        return;
      }

      AppDialogs.showErrorDialog(message: _activationErrorMessage(response));
    } catch (_) {
      Loader.instance.hide();
      isSubmitting.value = false;
      AppDialogs.showErrorDialog(
        message: AppStrings.anUnexpectedErrorOccurred.tr,
      );
    }
  }

  bool _isActivationSuccess(ClientSuccessModel? response) {
    if (response == null) return false;

    final topLevelStatus = response.statusCode;
    if (topLevelStatus != null && topLevelStatus != 200) return false;

    return response.response?.resultcode == '200';
  }

  String _activationErrorMessage(ClientSuccessModel? response) {
    final topLevelMessage = response?.message?.trim();
    if (topLevelMessage != null && topLevelMessage.isNotEmpty) {
      return topLevelMessage;
    }

    final nestedMessage = response?.response?.message?.trim();
    if (nestedMessage != null && nestedMessage.isNotEmpty) {
      return nestedMessage;
    }

    return AppStrings.anUnexpectedErrorOccurred.tr;
  }

  @override
  void onClose() {
    nameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    emailController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    super.onClose();
  }
}
