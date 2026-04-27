import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../domain/entities/ride_chat_message.dart';
import '../controllers/ride_message_controller.dart';

class RideMessageScreen extends GetView<RideMessageController> {
  const RideMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Map Header (Faded static image)
            SizedBox(
              height: 100.h,
              width: double.infinity,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  AppAssets.mapBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _grabber(),
                    _header(),
                    _safetyBanner(),
                    Expanded(child: _messageList()),
                    _composer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grabber() {
    return Container(
      width: 48.w,
      height: 4.h,
      margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        borderRadius: BorderRadius.circular(40.r),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Row(
        children: [
          AppBackButton(
            color: AppColors.textHeading,
            onPressed: controller.goBack,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  controller.driverName,
                  style: AppTextStyles.homeTitle.copyWith(fontSize: 18.sp),
                ),
                Text(
                  controller.driverSubtitle,
                  style: AppTextStyles.homeCaption.copyWith(
                    color: AppColors.figmaTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: controller.onTapCallDriver,
              icon: const Icon(Icons.call, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.safetyBannerBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: const BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.white,
              size: 14,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppStrings
                  .doNotShareYourPersonalDetailsWithRiderBeSafeAndAlwaysCheckYourLuggage
                  .tr,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textHeading,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    return Obx(() {
      return ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.all(16.w),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final m = controller.messages[index];
          return m.isFromRider ? _riderRow(m) : _driverRow(m);
        },
      );
    });
  }

  Widget _driverRow(RideChatMessage m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.72.sw),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.driverBubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.r),
                    topRight: Radius.circular(14.r),
                    bottomLeft: Radius.circular(14.r),
                    bottomRight: Radius.circular(14.r),
                  ),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.text,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textHeading,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatTime(m.sentAt),
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.borderInputMuted,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderRow(RideChatMessage m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.72.sw),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14.r),
                    topRight: Radius.circular(4.r),
                    bottomLeft: Radius.circular(14.r),
                    bottomRight: Radius.circular(14.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.text,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        height: 1.35,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(m.sentAt),
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 10.sp,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.done_all_rounded,
                            size: 14.sp,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}";
  }

  Widget _composer() {
    return Obx(() {
      final bool allowed = controller.canChat;
      return Container(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Opacity(
          opacity: allowed ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !allowed,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(32.r),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.messageController,
                            enabled: allowed,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: 5,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textHeading,
                            ),
                            decoration: InputDecoration(
                              hintText: allowed
                                  ? 'Write a message...'
                                  : 'Chat unavailable',
                              hintStyle: AppTextStyles.hint,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: allowed ? AppColors.primary : AppColors.skeletonBase,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: controller.sendCurrentMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
