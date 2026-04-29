import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/agora_voice_call_state.dart';
import 'agora_voice_call_controller.dart';

class AgoraVoiceCallBottomSheet extends StatelessWidget {
  const AgoraVoiceCallBottomSheet({
    super.key,
    required this.controller,
    required this.displayName,
  });

  final AgoraVoiceCallController controller;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Obx(() {
            controller.showErrorIfNeeded();
            final state = controller.callState.value;
            return Column(
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
                    'In-App Voice Call',
                    style: AppTextStyles.homeTitle.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayName,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'State: ${controller.stateLabel()}',
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _smallButton(
                        icon: controller.isMuted.value
                            ? Icons.mic_off_outlined
                            : Icons.mic_none_outlined,
                        label: controller.isMuted.value ? 'Unmute' : 'Mute',
                        onTap: state == AgoraVoiceCallState.connected
                            ? controller.toggleMute
                            : null,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _smallButton(
                        icon: controller.isSpeakerEnabled.value
                            ? Icons.volume_up_outlined
                            : Icons.hearing_disabled_outlined,
                        label: controller.isSpeakerEnabled.value
                            ? 'Speaker On'
                            : 'Speaker Off',
                        onTap: state == AgoraVoiceCallState.connected
                            ? controller.toggleSpeaker
                            : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                if (state == AgoraVoiceCallState.idle ||
                    state == AgoraVoiceCallState.ended ||
                    state == AgoraVoiceCallState.error)
                  _primaryAction(
                    label: state == AgoraVoiceCallState.error
                        ? 'Retry Call'
                        : 'Start Call',
                    onTap: state == AgoraVoiceCallState.error
                        ? controller.restartCall
                        : controller.startCall,
                  )
                else
                  _primaryAction(
                    label: state == AgoraVoiceCallState.connecting
                        ? 'Connecting...'
                        : 'End Call',
                    isDanger: state == AgoraVoiceCallState.connected,
                    onTap: state == AgoraVoiceCallState.connected
                        ? controller.endCall
                        : null,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderWalletCard),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: AppColors.textHeading),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction({
    required String label,
    required VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? AppColors.error : AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
