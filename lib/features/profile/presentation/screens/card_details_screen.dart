import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/payment_card.dart';
import '../controllers/card_details_controller.dart';
import '../widgets/payment_card_action_bottom_sheet.dart';
import '../../../../shared/utils/app_dialogs.dart';

class CardDetailsScreen extends StatefulWidget {
  final PaymentCard card;

  const CardDetailsScreen({super.key, required this.card});

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  late final TextEditingController _nickNameController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;
  late final CardDetailsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CardDetailsController(card: widget.card));
    _nickNameController = TextEditingController(text: widget.card.nickName);
    _expiryController = TextEditingController(text: widget.card.expiry);
    _cvvController = TextEditingController(text: widget.card.cvv);
  }

  @override
  void dispose() {
    _nickNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    Get.delete<CardDetailsController>();
    super.dispose();
  }

  void _openDeleteConfirmationSheet() {
    AppDialogs.showAnimatedBottomSheet(
      barrierDismissible: true,
      child: Obx(
        () => PaymentCardActionBottomSheet(
          title: AppStrings.areYouSureWantToAddNdeleteThisCard.tr,
          description:
              AppStrings.cardDeleteWarningDescription.tr,
          cardNumber: widget.card.fullNumber,
          imageAssetPath: AppAssets.imgPaymentDeleteCardConfirm,
          primaryButtonLabel: AppStrings.noCancel.tr,
          onPrimaryPressed: AppDialogs.closeActiveDialog,
          secondaryButtonLabel: AppStrings.deleteCard.tr,
          onSecondaryPressed: () async {
            final isDeleted = await controller.deleteCard();
            if (!isDeleted) return;
            AppDialogs.closeActiveDialog();
            Get.back();
          },
          isSecondaryLoading: controller.isDeleteLoading.value,
          isSecondaryDanger: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS ? 0 : 8.h)
        : 24.h;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(title: AppStrings.cardDetail.tr),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderWalletCard),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppStrings.visa.tr,
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.textBrandVisaPrimary,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 34.sp * 0.55,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.card.fullNumber,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textHeading,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.expiry.tr,
                          controller: _expiryController,
                          readOnly: true,
                          textFieldBackgroundColor: AppColors.surfaceSubtle,
                          textColor: AppColors.textHeading,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Obx(
                          () => AppTextField(
                            label: AppStrings.cvv.tr,
                            controller: _cvvController,
                            readOnly: true,
                            isPassword: controller.isCvvHidden.value,
                            suffixIcon: IconButton(
                              onPressed: controller.toggleCvvVisibility,
                              icon: Icon(
                                controller.isCvvHidden.value
                                    ? Iconsax.eye_slash
                                    : Iconsax.eye,
                                color: AppColors.primary,
                                size: 18.w,
                              ),
                            ),
                            textFieldBackgroundColor: AppColors.surfaceSubtle,
                            textColor: AppColors.textHeading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  AppTextField(
                    label: AppStrings.setANickName.tr,
                    controller: _nickNameController,
                    readOnly: true,
                    textFieldBackgroundColor: AppColors.surfaceSubtle,
                    textColor: AppColors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(height: 24.h),

                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, computedBottomPadding),
              child: AppPrimaryButton(
                label: AppStrings.deleteCard.tr,
                onPressed: _openDeleteConfirmationSheet,
                height: 56.h,
                borderRadius: 16.r,
                outlined: true,
                backgroundColor: AppColors.white,
                textColor: AppColors.error,
                outlinedTextColor: AppColors.error,
                outlinedBorderColor: AppColors.error,
                outlinedBorderWidth: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
