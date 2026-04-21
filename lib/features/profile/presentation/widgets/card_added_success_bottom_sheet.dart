import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class CardAddedSuccessBottomSheet extends StatelessWidget {
  const CardAddedSuccessBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 28.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your card has been added successfully.',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.shade1,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'VISA',
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: const Color(0xFF0057A0),
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 28.sp * 0.6,
                            ),
                          ),
                          TextSpan(
                            text: ' 1232 1231 5453 5333',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.shade1,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 86.w,
                height: 86.w,
                child: Image.asset(
                  AppAssets.imgPaymentAddCardSuccess,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'Now ready to use for payments. You can manage or remove this card anytime from your payment settings.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.shade2,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28.h),
          AppPrimaryButton(
            label: 'Okay',
            trailingIcon: Iconsax.arrow_right_3,
            onPressed: Get.back,
          ),
        ],
      ),
    );
  }
}
