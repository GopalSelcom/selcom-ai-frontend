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
class RideDriverCallOptionsSheet extends StatelessWidget {
  const RideDriverCallOptionsSheet({
    super.key,
    required this.rideId,
    required this.peerDisplayName,
    required this.driverPhone,
    this.peerAvatarUrl,
  });

  final String rideId;
  final String peerDisplayName;
  final String driverPhone;
  final String? peerAvatarUrl;

  static Future<void> show({
    required String rideId,
    required String peerDisplayName,
    required String driverPhone,
    String? peerAvatarUrl,
  }) {
    if (rideId.isEmpty) return Future.value();

    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.callDriver.tr,
      subtitle: AppStrings.callDriverSheetSubtitle.tr,
      headerTextAlign: TextAlign.start,
      barrierDismissible: true,
      content: RideDriverCallOptionsSheet(
        rideId: rideId,
        peerDisplayName: peerDisplayName,
        driverPhone: driverPhone,
        peerAvatarUrl: peerAvatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DriverCallOptionTile(
          icon: Icons.phone_in_talk_outlined,
          title: AppStrings.inAppCalling.tr,
          subtitle: AppStrings.inAppCallingSubtitle.tr,
          onTap: () => _onInAppCallTap(),
        ),
        SizedBox(height: 10.h),
        _DriverCallOptionTile(
          icon: Icons.call_outlined,
          title: AppStrings.normalCall.tr,
          subtitle: AppStrings.normalCallSubtitle.tr,
          onTap: () => _onNormalCallTap(),
        ),
      ],
    );
  }

  Future<void> _onInAppCallTap() async {
    Get.back<void>();
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
        title: AppStrings.callDriver.tr,
        message: e.outcome == PermissionOutcome.permanentlyDenied
            ? 'Microphone permission is permanently denied. Open Settings to allow it.'
            : 'Microphone permission is required to place a call.',
      );
    } catch (e, st) {
      ErrorReporter.instance.report(error: e, stackTrace: st);
      await show(
        rideId: rideId,
        peerDisplayName: peerDisplayName,
        driverPhone: driverPhone,
        peerAvatarUrl: peerAvatarUrl,
      );
    }
  }

  void _onNormalCallTap() {
    Get.back<void>();
    final phone = driverPhone.trim();
    if (phone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.callDriver.tr,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    unawaited(_launchSystemPhoneDialer(phone));
  }

  static Future<void> _launchSystemPhoneDialer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.callDriver.tr,
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
        title: AppStrings.callDriver.tr,
        message: AppStrings.errorOpeningPhoneDialer.tr,
      );
    }
  }
}

class _DriverCallOptionTile extends StatelessWidget {
  const _DriverCallOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.homeSubtitle.copyWith(
                        color: AppColors.textHeading,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
}
