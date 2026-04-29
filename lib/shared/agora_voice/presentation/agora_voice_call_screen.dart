import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/agora_voice_call_state.dart';
import 'agora_voice_call_controller.dart';

class AgoraVoiceCallScreen extends StatelessWidget {
  const AgoraVoiceCallScreen({
    super.key,
    required this.controller,
    required this.displayName,
    required this.isIncoming,
    required this.onAccept,
    required this.onReject,
  });

  final AgoraVoiceCallController controller;
  final String displayName;
  final bool isIncoming;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textHeading,
      body: SafeArea(
        child: Obx(() {
          final state = controller.callState.value;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isIncoming ? 'Incoming Voice Call' : 'Calling...',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeTitle.copyWith(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 18.h),
                CircleAvatar(
                  radius: 42.r,
                  backgroundColor: AppColors.white.withValues(alpha: 0.16),
                  child: Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 42.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeTitle.copyWith(
                    color: AppColors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'State: ${controller.stateLabel()}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const Spacer(),
                if (state == AgoraVoiceCallState.connected)
                  Row(
                    children: [
                      Expanded(
                        child: _secondaryAction(
                          icon: controller.isMuted.value
                              ? Icons.mic_off_outlined
                              : Icons.mic_none_outlined,
                          label: controller.isMuted.value ? 'Unmute' : 'Mute',
                          onTap: controller.toggleMute,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _secondaryAction(
                          icon: controller.isSpeakerEnabled.value
                              ? Icons.volume_up_outlined
                              : Icons.hearing_disabled_outlined,
                          label: controller.isSpeakerEnabled.value
                              ? 'Speaker'
                              : 'Earpiece',
                          onTap: controller.toggleSpeaker,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 16.h),
                if (isIncoming && state != AgoraVoiceCallState.connected)
                  Row(
                    children: [
                      Expanded(
                        child: _primaryAction(
                          icon: Icons.call_end_outlined,
                          label: 'Reject',
                          color: AppColors.error,
                          onTap: onReject,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _primaryAction(
                          icon: Icons.call_outlined,
                          label: 'Accept',
                          color: AppColors.successBadge,
                          onTap: onAccept,
                        ),
                      ),
                    ],
                  )
                else
                  _primaryAction(
                    icon: Icons.call_end_outlined,
                    label: state == AgoraVoiceCallState.connected
                        ? 'End Call'
                        : 'Cancel',
                    color: AppColors.error,
                    onTap: onReject,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.white),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
