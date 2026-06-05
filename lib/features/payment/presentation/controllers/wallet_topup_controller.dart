import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../wallet/domain/repositories/registration_repository.dart';
import '../../domain/models/wallet_other_payment_topup_request.dart';
import '../models/wallet_other_payment_topup_response.dart';

class WalletTopupController extends GetxController {
  static const String paymentModeMobileMoney = 'Mobile Money';

  final RxString phoneInput = ''.obs;
  final RxString amountInput = ''.obs;
  final RxnString phoneError = RxnString();
  final RxnString amountError = RxnString();
  final RxBool isSubmitting = false.obs;
  final RxString paymentMode = paymentModeMobileMoney.obs;

  void prepareForTopup({String? mode}) {
    phoneInput.value = '';
    amountInput.value = '';
    phoneError.value = null;
    amountError.value = null;
    paymentMode.value = mode ?? paymentModeMobileMoney;
  }

  void updatePhone(String value) {
    phoneInput.value = value;
    if (phoneError.value != null) {
      phoneError.value = null;
    }
  }

  void updateAmount(String value) {
    amountInput.value = value;
    if (amountError.value != null) {
      amountError.value = null;
    }
  }

  bool validateInputs() {
    final phone = phoneInput.value.replaceAll(RegExp(r'\s+'), '');
    final amount = amountInput.value.trim();

    if (phone.length < 9) {
      phoneError.value = AppStrings.enterPhoneNumber.tr;
      return false;
    }
    if (amount.isEmpty) {
      amountError.value = AppStrings.amount.tr;
      return false;
    }

    phoneError.value = null;
    amountError.value = null;
    return true;
  }

  int? _parseUssdPhoneNumber(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return null;

    if (digits.startsWith('0')) {
      digits = '255${digits.substring(1)}';
    } else if (!digits.startsWith('255')) {
      digits = '255$digits';
    }

    return int.tryParse(digits);
  }

  WalletOtherPaymentTopupRequest? buildRequest() {
    if (!validateInputs()) return null;

    final amount = int.tryParse(amountInput.value.trim());
    final phone = _parseUssdPhoneNumber(phoneInput.value);
    if (amount == null || amount <= 0 || phone == null) {
      amountError.value = AppStrings.amount.tr;
      return null;
    }

    return WalletOtherPaymentTopupRequest(
      totalPrice: amount,
      paymentMode: paymentMode.value,
      ussdPhoneNumber: phone,
      sqrAmount: 0,
    );
  }

  Future<WalletOtherPaymentTopupResponse?> submitTopup() async {
    final request = buildRequest();
    if (request == null) return null;

    isSubmitting.value = true;
    try {
      return await RegistrationRepository.walletOtherPaymentTopupAPI(
        request: request,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> submitTopupWithFeedback() async {
    final response = await submitTopup();
    if (response?.statusCode == 200) {
      return true;
    }

    final message = response?.message?.trim();
    if (message != null && message.isNotEmpty) {
      AppDialogs.showErrorDialog(message: message);
    } else {
      AppDialogs.showErrorDialog(
        message: AppStrings.somethingWentWrongPleaseTryAgain.tr,
      );
    }
    return false;
  }
}
