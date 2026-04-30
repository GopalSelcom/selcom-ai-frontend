import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class CancelConfirmationDialog extends StatelessWidget {
  const CancelConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.areYouSureYouWantToCancel.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                fontWeight: FontWeight.w600,
                height: 34 / 20,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 24.h),
            _ActionButton(
              title: AppStrings.yesCancel.tr,
              color: AppColors.primary,
              textColor: AppColors.white,
              onTap: () => Get.back(result: true),
            ),
            SizedBox(height: 16.h),
            _ActionButton(
              title: AppStrings.no.tr,
              color: AppColors.white,
              textColor: AppColors.textNeutralButton,
              outlined: true,
              outlinedBorderColor: AppColors.textNeutralButton,
              onTap: () => Get.back(result: false),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelAssignmentWarningDialog extends StatelessWidget {
  const CancelAssignmentWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.areYouSureYouWantToCancel.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlateStrong,
              ),
            ),
            Text(
              AppStrings.yourDriverIsAlreadyOnTheWay.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlateStrong,
                height: 1.2,
              ),
            ),
            SizedBox(height: 16.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppColors.textSlate,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                children: const [
                  TextSpan(text: 'A cancellation fee of '),
                  TextSpan(
                    text: 'TZS 150',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' will be charged since your driver is on the way.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: AppStrings.keepRide.tr,
              color: AppColors.primary,
              textColor: AppColors.white,
              onTap: () => Get.back(result: false),
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: AppStrings.cancelAndPay.tr,
              color: AppColors.bgSoftCircle,
              textColor: AppColors.textSlateSoft,
              onTap: () => Get.back(result: true),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelReasonSelectionDialog extends StatefulWidget {
  final List<String>? reasons;

  const CancelReasonSelectionDialog({super.key, this.reasons});

  @override
  State<CancelReasonSelectionDialog> createState() =>
      _CancelReasonSelectionDialogState();
}

class _CancelReasonSelectionDialogState
    extends State<CancelReasonSelectionDialog> {
  late final List<String> _reasons;

  @override
  void initState() {
    super.initState();
    _reasons =
        widget.reasons ??
        [
          'Selected wrong pickup location',
          'Selected wrong drop location',
          'Booked by mistake',
          'Selected different service/vehicle',
          'Driver asked to pay offline',
          'Driver asked to cancel',
          'Taking too long to arrive',
          'Others',
        ];
  }

  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.whyDoYouWantToCancel.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                fontWeight: FontWeight.w600,
                height: 34 / 20,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 24.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _reasons.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1.h, color: AppColors.bgSoftCircle),
                itemBuilder: (context, index) {
                  final reason = _reasons[index];
                  final isSelected = _selectedReason == reason;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: AppTextStyles.homeSubtitle.copyWith(
                                color: AppColors.black,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                height: 20 / 15,
                              ),
                            ),
                          ),
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.iconHeartOutline,
                                width: 1.5,
                              ),
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14.sp,
                                    color: AppColors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: AppStrings.continueLabel.tr,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.5),
              textColor: AppColors.white,
              onTap: _selectedReason == null
                  ? null
                  : () => Get.back(result: _selectedReason),
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: AppStrings.no.tr,
              color: AppColors.white,
              textColor: AppColors.textNeutralButton,
              outlined: true,
              outlinedBorderColor: AppColors.textNeutralButton,
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  bool get isSelected => _selectedReason != null;
}

class CancellationChargesDialog extends StatelessWidget {
  const CancellationChargesDialog({
    super.key,
    required this.canCancel,
    required this.cancellationFee,
    required this.netRefund,
    required this.policyLabel,
  });

  final bool canCancel;
  final int cancellationFee;
  final int netRefund;
  final String policyLabel;

  @override
  Widget build(BuildContext context) {
    final feeLabel = 'TZS $cancellationFee';
    final refundLabel = 'TZS $netRefund';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: AppColors.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 13.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.areYouSureYouWantToCancel.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                fontWeight: FontWeight.w600,
                height: 26 / 20,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              AppStrings.yourDriverIsAlreadyOnTheWay.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle.copyWith(
                fontWeight: FontWeight.w600,
                height: 26 / 20,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 14.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.homeSubtitle.copyWith(
                  color: AppColors.textSlate,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'A cancellation fee of '),
                  TextSpan(
                    text: feeLabel,
                    style: AppTextStyles.price.copyWith(
                      fontSize: 15.sp,
                      height: 1.4,
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ' will be charged since your driver is on the way.',
                  ),
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: 'Net amount refunded: ',
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.textSlate,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  TextSpan(
                    text: refundLabel,
                    style: AppTextStyles.price.copyWith(
                      fontSize: 15.sp,
                      height: 1.4,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (policyLabel.trim().isNotEmpty)
                    TextSpan(
                      text: '\n$policyLabel',
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.textSlate,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Divider(height: 1.h, color: AppColors.bgSoftCircle),
            SizedBox(height: 20.h),
            _ActionButton(
              title: AppStrings.keepRide.tr,
              color: AppColors.primary,
              textColor: AppColors.white,
              onTap: () => Get.back(result: false),
            ),
            SizedBox(height: 10.h),
            _ActionButton(
              title: 'Cancel & Pay',
              color: AppColors.white,
              textColor: AppColors.textNeutralButton,
              outlined: true,
              outlinedBorderColor: AppColors.textNeutralButton,
              onTap: canCancel ? () => Get.back(result: true) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.outlined = false,
    this.outlinedBorderColor,
  });

  final String title;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? outlinedBorderColor;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: title,
      onPressed: onTap,
      height: 54.h,
      borderRadius: 100.r,
      backgroundColor: color,
      textColor: textColor,
      outlined: outlined,
      outlinedBorderColor: outlinedBorderColor,
      outlinedBorderWidth: outlined ? 1.0 : null,
      outlinedTextColor: textColor,
    );
  }
}
