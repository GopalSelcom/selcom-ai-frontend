import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
    /// When set, used for incoming calls after connected (sends `end` to peer).
    this.onHangUp,
  });

  final AgoraVoiceCallController controller;
  final String displayName;
  final bool isIncoming;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onHangUp;
  static const Color _bgColor = Color(0xFF121212);
  static const Color _white = Colors.white;
  static const Color _danger = Color(0xFFE53935);
  static const Color _success = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _white,
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
        );
    final nameStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: _white,
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _white.withValues(alpha: 0.9),
        );
    final chipStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _white,
          fontWeight: FontWeight.w600,
        );

    return Scaffold(
      backgroundColor: _bgColor,
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
                  style: titleStyle,
                ),
                SizedBox(height: 18.h),
                CircleAvatar(
                  radius: 42.r,
                  backgroundColor: _white.withValues(alpha: 0.16),
                  child: Icon(
                    Icons.person,
                    color: _white,
                    size: 42.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: nameStyle,
                ),
                SizedBox(height: 8.h),
                Text(
                  _statusTextFor(state),
                  textAlign: TextAlign.center,
                  style: subtitleStyle,
                ),
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: _white.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      _statusChipLabelFor(state),
                      style: chipStyle,
                    ),
                  ),
                ),
                if (state == AgoraVoiceCallState.ended) ...[
                  SizedBox(height: 6.h),
                  Text(
                    controller.endReasonLabel(),
                    textAlign: TextAlign.center,
                    style: subtitleStyle,
                  ),
                ],
                if (state == AgoraVoiceCallState.connected) ...[
                  SizedBox(height: 6.h),
                  Text(
                    'Duration: ${controller.connectedDurationLabel()}',
                    textAlign: TextAlign.center,
                    style: subtitleStyle,
                  ),
                ],
                const Spacer(),
                if (state == AgoraVoiceCallState.connected)
                  Row(
                    children: [
                      Expanded(
                        child: _secondaryAction(
                          context: context,
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
                          context: context,
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
                          color: _danger,
                          onTap: onReject,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _primaryAction(
                          icon: Icons.call_outlined,
                          label: 'Accept',
                          color: _success,
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
                    color: _danger,
                    onTap: isIncoming &&
                            state == AgoraVoiceCallState.connected &&
                            onHangUp != null
                        ? onHangUp!
                        : onReject,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _secondaryAction({
    required BuildContext context,
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
          color: _white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _white.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _white),
            SizedBox(height: 4.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _white,
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
        foregroundColor: _white,
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

  String _statusTextFor(AgoraVoiceCallState state) {
    switch (state) {
      case AgoraVoiceCallState.idle:
        return 'Ready to call';
      case AgoraVoiceCallState.connecting:
        return 'Connecting call...';
      case AgoraVoiceCallState.connected:
        return 'Call in progress';
      case AgoraVoiceCallState.ended:
        return 'Call finished';
      case AgoraVoiceCallState.error:
        return 'Call error';
    }
  }

  String _statusChipLabelFor(AgoraVoiceCallState state) {
    switch (state) {
      case AgoraVoiceCallState.idle:
        return 'Ready';
      case AgoraVoiceCallState.connecting:
        return 'Connecting';
      case AgoraVoiceCallState.connected:
        return 'Connected';
      case AgoraVoiceCallState.ended:
        return 'Ended';
      case AgoraVoiceCallState.error:
        return 'Error';
    }
  }
}
