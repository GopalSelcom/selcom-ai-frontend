import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/payment_card.dart';
import '../controllers/card_details_controller.dart';
import '../widgets/payment_card_action_bottom_sheet.dart';

class CardDetailsScreen extends StatefulWidget {
  final PaymentCard card;

  const CardDetailsScreen({
    super.key,
    required this.card,
  });

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
    controller = Get.put(
      CardDetailsController(
        card: widget.card,
      ),
    );
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
    Get.bottomSheet(
      Obx(
        () => PaymentCardActionBottomSheet(
          title: 'Are you sure want to add\nDelete this card?',
          description:
              'This action will remove the card from your account, and you will need to add it again if you want to use it in the future.',
          cardNumber: widget.card.fullNumber,
          imageAssetPath: AppAssets.imgPaymentDeleteCardConfirm,
          primaryButtonLabel: 'No, Cancel',
          onPrimaryPressed: Get.back,
          secondaryButtonLabel: 'Delete Card',
          onSecondaryPressed: () async {
            final isDeleted = await controller.deleteCard();
            if (!isDeleted) return;
            if (Get.isBottomSheetOpen ?? false) {
              Get.back();
            }
            Get.back();
          },
          isSecondaryLoading: controller.isDeleteLoading.value,
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const AppProfileHeader(title: 'Card Detail'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F7),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE6E9EE)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'VISA',
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: const Color(0xFF0057A0),
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 34.sp * 0.55,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.card.fullNumber,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.shade1,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Expiry',
                          controller: _expiryController,
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Obx(
                          () => AppTextField(
                            label: 'CVV',
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
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  AppTextField(
                    label: 'Set a Nick name',
                    controller: _nickNameController,
                    readOnly: true,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
            child: SizedBox(
              height: 56.h,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openDeleteConfirmationSheet,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Delete card',
                  style: AppTextStyles.button.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
