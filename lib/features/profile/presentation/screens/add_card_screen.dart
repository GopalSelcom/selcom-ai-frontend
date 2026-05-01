import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/add_card_controller.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  late final AddCardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddCardController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.addNewCard.tr, onBack: Get.back),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => AppTextField(
                              label: 'Full Name',
                              hintText: AppStrings.eGJohnDoe.tr,
                              controller: controller.cardHolderController,
                              focusNode: controller.fullNameFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => controller.focusCardNumber(),
                              onChanged: (_) => controller.onFieldChanged(),
                              errorText: controller.fullNameError.value,
                              fontSize: 15.h,
                              fontWeight: FontWeight.w500,
                              textFieldBackgroundColor: AppColors.pageBackground,
                              textColor: AppColors.textHeading,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Obx(
                            () => AppTextField(
                              label: 'Card Number',
                              hintText: AppStrings.value0000000000000000.tr,
                              controller: controller.cardNumberController,
                              focusNode: controller.cardNumberFocus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => controller.focusExpiry(),
                              onChanged: (_) => controller.onFieldChanged(),
                              errorText: controller.cardNumberError.value,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                                _CardNumberFormatter(),
                              ],
                              fontSize: 15.h,
                              fontWeight: FontWeight.w500,
                              textFieldBackgroundColor: AppColors.pageBackground,
                              textColor: AppColors.textHeading,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: Obx(
                                  () => AppTextField(
                                    label: 'Expiry',
                                    hintText: AppStrings.mmYy.tr,
                                    controller: controller.expiryController,
                                    focusNode: controller.expiryFocus,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => controller.focusCvv(),
                                    onChanged: (_) =>
                                        controller.onFieldChanged(),
                                    errorText: controller.expiryError.value,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                      _CardExpiryFormatter(),
                                    ],
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    textFieldBackgroundColor: AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Obx(
                                  () => AppTextField(
                                    label: 'CVV',
                                    hintText: AppStrings.eG123.tr,
                                    controller: controller.cvvController,
                                    focusNode: controller.cvvFocus,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => controller.submitCard(),
                                    onChanged: (_) =>
                                        controller.onFieldChanged(),
                                    errorText: controller.cvvError.value,
                                    isPassword: controller.isCvvHidden.value,
                                    suffixIcon: IconButton(
                                      onPressed: controller.toggleCvvVisibility,
                                      icon: Icon(
                                        controller.isCvvHidden.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textBody.withValues(
                                          alpha: 0.7,
                                        ),
                                        size: 20.w,
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    fontSize: 15.h,
                                    fontWeight: FontWeight.w500,
                                    textFieldBackgroundColor: AppColors.pageBackground,
                                    textColor: AppColors.textHeading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => AppPrimaryButton(
                      label: 'Add Card',
                      iconAsset: AppAssets.locationIcArrowRight,
                      isLoading: controller.isSubmitting.value,
                      onPressed: controller.isSubmitting.value
                          ? null
                          : controller.submitCard,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 < digits.length) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }

    final month = digits.substring(0, 2);
    final year = digits.substring(2);
    final formatted = '$month/$year';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
