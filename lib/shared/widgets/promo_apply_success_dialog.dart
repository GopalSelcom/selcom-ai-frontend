import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/payment_dialog_header_section.dart';

/// In-screen promo success card (promo flow overlay — not a [Dialog] route).
class PromoApplySuccessPanel extends StatelessWidget {
  const PromoApplySuccessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PaymentSuccessDialogHeader(),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
            child: Text(
              AppStrings.promoApplySuccessMessage.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPaymentDialogMessage,
                height: 26 / 20,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 20.h),
            child: Text(
              AppStrings.thankYouForRidingWithUsSeeYouOnTheNextTrip.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.textBody,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
