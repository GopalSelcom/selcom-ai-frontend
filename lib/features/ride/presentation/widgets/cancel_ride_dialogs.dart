import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';

class CancelConfirmationDialog extends StatelessWidget {
  const CancelConfirmationDialog({super.key});

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
                height: 1.2,
              ),
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: AppStrings.yesCancel.tr,
              color: AppColors.primary,
              textColor: AppColors.white,
              onTap: () => Get.back(result: true),
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: AppStrings.no.tr,
              color: AppColors.bgSoftCircle,
              textColor: AppColors.textSlateSoft,
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
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textSlateStrong,
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
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: AppColors.textSlate,
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
                                    : AppColors.skeletonBase,
                                width: 1.2,
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
              color: AppColors.bgSoftCircle,
              textColor: AppColors.textSlateSoft,
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  bool get isSelected => _selectedReason != null;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.r),
          ),
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
