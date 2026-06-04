import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../bindings/wallet_biometric_intro_binding.dart';
import '../bindings/wallet_passport_scan_binding.dart';
import '../screens/wallet_biometric_intro_screen.dart';
import '../screens/wallet_passport_scan_method_screen.dart';
import '../wallet_link_flow_data.dart';

/// NIDA / passport identity capture for wallet linking (selcom_auth flow parity).
class WalletEnterNidaController extends GetxController {
  final nidaNumberController = TextEditingController();
  final passportNumberController = TextEditingController();
  final passportDobController = TextEditingController();
  final passportExpiryController = TextEditingController();

  final nidaFocusNode = FocusNode();
  final passportFocusNode = FocusNode();

  final isNidaSelected = true.obs;
  final isButtonEnabled = false.obs;

  final passportDateOfBirth = ''.obs;
  final passportDateOfExpiry = ''.obs;

  final nidaNumber = ''.obs;
  final passportNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    nidaNumberController.addListener(_onNidaChanged);
    passportNumberController.addListener(_onPassportNumberChanged);
  }

  @override
  void onClose() {
    nidaFocusNode.dispose();
    passportFocusNode.dispose();
    nidaNumberController.dispose();
    passportNumberController.dispose();
    passportDobController.dispose();
    passportExpiryController.dispose();
    super.onClose();
  }

  void _onNidaChanged() {
    nidaNumber.value = nidaNumberController.text;
  }

  void _onPassportNumberChanged() {
    passportNumber.value =
        passportNumberController.text.replaceAll(' ', '');
  }

  void selectNida() {
    isNidaSelected.value = true;
  }

  void selectPassport() {
    isNidaSelected.value = false;
  }

  void onNidaFieldChanged() {
    passportNumberController.clear();
    passportDobController.clear();
    passportExpiryController.clear();
    passportDateOfBirth.value = '';
    passportDateOfExpiry.value = '';
    isNidaSelected.value = true;
    validateFields();
  }

  void onPassportNumberChanged() {
    nidaNumberController.clear();
    isNidaSelected.value = false;
    validateFields();
  }

  void onPassportDobChanged() {
    nidaNumberController.clear();
    isNidaSelected.value = false;
    validateFields();
  }

  void setPassportDateOfBirth(DateTime date) {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    passportDobController.text = formatted;
    passportDateOfBirth.value = formatted;
    nidaNumberController.clear();
    isNidaSelected.value = false;
    validateFields();
  }

  void setPassportExpiry(DateTime date) {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    passportExpiryController.text = formatted;
    passportDateOfExpiry.value = formatted;
    nidaNumberController.clear();
    isNidaSelected.value = false;
    validateFields();
  }

  void validateFields() {
    if (isNidaSelected.value && nidaNumberController.text.length == 23) {
      isButtonEnabled.value = true;
      return;
    }
    if (!isNidaSelected.value &&
        passportNumberController.text.length >= 8 &&
        passportDobController.text.isNotEmpty &&
        passportExpiryController.text.isNotEmpty) {
      isButtonEnabled.value = true;
      return;
    }
    isButtonEnabled.value = false;
  }

  void unfocusAll() {
    nidaFocusNode.unfocus();
    passportFocusNode.unfocus();
  }

  WalletLinkFlowData get _flow => Get.find<WalletLinkFlowData>();

  /// Mirrors selcom_auth [LoginController.verifyNidaOrPassport] navigation (API stubbed).
  Future<void> submitVerification() async {
    unfocusAll();
    if (!isButtonEnabled.value) return;

    _flow.resetRouteStack();
    _flow.isNidaSelected = isNidaSelected.value;
    if (isNidaSelected.value) {
      _flow.nidaNumber = nidaNumberController.text.trim();
      _flow.passportNumber = '';
      _flow.passportDateOfBirth = '';
      _flow.passportDateOfExpiry = '';
    } else {
      _flow.nidaNumber = '';
      _flow.passportNumber =
          passportNumberController.text.replaceAll(' ', '').trim();
      _flow.passportDateOfBirth = passportDobController.text.trim();
      _flow.passportDateOfExpiry = passportExpiryController.text.trim();
    }

    // TODO(wallet-link): verifyNidaNew / wallet identity API.
    if (isNidaSelected.value) {
      await Get.to(
        () => const WalletBiometricIntroScreen(),
        binding: WalletBiometricIntroBinding(),
      );
    } else {
      await Get.to(
        () => const WalletPassportScanMethodScreen(),
        binding: WalletPassportScanBinding(),
      );
    }
    _flow.recordRoutePush();
  }
}
