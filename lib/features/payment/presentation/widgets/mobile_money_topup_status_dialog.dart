import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/payment_dialog_header_section.dart';

enum MobileMoneyTopupDialogType { request, success }

class MobileMoneyTopupStatusDialog extends StatelessWidget {
  const MobileMoneyTopupStatusDialog({
    super.key,
    required this.type,
    this.secondsListenable,
  });

  final MobileMoneyTopupDialogType type;
  final ValueListenable<int>? secondsListenable;

  @override
  Widget build(BuildContext context) {
    final bool isRequest = type == MobileMoneyTopupDialogType.request;
    final Color bgColor = isRequest
        ? AppColors.bgPaymentRequest
        : AppColors.bgPaymentSuccess;
    final Color iconColor = isRequest
        ? AppColors.iconPaymentRequest
        : AppColors.iconPaymentSuccess;
    final String iconAsset = isRequest
        ? AppAssets.icRequest
        : AppAssets.icSuccess;

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
            PaymentDialogHeaderSection(
              backgroundColor: bgColor,
              iconAsset: iconAsset,
              iconColor: iconColor,
              placeholderIcon: isRequest
                  ? Icons.access_time_filled
                  : Icons.check_circle,
            ),
            SizedBox(height: 18.h),
            Text(
              isRequest
                  ? AppStrings.topUpRequestSentTitle.tr
                  : AppStrings.walletFundsReceivedTitle.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                height: 26 / 20,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 3.h),
            Padding(
              padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 26.h),
              child: isRequest
                  ? (secondsListenable == null
                        ? Text(
                            AppStrings.expiresInWithTime.trParams({
                              'time': _formatTimer(120),
                            }),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.homeSubtitle,
                          )
                        : ValueListenableBuilder<int>(
                            valueListenable: secondsListenable!,
                            builder: (_, seconds, __) => Text(
                              AppStrings.expiresInWithTime.trParams({
                                'time': _formatTimer(seconds),
                              }),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.homeSubtitle,
                            ),
                          ))
                  : Text(
                      AppStrings.walletFundsReceivedSubtitle.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeSubtitle,
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
