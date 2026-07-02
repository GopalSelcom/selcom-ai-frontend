import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/payment_dialog_header_section.dart';
import '../../../../shared/widgets/app_primary_button.dart';

enum MobileMoneyTopupDialogType { request, success }

class MobileMoneyTopupStatusDialog extends StatelessWidget {
  const MobileMoneyTopupStatusDialog({
    super.key,
    required this.type,
    this.secondsListenable,
    this.requestTitle,
    this.requestSubtitle,
    this.onCancel,
    this.onAcknowledge,
    this.isCancelling = false,
  });

  final MobileMoneyTopupDialogType type;
  final ValueListenable<int>? secondsListenable;
  final String? requestTitle;
  final String? requestSubtitle;
  final VoidCallback? onCancel;
  final VoidCallback? onAcknowledge;
  final bool isCancelling;

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
    final bool showCancel = isRequest && onCancel != null;
    final bool showAcknowledge = isRequest && onAcknowledge != null;

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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isRequest
                        ? (requestTitle ?? AppStrings.topUpRequestSentTitle.tr)
                        : AppStrings.walletFundsReceivedTitle.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.homeTitle.copyWith(
                      height: 26 / 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      22.w,
                      0,
                      22.w,
                      showCancel || showAcknowledge ? 16.h : 26.h,
                    ),
                    child: isRequest
                        ? (secondsListenable == null
                              ? Text(
                                  requestSubtitle ??
                                      AppStrings.expiresInWithTime.trParams({
                                        'time': _formatTimer(120),
                                      }),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.homeSubtitle,
                                )
                              : ValueListenableBuilder<int>(
                                  valueListenable: secondsListenable!,
                                  builder: (_, seconds, __) {
                                    final subtitle = requestSubtitle;
                                    if (subtitle == null || subtitle.isEmpty) {
                                      return Text(
                                        AppStrings.expiresInWithTime.trParams({
                                          'time': _formatTimer(seconds),
                                        }),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.homeSubtitle,
                                      );
                                    }
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          subtitle,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.homeSubtitle,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          AppStrings.expiresInWithTime.trParams({
                                            'time': _formatTimer(seconds),
                                          }),
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.homeSubtitle,
                                        ),
                                      ],
                                    );
                                  },
                                ))
                        : Text(
                            AppStrings.walletFundsReceivedSubtitle.tr,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.homeSubtitle,
                          ),
                  ),
                  if (showCancel)
                    Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 26.h),
                      child: AppPrimaryButton(
                        label: AppStrings.tanQrCancelRequest.tr,
                        onPressed: isCancelling ? null : onCancel,
                        isLoading: isCancelling,
                        width: double.infinity,
                        height: 56.h,
                        borderRadius: 16.r,
                      ),
                    ),
                  if (showAcknowledge)
                    Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 0, 22.w, 26.h),
                      child: AppPrimaryButton(
                        label: AppStrings.gotIt.tr,
                        onPressed: onAcknowledge,
                        width: double.infinity,
                        height: 56.h,
                        borderRadius: 16.r,
                      ),
                    ),
                ],
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
