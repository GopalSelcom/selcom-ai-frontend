import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../payment/presentation/controllers/saved_cards_controller.dart';
import '../../../wallet/data/models/go_wallet_card_model.dart';
import '../controllers/payment_methods_controller.dart';
import '../widgets/payment_card_action_bottom_sheet.dart';
import 'add_card_screen.dart';

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
                final isVisa = card.maskedCard?.startsWith('4') ?? false;
                final bool isMastercard = card.maskedCard?.startsWith('5') ?? false;
                final brand = isVisa ? 'VISA' : (isMastercard ? 'MC' : 'CARD');
                final label = (card.maskedCard ?? '').replaceAll(RegExp(r'[xX]'), '*');

                return _buildCardTile(
                  icon: Icons.credit_card,
                  brand: brand,
                  number: label,
                  onTap: () {
                    // Open details screen or simply show info
                  },
                  onDelete: () => _openDeleteConfirmationSheet(card, savedCardsController),
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

  void _openDeleteConfirmationSheet(Datum card, SavedCardsController savedCardsController) {
    final label = (card.maskedCard ?? '').replaceAll(RegExp(r'[xX]'), '*');
    AppDialogs.showAnimatedBottomSheet(
      barrierDismissible: true,
      child: PaymentCardActionBottomSheet(
        title: AppStrings.areYouSureWantToAddNdeleteThisCard.tr,
        description: AppStrings.cardDeleteWarningDescription.tr,
        cardNumber: label,
        imageAssetPath: AppAssets.imgPaymentDeleteCardConfirm,
        primaryButtonLabel: AppStrings.noCancel.tr,
        onPrimaryPressed: AppDialogs.closeActiveDialog,
        secondaryButtonLabel: AppStrings.deleteCard.tr,
        onSecondaryPressed: () async {
          if (card.id == null) return;
          AppDialogs.closeActiveDialog();
          Loader.instance.show();
          final result = await savedCardsController.deleteCard(card.id!);
          await Loader.instance.hideAsync();

          result.fold(
            (failure) => AppDialogs.showErrorDialog(message: failure.message),
            (statusMsg) => AppDialogs.showSuccessDialog(
              message: statusMsg.message ?? "Card deleted successfully",
            ),
          );
        },
        isSecondaryDanger: true,
      ),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String brand,
    String? name,
    required String number,
    String? status,
    required VoidCallback onTap,
    required VoidCallback onDelete,
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
                GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Iconsax.trash,
                      size: 20.w,
                      color: AppColors.error,
                    ),
                  ),
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
      onTap: () async {
        final success = await Get.to<bool>(
          () => const AddCardScreen(),
          arguments: {'amount': 0},
        );
        if (success == true) {
          await controller.loadCards();
        }
      },
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
}
