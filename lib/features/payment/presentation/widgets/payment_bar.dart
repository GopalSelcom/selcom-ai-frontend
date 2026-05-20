import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/payment_method_controller.dart';
import './payment_method_bottom_sheet.dart';
import '../../../../shared/utils/app_dialogs.dart';

class PaymentBar extends StatelessWidget {
  final String buttonLabel;
  final VoidCallback onActionButtonPressed;
  final RxBool? isLoading;

  const PaymentBar({
    super.key,
    required this.buttonLabel,
    required this.onActionButtonPressed,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PaymentMethodController>();

    return Obx(() {
      final pay = controller.selectedPayment.value;
      final loading = isLoading?.value ?? false;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(25.w, 18.h, 25.w, 18.h),
        decoration: const BoxDecoration(color: AppColors.primary),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openPaymentSheet(context),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              AppStrings.payUsing.tr,
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.white,
                                fontSize: 14.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          SvgPictureAsset(
                            AppAssets.icPaymentArrowUp,
                            color: AppColors.white,
                            width: 14.w,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        pay?.label ?? AppStrings.selectPayment.tr,
                        style: AppTextStyles.homeCaption.copyWith(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pay?.type == 'card')
                        Text(
                          AppStrings
                              .cardEndingInPlaceholder
                              .tr, // Mock descriptive text from Figma
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.white,
                            fontSize: 11.sp,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(24.r),
                onTap: loading ? null : onActionButtonPressed,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 22.h,
                  ),
                  child: loading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          buttonLabel,
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                            fontSize: 15.sp,
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _openPaymentSheet(BuildContext context) {
    AppDialogs.showAnimatedBottomSheet(
      child: const PaymentMethodBottomSheet(),
      barrierDismissible: true,
    );
  }
}
