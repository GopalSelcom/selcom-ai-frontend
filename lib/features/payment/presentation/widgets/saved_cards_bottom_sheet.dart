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
import 'package:iconsax/iconsax.dart';
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
      return _buildCardsSection(controller);
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

  Widget _buildCardsSection(SavedCardsController controller) {
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
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 19.h, 10.w, 0.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cards.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  AppStrings.noSavedCardsFound.tr,
                  style: AppTextStyles.body.copyWith(color: AppColors.textBody),
                ),
              ),
            )
          else
            ...List.generate(cards.length, (index) {
              final card = cards[index];
              final bool isVisa = card.maskedCard?.startsWith('4') ?? false;
              final bool isMastercard = card.maskedCard?.startsWith('5') ?? false;
              final String brand = isVisa ? 'VISA' : (isMastercard ? 'MC' : 'CARD');
              final String label = (card.maskedCard ?? '').replaceAll(RegExp(r'[xX]'), '*');

              return _buildCardTile(
                brand: brand,
                number: label,
                onTap: () => controller.selectCard(card),
                showDivider: true,
              );
            }),
          const Divider(color: AppColors.borderWalletCard, height: 1),
          _buildAddCardTile(controller),
        ],
      ),
    );
  }

  Widget _buildCardTile({
    required String brand,
    required String number,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final isVisa = brand == 'VISA';
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h, left: 8.w, right: 2.w),
            child: Row(
              children: [
                Text(
                  brand,
                  style: TextStyle(
                    color: isVisa
                        ? AppColors.textBrandVisaSecondary
                        : AppColors.brandRed,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  number,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHeading,
                  ),
                ),
                const Spacer(),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 20.w,
                  color: AppColors.textBody.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          if (showDivider) ...[
            const Divider(color: AppColors.borderWalletCard, height: 1),
            SizedBox(height: 18.h),
          ],
        ],
      ),
    );
  }

  Widget _buildAddCardTile(SavedCardsController controller) {
    return InkWell(
      onTap: controller.onAddCardPressed,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h, top: 14.h, left: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 24.w),
            SizedBox(width: 4.w),
            Text(
              AppStrings.addDebitCreditCard.tr,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                height: 20 / 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFooter(SavedCardsController controller) {
    if (controller.isSubmitting.value) return null;

    final step = controller.step.value;
    if (step == SavedCardsStep.cardList) {
      return null;
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
