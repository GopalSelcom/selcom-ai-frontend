import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ride_chat_message.dart';
import '../controllers/ride_message_controller.dart';

class RideMessageScreen extends GetView<RideMessageController> {
  const RideMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
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
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(40.r),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.goBack,
            icon: const Icon(Iconsax.arrow_left, color: AppColors.shade1),
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
                    color: const Color(0xFF586377),
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
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
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
              color: Colors.white,
              size: 14,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Do not share your personal Details with rider Be safe and always check your luggage',
              style: AppTextStyles.body.copyWith(
                color: AppColors.shade1,
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
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 0.75.sw),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.driverBubbleBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarWithDot(m.avatarUrl),
                SizedBox(height: 8.h),
                if (m.displayName != null)
                  Text(
                    m.displayName!,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 4.h),
                Text(
                  m.text,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.shade1,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTime(m.sentAt),
                    style: AppTextStyles.homeCaption.copyWith(
                      color: const Color(0xFF8B9AAC),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderRow(RideChatMessage m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 0.75.sw),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _avatarWithDot(m.avatarUrl, isRider: true),
                SizedBox(height: 8.h),
                if (m.displayName != null)
                  Text(
                    m.displayName!,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                SizedBox(height: 4.h),
                Text(
                  m.text,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 4.h),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    _formatTime(m.sentAt),
                    style: AppTextStyles.homeCaption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWithDot(String? url, {bool isRider = false}) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 18.r,
          backgroundImage: url != null ? NetworkImage(url) : null,
          backgroundColor: isRider
              ? Colors.white.withOpacity(0.2)
              : const Color(0xFFF3F4F6),
          child: url == null
              ? Icon(
                  Icons.person,
                  size: 20.sp,
                  color: isRider ? Colors.white : const Color(0xFF9CA3AF),
                )
              : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: AppColors.onlineGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
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
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
        ),
        child: Opacity(
          opacity: allowed ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !allowed,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(32.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.messageController,
                            enabled: allowed,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.shade1,
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
                    color: allowed ? AppColors.primary : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: controller.sendCurrentMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
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
