import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/device_security_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';

/// Full-screen gate shown when release integrity checks fail.
///
/// The app cannot continue until checks pass (via Try again) after remediation.
class DeviceSecurityBlockedScreen extends StatefulWidget {
  const DeviceSecurityBlockedScreen({super.key});

  @override
  State<DeviceSecurityBlockedScreen> createState() =>
      _DeviceSecurityBlockedScreenState();
}

class _DeviceSecurityBlockedScreenState
    extends State<DeviceSecurityBlockedScreen> {
  /// True while [DeviceSecurityService.recheckAndResume] is running.
  bool _isRechecking = false;

  /// Which security check failed — drives localized title / subtitle / guidance.
  late DeviceSecurityIssue _issue;

  @override
  void initState() {
    super.initState();
    _issue = _resolveIssue();
  }

  DeviceSecurityIssue _resolveIssue() {
    final args = Get.arguments;
    if (args is DeviceSecurityIssue) return args;
    return DeviceSecurityService.instance.lastVerdict.issue ??
        DeviceSecurityIssue.jailbreakOrRoot;
  }

  Future<void> _onTryAgain() async {
    if (_isRechecking) return;
    setState(() => _isRechecking = true);
    try {
      final cleared = await DeviceSecurityService.instance.recheckAndResume();
      if (!mounted) return;
      if (!cleared) {
        setState(() {
          _issue = DeviceSecurityService.instance.lastVerdict.issue ?? _issue;
          _isRechecking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRechecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(_issue);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 88.w,
                  height: 88.w,
                  decoration: const BoxDecoration(
                    color: AppColors.errorBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.shield_cross,
                    size: 40.sp,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 28.h),
                Text(
                  copy.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle.copyWith(
                    color: AppColors.textHeading,
                    fontSize: 22.sp,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  copy.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textBody,
                    fontSize: 15.sp,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.errorBackground),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 20.sp,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          copy.guidance,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSlate,
                            fontSize: 13.sp,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                AppPrimaryButton(
                  label: AppStrings.deviceSecurityTryAgain.tr,
                  width: double.infinity,
                  height: 52.h,
                  isLoading: _isRechecking,
                  backgroundColor: AppColors.primaryButton,
                  onPressed: _isRechecking ? null : _onTryAgain,
                ),
                SizedBox(height: 12.h),
                AppPrimaryButton(
                  label: AppStrings.deviceSecurityCloseApp.tr,
                  width: double.infinity,
                  height: 52.h,
                  outlined: true,
                  outlinedBorderColor: AppColors.primaryButton,
                  outlinedTextColor: AppColors.primaryButton,
                  onPressed: _isRechecking
                      ? null
                      : () => SystemNavigator.pop(),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Localized title / body / guidance for each [DeviceSecurityIssue].
  static _BlockedCopy _copyFor(DeviceSecurityIssue issue) {
    switch (issue) {
      case DeviceSecurityIssue.mockLocation:
        return _BlockedCopy(
          title: AppStrings.deviceSecurityMockLocationTitle.tr,
          subtitle: AppStrings.deviceSecurityMockLocationSubtitle.tr,
          guidance: AppStrings.deviceSecurityMockLocationGuidance.tr,
        );
      case DeviceSecurityIssue.developerOptions:
        return _BlockedCopy(
          title: AppStrings.deviceSecurityDeveloperOptionsTitle.tr,
          subtitle: AppStrings.deviceSecurityDeveloperOptionsSubtitle.tr,
          guidance: AppStrings.deviceSecurityDeveloperOptionsGuidance.tr,
        );
      case DeviceSecurityIssue.jailbreakOrRoot:
        return _BlockedCopy(
          title: AppStrings.deviceSecurityJailbreakTitle.tr,
          subtitle: AppStrings.deviceSecurityJailbreakSubtitle.tr,
          guidance: AppStrings.deviceSecurityJailbreakGuidance.tr,
        );
      case DeviceSecurityIssue.routeSpoofing:
        return _BlockedCopy(
          title: AppStrings.deviceSecurityRouteSpoofingTitle.tr,
          subtitle: AppStrings.deviceSecurityRouteSpoofingSubtitle.tr,
          guidance: AppStrings.deviceSecurityRouteSpoofingGuidance.tr,
        );
    }
  }
}

class _BlockedCopy {
  const _BlockedCopy({
    required this.title,
    required this.subtitle,
    required this.guidance,
  });

  final String title;
  final String subtitle;
  final String guidance;
}
