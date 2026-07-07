import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../payment/presentation/controllers/saved_cards_controller.dart';
import '../controllers/payment_methods_controller.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.put(sl<PaymentMethodsController>());
    final savedCardsController = Get.put(sl<SavedCardsController>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.refreshPaymentMethodsState());
      unawaited(savedCardsController.loadCards());
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentMethodsController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProfileHeader(title: AppStrings.savedCardLabel.tr),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment methods section
                // _buildSectionTitle(AppStrings.paymentMethodsTitle.tr),
                SizedBox(height: 8.h),
                // Obx(() => _buildSelcomPesaCard(controller)),
                // SizedBox(height: 14.h),
                // Cards section
                _buildSectionTitle(AppStrings.cards.tr),
                SizedBox(height: 8.h),
                _buildCardsSection(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle.copyWith(
        color: AppColors.textBody,
        fontWeight: FontWeight.w500,
        fontSize: 15.sp,
        height: 20 / 15,
      ),
    );
  }

  Widget _buildSelcomPesaCard(PaymentMethodsController controller) {
    bool isLinked = controller.isSelcomPesaLinked.value;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: controller.openSelcomPesaToWallet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.selcomPesa.tr,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                    height: 20 / 15,
                  ),
                ),
                if (isLinked) ...[
                  SizedBox(width: 7.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textVerified,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      AppStrings.defaultLabel.tr,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isLinked) ...[
                  const Spacer(),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 20.w,
                    color: AppColors.textBody.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              controller.selcomPesaSummarySubtitle,
              style: isLinked
                  ? AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textBody,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                    )
                  : AppTextStyles.caption.copyWith(
                      color: AppColors.textBody,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      height: 20 / 12,
                    ),
            ),
            if (!isLinked) ...[
              SizedBox(height: 5.h),
              Text(
                AppStrings.linkAccount.tr,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15.sp,
                  height: 20 / 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection(PaymentMethodsController controller) {
    final savedCardsController = Get.find<SavedCardsController>();
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 19.h, 10.w, 0.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Obx(() {
        if (savedCardsController.isLoading.value) {
          return SizedBox(
            height: 100.h,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final cards = savedCardsController.cards;
        return Column(
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
                final isVisa = card.maskedCard.startsWith('4');
                final isMastercard = card.maskedCard.startsWith('5');
                final brand = isVisa ? 'VISA' : (isMastercard ? 'MC' : 'CARD');
                final label = card.maskedCard.replaceAll(RegExp(r'[xX]'), '*');

                return _buildCardTile(
                  icon: Icons.credit_card,
                  brand: brand,
                  number: label,
                  onTap: () {
                    // Open details screen or simply show info
                  },
                  showDivider: index < cards.length - 1,
                );
              }),
            const Divider(color: AppColors.borderWalletCard, height: 1),
            _buildAddCardTile(savedCardsController),
          ],
        );
      }),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String brand,
    String? name,
    required String number,
    String? status,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h, left: 8.w, right: 2.w),
            child: Row(
              children: [
                // Visa Logo placeholder
                Text(
                  brand,
                  style: TextStyle(
                    color: AppColors.textBrandVisaSecondary,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                if (name != null) ...[
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: status == AppStrings.cardExpired.tr
                          ? AppColors.textBody
                          : AppColors.textHeading,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  number,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15.h,
                    fontWeight: FontWeight.w500,
                    color: status == AppStrings.cardExpired.tr
                        ? AppColors.textBody
                        : AppColors.textHeading,
                  ),
                ),
                if (status != null) ...[
                  SizedBox(width: 8.w),
                  Text(
                    status,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: status == AppStrings.cardExpired.tr
                          ? AppColors.textBody
                          : AppColors.textHeading,
                    ),
                  ),
                ],
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
      onTap: () => _showAmountPrompt(controller),
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
                fontSize: 15.h,
                fontWeight: FontWeight.w500,
                height: 20 / 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAmountPrompt(SavedCardsController controller) {
    final TextEditingController localAmountController = TextEditingController(text: '100');
    final RxString error = ''.obs;

    AppDialogs.showStandardBottomSheet<void>(
      sheet: AppStandardBottomSheet(
        title: AppStrings.addMoneyToWallet.tr,
        headerTextAlign: TextAlign.center,
        showHeaderDivider: true,
        content: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Enter amount to top up and link card (Minimum TZS 100)",
                style: AppTextStyles.homeSubtitle.copyWith(color: AppColors.textMutedStrong),
              ),
              SizedBox(height: 8.h),
              Obx(() => AppTextField(
                hintText: '100',
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                textFieldBackgroundColor: AppColors.surfaceSubtle,
                borderColor: AppColors.borderWalletCard,
                controller: localAmountController,
                errorText: error.value.isEmpty ? null : error.value,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 8.w),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      AppStrings.defaultCurrencyTzs.tr,
                      style: AppTextStyles.homeTitle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                ),
                textColor: AppColors.success,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              )),
              SizedBox(height: 24.h),
              AppPrimaryButton(
                label: AppStrings.continueLabel.tr,
                onPressed: () async {
                  final text = localAmountController.text.replaceAll(RegExp(r'\D'), '');
                  final val = int.tryParse(text);
                  if (val == null || val < 100) {
                    error.value = "Minimum top-up is TZS 100";
                    return;
                  }
                  Get.back<void>(); // close amount prompt sheet
                  await controller.startNewCardLinkFlow(amount: val);
                },
                borderRadius: 16.r,
                height: 56.h,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
