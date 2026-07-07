import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/saved_cards_controller.dart';

class SavedCardsBottomSheet extends GetView<SavedCardsController> {
  const SavedCardsBottomSheet({super.key});

  static Future<void> show() {
    if (!Get.isRegistered<SavedCardsController>()) {
      Get.put(sl<SavedCardsController>());
    }
    final controller = Get.find<SavedCardsController>();
    controller.resetState();
    unawaited(controller.loadCards());

    return AppDialogs.showStandardBottomSheet<void>(
      sheet: const SavedCardsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SavedCardsController>();
    return Obx(() {
      final step = controller.step.value;
      return AppStandardBottomSheet(
        title: step == SavedCardsStep.cardList
            ? AppStrings.savedCardLabel.tr
            : AppStrings.addMoneyToWallet.tr,
        headerTextAlign: TextAlign.center,
        showHeaderDivider: true,
        content: _buildContent(controller),
        footer: _buildFooter(controller),
      );
    });
  }

  Widget _buildContent(SavedCardsController controller) {
    if (controller.isSubmitting.value) {
      return SizedBox(
        height: 150.h,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final step = controller.step.value;
    if (step == SavedCardsStep.cardList) {
      if (controller.isLoading.value) {
        return SizedBox(
          height: 150.h,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final apiError = controller.apiError.value;
      if (apiError != null) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              apiError,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
          ),
        );
      }

      final cards = controller.cards;
      if (cards.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 36.h),
          child: Center(
            child: Text(
              AppStrings.noSavedCardsFound.tr,
              style: AppTextStyles.body.copyWith(color: AppColors.textBody),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final card = cards[index];
          final bool isVisa = card.maskedCard.startsWith('4');
          final bool isMastercard = card.maskedCard.startsWith('5');
          final String brandText = isVisa ? 'VISA' : (isMastercard ? 'MC' : 'CARD');
          final String label = card.maskedCard.replaceAll(RegExp(r'[xX]'), '*');

          return InkWell(
            onTap: () => controller.selectCard(card),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Text(
                    brandText,
                    style: TextStyle(
                      color: isVisa
                          ? AppColors.textBrandVisaSecondary
                          : AppColors.brandRed,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.homeSubtitle.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14.sp,
                    color: AppColors.textBody,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Amount Entry Step
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.amount.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textMutedStrong,
            ),
          ),
          SizedBox(height: 4.h),
          AppTextField(
            readOnly: false,
            hintText: '5,000',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: controller.amountController,
            errorText: controller.amountError.value,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: Center(
                widthFactor: 1,
                child: Text(
                  AppStrings.defaultCurrencyTzs.tr,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 16.sp,
                    height: 22 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            textColor: AppColors.success,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: 24.h),
        ],
      );
    }
  }

  Widget? _buildFooter(SavedCardsController controller) {
    if (controller.isSubmitting.value) return null;

    final step = controller.step.value;
    if (step == SavedCardsStep.cardList) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: TextButton(
            onPressed: controller.onAddCardPressed,
            child: Text(
              AppStrings.addNewCardText.tr,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.back.tr,
              onPressed: controller.backToCardList,
              outlined: true,
              backgroundColor: AppColors.white,
              outlinedTextColor: AppColors.black,
              outlinedBorderColor: AppColors.black,
              outlinedBorderWidth: 1,
              borderRadius: 16.r,
              height: 56.h,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.continueLabel.tr,
              onPressed: controller.submitTopUp,
              borderRadius: 16.r,
              height: 56.h,
            ),
          ),
        ],
      );
    }
  }
}
