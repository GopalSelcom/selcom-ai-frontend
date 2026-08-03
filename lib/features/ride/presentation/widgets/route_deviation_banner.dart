import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/driver_accepted_controller.dart';

/// Route-deviation card for the in-progress ride sheet (socket/REST only).
///
/// Having-trouble cancel requests use [HavingTroubleCancellationBanner].
class RouteDeviationBanner extends StatelessWidget {
  const RouteDeviationBanner({super.key, required this.controller});

  final DriverAcceptedController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.shouldShowRouteDeviationBanner) {
        return const SizedBox.shrink();
      }

      final offRoute = controller.isRouteDeviationOffRoute;
      final pending = controller.isDeviationCancellationPending;
      final rejected = controller.isDeviationCancellationRejected;
      final onRoute = !offRoute && !pending && !rejected;
      final tone = rejected
          ? _DeviationTone.neutral
          : offRoute
          ? _DeviationTone.warning
          : _DeviationTone.success;

      return _DeviationCard(
        tone: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(
              tone: tone,
              title: controller.routeDeviationBannerTitle,
              subtitle: controller.routeDeviationBannerSubtitle,
              distanceText: offRoute
                  ? controller.routeDeviationDistanceText
                  : '',
              showDismiss: controller.canDismissRouteDeviationBanner,
              onDismiss: controller.dismissRouteDeviationBanner,
            ),
            if (pending) ...[
              SizedBox(height: 12.h),
              _StatusCallout(
                text: AppStrings.cancellationRequestSentWithTicket.trParams({
                  'ticket': controller.deviationCancellationTicketNumber,
                }),
              ),
              SizedBox(height: 12.h),
              AppPrimaryButton(
                label: AppStrings.withdrawRequest.tr,
                onPressed: controller.withdrawDeviationCancellationRequest,
                outlined: true,
                outlinedBorderColor: AppColors.borderWalletCard,
                outlinedTextColor: AppColors.textHeading,
                height: 44.h,
                borderRadius: 12.r,
                labelStyle: AppTextStyles.homeSubtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ] else if (rejected) ...[
              SizedBox(height: 12.h),
              _StatusCallout(
                text: AppStrings.supportDeclinedCancellation.tr,
                note: controller.deviationCancellationNote.isEmpty
                    ? null
                    : controller.deviationCancellationNote,
              ),
              if (controller.canRequestCancellationFromDeviation) ...[
                SizedBox(height: 12.h),
                AppPrimaryButton(
                  label: AppStrings.requestToCancel.tr,
                  onPressed: controller.openRequestCancellationSheet,
                  height: 44.h,
                  borderRadius: 12.r,
                  labelStyle: AppTextStyles.homeSubtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ] else if (offRoute) ...[
              SizedBox(height: 14.h),
              _ActionRow(controller: controller),
            ] else if (onRoute) ...[
              // Muted "back on route" — dismiss via header close only.
            ],
          ],
        ),
      );
    });
  }
}

enum _DeviationTone { warning, success, neutral }

class _DeviationCard extends StatelessWidget {
  const _DeviationCard({required this.tone, required this.child});

  final _DeviationTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    switch (tone) {
      case _DeviationTone.warning:
        bg = AppColors.bgWarningLight;
        border = AppColors.warning.withValues(alpha: 0.35);
      case _DeviationTone.success:
        bg = AppColors.success.withValues(alpha: 0.08);
        border = AppColors.success.withValues(alpha: 0.28);
      case _DeviationTone.neutral:
        bg = AppColors.surfaceSubtle;
        border = AppColors.borderWalletCard;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.distanceText,
    required this.showDismiss,
    required this.onDismiss,
  });

  final _DeviationTone tone;
  final String title;
  final String subtitle;
  final String distanceText;
  final bool showDismiss;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final IconData icon;
    switch (tone) {
      case _DeviationTone.warning:
        accent = AppColors.warningStrong;
        icon = Icons.warning_amber_rounded;
      case _DeviationTone.success:
        accent = AppColors.success;
        icon = Icons.check_circle_rounded;
      case _DeviationTone.neutral:
        accent = AppColors.textSlate;
        icon = Icons.info_outline_rounded;
    }

    final hasText =
        title.isNotEmpty || subtitle.isNotEmpty || distanceText.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 20.sp, color: accent),
        ),
        if (hasText) ...[
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                      height: 1.3,
                    ),
                  ),
                if (distanceText.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      distanceText,
                      style: AppTextStyles.homeCaption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.textSlate,
                      height: 1.4,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else
          const Spacer(),
        if (showDismiss)
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Icon(
                Icons.close_rounded,
                size: 18.sp,
                color: AppColors.textSlate,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusCallout extends StatelessWidget {
  const _StatusCallout({required this.text, this.note});

  final String text;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderWalletCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
              height: 1.35,
              fontSize: 13.sp,
            ),
          ),
          if (note != null && note!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              note!,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.textSlate,
                height: 1.35,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller});

  final DriverAcceptedController controller;

  @override
  Widget build(BuildContext context) {
    final showRequest = controller.canRequestCancellationFromDeviation;
    final labelStyle = AppTextStyles.homeSubtitle.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 12.5.sp,
      height: 1.2,
    );

    return Row(
      children: [
        Expanded(
          child: AppPrimaryButton(
            label: AppStrings.continueToTrip.tr,
            onPressed: controller.continueToTripFromDeviation,
            outlined: true,
            outlinedBorderColor: AppColors.borderWalletCard,
            outlinedTextColor: AppColors.textHeading,
            height: 44.h,
            borderRadius: 12.r,
            labelStyle: labelStyle.copyWith(color: AppColors.textHeading),
          ),
        ),
        if (showRequest) ...[
          SizedBox(width: 8.w),
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.requestToCancel.tr,
              onPressed: controller.openRequestCancellationSheet,
              height: 44.h,
              borderRadius: 12.r,
              labelStyle: labelStyle.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ],
    );
  }
}
