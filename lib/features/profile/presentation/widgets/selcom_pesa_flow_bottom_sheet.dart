import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/payment_methods_controller.dart';

/// Phone-number entry for Selcom Pesa link (`POST send_link_request`).
///
/// Shown from [PaymentMethodsController.linkSelcomPesa]; on dismiss calls
/// [PaymentMethodsController.stopLinkFlow]. See `docs/flows/selcom-pesa-link-flow.md`.
class SelcomPesaFlowBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaFlowBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      sheet: const SelcomPesaFlowBottomSheet(),
      barrierDismissible: true,
    ).whenComplete(() {
      if (Get.isRegistered<PaymentMethodsController>()) {
        Get.find<PaymentMethodsController>().stopLinkFlow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStandardBottomSheet(
      title: AppStrings.enterYourSelcomPesaNumber.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      maxHeightFactor: 0.92,
      content: _buildPhoneInputStep(context),
    );
  }

  Widget _buildPhoneInputStep(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppStrings.enterPhoneNumber.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textMutedStrong,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Obx(
          () => AppTextField(
            controller: controller.selcomPhoneController,
            keyboardType: TextInputType.phone,
            autofocus: false,
            textFieldBackgroundColor: AppColors.pageBackground,
            borderColor: AppColors.borderWalletCard,
            errorText: controller.phoneError.value.isEmpty
                ? null
                : controller.phoneError.value,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TanzaniaPhoneFormatter(),
            ],
            prefixIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Text(
                AppStrings.value255.tr,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            onChanged: controller.onSelcomPhoneChanged,
          ),
        ),
        SizedBox(height: 24.h),
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.vertical,
                child: child,
              ),
            ),
            child: controller.canContinueSelcomPhone.value
                ? AppPrimaryButton(
                    key: const ValueKey('selcom-pesa-continue-visible'),
                    label: AppStrings.continueLabel.tr,
                    isLoading: controller.isLinkRequestSubmitting.value,
                    onPressed: controller.isLinkRequestSubmitting.value
                        ? null
                        : controller.onPhoneContinue,
                  )
                : const SizedBox.shrink(
                    key: ValueKey('selcom-pesa-continue-hidden'),
                  ),
          ),
        ),
      ],
    );
  }
}
