import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';

enum PaymentStatus { pending, success }

class PaymentStatusDialog extends StatelessWidget {
  final PaymentStatus status;
  final int? secondsRemaining;

  const PaymentStatusDialog({
    super.key,
    required this.status,
    this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = status == PaymentStatus.pending;

    final Color bgColor = isPending
        ? AppColors.bgPaymentRequest
        : AppColors.bgPaymentSuccess;
    final Color iconColor = isPending
        ? AppColors.iconPaymentRequest
        : AppColors.iconPaymentSuccess;
    final String asset = isPending ? AppAssets.icRequest : AppAssets.icSuccess;
    final String title = isPending
        ? AppStrings
            .requestSentPleaseCompletePaymentOnSelcomPesaToBookYourRide
            .tr
        : AppStrings.paymentCompletedSuccessfully.tr;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 132.h,
              width: double.infinity,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: _PaymentHeaderShapeClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28.r),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.05),
                    child: SvgPictureAsset(
                      asset,
                      width: 75.w,
                      height: 75.w,
                      color: iconColor,
                      placeholderBuilder: (_) => Icon(
                        isPending
                            ? Icons.access_time_filled
                            : Icons.check_circle,
                        color: iconColor,
                        size: 75.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.homeTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPaymentDialogMessage,
                  height: 26 / 20,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            if (isPending && secondsRemaining != null)
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Text(
                  AppStrings.expiresInTimer.trParams({
                    'timer': _formatTimer(secondsRemaining!),
                  }),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeSubtitle.copyWith(height: 20 / 15),
                ),
              )
            else
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
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString();
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PaymentHeaderShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final dipTopY = size.height - 22;
    final dipBottomY = size.height - 6;
    final half = size.width / 2;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, dipTopY)
      ..quadraticBezierTo(size.width * 0.75, dipTopY, half, dipBottomY)
      ..quadraticBezierTo(size.width * 0.25, dipTopY, 0, dipTopY)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
