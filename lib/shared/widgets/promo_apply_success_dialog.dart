import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Lightweight success overlay after a promo validates; auto-closes after 3s.
class PromoApplySuccessDialog extends StatefulWidget {
  const PromoApplySuccessDialog({super.key});

  @override
  State<PromoApplySuccessDialog> createState() =>
      _PromoApplySuccessDialogState();
}

class _PromoApplySuccessDialogState extends State<PromoApplySuccessDialog> {
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _autoClose = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (Get.isDialogOpen ?? false) {
        Get.back<void>();
      }
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 260.w,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48.sp,
              ),
              SizedBox(height: 14.h),
              Text(
                AppStrings.promoApplySuccessMessage.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeSubtitle.copyWith(
                  color: AppColors.textHeading,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
