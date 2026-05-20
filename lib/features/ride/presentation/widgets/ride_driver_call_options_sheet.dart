import 'dart:async';

import 'package:agora_calling_package/agora_calling_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';

/// In-app (Agora) vs system dialer — same UX from driver-accepted and ride chat.
class RideDriverCallOptionsSheet {
  RideDriverCallOptionsSheet._();

  static void show({
    required String rideId,
    required String peerDisplayName,
    required String driverPhone,
    String? peerAvatarUrl,
  }) {
    if (rideId.isEmpty) return;

    AppDialogs.showAnimatedBottomSheet(
      barrierDismissible: true,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBase,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.call.tr,
                    style: AppTextStyles.homeTitle.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _optionTile(
                  title: AppStrings.inAppCalling.tr,
                  icon: Icons.phone_in_talk_outlined,
                  onTap: () async {
                    AppDialogs.closeActiveDialog();
                    try {
                      await AgoraCalling.controller.placeCall(
                        rideId: rideId,
                        peerDisplayName: peerDisplayName.isNotEmpty
                            ? peerDisplayName
                            : 'Your Driver',
                        peerAvatarUrl: peerAvatarUrl,
                      );
                    } on CallPermissionDeniedException catch (e) {
                      AppDialogs.showErrorDialog(
                        title: AppStrings.call.tr,
                        message: e.outcome == PermissionOutcome.permanentlyDenied
                            ? 'Microphone permission is permanently denied. Open Settings to allow it.'
                            : 'Microphone permission is required to place a call.',
                      );
                    } catch (e, st) {
                      ErrorReporter.instance.report(error: e, stackTrace: st);
                      show(
                        rideId: rideId,
                        peerDisplayName: peerDisplayName,
                        driverPhone: driverPhone,
                        peerAvatarUrl: peerAvatarUrl,
                      );
                    }
                  },
                ),
                SizedBox(height: 10.h),
                _optionTile(
                  title: AppStrings.normalCall.tr,
                  icon: Icons.call_outlined,
                  onTap: () {
                    AppDialogs.closeActiveDialog();
                    final phone = driverPhone.trim();
                    if (phone.isEmpty) {
                      AppDialogs.showErrorDialog(
                        title: AppStrings.call.tr,
                        message: AppStrings.phoneNumberUnavailable.tr,
                      );
                      return;
                    }
                    unawaited(_launchSystemPhoneDialer(phone));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _optionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textHeading, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.textHeading,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: AppColors.textMapHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchSystemPhoneDialer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.call.tr,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint('Error launching dialer: $e');
      AppDialogs.showErrorDialog(
        title: AppStrings.call.tr,
        message: AppStrings.errorOpeningPhoneDialer.tr,
      );
    }
  }
}
